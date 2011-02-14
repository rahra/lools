# @author Bernhard R. Fischer, 2048R/5C5FFD47 <bf@abenteuerland.at>
#

SVNVER=$(shell svnversion | tr -d -c '[:digit:]')
DISTFILES=Makefile Makefile.cr db.conf list_of_lights.sql README conv_html_lol.pl gen_altchar.pl gen_osm.pl gen_sql.pl gen_xml.pl
DISTDST=list_of_lights-r$(SVNVER)

all:
	for f in Pub11?bk.pdf ; do \
		nr=$${f}_make ; \
		if test ! -e $$nr ; then mkdir $$nr ; fi ; \
		if test ! -e $$nr/Makefile ; then ln -s ../Makefile.cr $$nr/Makefile ; fi ; \
		if test ! -e $$nr/$$f ; then ln -s ../$$f $$nr/$$f ; fi ; \
		if test ! -e $$nr/db.conf ; then ln -s ../db.conf $$nr/db.conf ; fi ; \
		echo $$f | perl -pe 'print "NR=";s/[^0-9\n]//g' > $$nr/NR ; \
		make -C $$nr ; \
		done

bz2:
	for nr in Pub11?bk.pdf ; do \
		make -C $${nr}_make bz2 ; \
		done

clean:
	for nr in Pub11?bk.pdf ; do \
		make -C $${nr}_make clean ; \
		done

cleancsv:
	for nr in Pub11?bk.pdf ; do \
		make -C $${nr}_make cleancsv ; \
		done

cleanall:
	for nr in Pub11?bk.pdf ; do \
		rm -rf $${nr}_make ; \
		done
 
dist:
	mkdir $(DISTDST)
	cp $(DISTFILES) $(DISTDST)
	tar cvfj $(DISTDST).tbz2 $(DISTDST)

.PHONY: clean cleancsv cleanall bz2 dist

