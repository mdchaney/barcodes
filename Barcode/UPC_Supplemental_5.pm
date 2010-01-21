package Barcode::UPC_Supplemental_5;

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

Barcode::UPC_Supplemental_5 - Create pattern for 5-digit UPC Supplemental
barcodes

=head1 SYNOPSIS

    use Barcode::UPC_Supplemental_5;
    
    my $bc = new Barcode::UPC_Supplemental_5;
	 my $text = '75';
	 my $checkdigit = $bc->checkdigit($text);
	 my $pattern = $bc->barcode($text.$checkdigit);

	 print $pattern,"\n";

=head1 DESCRIPTION

Barcode::UPC_Supplemental_5 creates the patterns that you need to display a
UPC 5-digit supplemental barcode.  The pattern returned is a string
of 1's and 0's, where 1 represent part of a black bar and 0 represents a space.
Each character is a single unit wide, so "111001" is a black bar 3 units wide,
a space two units wide, and a black bar that is one unit wide.  It is up to the
programmer to create code to display the resultant barcode.

Unlike some of the other barcodes, e.g. Code 3 of 9, there is no "wnstr" for
EAN & UPC style barcodes because the bars and spaces are variable width from
1 to 3 units.

=head2 MISCELLANEOUS INFORMATION

This type of barcode consists of 5 digits, and a check digit (a
modulus 10 of the sum of the digits with weights of 3 and 9) that
is encoded in the "parity" of the two barcode digits.  It is positioned
to the right of a UPC-A or EAN-13 to create a "Bookland" code.

The two are scanned together, and typically the scanner will return the
five digits of the supplemental barcode immediately following the check
digit from the main barcode.  You will likely need to use the
Barcode::UPC_A or Barcode::EAN_13 module in addition to this one to create
the full code.

The 5-digit supplement is generally used on literature, and represents
a type-indicator digit followed by a 4-digit MSRP.  The type is "0"
for British Pound units, "5" for US Dollar units, and 9 for extra
information.  A code of "90000" means "no MSRP", "99991" indicates a
complimentary copy, "99990" is used to mark used books (by college
bookstores), and "90001" through "98999" are used internally by some
publishers.


=head2 RENDERING

The 5-digit supplement is positioned to the right of the main UPC
code, and the human-readable digits are usually printed above the
supplemental barcode.

A UPC-A is generally rendered at one inch across, then there's a 1/8th
inch gap, then the supplemental.  A UPC-A is 95 units wide, so the gap
is 24 units wide.  The 5-digit supplemental barcode is 47 units wide,
essentially half an inch at this scale.  Note that regardless of
scale, the gap should be at least the smaller of 1/8th inch or 10 units.


=head1 PREREQUISITES

This module requires C<strict>, C<Exporter>, and C<Carp>

=head2 EXPORT

None.

=cut

# patterns to create the bar codes:

# left side, odd/even
my %patterns = (
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

# parity patterns, essentially binary counting where "e" is "1"
my %parity_patterns = (
'0' => 'eeooo',
'1' => 'eoeoo',
'2' => 'eooeo',
'3' => 'eoooe',
'4' => 'oeeoo',
'5' => 'ooeeo',
'6' => 'oooee',
'7' => 'oeoeo',
'8' => 'oeooe',
'9' => 'ooeoe',
);

my $left_guard_pattern='1011';
my $interchar_guard_pattern='01';

=head1 CONSTRUCTOR

=over 4

=item C<new(options)>

Create a new Barcode::UPC_Supplemental_5 object. The different options that can be set are:

=over 4

=item addcheck

Automatically add a check digit to each barcode

=item barchar

Character to represent bars (defaults to '1')

=item spacechar

Character to represent spaces (defaults to '0')

=back

Example:

	 $bc = new Barcode::UPC_Supplemental_5(addcheck => 1);

    Create a new UPC 5-digit Supplemental barcode object that will automatically add check digits.

=back

=cut


sub new {

  my ($class, %opts) = @_;
  my $self = {
    addcheck => 0,
	 barchar => '1',
	 spacechar => '0',
	 barcode_type => 'UPC Supplemental 5-digit',
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
string has a non-allowable character in it.  You can avoid this if you assure
that only correct strings are passed in, as there is no other failure scenario.
Allowable characters are 0-9 A-Z - . $ / + % and space.

Example:

	print $bc->checkdigit('45435'),"\n";

	Prints a single 0

=cut


sub checkdigit {

  my $self = shift;
  my $str = shift;

  if (!$self->validate($str,5)) {
    croak("Invalid data for $self->{barcode_type} >>$str<<");
  }

  my $weight=3;   #alternates between 3 and 9
  my $a=0;

  my @str=split(//,$str);
  while (@str) {
    my $digit = pop(@str);
    $a += $digit * $weight;
	 $weight = 12 - $weight;
  }

  return $a % 10;
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
    croak("Invalid data for $self->{barcode_type} >>$str<<");
  }

  if ($self->{'addcheck'}) {
	 $str .= $self->checkdigit($str);
  } else {
    if (!$self->validate_checksum($str)) {
      croak("Invalid checksum for $self->{barcode_type}: >>$str<<");
    }
  }

  my ($payload, $checksum) = unpack('a5a1', $str);

  my $retstr;

  $retstr=$left_guard_pattern;

  # encode the 5 digits
  for (my $i=0 ; $i<5 ; $i++) {
    $retstr .= $interchar_guard_pattern if ($i>0);
    $retstr .= $patterns{substr($payload,$i,1)}{substr($parity_patterns{$checksum},$i,1)};
  }

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
    $expected_length=($self->{'addcheck'}?5:6);
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

L<Barcode>, L<Barcode::UPC_A>, L<Barcode::EAN_13>, L<Barcode::UPC_Supplemental_2>

=cut

1;
