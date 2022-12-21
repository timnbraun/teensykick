/* hello adc : teensy LC
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

#include <Arduino.h>
#include <usb_dev.h>
#include <ADC.h>

#define dbg(...) \
	fiprintf(stderr, __VA_ARGS__)
#define dbg_putc(c) \
	fputc((c), stderr)

void onNoteOn(byte chan, byte note, byte vel);
void onNoteOff(byte chan, byte note, byte vel);

// AudioControlSGTL5000	dac;
// AudioSynthWaveformSine  sine1;
// AudioOutputI2S        	out;
// AudioConnection         patchCord1(sine1, 0, out, 0);
// AudioConnection         patchCord2(sine1, 0, out, 1);

usb_serial_class 		Serial;
elapsedMillis 			since_LED_switch, since_hello, since_threshold;

uint32_t	counter, bigtime;
uint32_t	interrupts_last, interrupts_delta;

ADC adc;

void setup()
{
	pinMode(LED_BUILTIN, OUTPUT);
	usb_init();
	delay(100);

	usbMIDI.setHandleNoteOn(onNoteOn);
	usbMIDI.setHandleNoteOff(onNoteOff);

	delay(2000);

	// pinMode( A0, INPUT_DISABLE );
	// pinMode( A1, INPUT_PULLDOWN );
	// pinMode( A2, INPUT_PULLDOWN );
	// pinMode( A3, INPUT_PULLDOWN );

	// pinMode( A4, INPUT_PULLDOWN );
	// pinMode( A5, INPUT_PULLDOWN );
	// pinMode( A6, INPUT_PULLDOWN );
	pinMode( A7, INPUT_DISABLE );
	delay(1000);
	dbg("pin mode init\n");

	adc.adc0->setResolution( 12 );
	adc.adc0->setConversionSpeed( ADC_CONVERSION_SPEED::LOW_SPEED );
	adc.adc0->setSamplingSpeed( ADC_SAMPLING_SPEED::MED_SPEED );
	dbg("adc init\n");

	delay(100);
	dbg("\nHello adc " TEENSYKICK_VERSION " " BUILD_DATE "\n\n");
}

bool faster, threshold_check, pause;

void loop()
{
	if (since_LED_switch > 500) {
		digitalToggleFast(LED_BUILTIN);
		since_LED_switch = 0;
	}

	if (!pause &&
		(since_hello > 5000 ||
		(since_hello > 1000 && faster))) {

		/*
		printf("0x%03x 0x%03x 0x%03x 0x%03x - ",
			adc.adc0->analogRead( A0 ), 
			adc.adc0->analogRead( A1 ), 
			adc.adc0->analogRead( A6 ), 
			adc.adc0->analogRead( A7 ) ); 
		 */
		printf("0x%03x - ",
			adc.adc0->analogRead( A7 ) ); 

		delayMicroseconds(200);
		/*
		printf("0x%03x 0x%03x 0x%03x 0x%03x - ",
			adc.adc0->analogRead( A0 ), 
			adc.adc0->analogRead( A1 ), 
			adc.adc0->analogRead( A6 ), 
			adc.adc0->analogRead( A7 ) ); 
		 */
		printf("0x%03x - ",
			adc.adc0->analogRead( A7 ) ); 

		delayMicroseconds(200);
		/*
		printf("0x%03x 0x%03x 0x%03x 0x%03x - ",
			adc.adc0->analogRead( A0 ), 
			adc.adc0->analogRead( A1 ), 
			adc.adc0->analogRead( A6 ), 
			adc.adc0->analogRead( A7 ) ); 
		printf("0x%03x 0x%03x 0x%03x 0x%03x\n",
			adc.adc0->analogRead( A8 ), 
			adc.adc0->analogRead( A9 ), 
			adc.adc0->analogRead( A10 ), 
			adc.adc0->analogRead( A11 ) ); 
		 */
		printf("0x%03x - ",
			adc.adc0->analogRead( A7 ) ); 
		printf("\n");

		since_hello = 0;
	}

	int val;
	if (threshold_check && (since_threshold > 100) &&
		(val = adc.adc0->analogRead( A7 )) > 0x40 ) {
		printf("trigger! 0x%03x\n", val );
		since_threshold = 0;
	}

	while (Serial.available()) {
		int incoming = Serial.read();
		switch (incoming) {

		case 'f':
			faster = !faster;
			printf("%s\n", faster? "faster" : "slower");
		break;

		case 't':
			threshold_check = !threshold_check;
			printf("threshold %s\n", threshold_check? "checked" : "not checked");
		break;

		case 'p':
			pause = !pause;
			printf("sampling %s\n", pause? "paused" : "running");
		break;

		case 'v':
			printf("hello_adc " TEENSYKICK_VERSION "\n");
		break;
		default:
			dbg_putc(incoming);
		}
	}

	usbMIDI.read();
}

void onNoteOn(byte chan, byte note, byte vel)
{
	dbg("N %d on\r\n", note);
}

void onNoteOff(byte chan, byte note, byte vel)
{
	dbg("N %d off\r\n", note);
}
