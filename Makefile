.PHONY: all
all: README.md xsr

README.md: xsr README.md.m4 markdown-preset.m4
	m4 --prefix-builtins markdown-preset.m4 \
		-D USAGE="$$(./xsr --help)" \
		README.md.m4 > README.md
