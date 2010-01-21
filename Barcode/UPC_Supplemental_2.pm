package Barcode::UPC_Supplemental_2;

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

Barcode::UPC_Supplemental_2 - Create pattern for 2-digit UPC Supplemental
barcodes

=head1 SYNOPSIS

    use Barcode::UPC_Supplemental_2;
    
    my $bc = new Barcode::UPC_Supplemental_2;
	 my $text = '75';
	 my $checkdigit = $bc->checkdigit($text);
	 my $pattern = $bc->barcode($text.$checkdigit);

	 print $pattern,"\n";

=head1 DESCRIPTION

Barcode::UPC_Supplemental_2 creates the patterns that you need to display a
UPC 2-digit supplemental barcode.  The pattern returned is a string
of 1's and 0's, where 1 represent part of a black bar and 0 represents a space.
Each character is a single unit wide, so "111001" is a black bar 3 units wide,
a space two units wide, and a black bar that is one unit wide.  It is up to the
programmer to create code to display the resultant barcode.

Unlike some of the other barcodes, e.g. Code 3 of 9, there is no "wnstr" for
EAN & UPC style barcodes because the bars and spaces are variable width from
1 to 3 units.

=head2 MISCELLANEOUS INFORMATION

This type of barcode consists of 2 digits, and a check digit (simply a
modulus 4 of the number encoded) that is encoded in the "parity" of
the two barcode digits.

The 2-digit supplement is generally used on periodicals as an "issue
number", so that the UPC-A code may remain the same across issues.
The two are scanned together, and typically the scanner will return the
two digits of the supplemental barcode immediately following the check
digit from the main UPC-A.  You will likely need to use the
Barcode::UPC_A module in addition to this one to create the full
code.

=head2 RENDERING

The 2-digit supplement is positioned to the right of the main UPC
code, and the human-readable digits are usually printed above the
supplemental barcode.  UPC-A is generally rendered at one inch across,
then there's a 1/8th inch gap, then the supplemental.  A UPC-A is 95
units wide, so the gap is 24 units wide.  The supplemental barcode is
20 units wide.  The author hasn't viewed the specification, but note that
the UPC (and more generally EAN) barcode system never a bar or space of
more than four units width.  Given that, the gap should likely be at
last 10 units wide.


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
'0' => 'oo',
'1' => 'oe',
'2' => 'eo',
'3' => 'ee',
);

my $left_guard_pattern='1011';
my $interchar_guard_pattern='01';

=head1 CONSTRUCTOR

=over 4

=item C<new(options)>

Create a new Barcode::UPC_Supplemental_2 object. The different options that can be set are:

=over 4

=item addcheck

Automatically add a check digit to each barcode

=item barchar

Character to represent bars (defaults to '1')

=item spacechar

Character to represent spaces (defaults to '0')

=back

Example:

	 $bc = new Barcode::UPC_Supplemental_2(addcheck => 1);

    Create a new UPC 2-digit Supplemental barcode object that will automatically add check digits.

=back

=cut


sub new {

  my ($class, %opts) = @_;
  my $self = {
    addcheck => 0,
	 barchar => '1',
	 spacechar => '0',
	 barcode_type => 'UPC Supplemental 2-digit',
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

	print $bc->checkdigit('435'),"\n";

	Prints a single 0

=cut


sub checkdigit {

  my $self = shift;
  my $str = shift;

  if (!$self->validate($str,2)) {
    croak("Invalid data for $self->{barcode_type} >>$str<<");
  }

  # Checksum is modulo 4 of the number

  return $str % 4;
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

  my ($payload, $checksum) = unpack('a2a1', $str);

  my $retstr;

  $retstr=$left_guard_pattern;

  # encode the 2 digits
  for (my $i=0 ; $i<2 ; $i++) {
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
    $expected_length=($self->{'addcheck'}?2:3);
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

L<Barcode>, L<Barcode::UPC_A>, L<Barcode::EAN_13>, L<Barcode::UPC_Supplemental_5>

=cut

1;
