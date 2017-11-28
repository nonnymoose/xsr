.PHONY: all
all: test README.md xsr

.PHONY: test
test:
	./xsr --help >/dev/null

README.md: xsr README.md.m4 markdown-preset.m4
	m4 --prefix-builtins markdown-preset.m4 \
		README.md.m4 > README.md
