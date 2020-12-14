
package xsr::Functions;

# All the functions used by xsr

use Cwd qw(cwd abs_path);
use File::Basename;
use File::Copy qw(copy);
use File::Path qw(remove_tree);
use HTML::Entities qw(encode_entities);
use Encode qw(encode decode);
use strict;
use Config::Properties;


# vars
my $properties = Config::Properties->new();
my $fh;

# usage
sub usage {
    my ($outfile, $lang, $countdown, $imageEditor, $imgext, $cursor, $htmleditor, $css, $fileexplorer, $screenshotmode, $watermarkfile) = @_;
	return <<endusage;
Description:
   $0 is a clone of PSR for Windows, a program that allows users to make a recording of all of the steps they took. It's like a screen recorder that doesn't record a video.
   It records your keystrokes too (!), and it saves the output as standard html (base64-uri-encoded images). This allows for easy editing of the resultant file, such as to remove passwords you typed.

Usage:
    $0 [options] outfile

Options:

  General:
  -o|--out outfile		Output file name with absolute path (also can be first argument) (default: $outfile)
  -l|--lang=code		Language for HTML page (en or fr) (default: $lang)
  -q|--quiet			Suppress output to STDOUT
  -y|--save-typing		Save typed keys
  -z|--need-final-return	Need to press Return at the end of script
  --countdown[=seconds]		Display countdown (default: $countdown)
  --no-countdown		Don't display countdown
  -h|--help			Print this message

  Images:
  -p|--images-absolute-path	Images absolute path into HTML
  -e|--edit-images-before-save	Edit images before saving file
  -i|--images-editor=file	Images editor (default: $imageEditor)
  -d|--image-deps		Do not convert images to base64; instead, output the dependent file and it's resources directory
  -c|--image-extension=ext	Extension of image output (png or jpg) (default: $imgext)
  -u|--screenshot-mode		Screenshot mode : all (all the desktop), select (a selection) or focus (the focused window) (default: $screenshotmode)
  --mouse-icon|--cursor=file	Specify cursor image (default: $cursor)
  --no-mouse			Do not add mouse to screenshots
  -w|--watermark=file	Specify watermark image (default: $watermarkfile)
  -a|--add-watermark			Add watermark to screenshots

  HTML:
  -s|--edit-html		Edit HTML
  -t|--html-editor=file		HTML editor (default: $htmleditor)
  --css=file			Specify CSS file (default: $css)
  -g|--legend			Put text above image

  Explore:
  -r|--view-record		Show recorded HTML directory
  -f|--file-explorer=file	File explorer (default: $fileexplorer)

endusage
}

sub begincountdown {
    my ($countdown, $ref_translate) = @_;
	my %translate = %{$ref_translate};
    if ($countdown) {
        my $translation = $translate{"startingin"};
        print(STDOUT "$translation ");
        for (my $i = $countdown; $i > 0; $i--) {
            print(STDOUT $i . "\b");
            STDOUT->flush();
            sleep(1);
        }
        $translation = $translate{"startstillhere"};
        print(STDOUT "0\n$translation\n");
    }
}

