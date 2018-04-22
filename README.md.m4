# xsr
X Steps Recorder

This program is a clone of [PSR for Windows](https://blogs.msdn.microsoft.com/patricka/2010/01/04/using-the-secret-windows-7-problem-steps-recorder-to-create-step-by-step-screenshot-documents/), a program that allows users to make a recording of all of the steps they took. (It's like a screen recorder except it doesn't record a video.)

The main differences are that this only runs on Linux, that it records your keystrokes too (!), and that it saves the output as standard html (base64-uri-encoded images) rather than mhtml. This allows for easy editing of the resultant file, such as to remove passwords you typed (which is why psr doesn't record keystrokes in the first place).

# Installation

## Installing a stable release

See the [Releases Page](https://github.com/nonnymoose/xsr/releases).
Make sure you have `scrot` installed; I recommend that you have `imagemagick` and `xdotool` installed as well (to add pointer to screenshots).
m4_define([[[m4_print_dependency_list]]], [[[scrot imagemagick xdotool xinput x11-xserver-utils]]])m4_dnl
m4_define([[[m4_print_cpan_dependency_list]]], [[[HTML::Entities]]])m4_dnl

For example, on Ubuntu/Debian:
```
version=v1.0.0
sudo apt install perl m4_print_dependency_list
curl https://github.com/nonnymoose/xsr/releases/download/$version/xsr.tar.gz | sudo tar -xzC /
```

## Installing a custom tree

1. `sudo apt install perl m4_print_dependency_list make cpanminus gcc libc-dev`
2. `cpanm m4_print_cpan_dependency_list`
3. `make`
4. `sudo make install`

# Usage

```
m4_syscmd([[[./xsr --help | head -n -1 | sed -rs 's#(^Usage:)(\s*)\./(\w+)#\1\2\3#']]])m4_dnl
```
To quit, press `Break` (usually `Shift`+`Pause`). `Ctrl`+`C` works most of time fine too, although xsr will record that keypress.

# Notes for this file
__Please don't edit this file (`README.md`) directly!__
Please edit rather `README.md.m4`, and run `make README.md` after.
You can commit the generated changes in `README.md` along with the manual changes in `README.md.m4`.
