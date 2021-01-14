#!/usr/bin/env python
""" midi_kick.py

example of midi output.

By default it runs the output example.

python midi_kick.py --kick
python midi_kick.py --loop
python midi_kick.py --list

"""

import sys
import os
from signal import signal, SIGINT
from time import sleep
from contextlib import redirect_stdout

# Suppress a silly banner that pygame sends to stdout on load
with open(os.devnull, 'w') as devnull:
	with redirect_stdout(devnull):
		from pygame.midi import init, quit, get_count, get_device_info, Output


def print_device_info():
    init()
    _print_device_info()
    quit()


def _print_device_info():
    for i in range(get_count()):
        r = get_device_info(i)
        (interf, name, input, output, opened) = r

        in_out = ""
        if input:
            in_out = "(input)"
        if output:
            in_out = "(output)"

        print(
            "%2i: '%-19s', opened :%s:  %s"
            % (i, 
				str(name, encoding='utf-8'), opened, in_out)
        )

def find_id(target='Teensy MIDI'):
	init()
	for d in range( get_count() ):
		info = get_device_info(d)
		(interf, name, input, out, op) = get_device_info(d)
		name = str(object=name, encoding='utf-8')
		if (name == 'Teensy MIDI' and out == 1):
			return d
	quit()
	return None


def kickit():
	port = find_id()
	if (port):
		print("kick on id", port)
		midi_out = Output(port, 0)
		midi_out.note_on(36, 101, channel=10)
		sleep(0.05)
		midi_out.note_off(36, channel=10)
		quit()
	else:
		print("no teensy MIDI available")

def exit_handler(signum, frame):
	print('\nThank you and good-night!\n')
	exit(0)

def loopit():
	signal(SIGINT, exit_handler)
	while True:
		kickit()
		sleep(5.0)


def usage():
    print("--kick : send kick note on / off")
    print("--loop : loop, sending kick every 5 sec")
    print("--list : list available midi devices")
    print("--find : just check for teensy MIDI device")


if __name__ == "__main__":

    if "--find" in sys.argv or "-f" in sys.argv:
        teensy = find_id()
        if (teensy):
            print("teensy MIDI is device", find_id())
        else:
            print("teensy MIDI is not available")
    elif "--kick" in sys.argv or "-k" in sys.argv:
        kickit()
    elif "--list" in sys.argv or "-l" in sys.argv:
        print_device_info()
    elif "--loop" in sys.argv or "-o" in sys.argv:
        loopit()
    else:
        usage()
