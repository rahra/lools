#!/usr/bin/perl

use strict;

#my $pub_nr = shift;
my $pub_nr = `cat NR`;
$pub_nr =~ s/[^0-9]//g;

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
   @vals = split /\t/;

   # convert value array to hash
   %val = ();
   my $i = 0;
   foreach (@vals) { $val{"$keys[$i++]"} = $_; }

   print "-- LINENO $lcnt:\n";
   print "INSERT INTO lights VALUES (1,NULL,";

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
      print "'$1','$2','$intsubnr',";
   }
   else
   {
      print "'u','$uslnr-$val{'usl_list'}','$uslsubnr',";
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

   my $fsignal = $val{'fsignal'} ? "'$val{'fsignal'}'" : 'NULL';

   #$topm = $val{'topmark'} ? 1 : 0;
   print "'$val{'usl_list'}',$uslnr,'$uslsubnr','$val{'section'}','$val{'name'}','',$val{'latd'},$val{'lond'},'$val{'character'}','$char','$group','$mpos',$val{'period'},$val{'multiplcty'},$val{'height_ft'},$val{'height_m'},'$val{'sequence'}','','',0,$val{'rreflect'},'$val{'topmark'}',0,'$val{'racon'}','$val{'struct'}','$val{'type'}','$val{'typea'}','$val{'bsystem'}','$val{'shape'}','$val{'shapecol'}',$fsignal,'$val{'error'}','$val{'source'}','$val{'remark'}'";

   print ");\n";

   my $loop = 0;
   my $col;
   my $coll = "";
   my $start = 0;
   my $end = 0;

   # insert all sectors that are found
   my $intensv = '\(unint\.\)|\(int\.\)|\(intensified\)|\(unintensified\)';
   if ($val{'sector'} =~ /$intensv/) { print STDERR "$uslnr, $val{'sector'}\n"; }
   while ($val{'sector'} =~ /($colors)\.?($intensv)?(([0-9]{3,3})°(([0-9]+)′)?)?\-(([0-9]{3,3})°(([0-9]+)′)?)/g)
   {
      print STDERR " $uslnr 1:$1 2:$2 3:$3 4:$4 5:$5 6:$6 7:$7 8:$8 9:$9 10:$10\n";
      $col = $1;
      $coll .= "$1,";
      if ($4) { $start = $4 + $6 / 60; }
      else { $start = $end; }
      $end = $8 + $10 / 60;
      my $vis = "";
      if ($2)
      {
         if ($2 =~ /unint/) { $vis = "unint"; }
         else { $vis = "int"; }
      }
      print "   INSERT INTO sectors VALUES (NULL, '$val{'usl_list'}',$uslnr,'$uslsubnr',NULL,$start,$end,'$col',NULL, '$vis');\n";
      $loop = 1;
   }

   while ($val{'character'} =~ /($colors)\./g)
   {
      $col = $1;
      unless ($coll =~ /$col/)
      {
         print "   INSERT INTO sectors VALUES (NULL, '$val{'usl_list'}',$uslnr,'$uslsubnr',NULL,NULL,NULL,'$col',NULL,'');\n";
      }
   }

   if ($val{'sector'} =~ /Intensified(([0-9]{3,3})°(([0-9]+)′)?)\-(([0-9]{3,3})°(([0-9]+)′)?)/)
   {
      $start= $2 + $4 / 60;
      $end = $6 + $8 / 60;
      #print "-- Intensified\n";
      print "   UPDATE sectors SET sectors.visibility='int',sectors.start=$start,sectors.end=$end WHERE usl_list='$val{'usl_list'}' AND usl_nr=$uslnr AND usl_subnr='$uslsubnr';\n";
   }
   elsif ($val{'sector'} =~ /Unintensified(([0-9]{3,3})°(([0-9]+)′)?)\-(([0-9]{3,3})°(([0-9]+)′)?)/)
   {
      $start= $2 + $4 / 60;
      $end = $6 + $8 / 60;
      #print "-- Unintensified\n";
      print "   UPDATE sectors SET sectors.visibility='unint',sectors.start=$start,sectors.end=$end WHERE usl_list='$val{'usl_list'}' AND usl_nr=$uslnr AND usl_subnr='$uslsubnr';\n";
   }
   elsif ($val{'sector'} =~ /(Obscured|Visible)($intensv)?(([0-9]{3,3})°(([0-9]+)′)?)\-(([0-9]{3,3})°(([0-9]+)′)?)/)
   {
      #print "-- PSECTOR: $1 -- $2 -- $3\n";
      if ($1 eq "Obscured")
      {
         $end = $4 + $6 / 60;
         $start = $8 + $10 / 60;
      }
      else
      {
         $start = $4 + $6 / 60;
         $end = $8 + $10 / 60;
      }
      my $vis = "";
      if ($2)
      {
         if ($2 =~ /^un/) { $vis = "unint"; }
         else { $vis = "int"; }
      }
      print "   UPDATE sectors SET sectors.start=$start,sectors.end=$end,sectors.visibility='$vis' WHERE usl_list='$val{'usl_list'}' AND usl_nr=$uslnr AND usl_subnr='$uslsubnr';\n";
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

