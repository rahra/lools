#!/usr/bin/perl
#
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
#
# This script generates an XML file out of the tabbed CSV file.
# 
# @author Bernhard R. Fischer, 2048R/5C5FFD47 <bf@abenteuerland.at>
# @version 20101116
#

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
   my @vals = split /\t/;

   print "   <csventry line='$lineno'>\n";
   for (my $i = 0; $i < @keys; $i++)
   {
      $vals[$i] =~ s/^"(.*)"$/\1/;
      print "      <csvcol k='$keys[$i]' v='$vals[$i]' />\n" if length "$vals[$i]";
   }
   print "   </csventry>\n";
}

print "</csv>\n";

