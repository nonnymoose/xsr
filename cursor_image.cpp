#include <X11/Xlib.h>
#include <X11/Xutil.h>
#include <X11/extensions/Xfixes.h>
#include "cursor_image.h"

void XFixesDestroyCursorImage(XFixesCursorImage* cimg) { // because XFixes couldn't implement that on their own, apparently
	XFree(cimg->pixels);
	XFree(cimg);
}

void compositeCursorOntoXImage(XImage* img, XFixesCursorImage* cimg) {
	int cimgRealX = cimg->x - cimg->xhot;
	int cimgRealY = cimg->y - cimg->yhot;
	for (int i = 0; i < cimg->height; i++) {
		for (int j = 0; j < cimg->width; j++) {
			// XPutPixel(img, cimgRealX + j, cimgRealY + i, cimg->pixels[i * cimg->width + j]); // direct overlay
			// alpha composite:
			// note: X11 pixel will always be alpha 1
			unsigned long origPixel = XGetPixel(img, cimgRealX + j, cimgRealY + i);
			unsigned char origRed   = (origPixel >> 16) & 0xff;
			unsigned char origGreen = (origPixel >> 8)  & 0xff;
			unsigned char origBlue  = (origPixel)       & 0xff;
			
			unsigned long cursorPixel = cimg->pixels[i * cimg->width + j];
			unsigned char cursorAlpha = (cursorPixel >> 24) & 0xff;
			unsigned char cursorRed   = (cursorPixel >> 16) & 0xff;
			unsigned char cursorGreen = (cursorPixel >> 8)  & 0xff;
			unsigned char cursorBlue  = (cursorPixel)       & 0xff;
			
			double alphaFraction = (0xff - cursorAlpha) / 0xff;
			
			unsigned char newRed = cursorRed + origRed * alphaFraction;
			unsigned char newGreen = cursorGreen + origGreen * alphaFraction;
			unsigned char newBlue = cursorBlue + origBlue * alphaFraction;
			
			unsigned long newPixel = (newRed << 16) + (newGreen << 8) + newBlue;
			XPutPixel(img, cimgRealX + j, cimgRealY + i, newPixel);
		}
	}
}