sub getnormalshiftaltkey {
    # From here on out the code is inspired by this answer: https://unix.stackexchange.com/a/129171, posted by Stéphane Chazelas
    open(my $X, "-|", "xmodmap -pke") or die("[ERROR] Couldn't open keymap."); # open keymap
    # =================================================================
    # $ xmodmap -pke
    # keycode   8 =
    # keycode   9 = Escape NoSymbol Escape
    # keycode  10 = ampersand 1 ampersand 1 dead_acute periodcentered
    # keycode  11 = eacute 2 eacute 2 asciitilde NoSymbol asciitilde Eacute
    # keycode  12 = quotedbl 3 quotedbl 3 numbersign NoSymbol numbersign cedilla
    # keycode  13 = apostrophe 4 apostrophe 4 braceleft NoSymbol braceleft acute
    # keycode  14 = parenleft 5 parenleft 5 bracketleft NoSymbol bracketleft diaeresis
    # keycode  15 = minus 6 minus 6 bar NoSymbol bar brokenbar
    # keycode  16 = egrave 7 egrave 7 grave NoSymbol dead_grave Egrave
    # keycode  17 = underscore 8 underscore 8 backslash NoSymbol backslash macron
    # keycode  18 = ccedilla 9 ccedilla 9 asciicircum NoSymbol asciicircum Ccedilla
    # ...
    # =================================================================
    my %k; # store normal in k, a hash
    my %K; # store shift in K, a hash
    my %Ka; # store alt in Ka, a hash
    while (<$X>) {
        #if (/^keycode\s+(\d+) = (\w+)(?:\s+(\w+))?/) { # keycode <number> = <normal> <shift> ...
        if (/^keycode\s+(\d+) = (\w+)(?:\s+(\w+))?(?:\s+(\w+))?/) { # keycode <number> = <normal> <shift> <alt> ...
            $k{$1}=$2;
            $K{$1}=$3 if $3;
            $Ka{$1}=$4 if $4;
        }
    }
    return (\%k, \%K, \%Ka);
}

sub getmodmap {
    # open modmap
    open(my $X, "-|", "xmodmap -pm") or warn("[WARN] Could not open modifier map: Special keypresses would mess"); <$X>;<$X>;
    # =================================================================
    # $ xmodmap -pm
    # xmodmap:  up to 4 keys per modifier, (keycodes in parentheses):
    #
    # shift       Shift_L (0x32),  Shift_R (0x3e)
    # lock        Caps_Lock (0x42)
    # control     Control_L (0x25),  Control_R (0x69)
    # mod1        Alt_L (0x40),  Meta_L (0xcd)
    # mod2        Num_Lock (0x4d)
    # mod3
    # mod4        Super_L (0x85),  Super_R (0x86),  Super_L (0xce),  Hyper_L (0xcf)
    # mod5        ISO_Level3_Shift (0x5c),  Mode_switch (0xcb)
    # =================================================================
    my $k;
    my @m;
    my $i = 0;
    while (<$X>) {
        if (/^(\w+)\s+(\w*)/) {
            ($k=$2) =~ s/_[LR]$//;
            $m[$i++]=$k||$1;
            #print(STDOUT "[DEBUG] $m[$i-1]\n");
        }
    } # get a list of modifiers and stick it in an array
    close($X);

    return @m;
}
# Load a properties file
sub loadpropertiesfile {
    my ($file) = @_;
    #my $file = $_[0];
    open($fh, '<', $file) or die "unable to open configuration file $file";
    $properties->load($fh);
    return $properties->properties;
}

sub getmimetype {
    my ($ref_mimetypes, $imgext) = @_;
    my %mimetypes = %{$ref_mimetypes};
    my $mimetype;
    if ($mimetypes{$imgext}) {
        $mimetype = $mimetypes{$imgext};
    }
    else {
        die("[ERROR] Invalid file type $imgext.\nAccepted file types are:\n" . join(", ", keys %mimetypes) . "\n");
    }
    return $mimetype;
}

sub getcursor {
    my ($cursor, $nomouse) = @_;
    if (! -e $cursor) {
        $nomouse = 1;
        warn("[WARN] Cursor image $cursor doesn't exists, therefore capturing mouse is disabled.");
    } else {
        $cursor = abs_path($cursor);
    }
    return ($cursor, $nomouse);
}

sub getwatermark {
    my ($withwatermark, $watermarkfile) = @_;
    if ($withwatermark) {
        if (-e $watermarkfile) {
            $watermarkfile = abs_path($watermarkfile);
        } else {
            $withwatermark = 0;
            warn("[WARN] Watermark image $watermarkfile doesn't exists, therefore add watermark is disabled.");
        }
    }
    return ($withwatermark, $watermarkfile);
}

# convert HTML file name to absolute path
sub getoutfileinfos {
    my ($outfile) = @_;
    $outfile = abs_path($outfile);
    my($outfilename, $outfiledir, $suffix) = fileparse($outfile);
    my $outfilename_noext = $outfilename;
    $outfilename_noext =~ s/\.[^\.]*$//;
    return ($outfilename, $outfilename_noext, $outfiledir);
}

