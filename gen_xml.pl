#!/usr/bin/perl

use strict;

my $pub_nr = `cat NR`;
$pub_nr =~ s/[^0-9]//g;

# the first line of the csv file must be a header line
$_ = <STDIN>;
chomp;
my @keys = split /\t/, lc;
my $date = `date`;
chomp $date;
print "<?xml version='1.0' encoding='UTF-8'?>\n\n<!--\nKEYS:\n@keys\n\nFile generated at $date.\n\n-->\n\n<csv>\n";

my $lineno = 1;
while (<STDIN>)
{
   $lineno++;
   chomp;
   s/'/&apos;/g;
   #s/"//g;
   my @vals = split /\t/;

   print "   <csventry line='$lineno'>\n";
   for (my $i = 0; $i < @keys; $i++)
   {
      print "      <csvcol k='$keys[$i]' v='$vals[$i]' />\n" if length "$vals[$i]";
   }
   print "   </csventry>\n";
}

print "</csv>\n";

