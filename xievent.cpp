#include <iostream>
#include <string>
#include <set>
#include <map>
#include <vector>
#include <queue>
#include <mutex>
#include <atomic>
#include <condition_variable>
#include <list>
#include <X11/extensions/XInput2.h>
#include <X11/Xlib.h>
#include <X11/Xutil.h>
#include <X11/XKBlib.h>
#include "signal_handler.h"
#include "xsrdata.h"
#include "xievent.h"

std::set<KeyCode> modifierKeyCodes;
std::map<int, std::string> modifierBitMap;

std::queue<XSRData> XSRDataQueue;
std::mutex XSRDataQueueMutex;
std::condition_variable XSRDataAvailable;
bool XSRDataAvailableBoolean = false;

std::list<XSRPress> typed_string;

#include "remap.h"


void setupModifiers(Display *display) {
	// get modifier map
	XModifierKeymap *modmap = XGetModifierMapping(display);
	KeyCode *modmap2 = modmap->modifiermap;
	for (int i = 0; i < modmap->max_keypermod * 8; i++) { // create a set for fast checking whether a key is a modifier
		if (modmap2[i] != 0x0) {
			modifierKeyCodes.insert(modmap2[i]);
		}
	}
	for (int i = 0; i < 8; i++) { // create a map for locating modifiers
		// std::cerr << "Level " << i << ": ";
		const char *mod_cstring;
		KeySym intermediate_keysym = XkbKeycodeToKeysym(display, modmap2[i*modmap->max_keypermod], 0, 0);
		if (intermediate_keysym != 0x0) {
			mod_cstring = XKeysymToString(intermediate_keysym);
		}
		else {
			mod_cstring = "NoSymbol";
		}
		std::string mod = mod_cstring;
		if (mod.back() == 'L' || mod.back() == 'R') {
			mod.pop_back();
			mod.pop_back(); // since we're only deleting 2 chars I'm pretty sure this is the fastest way
		}
		// std::cerr << mod << '\n';
		modifierBitMap[1 << i] = mod;
	}

	XFreeModifiermap(modmap);
}

// std::string getModifiers() {
//
// }

void sendData(XSRData&& toSend) { // must be moved here!
	if (! typed_string.empty()) { // if typed_string was sent here then it will be empty!
		XSRData sendString((XImage*) nullptr, std::move(typed_string), XSRDataType::typing);
		typed_string.clear();
		XSRDataQueueMutex.lock();
		XSRDataQueue.push(std::move(sendString));
		XSRDataQueueMutex.unlock();
	}
	XSRDataQueueMutex.lock();
	XSRDataQueue.push(std::move(toSend));
	XSRDataQueueMutex.unlock();	// minimize the time the mutex is left locked!
	XSRDataAvailableBoolean = true;
	XSRDataAvailable.notify_all();
}

Display *display;
Window captureWindow;

XImage* takeScreenShot() {
	XWindowAttributes rootwinattrib; // used for image width and height
	XGetWindowAttributes(display, captureWindow, &rootwinattrib);
	
	int height = rootwinattrib.height;
	int width = rootwinattrib.width;
	
	return XGetImage(display, captureWindow, 0, 0, width, height, AllPlanes, ZPixmap); // take image
}

