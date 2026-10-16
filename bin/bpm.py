#!/usr/bin/env python3
import sys
import numpy as np
import librosa
import soundfile as sf

if len(sys.argv) < 2:
    print(f"Usage: python3 {sys.argv[0]} <audio_file.mp3> [output_countoff.wav]")
    sys.exit(1)

filename = sys.argv[1]
output_wav = sys.argv[2] if len(sys.argv) > 2 else "count_off.wav"

# 1. Load song and get precise BPM
print(f"Analyzing {filename}...")
y, sr = librosa.load(filename)
tempo, _ = librosa.beat.beat_track(y=y, sr=sr)
bpm = tempo.item() if hasattr(tempo, "item") else tempo
print(f"Detected BPM: {bpm:.2f}")

# 2. Calculate exact beat interval in samples
beat_interval_sec = 60.0 / bpm
samples_per_beat = int(sr * beat_interval_sec)

# 3. Synthesize a prominent metronome click (woodblock style)
def create_click(sr, duration=0.07):
    n_samples = int(sr * duration)
    t = np.linspace(0, duration, n_samples, endpoint=False)

    # Mix two frequencies for a sharp, woody click tone (1000Hz + 1200Hz)
    click = 0.6 * np.sin(2 * np.pi * 1000 * t) + 0.4 * np.sin(2 * np.pi * 1200 * t)

    # Sharp exponential decay envelope so it doesn't ring out
    envelope = np.exp(-np.linspace(0, 15, n_samples))
    click *= envelope

    # Normalize volume
    return (click / np.max(np.abs(click))) * 0.8

click_sound = create_click(sr)
click_len = len(click_sound)

# 4. Build the 8-beat count-off buffer with a 1-second intro lead-in
intro_samples = int(sr * 1.0)
total_samples = intro_samples + (samples_per_beat * 7) + click_len + int(sr * 0.1)
countoff_audio = np.zeros(total_samples)

for i in range(8):
    start_idx = intro_samples + (i * samples_per_beat)
    end_idx = start_idx + click_len
    countoff_audio[start_idx:end_idx] += click_sound

# 5. Save the output WAV file
sf.write(output_wav, countoff_audio, sr)
print(f"Success! 8-beat count-off saved to '{output_wav}'")
