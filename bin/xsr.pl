#!/usr/bin/env perl

use utf8;
use Time::HiRes qw/gettimeofday/;
use sigtrap qw/handler finish normal-signals/;
use Cwd qw(cwd abs_path);
use File::Copy qw(copy);
use File::Path qw(remove_tree);
use File::Basename;
use HTML::Entities qw(encode_entities);
use Encode qw(encode decode);
use MIME::Base64 qw(encode_base64); # internal Base64 (see #41)
use strict;
use warnings;
use Getopt::Long;

my $parentscriptdir = getabsolutescriptdir();

# External functions
use lib::relative "../lib";

use xsr::Functions;

my $istakescreenshot = 0;
my $lang = "en"; # "fr"
my $outfile = "$parentscriptdir/html/Untitled Recording.html";
my $FOUT; # output filehandle
my $XIN;
my $verbose = 0;
my $quiet = 0;
my $editimages = 0;
my $imageEditor = "xdg-open"; # fotoxx, gwenview, darktable
my $imagedeps = 1;
my $imageabspath = 0;
my $imgext="png";
my $screenshotmode = "focus"; # all or select
my $countdown = 5;
my $screeni = 0; # counter for screenshot number
my $cursor = "$parentscriptdir/cursor/default.png";
my $css = "$parentscriptdir/css/tuto.css";
my $nomouse = 0;
my $edithtml = 0;
my $htmleditor = ""; # bluegriffon, komposer (sea-monkey)
my $viewrecord = 0;
my $fileexplorer = "xdg-open"; # dolphin
my $isdelayed = 0;
my $islegend = 0;
my $ispaused = 0;
my $finalreturn = 0;
my $withwatermark = 0;
my $watermarkfile = undef;
my %mimetypes = (
	"png", "image/png",
	"jpg", "image/jpeg",
	"jpeg", "image/jpeg"
);
my @mousegrabs = ();
my @windowgrabs = ();
my $cursorw = 10; # cursor width
my $cursorh = 10; # cursor height

GetOptions (
	"out|o=s" => \$outfile,
	"images-absolute-path|p" => \$imageabspath,
	"edit-images-before-save|e" => \$editimages,
	"images-editor|i=s" => \$imageEditor,
	"edit-html|s" => \$edithtml,
	"html-editor|t=s" => \$htmleditor,
	"view-record|r" => \$viewrecord,
	"file-explorer|f=s" => \$fileexplorer,
	"image-deps|d" => \$imagedeps,
	"image-extension|c=s" => \$imgext,
	"lang|l=s" => \$lang,
	"screenshot-mode|u=s" => \$screenshotmode,
	"verbose|v" => \$verbose,
	"quiet|q" => \$quiet,
	"need-final-return|z" => \$finalreturn,
	"legend|g" => \$islegend,
	"mouse-icon|cursor=s" => \$cursor,
	"watermark|w=s" => \$watermarkfile,
	"add-watermark|a" => \$withwatermark,
	"css=s" => \$css,
	"countdown:i" => \$countdown,
	"no-countdown" => sub {$countdown = 0},
	"no-mouse" => \$nomouse,
	"help|h" => sub {print(STDOUT xsr::Functions::usage($outfile, $lang, $countdown, $imageEditor, $imgext, $cursor, $htmleditor, $css, $fileexplorer, $screenshotmode)); exit(0);}
	) or die("[ERROR] $!\n" . xsr::Functions::usage($outfile, $lang, $countdown, $imageEditor, $imgext, $cursor, $htmleditor, $css, $fileexplorer, $screenshotmode));

my $realcharsfile = "$parentscriptdir/langs/$lang/realchars.props";
my $translatefile = "$parentscriptdir/langs/$lang/translate.props";
my $altfile = "$parentscriptdir/langs/$lang/alt.props";
my $realbuttonsfile = "$parentscriptdir/langs/$lang/realbuttons.props";
my $modifiersfile = "$parentscriptdir/langs/$lang/modifiers.props";

