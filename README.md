# teensykick
Experiments and demos using teensy-duino library and Makefile / ubuntu tools.

Target device is the teensy LC. This device have very limited resources so experiments are required to get
desired functions to fit together.

hello_lc - blink the led
hello_midi - provide a midi USB endpoint and listen on the incoming notes.
hello_sine - generate a sine wave on the i2s output. Not initializing the SGTL5000 here.
kick - generate a sine wave on the i2s o/p, initializing the SGTL5000 on the Audio Adapter Board.
