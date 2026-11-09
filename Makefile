# Installs what `cargo build --release` produces, plus the desktop entry and
# icon. Cargo does the building; this only knows where files go.

PREFIX ?= /usr
DESTDIR ?=
BINDIR = $(DESTDIR)$(PREFIX)/bin
DATADIR = $(DESTDIR)$(PREFIX)/share
CARGO ?= cargo

.PHONY: all install uninstall clean

all: target/release/atlas

target/release/atlas:
	$(CARGO) build --release --locked

install: target/release/atlas
	install -Dm755 target/release/atlas $(BINDIR)/atlas
	install -Dm644 assets/atlas.desktop $(DATADIR)/applications/atlas.desktop
	install -Dm644 assets/atlas.svg $(DATADIR)/icons/hicolor/scalable/apps/atlas.svg
	install -Dm644 assets/atlas.svg $(DATADIR)/pixmaps/atlas.svg

uninstall:
	rm -fv $(BINDIR)/atlas \
		$(DATADIR)/applications/atlas.desktop \
		$(DATADIR)/icons/hicolor/scalable/apps/atlas.svg \
		$(DATADIR)/pixmaps/atlas.svg

clean:
	$(CARGO) clean
