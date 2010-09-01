#!/usr/bin/perl

while (<>)
{
   if (/<br>(.+)/)
   {
      chomp;
      s/<br>/<br>\n/g;
      print;
      next;
   }
   print;
}

