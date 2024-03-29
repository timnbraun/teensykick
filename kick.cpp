/* teensy kick
 *
 * Copyright (c) 2022 Tim Braun <tim.n.braun@gmail.com>
 *
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the
 * "Software"), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to
 * the following conditions:
 *
 * 1. The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * 2. If the Software is incorporated into a build system that allows
 * selection among a list of target devices, then similar target
 * devices manufactured by PJRC.COM must be included in the list of
 * target devices and selectable in the same manner.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
 * BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
 * ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 * CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */


#include <Arduino.h>
#include <Audio.h>
#include <usb_dev.h>
#include <TimedBlink.h>

#include "AudioSampleKiddykick.h"
#include "piezoTrigger.h"
#include "play_memory2.h"

#define TAP_INPUT                  A7

#define dbg(...) \
	fiprintf(stderr, __VA_ARGS__)
#define dbg_putc(c) \
	fputc((c), stderr)

#define printf( ... ) \
	fiprintf(stdout, __VA_ARGS__ )

void onNoteOn(byte chan, byte note, byte vel);
void onNoteOff(byte chan, byte note, byte vel);
void onPiezoTrigger(uint32_t);

AudioControlSGTL5000	dac;
AudioOutputI2S        	out;
AudioAmplifier			gain_l;
AudioAmplifier			gain_r;

AudioPlayMemory2		kickSample;

AudioConnection         patchCord1_l(kickSample, 0, gain_l, 0);
AudioConnection         patchCord1_r(kickSample, 1, gain_r, 0);
AudioConnection			patchCord3(gain_l, 0, out, 0);
AudioConnection			patchCord4(gain_r, 0, out, 1);

usb_serial_class 		Serial;
elapsedMillis 			metronome_beat, since_kick;
bool					kicked = false;

TimedBlink				heart(LED_BUILTIN);

piezoTrigger			piezo(TAP_INPUT, onPiezoTrigger);


//////////////////////////////
//
// Normal setup() function
// initialize usb, midi, audio
//
//////////////////////////////
void setup()
{
	pinMode(LED_BUILTIN, OUTPUT);
	heart.blink(250, 250);
	usb_init();
	Serial.begin(115200);

	for (int i = 0; !Serial && (i < 10); i++) {
		heart.blinkDelay(100);
	}

	// Midi setup
	usbMIDI.setHandleNoteOn(onNoteOn);
	// usbMIDI.setHandleNoteOff(onNoteOff);

	heart.blinkDelay(1000);

	// Audio component setup
	AudioMemory(6);
	dac.enable();
	dac.lineOutLevel( 29 );

	heart.blinkDelay(500);
	dbg("Audio init\n");

	kickSample.invertPhase(1, true);

	heart.blinkDelay(100);
	dbg("Sample init\n");

	gain_l.gain(0.5);
	gain_r.gain(0.5);

	heart.blinkDelay(100);
	dbg("Gain init\n");

	piezo.setup();

	heart.blinkDelay(100);
	dbg("\nHello teensy kick " TEENSYKICK_VERSION " " BUILD_DATE "\n\n");
	heart.heartbeat( 150, 4000 - (3*150), 2 );
}

void loop()
{
	static bool levelHigh = true, metronome = false;
	static float gain = 1.0f;


	if (metronome && metronome_beat > 10000) {
		dbg("kick\n");
		kickSample.play(AudioSampleKiddykick);
		since_kick = 0;
		kicked = true;
		metronome_beat = 0;
	}

	if (kicked && since_kick > 200) {
		digitalWrite(LED_BUILTIN, LOW);
		since_kick = 0;
		kicked = false;
	}

	while (Serial.available()) {
		int incoming = Serial.read();
		switch (incoming) {
		case 'a':
			printf("Audio used %u buffers\n", AudioMemoryUsageMax() );
		break;

		// Kick it
		case 'k':
		case ' ':
			printf("kick it now\n");
			kickSample.play(AudioSampleKiddykick);
			kicked = true;
		break;

		// Adjust the gain
		case 'g':
			gain = gain / 2.0f;
			if (gain < 0.0625)
				gain = 1.0f;
			printf("gain %3u\n", int(gain * 100.0));
			gain_r.gain( gain );
			gain_l.gain( gain );
		break;

		case 'l':
			if (levelHigh) {
				dac.lineOutLevel( 28 );
			}
			else {
				dac.lineOutLevel( 14 );
			}
			levelHigh = !levelHigh;
			dbg("level now %s\n", levelHigh? "high" : "low");
		break;

		// metronome kick
		case 'm':
			metronome = !metronome;
			dbg("metronome %s\n", metronome? "true" : "false");
		break;

		// Put the piezo object into test mode
		case 't':
			{
				bool piezoTest = piezo.testMode();

				piezoTest = piezo.testMode( not piezoTest );

				dbg("piezo test = %s\n", piezoTest? "true" : "false");
			}
		break;

		// Print the version from compile time
		case 'v':
			printf("\nteensy kick " TEENSYKICK_VERSION "\n\n");
		break;

		// case 'r':
		// 	_reboot_Teensyduino_();
		// break;
		case '\n':
			break;
		default:
			dbg_putc(incoming);
		}
	}

	piezo.loop();

	usbMIDI.read();

	heart.loop();
}

void onNoteOn(byte chan, byte note, byte vel)
{
	dbg("N=%u ( %u ) c=%u\n", note, vel, chan);

	onPiezoTrigger( vel );
}

// void onNoteOff(byte chan, byte note, byte vel)
// {
// 	dbg("N c=%u %u( %u ) off\n", chan, note, vel);
// }

////////////
///
/// vel is like midi => 0 - 127
///
////////////
void onPiezoTrigger(uint32_t vel)
{
	dbg("gonna kick %3lu @ %6lu\n\n", vel, millis());

	// A pretty light
	digitalWrite(LED_BUILTIN, HIGH);
	since_kick = 0;
	kicked = true;

	// Set the gain
	gain_l.gain( vel / 127.0f );
	gain_r.gain( vel / 127.0f );

	// boom!
	kickSample.play(AudioSampleKiddykick);
}
