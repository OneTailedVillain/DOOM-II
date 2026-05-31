"""
MIDI and MUS conversion functions.
"""

import struct
import os
import tempfile
from subprocess import Popen, PIPE
from modules.utils import find_fluidsynth, find_ffmpeg, find_soundfont

# Most idTech games that we care about only use 140 TPS!
MUS_TICKS_PER_SECOND = 140

# We use PPQN equal to the MUS tick rate so each MUS tick becomes exactly one MIDI tick.
MIDI_PPQN = MUS_TICKS_PER_SECOND

# MUS logical channels 0..14 can map to these MIDI channels.
# Channel 9 is reserved for percussion.
AVAILABLE_MIDI_CHANNELS = [0, 1, 2, 3, 4, 5, 6, 7, 8, 10, 11, 12, 13, 14, 15]

# MUS controller numbers do not match MIDI controller numbers directly,
# MUS 0 = instrument/program change, so it gets handled outside of here.
MUS_TO_MIDI_CC = {
    1: 0,    # bank select MSB
    2: 1,    # modulation
    3: 7,    # volume
    4: 10,   # pan
    5: 11,   # expression
    6: 91,   # reverb depth
    7: 93,   # chorus depth
    8: 64,   # sustain pedal
    9: 67,   # soft pedal
}

def to_varlen(value):
    """Convert an integer to a variable-length quantity (MIDI format)."""
    if value == 0:
        return bytes([0])
    chunks = []
    while value:
        chunks.append(value & 0x7F)
        value >>= 7
    chunks.reverse()
    result = bytearray()
    for i in range(len(chunks)):
        if i < len(chunks) - 1:
            result.append(chunks[i] | 0x80)
        else:
            result.append(chunks[i])
    return bytes(result)

def read_varlen(data, offset):
    """Read a variable-length quantity from the data starting at offset."""
    value = 0
    while offset < len(data):
        b = data[offset]
        offset += 1
        value = (value << 7) | (b & 0x7F)
        if not (b & 0x80):
            break
    return value, offset

def _midi_setup_events(midi_channel):
    """Initial controller setup for a newly allocated MIDI channel."""
    # Set pitch bend sensitivity to 2 semitones
    return [
        [0xB0 | midi_channel, 101, 0],  # RPN MSB: pitch bend sensitivity
        [0xB0 | midi_channel, 100, 0],  # RPN LSB
        [0xB0 | midi_channel, 6, 2],    # Data Entry MSB: 2 semitones
        [0xB0 | midi_channel, 38, 0],   # Data Entry LSB
    ]

def _allocate_midi_channel(mus_channel, channel_map, next_free_index):
    """
    Map a MUS channel to a MIDI channel.
    MUS percussion channel 15 always maps to MIDI channel 9.
    Other MUS channels are assigned the next free non-percussion MIDI channel.
    """
    if mus_channel == 15:
        return 9, next_free_index, []

    if mus_channel in channel_map:
        return channel_map[mus_channel], next_free_index, []

    if next_free_index >= len(AVAILABLE_MIDI_CHANNELS):
        raise ValueError("MUS file uses more than 15 non-percussion channels")

    midi_channel = AVAILABLE_MIDI_CHANNELS[next_free_index]
    channel_map[mus_channel] = midi_channel
    next_free_index += 1
    return midi_channel, next_free_index, _midi_setup_events(midi_channel)

