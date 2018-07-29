#!/usr/bin/env make -f

# user variables (can be set via command line too)
DEBUG = true
# end user variables

VPATH = ..
vpath base64.% ../base64
CXXFLAGS = -Wall -Wextra -pedantic --std=c++14
LDFLAGS = -pthread
CXXFLAGS += -pthread # this IS necessary; see pthreads(7), Compiling on Linux
LDLIBS = -lX11 -lXi -lpng16 -lz -lXfixes
OBJECTS = arg_parser.o html_out.o to_png.o main.o signal_handler.o xievent.o base64.o cursor_image.o

ifeq ($(strip $(DEBUG)),true)
CXXFLAGS += -g
endif

.PHONY: all clean

all: xsr

xsr: $(OBJECTS)
	$(CXX) $(LDFLAGS) -o xsr $(OBJECTS) $(LDLIBS)

clean:
	-rm -rf *.o xsr

arg_parser.o: arg_parser.h
html_out.o: signal_handler.h html_out.h html_template.h xsrdata.h to_png.h arg_parser.h cursor_image.h
signal_handler.o: signal_handler.h arg_parser.h
xievent.o: signal_handler.h xsrdata.h xievent.h remap.h arg_parser.h arg_parser.h
main.o: arg_parser.h signal_handler.h xievent.h html_out.h arg_parser.h
base64.o: base64.h
to_png.o: to_png.h
cursor_image.o: cursor_image.h
