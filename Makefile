# Installs the browser-picker command and its desktop entry.
# The overlay plugin is installed separately, with `omarchy plugin add`.

PREFIX ?= $(HOME)/.local
DESTDIR ?=

BINDIR := $(PREFIX)/bin
APPDIR := $(PREFIX)/share/applications

.PHONY: install uninstall check

install:
	install -Dm755 browser-picker "$(DESTDIR)$(BINDIR)/browser-picker"
	install -d "$(DESTDIR)$(APPDIR)"
	sed 's|^Exec=browser-picker |Exec=$(BINDIR)/browser-picker |' browser-picker.desktop \
		>"$(DESTDIR)$(APPDIR)/browser-picker.desktop"
	chmod 644 "$(DESTDIR)$(APPDIR)/browser-picker.desktop"
	@if [ -z "$(DESTDIR)" ]; then update-desktop-database "$(APPDIR)" 2>/dev/null || true; fi

uninstall:
	rm -f "$(DESTDIR)$(BINDIR)/browser-picker" "$(DESTDIR)$(APPDIR)/browser-picker.desktop"
	@if [ -z "$(DESTDIR)" ]; then update-desktop-database "$(APPDIR)" 2>/dev/null || true; fi

check:
	./tests/run
