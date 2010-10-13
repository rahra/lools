#!/usr/bin/perl

use strict;


my $lcnt = 1;
my $colors = "W|R|G|Y|Bu|Or|Vi";
my @vals;
my %val;

my $uslnr;
my $uslsubnr;
my $intsubnr;
my $char;
my $group;
#my $topm;
 
print "TRUNCATE lights;\nTRUNCATE sectors;\n\n";

# the first line of the csv file must be a header line
$_ = <STDIN>;
chomp;
my @keys = split /\t/, lc;
print "-- KEYS: @keys\n";

while (<STDIN>)
{
   $lcnt++;
   chomp;
   s/'/\\'/g;
   @vals = split /\t/;

   # convert value array to hash
   %val = ();
   my $i = 0;
   foreach (@vals) { $val{"$keys[$i++]"} = $_; }

   print "-- LINENO $lcnt:\n";
   print "INSERT INTO lights VALUES (1,";

   my $udup = $val{'error'} =~ /usldup/ ? 'a' : '';
   $val{'uslnr'} =~ /([0-9]+)(\.([0-9]+))?/;
   $uslnr = $1;
   $uslsubnr = $3 . $udup;
   #$uslsubnr = '' unless $3;

   my $idup = $val{'error'} =~ /intdup/ ? 'a' : '';
   $val{'intnr'} =~ s/ //g;
   if ($val{'intnr'})
   {
      $val{'intnr'} =~ /^([A-Z])([0-9]+)(\.([0-9]+))?/;
      $intsubnr = $4 . $idup;
      #$intsubnr = '' unless $4;
      print "'$1',$2,'$intsubnr',";
   }
   else
   {
      print "'u',$uslnr,'$uslsubnr',";
   }

   # set some missing default values if missing
   $val{'multiplcty'} = 1 unless $val{'multiplcty'};
   $val{'period'} = 0 unless $val{'period'};
   $val{'height_m'} = 0 unless $val{'height_m'};
   $val{'height_ft'} = 0 unless $val{'height_ft'};
   $val{'height_ft'} = 0 if $val{'height_ft'} eq "N/A";
   $val{'latd'} = 0.0 unless $val{'latd'};
   $val{'lond'} = 0.0 unless $val{'lond'};

   $val{'mult_pos'} =~ /\((horiz|vert)\.\)/;
   my $mpos = $1;

   $val{'character'} =~ /^([0-9] ?)?(Dir\.)?(F|L.Fl|Al.Fl|Fl|Iso|Oc|V.Q|U.Q|Q|Mo)\.(\((.*?)\))?/;
   $char = $3;
   $group = $5;
   $group = 1 unless $5;

   #$topm = $val{'topmark'} ? 1 : 0;

   print "$uslnr,'$uslsubnr','$val{'section'}','$val{'name'}','',$val{'latd'},$val{'lond'},'$val{'character'}','$char','$group','$mpos',$val{'period'},$val{'multiplcty'},$val{'height_ft'},$val{'height_m'},'$val{'sequence'}','','',0,0,'$val{'topmark'}',0,'$val{'racon'}','$val{'struct'}','$val{'type'}','$val{'typea'}','$val{'bsystem'}'";

   print ");\n";

   my $loop = 0;
   my $col;
   my $coll = "";
   my $start = 0;
   my $end = 0;

   # insert all sectors that are found
   while ($val{'sector'} =~ /($colors)\.?(([0-9]{3,3})°(([0-9]+)′)?)?\-(([0-9]{3,3})°(([0-9]+)′)?)/g)
   {
      $col = $1;
      $coll .= "$1,";
      if ($3) { $start = $3 + $5 / 60; }
      else { $start = $end; }
      $end = $7 + $9 / 60;
      print "   INSERT INTO sectors VALUES ($uslnr,'$uslsubnr',NULL,$start,$end,'$col',NULL, '');\n";
      $loop = 1;
   }

   while ($val{'character'} =~ /($colors)\./g)
   {
      $col = $1;
      unless ($coll =~ /$col/)
      {
         print "   INSERT INTO sectors VALUES ($uslnr,'$uslsubnr',NULL,NULL,NULL,'$col',NULL,'');\n";
      }
   }

   if ($val{'sector'} =~ /Intensified(([0-9]{3,3})°(([0-9]+)′)?)\-(([0-9]{3,3})°(([0-9]+)′)?)/)
   {
      $start= $2 + $4 / 60;
      $end = $6 + $8 / 60;
      print "-- Intensified\n";
      print "   UPDATE sectors SET sectors.visibility='int',sectors.start=$start,sectors.end=$end WHERE usl_nr=$uslnr AND usl_subnr='$uslsubnr';\n";
   }
   elsif ($val{'sector'} =~ /Unintensified(([0-9]{3,3})°(([0-9]+)′)?)\-(([0-9]{3,3})°(([0-9]+)′)?)/)
   {
      $start= $2 + $4 / 60;
      $end = $6 + $8 / 60;
      print "-- Unintensified\n";
      print "   UPDATE sectors SET sectors.visibility='unint',sectors.start=$start,sectors.end=$end WHERE usl_nr=$uslnr AND usl_subnr='$uslsubnr';\n";
   }
   elsif ($val{'sector'} =~ /Obscured(([0-9]{3,3})°(([0-9]+)′)?)\-(([0-9]{3,3})°(([0-9]+)′)?)/)
   {
      $end = $2 + $4 / 60;
      $start = $6 + $8 / 60;
      print "-- Obscured\n";
      print "   UPDATE sectors SET sectors.start=$start,sectors.end=$end WHERE usl_nr=$uslnr AND usl_subnr='$uslsubnr';\n";
   }
   elsif ($val{'sector'} =~ /Visible(([0-9]{3,3})°(([0-9]+)′)?)\-(([0-9]{3,3})°(([0-9]+)′)?)/)
   {
      $start= $2 + $4 / 60;
      $end = $6 + $8 / 60;
      print "-- Visible\n";
      print "   UPDATE sectors SET sectors.start=$start,sectors.end=$end WHERE usl_nr=$uslnr AND usl_subnr='$uslsubnr';\n";
   }

   if ($val{'range'} =~ /^[0-9]+$/)
   {
      print "   UPDATE sectors SET sectors.range=$vals[20] WHERE usl_nr=$uslnr AND usl_subnr='$uslsubnr';\n";
   }
   else
   {
      while ($val{'range'} =~ /($colors)\. ([0-9]+)/g)
      {
         print "   UPDATE sectors SET sectors.range=$2 WHERE usl_nr=$uslnr AND usl_subnr='$uslsubnr' AND colour='$1';\n";
      }
   }
}

