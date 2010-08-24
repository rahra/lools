#!/usr/bin/perl

$lcnt = 0;

while (<>)
{
   $lcnt++;
   chomp;
   s/'/\\'/g;
   @vals = split /\t/;

   $vals[15] =~ s/\.$//;
   if (length($vals[14]) == 0) { $vals[14] = 1; }
   if ($vals[27] eq "yes") { $vals[27] = 1; }
   else { $vals[27] = 0; }
   if ($vals[29] eq "yes") { $vals[29] = 1; }
   else { $vals[29] = 0; }
   if ($vals[30] eq "yes") { $vals[30] = 1; }
   else { $vals[30] = 0; }
   if ($vals[31] eq "yes") { $vals[31] = 1; }
   else { $vals[31] = 0; }
   if ($vals[32] eq "yes") { $vals[32] = 1; }
   else { $vals[32] = 0; }

   unless ($vals[22]) { $vals[22] = 0; }
   unless ($vals[23]) { $vals[23] = 0; }
   unless ($vals[24]) { $vals[24] = 0; }

   # comment out first line which contains headers
   if ($lcnt == 1) { print "-- "; }

   print "INSERT INTO lights VALUES ('$vals[2]','$vals[3]','$vals[4]','$vals[6]','$vals[7]','$vals[8]',$vals[11],$vals[12],'$vals[13]','$vals[15]','$vals[16]','$vals[17]','$vals[19]',$vals[14],$vals[22],$vals[23],'$vals[20]','$vals[25]','$vals[26]',$vals[27],$vals[29],$vals[30],$vals[31],$vals[32],'$vals[28]','$vals[33]');\n";

   # 18 ... colour
   # 21 ... sector
   #$vals[21] = s/\s//g;
   undef $loop;
   while ($vals[21] =~ /(W|R|G|Y|Bu|Or|Vi)\.[ ]?(([0-9]{3,3})°)?\-(([0-9]{3,3})°)/g)
   {
      $col = $1;
      if ($3) { $start = $3; }
      else { $start = $end; }
      $end = $5;
      print "   INSERT INTO sectors VALUES ('$vals[2]','$vals[3]','$vals[4]',NULL,$start,$end,'$col');\n";
      $loop = 1;
   }

   while (!$loop && ($vals[18] =~ /(W|R|G|Y|Bu|Or|Vi)\./g))
   {
      print "   INSERT INTO sectors VALUES ('$vals[2]','$vals[3]','$vals[4]',NULL,NULL,NULL,'$1');\n";
   }
}

