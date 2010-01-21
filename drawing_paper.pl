#!/usr/bin/perl

use strict;

use PostScript::Simple;
use PostScript::TextBlock;
use PostScript::Metrics;

# create a new PostScript object
my $p = new PostScript::Simple(papersize => "Letter",
		eps => 0,
		units => "in");

# create a new page
$p->newpage;

$p->setlinewidth(1/64);

for (my $y=.5 ; $y<=10.5 ; $y+=2/3) {
	$p->line(0,$y,8.5,$y);
}

$p->setlinewidth(1/256);
for (my $y=.5+(1/3) ; $y<=10.5 ; $y+=2/3) {
	$p->line(0,$y,8.5,$y);
}

# write the output to a file
$p->output("drawing_paper.ps");
