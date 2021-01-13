/* hello teensy LC
 *
 * Copyright (c) 2020 Tim Braun
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
#include <usb_dev.h>

#define dbg(...) \
	fiprintf(stderr, __VA_ARGS__)


AudioSynthWaveformSine  sine1;
AudioOutputI2S        	out;
AudioConnection         patchCord1(sine1, 0, out, 0);
AudioConnection         patchCord2(sine1, 0, out, 1);

usb_serial_class 		Serial;
elapsedMillis 			since_LED_switch, since_hello;
elapsedMillis			interrupt_time;

uint32_t	Freq = 440;
bool 		ledState = true;
uint32_t	counter, bigtime;
uint32_t	interrupts_last, interrupts_delta;

void setup()
{
	pinMode(LED_BUILTIN, OUTPUT);
	usb_init();
	AudioMemory(2);
	sine1.frequency(Freq);
	sine1.amplitude(1.0);
	dbg("Hello sine\r\n");
}

void loop()
{
	if (since_LED_switch > 500) {
		ledState = !ledState;
		digitalWriteFast(LED_BUILTIN, ledState? HIGH : LOW);
		since_LED_switch = 0;
	}
	if (since_hello >= 1000) {
		dbg(".");
		if (++counter >= 10) {
			uint32_t this_count = out.isrCount();
			interrupts_delta = this_count - interrupts_last;
			interrupts_last = this_count;
			dbg(" %5lu %5lu %03lu\r\n", interrupts_delta,
				(uint32_t )interrupt_time, bigtime++);
			interrupt_time = 0;
			counter = 0;
		}
		since_hello = 0;
	}
	while (Serial.available()) {
		int incoming = Serial.read();
		switch (incoming) {
		case 'b':
			dbg("sine used %u cycles\r\n", sine1.cpu_cycles_total );
		break;
		default:
			Serial.write((uint8_t)incoming);
		}
	}
	sine1.update();
}
