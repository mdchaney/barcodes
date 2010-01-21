package Barcode::UPC_A;

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
use Barcode::EAN_13;

@ISA = qw(Exporter);
@EXPORT = qw();
$VERSION = '0.05';

=head1 NAME

Barcode::UPC_A - Create pattern for UPC-A barcodes

=head1 SYNOPSIS

    use Barcode::UPC_A;
    
    my $bc = new Barcode::UPC_A;
	 my $text = '63692092149';
	 my $checkdigit = $bc->checkdigit($text);
	 my $pattern = $bc->barcode($text.$checkdigit);

	 print $pattern,"\n";

=head1 DESCRIPTION

Barcode::UPC_A creates the patterns that you need to display a UPC-A barcode.
The pattern returned is a string of 1's and 0's, where 1 represent part of a
black bar and 0 represents a space.  Each character is a single unit wide, so
"111001" is a black bar 3 units wide, a space two units wide, and a black bar
that is one unit wide.  It is up to the programmer to create code to display
the resultant barcode.

=head2 MISCELLANEOUS INFORMATION

A UPC-A barcode is identical to an EAN-13 with the initial EAN number
system digit set to "0".  Because that digit is encoded in the parity
of the left side, the codes are printed identically.

A UPC-A barcode has 4 elements:
1. A single digit "number system" designation
2. A 5-digit manufacturer's code
3. A 5-digit product code
4. A single digit checksum

The number system digit:
0, 7 - standard UPC codes
2    - a product weight- generally calculated at the store
3    - pharmaceuticals
5    - coupons
1, 6, 8, 9 are reserved

=head2 RENDERING

The UPC-A is typically rendered at 1-1.5 inch across, and half an inch high.
The number system digit and checksum digit are shown on the left and right
sides of the code.  The other two sets of five digits are rendered at the
bottom of the barcode.  The alignment can be either bottom of the text flush
with bottom of barcode, or middle of text aligned with bottom of barcode.
The two sets of five digits are separated by the two middle guard bars which
always extend to the bottom.

=head1 PREREQUISITES

This module requires C<strict>, C<Exporter>, C<Carp>, and C<Barcode::EAN_13>.

=head2 EXPORT

None.

=cut

=head1 CONSTRUCTOR

=over 4

=item C<new(options)>

Create a new Barcode::UPC_A object. The different options that can be set are:

=over 4

=item addcheck

Automatically add a check digit to each barcode

=item barchar

Character to represent bars (defaults to '1')

=item spacechar

Character to represent spaces (defaults to '0')

=back

Example:

	 $bc = new Barcode::UPC_A(addcheck => 1);

    Create a new UPC-A barcode object that will automatically add check digits.

=back

=cut

# Keep an EAN_13 object around
my $ean_13_bc;

sub new {

  my ($class, %opts) = @_;
  my $self = {
    addcheck => 0,
	 barchar => '1',
	 spacechar => '0',
	 barcode_type => 'UPC-A',
  };

  foreach (keys %opts) {
    $self->{$_} = $opts{$_};
  }

  $opts{'addcheck'}=0;
  $ean_13_bc = new Barcode::EAN_13(%opts);

  bless $self, $class;

  return $self;
}

=head1 OBJECT METHODS

All methods croak on errors.

=over 4

=item C<checkdigit(number)>

Generates the check digit for a string.  There are only two possible failure
scenarios.  First, if anything other than 11 digits is passed in, it'll croak.
Second, if any of the characters aren't digits, it'll croak.

Example:

	print $bc->checkdigit('435'),"\n";

	Prints a single 0

=cut


sub checkdigit {

  my $self = shift;
  my $str = shift;

  my $a=0;
  
  if (!$self->validate($str,11)) {
    croak("Invalid $self->{barcode_type} data: >> $str <<");
  }

  return $ean_13_bc->checkdigit('0'.$str);
}


=item C<barcode(string)>

Creates the pattern for this string.  If the C<addcheck> option was set, then
the check digit will be computed and appended automatically.  The pattern will
use C<barchar> and C<spacechar> to represent the bars and spaces.

"barcode" will croak if a non-digit or a string of incorrect length is
passed to it.

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

  return $ean_13_bc->barcode('0'.$str);
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
    $expected_length=($self->{'addcheck'}?11:12);
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

L<Barcode>, L<Barcode::UPC_E>, L<Barcode::EAN_13>

=cut

1;