sub getexternaltool {
    my ($thetoolname, $message) = @_;
	my $thetool = `which $thetoolname`;
	chomp($thetool);
	return $thetool or warn("[WARN] $thetoolname unavailable: $message\n");
}

sub getapptitle {
	my ($xdotool, $ref_translate) = @_;
	my %translate = %{$ref_translate};

    my $apptitle = "";
    my $mytitle = "";

    if ($xdotool) {
        $apptitle = encode_entities(decode(q(UTF-8), `xdotool getwindowfocus getwindowname`));
        chomp($apptitle);
        my $field = "in";
        $mytitle = " $translate{$field} <span class=\"apptitle\">$apptitle</span>";
    }

    return $mytitle;
}

sub getcursorsize {
    my ($cursor) = @_;
    my $cursorw = 10; # default cursor width
    my $cursorh = 10; # default cursor height
    # identify
	my $identify = getexternaltool("identify", "mouse cursor will not appear well positionned in screenshots");
    if ($identify) {
        # get cursor width and height
        my $cursordim = `$identify $cursor`;
        # $ identify Cursor.png
        # Cursor.png PNG 48x48 48x48+0+0 8-bit sRGB 1.09KB 0.000u 0:00.000
        if ($cursordim =~ /^.* ... (\d+)x(\d+) /) {
            $cursorw = $1; # cursor width
            $cursorh = $2; # cursor height
            #print(STDOUT "Cursor dimension : $cursorw x $cursorh\n");
        }
    }
    return ($cursorw, $cursorh);
}

sub convertToB64 {
    my ($imagename) = @_;
	if (! -e $imagename) {
		warn("[WARN] Cannot convert $imagename: no such file or directory\n");
		return $imagename;
	}
	# return `base64 -w 0 $_[0]`; # -w 0 : do not wrap  # should use internal base64
	open(my $INIMG, "<", $imagename) or (warn("[WARN] Cannot open $imagename, this image will be broken!") and return "");
	{ # Slurp mode. If we don't have enough ram, I don't know how it ran in the first place!
		local $/; # enable "slurp" mode
		my $imgcontent = <$INIMG>;
		close($INIMG);
		return encode_base64($imgcontent);
	}
}

# instruction to interact with the application
sub showinstructions {
	my ($ref_translate, $istypedsaved) = @_;
	my %translate = %{$ref_translate};
    printinfomessage("=============================================================");
    printinfotranlated("instruction", \%translate);
    printinfomessage("=============================================================");
    printinfotranlated("screenshot", \%translate);
    if ($istypedsaved) {
        printinfotranlated("keypress", \%translate);
    }
    else {
        printinfotranlated("textblock", \%translate);
    }
    printinfotranlated("pressscrolllock", \%translate);
    printinfotranlated("pressshiftscrolllock", \%translate);
    printinfotranlated("presspause", \%translate);
    printinfotranlated("pressshiftpause", \%translate);
    printinfomessage("=============================================================");
}

sub printinfomessage {
    my ($message) = @_;
    print(STDOUT "[INFO] $message\n");
}

sub getrealchar { # function that makes using the above hash easier
	my ($rawkey, $ref_realchars) = @_;
	my %realchars = %{$ref_realchars};
	#print(STDOUT "[DEBUG] Keycode = $rawkey\n");
	$rawkey =~ s/KP_//i; # remove any number pad designation
	if ($realchars{$rawkey}) {
		return $realchars{$rawkey}; # make sure to only return the value if it's in the array (many aren't because the machine-readable name is also human-readable)
	}
	else {
		return $rawkey;
	}
}

sub getrealbutton { # function that makes using the above array easier
    my ($detail, $ref_realbuttons) = @_;
    my %realbuttons = %{$ref_realbuttons};
	if ($realbuttons{$detail}) {
		return $realbuttons{$detail};
	}
	else {
		return "Click mouse button $detail"; # fail-safe
	}
}

