#include <X11/Xlib.h>
#include <X11/Xutil.h>
#include <vector>
#include <png.h>
#include <exception>
#include <string>
#include "to_png.h"

static void PngWriteCallback(png_structp  png_ptr, png_bytep data, png_size_t length) {
	std::vector<char> *writeptr = (std::vector<char>*)png_get_io_ptr(png_ptr);
	writeptr->insert(writeptr->end(), data, data + length);
}

std::vector<unsigned char> XImageToPNG(XImage *img) {
	std::vector<unsigned char> pngdata; // where to store the png
	png_structp pngwrite = png_create_write_struct(PNG_LIBPNG_VER_STRING, NULL, NULL, NULL); // initialize write structure
	png_infop pnginfo_ptr = png_create_info_struct(pngwrite); // initialize info structure
	setjmp(png_jmpbuf(pngwrite));
	png_set_IHDR(pngwrite, pnginfo_ptr, img->width, img->height, 8, PNG_COLOR_TYPE_RGB, PNG_INTERLACE_NONE, PNG_COMPRESSION_TYPE_BASE, PNG_FILTER_TYPE_BASE); // write our info

	png_set_write_fn(pngwrite, &pngdata, PngWriteCallback, NULL); // use that function to write the data to the vector

	png_write_info(pngwrite, pnginfo_ptr);
	// std::vector<char*> png_row(img->height);

	// png_row = (png_bytep) malloc(3 * img->width * sizeof(png_byte));
	png_byte png_row[3 * img->width]; // convert the XImage to png                vvvvv
	
	unsigned long red_mask = img->red_mask;
	unsigned long green_mask = img->green_mask;
	unsigned long blue_mask = img->blue_mask;
	
	
	
	// Write image data
	for (int y = 0; y < img->height; y++) {
		for (int x = 0; x < img->width; x++) {
			unsigned long pixel = XGetPixel(img, x, y);
			unsigned char blue = pixel & blue_mask;
			unsigned char green = (pixel & green_mask) >> 8;
			unsigned char red = (pixel & red_mask) >> 16;
			// png_byte *ptr = (png_row[x * 3]);
			// ptr[0] = red;
			// ptr[1] = green;
			// ptr[2] = blue;
			// that way is bad; I think I have a better way!
			png_row[x*3] = red;
			png_row[x*3 + 1] = green;
			png_row[x*3 + 2] = blue;
		}
		png_write_row(pngwrite, png_row);
	}																					// finish converting           ^^^^^
	
	png_write_end(pngwrite, NULL); // write the footer
	if (pnginfo_ptr != NULL) {
		png_free_data(pngwrite, pnginfo_ptr, PNG_FREE_ALL, -1);
	}
	if (pngwrite != NULL) {
		png_destroy_write_struct(&pngwrite, (png_infopp) NULL);
	}
	return pngdata;
}
