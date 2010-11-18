#!/usr/bin/perl
#
# Generate pseudo HTML containing alternative light characters of lights. It
# should be parse by conv_html_lol.pl again.
#
# @author Bernhard R. Fischer
#


use strict;
#use feature ":5.10";

my $pub_nr = `cat NR`;
$pub_nr =~ s/[^0-9]//g;

# the first line of the csv file must be a header line
$_ = <STDIN>;
chomp;
my @keys = split /\t/, lc;

print "Section 1<br>\nSection 1<br>\n";

my $lcnt = 1;
while (<STDIN>)
{
   $lcnt++;
   chomp;
   #s/'/\\'/g;
   #s/"//g;
   my @vals = split /\t/;

   # convert value array to hash
   my %val = ();
   my $i = 0;
   foreach (@vals) { $val{"$keys[$i++]"} = $_; }

   next unless $val{'alt_light'};

   $val{'uslnr'} =~ s/^"(.*)"$/\1/;
   $val{'name'} =~ s/^"(.*)"$/\1/;
   $val{'intnr'} =~ s/^"([A-Z0])(.*)"$/\1 \2/;

   $val{'alt_light'} =~ s/<br>/<br>\n/g;
   my $out = "$val{'uslnr'}&nbsp;$val{'name'}<br>\n$val{'lat'}&nbsp;$val{'alt_light'}\n<i>$val{'intnr'}</i><br>\n$val{'lon'}<br>\n";
   #$out =~ s/^\n//;
   print $out;
}