sub printinfotranlated {
    my ($code, $ref_translate) = @_;
    my %translate = %{$ref_translate};
    my $translation = $translate{$code};
    printinfomessage($translation);
}

sub printtitleandimage {
    my ($FOUT, $myimage, $mytitle, $islegend) = @_;

    print($FOUT "<div class=\"instruction full\">\n");
    printonlytitle($FOUT, $mytitle, "") if not $islegend;
    printimage($FOUT, "$myimage");
    printonlytitle($FOUT, $mytitle, "") if $islegend;
    print($FOUT "</div>\n");
}

sub printimage {
    my ($FOUT, $myimage) = @_;

    print($FOUT "<div class=\"image\"><img src=\"$myimage\" /></div>\n");
}

sub printtitle {
    my ($FOUT, $mytitle) = @_;

    print($FOUT "<div class=\"instruction\">\n");
    printonlytitle($FOUT, $mytitle, "only");
    print($FOUT "</div>\n");
}

sub printonlytitle {
    my ($FOUT, $mytitle, $myotherclass) = @_;

    print($FOUT "<div class=\"title $myotherclass\">$mytitle</div>\n");
}

sub printetape {
    my ($FOUT, $val, $ref_translate) = @_;
    my %translate = %{$ref_translate};
    my $translation = $translate{"step"};
    print($FOUT "<h2>$translation $val</h2>\n");
    printinfomessage("$translation $val");
}

# called by non-typing events
sub handletypingstate {
    my ($FOUT, $typing, $quiet, $typingtext) = @_;
	if ($typing) {
		printtitle($FOUT, $typingtext);
		# add line break if type before
        print(STDOUT "\n") if not $quiet;
		$typing = 0; # reprint "Type:" and the like next time
	}
	return $typing;
}

sub takescreenshot {
	my ($ref_translate, $xdotool, $composite, $nomouse, $ref_windowgrabs, $ref_mousegrabs, $isdelayed, $screenshotmode, $imgext, $quiet, $screeni, $maim, $scrot) = @_;
	my %translate = %{$ref_translate};
	my @windowgrabs = @{$ref_windowgrabs};
	my @mousegrabs = @{$ref_mousegrabs};
	my $istakescreenshot = 0;

	if ($xdotool && $composite && not $nomouse && not $screenshotmode eq "select") {
        # ---------------------------------------------
        # memorize mouse and window position to place
        # properly the cursor on screenshot
        # ---------------------------------------------
        # window id
        my $curwindowid = `xdotool getwindowfocus`;
        # screenshot position
		my $curwindowloc = `xdotool getwindowgeometry $curwindowid`;
		# $ xdotool getwindowgeometry 111149062
        # Window 111149062
        # Position: 31,29 (screen: 0)
        # Geometry: 1144x801
		push(@windowgrabs, $curwindowloc);

        # mouse position
        my $curmouseloc = `xdotool getmouselocation`;
        # $ xdotool getmouselocation
        # x:2676 y:441 screen:0 window:111149062
        push(@mousegrabs, $curmouseloc);
    }
	if ($isdelayed) {
		# wait one second before screenshot
		sleep 1;
		# remove delay
		$isdelayed = 0;
		printinfotranlated("slinactif", \%translate);
	}
	# Image name completed with zeroes to get them with right order when editing
	my $imgname = imagename($screeni);
	my $systemoutput = 1;
	if ($maim && $screenshotmode eq "select") {
        $systemoutput = system("maim --hidecursor --select $imgname.$imgext 1>/dev/null 2>/dev/null");
	}
	else {
        if ($scrot) {
            $systemoutput = system("scrot".( $screenshotmode eq "focus" ? " --focused" : "" )." $imgname.$imgext");
        }
        else {
            my $errorss = $translate{"errorss"};
            warn("[XWARN] $errorss\n");
        }
    }

	if ($systemoutput eq 0) {
        # screenshot is done
        print(STDOUT "[INFO] Screenshot $imgname\n") if not $quiet;
        # image number incrementation
        $screeni++;
        $istakescreenshot = 1;
    }

	return ($imgname, $screeni, \@windowgrabs, \@mousegrabs, $istakescreenshot);
}

