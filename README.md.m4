# xsr
X Steps Recorder

This program is a clone of [PSR for Windows](https://blogs.msdn.microsoft.com/patricka/2010/01/04/using-the-secret-windows-7-problem-steps-recorder-to-create-step-by-step-screenshot-documents/), a program that allows users to make a recording of all of the steps they took. (It's like a screen recorder except it doesn't record a video.)

The main differences are that this **only runs on Linux**, that it records your keystrokes too (!), and that it saves the output as standard html (base64-uri-encoded images) rather than mhtml. This allows for easy editing of the resultant file, such as to remove passwords you typed (which is why psr doesn't record keystrokes in the first place).

# Installation

See the [Releases Page](https://github.com/olivierlab/xsr/releases).

You need to install perl module `Config::Properties` to read config and translation files :

    `sudo cpan install Config::Properties`

You need to install perl module `lib::relative` to access internal module :

    `sudo cpan install lib::relative`

Make sure you have `scrot` (direct screenshot), `maim` (screenshot with selection), `xmodmap` (key map code) and `xinput` (listen keyboard and mouse) installed.

I recommend that you have `xdotool` (mouse position) and `imagemagick` (to add pointer to screenshots) installed as well.

If you want to use the bash script `xsr.sh`, install `zenity` (dialog box) and `pandoc` (convert from HTML to md) then edit it and update the default file names zone.

For `xsr.desktop`, change keys `Exec`, `Icon` and `Path`.

# New things compared with original fork

With this version, you may edit image (add `gwenview` or `fotoxx`, not `gimp` because you need bulk editors), edit HTML (add `bluegriffon` or `seamonkey composer`) and view generated files.

The CSS is also customisable. A exemple file is present into the `css` directory.

Press on `Scroll Lock` key during recording add one seconde wait before screenshot. Usefull when you want to show the click result and not the moment of the click.

Press on `Shift + Scroll Lock` key during recording if you want to add a step.

Press on `Pause` key to put recording in stand-by. Press again `Pause` key to continue. Usefull if you need to continue the process but don't want to show some screens.

Press on `Shift + Pause` to quit recording.

# Usage

```
m4_syscmd([[[./bin/xsr.pl --help | head -n -1 | sed -rs 's#(^Usage:)(\s*)\./(\w+)#\1\2\3#' | sed -rs 's#/.*/xsr/bin/../#./#']]])m4_dnl
```
To quit, press `Break` (usually `Shift`+`Pause`). `Ctrl`+`C` works most of time fine too, although xsr will record that keypress.

# Process

The process is simple :

1. Run `xsr` with parameters of your choice
2. Click and type everywhere you want. Every key pressed is saved. After each `click` or `return`, a screenshot is taken. Hit `Shift`+`Pause` to stop.
3. If an image editor is defined, you can crop, draw on images, then exit
4. If an HTML editor is defined, you can modify default generated text with your own, then exit
5. If a file explorer is defined, you can view the generated files

# Examples

1. Full edition : images > html > files

`./bin/xsr.pl "./html/save.html" -e --images-editor="your-img-editor" -s --html-editor="your-html-editor" -r --file-explorer="your-file-explorer"`

2. With absolute image path (`-p`) usefull to copy the result into an mail :

`./bin/xsr.pl "./html/save.html" -p -e --images-editor="your-img-editor" -s --html-editor="your-html-editor"`

Without `-p` option, images have relative path. Usefull if you need to move the HTML result.

3. With selection of each zone of image after click :

`./bin/xsr.pl "./html/save.html" --screenshot-mode="select" -e --images-editor="your-img-editor" -s --html-editor="your-html-editor"`

Enjoy.

# Notes for this file
__Please don't edit this file (`README.md`) directly!__
Please edit rather `README.md.m4`, and run `make README.md` after.
You can commit the generated changes in `README.md` along with the manual changes in `README.md.m4`.
