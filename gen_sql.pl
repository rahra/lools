#!/usr/bin/perl


while (<>)
{
   @vals = split /\t/;

   unless ($vals[4]) { $vals[4] = 0; }

   print "INSERT INTO lights VALUES ('$vals[2]',$vals[3],$vals[4],'$vals[6]','$vals[7]','$vals[8]',$vals[11],$vals[12]);\n";

}

