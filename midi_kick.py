#!/usr/bin/env python
""" midi_kick.py

example of midi output.

By default it runs the output example.

python midi_kick.py --find
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
		from pygame.midi import time as Time

tempo = 120.0
# tempo = 1.0 / (10.0 * 60.0)

def print_device_info():
    init()
    _print_device_info()
    quit()


def _print_device_info():
    for i in range(get_count()):
        r = get_device_info(i)
        (interf, name, input, output, opened) = r
        name = "'" + str(name, encoding='utf-8').strip() + "'"

        in_out = ""
        if input:
            in_out = "(input)"
        if output:
            in_out = "(output)"

        print(
            "%2i: %-19s - opened :%s:  %s"
            % (i, name, opened, in_out)
        )

def find_id(target='Teensy MIDI'):
	init()
	for d in range( get_count() ):
		(interf, name, input, out, op) = get_device_info(d)
		name = str(object=name, encoding='utf-8')
		if (name.startswith( target ) and out == 1):
			return d
	quit()
	return None

def device_name(id):
	(interf, name, inp, outp, op) = get_device_info(id)
	return str(object=name, encoding='utf-8')

def kickit():
	port = find_id()
	if (port):
		print("kick on", device_name(port))
		midi_out = Output(port, 0)
		# Midi raw channel 9 is percussion, most people call it channel 10
		# pygame passes channel number verbatim
		midi_out.note_on(36, 101, channel=9)
		sleep(0.05)
		midi_out.note_off(36, channel=9)
		quit()
	else:
		print("no teensy MIDI available")

def sendit( it ):
	port = find_id()
	if (port):
		midi_out = Output(port, 0)
		midi_out.write_short( it )
	else:
		print("no teensy MIDI available")

def clockit():
	sendit( 0xf8 )

def stopit():
	sendit( 0xfc )

def startit():
	sendit( 0xfa )

def sendtempo( bpm ):
	if bpm > 0:
		t = (60000/24) / bpm
	else:
		stopit()
		quit()
	port = find_id()
	if not port:
		print("no teensy MIDI available")
	midi_out = Output(port, 0)
	# now = Time() + 3
	# midi_out.write( [[[ 0xf8 ], now], [[ 0xf8 ], now + t]] )
	# midi_out.write( [[[ 0xf8 ], now], [[ 0xf8 ], now + t]] )
	# print("t=", t, "now=", now)
	midi_out.write_short( 0xf8 )
	sleep( t/1000 )
	midi_out.write_short( 0xf8 )

def exit_handler(signum, frame):
	print('\nThank you and good-night!\n')
	exit(0)

def loopit():
	signal(SIGINT, exit_handler)
	while True:
		kickit()
		sleep(5.0)


def usage():
    print("--find  : just check for teensy MIDI device")
    print("--kick  : send kick note on / off")
    print("--list  : list available midi devices")
    print("--loop  : loop, sending kick every 5 sec")
    print("--start : send start to teensy MIDI device")
    print("--stop  : send stop to teensy MIDI device")
    print("--tempo n : send two clock messages based on tempo")


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
    elif "--start" in sys.argv or "-s" in sys.argv:
        startit()
    elif "--stop" in sys.argv or "-q" in sys.argv:
        stopit()
    elif "--tempo" in sys.argv or "-t" in sys.argv:
        print("setting tempo to {0:6.3f} bpm".format( tempo ))
        sendtempo( tempo )
    else:
        usage()
