#!/usr/bin/perl

use strict;
use DBI;

my $dsn = "DBI:mysql:database=list_of_lights;host=localhost;port=3306";
my $dbh = DBI->connect($dsn, "root", "060378hasen", {RaiseError => 1});

my $pub_nr = `cat NR`;
$pub_nr =~ s/[^0-9]//g;
print STDERR "Generating OSM for Pub. $pub_nr\n";
my $where = "WHERE usl_list='$pub_nr'" if $pub_nr;
my $sth = $dbh->prepare("SELECT * FROM lights $where");
$sth->execute();

print "<?xml version='1.0' encoding='UTF-8'?>\n\n<!--\n";
my $date = `date`;
chomp $date;
print "OSM file generated at $date.\nUse at your own risk.\n";
#print "SVN revisions:\n";
#system 'svn --verbose ls';
print "-->\n\n<osm version='0.6' generator='lol_gen_osm'>\n";

my $id = 0;
while (my $ref = $sth->fetchrow_hashref())
{
   if ($ref->{'error'} =~ /position/)
   {
      print STDERR "skipping $ref->{'int_chr'} $ref->{'int_nr'}";
      print STDERR ".$ref->{'int_subnr'}" if $ref->{'int_subnr'};
      print STDERR " due to position error.\n";
      next;
   }

   if ($ref->{'name'} =~ /RACON\.$/)
   {
      if ($ref->{'character_full'} =~ /^[A-Z0-9]{1,2}\(.*?\)$/)
      {
         print STDERR "skipping $ref->{'int_chr'} $ref->{'int_nr'}";
         print STDERR ".$ref->{'int_subnr'}" if $ref->{'int_subnr'};
         print STDERR ", RACON.\n";
         next;
      }
   }

   $id--;
   print "   <node id='$id' action='modify' visible='true' lat='$ref->{'lat'}' lon='$ref->{'lon'}'>\n";

   # FIXME: where to put the name of a light?
   $ref->{'name'} =~ s/'/&apos;/g;
   $ref->{'name'} =~ s/<.*?>//g;
   print "      <tag k='name' v='$ref->{'name'}' />\n";
#   $ref->{'name_comb'} =~ s/'/&apos;/g;
#   print "      <tag k='loc_name' v='$ref->{'name'}' />\n";

   $ref->{'int_chr'} = "USNGA" if $ref->{'int_chr'} eq 'u';
   my $intnr;
   if ($ref->{'int_subnr'}) { $intnr = "$ref->{'int_chr'} $ref->{'int_nr'}.$ref->{'int_subnr'}"; }
   else { $intnr = "$ref->{'int_chr'} $ref->{'int_nr'}"; }

   print "      <tag k='ref' v='$intnr' />\n";
   print "      <tag k='source' v='$ref->{'source'}' />\n";
   print "      <tag k='seamark:light:ref' v='$intnr' />\n";

   $ref->{'character'} =~ s/\.//g;
   print "      <tag k='seamark:light:character' v='$ref->{'character'}' />\n";

   if ($ref->{'group'} ne "1")
   {
      print "      <tag k='seamark:light:group' v='$ref->{'group'}' />\n";
   }
   if ($ref->{'period'} > 0)
   {
      print "      <tag k='seamark:light:period' v='$ref->{'period'}' />\n";
   }
   if ($ref->{'height_m'} > 0)
   {
      print "      <tag k='seamark:light:height' v='$ref->{'height_m'}' />\n";
   }
   if ($ref->{'mult_light'} > 1)
   {
      print "      <tag k='seamark:light:multiple' v='$ref->{'mult_light'}' />\n";
   }
   if ($ref->{'pos'})
   {
      print "      <tag k='seamark:light:category' v='$ref->{'pos'}' />\n";
   }
   if ($ref->{'sequence'})
   {
      print "      <tag k='seamark:light:sequence' v='$ref->{'sequence'}' />\n";
   }


   my $sti = $dbh->prepare("SELECT * FROM sectors WHERE usl_list='$ref->{'usl_list'}' AND usl_nr='$ref->{'usl_nr'}' AND usl_subnr='$ref->{'usl_subnr'}'");
   $sti->execute();
   my $rcnt = $sti->rows;
   my $sector_nr;
   while (my $reg = $sti->fetchrow_hashref())
   {
      if (($rcnt == 1) && !$reg->{'start'}) { $sector_nr = ""; }
      else { $sector_nr = ":" . $reg->{'sector_nr'}; }

      if ($reg->{'range'})
      {
         print "         <tag k='seamark:light$sector_nr:range' v='$reg->{'range'}' />\n";
      }
      if ($reg->{'start'})
      {
         print "         <tag k='seamark:light$sector_nr:sector_start' v='$reg->{'start'}' />\n";
      }
      if ($reg->{'end'})
      {
         print "         <tag k='seamark:light$sector_nr:sector_end' v='$reg->{'end'}' />\n";
      }
      if ($reg->{'visibility'} eq 'int')
      {
         print "         <tag k='seamark:light$sector_nr:visibility' v='intensified' />\n";
      }
      if ($reg->{'visibility'} eq 'unint')
      {
         print "         <tag k='seamark:light$sector_nr:visibility' v='unintensified' />\n";
      }

      my $col;
      if ($reg->{'colour'} eq "W") { $col = "white"; }
      elsif ($reg->{'colour'} eq "R") { $col = "red"; }
      elsif ($reg->{'colour'} eq "G") { $col = "green"; }
      elsif ($reg->{'colour'} eq "Y") { $col = "yellow"; }
      elsif ($reg->{'colour'} eq "Or") { $col = "orange"; }
      elsif ($reg->{'colour'} eq "Bu") { $col = "blue"; }
      elsif ($reg->{'colour'} eq "Vi") { $col = "violet"; }

      print "         <tag k='seamark:light$sector_nr:colour' v='$col' />\n";
 
   }
   $sti->finish();


   if (($ref->{'typea'} eq 'buoy') || ($ref->{'typea'} eq 'beacon'))
   {
      #$ref->{'type'} = 'lateral' unless $ref->{'type'};
      $ref->{'type'} =~ s/:(.*)//;
      my $stype = "$ref->{'typea'}_$ref->{'type'}";
      print "      <tag k='seamark:type' v='$stype' />\n";
      print "         <tag k='seamark:$stype:category' v='$1' />\n" if $1;
      # FIXME: buoyage system should have a defined tag.
      print "         <tag k='seamark:$stype:marsys' v='$ref->{'bsystem'}' />\n" if $ref->{'bsystem'};
      print "      <tag k='seamark:$stype:shape' v='$ref->{'shape'}' />\n" if $ref->{'shape'};

      if ($ref->{'shapecol'})
      {
         print "      <tag k='seamark:$stype:colour' v='$ref->{'shapecol'}' />\n";

         # test if a shape has more than 1 color
         my $cc = $ref->{'shapecol'};
         $cc =~ s/[^;]//g;
         if (length $cc > 0)
         {
            if ($ref->{'type'} =~ /cardinal|preferred|isolated/)
            {
               print "      <tag k='seamark:$stype:colour_pattern' v='horizontal_stripes' />\n";
            }
            elsif ($ref->{'type'} =~ /safe_water/)
            {
               print "      <tag k='seamark:$stype:colour_pattern' v='vertical_stripes' />\n";
            }
         }
      }
   }
   else
   {
      print "      <tag k='seamark:type' v='light_$ref->{'typea'}' />\n";
   }

   # FIXME: is this topmark definition correct?
   if ($ref->{'topmark'})
   {
      if ($ref->{'topmark'} eq 'yes') { print "      <tag k='seamark:topmark' v='yes' />\n"; }
      else { print "      <tag k='seamark:topmark:shape' v='$ref->{'topmark'}' />\n"; }
   }

   print "      <tag k='seamark:radar_reflector' v='yes' />\n" if $ref->{'radar_reflector'};

   print "      <tag k='seamark:fog_signal:category' v='$ref->{'fsignal'}' />\n" if $ref->{'fsignal'};

   print "   </node>\n";
}
$sth->finish();

print "</osm>\n";

$dbh->disconnect();


