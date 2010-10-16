PUB=110 111 112 113 114 115 116

all:
	for nr in $(PUB) ; do \
		if test ! -e $$nr ; then \
			mkdir $$nr ; \
		fi ; \
		if test ! -e $$nr/Makefile ; then \
			ln -s ../Makefile.cr $$nr/Makefile ; \
		fi ; \
		if test ! -e $$nr/Pub$${nr}bk.pdf ; then \
			ln -s ../Pub$${nr}bk.pdf $$nr/Pub$${nr}bk.pdf ; \
		fi ; \
		make -C $$nr NR=$$nr ; \
		done

clean:
	for nr in $(PUB) ; do \
		make -C $$nr clean NR=$$nr ; \
		done

cleanall:
	for nr in $(PUB) ; do \
		rm -rf $$nr ; \
		done

.PHONY: clean cleanall

