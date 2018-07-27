#include <string>
#include <regex>
#include <iostream>
#include <fstream>
#include <list>
#include <queue>
#include <mutex>
#include <atomic>
#include <condition_variable>
#include <X11/Xlib.h>
#include <X11/Xutil.h>
#include "base64/base64.h"
#include "arg_parser.h"
#include "signal_handler.h"
#include "html_out.h"
#include "html_template.h"
#include "xsrdata.h"
#include "to_png.h"

const std::string mimetype = "image/png;base64,"; // if we make other output formats this could be stored differently
std::ofstream fout;

bool this_thread_exit_cleanly = false; // this thread has its own because it needs to empty the queue first.

bool checkData() { // return whether there is data in the queue
	bool result;
	XSRDataQueueMutex.lock();
	result = ! XSRDataQueue.empty();
	XSRDataQueueMutex.unlock();
	return result;
}

void writeScreenshot(XImage* screenshot) {
	VVB std::cerr << '[' << __FILE__ << "] Begin writing screenshot" << std::endl;
	std::vector<unsigned char> pngimage = XImageToPNG(screenshot);
	XDestroyImage(screenshot);
	// std::cerr << "Successfully destroyed image" << std::endl;
	fout << mimetype << base64_encode(&pngimage[0], pngimage.size());
	VVB std::cerr << '[' << __FILE__ << "] Finish writing screenshot" << std::endl;
}

void* html_out(void *) {
	fout.open(options.outfile);
	if (options.verbose) std::cerr << '[' << __FILE__ << "] Opened outfile." << std::endl;
	fout << XSR_HTML::header << "\n" << XSR_HTML::title() << "\n"; // print out the html header + document title
	VVB std::cerr << '[' << __FILE__ << "] Wrote header" << std::endl;
	while (! this_thread_exit_cleanly) {
		std::unique_lock<std::mutex> dataLock(XSRDataQueueMutex);
		XSRDataAvailable.wait(dataLock, []{return XSRDataAvailableBoolean;}); // wait for stuff to be in the queue
		dataLock.unlock(); // do this to minimize queue locking time so that the other thread can write to it while we're processing data in the background
		while (checkData() && ! this_thread_exit_cleanly) {
			XSRData thisData;
			XSRDataQueueMutex.lock();
			thisData = std::move(XSRDataQueue.front());
			XSRDataQueue.pop();
			XSRDataQueueMutex.unlock();
			fout << XSR_HTML::tags::instruction << "\n" << XSR_HTML::tags::instruction_title;
			VVB std::cerr << '[' << __FILE__ << "] Wrote instruction and title tags" << std::endl;
			switch (thisData.type()) {
				case XSRDataType::typing:
				{
					fout << "Type: ";
					for (auto i = thisData.presses.begin(); i != thisData.presses.end(); i++) {
						if (i->isModifier) {
							fout << "<kbd>" << i->description << "</kbd>+"; // modifiers get styling
						}
						else if (i->description.size() == 1) {
							fout << i->description;
						}
						else {
							fout << "<kbd>" << i->description << "</kbd>"; // keys with descriptions longer than one character get styling
							// this includes the backspace (⌫) and delete (⌦) special characters!
							// this is because they are unicode and more than one byte. THIS IS INTENDED BEHAVIOR
						}
					}
					fout << '\n';
					break;
				}
				case XSRDataType::click:
				{
					for (auto i = thisData.presses.begin(); i != thisData.presses.end(); i++) {
						if (i->isModifier) {
							fout << "<kbd>" << i->description << "</kbd>+"; // modifiers on mouse clicks get treated as special keys (because they are)
						}
						else {
							fout << i->description;
						}
					}
					fout << '\n';
					break;
				}
				case XSRDataType::drag:
					fout << "... and drag." << '\n';
					break;
				case XSRDataType::EXIT:
					this_thread_exit_cleanly = true;
					fout << "[End recording]" << '\n';
					if (options.verbose) std::cerr << '[' << __FILE__ << "] End recording" << '\n';
					break;
				default:
					// std::cerr << "PROBLEM";
					break;
			}
			fout << XSR_HTML::tags::div_end << "\n";
			if (thisData.screenshot() != nullptr) {
				fout << XSR_HTML::tags::img_start;
				writeScreenshot(thisData.screenshot());
				fout << XSR_HTML::tags::img_end << "\n";
			}
			fout << XSR_HTML::tags::div_end << "\n";
			VVB std::cerr << '[' << __FILE__ << "] Closed instruction and title tags" << std::endl;
		}
	}
	fout << XSR_HTML::footer;
	VVB std::cerr << '[' << __FILE__ << "] Wrote footer" << std::endl;
	fout.close();
	if (options.verbose) std::cerr << '[' << __FILE__ << "] Closed outfile" << std::endl;
	if (options.verbose) std::cerr << '[' << __FILE__ << "] Clean exit" << std::endl;
	return 0;
}
