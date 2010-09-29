#!/usr/bin/perl


use strict;
use Switch;

use constant MAX_SEC_DEPTH => 3;

# enable debug output (1)
use constant DPRINT => 1;


my $NBSP = '&nbsp;';

my $lineno = 0;
my $lightcnt = 0;
my $lightno = 0;
my $namebreak = 0;
my $structbreak = 0;

my $next_line = 0;
my $prev_line = 0;

my $colors = "W|R|G|Y|Bu|Or|Vi";
my %direction = ('N' => 'north', 'E' => 'east', 'S' => 'south', 'W' => 'west');

my @section = ();
my @prev_section = ();
my %light = ();
my %prev_light = ();

# buffer containing lines of file
my @fbuf = ();
# buffer containing lights
my @lbuf = ();


sub pprogress
{
   $| = 1;
   print shift;
}


sub dprint
{
   print shift if DPRINT;
}


sub output_light
{
   my $l = shift;
   if (!$l->{'intnr'} && !$l->{'uslnr'})
   {
      print "LINENO\tSECTION\tINTNR\tUSLNR\tCATEGORY\tNAME\tN_INC\tFRONT\tLAT\tLON\tLATD\tLOND\tCHARACTER\tMULTIPLCTY\tMULT_POS\tPERIOD\tSEQUENCE\tHEIGHT_FT\tHEIGHT_M\tRANGE\tSTRUCT\tREMARK\tSECTOR\tRACON\tALT_LIGHT\tTYPE\tTOPMARK\n";
      return;
   }

   print "$l->{'lineno'}\t$l->{'section'}\t$l->{'intnr'}\t$l->{'uslnr'}\t$l->{'cat'}\t$l->{'name'}\t$l->{'n_inc'}\t$l->{'front'}\t$l->{'lat'}\t$l->{'lon'}\t$l->{'latd'}\t$l->{'lond'}\t$l->{'char'}\t$l->{'multi'}\t$l->{'mpos'}\t$l->{'period'}\t$l->{'sequence'}\t$l->{'height_ft'}\t$l->{'height_m'}\t$l->{'range'}\t\"$l->{'struct'}\"\t\"$l->{'rem'}\"\t$l->{'sector'}\t$l->{'racon'}\t$l->{'altlight'}\t$l->{'type'}\t$l->{'topmark'}\n";
}


dprint "PASS 1: ";
my $no_detect = 0;

