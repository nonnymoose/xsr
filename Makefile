SHELL:=/bin/bash -e

TEST_ARGS=--help

.PHONY: all
all: test maint xsr

.PHONY: test
test: xsr
	./$< $(TEST_ARGS) 2>&1 1>/dev/null | [[ `tee >(cat >&2) | wc -c` -eq 0 ]]

.PHONY: maint
maint: README.md

README.md: xsr README.md.m4 markdown-preset.m4
	m4 --prefix-builtins markdown-preset.m4 \
		README.md.m4 > README.md

xsr: xsr.pl
	cp $< $@
