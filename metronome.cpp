/* teensy metronome
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

#include <Audio.h>
#include <Bounce.h>
#include <IntervalTimer.h>
#include <usb_dev.h>
#include "AudioSampleKiddykick.h"

#define dbg( ... ) \
	fiprintf(stderr, __VA_ARGS__ )

#define dbg_putc(c) \
	fputc((c), stderr)

#define printf( ... ) \
	fiprintf(stdout, __VA_ARGS__ )

class Metronome {
public:
	Metronome() { running = false; };
	~Metronome() { if (running) stop(); };
	static void onTick();
	void start(uint32_t bpdm = 1200)
	{
		dbg("Starting metronome at %lu bpdm, beat time is %lu usec\n", bpdm,
			(1000000 * 600) / bpdm );
		if (bpdm > 0 && bpdm < 4000)
			beatTimer.begin(onTick, (1000000 * 600) / bpdm );
		this->bpdm = bpdm;
	}
	void stop()
	{
		beatTimer.end();
	}
private:
	bool 			running;
	uint32_t 		bpdm;	// beats per deci-minute
	IntervalTimer	beatTimer;
};

void onTick();
void onNoteOn(byte chan, byte note, byte vel);
void onNoteOff(byte chan, byte note, byte vel);

Metronome				metronome;
AudioControlSGTL5000	dac;
AudioSynthSimpleDrum	click;
AudioPlayMemory			kickSample;
AudioOutputI2S        	out;
// AudioConnection         patchCord1(click, 0, out, 0);
AudioConnection         patchCord1(kickSample, 0, out, 0);
AudioConnection         patchCord2(kickSample, 0, out, 1);
Bounce					tempo = Bounce(0, 5);

usb_serial_class 		Serial;
elapsedMillis 			since_LED_switch, since_hello;
elapsedMillis			interrupt_time;

uint32_t		counter, bigtime;
uint32_t		interrupts_last, interrupts_delta;
uint32_t 		tap_times[5], tap_count;


void setup()
{
	pinMode(LED_BUILTIN, OUTPUT);
	pinMode(0, INPUT_PULLUP);
	usb_init();

	usbMIDI.setHandleNoteOn(onNoteOn);
	usbMIDI.setHandleNoteOff(onNoteOff);

	delay(1000);
	AudioMemory(2);
	click.frequency(80);
	click.length(200);
	click.secondMix(0.25);
	click.pitchMod(0x2f0); // 0x200 is no mod...
	printf("\nHello teensy click " TEENSYKICK_VERSION "\n\n");
	dac.enable();
	dac.lineOutLevel( 14 );
}

void loop()
{
	static bool run = true, levelHigh = true, metronome_running = false;

	if (since_LED_switch > 500) {
		if (!metronome_running)
			digitalToggleFast(LED_BUILTIN);
		since_LED_switch = 0;
	}
	if (since_hello >= 1000) {
		// dbg(".");
		if (++counter >= 10) {
			uint32_t this_count = out.isrCount();
			interrupts_delta = this_count - interrupts_last;
			interrupts_last = this_count;
			// dbg(" isr=%4lu %5lu %3lu\n", interrupts_delta,
			// 	(uint32_t)interrupt_time, bigtime);
			interrupt_time = 0;
			counter = 0;
			bigtime++;
		}
		since_hello = 0;
	}
	while (Serial.available()) {
		int incoming = Serial.read();
		switch (incoming) {
		case 'b':
			dbg("drum used %u cycles\n", click.cpu_cycles_total );
		break;
		case ' ':
			break;
		case 'r':
		case 'g':
			run = !run;
			dbg("now %s\n", run? "running" : "stopped");
			if (run) {
				click.noteOn();
			}
			else {
				click.noteOn(0x6000);
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
			dbg("level now %s\n", levelHigh? "high" : "low");
		break;
		case 'm':
			if (metronome_running) {
				dbg("stopping metronome\n");
				metronome.stop();
			}
			else {
				dbg("starting metronome\n");
				metronome.start(1000);
			}
			metronome_running = !metronome_running;
			break;
		case 'v':
			printf("\nteensy click " TEENSYKICK_VERSION "\n\n");
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

	usbMIDI.read();

	tempo.update();
	if (tempo.fallingEdge()) {
		bool clear_times = false;

		// check how long since last tap 
		// if too long, zero out all tap times
		if ((millis() - tap_times[(tap_count-1) % 5]) > 2000) {
			// we don't go as slow as 30 bpm
			clear_times = true;
		}

		tap_times[tap_count++] = millis();
		if (tap_count == 4) {
			tap_count = 0;
		}

		if (clear_times) {
			for (int i = 0; i < 4; i++) {
				tap_times[tap_count++] = 0;
				if (tap_count == 4)
					tap_count = 0;
			}
		}
		else {
			// update tempo as average of tap times
			uint32_t delta = 0, taps = 0, tempo = 0;

			for (int i = 0; i < 4; i++) {
				if ((tap_times[i] > 0) &&
						(tap_times[(i-1) % 5] > 0) &&
						(tap_times[i] > tap_times[(i-1) % 5])) {
					delta += (tap_times[i] - tap_times[(i-1) % 5]);
					taps++;
				}
			}
			if (taps > 0) {
				delta = delta / taps;
			}

			if (delta > 0) {
				tempo = 60000 / delta;
			}

			dbg("delta is %lu, %lu bpdm\n", delta, tempo);
		}
	}
}

void Metronome::onTick()
{
	static uint8_t beat = 1;

	digitalToggleFast(LED_BUILTIN);

	dbg_putc(beat + '0');
	if (beat++ == 1) {
		// click.noteOn(127 << 8);
		kickSample.play(AudioSampleKiddykick);
	}
	else {
		// click.noteOn(101 << 8);
		kickSample.play(AudioSampleKiddykick);
		if (beat > 4)
			beat = 1;
	}
}

void onNoteOn(byte chan, byte note, byte vel)
{
	uint32_t v = vel << 8;
	dbg("N %d on %lu\n", note, v);
	click.noteOn(v);
	kickSample.play(AudioSampleKiddykick);
}

void onNoteOff(byte chan, byte note, byte vel)
{
	dbg("N %d off\n", note);
}
