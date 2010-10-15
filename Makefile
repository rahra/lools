NR=113
TARGET=Pub$(NR)bk

all: $(TARGET).osm

$(TARGET).html: $(TARGET).pdf
	pdftohtml -f 33 -noframes $(TARGET).pdf > /dev/null

$(TARGET)_.html: $(TARGET).html
	perl -pe 's/<br>(.*?)<br>/<br>\n\1<br>\n/g' < $(TARGET).html > $(TARGET)_.html

$(TARGET)_.csv: $(TARGET)_.html
	./conv_html_lol.pl $(NR) < $(TARGET)_.html > $(TARGET)_.csv

$(TARGET).csv: $(TARGET)_.csv
	perl -pe 's/&.*?;//g' < $(TARGET)_.csv > $(TARGET).csv

$(TARGET).sql: $(TARGET).csv
	./gen_sql.pl < $(TARGET).csv > $(TARGET).sql

$(TARGET).mysql: $(TARGET).sql
	mysql -ulol -plol1234 list_of_lights < $(TARGET).sql
	touch $(TARGET).mysql

$(TARGET).osm: $(TARGET).mysql
	./gen_osm.pl > $(TARGET).osm

clean:
	rm -f $(TARGET).html $(TARGET)_.html $(TARGET).csv $(TARGET)_.csv $(TARGET).sql $(TARGET).mysql $(TARGET).osm

.PHONY: clean

