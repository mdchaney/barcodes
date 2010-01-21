package Barcode::EAN_8;

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

Barcode::EAN_8 - Create pattern for EAN-8 barcodes

=head1 SYNOPSIS

    use Barcode::EAN_8;
    
    my $bc = new Barcode::EAN_8;
	 my $text = '123459';
	 my $checkdigit = $bc->checkdigit($text);
	 my $pattern = $bc->barcode($text.$checkdigit);

	 print $pattern,"\n";

=head1 DESCRIPTION

Barcode::EAN_8 creates the patterns that you need to display an EAN-8
barcode.  The pattern returned is a string of 1's and 0's, where 1 represent
part of a black bar and 0 represents a space.  Each character is a single unit
wide, so "111001" is a black bar 3 units wide, a space two units wide, and a
black bar that is one unit wide.  It is up to the programmer to create code to
display the resultant barcode.

Unlike some of the other barcodes, e.g. Code 3 of 9, there is no "wnstr" for
EAN & UPC style barcodes because the bars and spaces are variable width from
1 to 3 units.

=head2 MISCELLANEOUS INFORMATION

Miscellaneous information for EAN-8

A EAN-8 barcode has 3 elements, and a total of 8 characters:

1. A 2 or 3 digit number system code
2. A 4 or 5 digit product code
3. A single digit checksum

=head2 RENDERING

When rendered, two sets of four digits are shown at the bottom of the
code, aligned with the bottom of the code, and with the middle guard
pattern bars extending down between them.

=head1 PREREQUISITES

This module requires C<strict>, C<Exporter>, C<Carp>, and C<Barcode::EAN_8>.

=head2 EXPORT

None.

=cut

# patterns to create the bar codes:

# left side, odd parity patterns from EAN-13
my %left_patterns = (
'0' => '0001101',
'1' => '0011001',
'2' => '0010011',
'3' => '0111101',
'4' => '0100011',
'5' => '0110001',
'6' => '0101111',
'7' => '0111011',
'8' => '0110111',
'9' => '0001011',
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

Create a new Barcode::EAN_8 object. The different options that can be set are:

=over 4

=item addcheck

Automatically add a check digit to each barcode

=item barchar

Character to represent bars (defaults to '1')

=item spacechar

Character to represent spaces (defaults to '0')

=back

Example:

	 $bc = new Barcode::EAN_8(addcheck => 1);

    Create a new EAN-8 barcode object that will automatically add check digits.

=back

=cut


sub new {

  my ($class, %opts) = @_;
  my $self = {
    addcheck => 0,
	 barchar => '1',
	 spacechar => '0',
	 barcode_type => 'EAN-8',
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

  my $a=0;
  
  if (!$self->validate($str,7)) {
    croak("Invalid data for $self->{barcode_type} >>$str<<");
  }

  my @str=split(//, $str);

  # Checksum is modulo 10 of sum of all digits, with odd digits
  # multiplied by 3.  Note that we start with the final digit as "odd"
  # and work toward the front, so that the same algorithm works for
  # UPC-A or EAN-8.
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
    croak("Invalid data for $self->{barcode_type} >>$str<<");
  }

  if ($self->{'addcheck'}) {
	 $str .= $self->checkdigit($str);
  } else {
    if (!$self->validate_checksum($str)) {
      croak("Invalid checksum for $self->{barcode_type}: >>$str<<");
    }
  }

  my ($parity_digit, $left_half, $right_half);

  if ($str=~/^(\d{4})(\d{4})/) {
    ($left_half, $right_half) = ($1, $2, $3);
  } else {
    croak("Malformed EAN: $str");
  }

  my $retstr;

  $retstr=$side_guard_pattern;

  # First, we'll encode the left 4 digits
  for (my $i=0 ; $i<4 ; $i++) {
    $retstr .= $left_patterns{substr($left_half,$i,1)};
  }

  $retstr.=$middle_guard_pattern;

  # Now, we'll encode the right 4 digits
  for (my $i=0 ; $i<4 ; $i++) {
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
in this barcode type or false if not.

=cut

sub validate {

  my $self = shift;
  my $str = shift;
  my $expected_length = shift;
  
  if (!$expected_length) {
    $expected_length=($self->{'addcheck'}?7:8);
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

L<Barcode>, L<Barcode::EAN_13>, L<Barcode::UPC_E>

=cut

1;
