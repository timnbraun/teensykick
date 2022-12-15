/* teensy kick
 *
 * Copyright (c) 2020 Tim Braun <tim.n.braun@gmail.com>
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

#define USE_SAMPLE
#include <Audio.h>
#include <usb_dev.h>
#if defined(USE_SAMPLE)
#include "AudioSampleKick.h"
#endif

#define dbg_putc(c) \
	fputc((c), stderr)

void onNoteOn(byte chan, byte note, byte vel);
void onNoteOff(byte chan, byte note, byte vel);

AudioControlSGTL5000	dac;
AudioOutputI2S        	out;
AudioAmplifier			gain;
#if defined(USE_SAMPLE)
AudioPlayMemory			kickSample;
AudioConnection         patchCord1(kickSample, 0, gain, 0);
#else
AudioSynthSimpleDrum	kick;
AudioConnection         patchCord1(kick, 0, gain, 0);
#endif
AudioConnection			patchCord3(gain, 0, out, 0);
AudioConnection			patchCord4(gain, 0, out, 1);

usb_serial_class 		Serial;
elapsedMillis 			since_LED_switch, since_hello;
elapsedMillis			interrupt_time;

uint32_t		counter, bigtime;
uint32_t		interrupts_last, interrupts_delta;


void setup()
{
	pinMode(LED_BUILTIN, OUTPUT);
	usb_init();

	usbMIDI.setHandleNoteOn(onNoteOn);
	usbMIDI.setHandleNoteOff(onNoteOff);

	delay(1000);
	AudioMemory(2);
#if defined(USE_SAMPLE)
#else
	kick.frequency(80);
	kick.length(200);
	kick.secondMix(0.25);
	kick.pitchMod(0x2f0); // 0x200 is no mod...
#endif
	dbg("\r\nHello teensy kick " TEENSYKICK_VERSION "\r\n\r\n");
	dac.enable();
	dac.lineOutLevel( 14 );
}

void loop()
{
	static bool run = true, levelHigh = true;

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
			dbg(" isr=%4lu %5lu %3lu\r\n", interrupts_delta,
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
		case 'b':
#if defined(USE_SAMPLE)
#else
			dbg("drum used %u cycles\r\n", kick.cpu_cycles_total );
#endif
		break;
		case ' ':
			run = !run;
			dbg("now %s\r\n", run? "running" : "stopped");
			if (run) {
#if defined(USE_SAMPLE)
				kickSample.play(AudioSampleKick);
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
		case 'l':
			if (levelHigh) {
				dac.lineOutLevel( 28 );
			}
			else {
				dac.lineOutLevel( 14 );
			}
			levelHigh = !levelHigh;
			dbg("level now %s\r\n", levelHigh? "high" : "low");
		break;
		case 'v':
			fiprintf(stderr, "\r\nHello teensy kick " TEENSYKICK_VERSION "\r\n\r\n");
		break;
		// case 'r':
		// 	_reboot_Teensyduino_();
		// break;
		default:
			dbg_putc(incoming);
		}
	}

	usbMIDI.read();
}

void onNoteOn(byte chan, byte note, byte vel)
{
	uint32_t v = vel << 8;
	dbg("N %d on %lu\r\n", note, v);
#if defined(USE_SAMPLE)
	kickSample.play(AudioSampleKick);
#else
	kick.noteOn(v);
#endif
}

void onNoteOff(byte chan, byte note, byte vel)
{
	dbg("N %d off\r\n", note);
}
