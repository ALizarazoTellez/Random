#!/usr/bin/env python3

"""Tones.

Simple extractor of valid notes on a chord progresion.
"""

import argparse
import sys

NOTES = "C", "D", "E", "F", "G", "A", "B"


def main():
    parser = argparse.ArgumentParser(prog=sys.argv[0])
    parser.add_argument('tone')
    parser.add_argument('tones', nargs='+')
    args = parser.parse_args()

    main_tone = args.tone.upper()
    tones = args.tones

    if not is_valid_tone(main_tone):
        print(f"The tone {main_tone} is not valid.")
        exit(2)

    main_tone_notes = get_notes(main_tone)
    for tone in tones:
        tone, is_minor = get_progression_tone(main_tone, tone)
        print(tone, end='')
        if is_minor:
            print(end='m:\t')
        else:
            print(end=':\t')

        notes = []
        for note in get_notes(tone):
            if note not in main_tone_notes:
                continue

            notes.append(note)

        print(" ".join(notes))


def is_valid_tone(tone) -> bool:
    for valid_tone in NOTES:
        if tone[0] == valid_tone:
            break

    if len(tone) > 2:
        return False

    if len(tone) == 2 and tone[1] != "#":
        return False

    return True


def get_notes(tone) -> list:
    notes = [tone]

    current_note = tone
    for _ in range(2):
        current_note = next_tone(current_note)
        notes.append(current_note)

    current_note = next_semitone(current_note)
    notes.append(current_note)

    for _ in range(3):
        current_note = next_tone(current_note)
        notes.append(current_note)

    return notes


def next_semitone(tone):
    """Advances the tone two semitones."""

    match tone:
        case "C" | "D" | "F" | "G" | "A":
            return tone + "#"
        case "E": return "F"
        case "B": return "C"
        case "C#" | "D#" | "F#" | "G#" | "A#":
            return NOTES[NOTES.index(tone[0]) + 1]


def next_tone(tone): return next_semitone(next_semitone(tone))


def advance_semitones(n, tone):
    current = tone
    for _ in range(n):
        current = next_semitone(current)
    return current


def get_progression_tone(main_tone, number) -> tuple:
    minor = True
    match number.upper():
        case "I":
            n = 1
            minor = False
        case "II": n = 2
        case "III": n = 3
        case "IV":
            n = 4
            minor = False
        case "V":
            n = 5
            minor = False
        case "VI": n = 6
        case "VII": n = 7
        case "VIII": n = 8
        case _: raise ValueError("Invalid progression tone")

    return NOTES[(NOTES.index(main_tone) + n - 1) % 7], minor


if __name__ == '__main__':
    main()
