#!/usr/bin/env python3
"""Test audio output on different devices"""
from typing import Any
import sounddevice as sd  # type: ignore[import-untyped]
import numpy as np

# List all output devices
print("Available output devices:")
devices: Any = sd.query_devices()  # type: ignore[reportUnknownMemberType]
for i, dev in enumerate(devices):
    if isinstance(dev, dict) and dev['max_output_channels'] > 0:
        print(f"  {i}: {dev['name']} ({dev['max_output_channels']} channels)")

print("\nTesting each output device with a beep...\n")

# Test each output device
for i, dev in enumerate(devices):
    if isinstance(dev, dict) and dev['max_output_channels'] > 0:
        try:
            print(f"Testing device {i}: {dev['name']}")
            # Generate a 440Hz beep for 0.5 seconds
            fs: int = int(dev['default_samplerate'])  # type: ignore[reportUnknownArgumentType]
            duration: float = 0.5
            t = np.linspace(0, duration, int(fs * duration))  # type: ignore[reportUnknownArgumentType]
            tone = 0.3 * np.sin(2 * np.pi * 440 * t)  # type: ignore[reportUnknownArgumentType]

            sd.play(tone, samplerate=fs, device=i, blocking=True)  # type: ignore[reportUnknownMemberType]
            print(f"  ✓ Played on device {i}\n")
        except Exception as e:
            print(f"  ✗ Failed: {e}\n")
