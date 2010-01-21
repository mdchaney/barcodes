package Barcode::Plessey;

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

Barcode::Plessey - Create pattern for Modified (MSI) Plessey barcodes

=head1 SYNOPSIS

    use Barcode::Plessey;
    
    my $bc = new Barcode::Plessey;
	 my $text = 'A123459D';
	 my $checkdigit = $bc->checkdigit($text);
	 my $pattern = $bc->barcode($text.$checkdigit);

	 print $pattern,"\n";

=head1 DESCRIPTION

Barcode::Plessey creates the patterns that you need to display a Plessey
barcode.  The pattern returned is a string of 1's and 0's, where 1 represent
part of a black bar and 0 represents a space.  Each character is a single unit
wide, so "111001" is a black bar 3 units wide, a space two units wide, and a
black bar that is one unit wide.  It is up to the programmer to create code to
display the resultant barcode.

Plessey has 3 or 4 different checksum algorithms, and checksum is generally
implemented at a higher level than the scanner.

Don't use this format except in legacy applications.  Use Code 128 or Codabar
instead.

The barcodes are simply 4-bit binary encodings of each digit, where "0" is
a narrow bar followed by a wide space and "1" is a wide bar folloed by a narrow
space.

=head1 PREREQUISITES

This module requires C<strict>, C<Exporter>, and C<Carp>.

=head2 EXPORT

None.

=cut

my @digits = qw(0 1 2 3 4 5 6 7 8 9 A B C D E F);
my %digit_values = ('0'=>0, '1'=>1, '2'=>2, '3'=>3, '4'=>4,
'5'=>5, '6'=>6, '7'=>7, '8'=>8, '9'=>9, 'A'=>10, 'B'=>11, 'C'=>12,
'D'=>13, 'E'=>14, 'F'=>15);

my %patterns = (
'0'=> {'wn'=>'0000', 'bars'=>'100100100100'},
'1'=> {'wn'=>'0001', 'bars'=>'100100100110'},
'2'=> {'wn'=>'0010', 'bars'=>'100100110100'},
'3'=> {'wn'=>'0011', 'bars'=>'100100110110'},
'4'=> {'wn'=>'0100', 'bars'=>'100110100100'},
'5'=> {'wn'=>'0101', 'bars'=>'100110100110'},
'6'=> {'wn'=>'0110', 'bars'=>'100110110100'},
'7'=> {'wn'=>'0111', 'bars'=>'100110110110'},
'8'=> {'wn'=>'1000', 'bars'=>'110100100100'},
'9'=> {'wn'=>'1001', 'bars'=>'110100100110'},
'A'=> {'wn'=>'1010', 'bars'=>'110100110100'},
'B'=> {'wn'=>'1011', 'bars'=>'110100110110'},
'C'=> {'wn'=>'1100', 'bars'=>'110110100100'},
'D'=> {'wn'=>'1101', 'bars'=>'110110100110'},
'E'=> {'wn'=>'1110', 'bars'=>'110110110100'},
'F'=> {'wn'=>'1111', 'bars'=>'110110110110'},
'('=> {'wn'=>'', 'bars'=>'110'},
')'=> {'wn'=>'', 'bars'=>'1001'},
);

=head1 CONSTRUCTOR

=over 4

=item C<new(options)>

Create a new Barcode::Plessey object. The different options that can be
set are:

=over 4

=item barchar

Character to represent bars (defaults to '1')

=item spacechar

Character to represent spaces (defaults to '0')

=back

Example:

	 $bc = new Barcode::Plessey();

    Create a new Plessey barcode object that will automatically add
    check digits.

=back

=cut


sub new {

  my ($class, %opts) = @_;
  my $self = {
    addcheck => 0,
	 barchar => '1',
	 spacechar => '0',
	 barcode_type => 'MSI Plessey',
	 wnstr => '',
  };

  foreach (keys %opts) {
    $self->{$_} = $opts{$_};
  }

  bless $self, $class;

  return $self;
}

=head1 OBJECT METHODS

All methods croak on bad characters, that's it for errors.

=over 4

=item C<checkdigit(number)>

Returns the check digit from the modulo 10 algorithm.

Example:

	print $bc->checkdigit('1177777777'),"\n";

	Prints "9"

   This check digit routine is the standard Modulo 10 routine for MSI-Plessey
	barcodes.  There seems to be no standard for check digits for this code,
	however, the author owns a Spectra-Physics SP300+ barcode reader which
	expects this particular checksum when reading Plessey codes.  Oddly, the
	documentation for the scanner doesn't even mention this code type, and the
	programming guide doesn't have any setups for Plessey codes.

