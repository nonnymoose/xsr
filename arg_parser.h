#ifndef ARGPARSER
#define ARGPARSER

#define VB if (options.verbose)
#define VVB if (options.very_verbose)

class xsr_options {
	public:
		std::string outfile;
		std::string image_ext;
		bool quiet;
		bool verbose;
		bool very_verbose;
		bool include_mouse;
		int countdown;
		xsr_options(): outfile("Untitled Recording.html"), image_ext("png"), quiet(false), verbose(false), very_verbose(false), include_mouse(true), countdown(5) {}
};
extern xsr_options options;
// global data structure variable containing all of the options

bool parse_arguments (int argc, char** argv);
#endif
