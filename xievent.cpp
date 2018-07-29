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
#include <X11/extensions/Xfixes.h>
#include <X11/Xlib.h>
#include <X11/Xutil.h>
#include <X11/XKBlib.h>
#include "signal_handler.h"
#include "arg_parser.h"
#include "xsrdata.h"
#include "xievent.h"

std::set<KeyCode> modifierKeyCodes; // for checking if a key is a modifier
std::map<int, std::string> modifierBitMap; // map individual modifiers to their descriptions

std::queue<XSRData> XSRDataQueue; // where the data collected by this thread gets sent for processing
std::mutex XSRDataQueueMutex; // makes sure we don't write to XSRDataQueue while another thread's reading
std::condition_variable XSRDataAvailable; // tells the other thread when there's data in the queue
bool XSRDataAvailableBoolean = false; // checked by the other thread to prevent spurious awakenings

std::list<XSRPress> typed_string; // the string the user is currently typing

#include "remap.h" // a map that renames badly described keys


void setupModifiers(Display *display) {
	// get modifier map
	XModifierKeymap *modmap = XGetModifierMapping(display);
	KeyCode *modmap2 = modmap->modifiermap;
	for (int i = 0; i < modmap->max_keypermod * 8; i++) { // create a set for fast checking whether a key is a modifier
		if (modmap2[i] != 0x0) { // if there is no key here, just skip it
			modifierKeyCodes.insert(modmap2[i]); // write the keycode to the set
		}
	}
	for (int i = 0; i < 8; i++) { // create a map for locating modifiers
		// std::cerr << "Level " << i << ": ";
		const char *mod_cstring;
		KeySym intermediate_keysym = XkbKeycodeToKeysym(display, modmap2[i*modmap->max_keypermod], 0, 0);
		if (intermediate_keysym != 0x0) { // if there's no modifier at this level, just skip it!
			mod_cstring = XKeysymToString(intermediate_keysym);
		}
		else {
			mod_cstring = "NoSymbol";
		}
		std::string mod = mod_cstring;
		if (mod.back() == 'L' || mod.back() == 'R') { // sometimes modifiers are named like Shift_L or Shift_R if there are two. We don't need this level of detail, so delete it
			mod.pop_back();
			mod.pop_back(); // since we're only deleting 2 chars I'm pretty sure this is the fastest way
		}
		// std::cerr << mod << '\n';
		modifierBitMap[1 << i] = mod; // each level gets its own bit, so that's how we'll check it too.
	}
	VB std::cerr << '[' << __FILE__ << "] Processed modifiers" << std::endl;

	XFreeModifiermap(modmap);
}

// std::string getModifiers() {
//
// }

void sendData(XSRData&& toSend) { // must be moved here!
	if (! typed_string.empty()) { // if typed_string was sent here then it will be empty!
		XSRData sendString((XImage*) nullptr, (XFixesCursorImage*) nullptr, std::move(typed_string), XSRDataType::typing); // create a type instruction with no screenshot if the user performs a different action afterwards
		typed_string.clear(); // at least some of the time the list is copied, not moved
		XSRDataQueueMutex.lock();
		XSRDataQueue.push(std::move(sendString));
		XSRDataQueueMutex.unlock();
	}
	XSRDataQueueMutex.lock();
	XSRDataQueue.push(std::move(toSend));
	XSRDataQueueMutex.unlock();	// minimize the time the mutex is left locked!
	XSRDataAvailableBoolean = true; // this only needs to be set here, and not when sending the typed_string data
	XSRDataAvailable.notify_all();
}

Display *display;
Window captureWindow;

XImage* takeScreenShot() {
	XWindowAttributes rootwinattrib; // used for image width and height
	XGetWindowAttributes(display, captureWindow, &rootwinattrib); // it's a good idea to call this every time in case the user does something funny
	
	int height = rootwinattrib.height;
	int width = rootwinattrib.width;
	
	return XGetImage(display, captureWindow, 0, 0, width, height, AllPlanes, ZPixmap); // take image
	// this returns a pointer which MUST be destroyed later using XDestroyImage(XImage*)
}

XFixesCursorImage* takeMouseShot() {
	if (options.include_mouse) {
		return XFixesGetCursorImage(display);
	}
	else {
		return nullptr;
	}
}

