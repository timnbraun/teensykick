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


AudioSynthWaveformSine   sine1;
AudioOutputI2S        	 out;
AudioConnection          patchCord1(sine1, 0, out, 0);
AudioConnection          patchCord2(sine1, 0, out, 1);

usb_serial_class Serial;
elapsedMillis since_LED_switch;

uint32_t Freq = 440;

void setup()
{
	pinMode(LED_BUILTIN, OUTPUT);
	usb_init();
	AudioMemory(12);
	sine1.frequency(Freq);
	sine1.amplitude(1.0);
	Serial.write("Hello sine\r\n");
}

bool ledState = true;

void loop()
{
	if (since_LED_switch > 500) {
		ledState = !ledState;
		digitalWriteFast(LED_BUILTIN, ledState? HIGH : LOW);
		since_LED_switch = 0;
	}
}
