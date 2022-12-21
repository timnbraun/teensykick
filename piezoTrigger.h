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
#pragma once

class piezoTrigger
{
	// Some configuration constants
	const static uint32_t threshhold_mv = 200;	// sample has to pass this
												// value to be a trigger
	const static uint32_t holdoff_msec  = 150;	// no re-triggering before this
	const static uint32_t NUM_SAMPLES   =   3;

	uint32_t		piezoInput;
	elapsedMillis	trigger_time;
	bool			fired;

	void (*func)(uint32_t	velocity);
	uint32_t		samples[NUM_SAMPLES];

	elapsedMillis	test_time;
	bool			testing;

	uint32_t		get_sample();

	public:
		piezoTrigger(uint32_t input, void (*f)(uint32_t)) : piezoInput(input), 
			fired(false), func(f), testing(false) {};
		~piezoTrigger() {};

		void	setup();
		void	loop();
		bool	testMode(bool testMode) { testing = testMode; return testing; };
		bool	testMode() { return testing; };
};

