TODO
====

Languages and Voices
--------------------

- [x] Command-line options + language autodetection (0.1.3)
- [x] Russian (0.1.3, Piper irina)
- [ ] Config file for defaults (voice, speed)
- [ ] More languages / more Russian voices (denis, dmitri, ruslan)

GPU Acceleration
----------------

- [ ] Add GPU acceleration support for NVIDIA cards (CUDA)
- [ ] Add GPU acceleration support for AMD cards (ROCm)
- [ ] Add auto-detection to choose GPU vs CPU based on hardware
- [ ] Document GPU setup instructions in README

Speech-to-Text (dictation)
--------------------------

- [ ] Voice input: hotkey -> record mic -> whisper.cpp (offline) -> text into clipboard/active window

Packaging
---------

- [ ] Rename legacy desktop id ``net.local.sh.desktop`` (needs kglobalshortcutsrc migration)

Distribution Support
--------------------

Currently only tested on Debian (SID)

- [ ] Test and package for Ubuntu
- [ ] Test and package for Gentoo
- [ ] Test and package for Arch Linux
- [ ] Test and package for Fedora/RHEL
