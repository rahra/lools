# @author Bernhard R. Fischer, 2048R/5C5FFD47 <bf@abenteuerland.at>

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

.PHONY: clean cleancsv cleanall bz2

