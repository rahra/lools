#/* Copyright 2010,2011 Bernhard R. Fischer, 2048R/5C5FFD47 <bf@abenteuerland.at>
# *
# * This file is part of Lools (List of Light Tools).
# *
# * Lools is free software: you can redistribute it and/or modify
# * it under the terms of the GNU General Public License as published by
# * the Free Software Foundation, version 3 of the License.
# *
# * Lools is distributed in the hope that it will be useful,
# * but WITHOUT ANY WARRANTY; without even the implied warranty of
# * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# * GNU General Public License for more details.
# *
# * You should have received a copy of the GNU General Public License
# * along with Lools. If not, see <http://www.gnu.org/licenses/>.
# */

NR=$(shell cat NR 2> /dev/null)
ifeq ($(NR),)
	NR=$(shell basename `pwd` | tr -d -c '[:digit:]')
else
include NR
endif

include ../db.conf

TARGET=Pub$(NR)bk
LOGFILE=lol.log
BINPATH=..

all: $(TARGET).osm

$(TARGET).html: $(TARGET).pdf
	pdftohtml -i -noframes $(TARGET).pdf > /dev/null 2>> $(LOGFILE)

$(TARGET)_.html: $(TARGET).html
	perl -pe 's/&#160;/ /g;s/(<br\/>)(<\/[bi]>)/\2\1/g;s/<br\/>(.*?)<br\/>/<br\/>\n\1<br\/>\n/g;s/^(&nbsp;| )+//g;s/&nbsp;&nbsp;((([0-9]{1,3})°&nbsp;([0-9]{2,2}\.[0-9])´&nbsp;([NS]))&nbsp;(<b>([^<]*)<\/b>)(.*?)<br\/>)/<br\/>\n\1/;s/-&nbsp;-/--/' < $(TARGET).html | perl -pe 's/^(&nbsp;| )+//g;/ /g;s/^\n//;' > $(TARGET)_.html 2>> $(LOGFILE)

$(TARGET)_.csv: $(TARGET)_.html
	$(BINPATH)/conv_html_lol.pl < $(TARGET)_.html > $(TARGET)_.csv

$(TARGET).csv: $(TARGET)_.csv
	#perl -pe 's/&.*?;//g' < $(TARGET)_.csv > $(TARGET).csv
	perl -pe 's/&nbsp;/ /g' < $(TARGET)_.csv > $(TARGET).csv

$(TARGET).sql: $(TARGET).csv
	$(BINPATH)/gen_sql.pl < $(TARGET).csv > $(TARGET).sql 2>> $(LOGFILE)

$(TARGET).mysql: $(TARGET).sql
	mysql -f -S $(MYSQL_SOCKET) -u$(MYSQL_USER) -p$(MYSQL_PASS) $(MYSQL_DB) < $(TARGET).sql
	touch $(TARGET).mysql

$(TARGET).osm: $(TARGET).mysql
	$(BINPATH)/gen_osm.pl > $(TARGET).osm

$(TARGET).osm.bz2: $(TARGET).osm
	bzip2 -c $(TARGET).osm > $(TARGET).osm.bz2

$(TARGET).csv.bz2: $(TARGET).csv
	bzip2 -c $(TARGET).csv > $(TARGET).csv.bz2

$(TARGET).xml: $(TARGET).csv
	if test -e $(TARGET).xml ; then \
		cp $(TARGET).xml $(TARGET).xml~ ; \
	fi
	$(BINPATH)/gen_xml.pl < $(TARGET).csv > $(TARGET).xml

$(TARGET)_alt.csv: $(TARGET)_.csv
	AC=3 ; \
		echo -n > $(TARGET)_alt.csv ; \
		CSV=`mktemp` ; \
		HTM=`mktemp` ; \
		cp $(TARGET)_.csv $$CSV ; \
		while test $$AC -gt 2 ; \
		do \
			$(BINPATH)/gen_altchar.pl < $$CSV > $$HTM ; \
			$(BINPATH)/conv_html_lol.pl < $$HTM > $$CSV ; \
			cat $$CSV >> $(TARGET)_alt.csv ; \
			AC=`wc -l < $$HTM` ; \
		done ; \
		rm $$CSV $$HTM

bz2: $(TARGET).osm.bz2 $(TARGET).csv.bz2

clean:
	rm -f $(TARGET).html $(TARGET)_.html $(TARGET).csv $(TARGET)_.csv $(TARGET).sql $(TARGET).mysql $(TARGET).osm $(TARGET).osm.bz2 NR

cleancsv:
	rm -f $(TARGET)_.csv

.PHONY: clean cleancsv bz2

