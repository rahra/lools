#!/usr/bin/perl


use strict;
use Switch;

use constant MAX_SEC_DEPTH => 3;
use constant NL_LAT => 1;
use constant NL_CHAR => 2;
use constant NL_RNG => 3;


my $lineno = 0;
my $namebreak = 0;
my $intfound = 0;
my $heightmfound = 0;
my $header = 1;
my $structbreak = 0;

my $next_line = 0;

my @section = ();
my %light = ();


while (<STDIN>)
{
   chomp;
   $lineno++;
#print "{ $_ }\n";
#print "$next_line, $lineno, $intfound, $heightmfound, $namebreak, $structbreak\n";
   if ($next_line)
   {
      switch ($next_line)
      {
         case NL_LAT
         {
            $next_line = 0;

            if (/(([0-9]{1,3})° ([0-9]{2,2}\.[0-9])´( [NS]))( <b>([^<]*)<\/b>)(\([^\)]*\))?<br>/)
            {
               $light{'lat'} = $1;
               $light{'latd'} = $2 + $3 / 60.0;
               if ($4 eq " S") { $light{'latd'} = -$light{'latd'}; }
               $light{'char'} = $6;
               if ($7) { $light{'mpos'} = $7; }
            }
            elsif (/(0° 00.0´)<br>/)
            {
               $light{'lat'} = $1;
               $light{'latd'} = 0.0;
               $next_line = NL_CHAR;
            }
         }
         case NL_CHAR
         {
            $next_line = 0;
            if (/<b>([^<]*)<\/b>(\([^\)]*\))?<br>/)
            {
               $light{'char'} = $1;
               if ($2) { $light{'mpos'} = $2; }
            }
         }
         case NL_RNG
         {
            $next_line = 0;
            if (/(<b>)?([0-9]+) (<\/b>)?([^<]*?(\.)?)<br>/)
            {
               $light{'range'} = $2;
               $light{'struct'} = $4;
               unless ($5) { $structbreak = 1; }
            }
         }
         else
         {
            print STDERR "*** unknown \$next_line = $next_line\n";
            $next_line = 0;
         }
      } # switch ($next_line)
      next;
   }

   if ($intfound && $namebreak)
   {
      m/([^<]*)<br>$/;
      $light{'name'} = "$light{'name'}$1";
      $namebreak = 0;
      next;
   }
   $intfound = 0;

   if ($heightmfound && $structbreak)
   {
      m/([^<]*)<br>$/;
      $light{'struct'} = "$light{'struct'}$1";
      $structbreak = 0;
      next;
   }
   $heightmfound = 0;

   if (/^(([0-9]+)(\.[0-9]+)?) ((<(.)>|([A-Z])|-)([^<]*?)(\.)?(<\/.>)?([^<]*?)(\.)?)<br>$/)
   {
      if ($7 && ($light{'uslnr'} > $1))
      {
#         print "ILL ($6): $_\n";
      }
      else
      {
         # output light
         #foreach my $elem (values %light) { print "\"$elem\","; }
         while ((my $k, my $v) = each(%light)) { print "$k => \"$v\","; }
         print "\n";


         # reset variables after output
         $intfound = 0;
         $namebreak = 0;
         $structbreak = 0;
         $next_line = 0;
         $heightmfound = 0;

         %light = ();

         # check if name is line-breaked
         if (!$12 && $11) { $namebreak = 1; }
         $light{'uslnr'} = $1;
         $light{'name'} = $4;

         $next_line = NL_LAT;
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

   if (/^([0-9]+)<br>/)
   {
      $light{'height_ft'} = $1;
      $next_line = NL_RNG;
      next;
   }

   if (/<b>([0-9]+) <\/b>([^<]*(\.)?)<br>/)
   {print "STR\n";
      $light{'range'} = $1;
      $light{'struct'} = $2;
      unless ($3) { $structbreak = 1; }
      next;
   }

   if (/^<b>([0-9]+)<\/b><br>/)
   {
      $light{'height_m'} = $1;
      $heightmfound = 1;
      next;
   }
}

