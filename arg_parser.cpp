#include <getopt.h>
#include <string>
#include <iostream>
#include "arg_parser.h"

xsr_options options;

void show_help(char* progname) {
	std::cerr << "Usage: " << progname << " [options] [outfile]\n\
where options are:\n\n\
 --out|-o outfile		Write data to outfile instead of \n\
 				\"Untitled Recording.html\"\n\
 --image-extension|-c ext	Use the image format with extension ext. \n\
 				Default: png; supported: png\n\
 --quiet|-q			Do not print to stdout or stderr\n\
 				(except in case of a crash). Implied by \"-o -\"\n\
 --verbose|-v			Print detailed information to stdout or stderr\n\
 --very-verbose|-vv		Print even more detailed information, \n\
 				including about individual events!\n\
 --countdown sec			Wait sec seconds before beginning to record.\n\
 				Default 5\n\
 --no-countdown			Do not wait before beginning to record.\n\
 --mouse|-m			Include the mouse cursor in the screenshot (default)\n\
 --no-mouse			Do not include the mouse cursor\n\
https://github.com/nonnymoose/xsr" << std::endl; // this looks funny but it looks good on a terminal, okay? :P
}

bool parse_arguments (int argc, char** argv) {
	const char* shortoptions = "o:c:qhv";
	const struct option longoptions[] =
	{
		{"out", required_argument, nullptr, 'o'},
		{"image-extension", required_argument, nullptr, 'c'},
		{"quiet", no_argument, nullptr, 'q'},
		{"help", no_argument, nullptr, 'h'},
		{"verbose", no_argument, nullptr, 'v'},
		{"very-verbose", no_argument, nullptr, '!'},
		{"mouse", no_argument, nullptr, 1},
		{"no-mouse", no_argument, nullptr, 2},
		{"countdown", optional_argument, nullptr, 3},
		{"no-countdown", no_argument, nullptr, 4}
	};
	while (true) {
		const auto option = getopt_long(argc, argv, shortoptions, longoptions, nullptr);
		if (option == -1) {
			break; // at first I wanted to put this in a case -1: but you can't
		}
		switch (option) {
			case 'o':
				options.outfile = optarg;
				if (options.outfile == "-") {
					options.quiet = true;
					options.verbose = false;
					options.very_verbose = false;
				}
				break;
			//
			case 'c':
				options.image_ext = optarg;
				break;
			//
			case 'q':
				options.quiet = true;
				options.verbose = false;
				options.very_verbose = false;
				break;
			//
			case '?':
			case 'h':
				show_help(argv[0]); // show_help uses the program name
				return true; // do return
				break;
			//
			case 'v':
				if (options.verbose) {
					// this option was already specified! be more verbose
					options.very_verbose = true;
				}
				options.verbose = true;
				options.quiet = false;
				break;
			//
			case '!':
				options.very_verbose = true;
				options.verbose = true;
				options.quiet = false;
				break;
			//
			case 1:
				options.include_mouse = true;
				break;
			//
			case 2:
				options.include_mouse = false;
				break;
			//
			case 3:
				if (optarg) {
					options.countdown = std::stoi(optarg);
				}
				else {
					options.countdown = 5;
				}
				break;
			//
			case 4:
				options.countdown = 0;
				break;
			//
			default:
				//no-op
				break;
		}
	}
	if (optind < argc) {
		options.outfile = argv[optind++]; // output file specified on command line
	}
	if (optind < argc && ! options.quiet) {
		std::cerr << "Warning: One or more spurious non-option arguments!" << std::endl;
		// the reason I'm using std::endl in cerr even though it's unbuffered is we
		// might eventually change the output for these sorts of things to print to a bufferred output
	}
	return false;
}
