#include <X11/Xlib.h>
#include <X11/Xatom.h>
#include <string>
#include "window_info.h"

std::string getActiveWindowTitle(Display *display) {
	Window root_window = DefaultRootWindow(display);
	Atom request_property;
	unsigned char *prop_return;
	Atom unused_actual_type_return;
	int unused_actual_format;
	unsigned long unused_nitems_return, unused_bytes_after_return;
	request_property = XInternAtom(display, "_NET_ACTIVE_WINDOW", true);
	XGetWindowProperty(display, root_window, request_property, 0, 1, false, AnyPropertyType, &unused_actual_type_return, &unused_actual_format, &unused_nitems_return, &unused_bytes_after_return, &prop_return);
	//                                        no long_offset --^  ^-- windows are a single long
	unsigned long active_window = prop_return[0] + (prop_return[1] << 8) + (prop_return[2] << 16) + (prop_return[3] << 24);
	request_property = XInternAtom(display, "_NET_WM_NAME", true);
	XGetWindowProperty(display, active_window, request_property, 0, 1000, false, AnyPropertyType, &unused_actual_type_return, &unused_actual_format, &unused_nitems_return, &unused_bytes_after_return, &prop_return);
	std::string result((char*) prop_return);
	XFree(prop_return);
	return result;
}
