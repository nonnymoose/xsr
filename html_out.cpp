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

const std::string mimetype = "image/png;base64,";
std::ofstream fout;

bool this_thread_exit_cleanly = false; // this thread has its own because it needs to empty the queue first.

bool checkData() {
	bool result;
	XSRDataQueueMutex.lock();
	result = ! XSRDataQueue.empty();
	XSRDataQueueMutex.unlock();
	return result;
}

void writeScreenshot(XImage* screenshot) {
	std::vector<unsigned char> pngimage = XImageToPNG(screenshot);
	XDestroyImage(screenshot);
	// std::cerr << "Successfully destroyed image" << std::endl;
	fout << mimetype << base64_encode(&pngimage[0], pngimage.size());
}

void* html_out(void *) {
	fout.open(options.outfile);
	fout << XSR_HTML::header << "\n" << XSR_HTML::title() << "\n";
	while (! this_thread_exit_cleanly) {
		std::unique_lock<std::mutex> dataLock(XSRDataQueueMutex);
		XSRDataAvailable.wait(dataLock, []{return XSRDataAvailableBoolean;});
		dataLock.unlock();
		while (checkData() && ! this_thread_exit_cleanly) {
			XSRData thisData;
			XSRDataQueueMutex.lock();
			thisData = std::move(XSRDataQueue.front());
			XSRDataQueue.pop();
			XSRDataQueueMutex.unlock();
			fout << XSR_HTML::tags::instruction << "\n" << XSR_HTML::tags::instruction_title;
			switch (thisData.type()) {
				case XSRDataType::typing:
				{
					fout << "Type: ";
					for (auto i = thisData.presses.begin(); i != thisData.presses.end(); i++) {
						if (i->isModifier) {
							fout << "<kbd>" << i->description << "</kbd>+";
						}
						else if (i->description.size() == 1) {
							fout << i->description;
						}
						else {
							fout << "<kbd>" << i->description << "</kbd>";
						}
					}
					fout << '\n';
					break;
				}
				case XSRDataType::click:
				{
					for (auto i = thisData.presses.begin(); i != thisData.presses.end(); i++) {
						if (i->isModifier) {
							fout << "<kbd>" << i->description << "</kbd>+";
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
		}
	}
	fout << XSR_HTML::footer;
	fout.close();
	// std::cerr << "thread html_out clean exit" << std::endl;
	return 0;
}
