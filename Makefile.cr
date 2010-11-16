NR=$(shell cat NR 2> /dev/null)
ifeq ($(NR),)
	NR=$(shell basename `pwd`)
else
include NR
endif

TARGET=Pub$(NR)bk
LOGFILE=lol.log
BINPATH=..

all: $(TARGET).osm

$(TARGET).html: $(TARGET).pdf
	pdftohtml -i -noframes $(TARGET).pdf > /dev/null 2>> $(LOGFILE)

$(TARGET)_.html: $(TARGET).html
	perl -pe 's/(<br>)(<\/[bi]>)/\2\1/g;s/<br>(.*?)<br>/<br>\n\1<br>\n/g;s/^(&nbsp;| )+//g;' < $(TARGET).html | perl -pe 's/^(&nbsp;| )+//g;s/^\n//;' > $(TARGET)_.html 2>> $(LOGFILE)

$(TARGET)_.csv: $(TARGET)_.html
	$(BINPATH)/conv_html_lol.pl < $(TARGET)_.html > $(TARGET)_.csv

$(TARGET).csv: $(TARGET)_.csv
	#perl -pe 's/&.*?;//g' < $(TARGET)_.csv > $(TARGET).csv
	perl -pe 's/&nbsp;/ /g' < $(TARGET)_.csv > $(TARGET).csv

$(TARGET).sql: $(TARGET).csv
	$(BINPATH)/gen_sql.pl < $(TARGET).csv > $(TARGET).sql 2>> $(LOGFILE)

$(TARGET).mysql: $(TARGET).sql
	mysql -f -ulol -plol1234 list_of_lights < $(TARGET).sql
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

bz2: $(TARGET).osm.bz2 $(TARGET).csv.bz2
	
clean:
	rm -f $(TARGET).html $(TARGET)_.html $(TARGET).csv $(TARGET)_.csv $(TARGET).sql $(TARGET).mysql $(TARGET).osm $(TARGET).osm.bz2 NR

cleancsv:
	rm -f $(TARGET)_.csv

.PHONY: clean cleancsv bz2

