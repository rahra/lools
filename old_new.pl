#!/usr/bin/perl

use strict;

my $nr = shift;
$nr = "usl_list=$nr AND" if $nr;

my $old = 0;
my $new = 0;

while (<>)
{
   if (m/S'([-]?)([0-9]+)'/)
   {
      if ($1)
      {
         $old = "$1$2";
      }
      else
      {
         $new = $2;

         print "UPDATE lights SET osm_id=$new WHERE $nr osm_id=$old;\n";
      }
   }
}