while (<STDIN>)
{
   chomp;

   $fbuf[$lineno] = "" unless $no_detect;
   $no_detect = 0;
   $lineno++;
   $fbuf[$lineno] = $_;

   # progress output
   pprogress "." unless $lineno % 100;

   print "$lineno: ($next_line,$prev_line,$structbreak) $_\n";

   if ($next_line)
   {
      my $nxt = 0;
      switch ($next_line)
      {
         case 'NL_NAT'
         {
            $next_line = 0;

            if (/(([0-9]{1,3})°$NBSP([0-9]{2,2}\.[0-9])´$NBSP([NS]))$NBSP(<b>([^<]*)<\/b>)(\([^\)]*\))?<br>/)
            {
               $light{'lat'} = $1;
               $light{'latd'} = $2 + $3 / 60.0;
               if ($4 eq "S") { $light{'latd'} = -$light{'latd'}; }
               $light{'char'} = $6;
               if ($7) { $light{'mpos'} = $7; }
               $nxt = 1;
            }
            elsif (/(0°($NBSP)00.0´)<br>/)
            {
               $light{'lat'} = $1;
               $light{'latd'} = 0.0;
               $next_line = 'NL_CHAR';
               $nxt = 1;
            }
        }
         case 'NL_CHAR'
         {
            $next_line = 0;
            if (/<b>([^<]*)<\/b>(\([^\)]*\))?<br>/)
            {
               $light{'char'} = $1;
               #if ($2) { $light{'mpos'} = $2; }
               $light{'mpos'} = $2 if $2;
               $nxt = 1;
            }
         }
         case 'NL_NAME'
         {
            $next_line = 0;

            if (/(([0-9]{1,3})°$NBSP([0-9]{2,2}\.[0-9])´$NBSP([EW]))<br>/)
            {
               $light{'lon'} = $1;
               $light{'lond'} = $2 + $3 / 60.0;
               if ($4 eq "W") { $light{'lond'} = -$light{'lond'}; }
            }
            else
            {
               m/([^<]*?(\.)?)<br>$/;
               $light{'name'} .= $1;
               $namebreak = 0 if $2;
            }
            $nxt = 1;
         }
         else
         {
            print STDERR "*** unknown \$next_line = $next_line\n";
            $next_line = 0;
         }
      } # switch ($next_line)

      if ($nxt) 
      { 
         next; 
      }
   }

   # detect page break
   if (/^<hr>$/)
   {
      $light{'linecnt'} = $lineno - $light{'lineno'} - 1;
      next;
   }

   if (/^(([0-9]+)(\.[0-9]+)?)$NBSP(\-?(<(.)>|([A-Z])|-)([^<]*?)(\.)?(<\/.>)?(.*?)(\.)?)<br>$/)
   {
      print "MATCH ";
      if ($7 && ($light{'uslnr'} > $1))
      {
#         print "ILL ($6): $_\n";
      }
      else
      {
         # progress output
         pprogress "+";

         $lightcnt++;
         $light{'linecnt'} = $lineno - $light{'lineno'} unless $light{'linecnt'};
         for (my $i = 0; $i < MAX_SEC_DEPTH; $i++) { $light{'section'} .= $prev_section[$i]; }
         @prev_section = @section;
         # output light
         #output_light \%light;
         push @lbuf, {%light};

         # reset variables after output
         $lightno++;
         $namebreak = 0;
         $structbreak = 0;
         $next_line = 0;

         %prev_light = %light;
         %light = ();

         # check if name is line-breaked
         if (!$12 && $11) { $namebreak = 1; }
         $light{'uslnr'} = $1;
         $light{'lineno'} = $lineno;
         $light{'cat'} = $6;
         $light{'name'} = $4;
         $light{'name'} =~ s/<[\/]?[bi]>//g;
         #if ($light{'name'} =~ /^[\- ]*Rear/) { $light{'front'} = $prev_light{'intnr'}; }
         if ($light{'name'} =~ /Rear/) { $light{'front'} = $prev_light{'intnr'}; }
         $next_line = 'NL_NAT';
         next;
      }
   }

   if (!$light{'intnr'} && /^<i>([A-Z] ($NBSP)?[0-9]{4}(\.[0-9]+)?)<\/i>/)
   {
      $light{'intnr'} = $1;
      $next_line = 'NL_NAME' if $namebreak;
      next;
   }

   if (/(([\-]*)?[^:]*):<br>$/)
   {
      $section[length $2] = $1;
      for (my $i = 1 + length $2; $i < MAX_SEC_DEPTH; $i++) { undef $section[$i]; }
      next;
   }

   if (!$light{'lon'} && /^(([0-9]{1,3})°$NBSP([0-9]{2,2}\.[0-9])´$NBSP([EW]))<br>/)
   {
      $light{'lon'} = $1;
      $light{'lond'} = $2 + $3 / 60.0;
      if ($4 eq "W") { $light{'lond'} = -$light{'lond'}; }
      next;
   }

   $no_detect = 1;
}

sub cap_test
{
   my $d = shift;
   $d =~ s/$NBSP//g;
   if ($d =~ /^[A-Z\(\)\s]+$/) { return 1; }
   return 0;
}

dprint "\n$lightcnt lights detected.\n";
dprint "\nPASS 2: ";

