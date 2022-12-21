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
#include <ADC.h>
#include "piezoTrigger.h"

// #undef dbg
// #define dbg( ... ) {}

#if defined(__MKL26Z64__)
#define ANALOG_DEFAULT_REFERENCE 3300
#endif

ADC adc;

inline uint32_t piezoTrigger::get_sample()
{
	return adc.adc0->analogRead(piezoInput) * 1000.0f *
		(ANALOG_DEFAULT_REFERENCE / 1000.0) / 4095.0f;
}

void piezoTrigger::setup()
{
	// Set up builtin adc for piezo input
	pinMode( piezoInput, INPUT_DISABLE );
	adc.adc0->setResolution( 12 );
	adc.adc0->setConversionSpeed( ADC_CONVERSION_SPEED::MED_SPEED );
	adc.adc0->setSamplingSpeed( ADC_SAMPLING_SPEED::MED_SPEED );

	dbg("piezoTrigger on pin %lu\n", piezoInput);
}

void piezoTrigger::loop()
{
	static uint32_t sample_count = 0;
	uint32_t t_mv;

	t_mv = get_sample();

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
			dbg( "sample = %5lu, %2lu\n", t_mv, sample_count );
			samples[sample_count++] = t_mv;
		}

		for (; sample_count < NUM_SAMPLES; sample_count++) {
			delayMicroseconds(200);
			samples[sample_count] = get_sample();
			dbg( "sample = %5lu\n", get_sample() );
		}

		if (sample_count == NUM_SAMPLES) {

			uint32_t trig = 0;
			for (unsigned i = 0; i < NUM_SAMPLES; i++)
				trig += samples[i];
			trig /= NUM_SAMPLES;

			uint32_t slope = (samples[NUM_SAMPLES - 1] > samples[0]?
				samples[NUM_SAMPLES - 1] - samples[0] : 0) / 2;

			trig += slope;

			dbg( "trigger = %5lu, %4ld %ld\n", t_mv, trig, slope );

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
			dbg( "t_mv = %5lu\n", t_mv);
			test_time = 0;

			sample_count = NUM_SAMPLES + 1;
		}
	}
}
