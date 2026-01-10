#!/usr/bin/env python3
"""
PC Speaker (DP) to DMX converter module for SRB2 Doom port.
Converts PC speaker sound effects (DP prefix) to standard DMX format.
Improvements:
 - Ensures `struct` is imported (fixes NameError).
 - Run-length compresses DP values so repeated ticks become continuous tones.
 - Uses correct quarter-tone frequency formula (value 33 == A4 == 440 Hz).
 - Keeps phase continuity across a tone to avoid buzzy artifacts.
 - Uses a reasonable amplitude (no clipping).
 - Produces proper DMX header + 16-byte pad before and after samples.
"""

import math
import struct
from pathlib import Path

# Constants
PC_TICK_RATE = 140.0  # DP tick rate in Hz
DEFAULT_DMX_SAMPLE_RATE = 11025
DMX_FORMAT_NUM = 3
DMX_PAD_BYTES = 16
DEFAULT_AMPLITUDE = 40  # reasonable amplitude to avoid clipping

def get_frequency_for_note(v):
    """Return frequency (Hz) for DP value v (0..127). 0 -> silence."""
    if v <= 0:
        return 0.0
    # quartertone steps: 24 quartertones per octave -> 2^(1/24)
    # reference: value 33 == A4 == 440 Hz
    return 440.0 * (2.0 ** ((v - 33) / 24.0))

def rle_dp_values(note_values):
    """Run-length encode a list of DP byte values into (value, run_length_in_ticks)."""
    if not note_values:
        return []
    runs = []
    current = note_values[0]
    length = 1
    for n in note_values[1:]:
        if n == current:
            length += 1
        else:
            runs.append((current, length))
            current = n
            length = 1
    runs.append((current, length))
    return runs

def generate_run_samples(freq_hz, run_ticks, sample_rate=DEFAULT_DMX_SAMPLE_RATE, amplitude=DEFAULT_AMPLITUDE, phase_start=0.0):
    """
    Generate samples for a run of `run_ticks` DP ticks (each tick = 1/140 s).
    Returns (samples_list, phase_end)
    Samples are unsigned 8-bit centered at 128 (0..255).
    """
    duration_seconds = run_ticks / PC_TICK_RATE
    num_samples = max(0, int(round(sample_rate * duration_seconds)))
    samples = []
    phase = phase_start

    if freq_hz <= 0.0 or num_samples == 0:
        # silence - generate mid-level samples
        return ([128] * num_samples, phase)  # phase unchanged

    phase_inc = 2.0 * math.pi * freq_hz / sample_rate

    for i in range(num_samples):
        """
        Uncomment this if you REALLY want sine waves
        val = 128 + int(round(amplitude * math.sin(phase)))
        # clamp
        if val < 0:
            val = 0
        elif val > 255:
            val = 255
        samples.append(val)
        phase += phase_inc
        """
        val = 128 + (amplitude if math.sin(phase) >= 0 else -amplitude)
        samples.append(val)
        phase = (phase + phase_inc) % (2 * math.pi)

    # keep phase in range to avoid overflow after many runs
    phase = phase % (2.0 * math.pi)
    return (samples, phase)

def convert_pcspeaker_to_dmx(dp_data, sample_rate=DEFAULT_DMX_SAMPLE_RATE, amplitude=DEFAULT_AMPLITUDE):
    """
    Convert PC speaker (DP format) data to DMX format bytes.

    dp_data: bytes-like object containing DP lump
    sample_rate: desired DMX sample rate (11025 typical)
    amplitude: amplitude for generated sine (recommended ~30-50)
    """
    if len(dp_data) < 4:
        raise ValueError("DP data too short")

    # Parse DP header
    format_num = struct.unpack_from('<H', dp_data, 0)[0]
    if format_num != 0:
        raise ValueError(f"Expected format 0 for PC speaker, got {format_num}")

    num_samples = struct.unpack_from('<H', dp_data, 2)[0]

    if len(dp_data) < 4 + num_samples:
        raise ValueError(f"DP data incomplete: header says {num_samples} bytes but file has {len(dp_data)-4}")

    note_values = list(dp_data[4:4 + num_samples])

    # Run-length encode consecutive identical values into runs of ticks
    runs = rle_dp_values(note_values)

    # Generate audio samples for each run. Keep phase continuity between runs of the same frequency.
    all_samples = []
    phase = 0.0

    for (note_value, run_length) in runs:
        freq = get_frequency_for_note(note_value)
        samples, phase = generate_run_samples(freq, run_length, sample_rate=sample_rate, amplitude=amplitude, phase_start=phase)
        all_samples.extend(samples)

    if not all_samples:
        # zero-length audio -> produce one silence sample so pads can be filled
        all_samples = [128]

    # Build DMX data
    dmx_data = bytearray()

    # Header: format (uint16), sample rate (uint16), number of samples + 32 (uint32 LE)
    num_dmx_samples = len(all_samples)
    total_samples_with_padding = num_dmx_samples + (DMX_PAD_BYTES * 2)  # +32

    dmx_data.extend(struct.pack('<H', DMX_FORMAT_NUM))
    dmx_data.extend(struct.pack('<H', int(sample_rate)))
    dmx_data.extend(struct.pack('<I', total_samples_with_padding))

    # 16 pad bytes before samples — filled with first actual sample value
    first_sample = all_samples[0]
    dmx_data.extend(bytes([first_sample] * DMX_PAD_BYTES))

    # Actual samples
    dmx_data.extend(bytes(all_samples))

    # 16 pad bytes after samples — filled with last actual sample value
    last_sample = all_samples[-1]
    dmx_data.extend(bytes([last_sample] * DMX_PAD_BYTES))

    return bytes(dmx_data)

def replace_ds_with_dp(wad, sample_rate=DEFAULT_DMX_SAMPLE_RATE):
    """
    Replace DS sound lumps with their DP (PC speaker) equivalents if available.

    wad: an object with dict-like wad.sounds mapping lump names -> Lump objects
    Returns number of converted sounds.
    """
    converted = 0

    # Find all DS sounds
    ds_sounds = [name for name in list(wad.sounds.keys()) if name.startswith('DS')]

    for ds_name in ds_sounds:
        dp_name = 'DP' + ds_name[2:]
        if dp_name in wad.sounds:
            try:
                dp_data = wad.sounds[dp_name].data
                dmx_data = convert_pcspeaker_to_dmx(dp_data, sample_rate=sample_rate)
                # Replace lump
                from omg import Lump
                wad.sounds[ds_name] = Lump(dmx_data)
                converted += 1
                print(f"  Converted {dp_name} -> {ds_name} (PC speaker)")
            except Exception as e:
                print(f"  Error converting {dp_name}: {e}")

    return converted