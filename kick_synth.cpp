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

#include "piezoTrigger.h"


#define TAP_INPUT                  14

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
#if defined(USE_SAMPLE)
AudioPlayMemory2			kickSample;
// AudioPlayMemory			kickSample;
AudioConnection         patchCord1_l(kickSample, 0, gain_l, 0);
AudioConnection         patchCord1_r(kickSample, 0, gain_r, 0);
#else
AudioSynthSimpleDrum	kick;
AudioConnection         patchCord1_l(kick, gain_l);
AudioConnection         patchCord1_r(kick, gain_r);
#endif
AudioConnection			patchCord3(gain_l, 0, out, 0);
// AudioConnection			patchCord3(kickSample, 0, out, 0);
AudioConnection			patchCord4(gain_r, 0, out, 1);
// AudioConnection			patchCord4(kickSample, 0, out, 1);

usb_serial_class 		Serial;
elapsedMillis 			since_LED_switch, since_hello;
elapsedMillis			interrupt_time;

piezoTrigger			piezo(TAP_INPUT, onPiezoTrigger);

uint32_t		counter, bigtime;
uint32_t		interrupts_last, interrupts_delta;


//////////////////////////////
//
// Normal setup() function
// initialize usb, midi, audio
//
//////////////////////////////
void setup()
{
	pinMode(LED_BUILTIN, OUTPUT);
	usb_init();
	Serial.begin(115200);

	delay(100);
	while (!Serial)
		delay(100);
	dbg("\nHello teensy kick " TEENSYKICK_VERSION "\n\n");

	// Midi setup
	usbMIDI.setHandleNoteOn(onNoteOn);
	usbMIDI.setHandleNoteOff(onNoteOff);

	delay(1000);

	// Audio component setup
	AudioMemory(6);
#if defined(USE_SAMPLE)
#else
	kick.frequency(80);
	kick.length(200);
	kick.secondMix(0.25);
	kick.pitchMod(0x2f0); // 0x200 is no mod...
#endif
	dac.enable();
	dac.lineOutLevel( 14 );

	gain_l.gain(0.5);
	gain_r.gain(0.5);

	piezo.setup();
}

void loop()
{
	static bool run = true, levelHigh = true;
	static float gain = 1.0f;

	if (since_LED_switch > 500) {
		digitalToggleFast(LED_BUILTIN);
		since_LED_switch = 0;
	}
	if (since_hello >= 1000) {
		// dbg(".");
		if (++counter >= 10) {
			/*
			 * This is code to verify the audio servicing interrupts
			 *
			uint32_t this_count = out.isrCount();
			interrupts_delta = this_count - interrupts_last;
			interrupts_last = this_count;
			dbg(" isr=%4lu %5lu %3lu\n", interrupts_delta,
					(uint32_t)interrupt_time, bigtime++);
			interrupt_time = 0;
			 */
			counter = 0;
		}
		since_hello = 0;
	}
	while (Serial.available()) {
		int incoming = Serial.read();
		switch (incoming) {
		case 'a':
			printf("Audio used %u buffers\n", AudioMemoryUsageMax() );
		break;
#if defined(USE_SAMPLE)
#else
		case 'b':
			printf("drum used %u cycles\n", kick.cpu_cycles_total );
		break;
#endif

		case ' ':
			run = !run;
			printf("now %s\n", run? "running" : "stopped");
			if (run) {
#if defined(USE_SAMPLE)
				kickSample.play(AudioSampleKiddykick);
#else
				kick.noteOn();
#endif
			}
			else {
#if defined(USE_SAMPLE)
#else
				kick.noteOn(0x6000);
#endif
			}
		break;

		// Adjust the gain
		case 'g':
			gain = gain / 2.0f;
			if (gain < 0.0625)
				gain = 1.0f;
			fprintf(stdout, "gain %3u\n", int(gain * 100.0));
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

		//
		case 't':
			{
				bool piezoTest = piezo.testMode();

				piezoTest = piezo.testMode( not piezoTest );

				printf("piezo test = %s\n", piezoTest? "true" : "false");
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
}

void onNoteOn(byte chan, byte note, byte vel)
{
	dbg("N ch=%u %u( %u ) on\n", chan, note, vel);
#if defined(USE_SAMPLE)
	kickSample.play(AudioSampleKiddykick);
#else
	uint32_t v = vel << 8;
	kick.noteOn(v);
#endif
}

void onNoteOff(byte chan, byte note, byte vel)
{
	dbg("N c=%u %u( %u ) off\n", chan, note, vel);
}

void onPiezoTrigger(uint32_t vel)
{
	dbg("PiezoTrigger %4lu %4lu\n\n", vel, millis());
#if defined(USE_SAMPLE)
	kickSample.play(AudioSampleKiddykick);
#else
	kick.noteOn(vel);
#endif
}
