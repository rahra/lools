#!/usr/bin/perl

#use utf8;

# line buffer keeps last 4 lines
@lbuf = ("", "", "", "");
$lcnt = 0;

while (<>)
{
   $lcnt++;
   chomp;

   # append rest of previous line
   if ($su) { $_ = "$su$_"; }

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
      $section = $1;
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

      # output
      print "LIGHT:\t";
      # Is it the first line?
      unless ($intnr) { print "INTNR\tUSLNR\tSECTION\tNAME\tLAT\tLON\tLAT_D\tLON_D\tCHARACTER\tPERIOD\tSEQUENCE\tSECTOR\tHEIGHT [ft}\tHEIGHT [m]\tRANGE [nm]\tHORN\tWHISTLE\tRACON\tSAFE_WATER\n"; }
      else { print "$intnr\t$uslnr\t$section\t$name\t$lat\t$lon\t$latd\t$lond\t$char\t$per\t$group\t$sector\t$hf\t$hm\t$range\t$horn\t$whistle\t$racon\t$sw\n"; }

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
      undef $su;
      undef $sw;

      $intnr = $_;
      $uslnr = $lbuf[0];
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
      }
   }

   #elsif (/^(([0-9] )?(Al\.|Dir\.)?([FLVIWRGU]\.)?([WRG]|F|Q|Mo|Oc|Fl|Iso|I)\.(\([A-Z0-9\+]+\))?(\+(([LV]\.)?(F|Q|Mo|Oc|Fl|Iso|I)\.))?(([RGWY]|Vi|Bu|Or)\.){1,3}( \([a-z]+\.\))?)[ ]*(.*)/)
   if (/^((([0-9]) )?((\([A-Z0-9\+]+\))?\+?[A-Z][a-z]{0,2}\.)+( \([a-z]+\.\))?)([ ]+(.*))?/)
   {
      unless ($char)
      {
         $char = $1;
         print "CHAR: ($8) ";
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
            print "HEIGHT [ft]: ";
         }
         else
         { 
            unless ($hm) 
            { 
               $hm = $_; 
               $hml = $lcnt;
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
      print "RANGE: ";
   }

   # Detect plain range:
   if ($char)
   {
   if (/^([0-9]+) .*/)
   {
      unless ($range)
      {
         $range = $1;
         $rnl = $lcnt;
         print "RANGE: ($1) ";
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
      print "HORN (cont'd) ";
   }

   # Is there a "Horn"?
   if (/.*?Horn: (.*)/)
   {
      $horn = $1;
      print "HORN: ($1) ";
      if ($horn =~ /(\([^\)]*$)/) { $hu = 1; }
      else { $hu = 0; }
      print "($hu) ($1) ";
   }

   # Is there a "Whistle"?
   if (/Whistle\./)
   {
      $whistle = "yes";
      print "WHISTLE: ";
   }

   if (/period ([0-9]+)s/)
   {
      $per = $1;
      print "PERIOD: ";
   }

   if (/fl\. ([0-9\.]+)s, ec\. ([0-9\.]+)s/)
   {
      unless ($group) { $group = "$1,($2)"; }
      else { $group = "$group,$1,($2)"; }
      print "GROUP: ";
   }

   #while (/(([WRG]\.[ ]?)?(([0-9]{3}°([0-9]{2}′)?)|obsc\.)?-([0-9]{3}°([0-9]{2}′)?))(.)(.*)/)
   if ($name)
   {
   while (/(([WRG]\.|[A-Za-z]+)?[ ]?(([0-9]{3}°([0-9]{2}′)?)|[A-Za-z\.]*)?-([0-9]{3}°([0-9]{2}′)?))(.)(.*)/)
   {
      unless ($sector) { $sector = $1; }
      else { $sector = "$sector,$1"; }

      if ($8 eq ",")
      { 
         $su = $9;
         print "SECTOR cont'd "; 
      }
      else 
      { 
         undef $su;
         print "SECTOR END"; 
      }
      print "SECTOR: ($1) ($2) ($3) ($4) ($5) ($6) ($7) ($8) ($9) ";
      s/$1//;
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
      print "RACON: ";
   }

   print "$_\n";

   unshift(@lbuf, $_);
   pop(@lbuf);
}

