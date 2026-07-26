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
    echo "Миру мир!" | speak        # Russian auto-detected
    cat document.txt | speak
    speak -h                        # all options

KDE Plasma Shortcut
~~~~~~~~~~~~~~~~~~~

The keyboard shortcut is configured automatically during installation:

1. Restart your Plasma session
2. Select any text
3. Press ``Alt+Esc`` to hear it spoken

Languages
---------

- **English** — Kokoro model, 10 voices
- **Russian** — Piper model (ru_RU-irina-medium), bundled

Language is auto-detected: Cyrillic text is spoken by the Russian voice.
Override with ``speak -l en`` / ``speak -l ru``.

Available Voices
----------------

Choose from natural-sounding voices (``speak -v NAME``):

- **American Female:** af_sky (default), af_bella, af_nicole, af_sarah
- **American Male:** am_michael, am_adam
- **British Female:** bf_emma, bf_isabella
- **British Male:** bm_george, bm_lewis
- **Russian Female:** irina (used automatically for Russian text)

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

Python upgrades
~~~~~~~~~~~~~~~

When Debian moves ``python3`` to a new version, ``speak`` and a dpkg trigger run
``kokoro-venv-setup``, which re-points the venv to its python (offline) or
rebuilds it.
