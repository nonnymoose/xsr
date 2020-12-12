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

If you want to use the bash script `xsr.sh`, edit it and update the default file names zone.

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
Description:
   ./bin/xsr.pl is a clone of PSR for Windows, a program that allows users to make a recording of all of the steps they took. It's like a screen recorder that doesn't record a video.
   It records your keystrokes too (!), and it saves the output as standard html (base64-uri-encoded images). This allows for easy editing of the resultant file, such as to remove passwords you typed.

Usage:
    ./bin/xsr.pl [options] outfile

Options:

  General:
  -o|--out outfile		Output file name with absolute path (also can be first argument) (default: ./html/Untitled Recording.html)
  -l|--lang=code		Language for HTML page (en or fr) (default: en)
  -q|--quiet			Suppress output to STDOUT
  -z|--need-final-return	Need to press Return at the end of script
  --countdown[=seconds]		Display countdown (default: 5)
  --no-countdown		Don't display countdown
  -h|--help			Print this message

  Images:
  -p|--images-absolute-path	Images absolute path into HTML
  -e|--edit-images-before-save	Edit images before saving file
  -i|--images-editor=file	Images editor (default: xdg-open)
  -d|--image-deps		Do not convert images to base64; instead, output the dependent file and it's resources directory
  -c|--image-extension=ext	Extension of image output (png or jpg) (default: png)
  -u|--screenshot-mode		Screenshot mode : all (all the desktop), select (a selection) or focus (the focused window) (default: focus)
  --mouse-icon|--cursor=file	Specify cursor image (default: ./cursor/default.png)
  --no-mouse			Do not add mouse to screenshots
  -w|--watermark=file	Specify watermark image (default: none)
  -a|--add-watermark			Add watermark to screenshots

  HTML:
  -s|--edit-html		Edit HTML
  -t|--html-editor=file		HTML editor (default: )
  --css=file			Specify CSS file (default: ./css/tuto.css)
  -g|--legend			Put text above image

  Explore:
  -r|--view-record		Show recorded HTML directory
  -f|--file-explorer=file	File explorer (default: xdg-open)
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