if (@ARGV == 1) {
	$outfile = $ARGV[0];
}
elsif (@ARGV == 0) {
	#fine.
    #print(STDOUT xsr::Functions::usage($outfile, $lang, $countdown, $imageEditor, $imgext, $cursor, $htmleditor, $css, $fileexplorer, $screenshotmode));
	warn("[WARN] Default HTML file $outfile used\n");
}
else {
	print(STDOUT xsr::Functions::usage($outfile, $lang, $countdown, $imageEditor, $imgext, $cursor, $htmleditor, $css, $fileexplorer, $screenshotmode));
	die("[ERROR] Too many arguments.\n");
}

if ($quiet) {$countdown = 0;}

($cursor, $nomouse) = xsr::Functions::getcursor($cursor, $nomouse);

($withwatermark, $watermarkfile) = xsr::Functions::getwatermark($withwatermark, $watermarkfile);

my ($outfilename, $outfilename_noext, $outfiledir) = xsr::Functions::getoutfileinfos($outfile);

my $mimetype = xsr::Functions::getmimetype(\%mimetypes, $imgext);

my $scrot = xsr::Functions::getexternaltool("scrot", "cannot take screenshots");

# check for features, warn and do not use if unavailable
# only check if mouse will be used for first two
my $xdotool;
my $composite;
if (not $nomouse) {
    # xdotool
	$xdotool = xsr::Functions::getexternaltool("xdotool", "mouse cursor will not appear in screenshots");

	# composite
	$composite = xsr::Functions::getexternaltool("composite", "mouse cursor will not appear in screenshots");

    ($cursorw, $cursorh) = xsr::Functions::getcursorsize($cursor);

    # mouse on screenshot always possible ?
	$nomouse = not ($xdotool && $composite);
}

# change to a temporary directory
#my $originaldir = cwd;
my $tmpdir = `mktemp -d`;
chomp($tmpdir); # mktemp returns a newline
chdir($tmpdir) or die("[ERROR] $! Is /tmp mounted?\n");

# ===========================================
#      Load properties files
# ===========================================
my %realchars = xsr::Functions::loadpropertiesfile($realcharsfile); # Load realchars
my %translate = xsr::Functions::loadpropertiesfile($translatefile); # translations
my %alt = xsr::Functions::loadpropertiesfile($altfile); # alt
my %realbuttons = xsr::Functions::loadpropertiesfile($realbuttonsfile); # realbuttons
$realbuttons{"0"} = undef;
my %modifiers = xsr::Functions::loadpropertiesfile($modifiersfile); # modifiers

xsr::Functions::showinstructions(\%translate);

xsr::Functions::begincountdown($countdown, \%translate);

my ($ref_k, $ref_K, $ref_Ka) = xsr::Functions::getnormalshiftaltkey();
my %k = %{$ref_k};
my %K = %{$ref_K};
my %Ka = %{$ref_Ka};

my @m = xsr::Functions::getmodmap();

my $mregex = "(shift|meta|alt|super|mod|lock|control|pause)"; # a regex to tell whether a KeyPress is a modifier or not

my $typing = 0; #boolean tracking whether the user is typing
my $mytypingtext = "";

# ==============================================================
#                             Functions
# ==============================================================

# get absolute script dir
sub getabsolutescriptdir {
    my ($scriptfilename, $relativescriptdir, $scriptsuffix) = fileparse(__FILE__);
    my $scriptdir = abs_path($relativescriptdir);
    return "$scriptdir/..";
}

