#!/usr/bin/perl

use strict;

use PostScript::Simple;
use PostScript::TextBlock;
use PostScript::Metrics;

use Barcode::Interleaved2of5;
use Barcode::Standard2of5;
use Barcode::Matrix2of5;
use Barcode::Coop2of5;
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
use Barcode::C128;

use Barcode::Code128;

# create a new PostScript object
my $p = new PostScript::Simple(papersize => "Letter",
		eps => 0,
		units => "in");

# create a new page
$p->newpage;

$p->setcolour('black');
$p->setfont('Times-Bold',20);
$p->text( {align=>'centre'}, 4.25, 10, 'Barcode Demo');

# right column, starting at bottom

my $bc=new Barcode::UPC_A('addcheck'=>0, 'barchar'=>'#', 'spacechar'=>' ');
my $rle=$bc->barcode_rle('636920922865');
render_barcode_rle(5.5, 1, 6.5, 1.45, $rle, '636920922865');
$p->setcolour('black');
$p->setfont('Times-Roman',12);
$p->text( 5.5, 1.5, $bc->{'barcode_type'});

my $bc=new Barcode::UPC_E('addcheck'=>0, 'barchar'=>'#', 'spacechar'=>' ');
my $rle=$bc->barcode_rle('04252614');
render_barcode_rle(5.5, 2, 6.2, 2.45, $rle, '04252614');
$p->setcolour('black');
$p->setfont('Times-Roman',12);
$p->text( 5.5, 2.5, $bc->{'barcode_type'});

my $bc=new Barcode::EAN_13('addcheck'=>0, 'barchar'=>'#', 'spacechar'=>' ');
my $rle=$bc->barcode_rle('9781565922860');
render_barcode_rle(5.5, 3, 6.5, 3.45, $rle, '9781565922860');

my $bc=new Barcode::UPC_Supplemental_5('addcheck'=>1, 'barchar'=>'#', 'spacechar'=>' ');
my $rle=$bc->barcode_rle('90000');
render_barcode_rle(6.6, 3, 7.1, 3.35, $rle, '90000');

$p->setcolour('black');
$p->setfont('Times-Roman',12);
$p->text( 5.5, 3.5, 'Bookland (EAN-13 + 5 Digit Supp)');

my $bc=new Barcode::UPC_A('addcheck'=>0, 'barchar'=>'#', 'spacechar'=>' ');
my $rle=$bc->barcode_rle('071896491005');
render_barcode_rle(5.5, 4, 6.5, 4.45, $rle, '071896491005');

my $bc=new Barcode::UPC_Supplemental_2('addcheck'=>1, 'barchar'=>'#', 'spacechar'=>' ');
my $rle=$bc->barcode_rle('12');
render_barcode_rle(6.6, 4, 6.6+(4/19), 4.35, $rle, '12');

$p->setcolour('black');
$p->setfont('Times-Roman',12);
$p->text( 5.5, 4.5, 'UPC-A + 2 Digit Supp');

# left column, starting at bottom

my $bc=new Barcode::Codabar('addcheck'=>1, 'barchar'=>'#', 'spacechar'=>' ');
my $rle=$bc->barcode_rle('A40156B');
render_barcode_rle(.5, 1, 1.5, 1.45, $rle, 'A40156B');
$p->setcolour('black');
$p->setfont('Times-Roman',12);
$p->text( .5, 1.5, $bc->{'barcode_type'});

my $bc=new Barcode::Code11('addcheck'=>0, 'barchar'=>'#', 'spacechar'=>' ');
my $rle=$bc->barcode_rle('123-4530');
render_barcode_rle(.5, 2, 1.5, 2.45, $rle, '123-453');
$p->setcolour('black');
$p->setfont('Times-Roman',12);
$p->text( .5, 2.5, $bc->{'barcode_type'});

my $bc=new Barcode::Code3of9('addcheck'=>1, 'barchar'=>'#', 'spacechar'=>' ');
my $rle=$bc->barcode_rle('+THIS IS A TEST+');
render_barcode_rle(.5, 3, 3, 3.45, $rle, '+THIS IS A TEST+');
$p->setcolour('black');
$p->setfont('Times-Roman',12);
$p->text( .5, 3.5, $bc->{'barcode_type'});

my $bc=new Barcode::Code93('autopromote'=>1, 'addcheck'=>1, 'barchar'=>'#', 'spacechar'=>' ');
my $rle=$bc->barcode_rle('This is a Full ASCII Test!');
render_barcode_rle(.5, 4, 4, 4.45, $rle, 'This is a Full ASCII Test!');
$p->setcolour('black');
$p->setfont('Times-Roman',12);
$p->text( .5, 4.5, $bc->{'barcode_type'});

my $bc=new Barcode::EAN_13('addcheck'=>1, 'barchar'=>'#', 'spacechar'=>' ');
my $rle=$bc->barcode_rle('750105453010');
render_barcode_rle(.5, 5, 1.2, 5.45, $rle, '7501054530107');
$p->setcolour('black');
$p->setfont('Times-Roman',12);
$p->text( .5, 5.5, $bc->{'barcode_type'});

