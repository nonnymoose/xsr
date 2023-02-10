# xsr
X Steps Recorder

This program is a clone of [PSR for Windows](https://blogs.msdn.microsoft.com/patricka/2010/01/04/using-the-secret-windows-7-problem-steps-recorder-to-create-step-by-step-screenshot-documents/), a program that allows users to make a recording of all of the steps they took. (It's like a screen recorder except it doesn't record a video.)

The main differences are that this only runs on Linux, that it records your keystrokes too (!), and that it saves the output as standard html (base64-uri-encoded images) rather than mhtml. This allows for easy editing of the resultant file, such as to remove passwords you typed (which is why psr doesn't record keystrokes in the first place).

# Installation

Run the **install.sh** script like so:
```
sudo sh install.sh
```

# Dependencies
Needs gnome-screenshot in order to run properly. It does get installed when running the `install.sh` script

# Usage

```
Usage: xsr [options] [outfile]

Options:

  -o|--out outfile		Output file name (also can be first argument)
  -e|--edit-images-before-save	Edit images before saving file
  -d|--image-deps		Do not convert images to base64; instead, output the dependent file and it's resources directory
  -c|--image-extension=ext	Extension of image output (png or jpg)
  -u|--capture-focused		Captured the focused window only
  -q|--quiet			Supress output to STDOUT
  --mouse-icon|--cursor=file	Specify cursor image (default: the one installed to /usr/share/xsr/Cursor.png)
  --no-mouse			Do not add mouse to screenshots
  --countdown[=seconds]		Display countdown (default 5)
  --no-countdown		Don't display countdown
  -h|--help			Print this message
```
To quit, press `Break` (usually `Shift`+`Pause`). `Ctrl`+`C` works most of time fine too, although xsr will record that keypress.