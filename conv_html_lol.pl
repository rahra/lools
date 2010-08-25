#!/usr/bin/perl

use strict;


my $lineno = 0;
my $uslnr = 0;
my $intnr = "";
my $namebreak = 0;
my $intfound = 0;


while (<>)
{
   chomp;
   $lineno++;

   if ($intfound && $namebreak)
   {
      $uslnr = "$uslnr :: $_";
      $intfound = 0;
      $namebreak = 0;
      next;
   }

   if (/^(([0-9]+)(\.[0-9]+)?) (<(.)>|([A-Z])|-)([^<]*?)(\.)?(<\/.>)?([^<]*?)(\.)?<br>$/)
   {
      if ($6 && ($uslnr > $1))
      {
#         print "ILL ($6): $_\n";
      }
      else
      {
         # output light
         print "$intnr\t$uslnr\n";


         # reset variables after output
         $intfound = 0;
         $namebreak = 0;
         $intnr = "";

         # check if name is line-breaked
         if (!$11 && $10) { $namebreak = 1; }
         #print "$_\n";
         $uslnr = $_;
         next;
      }
   }

   if (/^<i>([A-Z] [0-9]{4}(\.[0-9]+)?)<\/i>/)
   {
      $intnr = $1;
      $intfound = 1;
      next;
   }
}

