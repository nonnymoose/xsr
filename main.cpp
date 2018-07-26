#include <iostream>
#include <atomic>
// #include <thread>
#include <pthread.h> // I would use std::thread but there's no support for catching signals
#include <thread> // only for sleep, not included in any other files
#include <chrono> // same
#include "arg_parser.h"
#include "signal_handler.h"
#include "xievent.h"
#include "html_out.h"
#include <string>
#include <X11/extensions/XInput2.h>

int main(int argc, char** argv) {
	// process arguments
	if (parse_arguments(argc, argv)) {return 1;} // return if instructed to do so by parse_arguments
	setup_signal_handler();
	if (! options.quiet) {
		std::cerr << "Starting in " << options.countdown;
		for (int i = options.countdown - 1; i >= 0; i--) { // start as soon as i reaches 0
			std::this_thread::sleep_for(std::chrono::seconds(1));
			std::cerr << "\b" << i;
		}
		std::cerr << std::endl;
	}
	pthread_t eventHandler;
	pthread_t htmlHandler;
	pthread_create(&eventHandler, NULL, xievent, NULL);
	pthread_create(&htmlHandler, NULL, html_out, NULL);
	pthread_join(eventHandler, nullptr);
	pthread_join(htmlHandler, nullptr);
	// std::cerr << "Exiting cleanly now." << std::endl;
	return 0;
}