sub finish {
	print(STDOUT "\n") if not $quiet;
	if ($FOUT) {
		$typing = xsr::Functions::handletypingstate($FOUT, $typing, $quiet, $mytypingtext);
		print $FOUT <<"/html";
		<div class="footer">
			<i>Made using <a href="https://github.com/olivierlab/xsr">X Steps Recorder</a>.</i>
		</div>
	</body>
</html>
/html

		$FOUT->flush();
		close($FOUT);
		close($XIN);

        if (not $screenshotmode eq "select") {
            # add cursor only with screenshot mode all and focus
            xsr::Functions::addcursortoimage($xdotool, $composite, $nomouse, \@mousegrabs, \@windowgrabs, $cursorw, $cursorh, $cursor, $imgext);
        }

		# Wait here if user wants to edit the images
		xsr::Functions::editimages($editimages, $imageEditor, $tmpdir, $quiet);

        xsr::Functions::writefinalfileintohtml($imagedeps, $imageabspath, $outfiledir, $outfilename_noext, $mimetype);

		# copy images into destination directory
		xsr::Functions::copyimagetodest($outfiledir, $imagedeps, $outfilename_noext, $screeni, $tmpdir, $imgext, $withwatermark, $watermarkfile);

		# put the output in the original directory
		copy "$tmpdir/tmpencoded.html", $outfilename or warn("[WARN] Could not write to output: $!");

		remove_tree $tmpdir or warn("[WARN] Unable to remove temporary directory; junk remains in $tmpdir");

        # Edit with HTML editor to modify text
        xsr::Functions::edithtmlfile($edithtml, $htmleditor, $outfile, $quiet);

        # View with file explorer
        xsr::Functions::viewwithfileexplorer($viewrecord, $fileexplorer, $outfiledir, $quiet);
	}

	# need to press return to stop script
	if ($finalreturn) {
        my $translation = $translate{"pressreturn"};
        print(STDOUT ">>> $translation\n") if not $quiet;
        <STDIN>;
    }

	exit();
}

# open output file (NOTE: no safety here! Watch out!)
open($FOUT, ">", "tmpassoconly.html") or warn("[WARN] Could not open temporary output file");

# print header
my $mycsscontents = xsr::Functions::readfileintovar($css);
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

# execute xinput with the monitoring options
open($XIN, "-|", "xinput --test-xi2 --root") or die("[ERROR] Unable to watch for X input events");

# =======================================================
# $ xinput --test-xi2 --root
#
#     EVENT type 2 (KeyPress)
#         device: 8 (8)
#         detail: 37
#         flags:
#         root: 2582.00/913.00
#         event: 2582.00/913.00
#         buttons:
#         modifiers: locked 0x10 latched 0 base 0 effective: 0x10
#         group: locked 0 latched 0 base 0 effective: 0
#         valuators:
#         windows: root 0x49c event 0x49c child 0x1c0044e
# =======================================================