my $bc=new Barcode::EAN_8('addcheck'=>0, 'barchar'=>'#', 'spacechar'=>' ');
my $rle=$bc->barcode_rle('55123457');
render_barcode_rle(2.5, 5, 3.2, 5.45, $rle, '55123457');
$p->setcolour('black');
$p->setfont('Times-Roman',12);
$p->text( 2.5, 5.5, $bc->{'barcode_type'});

my $bc=new Barcode::Interleaved2of5('addcheck'=>1, 'barchar'=>'#', 'spacechar'=>' ');
my $rle=$bc->barcode_rle('750105453010');
render_barcode_rle(.5, 6, 1.5, 6.45, $rle, '750105453010');
$p->setcolour('black');
$p->setfont('Times-Roman',12);
$p->text( .5, 6.5, $bc->{'barcode_type'});

my $bc=new Barcode::Standard2of5('addcheck'=>1, 'barchar'=>'#', 'spacechar'=>' ');
my $rle=$bc->barcode_rle('750105453010');
render_barcode_rle(2.5, 6, 5.5, 6.45, $rle, '750105453010');
$p->setcolour('black');
$p->setfont('Times-Roman',12);
$p->text( 2.5, 6.5, $bc->{'barcode_type'});

my $bc=new Barcode::Matrix2of5('addcheck'=>1, 'barchar'=>'#', 'spacechar'=>' ');
my $rle=$bc->barcode_rle('0123456789');
render_barcode_rle(2.5, 7, 4.0, 7.45, $rle, '0123456789');
$p->setcolour('black');
$p->setfont('Times-Roman',12);
$p->text( 2.5, 7.5, $bc->{'barcode_type'});

my $bc=new Barcode::Coop2of5('addcheck'=>1, 'barchar'=>'#', 'spacechar'=>' ');
my $rle=$bc->barcode_rle('0123456789');
render_barcode_rle(5.5, 7, 7.0, 7.45, $rle, '0123456789');
$p->setcolour('black');
$p->setfont('Times-Roman',12);
$p->text( 5.5, 7.5, $bc->{'barcode_type'});

my $bc=new Barcode::Plessey('addcheck'=>0, 'barchar'=>'#', 'spacechar'=>' ');
my $rle=$bc->barcode_rle('80523');
render_barcode_rle(.5, 7, 1.5, 7.45, $rle, '80523');
$p->setcolour('black');
$p->setfont('Times-Roman',12);
$p->text( .5, 7.5, $bc->{'barcode_type'});

my $bc=new Barcode::PostNet('addcheck'=>1, 'barchar'=>'#', 'spacechar'=>' ');
my $bars=$bc->barcode('37013-185224');
render_postnet(.5, 8, 5, 8.2, $bars);
my $bars=$bc->barcode('37013-1852');
render_postnet(.5, 8.25, 4.5, 8.45, $bars);
$p->setcolour('black');
$p->setfont('Times-Roman',12);
$p->text( .5, 8.5, $bc->{'barcode_type'});

my $bc=new Barcode::C128('barchar'=>'#', 'spacechar'=>' ');
my $rle=$bc->barcode_rle('This is a test!');
render_barcode_rle(.5, 9, 2.5, 9.45, $rle, 'This is a test!');
$p->setcolour('black');
$p->setfont('Times-Roman',12);
$p->text( .5, 9.5, $bc->{'barcode_type'});

my $bc=new Barcode::C128('barchar'=>'#', 'spacechar'=>' ');
my $rle=$bc->barcode_rle("\x1b[H\x1b[2J");
render_barcode_rle(4.5, 9, 5.5, 9.45, $rle, 'Clear Screen!');
$p->setcolour('black');
$p->setfont('Times-Roman',12);
$p->text( 4.5, 9.5, $bc->{'barcode_type'});

# write the output to a file
$p->output("showcase.ps");


# make a bar code
sub make_barcode() {
	my ($x, $y, $x1, $y1, $text)=@_;

	my $bc=new Barcode::Codabar('addcheck'=>1, 'barchar'=>'#', 'spacechar'=>' ');
	my $stripes=$bc->barcode($text);

	render_barcode($x, $y, $x1, $y1, $stripes, $text);
}

sub render_barcode {
	my ($x, $y, $x1, $y1, $stripes, $text)=@_;

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

sub render_postnet() {
	my ($x, $y, $x1, $y1, $bars)=@_;

	# actually prints the postnet bar code
	my $bcwidth=$x1-$x;
	my $barwidth=$bcwidth/length($bars);
	my $top=0;
	for (my $i=0 ; $i<length($bars) ; $i++) {
		if (substr($bars,$i,1) eq ' ') { $top=($y1+$y)/2; } else { $top=$y1; }
		$p->box( {filled=>1}, $x+($i*$barwidth), $y, $x+(($i+.5)*$barwidth), $top);
	}
}