# image name with filled zero
sub imagename {
    my ($index) = @_;
	# Image name completed with zeroes to get them with right order when editing
	my $nbzero = 3 - length($index);
	my $imgname = "0"x$nbzero . $index;
	return $imgname;
}

# put file content inside var
sub readfileintovar {
    my ($filename) = @_;
    open my $fh, '<', $filename or die "[ERROR] Could not open $filename for reading: $!";
    my $contents = do { local $/; <$fh> };
    return $contents;
}

# add cursor to the images
sub addcursortoimage {
	my ($xdotool, $composite, $nomouse, $ref_mousegrabs, $ref_windowgrabs, $cursorw, $cursorh, $cursor, $imgext) = @_;
	my @windowgrabs = @{$ref_windowgrabs};
	my @mousegrabs = @{$ref_mousegrabs};

    if ($xdotool && $composite && not $nomouse) {
        for (my $i = 0; $i < @mousegrabs; $i++) {
            my $curwindow = $windowgrabs[$i];
            my $curmouse = $mousegrabs[$i];
            chomp($curwindow);
            chomp($curmouse);
            if ($curwindow =~ /Position: (\d+),(\d+) /) {
                # window position inside screen
                my $curwindowx;
                my $curwindowy;
                $curwindowx = $1;
                $curwindowy = $2;
                if ($curmouse =~ /x:(\d+).*y:(\d+)/) {
                    # cursor position inside screenshot
                    my $curmousex;
                    my $curmousey;
                    $curmousex = int($1 - $curwindowx - $cursorw / 2);
                    $curmousey = int($2 - $curwindowy - $cursorh / 2);
                    my $imgname = imagename($i);
                    system("composite -geometry +$curmousex+$curmousey \"$cursor\" \"$imgname.$imgext\" \"$imgname.$imgext\"") and warn("[WARN] Had a problem adding the cursor to image $i\n"); # shell has reversed error codes
                }
            }
        }
    }
}

# Wait here if user wants to edit the images
sub editimages {
    my ($editimages, $imageEditor, $tmpdir, $quiet) = @_;
    if ($editimages) {
        my $imageEditor = `which $imageEditor`;
        chomp($imageEditor);
        if ($imageEditor) {
            system("$imageEditor \"$tmpdir\" 1>/dev/null 2>/dev/null");
            print(STDOUT "[INFO] End of images edition into '$tmpdir' with '$imageEditor'.\n") if not $quiet;
        }
        else {
            print(STDOUT "[WARN] Image editor $imageEditor not exist !\n");
        }
        print(STDOUT "[INFO] Initial image processing complete.\n") if not $quiet;
        #print(STDOUT "Initial image processing complete. If you would like to edit the images before the file is saved, they are located in $tmpdir. Press return when finished.\n") if not $quiet;
        #<STDIN>
    }
}

sub writefinalfileintohtml {
    my ($imagedeps, $imageabspath, $outfiledir, $outfilename_noext, $mimetype) = @_;

    # this file contains only image associations, not base64
    open(my $ASSOCFILE, "<", "tmpassoconly.html") or warn("[WARN] Couldn't open image associations: The resulting file would require manual edit");

    # this file will either be base64-encoded or associated with the final output *directory*
    open(my $FINALFILE, ">", "tmpencoded.html") or die("[ERROR] Couldn't open final output file");

    if ($imagedeps) {
        while (<$ASSOCFILE>) {
            if ($imageabspath) {
                # absolute path
                $_ =~ s/<img src=\"([^\"]+)\" \/>/<img src=\"file:\/\/$outfiledir$outfilename_noext\/$1\" \/>/gi; # replace <img> tags' src attr with relative path to images
            } else {
                # relative path
                $_ =~ s/<img src=\"([^\"]+)\" \/>/<img src=\"$outfilename_noext\/$1\" \/>/gi; # replace <img> tags' src attr with relative path to images
            }
            print($FINALFILE $_);
        }
    }
    else {
        while (<$ASSOCFILE>) {
            $_ =~ s/<img src=\"([^\"]+)\" \/>/"<img src=\"data:$mimetype;base64," . convertToB64($1) . "\" \/>"/gie; # replace <img> tags' src attr with a base64 uri
            print($FINALFILE $_);
        }
    }
    close($ASSOCFILE);
    close($FINALFILE);
}

