TARGET=Pub$(NR)bk
LOGFILE=lol.log
BINPATH=..

all: $(TARGET).osm.bz2

$(TARGET).html: $(TARGET).pdf
	pdftohtml -i -noframes $(TARGET).pdf > /dev/null 2> $(LOGFILE)

$(TARGET)_.html: $(TARGET).html
	perl -pe 's/<br>(.*?)<br>/<br>\n\1<br>\n/g' < $(TARGET).html > $(TARGET)_.html 2> $(LOGFILE)

$(TARGET)_.csv: $(TARGET)_.html
	$(BINPATH)/conv_html_lol.pl $(NR) < $(TARGET)_.html > $(TARGET)_.csv

$(TARGET).csv: $(TARGET)_.csv
	perl -pe 's/&.*?;//g' < $(TARGET)_.csv > $(TARGET).csv

$(TARGET).sql: $(TARGET).csv
	$(BINPATH)/gen_sql.pl $(NR) < $(TARGET).csv > $(TARGET).sql 2> $(LOGFILE)

$(TARGET).mysql: $(TARGET).sql
	mysql -ulol -plol1234 list_of_lights < $(TARGET).sql
	touch $(TARGET).mysql

$(TARGET).osm: $(TARGET).mysql
	$(BINPATH)/gen_osm.pl $(NR) > $(TARGET).osm

$(TARGET).osm.bz2: $(TARGET).osm
	bzip2 -c $(TARGET).osm > $(TARGET).osm.bz2

clean:
	rm -f $(TARGET).html $(TARGET)_.html $(TARGET).csv $(TARGET)_.csv $(TARGET).sql $(TARGET).mysql $(TARGET).osm $(TARGET).osm.bz2

.PHONY: clean

