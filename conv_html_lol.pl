#!/usr/bin/perl


use strict;
use constant MAX_SEC_DEPTH => 3;


my $lineno = 0;
my $namebreak = 0;
my $intfound = 0;

my @section = ();
my %light = ();


while (<STDIN>)
{
   chomp;
   $lineno++;

   if ($intfound && $namebreak)
   {
      $light{'uslnr'} = "$light{'uslnr'} :: $_";
      $intfound = 0;
      $namebreak = 0;
      next;
   }

   if (/^(([0-9]+)(\.[0-9]+)?) (<(.)>|([A-Z])|-)([^<]*?)(\.)?(<\/.>)?([^<]*?)(\.)?<br>$/)
   {
      if ($6 && ($light{'uslnr'} > $1))
      {
#         print "ILL ($6): $_\n";
      }
      else
      {
         # output light
         print %light;
         print "\n";


         # reset variables after output
         $intfound = 0;
         $namebreak = 0;

         %light = ();

         # check if name is line-breaked
         if (!$11 && $10) { $namebreak = 1; }
         $light{'uslnr'} = $_;

         $_ = <STDIN>;
         m/(([0-9]{1,3})° ([0-9]{2,2}\.[0-9])´( [NS])?)(<b>([^<]*)<\/b>)?<br>/;

         $light{'lat'} = $1;
         $light{'latd'} = $2 + $3 / 60.0;
         if ($4 eq " S") { $light{'latd'} = -$light{'latd'}; }
         $light{'char'} = $6;

         next;
      }
   }

   if (/^<i>([A-Z] [0-9]{4}(\.[0-9]+)?)<\/i>/)
   {
      $light{'intnr'} = $1;
      $intfound = 1;
      next;
   }

   if (/(([\-]*)?[^:]*):<br>$/)
   {
      $section[length($2)] = $1;
      for (my $i = length($2) + 1; $i < MAX_SEC_DEPTH; $i++) { undef $section[$i]; }
      next;
   }

}

