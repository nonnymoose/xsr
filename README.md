# xsr
X Steps Recorder

This program is a clone of [PSR for Windows](https://blogs.msdn.microsoft.com/patricka/2010/01/04/using-the-secret-windows-7-problem-steps-recorder-to-create-step-by-step-screenshot-documents/), a program that allows users to make a recording of all of the steps they took. (It's like a screen recorder except it doesn't record a video.)

The main differences are that this only runs on Linux, that it records your keystrokes too (!), and that it saves the output as standard html (base64-uri-encoded images) rather than mhtml. This allows for easy editing of the resultant file, such as to remove passwords you typed (which is why psr doesn't record keystrokes in the first place).

# Installation

See the [Releases Page](https://github.com/nonnymoose/xsr/releases).
Make sure you have `scrot` installed; I recommend that you have `imagemagick` and `xdotool` installed as well (to add pointer to screenshots).

# Usage

```
Usage: xsr [options] [outfile]

Options:

  -o|--out outfile		Output file name (also can be first argument)
  -e|--edit-images-before-save	Edit images before saving file
  -c|--image-extension ext	Extension of image output (png or jpg)
  -u|--capture-focused		Captured the focused window only
  --no-mouse			Do not add mouse to screenshots
  --countdown[=seconds]		Display countdown (default 5)
  --no-countdown			Don't display countdown
  -h|--help			Print this message
```
To quit, press `Break` (usually on top of `Pause`). `Ctrl`+`C` works most of time fine too, although xsr will record that keypress.