def mus_to_midi(mus_data):
    """Convert MUS file data to MIDI file data."""
    if len(mus_data) < 16 or mus_data[0:4] != b'MUS\x1a':
        raise ValueError("Invalid MUS file: signature mismatch")

    score_len = struct.unpack('<H', mus_data[4:6])[0]
    score_start = struct.unpack('<H', mus_data[6:8])[0]
    primary_channels = struct.unpack('<H', mus_data[8:10])[0]
    secondary_channels = struct.unpack('<H', mus_data[10:12])[0]
    instr_cnt = struct.unpack('<H', mus_data[12:14])[0]
    _dummy = struct.unpack('<H', mus_data[14:16])[0]

    if score_start < 16 or score_start > len(mus_data):
        raise ValueError("Invalid MUS file: scoreStart out of range")
    if score_start + score_len > len(mus_data):
        raise ValueError("Invalid MUS file: scoreLen out of range")
    if score_start < 16 + (instr_cnt * 2):
        raise ValueError("Invalid MUS file: instrument table overruns scoreStart")

    # The instrument list is parsed for validation only; the converter does not need it.
    instruments = []
    pos = 16
    for _ in range(instr_cnt):
        instruments.append(struct.unpack('<H', mus_data[pos:pos + 2])[0])
        pos += 2

    song_data = mus_data[score_start:score_start + score_len]

    events = []

    tempo_usec_per_qn = round(1_000_000 * MIDI_PPQN / MUS_TICKS_PER_SECOND)
    events.append((0, [0xFF, 0x51, 0x03,
                      (tempo_usec_per_qn >> 16) & 0xFF,
                      (tempo_usec_per_qn >> 8) & 0xFF,
                      tempo_usec_per_qn & 0xFF]))

    last_note_volume = [100] * 16
    mus_to_midi_channel = {}
    next_free_index = 0

    current_time = 0
    index = 0
    size = len(song_data)

    while index < size:
        event_byte = song_data[index]
        index += 1

        last_flag = event_byte & 0x80
        event_type = (event_byte >> 4) & 0x07
        mus_channel = event_byte & 0x0F

        midi_channel, next_free_index, setup_events = _allocate_midi_channel(
            mus_channel, mus_to_midi_channel, next_free_index
        )
        for ev in setup_events:
            events.append((current_time, ev))

        if event_type == 0:
            # Release note
            if index >= size:
                raise ValueError("Truncated MUS note-off event")
            note = song_data[index] & 0x7F
            index += 1
            events.append((current_time, [0x80 | midi_channel, note, 64]))

        elif event_type == 1:
            # Play note
            if index >= size:
                raise ValueError("Truncated MUS note-on event")
            note_byte = song_data[index]
            index += 1
            has_volume = note_byte & 0x80
            note = note_byte & 0x7F

            if has_volume:
                if index >= size:
                    raise ValueError("Truncated MUS note-on volume")
                velocity = song_data[index] & 0x7F
                index += 1
                last_note_volume[mus_channel] = velocity
            else:
                velocity = last_note_volume[mus_channel]

            events.append((current_time, [0x90 | midi_channel, note, velocity]))

        elif event_type == 2:
            # Pitch wheel
            if index >= size:
                raise ValueError("Truncated MUS pitch-wheel event")
            bend_byte = song_data[index]
            index += 1

            # MUS uses 0..255 with 128 as center.
            # Scale to MIDI's 14-bit pitch bend range with center at 8192.
            bend_value = round(bend_byte * 16383 / 255)
            bend_value = max(0, min(16383, bend_value))
            lsb = bend_value & 0x7F
            msb = (bend_value >> 7) & 0x7F
            events.append((current_time, [0xE0 | midi_channel, lsb, msb]))

        elif event_type == 3:
            # System event (valueless controller)
            if index >= size:
                raise ValueError("Truncated MUS system event")
            sys_byte = song_data[index]
            index += 1

            controller = sys_byte & 0x7F
            midi_cc_map = {
                10: 120,  # all sounds off
                11: 123,  # all notes off
                12: 126,  # mono
                13: 127,  # poly
                14: 121,  # reset all controllers
            }
            if controller in midi_cc_map:
                events.append((current_time, [0xB0 | midi_channel, midi_cc_map[controller], 0]))

        elif event_type == 4:
            # Change controller
            if index + 1 > size:
                raise ValueError("Truncated MUS controller event")
            ctrl_num = song_data[index] & 0x7F
            val = song_data[index + 1] & 0x7F
            index += 2

            if ctrl_num == 0:
                # MUS instrument change -> MIDI program change
                if midi_channel != 9:
                    events.append((current_time, [0xC0 | midi_channel, val]))
            elif ctrl_num in MUS_TO_MIDI_CC:
                events.append((current_time, [0xB0 | midi_channel, MUS_TO_MIDI_CC[ctrl_num], val]))

        elif event_type in (5, 7):
            # Reserved/unknown, probably just not used entirely.
            # Consume one byte conservatively so the stream stays aligned.
            if index < size:
                index += 1

        elif event_type == 6:
            # End of score
            break

        else:
            # The format only defines 0..7, but keep this defensive.
            raise ValueError(f"Unknown MUS event type: {event_type}")

        if last_flag and index < size:
            delay, index = read_varlen(song_data, index)
            current_time += delay

    events.append((current_time, [0xFF, 0x2F, 0x00]))
    events.sort(key=lambda x: x[0])

    track_data = bytearray()
    prev_time = 0
    for time, event_bytes in events:
        delta = time - prev_time
        track_data.extend(to_varlen(delta))
        track_data.extend(event_bytes)
        prev_time = time

    header = (
        b'MThd' +
        (6).to_bytes(4, 'big') +
        (0).to_bytes(2, 'big') +
        (1).to_bytes(2, 'big') +
        (MIDI_PPQN).to_bytes(2, 'big')
    )

    track_chunk = (
        b'MTrk' +
        len(track_data).to_bytes(4, 'big') +
        track_data
    )

    return header + track_chunk