void* xievent(void *) {
	display = XOpenDisplay(NULL);
	
	setupModifiers(display);
	
	// begin to capture events
	XIEventMask captureEvents;
	captureWindow = DefaultRootWindow(display);
	captureEvents.deviceid = XIAllDevices;
	captureEvents.mask_len = XIMaskLen(XI_LASTEVENT);
	// unsigned char *mymask = new unsigned char [captureEvents.mask_len];
	std::vector<unsigned char> mymask(captureEvents.mask_len);
	captureEvents.mask = &mymask[0];
	XISetMask(captureEvents.mask, XI_KeyPress);
	XISetMask(captureEvents.mask, XI_KeyRelease);
	XISetMask(captureEvents.mask, XI_ButtonPress);
	XISetMask(captureEvents.mask, XI_ButtonRelease);
	XISetMask(captureEvents.mask, XI_Motion);
	
	XISelectEvents(display, captureWindow, &captureEvents, 1); // 1 mask
	XSync(display, false); // only doing this because xinput did
	
	bool lastKeyWasModifier = false;
	bool draggedSincePress = false;
	short int lastScrollDirection = 0; //-1 for down, 1 for up
	
	while (! exit_cleanly) {
		XEvent ev;
		XNextEvent(display, &ev);
		XGenericEventCookie *cookie = &ev.xcookie;
		if (XGetEventData(display, cookie) && cookie->type == GenericEvent /*&& cookie->extension == xi_opcode*/) { // I'm 90% sure that's safe to ignore. If not, make an issue ;)
			XIDeviceEvent *event;
			event = (XIDeviceEvent*) cookie->data;
			switch (cookie->evtype) {
				case XI_KeyPress:
					{
						lastScrollDirection = 0;
						std::string key = XKeysymToString(XkbKeycodeToKeysym(display, event->detail, 0, 0));
						bool shifted = false;
						if (modifierKeyCodes.find(event->detail) == modifierKeyCodes.end()) { // only print it if it's not a modifier
							lastKeyWasModifier = false;
							for (auto i: modifierBitMap) {
								if (event->mods.effective & i.first) { // check each modifier bit and print if significant
									if (key.substr(0, 3) == "KP_") { // numpad
										std::string upperKey = XKeysymToString(XkbKeycodeToKeysym(display, event->detail, 0, 1));
										if (i.second == "Num_Lock" && ((upperKey.size() == 4 && upperKey[3] >= '0' && upperKey[3] <= '9') || upperKey == "KP_Decimal")) { // only 11 keys affected by Num_Lock (different for others?)
											key = upperKey; // next level
										}
										else if (i.second != "Caps_Lock"&& i.second != "Num_Lock") {
											// std::cerr << "<kbd>" << i.second << "</kbd>+";
											typed_string.emplace_back(i.second, true);
										}
										key.erase(0, 3); // delete preceding KP_
									}
									else if (i.second == "Num_Lock") {
										// worthless
									}
									else if (i.second == "Caps_Lock" && key.size() == 1 && key[0] >= 'a' && key[0] <= 'z') {
										key = XKeysymToString(XkbKeycodeToKeysym(display, event->detail, 0, !shifted)); // next level (or down one in the case that shift was pressed too)
									}
									else if (i.second == "Shift") {
										std::string keyUP = XKeysymToString(XkbKeycodeToKeysym(display, event->detail, 0, 1)); // next level
										if (keyUP != "NoSymbol" && keyUP != key) {
											key = keyUP; // only apply it if the key has a second level
											shifted = true;
										}
										else {
											// std::cerr << "<kbd>" << i.second << "</kbd>+"; // else print out shift as part of the modifiers
											typed_string.emplace_back(i.second, true);
										}
									}
									else {
										// std::cerr << "<kbd>" << i.second << "</kbd>+";
										typed_string.emplace_back(i.second, true);
									}
								}
							}
							// we could use XLookupString(3) instead of lookup tables, but it's slower and only supports latin characters, while lookup tables could easily be extended to support e.g. cyrillic
							auto lookedUpKey = lookup.find(key);
							if (lookedUpKey != lookup.end()) {
								key = lookedUpKey->second;
							}
							// if (key.size() > 1) {
							// 	key = "<kbd>" + key + "</kbd>";
							// }
							// std::cerr << key;
							typed_string.emplace_back(key, false);
							if (key == "Enter" || key == "Return" || key == "Linefeed") {
								// screenshot
								XSRData thisData(takeScreenShot(), std::move(typed_string), XSRDataType::typing);
								typed_string.clear();
								sendData(std::move(thisData));
							}
						}
						else {
							lastKeyWasModifier = true;
						}
						break;
					}
				case XI_KeyRelease:
					{
						lastScrollDirection = 0;
						std::string key = XKeysymToString(XkbKeycodeToKeysym(display, event->detail, 0, 0));
						if (modifierKeyCodes.find(event->detail) != modifierKeyCodes.end() && lastKeyWasModifier) {
							lastKeyWasModifier = false;
							// send modifiers
							if (key.back() == 'L' || key.back() == 'R') {
								key.pop_back();
								key.pop_back(); // since we're only deleting 2 chars I'm pretty sure this is the fastest way
							}
							for (auto i: modifierBitMap) {
								if (event->mods.effective & i.first && i.second != key && i.second != "Num_Lock" && i.second != "Caps_Lock") { // check each modifier bit and print if significant
									// std::cerr << "<kbd>" << i.second << "</kbd>+";
									typed_string.emplace_back(i.second, true);
								}
							}
							// std::cerr << "<kbd>" << key << "</kbd>";
							typed_string.emplace_back(key, false);
						}
						break;
					}
				case XI_ButtonPress:
					{
						// screenshot
						XImage *thisScreenShot = nullptr;
						draggedSincePress = false;
						lastKeyWasModifier = false;
						// ensure that scroll events aren't repeated in the output (that would be awful)
						if (event->detail == 4 || event->detail == 7) {
							if (1 == lastScrollDirection) {
								break;
							}
							else {
								lastScrollDirection = 1;
							}
						}
						else if (event->detail == 5 || event->detail == 6) {
							if (-1 == lastScrollDirection) {
								break;
							}
							else {
								lastScrollDirection = -1;
							}
						} // there HAS to be a better way to do this!
						else {
							thisScreenShot = takeScreenShot();
							lastScrollDirection = 0;
						}
						XSRData thisData(thisScreenShot, XSRDataType::click); // don't take a screenshot for scroll events
						for (auto i: modifierBitMap) {
							if (event->mods.effective & i.first && i.second != "Num_Lock" && i.second != "Caps_Lock") { // check each modifier bit and print if significant
								// std::cerr << "<kbd>" << i.second << "</kbd>+";
								thisData.presses.emplace_back(i.second, true);
							}
						}
						auto lookedUpButton = lookupmouse.find(event->detail);
						if (lookedUpButton != lookupmouse.end()) {
							// std::cerr << lookedUpButton->second;
							thisData.presses.emplace_back(lookedUpButton->second, false);
						}
						else {
							// std::cerr << "Mouse button " << event->detail;
							thisData.presses.emplace_back("Mouse button " + std::to_string(event->detail), false);
						}
						sendData(std::move(thisData));
						break;
					}
				case XI_Motion:
					draggedSincePress = true;
					break;
				case XI_ButtonRelease:
					{
						if (draggedSincePress) {
							draggedSincePress = false;
							// screenshot
							// std::cerr << "... and drag.";
							XSRData thisData(takeScreenShot(), XSRDataType::drag);
							sendData(std::move(thisData));
						}
						break;
					}
				default:
					// std::cerr << "PROBLEM";
					break;
			}
		}
	}
	XSRData thisData((XImage*)nullptr, XSRDataType::EXIT);
	sendData(std::move(thisData));
	// std::cerr << "thread xievent clean exit" << std::endl;
	return 0;
}