for my $lgt (@lbuf)
{
   print "/********************/\n";

   $structbreak = 0;
   $next_line = 0;
   $prev_line = 0;

   for (my $i = $lgt->{'lineno'}; $i < $lgt->{'lineno'} + $lgt->{'linecnt'}; $i++)
   {
      next unless $fbuf[$i];
      print "$i: ($next_line,$prev_line,$structbreak) $fbuf[$i]\n";


      if ($lgt->{'racon'})
      {
         $lgt->{'racon'} .= $fbuf[$i];
         $fbuf[$i] = "";
         next;
      }

      if ($lgt->{'altlight'})
      {
         $lgt->{'altlight'} .= $fbuf[$i];
         $fbuf[$i] = "";
         next;
      }
 
         if ($fbuf[$i] =~ /RACON/)
         {
            $lgt->{'racon'} = $fbuf[$i];
            $fbuf[$i] = "";
            $prev_line = 'PL_RACON';
            next;
         }

         # detect second light
         # FIXME: pattern does not work
         if ($fbuf[$i] =~ /^<b>((Dir\.)?(F|L\.Fl|Al\.Fl|Fl|Iso|Oc|V\.Q|I\.Q|U\.Q|Q|Mo)\.[^<]*)<\/b><br>/)
         {
            unless ($lgt->{'char'}) 
            { 
               $lgt->{'char'} = $1; 
               $prev_line = 'PL_CHAR';
            }
            else 
            { 
               $lgt->{'altlight'} = $1; 
               $prev_line = 'PL_ALTLGT';
            }
            $fbuf[$i] = "";
            next;
         }

         if ($next_line)
         {
            switch ($next_line)
            {
               case 'NL_RNGPRT_STRUCT'
               {
                  $next_line = 0;
                  $fbuf[$i] =~ /^([0-9]+)(.*?(\.)?)<br>/;
                  $lgt->{'range'} .= $1;
                  $lgt->{'struct'} .= $2;
                  if ($3) { $structbreak = 0; }
                  else { $structbreak = 1; }
                  $prev_line = 'PL_RNGPRT_STRUCT';
               }
               case 'NL_STRUCT'
               {
                  $next_line = 0;
                  # this line might be a color range
                  if ($fbuf[$i] =~ /^(($colors)\.)<br>/)
                  {
                     $lgt->{'range'} .= ',' if $lgt->{'range'};
                     $lgt->{'range'} .= $1;
                     $prev_line = 'PL_RANGE_PART';
                     $next_line = 'NL_RNGPRT_STRUCT';
                  }
                  elsif ($fbuf[$i] =~ /^($colors)\.($NBSP| )(<b>)?([0-9]+)(<\/b>)?<br>/)
                  {
                     $lgt->{'range'} .= "," if $lgt->{'range'};
                     $lgt->{'range'} .= "$1. $4";
                     $prev_line = 'PL_RANGE';
                  }
                  else
                  {
                     $fbuf[$i] =~ /^(.*?(\.)?)<br>$/;
                     $lgt->{'struct'} .= " " . $1;
                     $structbreak = 0 if $2;
                     $prev_line = 'PL_STRUCT';
                  }
               }
               case 'NL_CRNG'
               {
                  $next_line = 0;
                  if ($fbuf[$i] =~ /^([0-9]+)<br>/)
                  {
                     $lgt->{'range'} .= $1;
                     $prev_line = 'PL_CRNG';
                  }
                  elsif ($fbuf[$i] =~ /^([0-9]+)($NBSP| )(.*?(\.)?)<br>/)
                  {
                     $lgt->{'range'} .= $1;
                     $lgt->{'struct'} .= $3;
                     if ($4) { $structbreak = 0; }
                     else { $structbreak = 1; }
                     $prev_line = 'PL_STRUCT';
                  }
               }
            }
            $fbuf[$i] = "";
            next;
         }

         unless ($lgt->{'height_ft'})
         {
            if ($fbuf[$i] =~ /^([0-9]+)<br>$/)
            {
               $lgt->{'height_ft'} = $1;
               $fbuf[$i] = "";
               $prev_line = 'PL_HEIGHT_FT';
               next;
            }
# I commented this out again. Unfortunately I cannot remember
# what exactly the reason for this was.
#            else
#            {
#               $lgt->{'height_ft'} = "N/A";
#            }
         }

         if ($fbuf[$i] =~ /^(([0-9]{1,3})°$NBSP([0-9]{2,2}\.[0-9])´$NBSP([NS]))<br>/)
         {
            unless ($lgt->{'lat'})
            {
               $lgt->{'lat'} = $1;
               $lgt->{'latd'} = $2 + $3 / 60.0;
               if ($4 eq "S") { $lgt->{'latd'} = -$lgt->{'latd'}; }
               $fbuf[$i] = "";
               $prev_line = 'PL_LAT';
               next;
            }
         }

         if ($fbuf[$i] =~ /(0°($NBSP)00.0´)<br>/)
         {
            unless ($lgt->{'lat'})
            {
               $lgt->{'lat'} = $1;
               $lgt->{'latd'} = 0.0;
               $fbuf[$i] = "";
               $prev_line = 'PL_LAT';
               next;
            }
            unless ($lgt->{'lon'})
            {
               $lgt->{'lon'} = $1;
               $lgt->{'lond'} = 0.0;
               $fbuf[$i] = "";
               $prev_line = 'PL_LON';
               next;
            }
         }

         if ($fbuf[$i] =~ /^(($colors)\.$NBSP)?(<b>)?([0-9]+)$NBSP(<\/b>)?([^<]*?(\.)?)<br>/)
         {
            #$lgt->{'range'} .= ',' if $lgt->{'range'};
            if ($lgt->{'range'})
            {
               unless (substr($lgt->{'range'}, length $lgt->{'range'} - 1, 1) eq ".")
               {
                  $lgt->{'range'} .= ',';
               }
            }
            $lgt->{'range'} .= $1 . $4;
            $lgt->{'struct'} .= ' ' if $lgt->{'struct'};
            $lgt->{'struct'} .= $6;
            $structbreak = 1 unless $7;
            $prev_line = 'PL_STRUCT';

            if ($lgt->{'struct'} =~ /^(.*?[^A-Z]\.)(.*)$/)
            {
               $lgt->{'struct'} = $1;
               $lgt->{'rem'} = $2;
            }

            if (cap_test $lgt->{'struct'})
            {
               $structbreak = 1;
            }
            elsif ($lgt->{'struct'} =~ /^(.*?(\.)?)$NBSP$NBSP(.+)$/)
            {
               $lgt->{'struct'} = $1;
               $lgt->{'rem'} = $3;
               $structbreak = 1 unless $2;
            }
            $fbuf[$i] = "";
            next;
         }

         if ($fbuf[$i] =~ /^period ([0-9]+(\.[0-9])?)s<br>/)
         {
            $lgt->{'period'} = $1;
            $fbuf[$i] = "";
            $prev_line = 'PL_PERIOD';
            next;
         }

         if ($fbuf[$i] =~ /^(fl|lt)\.($NBSP| )([0-9]+(\.[0-9])?)s, ec\. ([0-9]+(\.[0-9])?)s/)
         {
            $lgt->{'sequence'} .= "," if $lgt->{'sequence'};
            $lgt->{'sequence'} .= "$3+($5)";
            $fbuf[$i] = "";
            $prev_line = 'PL_SEQ';
            next;
         }

         if ($fbuf[$i] =~ /^($colors)\.<br>/)
         {
            $lgt->{'range'} .= "," if $lgt->{'range'};
            $lgt->{'range'} .= "$1. ";
            $fbuf[$i] = "";
            $next_line = 'NL_CRNG';
            $prev_line = 'PL_RNG';
            next;
         }

         if ($fbuf[$i] =~ /^($colors)\.($NBSP| )(<b>)?([0-9]+)(<\/b>)?<br>/)
         {
            $lgt->{'range'} .= "," if $lgt->{'range'};
            $lgt->{'range'} .= "$1. $4";
            $fbuf[$i] = "";
            $prev_line = 'PL_RNG';
            next;
 
         }
         
         unless ($lgt->{'struct'})
         {
            if ($fbuf[$i] =~ /^([^<0-9][^<]*?(\.)?)<br>/)
            {
               $lgt->{'struct'} = $1;
               $structbreak = 1 unless $2;
               $fbuf[$i] = "";
               $prev_line = 'PL_STRUCT';
               next;
            }
         }

         unless ($lgt->{'height_m'})
         {
            if ($fbuf[$i] =~ /^<b>([0-9]+)<\/b><br>/)
            {
               $lgt->{'height_m'} = $1;
               $fbuf[$i] = "";
               $next_line = 'NL_STRUCT' if $structbreak;
               $prev_line = 'PL_HEIGHT_M';
               next;
            }
         }


         if ($prev_line eq 'PL_STRUCT')
         {
            $lgt->{'rem'} .= $fbuf[$i];
            $fbuf[$i] = "";
            $prev_line = 'PL_REM';
            next;
         }

         if ($structbreak)
         {
            $fbuf[$i] =~ /^(.*?(\.)?)<br>/;
            $lgt->{'struct'} .= " $1";
            $structbreak = 0 if $2;
            $fbuf[$i] = "";
            $prev_line = 'PL_STRUCT';
            next;
         }
 
         $prev_line = 0;


   } # for ()

#   print "LIGHT:\t";
   output_light $lgt;
}

