#!/usr/bin/env python3
import os
import sys
import numpy as np
import librosa
import soundfile as sf

if len(sys.argv) < 2:
    print(f"Usage: python3 {sys.argv[0]} <audio_file.mp3> [output_click_track.wav]")
    sys.exit(1)

filename = sys.argv[1]
output_wav = sys.argv[2] if len(sys.argv) > 2 else "click_track.wav"

# 1. Load song and get precise BPM and beats
print(f"Analyzing {filename}...")
y, sr = librosa.load(filename)
tempo, beats = librosa.beat.beat_track(y=y, sr=sr)
bpm = tempo.item() if hasattr(tempo, "item") else tempo
print(f"Detected BPM: {bpm:.2f}")

# 2. Load or synthesize hi-hat click sound
def get_hihat_click(sr):
    # Check default location in ClearSCM data directory
    base_dir = os.path.dirname(os.path.dirname(os.path.realpath(__file__)))
    hihat_path = os.path.join(base_dir, "data", "hihat.wav")

    if os.path.exists(hihat_path):
        click, _ = librosa.load(hihat_path, sr=sr)
        return (click / np.max(np.abs(click))) * 0.8

    # Fallback synthetic hi-hat click (high-passed noise with rapid exponential decay)
    n_samples = int(sr * 0.05)
    noise = np.random.uniform(-1, 1, n_samples)
    envelope = np.exp(-np.linspace(0, 25, n_samples))
    click = noise * envelope
    return (click / np.max(np.abs(click))) * 0.8

click_sound = get_hihat_click(sr)

# 3. Generate click track for the entire length of the song
if len(beats) > 0:
    click_audio = librosa.clicks(frames=beats, sr=sr, length=len(y), click=click_sound)
else:
    # Fallback to uniform grid if beat tracking found no beats
    beat_interval_sec = 60.0 / bpm
    samples_per_beat = int(sr * beat_interval_sec)
    beat_samples = np.arange(0, len(y), samples_per_beat)
    click_audio = librosa.clicks(times=beat_samples / sr, sr=sr, length=len(y), click=click_sound)

# 4. Save the output WAV file
sf.write(output_wav, click_audio, sr)
print(f"Success! Click track saved to '{output_wav}'")
