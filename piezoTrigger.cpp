////////////////////////////
///
/// piezoTrigger class
///
///  Watch an analog input
///  Calculate velocity value based on 3 samples
///
///  (y3 + y2 + y1) / 3 + (y3 - y1) / 2
///
///  Call a callback function when a threshold is passed
///
///
///
////////////////////////////

#include <cstdint>
#include <Arduino.h>
#include "piezoTrigger.h"

#define ANALOG_DEFAULT_REFERENCE 1000

void piezoTrigger::setup()
{
	// Set up builtin adc for pizeo input
	analog_init();
	analogReadResolution(12);
}

void piezoTrigger::loop()
{
	static uint32_t timeStamp = 0;
	static uint32_t sample_count = 0;
	uint32_t t_mv;

	uint32_t now = millis(), elapsed = now - timeStamp;

	t_mv = analogRead(piezoInput) * 3300 * 
		(ANALOG_DEFAULT_REFERENCE / 1000.0) / 4095;

	////
	// Experiments to find a way to get a velocity mapped to the
	// incoming piezo signal. Looks like the first 3 samples
	// above a threshold at 1 msec intervals will be a good estimate.
	// Slope based on 3 samples = avg( slope1, slope 2 )
	//
	//  (y2 - y1) + (y3 - y2) / 2 = (y3 - y1) / 2
	//
	// It might be useful to add the mean value as a factor...
	//
	//  (y3 + y2 + y1) / 3 + (y3 - y1) / 2
	//
	////
	if ((t_mv > 400) && ((sample_count < 1) || (elapsed > 10))) {
		sample_count++;
		timeStamp = now;
		printf( "trigger = %5lu\n", t_mv);
		// if (sample_count == 1) {
			func( t_mv );
		// }
	}

	if (testing) {
		if (elapsed > 1000) {
			printf( "t_mv = %5lu\n", t_mv);
			sample_count = 0;
			timeStamp = now;
		}
	}
}
