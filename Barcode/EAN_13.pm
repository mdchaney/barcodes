package Barcode::EAN_13;

# Barcode generation classes
#
# Copyright 2003 Michael Chaney Consulting Corporation
# Written by: Michael Chaney
#
# See enclosed documentation for full copyright and contact information

use strict;
use vars qw($VERSION @ISA @EXPORT);
use Exporter;
use Carp qw(croak);

@ISA = qw(Exporter);
@EXPORT = qw();
$VERSION = '0.05';

=head1 NAME

Barcode::EAN_13 - Create pattern for EAN-13 barcodes

=head1 SYNOPSIS

    use Barcode::EAN_13;
    
    my $bc = new Barcode::EAN_13;
	 my $text = '123459';
	 my $checkdigit = $bc->checkdigit($text);
	 my $pattern = $bc->barcode($text.$checkdigit);

	 print $pattern,"\n";

=head1 DESCRIPTION

Barcode::EAN_13 creates the patterns that you need to display EAN-13
barcodes.  The pattern returned is a string of 1's and 0's, where 1 represent
part of a black bar and 0 represents a space.  Each character is a single unit
wide, so "111001" is a black bar 3 units wide, a space two units wide, and a
black bar that is one unit wide.  It is up to the programmer to create code to
display the resultant barcode.

Unlike some of the other barcodes, e.g. Code 3 of 9, there is no "wnstr" for
EAN & UPC style barcodes because the bars and spaces are variable width from
1 to 3 units.

Note that JAN codes (Japanese) are simply EAN-13's, and they always start with
"49".  The table below shows "49" to be "Japan".

Also note that many books use a "bookland" code, perhaps along with a UPC
Supplemental.  The bookland code is really an EAN-13 with the initial 3 digits
of "978".  The next 9 digits are the first 9 digits of the ISBN, and of course
we still include the final check digit.  An ISBN is 10 digits, however, the
final digit is also a check digit, so it is not necessary.

=head2 MISCELLANEOUS INFORMATION

An EAN-13 with an initial "number system" digit of "0" is a UPC-A.
The Barcode::UPC_A module actually just uses this EAN_13 module.

A EAN-13 barcode has 4 elements:
1. A two-digit "number system" designation
2. A 5-digit manufacturer's code
3. A 5-digit product code
4. A single digit checksum

There is some flexibility in EAN-13 on the digit layout.  Sometimes,
the first three digits indicate numbering system, i.e. some number
systems are further split up.  An example is "74", which is used for
Central America with "740" for Guatemala, "741" for El Salvador, etc.

Here is the complete table from www.barcodeisland.com:

00-13: USA & Canada          590: Poland               780: Chile
20-29: In-Store Functions    594: Romania              784: Paraguay
30-37: France                599: Hungary              785: Peru
40-44: Germany               600 & 601: South Africa   786: Ecuador
45:  Japan (also 49)         609: Mauritius            789: Brazil
46:  Russian Federation      611: Morocco              80 - 83: Italy
471: Taiwan                  613: Algeria              84: Spain
474: Estonia                 619: Tunisia              850: Cuba
475: Latvia                  622: Egypt                858: Slovakia
477: Lithuania               625: Jordan               859: Czech Republic
479: Sri Lanka               626: Iran                 860: Yugloslavia
480: Philippines             64:  Finland              869: Turkey
482: Ukraine                 690-692: China            87:  Netherlands
484: Moldova                 70:  Norway               880: South Korea
485: Armenia                 729: Israel               885: Thailand
486: Georgia                 73:  Sweden               888: Singapore
487: Kazakhstan              740: Guatemala            890: India
489: Hong Kong               741: El Salvador          893: Vietnam
49:  Japan (JAN-13)          742: Honduras             899: Indonesia
50:  United Kingdom          743: Nicaragua            90 & 91: Austria
520: Greece                  744: Costa Rica           93:  Australia
528: Lebanon                 746: Dominican Republic   94:  New Zealand
529: Cyprus                  750: Mexico               955: Malaysia
531: Macedonia               759: Venezuela            977: ISSN
535: Malta                   76:  Switzerland          978: ISBN
539: Ireland                 770: Colombia             979: ISMN
54:  Belgium & Luxembourg    773: Uruguay              980: Refund receipts
560: Portugal                775: Peru                 981 & 982: CCC
569: Iceland                 777: Bolivia              99:  Coupons
57:  Denmark                 779: Argentina