def convert_mus_to_midi(data):
    """Convert MUS data to MIDI format with error handling."""
    try:
        if len(data) >= 4 and data[0:4] == b'MUS\x1a':
            return mus_to_midi(data)
    except Exception as e:
        print(f"[!] MUS conversion error: {e}")
    return data

def midi_to_ogg(midi_data, soundfont_path=None, quality=0):
    """
    Convert MIDI data to OGG using a more reliable fluidsynth approach.
    """
    print(f"Starting MIDI to OGG conversion (MIDI data: {len(midi_data)} bytes, quality: {quality})")
    
    fluidsynth_exe = find_fluidsynth()
    ffmpeg_exe = find_ffmpeg()
    
    if fluidsynth_exe is None or ffmpeg_exe is None:
        raise ValueError("Required executables not found")
    
    if soundfont_path is None:
        soundfont_path = find_soundfont()
        if soundfont_path is None:
            raise ValueError("No soundfont available")
    print(f"Using soundfont: {soundfont_path}")

    try:
        with tempfile.NamedTemporaryFile(suffix='.mid', delete=False) as temp_midi:
            temp_midi_path = temp_midi.name
            temp_midi.write(midi_data)
        
        with tempfile.NamedTemporaryFile(suffix='.wav', delete=False) as temp_wav:
            temp_wav_path = temp_wav.name
        
        try:
            print("Converting MIDI to WAV...")
            fluidsynth_cmd = [
                fluidsynth_exe,
                "-r", "44100",
                "-g", "1.0", 
                "-O", "s16",
                "-T", "wav",
                "-q",
                "-F", temp_wav_path,
                soundfont_path,
                temp_midi_path
            ]
            
            print(f"Fluidsynth command: {' '.join(fluidsynth_cmd)}")
            fluidsynth_process = Popen(fluidsynth_cmd, stderr=PIPE, stdout=PIPE)
            fluidsynth_stdout, fluidsynth_stderr = fluidsynth_process.communicate(timeout=30)
            
            if fluidsynth_process.returncode != 0:
                error_msg = fluidsynth_stderr.decode('utf-8', errors='ignore')
                print(f"Fluidsynth failed: {error_msg}")
                raise Exception(f"Fluidsynth conversion failed: {error_msg}")
            
            if not os.path.exists(temp_wav_path) or os.path.getsize(temp_wav_path) == 0:
                raise Exception("Fluidsynth produced no WAV output")
            
            wav_size = os.path.getsize(temp_wav_path)
            print(f"WAV file created: {wav_size} bytes")
            
            print("Converting WAV to OGG...")
            ffmpeg_cmd = [
                ffmpeg_exe,
                "-y",
                "-i", temp_wav_path,
                "-af", "silenceremove=stop_periods=-1:stop_duration=0:stop_threshold=-35dB",
                "-c:a", "libvorbis", 
                "-q:a", str(quality),
                "-f", "ogg",
                "-"
            ]
            
            print(f"FFmpeg command: {' '.join(ffmpeg_cmd)}")
            ffmpeg_process = Popen(ffmpeg_cmd, stdout=PIPE, stderr=PIPE)
            ogg_data, ffmpeg_stderr = ffmpeg_process.communicate(timeout=30)
            
            if ffmpeg_process.returncode != 0:
                error_msg = ffmpeg_stderr.decode('utf-8', errors='ignore')
                print(f"FFmpeg failed: {error_msg}")
                raise Exception(f"FFmpeg conversion failed: {error_msg}")
            
            if len(ogg_data) == 0:
                raise Exception("FFmpeg produced no OGG output")
            
            print(f"Successfully converted MIDI to OGG ({len(ogg_data)} bytes)")
            return ogg_data
            
        finally:
            try:
                os.unlink(temp_midi_path)
            except:
                pass
            try:
                os.unlink(temp_wav_path)
            except:
                pass
                
    except Exception as e:
        print(f"Conversion error: {e}")
        raise