my $e;
my $d;
my $movedsince;
my $lastscroll = 0;
my $buttondown = gettimeofday();
my $valstep = 1;
my $fuck = gettimeofday(); # store time of buttonpress
MAINLOOP: while (<$XIN>) {
    if ($istakescreenshot) {
        if (gettimeofday() - $fuck >= .075) {
            $istakescreenshot = 0;
        }
        $fuck = gettimeofday(); # store time of buttonpress
        next;
    }
	if (/^EVENT type.*\((.*)\)/) {
        $e = $1; # store event type in $e
    }
	elsif (/detail: (\d+)/) {
        $d = $1; # store event detail in $d
    }
	elsif (/modifiers:.*effective: (.*)/) { # do the real work now that we have all of the information
		my $m=$1; # store modifier counter in $m

        # ------------------------------------------------------------
        #                    MANAGEMENT key pressed
        # ------------------------------------------------------------
		if ($e =~ /^KeyPress/) { # handle typing
			$lastscroll = 0; # definitely not scrolling anymore
			my $key = xsr::Functions::getrealchar($k{$d}, \%realchars); # get machine-readable name from detail, then get human-readable name from that
			#print(STDOUT "[DEBUG] $key\n");

			# ------------------------------------------------------
			# get modifiers
			# ------------------------------------------------------
			my @mods;
			for (0..$#m) {
				if (hex($m) & (1<<$_)) { # this is the tricky part
					# xinput returns a hexadecimal string that converts to a byte
					#                   so, 00000000 if no modifier keys are pressed
					# the modifier order is 87654321
					# this loop goes through all modifiers and checks if their bit is set
					if ($m[$_] =~ /iso_level3/i) { # if AltGr is pressed
						if (xsr::Functions::getrealchar($Ka{$d}, \%realchars) ne "NoSymbol") {
                            $key = $alt{$Ka{$d}}; # get its third level, if there is one
						}
						else {
							push(@mods, $m[$_]); # otherwise DO add shift to modifier list
						}
					}
					elsif ($k{$d} =~ /^KP_/i && $m[$_] =~ /num.*lock/i) { # if it's a keypad key and num lock is on
						$key = xsr::Functions::getrealchar($K{$d}, \%realchars) unless xsr::Functions::getrealchar($K{$d}, \%realchars) eq "NoSymbol"; # get its second level (if there is one)
					}
					elsif ($m[$_] =~ /num.*lock/i) {
						# do nothing, num lock should not appear in the modifier array
					}
					elsif ($m[$_] =~ /shift/i) { # if shift is pressed for uppercase letters
						if (xsr::Functions::getrealchar($K{$d}, \%realchars) ne "NoSymbol") {
							$key = xsr::Functions::getrealchar($K{$d}, \%realchars); # get its second level, if there is one
						}
						else {
							push(@mods, $m[$_]); # otherwise DO add shift to modifier list
						}
					}
					else {
						push(@mods, $m[$_]); # add any other modifier to the list
					}
				}
			}

			# ------------------------------------------------------
			# management of keys that interact with the application
			# ------------------------------------------------------

			# quit if the user presses Break
			if ($key =~ /^break$/i) {
                last MAINLOOP;
            }

            # Manage Pause key
			if ($key =~ /Pause/) {
				if ($ispaused) {
					$ispaused = 0;
					xsr::Functions::printinfotranlated("pauseinactif", \%translate);
				} else {
					$ispaused = 1;
					xsr::Functions::printinfotranlated("pauseactif", \%translate);
				}
			}

			# if pause active, we do nothing
			if ($ispaused) {
				next;
			}

			# add a delay before screenshot when Scroll lock is pressed
			# or a step when Shift + Scroll lock is pressed
			if ($key =~ /Scroll_Lock/) {
                if (@mods > 0) {
                    # detect shift modifier pressed
                    my $shiftpressed = 0;
                    for (0..$#mods) {
                        $shiftpressed = 1 if $mods[$_] =~ /shift/i;
                    }
                    if ($shiftpressed) {
                        $typing = xsr::Functions::handletypingstate($FOUT, $typing, $quiet, $mytypingtext);
                        xsr::Functions::printetape($FOUT, $valstep, \%translate);
                        $valstep++;
                    }
                } else {
                    if ($isdelayed) {
                        $isdelayed = 0;
                        xsr::Functions::printinfotranlated("slinactif", \%translate);
                    } else {
                        $isdelayed = 1;
                        xsr::Functions::printinfotranlated("slactif", \%translate);
                    }
                }
                # Don't memorize Scroll Lock key
                next;
			}

			# skip this iteration if the key is a modifier
			if ($key =~ /$mregex/i) {
				next;
			}

			# ------------------------------------------------------
			# Print of typed keys
			# ------------------------------------------------------
			# print a type instruction if not already typing, then note that already typing from now on
			if (! $typing) {
                my $translation = $translate{"type"};
                $mytypingtext = "$translation : ";
                $typing = 1
            }
			if (@mods > 0) {
				for (0..$#mods) {
                    $mytypingtext .= "<span class=\"kbd\">$modifiers{$mods[$_]}</span>+";
                    print(STDOUT "$modifiers{$mods[$_]}+") if not $quiet;
                } # if there are modifiers in effect, print as a sequence of keys
				$mytypingtext .= "<span class=\"kbd\">$key</span>";
				print(STDOUT "$key") if not $quiet;
			}
			elsif (length($key) == 1) {
				$mytypingtext .= "$key"; # if the realchar of a key is a single character, don't style it as a key
				print(STDOUT "$key") if not $quiet;
			}
			else {
				$mytypingtext .= "<span class=\"kbd\">$key</span>"; # else style it as a key
				print(STDOUT "$key") if not $quiet;
			}
			if ($k{$d} =~ /Return|Enter/i) {
                print(STDOUT "\n") if $typing && not $quiet;
                #print(STDOUT "1: $XIN\n");
				(my $shotnumber, $screeni, my $ref_windowgrabs, my $ref_mousegrabs, $istakescreenshot) = xsr::Functions::takescreenshot(\%translate, $xdotool, $composite, $nomouse, \@windowgrabs, \@mousegrabs, $isdelayed, $screenshotmode, $imgext, $quiet, $screeni);

                @windowgrabs = @{$ref_windowgrabs};
                @mousegrabs = @{$ref_mousegrabs};
				xsr::Functions::printtitleandimage($FOUT, "$shotnumber.$imgext", "$mytypingtext", $islegend);
				$typing = 0; # reprint "Type:" and the like next time

				$fuck = gettimeofday(); # store time of buttonpress
			} # if the user presses return, then end the type instruction and add a screenshot
        }

        # ------------------------------------------------------------
        #                 MANAGE mouse action
        # ------------------------------------------------------------
        if ($ispaused) {
            # on pause, we do not manage the mouse buttons
            next;
        }
		if ($e =~ /^ButtonPress/) { # process mouse events (for some reason, maximized windows don't return standard motion events)
			if ($d == 0) {
				# WHAT THE HECK!?!?!?!?
				# This should not happen and will cause problems. Skip it.
				next;
			}
			$typing = xsr::Functions::handletypingstate($FOUT, $typing, $quiet, $mytypingtext);
			$movedsince = 0; # haven't moved yet since this button press
			my $mousebutton = xsr::Functions::getrealbutton($d, \%realbuttons);
			unless ($d == $lastscroll || $mousebutton =~ /scroll/i) { # only do printing and stuff if this is not a second or later scroll event
                (my $shotnumber, $screeni, my $ref_windowgrabs, my $ref_mousegrabs, $istakescreenshot) = xsr::Functions::takescreenshot(\%translate, $xdotool, $composite, $nomouse, \@windowgrabs, \@mousegrabs, $isdelayed, $screenshotmode, $imgext, $quiet, $screeni);

                @windowgrabs = @{$ref_windowgrabs};
                @mousegrabs = @{$ref_mousegrabs};
                $buttondown = gettimeofday(); # store time of buttonpress
				my $mytitle = "";
				# get modifiers
				my @mods;
				for (0..$#m) {
					if (hex($m) & (1<<$_)) {
						if ($m[$_] =~ /num.*lock/i) {
							# do nothing, does not affect clicking
						}
						else {
							push(@mods, $m[$_]); # get modifiers
						}
					}
				}
				if (@mods > 0) {
					for (0..$#mods) {
                        $mytitle .= "<span class=\"kbd\">$mods[$_]</span>+";
                    } # print modifiers if necessary
				}
				$mytitle .= xsr::Functions::getrealbutton($d, \%realbuttons);
				if ($d == 4 || $d == 5) {
                    # if scrolling, don't recognize any more events in the same direction until we stop scrolling
                    $lastscroll = $d
				} else {
                    # we stopped scrolling because we clicked or something
                    $lastscroll = 0
                }
				if ($xdotool) { # Add application title
					my $apptitle = encode_entities(decode(q(UTF-8), `xdotool getwindowfocus getwindowname`));
					chomp($apptitle);
					my $field = "in";
                    $mytitle .= " $translate{$field} <span class=\"apptitle\">$apptitle</span>";
				} else {
                    my $field = "notitle";
					$mytitle .= " ($translate{$field})";
				}

				xsr::Functions::printtitleandimage($FOUT, "$shotnumber.$imgext", "$mytitle", $islegend);
				$fuck = gettimeofday(); # store time of buttonpress
			}
		}
		elsif ($e =~ /^Motion/) {
			$movedsince = 1; # moved since clicked
		}
		elsif ($e =~ /^ButtonRelease/){
			$typing = xsr::Functions::handletypingstate($FOUT, $typing, $quiet, $mytypingtext);
			if (gettimeofday() - $buttondown >= .075 && $movedsince) { # if we have moved the mouse since clicking and it's been more than 0.075 seconds, recognize it as a click and drag
																																 # This is very similar to the system default
				(my $shotnumber, $screeni, my $ref_windowgrabs, my $ref_mousegrabs, $istakescreenshot) = xsr::Functions::takescreenshot(\%translate, $xdotool, $composite, $nomouse, \@windowgrabs, \@mousegrabs, $isdelayed, $screenshotmode, $imgext, $quiet, $screeni);

                @windowgrabs = @{$ref_windowgrabs};
                @mousegrabs = @{$ref_mousegrabs};
				my $field = "drag";

				xsr::Functions::printtitleandimage($FOUT, "$shotnumber.$imgext", "$translate{$field}", $islegend);
				$fuck = gettimeofday(); # store time of buttonpress
			}
		}
	}
}

finish();
