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

   if (/^([\-]*)(.*):$/)
   {
      $lasts = 1;
      print "SECTION: ";
      $osection = $section;
      if ($1)
      {
         $section = "$topsection$1$2";
      }
      else
      {
         $section = $2;
         $topsection = $section;
      }
      undef $su;
      $match = 1;
      next;
   }

   # This detects the international light number.
   # Once it is found, all previous data is displayed
   # and cleared.
   if (/^([A-Z]) ([0-9]{4,4})(\.([0-9]{1,2}))?$/)
   {
      @oiintnr = @iintnr;
      $iintnr[0] = $1;
      $iintnr[1] = $2;
      $iintnr[2] = $4;

      # correct erroneous height detection
      if ($hml == $lcnt - 1) { $hm = ""; }
      if ($hfl == $lcnt - 1) { $hf = ""; }
      if (($hm eq "") && ($range eq "") && ($hf ne "")) { $range = $hf; $hf = ""; }
      # Correct if number of light was accidently detected
      # as structure.
      if ($struct =~ /^( [A-Z] )?[0-9]+(\.[0-9]+)?[\.]?$/) { print "UNDEF \"$struct\"\n"; undef $struct; }
      if ($siren) { $siren = $horn; undef $horn; }
      # some lights don't have coords
      unless ($lat) { $lat = "0° 00.0´ N"; $latd = 0.0; }
      unless ($lon) { $lon = "0° 00.0´ E"; $lond = 0.0; }

      # Remove leading or trailing spaces from name.
      $name =~ s/(?:^ +)||(?: +$)//g;
      if ($name =~ /^([\-]+)/)
      {
         $n = length($1);
         $namea[$n] = $name;
         for ($i = $n + 1; $i < 5; $i++)
         {
            undef $namea[$i];
         }
      }
      else
      {
         undef @namea;
         $namea[0] = $name;
      }

      # output
      print "LIGHT:\t";
      # Is it the first line?
      unless ($intnr) { print "INTNR\tIINTNR_1\tIINTNR_2\tIINTNR_3\tUSLNR\tSECTION\tNAME\tNAME_COMB\tLAT\tLON\tLAT_D\tLON_D\tCHARACTER\tMULT_LIGHT\tCHAR_ONLY\tGROUP\tPOS\tCOLOUR\tPERIOD\tSEQUENCE\tSECTOR\tHEIGHT [ft}\tHEIGHT [m]\tRANGE [nm]\tHORN\tSIREN\tWHISTLE\tRACON\tSAFE_WATER\tRADAR_REFLECTOR\tTOPMARK\tAV_LIGHT\tSTRUCTURE\n"; }
      else { print "$intnr\t$oiintnr[0]\t$oiintnr[1]\t$oiintnr[2]\t$uslnr\t$xsection\t$name\t$namea[0]$namea[1]$namea[2]$namea[3]$namea[4]\t$lat\t$lon\t$latd\t$lond\t$char\t$mult_light\t$charo\t$rgroup\t$pos\t$chcol\t$per\t$group\t$sector\t$hf\t$hm\t$range\t$horn\t$siren\t$whistle\t$racon\t$sw\t$rref\t$topmark\t$avia\t$struct\n"; }

      # New sections are detected directly before end of light
      # is detected, hence, previous light belongs to previous (old) section.
      # This is what happens here.
      if ($lasts)
      #if ($section ne $osection)
      { 
         $xsection = $section;
         undef $lasts;
         undef @namea; 
      }

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
      undef $siren;
      $icnt = 0;
      undef $rgroup;
      undef $pos;
      undef $chcol;
      undef $charo;
      undef $rref;
      undef $topmark;
      undef $avia;

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
         $mult_light = $3;
         $icnt = 3;
         print "CHAR: ($8) ";
         $match = 1;
         if ($8 =~ /^([0-9]+)$/)
         { 
            $hf = $1; 
            print "\nHEIGHT [ft]: ";
         }
         if ($char =~ /\(([^\)]+)\)/)
         { 
            if (($1 eq "vert.") || ($1 eq "horiz.")) { $pos = $1; }
            else { $rgroup = $1; }
         }
         else { $rgroup = "1"; }

         if ($char =~ /(F|L\.Fl|Al\.Fl|Fl|Iso|Oc|V\.Q|I\.Q|U\.Q|Q|Mo)\./) { $charo = "$1."; }

         while ($char =~ /(W|R|G|Y|Bu|Or|Vi)\./g)
         {
            $chcol = "$chcol$1.";
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
   if (/.*?(Horn|Siren): (.*)/)
   {
      if ($1 eq "Siren") { $siren = 1; }
      $horn = $2;
      $match = 1;
      $rxc = "$1: $2";
      print "HORN: ($2) ";
      if ($horn =~ /(\([^\)]*$)/) { $hu = 1; }
      else { $hu = 0; }
      print "($hu) ($1) ";
      s/\Q$rxc\E//;
   }

   # Is there a "Whistle"?
   if (/Whistle\./)
   {
      $whistle = "yes";
      $match = 1;
      print "WHISTLE: ";
   }

   if (/Radar reflector/) { $rref = "yes"; }

   if (/topmark/) { print "TOPMARK: "; $topmark = "yes"; }

   if (/AVIATION/) { print "AVIATION: "; $avia = "yes"; }

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

