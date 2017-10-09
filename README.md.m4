# xsr
X Steps Recorder

This program is a clone of [PSR for Windows](https://blogs.msdn.microsoft.com/patricka/2010/01/04/using-the-secret-windows-7-problem-steps-recorder-to-create-step-by-step-screenshot-documents/), a program that allows users to make a recording of all of the steps they took. (It's like a screen recorder except it doesn't record a video.)

The main differences are that this only runs on Linux, that it records your keystrokes too (!), and that it saves the output as standard html (base64-uri-encoded images) rather than mhtml. This allows for easy editing of the resultant file, such as to remove passwords you typed (which is why psr doesn't record keystrokes in the first place).

# Installation

See the [Releases Page](https://github.com/nonnymoose/xsr/releases).
Make sure you have `scrot` installed; I recommend that you have `imagemagick` and `xdotool` installed as well (to add pointer to screenshots).

# Usage

```
m4_define([[[./xsr]]], [[[xsr]]])m4_dnl
m4_changeword([\.\/_a-zA-Z0-9]+)m4_dnl
USAGE
m4_changeword([_a-zA-Z][_a-zA-Z0-9]*)m4_dnl
```
To quit, press `Break` (usually on top of `Pause`). `Ctrl`+`C` works most of time fine too, although xsr will record that keypress.

# Notes for this file
__Please don't edit this file (`README.md`) directly!__
/* You should edit THIS file instead */
Please edit rather `README.md.m4`, and run `make README.md` after.
You can commit the generated changes in `README.md` along with the manual changes in `README.md.m4`.
