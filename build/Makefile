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

.PHONY: all clean depends

all: depends xsr

xsr: $(OBJECTS)
	$(CXX) $(LDFLAGS) -o xsr $(OBJECTS) $(LDLIBS)

clean:
	-rm -rf *.o *.mk xsr

depends: $(OBJECTS:.o=.mk)

%.mk: %.cpp
	$(CXX) -MM $< | sed 's/\.\.\///g' | sed -r 's/^(.*?):/\1 $@:/' > $@

include $(wildcard *.mk)
