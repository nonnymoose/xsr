#ifndef ARGPARSER
#define ARGPARSER

#define VB if (options.verbose)
#define VVB if (options.very_verbose)

class xsr_options {
	public:
		std::string outfile;
		bool edit_before_save;
		bool image_deps;
		std::string image_ext;
		bool capture_focused;
		bool quiet;
		bool verbose;
		bool very_verbose;
		std::string mouse_icon;
		bool no_mouse;
		int countdown;
		xsr_options(): outfile("Untitled Recording.html"), edit_before_save(false), image_deps(false), image_ext("png"), capture_focused(false), quiet(false), verbose(false), mouse_icon("/usr/share/xsr/Cursor.png"), no_mouse(false), countdown(5) {}
};
extern xsr_options options;
// global data structure variable containing all of the options

bool parse_arguments (int argc, char** argv);
#endif