=cut


sub checkdigit {

  my $self = shift;
  my $str = shift;

  if (!$self->validate($str)) {
    croak("Invalid data for $self->{barcode_type} >>$str<<");
  }

  my ($num1, $num2);

  my @digits=split(//, $str);

  if (scalar(@digits)&1) {
    $num1=$digit_values{shift(@digits)};
  }

  while (@digits) {
    $num2 += $digit_values{shift(@digits)};
    $num1 .= $digit_values{shift(@digits)};
  }

  $num1 *= 2;

  my @digits=split(//, $num1);
  while (@digits) {
    $num2 += pop(@digits);
  }

  return ((10-($num2%10))%10);
}

=item C<checkdigit_2_modulo_10(number)>

Returns the checkdigits for a double modulo 10.  In this scheme, the standard
Plessey modulo 10 algorithm above is computed, that digit is added to the code,
then a second is computed.  Both are then returned.

=cut

sub checkdigit_2_modulo_10 {

  my $self = shift;
  my $str = shift;

  if (!$self->validate($str)) {
    croak("Invalid data for $self->{barcode_type} >>$str<<");
  }

  my $check1 = $self->checkdigit($str);
  my $check2 = $self->checkdigit($str.$check1);

  return $check1.$check2;
}

=item C<checkdigit_modulo_11(number)>

Returns the checkdigit for the modulo 11 algorithm.  In this scheme, the digits
are summed with a weight that varies from 2 to 7 increasing from the right,
the result is modulo'd 11, and the check digit is whatever is needed to bring that number to 11.  If you're like me, you see a problem in that there are only
10 digits.  Since Plessey can implement A-F (as hex digits), I'm just returning
"A" when it's 10.  I have no real way to test it.

=cut

sub checkdigit_modulo_11 {

  my $self = shift;
  my $str = shift;

  if (!$self->validate($str)) {
    croak("Invalid data for $self->{barcode_type} >>$str<<");
  }

  my @str=split(//, $str);

  # For the first check digit, the weight increases per position (from
  # the right) and resets to 1 after 10.
	 
  my $weight=2;
  my $a=0;
	 
  while (@str) {
    my $digit = $digit_values{pop(@str)};
    $a += $digit * $weight;
    $weight++;
    $weight=2 if ($weight>7);
  }

  return $digits[((11-($a%11))%11)];
}

=item C<checkdigit_modulo_11_10(number)>

Returns the checkdigits for a double modulo 10.  In this scheme, the standard
Plessey modulo 10 algorithm above is computed, that digit is added to the code,
then a second is computed.  Both are then returned.

=cut

sub checkdigit_modulo_11_10 {

  my $self = shift;
  my $str = shift;

  if (!$self->validate($str)) {
    croak("Invalid data for $self->{barcode_type} >>$str<<");
  }

  my $check1 = $self->checkdigit_modulo_11($str);
  my $check2 = $self->checkdigit($str.$check1);

  return $check1.$check2;
}

=item C<barcode(string)>

Creates the pattern for this string.  If the C<addcheck> option was set, then
the check digit will be computed and appended automatically.  The pattern will
use C<barchar> and C<spacechar> to represent the bars and spaces.  As a side
effect, the "wnstr" property is set to a string of w's and n's to represent the
barcode.

If the string that is passed in contains a non-valid character, this will
"croak".

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
      croak("Invalid checksum for $self->{barcode_type} >>$str<<");
	 }
  }

  $str = '('.$str.')';

  my $retstr=$str;

  $retstr =~ s/(.)/$patterns{$1}{'bars'}/eg;

  my $wnstr=$str;

  $wnstr =~ s/(.)/$patterns{$1}{'wn'}/eg;

  $self->{'wnstr'} = $wnstr;

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
  
  return ($str=~/^[0-9A-F]+$/);
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

It seems that wnstr can't encode the start/stop areas.  The start is "110"
and the stop is "1001".  Plesseys are not good barcodes, do not use these
except in legacy applications.

There are 3 or 4 different checksum algorithms for these, we use the
modulo 10.

While Plessey can encode A-F as hex digits, the checksum algorithms might
not work.  They are coded to take that into account.  The author's barcode
scanner doesn't recognize them.

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

L<Barcode>

=cut

1;
