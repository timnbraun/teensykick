/*
 * _write for usb_serial
 *
 * Resolves hanging library reference for specs=nano.specs building.
 *
 * Copyright (c) 2021 Tim Braun <tim@tim-braun.com>
 *
 * MIT License
 */

#include <usb_serial.h>

extern "C" {

__attribute__((weak)) int _write(int file, char *ptr, int len)
{
	if (ptr[len-1] == '\n') {
		usb_serial_write((const void *)ptr, len-1);
		usb_serial_write((const void *)"\r\n", 2);
		return len;
	}
	usb_serial_write((const void *)ptr, len);
	return len;
}

}
