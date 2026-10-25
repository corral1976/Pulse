# SPDX-License-Identifier: MIT
#
# Generic install for any Linux distribution.
#
#   make install                              -> /usr/local (needs root)
#   make install PREFIX=$$HOME/.local         -> per-user, no root
#   make install PREFIX=/usr DESTDIR=pkgdir   -> for distro packagers
#   make uninstall [PREFIX=...]
#   make check                                -> syntax, shellcheck (if present) and smoke tests
#   make deb                                  -> build the .deb (Debian/Ubuntu)

PREFIX  ?= /usr/local
DESTDIR ?=
BINDIR  ?= $(PREFIX)/bin
DATADIR ?= $(PREFIX)/share

VERSION := $(shell sed -n 's/^readonly SCRIPT_VERSION="\(.*\)"/\1/p' src/pulse)

.PHONY: all install uninstall check deb clean

all:
	@echo "Nothing to build. Use 'make install' (see the header of this Makefile)."

install:
	install -Dm755 src/pulse $(DESTDIR)$(BINDIR)/pulse
	install -Dm644 data/pulse-active.desktop $(DESTDIR)$(DATADIR)/applications/pulse-active.desktop
	install -Dm644 data/pulse.svg $(DESTDIR)$(DATADIR)/icons/hicolor/scalable/apps/pulse.svg
	install -Dm644 man/pulse.1 $(DESTDIR)$(DATADIR)/man/man1/pulse.1
	install -Dm644 README.md $(DESTDIR)$(DATADIR)/doc/pulse-active/README.md
	install -Dm644 LICENSE $(DESTDIR)$(DATADIR)/licenses/pulse-active/LICENSE
	@if [ -z "$(DESTDIR)" ]; then \
		command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database -q $(DATADIR)/applications 2>/dev/null || true; \
		command -v gtk-update-icon-cache >/dev/null 2>&1 && gtk-update-icon-cache -q -f -t $(DATADIR)/icons/hicolor 2>/dev/null || true; \
	fi
	@echo "Installed Pulse-Active $(VERSION) in $(DESTDIR)$(BINDIR)/pulse"
	@case ":$$PATH:" in *":$(BINDIR):"*) ;; *) [ -n "$(DESTDIR)" ] || echo "Note: $(BINDIR) is not in your PATH." ;; esac

uninstall:
	rm -f $(DESTDIR)$(BINDIR)/pulse
	rm -f $(DESTDIR)$(DATADIR)/applications/pulse-active.desktop $(DESTDIR)$(DATADIR)/man/man1/pulse.1
	rm -f $(DESTDIR)$(DATADIR)/icons/hicolor/scalable/apps/pulse.svg
	rm -rf $(DESTDIR)$(DATADIR)/doc/pulse-active $(DESTDIR)$(DATADIR)/licenses/pulse-active
	@if [ -z "$(DESTDIR)" ]; then \
		command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database -q $(DATADIR)/applications 2>/dev/null || true; \
		command -v gtk-update-icon-cache >/dev/null 2>&1 && gtk-update-icon-cache -q -f -t $(DATADIR)/icons/hicolor 2>/dev/null || true; \
	fi
	@echo "Removed Pulse-Active from $(DESTDIR)$(PREFIX)"

check:
	bash -n src/pulse BUILD_DEB.sh install_pulse.sh uninstall_pulse.sh
	@if command -v shellcheck >/dev/null 2>&1; then \
		shellcheck --severity=warning src/pulse BUILD_DEB.sh install_pulse.sh uninstall_pulse.sh packaging/debian/postinst packaging/debian/postrm; \
	else echo "shellcheck not installed, skipping"; fi
	bash src/pulse --version
	bash src/pulse --once | grep -q 'CPU:'
	@echo "All checks passed."

deb:
	bash BUILD_DEB.sh

clean:
	rm -f pulse-active_*_all.deb
