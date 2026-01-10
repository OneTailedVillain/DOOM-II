"""
MIDI and MUS conversion functions.
"""

import struct
import os
import tempfile
from subprocess import Popen, PIPE
from modules.utils import find_fluidsynth, find_ffmpeg, find_soundfont

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

def mus_to_midi(mus_data):
    """Convert MUS file data to MIDI file data."""
    if len(mus_data) < 16 or mus_data[0:4] != b'MUS\x1a':
        raise ValueError("Invalid MUS file: signature mismatch")
    
    len_song = struct.unpack('<H', mus_data[4:6])[0]
    off_song = struct.unpack('<H', mus_data[6:8])[0]
    primary_channels = struct.unpack('<H', mus_data[8:10])[0]
    secondary_channels = struct.unpack('<H', mus_data[10:12])[0]
    num_instruments = struct.unpack('<H', mus_data[12:14])[0]
    reserved = struct.unpack('<H', mus_data[14:16])[0]
    
    instruments = []
    pos = 16
    for _ in range(num_instruments):
        instruments.append(struct.unpack('<H', mus_data[pos:pos+2])[0])
        pos += 2
    
    song_data = mus_data[off_song:off_song+len_song]
    events = []
    
    events.append((0, [0xFF, 0x51, 0x03, 0x0F, 0x42, 0x40]))
    
    for c in range(primary_channels):
        midi_channel = c
        events.append((0, [0xB0 | midi_channel, 101, 0]))
        events.append((0, [0xB0 | midi_channel, 100, 0]))
        events.append((0, [0xB0 | midi_channel, 6, 2]))
        events.append((0, [0xB0 | midi_channel, 38, 0]))
    
    for c in range(10, 10 + secondary_channels):
        midi_channel = c
        events.append((0, [0xB0 | midi_channel, 101, 0]))
        events.append((0, [0xB0 | midi_channel, 100, 0]))
        events.append((0, [0xB0 | midi_channel, 6, 2]))
        events.append((0, [0xB0 | midi_channel, 38, 0]))
    
    last_note_volume = [100] * 16
    current_time = 0
    index = 0
    size = len(song_data)
    break_loop = False
    
    while index < size and not break_loop:
        event_byte = song_data[index]
        index += 1
        
        last_flag = event_byte & 0x80
        event_type = (event_byte >> 4) & 0x07
        channel = event_byte & 0x0F
        
        if channel == 15:
            midi_channel = 9
        elif channel < primary_channels:
            midi_channel = channel
        elif 10 <= channel < 10 + secondary_channels:
            midi_channel = channel
        else:
            midi_channel = 9
        
        if event_type == 0:
            note_byte = song_data[index]
            index += 1
            note = note_byte & 0x7F
            events.append((current_time, [0x80 | midi_channel, note, 64]))
        
        elif event_type == 1:
            note_byte = song_data[index]
            index += 1
            vol_flag = note_byte & 0x80
            note = note_byte & 0x7F
            if vol_flag:
                vol_byte = song_data[index]
                index += 1
                velocity = vol_byte & 0x7F
                last_note_volume[channel] = velocity
            else:
                velocity = last_note_volume[channel]
            events.append((current_time, [0x90 | midi_channel, note, velocity]))
        
        elif event_type == 2:
            bend_byte = song_data[index]
            index += 1
            bend_value = (bend_byte * 16383) // 255
            lsb = bend_value & 0x7F
            msb = (bend_value >> 7) & 0x7F
            events.append((current_time, [0xE0 | midi_channel, lsb, msb]))
        
        elif event_type == 3:
            sys_byte = song_data[index]
            index += 1
            controller = sys_byte & 0x7F
            if controller == 10: cc = 120
            elif controller == 11: cc = 123
            elif controller == 12: cc = 126
            elif controller == 13: cc = 127
            elif controller == 14: cc = 121
            else: continue
            events.append((current_time, [0xB0 | midi_channel, cc, 0]))
        
        elif event_type == 4:
            ctrl_byte = song_data[index]
            index += 1
            ctrl_num = ctrl_byte & 0x7F
            val_byte = song_data[index]
            index += 1
            value = val_byte & 0x7F
            if ctrl_num == 0:
                if midi_channel != 9:
                    events.append((current_time, [0xC0 | midi_channel, value]))
            else:
                events.append((current_time, [0xB0 | midi_channel, ctrl_num, value]))
        
        elif event_type == 5:
            pass
        
        elif event_type == 6:
            break_loop = True
        
        elif event_type == 7:
            if index < size:
                index += 1
        
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
        (140).to_bytes(2, 'big')
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