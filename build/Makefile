#!/usr/bin/env make -f

# user variables (can be set via command line too)
DEBUG = true
# end user variables

VPATH = ..
vpath base64.% ../base64
CXXFLAGS = -Wall -Wextra -pedantic --std=c++14
LDFLAGS = -pthread
CXXFLAGS += -pthread # this IS necessary; see pthreads(7), Compiling on Linux
LDLIBS = -lX11 -lXi -lpng16 -lz
OBJECTS = arg_parser.o html_out.o to_png.o main.o signal_handler.o xievent.o base64.o

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
html_out.o: signal_handler.h html_out.h html_template.h xsrdata.h to_png.h
signal_handler.o: signal_handler.h
xievent.o: signal_handler.h xsrdata.h xievent.h remap.h
main.o: arg_parser.h signal_handler.h xievent.h html_out.h
base64.o: base64.h
to_png.o: to_png.h
