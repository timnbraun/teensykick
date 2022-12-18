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
	uint32_t	piezoInput;
	uint32_t	timeStamp;
	bool		testing;
	void		(*func)(uint32_t velocity);

	public:
		piezoTrigger(uint32_t input, void (*f)(uint32_t)) : piezoInput(input), 
			timeStamp(0), testing(false), func(f) {};
		~piezoTrigger() {};

		void	setup();
		void	loop();
		bool	testMode(bool testMode) { testing = testMode; return testing; };
		bool	testMode() { return testing; };
};

