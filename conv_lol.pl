#!/usr/bin/perl
#
# This perl script extracts data from the unformatted
# List of Lights into a formatted from.
# Run `conv_lol.pl < list.txt | grep LIGHT: > list.csv`.
#
# The List of Lights has to converted into text before.
# The conversion should be done with `pdftotext -raw`.
#
# @author Bernhard R. Fischer <bf@abenteuerland.at>
#

# line buffer keeps last 4 lines
@lbuf = ("", "", "", "");
$lcnt = 0;
$icnt = 0;

while (<>)
{
   $lcnt++;
   $match = 0;
   chomp;

   # append rest of previous line
   if ($su) { $_ = "$su$_"; }

   print "{$_}\n";

   # skip page breaks
   if (/\f/) { next; }

#   area detection unsafe
#   elsif (/^[A-Z\- ]*$/)
#   {
#      print "AREA: ";
#   }

   if (/(.*):$/)
   {
      print "SECTION: ";
      $osection = $section;
      $section = $1;
      undef $su;
      $match = 1;
   }

   # This detects the international light number.
   # Once it is found, all previous data is displayed
   # and cleared.
   if (/^[A-Z] [0-9]{4,4}(.[0-9]{1,2})?$/)
   {
      # correct erroneous height detection
      if ($hml == $lcnt - 1) { $hm = ""; }
      if ($hfl == $lcnt - 1) { $hf = ""; }
      if (($hm eq "") && ($range eq "") && ($hf ne "")) { $range = $hf; $hf = ""; }
      # Correct if number of light was accidently detected
      # as structure.
      if ($struct =~ /^( [A-Z] )?[0-9]+(\.[0-9]+)?[\.]?$/) { print "UNDEF \"$struct\"\n"; undef $struct; }

      # output
      print "LIGHT:\t";
      # Is it the first line?
      unless ($intnr) { print "INTNR\tUSLNR\tSECTION\tNAME\tLAT\tLON\tLAT_D\tLON_D\tCHARACTER\tPERIOD\tSEQUENCE\tSECTOR\tHEIGHT [ft}\tHEIGHT [m]\tRANGE [nm]\tHORN\tWHISTLE\tRACON\tSAFE_WATER\tSTRUCTURE\n"; }
      else { print "$intnr\t$uslnr\t$osection\t$name\t$lat\t$lon\t$latd\t$lond\t$char\t$per\t$group\t$sector\t$hf\t$hm\t$range\t$horn\t$whistle\t$racon\t$sw\t$struct\n"; }

      # New sections are detected directly before end of light
      # is detected, hence, previous light belongs to previous (old) section.
      # This is what happens here.
      if ($section ne $osection) { $osection = $section; }

      # clear variables to reduce risk of detection errors.
      $name = "";
      undef $lat;
      undef $lon;
      $name = "";
      undef $char;
      $hf = "";
      $hm = "";
      $range = "";
      $horn = "";
      $whistle = "";
      $hu = 0;
      $per = "";
      $group = "";
      undef $sector;
      undef $su;
      undef $latd;
      undef $lond;
      undef $racon;
      undef $sw;
      undef $struct;
      undef $stcont;
      undef $structend;
      $icnt = 0;

      $intnr = $_;
      $uslnr = $lbuf[0];
      $match = 1;
      print "USLNR: $uslnr, INTNR: ";
   }

   unless ($racon)
   {

   # Detect latitude/longitude.
   if (/((.*?) )?(([0-9]{1,3})° ([0-9]{2,2}\.[0-9])´ ([NS]))/)
   {
      unless ($lat)
      {
         unless ($2) { $name = "$lbuf[1] $lbuf[0]"; }
         else { $name = $2; }
         $lat = $3;
         print "LAT: ($1) ($2) ($3) ($4) ($5) ($6) ";
         $latd = $5 / 60.0 + $4;
         if ($6 eq "S") { $latd = -$latd; }
         #$latd =~ s/\./,/;
         $match = 1;
      }
   }
   if (/([0-9]{1,3})° ([0-9]{2,2}\.[0-9])´ ([EW])/)
   {
      unless ($lon)
      {
         $lon = $_;
         print "LON: ($1) ($2) ($3) ";
         $lond = $2 / 60.0 + int($1);
         if ($3 eq "W") { $lond = -$lond; }
         #$lond =~ s/\./,/;
         $match = 1;
      }
   }

   #elsif (/^(([0-9] )?(Al\.|Dir\.)?([FLVIWRGU]\.)?([WRG]|F|Q|Mo|Oc|Fl|Iso|I)\.(\([A-Z0-9\+]+\))?(\+(([LV]\.)?(F|Q|Mo|Oc|Fl|Iso|I)\.))?(([RGWY]|Vi|Bu|Or)\.){1,3}( \([a-z]+\.\))?)[ ]*(.*)/)
   if (/^((([0-9]) )?((\([A-Z0-9\+]+\))?\+?[A-Z][a-z]{0,2}\.)+( \([a-z]+\.\))?)([ ]+(.*))?/ && $lon)
   {
      unless ($char)
      {
         $char = $1;
         $icnt = 3;
         print "CHAR: ($8) ";
         $match = 1;
         if ($8 =~ /^([0-9]+)$/)
         { 
            $hf = $1; 
            print "\nHEIGHT [ft]: ";
         }
      }
   }

   # Detect height of light.
   if (/^[0-9]+$/)
   {
      unless ($range)
      {
         unless ($hf) 
         { 
            $hf = $_; 
            $hfl = $lcnt;
            $match = 1;
            print "HEIGHT [ft]: ";
         }
         else
         { 
            unless ($hm) 
            { 
               $hm = $_; 
               $hml = $lcnt;
               $match = 1;
               print "HEIGHT [m]: ";
            } 
         }
      }
   }

   # Detect range of sector light.
   if (/^[WRG]\. [0-9]+$/)
   {
      unless ($range) { $range = $_; }
      else { $range = "$range, $_"; }
      $rnl = $lcnt;
      $match = 1;
      print "RANGE: ";
   }

   if ($stcont)
   {
      if (/([^\.]*\.)/)
      {
         $struct = "$struct $1";
         undef $stcont;
         $match = 1;
         $structend = 1;
         print "STRUCT END: ";
      }
   }

   # Detect plain range:
   if ($char)
   {
   if (/^([0-9]+) (.*)/)
   {
      unless ($range)
      {
         $range = $1;
         $rnl = $lcnt;
         $struct = $2;
         $icnt = 9;
         $match = 1;
         print "RANGE: ($1) ";
         if ($struct =~ /[^\.]/)
         {
            print "STRUCT cont'd ";
            $stcont = 1;
         }
         else { undef $stcont; }

      }
   }
   }

   # was "Horn" line-breaked?
   # (must be before detection of beginning.)
   if ($hu == 1)
   {
      # detect end of "Horn"
      if (/\)\./) { $hu = 0; }
      $horn = "$horn $_";
      $match = 1;
      print "HORN (cont'd) ";
   }

   # Is there a "Horn"?
   if (/.*?Horn: (.*)/)
   {
      $horn = $1;
      $match = 1;
      print "HORN: ($1) ";
      if ($horn =~ /(\([^\)]*$)/) { $hu = 1; }
      else { $hu = 0; }
      print "($hu) ($1) ";
   }

   # Is there a "Whistle"?
   if (/Whistle\./)
   {
      $whistle = "yes";
      $match = 1;
      print "WHISTLE: ";
   }

   if (/period ([0-9]+)s/)
   {
      $per = $1;
      $icnt = 4;
      $match = 1;
      print "PERIOD: ";
   }

   if (/(fl|lt)\. ([0-9\.]+)s, ec\. ([0-9\.]+)s/)
   {
      unless ($group) { $group = "$2,($3)"; }
      else { $group = "$group,$2,($3)"; }
      $icnt = 5;
      $match = 1;
      print "GROUP: ";
   }

   #while (/(([WRG]\.[ ]?)?(([0-9]{3}°([0-9]{2}′)?)|obsc\.)?-([0-9]{3}°([0-9]{2}′)?))(.)(.*)/)
   if ($name)
   {
      undef $whloop;
   while (/(([WRG]\.|[A-Za-z]+)?[ ]?(([0-9]{3}°([0-9]{2}′)?)|[A-Za-z\.]*)?-([0-9]{3}°([0-9]{2}′)?))(.)(.*)/)
   {
      $whloop = 1;
      unless ($sector) { $sector = $1; }
      else { $sector = "$sector,$1"; }
      $match = 1;

      print "SECTOR: ($1) ($2) ($3) ($4) ($5) ($6) ($7) ($8) ($9) ";
      $del = $8;
      print " \\$1$8\\ ";
      s/\Q$1$8\E//;

      if (($del eq ",") || ($del eq " "))
      { 
         $su = $_;
         print "SECTOR cont'd "; 
      }
      else 
      { 
         undef $su;
         print "SECTOR END "; 
      }
      print " :$_: ";
   }

      if ($su =~ /([^\.]+\.)$/)
      {
         $sector = "$sector,$1";
         undef $su;
         $match = 1;
         print "NONSECTOR END ";
      }

      if ($su && !$whloop)
      {
         $sector = "$sector,$_";
         undef $su;
         $match = 1;
         print "NONSECTOR END ";
      }

      if (!$su && $whloop)
      { 
         print "NOT_SECTOR: \"\"$_\"\""; 
         if (/([^\.]+[\.])/ && !$structend)
         {
            $struct = $1;
            print "STRUCT: ";
         }
      }
   }

   if (/SAFE WATER/)
   {
      $sw = "yes";
   }

   } # unless ($racon)

   if (/^[\-]*RACON (.*)/)
   {
      $racon = $1;
      $match = 1;
      print "RACON: ";
   }

   unless ($match)
   {
      if (!$struct && $lat && $lon)
      {
         $struct = $_;
         if ($struct =~ /[^\.]/)
         {
            print "STRUCT cont'd ";
            $stcont = 1;
         }
         else { undef $stcont; }
         print "STRUCT: ";
      }
   }

#   print "$_\n";
   print "\n";

   unshift(@lbuf, $_);
   pop(@lbuf);
}

