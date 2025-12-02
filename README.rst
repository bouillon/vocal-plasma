Vocal Plasma
============

Make your Plasma Linux desktop more accessible and productive with high-quality text-to-speech integration. Select any text anywhere and hear it spoken with natural-sounding voices.

What This Does
--------------

This package integrates text-to-speech into your KDE Plasma desktop:

- **Select and listen:** Highlight any text, press ``Alt+Esc``, and hear it spoken. Works in any application where text can be selected - browsers, Okular (PDF reader), text editors, email clients, documents
- **Natural voices:** Choose from multiple realistic American and British voices
- **Works everywhere:** Read emails, documents, web pages, or any text on screen
- **Offline:** All processing happens locally, no internet required
- **Simple commands:** Pipe any text to the ``speak`` command

Installation
------------

Install the Debian package:

.. code-block:: bash

    dpkg -i vocal-plasma_*.deb
    apt-get install -f

That's it! The package works out of the box.

Usage
-----

Command Line
~~~~~~~~~~~~

.. code-block:: bash

    echo "Hello world" | speak
    cat document.txt | speak

KDE Plasma Shortcut
~~~~~~~~~~~~~~~~~~~

The keyboard shortcut is configured automatically during installation:

1. Restart your Plasma session
2. Select any text
3. Press ``Alt+Esc`` to hear it spoken

Available Voices
----------------

Choose from natural-sounding voices:

- **American Female:** af_sky (default), af_bella, af_nicole, af_sarah
- **American Male:** am_michael, am_adam
- **British Female:** bf_emma, bf_isabella
- **British Male:** bm_george, bm_lewis

To change the default voice, edit ``/opt/kokoro-tts/kokoro_tts/core.py``

Building from Source
--------------------

See ``BUILD_GUIDE.rst`` for instructions on building the Debian package.

For Developers
--------------

Local Development Setup
~~~~~~~~~~~~~~~~~~~~~~~

Quick setup for development without building the package:

.. code-block:: bash

    ./DEVINSTALL.sh
    ./INSTALL-MODELS.sh

Run without installing:

.. code-block:: bash

    echo "Hello world" | uv run -m kokoro_tts.cli

Technical Details
-----------------

This package uses the Kokoro ONNX neural network model for high-quality speech synthesis:

- **Model:** Kokoro-82M (82 million parameters)
- **Engine:** ONNX Runtime for efficient inference
- **Voices:** 47 voices across 9 languages
- **Size:** ~340MB installed (includes neural network and voice data)

About Kokoro TTS
~~~~~~~~~~~~~~~~

Kokoro uses two files for speech synthesis:

**kokoro-v1.0.onnx (311MB)**
   Neural network model that converts text to speech. Language-independent and works for all supported languages.

**voices-v1.0.bin (27MB)**
   Voice embeddings containing characteristics for 47 different voices across multiple languages and accents.

The model processes text and voice data together to generate natural-sounding speech with the selected voice characteristics.