dprint "\nPASS 3: ";

for my $lgt (@lbuf)
{
   print "/********************/\n";

   $structbreak = 0;
   $next_line = 0;

   for (my $i = $lgt->{'lineno'}; $i < $lgt->{'lineno'} + $lgt->{'linecnt'}; $i++)
   {
      next unless $fbuf[$i];
      print "$i: $fbuf[$i]\n";

      $lgt->{'rem'} .= $fbuf[$i];
   }

   # check if light character contains muliplicity
   if ($lgt->{'char'} =~ /^([0-9]) /) { $lgt->{'multi'} = $1; }

   # look for incomplete names
   unless ($lgt->{'name'} =~ /\.$/) { $lgt->{'n_inc'} = 1; }

   # remove "<br>" from remarks
   $lgt->{'rem'} =~ s/<br>//g;
   $lgt->{'racon'} =~ s/<br>//g;

   # try to detect sectors
   my $sec = $lgt->{'rem'};
   $sec =~ s/$NBSP| //g;

   my $deg_pat = "([0-9]{3}°([0-9]{2}′)?)|shore|obsc\.";
   while ($sec =~ /((Visible|Intensified|Obscured|($colors)\.)(from|\(unint\.\)|\(int.\)|\(unintensified\))?($deg_pat)?\-?($deg_pat))/g)
   {
      $lgt->{'sector'} .= ',' if $lgt->{'sector'};
      $lgt->{'sector'} .= $1;
   }

   my $str = $lgt->{'struct'};
   $str =~ s/$NBSP| //g;
   if ($str =~ /([nesw])\.cardinal/i)
   {
      print "cardinal: $1\n";
      $lgt->{'type'} = 'cardinal:' . $direction{"$1"};
   }
   elsif ($str =~ /isolated/i) { $lgt->{'type'} = 'isolated_danger';}
   elsif ($str =~ /safewater/i) { $lgt->{'type'} = 'safe_water'; }

   if ($str =~ /topmark/i) { $lgt->{'topmark'} = 'yes'; }

   print "LIGHT:\t";
   output_light $lgt;

}

