#!/usr/bin/perl
#
# @author Bernhard R. Fischer, 2048R/5C5FFD47 <bf@abenteuerland.at>
#

use strict;
use feature ":5.10";

#my $pub_nr = shift;
my $pub_nr = `cat NR`;
$pub_nr =~ s/[^0-9]//g;

my $lcnt = 1;
my $colors = "W|R|G|Y|Bu|Or|Vi";
my $visible = "Visible|Obscured|Intensified|Unintensified";
my $intensv = '\(unint\.\)|\(int\.\)|\(intensified\)|\(unintensified\)';
my @vals;
my %val;

my $uslnr;
my $uslsubnr;
my $intsubnr;
my $char;
my $group;
#my $topm;
 
my $date = `date`;
chomp $date;
print "-- File generated at $date.\n-- Use at your own risk.\n\n";


if ($pub_nr) { print "DELETE FROM sectors WHERE usl_list='$pub_nr';\nDELETE FROM lights WHERE usl_list='$pub_nr';\n\n"; }
else { print "DELETE FROM sectors;\nDELETE FROM lights;\n\n"; }

# the first line of the csv file must be a header line
$_ = <STDIN>;
chomp;
my @keys = split /\t/, lc;
print "-- KEYS: @keys\n\n";

while (<STDIN>)
{
   $lcnt++;
   chomp;
   s/'/\\'/g;
   s/"//g;
   @vals = split /\t/;

   # convert value array to hash
   %val = ();
   my $i = 0;
   foreach (@vals) { $val{"$keys[$i++]"} = $_; }

   print "-- LINENO $lcnt:\n";
   print "INSERT INTO lights VALUES (1,NULL,";

   my $udup = $val{'error'} =~ /usldup/ ? 'a' : '';

   undef $uslnr;
   undef $uslsubnr;
   if ($val{'uslnr'} =~ /([0-9]+)(\.([0-9]+))?/)
   {
      $uslnr = $1;
      $uslsubnr = $3 . $udup;
   }

   my $idup = $val{'error'} =~ /intdup/ ? 'a' : '';
   #$val{'intnr'} =~ s/"//g;
   if ($val{'intnr'})
   {
      undef $intsubnr;
      if ($val{'intnr'} =~ /^([A-Z]?)([0-9]+)(\.([0-9]+))?/)
      {
         $intsubnr = $4 . $idup;
         print "'$1','$2','$intsubnr',";
      }
   }
   else
   {
      print "'u','$uslnr-$val{'usl_list'}','$uslsubnr',";
   }

   # set some missing default values if missing
   $val{'multi'} = 1 unless $val{'multi'};
   $val{'period'} = 0 unless $val{'period'};
   $val{'height_m'} = 0 unless $val{'height_m'};
   $val{'height_ft'} = 0 unless $val{'height_ft'};
   $val{'height_ft'} = 0 if $val{'height_ft'} eq "N/A";
   $val{'latd'} = 0.0 unless $val{'latd'};
   $val{'lond'} = 0.0 unless $val{'lond'};
   $val{'dir'} = 'NULL' if $val{'dir'} eq "";
   $val{'dirdist'} = 'NULL' if $val{'dirdist'} eq "";

   undef $char;
   undef $group;
   if ($val{'char'} =~ /^([0-9] ?)?(Dir\.)?(F|L.Fl|Al.Fl|Fl|Iso|Oc|V.Q|U.Q|Q|Mo)\.(\((.*?)\))?/)
   {
      $char = $3;
      $group = $5;
      $group = 1 unless $5;
   }

   my $leading = 'NULL';
   $leading = "'front'" if $val{'rear'};
   $leading = "'rear'" if $val{'front'};

   my $fsignal = $val{'fsignal'} ? "'$val{'fsignal'}'" : 'NULL';

   #$topm = $val{'topmark'} ? 1 : 0;
   print "'$val{'usl_list'}',$uslnr,'$uslsubnr','$val{'section'}','$val{'name'}','$val{'longname'}',$val{'latd'},$val{'lond'},'$val{'char'}','$char','$group','$val{'mpos'}',$val{'period'},$val{'multi'},$val{'height_ft'},$val{'height_m'},'$val{'sequence'}','','',0,$val{'rreflect'},'$val{'topmark'}',0,'$val{'racon'}','$val{'struct'}','$val{'type'}','$val{'typea'}','$val{'bsystem'}','$val{'shape'}','$val{'shapecol'}',$fsignal,'$val{'error'}','$val{'source'}','$val{'rem'}',$val{'dir'},$val{'dirdist'},$leading";

   print ");\n";

   my $loop = 0;
   my $col;
   my $coll = "";
   my $start = 0;
   my $end = 0;

   my @defcol = ();
   while ($val{'char'} =~ /($colors)\./g) { push @defcol, $1; }

   # insert all sectors that are found
   if ($val{'sector'} =~ /$intensv/) { print STDERR "$uslnr, $val{'sector'}\n"; }
   while ($val{'sector'} =~ /($colors|$visible)\.?($intensv)?(([0-9]{3,3})°(([0-9]+)′)?)?\-(([0-9]{3,3})°(([0-9]+)′)?)/g)
   {
      print STDERR " $uslnr 1:$1 2:$2 3:$3 4:$4 5:$5 6:$6 7:$7 8:$8 9:$9 10:$10\n";

      if ($4) { $start = $4 + $6 / 60; }
      else { $start = $end; }
      $end = $8 + $10 / 60;

      my $vis = "";

      given ($1)
      {
         when ("Obscured")
         {
            my $t = $start;
            $start = $end;
            $end = $t;
            $col = $defcol[0];
            $coll .= "$defcol[0],";
         }
         when ("Visible")
         {
            $col = $defcol[0];
            $coll .= "$defcol[0],";
         }
         when ("Intensified")
         {
            $vis = "int";
            $col = $defcol[0];
            $coll .= "$defcol[0],";
         }
         when ("Unintensified")
         {
            $vis = "unint";
            $col = $defcol[0];
            $coll .= "$defcol[0],";
         }
         default
         {
            $col = $1;
            $coll .= "$1,";
         }
      }

      if ($2)
      {
         if ($2 =~ /unint/) { $vis = "unint"; }
         else { $vis = "int"; }
      }

      print "   INSERT INTO sectors VALUES (NULL, '$val{'usl_list'}',$uslnr,'$uslsubnr',NULL,$start,$end,'$col',NULL, '$vis');\n";
      $loop++;
   }

   foreach my $c (@defcol)
   {
      if ($val{'dir'} ne "NULL")
      {
         print "   -- leading rear \"$val{'dir'}\"\n";
         print "   INSERT INTO sectors VALUES (NULL, '$val{'usl_list'}',$uslnr,'$uslsubnr',NULL,$val{'dir'},$val{'dir'},'$c',NULL,'');\n";
         next;
      }

      unless ($coll =~ /$c/)
      {
         print "   INSERT INTO sectors VALUES (NULL, '$val{'usl_list'}',$uslnr,'$uslsubnr',NULL,NULL,NULL,'$c',NULL,'');\n";
      }
   }

   if ($val{'range'} =~ /^[0-9]+$/)
   {
      print "   UPDATE sectors SET sectors.range=$val{'range'} WHERE usl_list='$val{'usl_list'}' AND usl_nr=$uslnr AND usl_subnr='$uslsubnr';\n";
   }
   else
   {
      while ($val{'range'} =~ /($colors)\.([0-9]+)/g)
      {
         print "   UPDATE sectors SET sectors.range=$2 WHERE usl_list='$val{'usl_list'}' AND usl_nr=$uslnr AND usl_subnr='$uslsubnr' AND colour='$1';\n";
      }
   }
}

