# xsr
X Steps Recorder

This program is a clone of [PSR for Windows](https://blogs.msdn.microsoft.com/patricka/2010/01/04/using-the-secret-windows-7-problem-steps-recorder-to-create-step-by-step-screenshot-documents/), a program that allows users to make a recording of all of the steps they took. (It's like a screen recorder except it doesn't record a video.)

The main differences are that this only runs on Linux, that it records your keystrokes too (!), and that it saves the output as standard html (base64-uri-encoded images) rather than mhtml. This allows for easy editing of the resultant file, such as to remove passwords you typed (which is why psr doesn't record keystrokes in the first place).

# Usage

```
Usage: xsr [options] [outfile]

Options:

  -o|--out outfile		Output file name (also can be first argument)
  -e|--edit-images-before-save	Edit images before saving file
  -c|--image-extension ext	Extension of image output (png or jpg)
  -h|--help			Print this message
```

# Todo (help welcomed)

 - **Make it quit on a sequence of keys, rather than having to go to the terminal and kill it**
 - Make a `deb`
 - Make a PPA
 - Clean up the code to make it run in strict mode