void* xievent(void *) {
	display = XOpenDisplay(NULL); // default display
	
	setupModifiers(display);
	
	// begin to capture events
	XIEventMask captureEvents;
	captureWindow = DefaultRootWindow(display); // I have no idea what this does with a multi-monitor setup
	captureEvents.deviceid = XIAllDevices; // mouse, keyboard, whatever. We want it all!
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
	short int lastScrollDirection = 0; // Used to prevent consecutive scroll directions in the same direction
	
	VB std::cerr << '[' << __FILE__ << "] Event collection started" << std::endl;
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
						lastScrollDirection = 0; // not scrolling anymore
						std::string key = XKeysymToString(XkbKeycodeToKeysym(display, event->detail, 0, 0));
						bool shifted = false; // whether or not to go up a level because the shift key is pressed
						if (modifierKeyCodes.find(event->detail) == modifierKeyCodes.end()) { // only print the press event if it's not a modifier
							lastKeyWasModifier = false;
							VVB std::cerr << '[' << __FILE__ << "] Keypress: ";
							for (auto i: modifierBitMap) {
								if (event->mods.effective & i.first) { // check each modifier bit and print if significant
									if (key.substr(0, 3) == "KP_") { // numpad
										std::string upperKey = XKeysymToString(XkbKeycodeToKeysym(display, event->detail, 0, 1));
										if (i.second == "Num_Lock" && ((upperKey.size() == 4 && upperKey[3] >= '0' && upperKey[3] <= '9') || upperKey == "KP_Decimal")) { // only 11 keys affected by Num_Lock (different for others?)
											key = upperKey; // next level if num lock is on; this ensures that the number is printed
										}
										else if (i.second != "Caps_Lock"&& i.second != "Num_Lock") {
											// std::cerr << "<kbd>" << i.second << "</kbd>+";
											if (options.very_verbose) std::cerr << i.second << '+';
											typed_string.emplace_back(i.second, true); // construct an XSRPress with the key description and the fact that it is a modifier
										}
										key.erase(0, 3); // delete preceding KP_
									}
									else if (i.second == "Num_Lock") {
										// num lock on keys not on the numpad is worthless
									}
									else if (i.second == "Caps_Lock" && key.size() == 1 && key[0] >= 'a' && key[0] <= 'z') {
										key = XKeysymToString(XkbKeycodeToKeysym(display, event->detail, 0, !shifted)); // next level (or down one in the case that shift was pressed too, since Caps_Lock+Shift+a == a)
									}
									else if (i.second == "Shift") {
										std::string keyUP = XKeysymToString(XkbKeycodeToKeysym(display, event->detail, 0, 1)); // next level
										if (keyUP != "NoSymbol" && keyUP != key) {
											key = keyUP; // only apply it if the key has a second level
											shifted = true;
										}
										else {
											// std::cerr << "<kbd>" << i.second << "</kbd>+"; // else print out shift as part of the modifiers
											if (options.very_verbose) std::cerr << i.second << '+';
											typed_string.emplace_back(i.second, true);
										}
									}
									else {
										// std::cerr << "<kbd>" << i.second << "</kbd>+";
										if (options.very_verbose) std::cerr << i.second << '+';
										typed_string.emplace_back(i.second, true); // print out modifier
									}
								}
							}
							// we could use XLookupString(3) instead of lookup tables, but it's slower and only supports latin characters, while lookup tables could easily be extended to support e.g. cyrillic
							auto lookedUpKey = lookup.find(key);
							if (lookedUpKey != lookup.end()) {
								key = lookedUpKey->second; // if we want to rename the key, do it!
							}
							// if (key.size() > 1) {
							// 	key = "<kbd>" + key + "</kbd>";
							// }
							// std::cerr << key;
							if (key == "}" && (event->mods.effective & 0b00001101) == 0b00001101) {
								// ctrl+shift+alt+] == exit
								// I wanted to put this above the modifier lookup because then I wouldn't have to erase the modifiers from the list, but the key lookup must occur after the modifier lookup :(
								VB std::cerr << '[' << __FILE__ << "] Quit hotkey, triggering clean exit" << std::endl;
								auto erase_beginning = typed_string.end();
								erase_beginning--;
								erase_beginning--;
								typed_string.erase(erase_beginning, typed_string.end()); // erase the last two modifiers that have been printed (ctrl and alt)
								exit_cleanly = true;
								break;
							}
							if (options.very_verbose) std::cerr << key << std::endl;
							typed_string.emplace_back(key, false);
							if (key == "Enter" || key == "Return" || key == "Linefeed") {
								// The user pressed return; this will submit forms and such, so we need to screenshot
								XSRData thisData(takeScreenShot(), takeMouseShot(), std::move(typed_string), XSRDataType::typing);
								typed_string.clear(); // again, move is not a guarantee
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
						lastScrollDirection = 0; // not scrolling anymore
						std::string key = XKeysymToString(XkbKeycodeToKeysym(display, event->detail, 0, 0));
						if (modifierKeyCodes.find(event->detail) != modifierKeyCodes.end() && lastKeyWasModifier) {
							/* if the last key was a modifier and the key that was just released was also a modifier,
							   that means that the user did something strange like pressing Ctrl+Shift and nothing else.
							   There are edge cases where this matters, so we should print it. */
							lastKeyWasModifier = false;
							// send modifiers
							if (key.back() == 'L' || key.back() == 'R') {
								key.pop_back();
								key.pop_back(); // since we're only deleting 2 chars I'm pretty sure this is the fastest way
							}
							for (auto i: modifierBitMap) {
								if (event->mods.effective & i.first && i.second != key && i.second != "Num_Lock" && i.second != "Caps_Lock") { // check each modifier bit and print if significant
									// std::cerr << "<kbd>" << i.second << "</kbd>+";
									if (options.very_verbose) std::cerr << i.second << '+';
									typed_string.emplace_back(i.second, true);
								}
							}
							// std::cerr << "<kbd>" << key << "</kbd>";
							if (options.very_verbose) std::cerr << key << std::endl;
							typed_string.emplace_back(key, false);
						}
						break;
					}
				case XI_ButtonPress: // mouse button, that is
					{
						// screenshot
						XImage *thisScreenShot = nullptr;
						XFixesCursorImage *thisMouseShot = nullptr;
						draggedSincePress = false;
						lastKeyWasModifier = false;
						// ensure that scroll events aren't repeated in the output (that would be awful)
						if (event->detail >= 4 && event->detail <= 7) {
							if (event->detail != lastScrollDirection) {
								lastScrollDirection = event->detail;
							}
							else {
								break;
							}
						}
						else {
							thisScreenShot = takeScreenShot(); // only take a screenshot if we're not scrolling
							thisMouseShot = takeMouseShot();
							lastScrollDirection = 0; // not scrolling anymore
						}
						VVB std::cerr << '[' << __FILE__ << "] Mouse press: ";
						XSRData thisData(thisScreenShot, thisMouseShot, XSRDataType::click);
						for (auto i: modifierBitMap) {
							if (event->mods.effective & i.first && i.second != "Num_Lock" && i.second != "Caps_Lock") { // check each modifier bit and print if significant
								// std::cerr << "<kbd>" << i.second << "</kbd>+";
								if (options.very_verbose) std::cerr << i.second << '+';
								thisData.presses.emplace_back(i.second, true); // again, construct XSRPress as a modifier
								                                               // this will get printed as a modifier key even if presses represents a mouse press
							}
						}
						auto lookedUpButton = lookupmouse.find(event->detail); // look up mouse button labels
						if (lookedUpButton != lookupmouse.end()) {
							// std::cerr << lookedUpButton->second;
							if (options.very_verbose) std::cerr << lookedUpButton->second << std::endl;
							thisData.presses.emplace_back(lookedUpButton->second, false);
						}
						else {
							// std::cerr << "Mouse button " << event->detail;
							if (options.very_verbose) std::cerr << "Mouse button " << event->detail << std::endl;
							thisData.presses.emplace_back("Mouse button " + std::to_string(event->detail), false);
						}
						sendData(std::move(thisData));
						break;
					}
				case XI_Motion:
					draggedSincePress = true; // set up drag event
					break;
				case XI_ButtonRelease:
					{
						if (draggedSincePress) {
							draggedSincePress = false;
							// screenshot
							// std::cerr << "... and drag.";
							VVB std::cerr << '[' << __FILE__ << "] Drag" << std::endl;
							XSRData thisData(takeScreenShot(), takeMouseShot(), XSRDataType::drag);
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
	XSRData thisData((XImage*)nullptr, (XFixesCursorImage*)nullptr, XSRDataType::EXIT); // tell other thread to clean exit
	sendData(std::move(thisData));
	VB std::cerr << '[' << __FILE__ << "] Clean exit" << std::endl;
	return 0;
}
