#!/usr/bin/perl
#
#/* Copyright 2010,2011 Bernhard R. Fischer, 2048R/5C5FFD47 <bf@abenteuerland.at>
# *
# * This file is part of Lools (List of Light Tools).
# *
# * Lools is free software: you can redistribute it and/or modify
# * it under the terms of the GNU General Public License as published by
# * the Free Software Foundation, version 3 of the License.
# *
# * Lools is distributed in the hope that it will be useful,
# * but WITHOUT ANY WARRANTY; without even the implied warranty of
# * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# * GNU General Public License for more details.
# *
# * You should have received a copy of the GNU General Public License
# * along with Lools. If not, see <http://www.gnu.org/licenses/>.
# */
#
#
# (1) Convert the original PDF document to an HTML by using pdftohtml:
# `pdftohtml -f 33 -l 470 -noframes Pub113bk.pdf`
# -f and -l denote the first a last page of the document.
#
# (2) Linebreak properly by running
# `perl -pe 's/<br>(.*?)<br>/<br>\n\1<br>\n/g' < Pub113bk.html > Pub113bk_.html`
#
# (3) Extract light information by running
# `./conv_html_lol.pl < Pub113bk_.html > Pub113bk_.csv`
#
# (4) You might remove HTML special characters.
# `perl -pe 's/&.*?;//g' < Pub113bk_.csv > Pub113bk.csv`
# You may have a look at it now by importing it into a spread sheet
# with OpenOffice Calc, for example.
#
# (5) Convert into into SQL by running
# `./gen_sql.pl < Pub113bk.csv > Pub113bk.sql`
#
# (6) Import it into a database, e.g. mysql by running
# `mysql -p list_of_lights < Pub113bk.sql`
# Don't forget to create the tables before. The definition is found in
# "list_of_lights.sql".
# 
# (7) Generate OSM file out of database:
# `./gen_osm.pl > Pub113bk.osm`
#

use strict;
use Switch;

use constant MAX_SEC_DEPTH => 3;

# enable debug output (1)
my $DPRINT =  shift eq lc "debug" ? 1 : 0;

my $pub_nr;
my $source;

my @pgrsc = ("-", "/", "|", "\\");
my $pgrscnt = 0;

my $NBSP = '&nbsp;';
my $SPACES = "$NBSP| ";

my $lineno = 0;
my $lightcnt = 0;
my $lightno = 0;
my $namebreak = 0;
my $structbreak = 0;
my $charbreak = 0;

my $next_line = 0;
my $prev_line = 0;

my @keys = (
   'lineno', 'area', 'section', 'intnr', 'usl_list', 'uslnr', 'cat', 'dashes',
   'name', 'longname', 'indname', 'n_inc', 'front', 'rear', 'dirdist', 'dir',
   'lat', 'lon', 'latd', 'lond', 'char', 'altchar', 'multi', 'mpos', 'period',
   'sequence', 'height_ft', 'height_m', 'range', 'struct', 'rem', 'sector',
   'racon', 'racon_grp', 'racon_period', 'altlight', 'type', 'topmark',
   'typea', 'bsystem', 'shape', 'shapecol', 'rreflect',
   'fsignal', 'source', 'error', 'height_landm'
);

my $COLORS = "W|R|G|Y|Bu|Or|Vi";
my $shapecolors = "red|green|black|white|gr[ae]y|yel[l]?ow";
my $rem_keywords = "obsc|shore|visible|occasional|intensified|whistle|synchronized|private|siren|reflector";
my %direction = (
   'N' => { 'name' => 'north', 'bear' => 0 },
   'NNE' => { 'name' => 'north north east', 'bear' => 22.5 },
   'NE' => { 'name' => 'north east', 'bear' => 45 },
   'ENE' => { 'name' => 'east north east', 'bear' => 67.5 },
   'E' => { 'name' => 'east', 'bear' => 90 },
   'ESE' => { 'name' => 'east south east', 'bear' => 112.5 },
   'SE' => { 'name' => 'south east', 'bear' => 135 },
   'SSE' => { 'name' => 'south south east', 'bear' => 157.5 },
   'S' => { 'name' => 'south', 'bear' => 180 },
   'SSW' => { 'name' => 'south south west', 'bear' => 202.5 },
   'SW' => { 'name' => 'south west', 'bear' => 225 },
   'WSW' => { 'name' => 'west south west', 'bear' => 247.5 },
   'W' => { 'name' => 'west', 'bear' => 270 },
   'WNW' => { 'name' => 'west north west', 'bear' => 292.5 },
   'NW' => { 'name' => 'north west', 'bear' => 315 },
   'NNW' => { 'name' => 'north north west', 'bear' => 337.5 },
);

my %topmark = (
   'cardinal:north' => '2 cones up',
   'cardinal:east' => '2 cones base together',
   'cardinal:south' => '2 cones down', 
   'cardinal:west' => '2 cones point together',
   'safe_water' => 'sphere',
   'isolated_danger' => '2 spheres',
   'special_purpose' => 'x-shape',
   'lateral:port' => 'cylinder',
   'lateral:starboard' => 'cone, point up'
);

my @section = ();
my @prev_section = ();
my %light = ();

# buffer containing lines of file
my @fbuf = ();
# buffer containing lights
my @lbuf = ();


sub pgrs_char
{
   return if $DPRINT;
   print STDERR "\r$pgrsc[$pgrscnt]";
   $pgrscnt = ($pgrscnt + 1) % @pgrsc;
}


sub pprogress
{
   $| = 1;
   print STDERR shift;
}


sub dprint
{
   print STDERR shift if $DPRINT;
}


sub output_light
{
   my $l = shift;
   if (!$l->{'intnr'} && !$l->{'uslnr'})
   {
      for (my $i = 0; $i < @keys - 1; $i++)
      {
         print $keys[$i] . "\t";
      }
      print $keys[@keys - 1] . "\n";
      return;
   }

   for (my $i = 0; $i < @keys - 1; $i++)
   {
      print $l->{$keys[$i]} . "\t";
   }
   print $l->{$keys[@keys - 1]} . "\n";
}


