TEXTDOMAIN=io.github.nonnymoose.xsr
TRANSLATIONS=$(basename $(notdir $(wildcard po/*.po)))

.PHONY: all
all: test maint xsr

.PHONY: test
test:
	./xsr --help >/dev/null

.PHONY: maint
maint: README.md po/template.pot

README.md: xsr README.md.m4 markdown-preset.m4
	m4 --prefix-builtins markdown-preset.m4 \
		README.md.m4 > README.md

po/template.pot: xsr
	xgettext -L perl xsr --from-code=utf-8 --omit-header `cat gettext_options` --output=po/template.pot

po/%.mo: po/%.po
	msgfmt --check --statistics $< -o $@

.PHONY: install
install: install-locale

.PHONY: install-locale
install-locale: $(addprefix po/,$(addsuffix .mo,$(TRANSLATIONS)))
	@for l in $(TRANSLATIONS); do \
		echo "Installing translation '$$l'..."; \
		cp po/$$l.mo /usr/share/locale/$$l/LC_MESSAGES/$(TEXTDOMAIN).mo || exit $$?; \
	done

.PHONY: uninstall
uninstall: uninstall-locale

.PHONY: uninstall-locale
uninstall-locale:
	-rm /usr/share/locale/*/LC_MESSAGES/$(TEXTDOMAIN).mo
