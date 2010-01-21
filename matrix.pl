#!/usr/bin/perl

use strict;

use PostScript::Simple;
use PostScript::TextBlock;
use PostScript::Metrics;

use Barcode::Coop2of5;

# create a new PostScript object
my $p = new PostScript::Simple(papersize => "Letter",
		eps => 0,
		units => "in");

# create a new page
$p->newpage;

my $bc=new Barcode::Coop2of5('addcheck'=>0, 'barchar'=>'#', 'spacechar'=>' ');

my @tests = qw(
0123456789
01234567890
01234567891
01234567892
01234567893
01234567894
01234567895
01234567896
01234567897
01234567898
01234567899
);

my $y=1;

foreach my $test (@tests) {
	my $rle=$bc->barcode_rle($test);
	# let's do 80 units/inch
	my ($total_units,$junk)=split(/:/,$rle);
	my $width=$total_units/70;
	render_barcode_rle(1.5, $y, 1.5+$width, $y+.45, $rle, $test);
	#$p->setcolour('black');
	#$p->setfont('Times-Roman',12);
	#$p->text( 5.5, 1.5, $bc->{'barcode_type'});
	$y+=.9;
}

# write the output to a file
$p->output("matrix.ps");


# make a bar code given an rle string
sub render_barcode_rle() {
	my ($x, $y, $x1, $y1, $str, $text)=@_;

	my ($total_units, $rle) = split(/:/, $str, 2);

	# actually prints the bar code
	my $bc_width=$x1-$x;
	my $unit_width=$bc_width/$total_units;
	my $start=$x;
	for (my $i=0 ; $i<length($rle) ; $i++) {
		# draw a bar
		my $bar_width = substr($rle, $i, 1) * $unit_width;
		$p->box( {filled=>1}, $start, $y+(11/72), $start + $bar_width, $y1);
		$i++;
		# skip over the space to the start of the next bar
		my $space_width = substr($rle, $i, 1) * $unit_width;
		$start += $bar_width + $space_width;
	}

	# prints the textual data under the bar code
	my $centre=$x+($x1-$x)/2;
	my $wordwidth = PostScript::Metrics::stringwidth($text,'Times-Roman',10)/72;
	#$p->setcolour('white');
	#$p->box( {filled=>1}, $centre-($wordwidth/2)-.1, $y, $centre+($wordwidth/2)+.1, $y+1/8+.02);
	$p->setcolour('black');
	$p->setfont('Times-Roman',10);
	$p->text( {align=>'centre'}, $centre, $y, $text);
}
