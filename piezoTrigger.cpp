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
#include <elapsedMillis.h>
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
	static uint32_t sample_count = 0;
	uint32_t t_mv;

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
	if ((t_mv > threshhold_mv) && !fired) {

		if (sample_count < NUM_SAMPLES) {
			// printf( "sample = %5lu, %2lu\n", t_mv, sample_count );
			samples[sample_count++] = t_mv;
		}

		if (sample_count == NUM_SAMPLES) {

			uint32_t trig = 0;
			for (unsigned i = 0; i < NUM_SAMPLES; i++)
				trig += samples[i];
			trig /= NUM_SAMPLES;

			uint32_t slope = (samples[NUM_SAMPLES - 1] > samples[0]?
				samples[NUM_SAMPLES - 1] - samples[0] : 0) / 2;

			trig += slope;

			// printf( "trigger = %5lu, %4ld %ld\n", t_mv, trig, slope );

			func( trig );
			fired = true;
			trigger_time = 0;
		}
	}

	else if ((t_mv < threshhold_mv) && (trigger_time > holdoff_msec)) {
		fired = false;
		sample_count = 0;
	}

	if (testing) {
		if (test_time > 1000) {
			printf( "t_mv = %5lu\n", t_mv);
			test_time = 0;
		}
	}
}