def convert_midi_lumps_to_ogg(src_wad, out_wad, output_prefix="O_"):
    """
    Convert all MIDI music lumps in WAD to OGG format and add to output WAD.
    """
    soundfont_path = find_soundfont()
    fluidsynth_exe = find_fluidsynth()
    ffmpeg_exe = find_ffmpeg()
    
    if fluidsynth_exe is None:
        print("Skipping MIDI to OGG conversion: fluidsynth not found")
        return 0
    
    if ffmpeg_exe is None:
        print("Skipping MIDI to OGG conversion: ffmpeg not found") 
        return 0
        
    if soundfont_path is None:
        print("Skipping MIDI to OGG conversion: no soundfont available")
        return 0
    
    converted_count = 0
    
    for lump_name, lump in src_wad.music.items():
        if lump_name.startswith("D_"):
            data = lump.data
            if len(data) >= 4 and data[:4] == b'MThd':
                print(f"Converting MIDI lump {lump_name} to OGG...")
                output_name = f"{output_prefix}{lump_name[2:]}".replace(" ", "_")
                
                try:
                    ogg_data = midi_to_ogg(data, soundfont_path, quality=0)
                    if ogg_data:
                        out_wad.data[output_name] = Lump(ogg_data)
                        converted_count += 1
                        print(f"Created OGG lump {output_name} in WAD")
                except Exception as e:
                    print(f"Failed to convert {lump_name}: {e}")
    
    for lump_name, lump in src_wad.data.items():
        data = lump.data
        if len(data) >= 4 and data[:4] == b'MThd':
            lump_upper = lump_name.upper()
            if (lump_upper.endswith(('.MID', '.MIDI')) or 
                lump_upper.startswith('D_')):
                
                print(f"Converting MIDI lump {lump_name} to OGG...")
                base_name = lump_name
                if '.' in base_name:
                    base_name = base_name.rsplit('.', 1)[0]
                output_name = f"{output_prefix}{base_name}".replace(" ", "_")
                
                try:
                    ogg_data = midi_to_ogg(data, soundfont_path, quality=0)
                    if ogg_data:
                        out_wad.music[output_name] = Lump(ogg_data)
                        converted_count += 1
                        print(f"Created OGG lump {output_name} in WAD")
                except Exception as e:
                    print(f"Failed to convert {lump_name}: {e}")
    
    print(f"Converted {converted_count} MIDI lumps to OGG format in WAD")
    return converted_count

def process_midi_conversion(src_wad, out_wad):
    """Process MIDI to OGG conversion as part of the main workflow."""
    print("Starting MIDI to OGG conversion...")
    convert_midi_lumps_to_ogg(src_wad, out_wad, "O_")