# copy images into destination directory
sub copyimagetodest {
    my ($outfiledir, $imagedeps, $outfilename_noext, $screeni, $tmpdir, $imgext, $withwatermark, $watermarkfile) = @_;

    chdir($outfiledir);

    if ($imagedeps) {
        my $destdirimage = "$outfilename_noext";

        if (-d $destdirimage) {
            # remove image destination to avoid junk data
            remove_tree $destdirimage or warn("[WARN] Unable to remove image destination directory; junk remains in $destdirimage");
        }
        mkdir($destdirimage);

        # copy all image files to the dependent directory
        for (my $i = 0; $i < $screeni; $i++) {
            my $imgname = imagename($i);
            my $sourceimage ="$tmpdir/$imgname.$imgext";
            my $destimage = "$destdirimage/$imgname.$imgext";
            if ($withwatermark) {
                # add watermark
                system("composite -gravity south -geometry +0+10 \"$watermarkfile\" \"$sourceimage\" \"$destimage\"") and warn("[WARN] Had a problem adding the watermark to image $i\n"); # shell has reversed error codes
            } else {
                # just copy files
                copy "$sourceimage", "$destimage" or warn("[WARN] Could not copy image #$i toward $destimage.");
            }
        }
    }
}

# Edit with HTML editor to modify text
sub edithtmlfile {
    my ($edithtml, $htmleditor, $outfile, $quiet) = @_;

    if ($edithtml) {
        my $htmleditor = `which $htmleditor`;
        chomp($htmleditor);
        if ($htmleditor) {
            system("$htmleditor \"file://$outfile\" 1>/dev/null 2>/dev/null");
            print(STDOUT "[INFO] End of edition of '$outfile' with '$htmleditor'.\n") if not $quiet;
        } else {
            print(STDOUT "[WARN] HTML editor $htmleditor not exist !\n");
        }
        print(STDOUT "[INFO] Edition of '$outfile' with '$htmleditor' completed.\n") if not $quiet;
        #print(STDOUT "Edit $outfile with $htmleditor. Press return when finished.\n") if not $quiet;
        #<STDIN>
    }

}

# View with file explorer
sub viewwithfileexplorer {
    my ($viewrecord, $fileexplorer, $outfiledir, $quiet) = @_;

    if ($viewrecord) {
        my $fileexplorer = `which $fileexplorer`;
        chomp($fileexplorer);
        if ($fileexplorer) {
            system("$fileexplorer \"$outfiledir\" 1>/dev/null 2>/dev/null");
            print(STDOUT "[INFO] End of show of '$outfiledir' with '$fileexplorer'.\n") if not $quiet;
        } else {
            print(STDOUT "[WARN] File explorer $fileexplorer not exist !\n");
        }
        print(STDOUT "[INFO] Show '$outfiledir' with '$fileexplorer' completed.\n") if not $quiet;
        #print(STDOUT "Show $outfiledir with $fileexplorer. Press return when finished.\n") if not $quiet;
        #<STDIN>
    }
}

sub addheader {
    my ($FOUT, $outfilename_noext, $mycsscontents) = @_;

    print $FOUT <<"/html";
<!DOCTYPE html>
<html>
	<head>
		<title>$outfilename_noext</title>
    <meta charset="UTF-8" />
	</head>
	<body>
        <style>$mycsscontents</style>
		<h1>$outfilename_noext</h1>
/html
}

sub addfooter {
    my ($FOUT) = @_;

	print $FOUT <<"/html";
		<div class="footer">
			<i>Made using <a href="https://github.com/olivierlab/xsr" target="_blank">X Steps Recorder</a>.</i>
		</div>
	</body>
</html>
/html
}
1;
