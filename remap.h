const std::map<std::string, std::string> lookup {
	{"exclam", "!"},
	{"at", "@"},
	{"numbersign", "#"},
	{"dollar", "$"},
	{"percent", "%"},
	{"asciicircum", "^"},
	{"ampersand", "&"},
	{"asterisk", "*"},
	{"parenleft", "("},
	{"parenright", ")"},
	{"minus", "-"},
	{"underscore", "_"},
	{"equal", "="},
	{"plus", "+"},
	{"bracketleft", "["},
	{"bracketright", "]"},
	{"braceleft", "{"},
	{"braceright", "}"},
	{"semicolon", ";"},
	{"colon", ":"},
	{"apostrophe", "'"},
	{"quotedbl", "\""},
	{"grave", "`"},
	{"asciitilde", "~"},
	{"backslash", "\\"},
	{"bar", "|"},
	{"comma", ","},
	{"less", "<"},
	{"slash", "/"},
	{"question", "?"},
	{"period", "."},
	{"greater", ">"},
	{"Multiply", "*"},
	{"space", " "},
	{"Subtract", "-"},
	{"Add", "+"},
	{"Prior", "PageUp"},
	{"Next", "PageDown"},
	{"BackSpace", "⌫"},
	{"Delete", "⌦"},
	{"Equal", "="},
	{"plusminus", "±"},
	{"Divide", "/"},
	{"Print", "PrintScreen"},
	{"Decimal", "."}
};

std::map<int, std::string> lookupmouse = {
	{1, "Left-click"},
	{2, "Middle-click"},
	{3, "Right-click"},
	{4, "Scroll up"},
	{5, "Scroll down"},
	{7, "Scroll up"},
	{6, "Scroll down"} // it's like this on my touchpad. Not sure why though
};