sub test_name
{
   my $a = shift;

   $a =~ s/&[a-z]*?;/ /g;
   if ($a =~ /;/)
   {
      return 1;
   }

   return 0;
}


pprogress "----- PASS 1 -----\n";
my $no_detect = 0;
my $start = 0;
my $areaguess;
my $area;
#my $prev_area;

while (<STDIN>)
{
   chomp;

   $fbuf[$lineno] = "" unless $no_detect;
   $no_detect = 0;
   $lineno++;
   $fbuf[$lineno] = $_;

   # progress output
   pgrs_char unless $lineno % 10;
   pprogress "   [line = $lineno]" unless $lineno % 500;

   dprint "$lineno: ($next_line,$prev_line,$structbreak,$charbreak) $_\n";

   # find the beginning of the lights.
   if ($start < 2)
   {
      if (/"date" content="([^T]+)T/) { $source = $1; }
      if (/PUB\. ([0-9]+)/)
      {
         $pub_nr = $1;
         `echo NR=$pub_nr > NR`;
         $source = "US NGA Pub. $pub_nr. $source.";
         pprogress "$source\n";
      }

      if (/Section 1</)
      {
         $start++;
         pprogress "\nbeginning at line $lineno\n" if $start >= 2;
      }
      next;
   }

   if ($next_line)
   {
      my $nxt = 0;
      switch ($next_line)
      {
         case 'NL_NAT'
         {
            $next_line = 0;

            # detect latitude/character line.
            if (/(([0-9]{1,3})°$NBSP([0-9]{2,2}\.[0-9])´$NBSP([NS]))$NBSP(<b>([^<]*)<\/b>)(.*?)<br>/)
            {
               $prev_line = "LAT";
               NL_NAT:
               $light{'lat'} = $1;
               $light{'latd'} = $2 + $3 / 60.0;
               if ($4 eq "S") { $light{'latd'} = -$light{'latd'}; }
               $light{'char'} = $6;
               if ($7)
               {
                  my $q = $7;
                  # detect if there is an alternate character
                  if ($q =~ /($SPACES)or($SPACES)(<b>(.*?)<\/b>)(.*)/)
                  {
                     $light{'altchar'} = "$4 $5";
                     dprint "ALTCHAR: $light{'altchar'}\n";
                  }
                  else
                  {
                     $light{'mpos'} = $7;
                     unless ($light{'mpos'} =~ /\)$/)
                     {
                        $charbreak = 1;
                     }
                  }
               }
               $nxt = 1;
            }
            # same pattern as above but a little bit weaker
            # NOTE: pattern should be obsolete
            #elsif (/(([0-9]{1,3})°$NBSP([0-9]{2,2}\.[0-9])´$NBSP([NS]))$NBSP(<b>([^<]*))<br>/)
            #{
            #   $prev_line = "LAT_WEAK";
            #   goto NL_NAT;
            #}
            elsif (/(0°($NBSP)00.0´)<br>/)
            {
               $prev_line = "LAT0";
               $light{'lat'} = $1;
               $light{'latd'} = 0.0;
               $next_line = 'NL_CHAR';
               $nxt = 1;
            }
            else { dprint "NL_NAT wrong?\n"; }
        }
         case 'NL_CHAR'
         {
            $next_line = 0;
            if (/<b>([^<]*)<\/b>(\([^\)]*\))?<br>/)
            {
               $prev_line = "CHAR";
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
               $prev_line = "LON";
               $light{'lon'} = $1;
               $light{'lond'} = $2 + $3 / 60.0;
               if ($4 eq "W") { $light{'lond'} = -$light{'lond'}; }
            }
            else
            {
               if (/([^<]*?(\.)?)<br>$/)
               {
                  $prev_line = "NAME";
                  $light{'name'} .= ' ' if $light{'name'};
                  $light{'name'} .= $1;
                  $namebreak = 0 if $2;
               }
            }
            $nxt = 1;
         }
         else
         {
            $prev_line = 0;
            dprint "*** unknown \$next_line = $next_line\n";
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
      $prev_line = 0;
      $next_line = 0;
      $light{'linecnt'} = $lineno - $light{'lineno'} - 1;
      next;
   }

   # detect end of list of lights
   if (/<b>Radiobeacons<\/b>/)
   {
      $light{'linecnt'} = $lineno - $light{'lineno'} unless $light{'linecnt'};
      for (my $i = 0; $i < MAX_SEC_DEPTH; $i++) { $light{'section'} .= $prev_section[$i]; }
      $lightcnt++;
      push @lbuf, {%light};
      pprogress "\nend at $lineno\n";
      last;
   }

   # detect US NGA number
   if (/^(([0-9]+)(\.[0-9]+)?)$NBSP(\-?(<(.)>|([A-Z“])|-)([^<]*?)(\.)?(<\/.>)?(.*?)(\.)?)<br>$/)
   {
      my $c = $lineno - $light{'lineno'};
      # Stanzas should have at least a view lines. 3 is good value for at least
      # Pub113-2009.
      if ($c < 3)
      {
         $prev_line = 0;
         dprint "MATCHSHORT ($c) '$_'\n";
      }
      elsif ($7 && ($light{'uslnr'} > $1))
      {
         $prev_line = 0;
         dprint "MATCHILL ($c) '$_'\n";
      }
      elsif (test_name $_)
      {
         $prev_line = 0;
         dprint "MATCHILL2 ($c) '$_'\n";
      }
      else
      {
         dprint "MATCH ($c) '$_'\n";
         if ($prev_line eq "AREAGUESS")
         {
            $area = $areaguess;
            $fbuf[$lineno - 1] = "";
         }
         $prev_line = "USLNR";
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
         $charbreak = 0;
         $next_line = 0;

         %light = ();

         # check if name is line-breaked
         if (!$12 && $11) { $namebreak = 1; }
         $light{'uslnr'} = $1;
         $light{'lineno'} = $lineno;
         $light{'cat'} = $6;
         $light{'name'} = $4;
         $light{'name'} =~ s/<[\/]?[bi]>//g;
         if ($light{'name'} =~ /\brear\b/i)
         {
            $light{'front'} = $lbuf[@lbuf - 1]->{'intnr'};
            $lbuf[@lbuf - 1]->{'rear'} = $light{'uslnr'};
         }
         $light{'area'} = $area;
         $next_line = 'NL_NAT';
         next;
      }
   }

   # detect section
   if (/(([\-]*)?[^:]*):<br>$/)
   {
      if ($prev_line eq "AREAGUESS") 
      { 
         $area = $areaguess; 
         $fbuf[$lineno - 1] = "";
      }
      $prev_line = "SECTION";
      $section[length $2] = $1;
      for (my $i = 1 + length $2; $i < MAX_SEC_DEPTH; $i++) { undef $section[$i]; }
      next;
   }

   unless ($light{'linecnt'})
   {
      if (!$light{'intnr'} && /^<i>([A-Z0] ($NBSP)?[0-9]{3,4}(\.[0-9]+)?)<\/i>/)
      {
         $prev_line = "INTNR";
         $light{'intnr'} = $1;
         $light{'intnr'} =~ s/$SPACES//g;
         $next_line = 'NL_NAME' if $namebreak;
         next;
      }

      if (!$light{'lon'} && /^(([0-9]{1,3})°$NBSP([0-9]{2,2}\.[0-9])´$NBSP([EW]))<br>/)
      {
         $prev_line = "LON";
         $light{'lon'} = $1;
         $light{'lond'} = $2 + $3 / 60.0;
         if ($4 eq "W") { $light{'lond'} = -$light{'lond'}; }
         next;
      }

      if ($charbreak)
      {
         if (/^([^(]*\))<br>/)
         {
            $prev_line = "MPOS";
            $charbreak = 0;
            $light{'mpos'} .= $1;
            next;
         }
      }
   }

   # try to detect area
   my $a = $_;
   if ($a =~ /^<b>((&nbsp;|[A-Z ()-])*)<\/b><br>$/)
   { 
      $areaguess = $1; 
      $prev_line = "AREAGUESS";
   }

   # if nothing was detected within this pass
   $no_detect = 1;
   $prev_line = 0 unless $prev_line eq "AREAGUESS";
}

sub cap_test
{
   my $d = shift;
   $d =~ s/$NBSP//g;
   if ($d =~ /^[A-Z\(\)\s]+$/) { return 1; }
   return 0;
}

pprogress "\n$lightcnt lights detected.\n";
pprogress "\n----- PASS 2 -----\n";

$lightcnt = 0;
my $i = 0;
for my $lgt (@lbuf)
{
   if ($lgt->{'intnr'}) { dprint "/***** $lgt->{'intnr'} ***************/\n"; }
   else { dprint "/***** u$lgt->{'uslnr'} ***************/\n"; }

   pgrs_char unless $lightcnt % 10;
   pprogress "   [light = $lightcnt]" unless $lightcnt % 20;
   $lightcnt++;

   $structbreak = 0;
   $next_line = 0;
   $prev_line = 0;

   dprint "$i: ($next_line,$prev_line,$structbreak) $fbuf[$i]\n";
   for ($i = $lgt->{'lineno'}; $i < $lgt->{'lineno'} + $lgt->{'linecnt'}; $i++)
   {
      next unless $fbuf[$i];
      dprint "$i: ($next_line,$prev_line,$structbreak) $fbuf[$i]\n";


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
 
      # sometimes the name contains RACON
      if ($fbuf[$i] =~ /^(.*?(.?)RACON\.)<br>$/)
      {
         if ($2 ne "-")
         {
            $lgt->{'name'} .= $1;
            $fbuf[$i] = "";
            $prev_line = 'PL_NAME';
            next;
         }
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
      if ($fbuf[$i] =~ /^<b>(([0-9] )?(Dir\.)?(F|L\.Fl|Al\.Fl|Fl|Iso|Oc|V\.Q|I\.Q|U\.Q|Q|Mo)\.[^<]*)<\/b><br>/)
      {
         unless ($lgt->{'char'}) 
         { 
            $lgt->{'char'} = $1; 
            $prev_line = 'PL_CHAR';
         }
         else 
         { 
            $lgt->{'altlight'} = $fbuf[$i];
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
               if ($fbuf[$i] =~ /^([0-9]+)(.*?(\.)?)<br>/)
               {
                  $lgt->{'range'} .= $1;
                  $lgt->{'struct'} .= $2;
                  if ($3) { $structbreak = 0; }
                  else { $structbreak = 1; }
                  $prev_line = 'PL_RNGPRT_STRUCT';
               }
               else
               {
                  $prev_line = 'PL_UNKNOWN';
               }
            }
            case 'NL_STRUCT'
            {
               $next_line = 0;
               # this line might be a color range
               if ($fbuf[$i] =~ /^(($COLORS)\.)<br>/)
               {
                  $lgt->{'range'} .= ',' if $lgt->{'range'};
                  $lgt->{'range'} .= $1;
                  $prev_line = 'PL_RANGE_PART';
                  $next_line = 'NL_RNGPRT_STRUCT';
               }
               elsif ($fbuf[$i] =~ /^($COLORS)\.($SPACES)(<b>)?([0-9]+)(<\/b>)?<br>/)
               {
                  $lgt->{'range'} .= "," if $lgt->{'range'};
                  $lgt->{'range'} .= "$1. $4";
                  $prev_line = 'PL_RANGE';
               }
               else
               {
                  if ($fbuf[$i] =~ /^(.*([^A-Z]))$NBSP$NBSP(.*)<br>/)
                  {
                     $lgt->{'struct'} .= ' ' if $lgt->{'struct'};
                     $lgt->{'struct'} .= $1;
                     $structbreak = $3 eq '.' ? 0 : 1;
                     $lgt->{'rem'} .= ' ' if $lgt->{'rem'};
                     $lgt->{'rem'} .= $3;
                     $prev_line = 'PL_REM';
                  }
                  elsif ($fbuf[$i] =~ /^(.*?(\.)?)<br>$/)
                  {
                     $lgt->{'struct'} .= " " . $1;
                     $structbreak = 0 if $2;
                     $prev_line = 'PL_STRUCT';
                  }
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
               elsif ($fbuf[$i] =~ /^([0-9]+)($SPACES)(.*?(\.)?)($NBSP$NBSP(.*))?<br>/)
               {
                  $lgt->{'range'} .= $1;
                  $lgt->{'struct'} .= ' ' if $lgt->{'struct'};
                  $lgt->{'struct'} .= $3;
                  $structbreak = $4 eq '.' ? 0 : 1;
                  if ($6)
                  {
                     $lgt->{'rem'} .= ' ' if $lgt->{'rem'};
                     $lgt->{'rem'} .= $6;
                     $prev_line = 'PL_REM';
                  }
                  else
                  {
                     $prev_line = 'PL_STRUCT';
                  }
               }
            }
         }
         $fbuf[$i] = "";
         next;
      } # if ($next_line)

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
#         else
#         {
#            $lgt->{'height_ft'} = "N/A";
#         }
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

      if ($fbuf[$i] =~ /^(($COLORS)\.$NBSP)?(<b>)?([0-9]+)$NBSP(<\/b>)?(.*?(\.)?)<br>/)
      {
         if ($lgt->{'struct'} && !$structbreak)
         {
            $lgt->{'rem'} .= ' ' if $lgt->{'rem'};
            $lgt->{'rem'} .= $fbuf[$i];
            $fbuf[$i] = "";
            $prev_line = 'PL_REM';
            next;
         }
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
            #$lgt->{'struct'} .= ' ' if $lgt->{'struct'};
            $lgt->{'struct'} = $1;
            $lgt->{'rem'} = $2;
         }

         if (cap_test $lgt->{'struct'})
         {
            $structbreak = 1;
         }
         elsif ($lgt->{'struct'} =~ /^(.*?(\.)?)$NBSP$NBSP(.+)$/)
         {
            #$lgt->{'struct'} .= ' ' if $lgt->{'struct'};
            $lgt->{'struct'} = $1;
            $lgt->{'rem'} = $3 . $lgt->{'rem'};
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

      if ($fbuf[$i] =~ /^(([0-9])($SPACES))?(($COLORS)\.($SPACES))?(fl|lt)\.($SPACES)([0-9]+(\.[0-9])?)s(,($SPACES)ec\.($SPACES)([0-9]+(\.[0-9])?)s)?/)
      {
         $lgt->{'sequence'} .= "," if $lgt->{'sequence'};
         if ($2 || $5)
         { 
            $lgt->{'sequence'} .= "[";
            $lgt->{'sequence'} .= $2 if $2;
            $lgt->{'sequence'} .= "$5." if $5;
            $lgt->{'sequence'} .= "]";
         }
         $lgt->{'sequence'} .= "$9";
         $lgt->{'sequence'} .= "+($14)" if $14;
         $fbuf[$i] = "";
         $prev_line = 'PL_SEQ';
         next;
      }

      if ($fbuf[$i] =~ /^($COLORS)\.<br>/)
      {
         $lgt->{'range'} .= "," if $lgt->{'range'};
         $lgt->{'range'} .= "$1. ";
         $fbuf[$i] = "";
         $next_line = 'NL_CRNG';
         $prev_line = 'PL_RNG';
         next;
      }

      if ($fbuf[$i] =~ /^($COLORS)\.($SPACES)(<b>)?([0-9]+)(<\/b>)?<br>/)
      {
         $lgt->{'range'} .= "," if $lgt->{'range'};
         $lgt->{'range'} .= "$1. $4";
         $fbuf[$i] = "";
         $prev_line = 'PL_RNG';
         next;
 
      }

      if ($fbuf[$i] =~ /((Helicopter platform\.($SPACES)?)<br>)/)
      {
         $lgt->{'struct'} .= $2;
         $fbuf[$i] =~ s/$1//;
         $prev_line = 'PL_STRUCT';
         next;
      }

      unless ($lgt->{'struct'})
      {
         if ($fbuf[$i] =~ /^([^<0-9][^<]*?(\.)?)<br>/)
         {
            my $struct = $1;
            my $break = $2;

            if ($struct =~ /^(.*?)($NBSP){2}(.*)$/)
            {
               #dprint "STR_SPLIT ($1 -- $3)\n";
               $lgt->{'struct'} = $1;
               $lgt->{'rem'} .= ' ' if $lgt->{'rem'};
               $lgt->{'rem'} .= $3;
               unless ($lgt->{'struct'} =~ /\.$/) { $structbreak = 1; }
               $prev_line = 'PL_STRUCT_REM';
            }
            # try to detect if this structure is a remark instead.
            elsif ($struct =~ /$rem_keywords/i)
            {
               $lgt->{'rem'} .= ' ' if $lgt->{'rem'};
               $lgt->{'rem'} .= $struct;
               $prev_line = 'PL_REM';
            }
            else
            {
               $lgt->{'struct'} = $struct;
               $structbreak = 1 unless $break;
               $prev_line = 'PL_STRUCT';
            }
            $fbuf[$i] = "";
            next;
         }
     }

     unless ($lgt->{'range'})
     {
         if ($fbuf[$i] =~ /^([0-9]+)($SPACES)([A-Z].*(\.))<br>/)
         {
            $lgt->{'range'} = $1;
            $lgt->{'struct'} .= ' ' if $lgt->{'struct'};
            $lgt->{'struct'} = $3;
            $structbreak = 1 unless $4;
            $fbuf[$i] = "";
            $prev_line = 'PL_STRUCT';
            next;
         }
         if ($fbuf[$i] =~ /^<b>([0-9]+)<\/b><br>/)
         {
            if (!$lgt->{'struct'} || !$lgt->{'rem'})
            {
               $lgt->{'range'} = $1;
               $fbuf[$i] = "";
               $prev_line = 'PL_RANGE1';
               next;
            }
         }
         if ($fbuf[$i] =~ /^([0-9]+)<br>$/)
         {
            $lgt->{'range'} = $1;
            $fbuf[$i] = "";
            $prev_line = 'PL_RANGE';
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
         if ($fbuf[$i] =~ /^(.*; [0-9]+\.)(&nbsp;.*)<br>/)
         {
            $lgt->{'struct'} .= " $1";
            $structbreak = 0;
            $lgt->{'rem'} .= ' ' if $lgt->{'rem'};
            $lgt->{'rem'} .= $2;
            $prev_line = 'PL_REM';
         $fbuf[$i] = "";
         next;
         }
         elsif ($fbuf[$i] =~ /^(.*?(\.)?)<br>/)
         {
            $lgt->{'struct'} .= " $1";
            $structbreak = 0 if $2;
            $prev_line = 'PL_STRUCT';
         $fbuf[$i] = "";
         next;
         }
      }
 
      $prev_line = 0;

   } # for ()
}

pprogress "\n$lightcnt lights processed.\n";

pprogress "\n----- PASS 3 -----\n";

# This pass refines attributes by either splitting them into further tags like
# radar reflectors, racons, and fog signals. It also tries to detect the type
# of seamark (buoy, beacon, vessel,...) and finds shapes and colors of their
# body.

$lightcnt = 0;

my %lightnr;
my %uslnr;
my $scolcnt = 0;

for my $lgt (@lbuf)
{
   if ($lgt->{'intnr'}) { dprint "/***** $lgt->{'intnr'} ***************/\n"; }
   else { dprint "/***** u$lgt->{'uslnr'} ***************/\n"; }

   pgrs_char unless $lightcnt % 10;
   pprogress "   [light = $lightcnt]" unless $lightcnt % 20;
   $lightcnt++;

   $structbreak = 0;
   $next_line = 0;

   for (my $i = $lgt->{'lineno'}; $i < $lgt->{'lineno'} + $lgt->{'linecnt'}; $i++)
   {
      next unless $fbuf[$i];
      dprint "$i: $fbuf[$i]\n";

      $fbuf[$i] =~ s/<br>//g;
      unless ($lgt->{'name'} =~ /\.$/)
      {
         $lgt->{'name'} .= $fbuf[$i];
      }
      else
      {
         $lgt->{'rem'} .= $fbuf[$i];
      }
      $fbuf[$i] = "";
   }

   # check if light character contains muliplicity
   if ($lgt->{'char'} =~ /^([0-9])/) { $lgt->{'multi'} = $1; }

   # look for incomplete names
   unless ($lgt->{'name'} =~ /\.$/)
   { 
      #$lgt->{'n_inc'} = 1; 
      $lgt->{'error'} .= ',' if $lgt->{'error'};
      $lgt->{'error'} .= 'name_incomplete';
   }

   # remove "<br>" from remarks
   $lgt->{'rem'} =~ s/<br>//g;

   if ($lgt->{'rem'})
   {
      my $rr = $lgt->{'rem'};
      $rr =~ s/<.*?>//g;
      unless ($rr =~ m/\.($SPACES)*$/)
      {
         $lgt->{'error'} .= ',' if $lgt->{'error'};
         $lgt->{'error'} .= 'rem_incomplete';
      }
   }

   # try to detect sectors
   my $sec = $lgt->{'rem'};
   $sec =~ s/$SPACES//g;

   # the pattern /(′|´|')/ is used instead of /[′|´|']/ because of
   # troubles with utf8 charachters
   my $deg_pat = "([0-9]{3}°([0-9]{2}(′|´|'))?)|shore|obsc\.";
   while ($sec =~ /((Visible|Intensified|Obscured|($COLORS)\.)?(from|\(unint\.\)|\(int\.\)|\(intensified\)|\(unintensified\))?($deg_pat)?\-?($deg_pat))/g)
   {
      $lgt->{'sector'} .= ',' if $lgt->{'sector'};
      $lgt->{'sector'} .= $1;
   }

   my $str = $lgt->{'struct'};
   $str =~ s/$SPACES//g;
   if ($str =~ /([nesw])\.cardinal/i)
   {
      dprint "cardinal: $1\n";
      $lgt->{'type'} = 'cardinal:' . $direction{"$1"}->{'name'};
   }
   elsif ($str =~ /isolated/i) { $lgt->{'type'} = 'isolated_danger';}
   elsif ($str =~ /safewater/i) { $lgt->{'type'} = 'safe_water'; }
   elsif ($str =~ /special/i) { $lgt->{'type'} = 'special_purpose'; }

   if ($str =~ /topmark/i) { $lgt->{'topmark'} = 'yes'; }

   # FIXME: not sure if the following is true.
   if ($lgt->{'cat'} eq 'i')
   {
      my $name = $lgt->{'name'};
      $name =~ s/$SPACES//g;

      if ($name =~ /LIGHTSHIP/)
      {
         $lgt->{'typea'} = 'vessel';
      }
      elsif ($name =~ /LIGHTFLOAT/)
      {
         $lgt->{'typea'} = 'float';
      }
      else
      {
         $lgt->{'typea'} = 'buoy';
      }
   }
   elsif ($lgt->{'cat'} eq 'b')
   {
      $lgt->{'typea'} = 'major';
   }

   if ($lgt->{'struct'} =~ /\bbeacon\b/)
   {
      $lgt->{'typea'} = 'beacon';
   }

#   else
#   {
#      $lgt->{'typea'} = 'beacon' if $lgt->{'type'};
#   }

   if ($lgt->{'struct'} =~ /\(([AB])\)/)
   {
      $lgt->{'bsystem'} = $1;
      my $str = $lgt->{'struct'};
      $str =~ s/$SPACES//g;
      if ($str =~ /\b(STARBOARD|PORT|GRG|RGR)\b/)
      {
         my $side = $1;
         $side = 'PREFERRED_CHANNEL_STARBOARD' if $side eq 'GRG';
         $side = 'PREFERRED_CHANNEL_PORT' if $side eq 'RGR';

         unless ($lgt->{'type'})
         {
            $lgt->{'type'} = 'lateral:' . lc $side;
         }
         else
         {
            $lgt->{'error'} .= ',' if $lgt->{'error'};
            $lgt->{'error'} .= 'e_lateral';
         }
      }
      else
      {
         $lgt->{'error'} .= ',' if $lgt->{'error'};
         $lgt->{'error'} .= 'lateral_unknown';
      }
   }

   if ($lgt->{'type'} && !$lgt->{'typea'})
   {
      $lgt->{'typea'} = 'beacon';
      $lgt->{'error'} .= ',' if $lgt->{'error'};
      $lgt->{'error'} .= 'beacon_guess';
   }

   # default to light_minor if no type could be detected
   if (!$lgt->{'typea'}) { $lgt->{'typea'} = 'minor'; }

   if (defined $topmark{$lgt->{'type'}} && ($lgt->{'topmark'} eq 'yes'))
   {
      $lgt->{'topmark'} = $topmark{$lgt->{'type'}};
   }

   if ($lgt->{'struct'} =~ /;($SPACES)([0-9]+)\./)
   {
      $lgt->{'height_landm'} = $2;
   }

   if ($lgt->{'height_m'} && $lgt->{'height_ft'})
   {
      if (($lgt->{'height_ft'} / $lgt->{'height_m'} < 3.0) || ($lgt->{'height_ft'} / $lgt->{'height_m'} > 3.6))
      {
         $lgt->{'error'} .= ',' if $lgt->{'error'};
         $lgt->{'error'} .= 'height';
      }
   }
   # try to guess if height_m was accidentally detected as range.
   elsif ($lgt->{'height_ft'} && !$lgt->{'height_m'})
   {
      if ($lgt->{'range'} =~ /^[0-9]+$/)
      {
         if (($lgt->{'height_ft'} / $lgt->{'range'} < 3.0) || ($lgt->{'height_ft'} / $lgt->{'range'} > 3.6))
         {
            $lgt->{'error'} .= ',' if $lgt->{'error'};
            $lgt->{'error'} .= 'height';
         }
         else
         {
            $lgt->{'height_m'} = $lgt->{'range'};
            undef $lgt->{'range'};
         }
      }
      else
      {
         $lgt->{'error'} .= ',' if $lgt->{'error'};
         $lgt->{'error'} .= 'height';
      }
   }
   elsif ($lgt->{'height_m'} || $lgt->{'height_ft'})
   {
      $lgt->{'error'} .= ',' if $lgt->{'error'};
      $lgt->{'error'} .= 'height';
   }

   if (($lgt->{'latd'} == 0.0) && ($lgt->{'lond'} == 0.0))
   {
      $lgt->{'error'} .= ',' if $lgt->{'error'};
      $lgt->{'error'} .= 'position';
   }

   # look for duplicate light international numbers
   if ($lgt->{'intnr'} && $lightnr{$lgt->{'intnr'}})
   {
         $lgt->{'error'} .= ',' if $lgt->{'error'};
         $lgt->{'error'} .= 'intdup';
         dprint "DUP\n";
   }
   else
   {
      $lightnr{$lgt->{'intnr'}} = 1;
   }

   # look for duplicate light US NGA numbers
   if ($uslnr{$lgt->{'uslnr'}})
   {
         $lgt->{'error'} .= ',' if $lgt->{'error'};
         $lgt->{'error'} .= 'usldup';
         dprint "DUP\n";
   }
   else
   {
      $uslnr{$lgt->{'uslnr'}} = 1;
   }

   my $str = $lgt->{'struct'};
   $str =~ s/$SPACES//g;
   if ($str =~ /(stake|withy|tower|lattice|pile|cairn|buoyant|column|post|pillar|conical|can|spherical|spar|barrel|super-boy)/)
   {
      $lgt->{'shape'} = $1;
   }

   if ($str =~/^($shapecolors)(and($shapecolors))?/i)
   {
      $scolcnt++;
      $lgt->{'shapecol'} = lc "$1;$3";
      $lgt->{'shapecol'} =~ s/yelow/yellow/g;
      $lgt->{'shapecol'} =~ s/grey/gray/g;
      $lgt->{'shapecol'} =~ s/;$//;
   }
   elsif ($lgt->{'struct'} =~ /\b(BYB|YBY|RGR|GRG|BRB|RW|BY|YB|G|R|Y)\b/)
   {
      $scolcnt++;
      $lgt->{'shapecol'} = $1;
      $lgt->{'shapecol'} =~ s/R/red;/g;
      $lgt->{'shapecol'} =~ s/G/green;/g;
      $lgt->{'shapecol'} =~ s/W/white;/g;
      $lgt->{'shapecol'} =~ s/Y/yellow;/g;
      $lgt->{'shapecol'} =~ s/B/black;/g;
      $lgt->{'shapecol'} =~ s/;$//;
   }

   # detect if a buoy or a beacon has no type (lateral, cardinal,...)
   # try to guess lateral seamark
   if (!$lgt->{'type'} && (($lgt->{'typea'} eq 'beacon') || ($lgt->{'typea'} eq 'buoy')))
   {
      if ($lgt->{'shapecol'} =~ /^red$/) { $lgt->{'type'} = 'lateral:port'; }
      elsif ($lgt->{'shapecol'} =~ /^green$/) { $lgt->{'type'} = 'lateral:starboard'; }
      elsif ($lgt->{'shapecol'} =~ /^yellow$/) { $lgt->{'type'} = 'special_purpose'; }
      elsif ($lgt->{'name'} =~ /approach/i) { $lgt->{'type'} = 'safe_water'; }
      else { $lgt->{'typea'} = 'minor'; }
   }

   $lgt->{'range'} =~ s/$SPACES//g;

   my $rem = $lgt->{'rem'};
   $rem =~ s/$NBSP/ /g;
   $rem =~ s/ [ ]+/ /g;
   if ($rem =~ /(whistle|horn|siren|diaphone|bell|explosive|gong)/i) { $lgt->{'fsignal'} = lc $1; }
   $lgt->{'rreflect'} = $rem =~ /radar reflector/i ? 1 : 0;

   if ($lgt->{'mpos'} =~ /^\((.*?)\.?\)$/) { $lgt->{'mpos'} = $1 if $1; }

   if ($lgt->{'altlight'} =~ /(RACON.*)/)
   {
      $lgt->{'racon'} = $1;
      $lgt->{'altlight'} =~ s/\Q$lgt->{'racon'}\E//;
   }

   # test if racon has ill character
   if ($lgt->{'name'} =~ /RACON\.$/)
   {
      unless ($lgt->{'char'} =~ /^[A-Z0-9]{1,2}\(.*?\)$/)
      {
         $lgt->{'error'} .= ',' if $lgt->{'error'};
         $lgt->{'error'} .= 'racon_char';
      }
   }

   # Clean name field.
   $lgt->{'name'} =~ s/$NBSP/ /g;
   $lgt->{'name'} =~ s/ [ ]+/ /g;

   # FIXME: this detection is not completely finished
   # detect front/rear detail
   #if ($lgt->{'name'} =~ /Rear,(.*?([0-9,.]+)($SPACES)(.*?))?([0-9]{3})°([0-9]+)?/)
   if ($lgt->{'front'})
   {
      dprint "REAR: \"$lgt->{'name'}\"\n";
      if ($lgt->{'name'} =~ m/([0-9.]{3,})°([0-9]*)/)
      {
         $lgt->{'dir'} = $1 + $2 / 60.0;
      }
      elsif ($lgt->{'name'} =~ m/\b([NESW]+)\b/)
      {
         dprint "REARMGK 1:$1\n";
         $lgt->{'dir'} = $direction{$1}->{'bear'};
      }

      if ($lgt->{'name'} =~ m/\b([0-9][0-9.,]*)\b([^°′'].*)/)
      {
         my $rd = $1;
         dprint "REARDIST 1:$1 2:$2\n";

         #unless ($2 =~ /^°/)
         {
            $lgt->{'dirdist'} = $rd;
            $lgt->{'dirdist'} =~ s/,//g;

            dprint "REARDISTSET $1,$lgt->{'dirdist'}\n";

            if ($lgt->{'name'} =~ /\bkm\b/)
            {
               $lgt->{'dirdist'} *= 1000;
            }
            elsif ($lgt->{'name'} =~ /\bkilom/)
            {
               $lgt->{'dirdist'} *= 1000;
            }
            elsif ($lgt->{'name'} =~ /\bmile/)
            {
               $lgt->{'dirdist'} *= 1852;
            }
         }
      }
   }

   if ($lgt->{'racon'})
   {
      $lgt->{'racon'} =~ s/<br>//g;
      $lgt->{'racon'} =~ s/$SPACES//g;
      if ($lgt->{'racon'} =~ m/<b>([A-Z]+)\(/)
      {
         $lgt->{'racon_grp'} = $1;
      }
      if ($lgt->{'racon'} =~ m/period([0-9]+)s/)
      {
         $lgt->{'racon_period'} = $1;
      }
   }
}

pprogress "\n$lightcnt lights processed.\n$scolcnt shape colors found.\n";

pprogress "\n----- PASS 4 -----\ncontinue reading HTML, parsing index.\n";

# This pass reads and parses the index into a separate data structure.

my $is_ind = 0;
my %ilgt;
my $uslcnt = 0;
my $intcnt = 0;
my $unmatch = 0;
my $linebuf;
my $otxt;

while (<STDIN>)
{
   $lineno++;
   pgrs_char unless $lineno % 100;
   pprogress "   [line = $lineno]" unless $lineno % 500;

   # Find beginning of index.
   if ($is_ind < 1)
   {
      if (/INDEX – LIGHTS/)
      {
         $is_ind = 1;
         $otxt = "                   lights $lineno";
         pprogress $otxt;
      }
      next;
   }

   # Find beginning of radio beacons (those are ignored yet).
   if ($is_ind < 2)
   {
      if (/RADIOBEACONS/)
      {
         $is_ind = 2;
         $otxt .= ", radio beacons $lineno";
         pprogress $otxt;
         next;
      }
   }

   # Find beginning of cross reference.
   if ($is_ind < 3)
   {
      if (m/CROSS REFERENCE/)
      {
         $is_ind = 3;
         $otxt .= ", cross ref $lineno";
         pprogress $otxt;
         next;
      }
   }

   chomp;
   s/&nbsp;/ /g;
   s/ [ ]+/ /g;

   if ($is_ind == 1)
   {
      if (/^([a-zA-Z][^.]*)[ .]*([0-9].*)</)
      {
         my $name = $1;
         my $uslnrc = $2;

         $name =~ s/ +$//g;

         ## filter section headings
         ## Bug in Lol?
         #if ($name =~ /^[A-Z ()-]+$/)
         #{
         #   print "skipping $uslnrc [$lineno]\n";
         #   next;
         #}

         $uslnrc =~ s/ //g;
         my @uslnr = split /,/, $uslnrc;
         if (@uslnr)
         {
            for (my $i = 0; $i < @uslnr; $i++)
            {
               # Detect and list duplicate USL#.
               my $uslnrd = $uslnr[$i];
               if ($ilgt{$uslnrd})
               {
                  $ilgt{$uslnrd}->{'dup'} = $uslnr[$i];
                  $ilgt{$uslnrd}->{'lineno'} .= "," . $lineno;

                  # If name is section name (upper case) then prepend it
                  # otherwise append it (the latter case may not always be
                  # correct.).
                  if ($name =~ /^[A-Z ()-]+$/)
                  {
                     $ilgt{$uslnrd}->{'name'} = $name . "," . $ilgt{$uslnrd}->{'name'};
                  }
                  else
                  {
                     $ilgt{$uslnrd}->{'name'} .= "," . $name;
                  }
               }
               else
               {
                  $ilgt{$uslnrd}->{'lineno'} = $lineno;
                  $ilgt{$uslnrd}->{'uslnr'} = $uslnr[$i];
                  $ilgt{$uslnrd}->{'name'} .= $name;
               }
               $uslcnt++;
            }
         }
         next;
      }

      next;
   }

   if ($is_ind == 3)
   {
      # if broken line is buffered try to reconnect it.
      if ($linebuf)
      {
         if (/^[0-9.]+<br/)
         {
            $_ = $linebuf . $_;
            $linebuf = "";
         }
      }

      # detect broken line and buffer it (this is rare).
      if (/(.*,) ?<br>/)
      {
         $linebuf = $1;
         next;
      }

      if (/^([A-Z0-9][0-9.]+[0-9]).*?([0-9][0-9., ]*)</)
      {
         my $intnr = $1;
         my @uslnr = split /,/, $2;

         for (my $i = 0; $i < @uslnr; $i++)
         {
            $uslnr[$i] =~ s/ //g;
            unless ($ilgt{$uslnr[$i]})
            {
               $ilgt{$uslnr[$i]}->{'uslnr'} = $uslnr[$i];
               $unmatch++;
            }
            if ($ilgt{$uslnr[$i]}->{'intnr'})
            {
               $ilgt{$uslnr[$i]}->{'dup'} .= "," if $ilgt{$uslnr[$i]}->{'dup'};
               $ilgt{$uslnr[$i]}->{'dup'} .= $intnr;
               $ilgt{$uslnr[$i]}->{'intnr'} .= "," . $intnr;
            }
            else
            {
               $ilgt{$uslnr[$i]}->{'intnr'} = $intnr;
            }

            $ilgt{$uslnr[$i]}->{'lineno'} .= "," if $ilgt{$2}->{'lineno'};
            $ilgt{$uslnr[$i]}->{'lineno'} .= $lineno;
         }
         $intcnt++;
         next;
      }

      next;
   }

}

pprogress "\nuslcnt = $uslcnt\nintcnt = $intcnt\nunmatch = $unmatch\n";

pprogress "\n----- PASS 5 -----\nPostprocessing of lights and index matching.\n";

# This run tries to compare the index of the LoL to the lights stanzas. It
# Further creates the full name of light by checking leading dashes.

$lightcnt = 0;
$unmatch = 0;

my @combname;
my $sec;

for my $lgt (@lbuf)
{
   $lightcnt++;
   pgrs_char unless $lightcnt % 10;
   pprogress "   [light = $lightcnt]" unless $lightcnt % 100;

   if ($lgt->{'section'} ne $sec)
   {
      undef @combname;
      $sec = $lgt->{'section'};
   }

   if ($lgt->{'name'} =~ m/^([ -]*)(.*)$/)
   {
      $lgt->{'name'} = $2;
      $lgt->{'dashes'} = $1;
      $lgt->{'dashes'} =~ s/[^-]//g;
      @combname[length $lgt->{'dashes'}] = $lgt->{'name'};
      for (my $i = 1 + length $lgt->{'dashes'}; $i < @combname; $i++)
      {
         undef $combname[$i];
      }
      unless ($combname[0])
      {
         $combname[0] = $lgt->{'section'} . '.';
      }
      for (my $i = 0; $i < @combname; $i++)
      {
         $lgt->{'longname'} .= ' ' if $i && $lgt->{'longname'};
         $lgt->{'longname'} .= $combname[$i];
      }
   }
   else
   {
      pprogress "NOMATCH\n";
   }

   # Test if there is an entry for a specific light in the index.
   unless ($ilgt{$lgt->{'uslnr'}})
   {
      # Append error 'noindex' if an entry is missing in the index.
      $lgt->{'error'} .= ',' if $lgt->{'error'};
      $lgt->{'error'} .= 'noindex';
      $unmatch++;
      next;
   }

   $lgt->{'indname'} = $ilgt{$lgt->{'uslnr'}}->{'name'};

   # If a light has an intt'l number test if it matches the entry in the index.
   if ($lgt->{'intnr'})
   {
      unless ($ilgt{$lgt->{'uslnr'}}->{'intnr'} =~ /\Q$lgt->{'intnr'}\E/)
      {
         # Append error 'illintmatch()' if light stanza contains different
         # intt'l number than the index.
         $lgt->{'error'} .= ',' if $lgt->{'error'};
         $lgt->{'error'} .= "illintmatch($ilgt{$lgt->{'uslnr'}}->{'intnr'})";
         $unmatch++;
      }
   }
   elsif ($ilgt{$lgt->{'uslnr'}}->{'intnr'})
   {
      # If light has no int'l number but the index has one, copy the number
      # from the index to the light and append the error 'intset' to the light.
      $lgt->{'intnr'} = $ilgt{$lgt->{'uslnr'}}->{'intnr'};
      $lgt->{'error'} .= ',' if $lgt->{'error'};
      $lgt->{'error'} .= 'intset';
      $unmatch++;
   }
}

pprogress "\n$lightcnt lights processed.\n$unmatch lights did not match.";

pprogress "\n\n----- PASS 6 -----\ngenerating output...\n";
$lightcnt = 0;

for my $lgt (@lbuf)
{
   $lightcnt++;
   pgrs_char unless $lightcnt % 10;
   pprogress "   [light = $lightcnt]" unless $lightcnt % 100;

   # Clean longname field.
   $lgt->{'longname'} =~ s/$NBSP/ /g;
   $lgt->{'longname'} =~ s/ [ ]+/ /g;
   $lgt->{'longname'} =~ s/^ +//g;
   $lgt->{'longname'} =~ s/ +$//g;

   # set source of information
   $lgt->{'source'} = $source;
   $lgt->{'usl_list'} = $pub_nr;

   print "LIGHT:\t";
   output_light $lgt;
}

pprogress "\n$lightcnt lights processed.\n";

