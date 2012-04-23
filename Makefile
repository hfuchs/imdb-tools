# Very simple, build manpages
#

PREFIX?=/usr/local
BINPREFIX?=$(PREFIX)/bin
MANPREFIX?=$(PREFIX)/share/man
DOCPREFIX?=$(PREFIX)/share/doc/imdb-tools

VERSION=$(shell sed -n '1s/Version \(.*\):/\1/p' changelog)

all: man bin

man: man/imdb-get.1 man/imdb-rename.1 man/imdb-link.1 man/imdb-update-cache.1 man/imdbgetrc.5 man/imdb.1 man/imdb-fxd.1

bin: bin/imdb-get bin/imdb-rename bin/imdb-link bin/imdb-update-cache bin/imdb bin/imdb-fxd

clean:
	rm -rf man bin
	rm -f .mandir .bindir .dist
	rm -rf imdb-tools-$(VERSION)
	rm -f imdb-tools-$(VERSION).tar.gz

.mandir:
	mkdir -p man
	touch .mandir

.bindir:
	mkdir -p bin
	touch .bindir

man/%.1: %.sgml .mandir
	docbook-to-man $< > $@
%.1: %.sgml .mandir
	docbook-to-man $< > $@
man/%.5: %.sgml .mandir
	docbook-to-man $< > $@
%.5: %.sgml .mandir
	docbook-to-man $< > $@

bin/%: %.sh .bindir
	sed "s,%PREFIX%,$(PREFIX),;s,%VERSION%,$(VERSION),"  < $< > $@
	chmod +x $@

install: install-bin install-man install-doc
	
install-bin: bin/imdb-get bin/imdb-rename bin/imdb-link bin/imdb-update-cache bin/imdb bin/imdb-fxd
	install -d $(DESTDIR)$(BINPREFIX)
	install $^ $(DESTDIR)$(BINPREFIX)

install-man: man/imdb-get.1 man/imdb-rename.1 man/imdb-link.1 man/imdb-update-cache.1 man/imdb-fxd.1 man/imdbgetrc.5 man/imdb.1
	install -d $(DESTDIR)$(MANPREFIX)
	install -d $(DESTDIR)$(MANPREFIX)/man1
	install -m 644 man/imdb.1 $(DESTDIR)$(MANPREFIX)/man1
	install -m 644 man/imdb-get.1 $(DESTDIR)$(MANPREFIX)/man1
	install -m 644 man/imdb-rename.1 $(DESTDIR)$(MANPREFIX)/man1
	install -m 644 man/imdb-link.1 $(DESTDIR)$(MANPREFIX)/man1
	install -m 644 man/imdb-update-cache.1 $(DESTDIR)$(MANPREFIX)/man1
	install -m 644 man/imdb-fxd.1 $(DESTDIR)$(MANPREFIX)/man1
	install -d $(DESTDIR)$(MANPREFIX)/man5
	install -m 644 man/imdbgetrc.5 $(DESTDIR)$(MANPREFIX)/man5

install-doc: INSTALL README COPYING changelog
	install -d $(DESTDIR)$(DOCPREFIX)
	install -m 644 $^ $(DESTDIR)$(DOCPREFIX)

dist: .dist

.dist: changelog imdbgetrc.sgml imdb-link.sgml todo COPYING imdb-rename.sgml imdb-link.sh imdb-update-cache.sgml imdb-get.sgml imdb-rename.sh Makefile imdb-update-cache.sh imdb-get.sh imdb.sh imdb.sgml INSTALL README imdb-fxd.sh imdb-fxd.sgml
	mkdir -p imdb-tools-$(VERSION)
	cp $^ imdb-tools-$(VERSION)
	touch .dist

imdb-tools-$(VERSION).tar.gz: .dist
	tar zcf imdb-tools-$(VERSION).tar.gz imdb-tools-$(VERSION)

tar: imdb-tools-$(VERSION).tar.gz

