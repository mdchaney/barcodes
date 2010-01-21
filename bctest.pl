#!/usr/bin/perl

use strict;

use PostScript::Simple;
use PostScript::TextBlock;
use PostScript::Metrics;

use Barcode::Interleaved2of5;
use Barcode::Standard2of5;
use Barcode::Code3of9;
use Barcode::Code93;
use Barcode::Code11;
use Barcode::Codabar;
use Barcode::EAN_13;
use Barcode::EAN_8;
use Barcode::UPC_A;
use Barcode::UPC_E;
use Barcode::UPC_Supplemental_2;
use Barcode::UPC_Supplemental_5;
use Barcode::Plessey;
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

my $bc=new Barcode::Codabar('addcheck'=>1, 'barchar'=>'#', 'spacechar'=>' ');
my $rle=$bc->barcode_rle('A40156B');
make_bar_code_rle(1, 1, 2, 1.45, $rle, 'A40156B');
$p->setcolour('black');
$p->setfont('Times-Roman',12);
$p->text( 1, 1.5, $bc->{'barcode_type'});

my $bc=new Barcode::Code11('addcheck'=>0, 'barchar'=>'#', 'spacechar'=>' ');
my $rle=$bc->barcode_rle('123-4530');
make_bar_code_rle(1, 2, 2, 2.45, $rle, '123-453');
$p->setcolour('black');
$p->setfont('Times-Roman',12);
$p->text( 1, 2.5, $bc->{'barcode_type'});

my $bc=new Barcode::Code3of9('addcheck'=>1, 'barchar'=>'#', 'spacechar'=>' ');
my $rle=$bc->barcode_rle('+THIS IS A TEST+');
make_bar_code_rle(1, 3, 3.5, 3.45, $rle, '+THIS IS A TEST+');
$p->setcolour('black');
$p->setfont('Times-Roman',12);
$p->text( 1, 3.5, $bc->{'barcode_type'});

my $bc=new Barcode::Code93('autopromote'=>1, 'addcheck'=>1, 'barchar'=>'#', 'spacechar'=>' ');
my $rle=$bc->barcode_rle('This is a Full ASCII Test!');
make_bar_code_rle(1, 4, 5.5, 4.45, $rle, 'This is a Full ASCII Test!');
$p->setcolour('black');
$p->setfont('Times-Roman',12);
$p->text( 1, 4.5, $bc->{'barcode_type'});


# write the output to a file
$p->output("bctest.ps");


# make a bar code
sub make_bar_code() {
	my ($x, $y, $x1, $y1, $text)=@_;

	my $bc=new Barcode::Codabar('addcheck'=>1, 'barchar'=>'#', 'spacechar'=>' ');
	my $stripes=$bc->barcode($text);

	# actually prints the bar code
	my $bcwidth=$x1-$x;
	my $barwidth=$bcwidth/length($stripes);
	my $start=0;
	for (my $i=0 ; $i<length($stripes) ; ) {
		$start=$i;
		while (substr($stripes,$i,1) ne ' ' && $i<length($stripes)) { $i++; }
		$p->box( {filled=>1}, $x+($start*$barwidth), $y+(11/72), $x+($i*$barwidth), $y1);
		while (substr($stripes,$i,1) eq ' ' && $i<length($stripes)) { $i++; }
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

# make a bar code given an rle string
sub make_bar_code_rle() {
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