ISSN - International Standard Serial Number for Periodicals
ISBN - International Standard Book Numbering
ISMN - International Standard Music Number
CCC  - Common Currency Coupons


=head2 RENDERING

When rendered, the initial digit of the number system is shown to the
left and above the rest of the digits.  The other two sets of six
digits each are shown at the bottom of the code, aligned with the
bottom of the code, and with the middle guard pattern bars extending
down between them.  The lower digits may be aligned flush with the
bottom of the barcode, or the center of the text may be aligned with the
bottom of the barcode.


=head1 PREREQUISITES

This module requires C<strict>, C<Exporter>, C<Carp>, and C<Barcode::EAN_13>.

=head2 EXPORT

None.

=cut

# patterns to create the bar codes:

# left side, odd/even
my %left_patterns = (
'0' => { 'o' => '0001101', 'e' => '0100111'},
'1' => { 'o' => '0011001', 'e' => '0110011'},
'2' => { 'o' => '0010011', 'e' => '0011011'},
'3' => { 'o' => '0111101', 'e' => '0100001'},
'4' => { 'o' => '0100011', 'e' => '0011101'},
'5' => { 'o' => '0110001', 'e' => '0111001'},
'6' => { 'o' => '0101111', 'e' => '0000101'},
'7' => { 'o' => '0111011', 'e' => '0010001'},
'8' => { 'o' => '0110111', 'e' => '0001001'},
'9' => { 'o' => '0001011', 'e' => '0010111'},
);

my %left_parity_patterns = (
'0' => 'oooooo',
'1' => 'ooeoee',
'2' => 'ooeeoe',
'3' => 'ooeeeo',
'4' => 'oeooee',
'5' => 'oeeooe',
'6' => 'oeeeoo',
'7' => 'oeoeoe',
'8' => 'oeoeeo',
'9' => 'oeeoeo',
);

# right side (could be an array, just keeping a hash for clarity
my %right_patterns = (
'0' => '1110010',
'1' => '1100110',
'2' => '1101100',
'3' => '1000010',
'4' => '1011100',
'5' => '1001110',
'6' => '1010000',
'7' => '1000100',
'8' => '1001000',
'9' => '1110100',
);

# AAAAHHHHHHHHH side + middle + side is 666, the number of the beast
my $side_guard_pattern='101';
my $middle_guard_pattern='01010';

=head1 CONSTRUCTOR

=over 4

=item C<new(options)>

Create a new Barcode::EAN_13 object. The different options that can be set are:

=over 4

=item addcheck

Automatically add a check digit to each barcode

=item barchar

Character to represent bars (defaults to '1')

=item spacechar

Character to represent spaces (defaults to '0')

=back

Example:

	 $bc = new Barcode::EAN_13(addcheck => 1);

    Create a new EAN-13 barcode object that will automatically add check digits.

=back

=cut


sub new {

  my ($class, %opts) = @_;
  my $self = {
    addcheck => 0,
	 barchar => '1',
	 spacechar => '0',
	 barcode_type => 'EAN-13',
  };

  foreach (keys %opts) {
    $self->{$_} = $opts{$_};
  }

  bless $self, $class;

  return $self;
}

=head1 OBJECT METHODS

All methods will croak if the input string is the wrong length or contains
any non-numeric characters.

=over 4

=item C<checkdigit(number)>

Generates the check digit for a string.  It will croak with an error if the
string has a non-digit character in it.  You can avoid this if you assure
that only correct strings are passed in, as there is no other failure scenario.

Example:

	print $bc->checkdigit('750105453010'),"\n";

	Prints a single 7

=cut


