#!/usr/bin/perl

use strict;

use PostScript::Simple;
use PostScript::TextBlock;
use PostScript::Metrics;
use Barcode::Interleaved2of5;
use Barcode::Standard2of5;
use Barcode::Code3of9;
use Barcode::Code11;
use Barcode::EAN_13;
use Barcode::EAN_8;
use Barcode::UPC_A;
use Barcode::UPC_E;
use Barcode::UPC_Supplemental_2;
use Barcode::UPC_Supplemental_5;
use Barcode::PostNet;

# create a new PostScript object
my $p = new PostScript::Simple(papersize => "Letter",
		eps => 0,
		units => "in");

# create a new page
$p->newpage;

#$p->setfont('Helvetica', 10);
#$p->text(1, 2, 'Hello');

# Make a bar code

make_bar_code(4, 8, 8, 8.2, '80122-1905');
make_bar_code(4, 7, 6.4, 7.2, '37013');
make_bar_code(3.4, 6, 8, 6.2, '37013-185224');
make_bar_code(3.4, 6.5, 7.4, 6.7, '37013-1852');

# write the output to a file
$p->output("postnet.ps");

sub make_bar_code() {
	my ($x, $y, $x1, $y1, $text)=@_;

	my $bc=new Barcode::PostNet('addcheck'=>1, 'barchar'=>'#', 'spacechar'=>' ');
	my $stripes=$bc->barcode($text);
	# remove leading and trailing spaces
	print $stripes,"\n";
	print length($stripes),"\n";
	print $text.$bc->checkdigit($text)."\n";

	# actually prints the bar code
	my $bcwidth=$x1-$x;
	my $barwidth=$bcwidth/length($stripes);
	my $top=0;
	for (my $i=0 ; $i<length($stripes) ; $i++) {
		if (substr($stripes,$i,1) eq ' ') { $top=($y1+$y)/2; } else { $top=$y1; }
		$p->box( {filled=>1}, $x+($i*$barwidth), $y, $x+(($i+.5)*$barwidth), $top);
	}

}
