/*
 * analog stub for smaller teensyduino builds
 *
 * If you don't need analog support, this satisfies references in
 * pins_teensy.c for a smaller binary image.
 *
 * Copyright (c) 2021 Tim Braun <tim@tim-braun.com>
 *
 * MIT License
 */

#include <core_pins.h>

#ifdef __cplusplus
extern "C" {
#endif
void analog_init(void)
{
}

void analogWriteDAC0(int val)
{
}

#ifdef __cplusplus
}
#endif
