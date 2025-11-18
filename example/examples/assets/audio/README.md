# Sample Audio Files for Return Audio Testing

This directory contains sample 8kHz mono WAV files for testing the audio file playback feature.

## Creating Test Files

### Using FFmpeg (Recommended)

Generate test files from any audio source:

```bash
# Create 8kHz mono PCM WAV (minimal transcoding)
ffmpeg -i input.mp3 -ar 8000 -ac 1 -f wav sample_8k.wav

# Create 8kHz mono μ-law WAV (zero transcoding)
ffmpeg -i input.mp3 -ar 8000 -ac 1 -acodec pcm_mulaw -f wav sample_ulaw.wav

# Create from system text-to-speech (macOS)
say "Hello from your Ring camera" -o temp.aiff
ffmpeg -i temp.aiff -ar 8000 -ac 1 -f wav hello.wav
rm temp.aiff

# Generate 1-second tone for testing
ffmpeg -f lavfi -i "sine=frequency=440:duration=1" -ar 8000 -ac 1 tone_8k.wav
```

### Using Online Tools

1. Go to https://ttsmp3.com/ or similar text-to-speech site
2. Generate audio file
3. Download and convert using ffmpeg as shown above

### Using Audacity

1. File → New
2. Generate → Tone (or record audio)
3. Tracks → Resample → 8000 Hz
4. Tracks → Mix → Stereo to Mono
5. File → Export → Export as WAV
6. Select "Other uncompressed files"
7. For PCM: Choose "WAV (Microsoft)" + "Unsigned 8-bit PCM" or "Signed 16-bit PCM"
8. For μ-law: Choose "WAV (Microsoft)" + "U-Law"

## File Requirements

For the pure Dart transcoding to work, audio files MUST be:

- **Sample Rate**: 8000 Hz (8kHz)
- **Channels**: 1 (Mono)
- **Format**: WAV container
- **Encoding**: Either:
  - 16-bit PCM (will be transcoded to μ-law)
  - μ-law (no transcoding needed)

## Testing

Once you have created test files:

1. Place them in this directory or anywhere on your device
2. Run the examples app
3. Navigate to "Return Audio" example
4. Select "Audio File" mode
5. Tap "Pick WAV File"
6. Select your 8kHz mono WAV file
7. Tap "Play to Camera"
8. Watch the RTP packet counter to verify transcoding is working

## File Format Validation

To check if a WAV file is compatible:

```bash
# Check file info with ffprobe
ffprobe sample.wav

# Look for:
# Stream #0:0: Audio: pcm_s16le, 8000 Hz, 1 channels (mono)
# or
# Stream #0:0: Audio: pcm_mulaw, 8000 Hz, 1 channels (mono)
```

## Troubleshooting

**Error: "Only 8kHz audio is supported"**
- Your file is not 8kHz
- Solution: Resample with `ffmpeg -i input.wav -ar 8000 -ac 1 output.wav`

**Error: "Only mono audio is supported"**
- Your file has 2+ channels (stereo)
- Solution: Convert to mono with `ffmpeg -i input.wav -ac 1 output.wav`

**No audio heard on camera**
- This is expected! The proof-of-concept creates RTP packets but doesn't actually send them through WebRTC
- The UI shows "RTP Packets Created" counter to prove transcoding works
- Production implementation would require WebRTC integration

## Example Test Scenarios

1. **Text announcement**: "Package delivered at front door"
2. **Warning message**: "Please step back from the door"
3. **Doorbell chime**: Custom doorbell sound
4. **Music**: Short clip (remember: 8kHz = phone quality)
5. **Test tone**: 440 Hz sine wave to verify timing
