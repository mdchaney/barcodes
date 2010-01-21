#!/usr/bin/perl

use strict;

use Barcode::Plessey;

my $bc=new Barcode::Plessey('addcheck'=>1, 'barchar'=>'#', 'spacechar'=>' ');
for (my $i=10000 ; $i<20000 ; $i++) {
  my $cd = $bc->checkdigit_modulo_11($i);
  printf("%s - %s\n", $i, $cd);
}