sub checkdigit {

  my $self = shift;
  my $str = shift;

  my $a=0;
  
  if (!$self->validate($str, 12)) {
    croak("Invalid $self->{barcode_type} data: >> $str <<");
  }

  my @str=split(//, $str);

  # Checksum is modulo 10 of sum of all digits, with odd digits
  # multiplied by 3.  Note that we start with the final digit as "odd"
  # and work toward the front, so that the same algorithm works for
  # UPC-A or EAN-13.
  my $weight=3;  # weight is 3 for even positions, 1 for odd positions

  while (@str) {
    my $digit = pop(@str);
    $a += $digit * $weight;
    $weight = 4 - $weight;
  }

  return ((10-($a%10))%10);
}


=item C<barcode(string)>

Creates the pattern for this string.  If the C<addcheck> option was set,
then the check digit will be computed and appended automatically.  The
pattern will use C<barchar> and C<spacechar> to represent the bars and
spaces.

If the string that is passed in contains a non-valid character, it'll croak
with an error.

=cut


sub barcode {

  my $self = shift;
  my $str = shift;
  
  if (!$self->validate($str)) {
    croak("Invalid $self->{barcode_type} data: >> $str <<");
  }

  if ($self->{'addcheck'}) {
	 $str .= $self->checkdigit($str);
  } else {
    if (!$self->validate_checksum($str)) {
      croak("Invalid checksum for $self->{barcode_type}: >>$str<<");
    }
  }

  my ($parity_digit, $left_half, $right_half);

  if ($str=~/^(\d)(\d{6})(\d{6})/) {
    ($parity_digit, $left_half, $right_half) = ($1, $2, $3);
  } else {
    croak("Malformed EAN: $str");
  }

  my $retstr;

  $retstr=$side_guard_pattern;

  # First, we'll encode the left 6 digits
  for (my $i=0 ; $i<6 ; $i++) {
    $retstr .= $left_patterns{substr($left_half,$i,1)}{substr($left_parity_patterns{$parity_digit},$i,1)};
  }

  $retstr.=$middle_guard_pattern;

  # Now, we'll encode the right 6 digits
  for (my $i=0 ; $i<6 ; $i++) {
    $retstr .= $right_patterns{substr($right_half,$i,1)};
  }

  $retstr.=$side_guard_pattern;

  my @pattern = ($self->{'spacechar'}, $self->{'barchar'});
  $retstr =~ s/(.)/$pattern[$1]/eg;

  return $retstr;
}

=item C<barcode_rle(string)>

Creates a run-length-encoded (RLE) barcode definition for the given string.
It consists of a width (in units) of the entire code, followed by a colon,
then followed by the RLE string.  The RLE string consists of digits which
alternately refer to the width of a black bar and a white space.  The RLE
string always starts with a black bar.

As an example, consider "38" in Code11 as an RLE string:

29:112211221112112111221

It will render as:

# ##  # ##  # #  # ## # ##  #

The point is not to save space, as there isn't much of a savings to be had.
Rather, it is far easier to write code to render the RLE format.

=cut

sub barcode_rle {

  my $self = shift;
  my $str = shift;
  
  if (!$self->validate($str)) {
    croak("Invalid $self->{barcode_type} data: >> $str <<");
  }

  my $pattern=$self->barcode($str);

  my $rle='';
  my $len;

  for (my $i=0 ; $i<length($pattern) ; ) {
    my $char=substr($pattern,$i,1);
    for ($len=0 ; substr($pattern,$i,1) eq $char ; $i++) { $len++; }
	 $rle .= $len;
  }

  my $retstr=sprintf('%d:%s', length($pattern), $rle);

  return $retstr;
}


=item C<validate(string)>

The validate method simply returns true if the given string can be encoded
in this barcode type or false if not.  In most of the modules, validate
also verifies the checksum, however, Codabar doesn't have a consistent
checksum scheme (nor does it need one) so we don't check it.


=cut

sub validate {

  my $self = shift;
  my $str = shift;
  my $expected_length = shift;
  
  if (!$expected_length) {
    $expected_length=($self->{'addcheck'}?12:13);
  }

  return ($str=~/^[0-9]{${expected_length}}$/);
}

=item C<validate_checksum(string)>

Returns true if the checksum encoded in the string is correct, false
otherwise.

=cut

sub validate_checksum {

  my $self = shift;
  my $str = shift;

  if (!$self->validate($str)) {
    croak("Invalid $self->{barcode_type} data: >> $str <<");
  }

  my ($payload, $checkme, $checkdigit);

  ($payload, $checkme) = ($str =~/^(.*)(.)$/);

  $checkdigit = $self->checkdigit($payload);

  return ($checkdigit eq $checkme);
}


=back

=head1 BUGS

None that I know of.  This is really simple.

=head1 AUTHOR

Michael Chaney mdchaney@michaelchaney.com
Michael Chaney Consulting Corporation http://www.michaelchaney.com/

=head1 COPYRIGHT

Copyright (C) 2003, Michael Chaney Consulting Corporation
All rights not explicitly granted herein are reserved
You may distribute under any of the following three licenses:
GNU General Public License
Standard BSD license
Artistic License


=head1 SEE ALSO

L<Barcode>, L<Barcode::EAN_8>, L<Barcode::UPC_A>

=cut

1;
