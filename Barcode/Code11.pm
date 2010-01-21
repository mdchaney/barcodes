package Barcode::Code11;

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

Barcode::Code11 - Create pattern for Code 11 barcodes

=head1 SYNOPSIS

    use Barcode::Code11;
    
    my $bc = new Barcode::Code11;
	 my $text = '123459';
	 my $checkdigit = $bc->checkdigit($text);
	 my $pattern = $bc->barcode($text.$checkdigit);

	 print $pattern,"\n";

=head1 DESCRIPTION

Barcode::Code11 creates the patterns that you need to display a Code 11
barcode.  The pattern returned is a string of 1's and 0's, where 1 represent
part of a black bar and 0 represents a space.  Each character is a single unit
wide, so "111001" is a black bar 3 units wide, a space two units wide, and a
black bar that is one unit wide.  It is up to the programmer to create code to
display the resultant barcode.

Code 11 also creates a secondary encoding of w's and n's, representing "wide"
and "narrow" bars.

Code 11 can encode all digits and "-", and can be any length.  There are
two check digits if the payload is 10 or more characters, one check digit
otherwise.

=head2 MISCELLANEOUS INFORMATION

Code 11 is used to label telecom equipment.

=head2 RENDERING

The author knows of no standards for rendering a Code 11 barcode.  The samples
indicate that the human-readable text should be below the barcode.  Since the
code allows for variable-width data, be sure that it's not rendered in units
that are too large or too small.

=head1 PREREQUISITES

This module requires C<strict>, C<Exporter>, and C<Carp>.

=head2 EXPORT

None.

=cut

# Each pattern starts with and ends with a bar, then has a narrow
# interchar gap.
my %patterns = (
	'0' => 'nnnnwn',
	'1' => 'wnnnwn',
	'2' => 'nwnnwn',
	'3' => 'wwnnnn',
	'4' => 'nnwnwn',
	'5' => 'wnwnnn',
	'6' => 'nwwnnn',
	'7' => 'nnnwwn',
	'8' => 'wnnwnn',
	'9' => 'wnnnnn',
	'-' => 'nnwnnn',
	'|' => 'nnwwnn',
);

=head1 CONSTRUCTOR

=over 4

=item C<new(options)>

Create a new Barcode::Code11 object. The different options that can be set are:

=over 4

=item addcheck

Automatically add a check digits to each barcode

=item barchar

Character to represent bars (defaults to '1')

=item spacechar

Character to represent spaces (defaults to '0')

=back

Example:

	 $bc = new Barcode::Code11(addcheck => 1);

    Create a new Code 11 barcode object that will automatically add check digits.

=back

=cut


sub new {

  my ($class, %opts) = @_;
  my $self = {
    addcheck => 0,
	 barchar => '1',
	 spacechar => '0',
	 barcode_type => 'Code11',
	 wnstr => ''
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

Generates the check digits for a string.  It will croak with an error if the
string has a non-allowable character in it.  You can avoid this if you assure
that only correct strings are passed in, as there is no other failure scenario.
Allowable characters are 0-9 and '-'.

Example:

	print $bc->checkdigit('435'),"\n";

	Prints 10

=cut


sub checkdigit {

  my $self = shift;
  my $str = shift;

  if ($str!~/^[0-9\-]+$/) {
    croak("Code 11 only allows digits and dashes to be encoded: $str\n");
  }

  my @str=split(//, $str);

  # For the first check digit, the weight increases per position (from
  # the right) and resets to 1 after 10.

  my $weight=1;
  my $a=0;
  
  while (@str) {
    my $digit = pop(@str);
	 $digit=10 if ($digit eq '-');
    $a += $digit * $weight;
    $weight++;
	 $weight=1 if ($weight>10);
  }

  my $digit1 = $a % 11;
  my $digit2 = '';

  if (length($str)>=10) {
    $str.=$digit1;

    my @str=split(//, $str);

    # For the first second digit, the weight increases per position (from
    # the right) and resets to 1 after 9.

    my $weight=1;
    my $a=0;

    while (@str) {
      my $digit = pop(@str);
	   $digit=10 if ($digit eq '-');
      $a += $digit * $weight;
      $weight++;
	   $weight=1 if ($weight>9);
    }

    $digit2 = $a % 11;
  }

  return $digit1.$digit2;
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
    croak("$self->{barcode_type} only allows digits and dashes to be encoded: >> $str <<\n");
  }

  if ($self->{'addcheck'}) {
	 $str .= $self->checkdigit($str);
  } else {
    if (!$self->validate_checksum($str)) {
      croak("Invalid $self->{barcode_type} checksum: >> $str <<");
    }
  }

  my $retstr;

  my $wnstr = '|' . $str . '|';

  $wnstr =~ s/(.)/$patterns{$1}/eg;
  chop($wnstr);

  $self->{'wnstr'} = $wnstr;

  my $digit;

  for (my $i=0 ; $i<length($wnstr) ; $i++) {
    if ($i & 1) {
	   $digit = $self->{'spacechar'};
	 } else {
	   $digit = $self->{'barchar'};
	 }
    if (substr($wnstr,$i,1) eq 'w') {
      $retstr .= $digit x 2;
	 } else {
      $retstr .= $digit;
	 }
  }

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
  if (!$self->{'addcheck'} && !$self->validate_checksum($str)) {
    croak("Invalid $self->{barcode_type} checksum: >> $str <<");
  }

  my $pattern=$self->barcode($str);

  my $retstr=sprintf('%d:%s', length($pattern), $self->{'wnstr'});

  $retstr =~ tr/wn/21/;

  return $retstr;
}


=item C<validate(string)>

The validate method simply returns true if the given string can be encoded
in this barcode type or false if not.

=cut

sub validate {

  my $self = shift;
  my $str = shift;
  
  return ($str=~/^[0-9\-]+$/);
}

=item C<validate_checksum(string)>

Returns true if the checksum encoded in the string is correct.  This is
interesting for Code11, because there may be one or two check digits.  If the
payload is fewer than 10 digits, then one check digit is added.  If it's 10
or more digits, two check digits are added.  This means that if our string here
is 10 or fewer digits, we'll check the last character.  If it's 12 or more,
we'll check the last two.  There should never be an 11 character string, but
if there is, we'll check the last two digits.

=cut

sub validate_checksum {

  my $self = shift;
  my $str = shift;

  if (!$self->validate($str)) {
    croak("Invalid $self->{barcode_type} data: >> $str <<");
  }

  my ($payload, $checkme, $checkdigit);

  if (length($str)<10) {
    ($payload, $checkme) = ($str =~/^(.*)(.)$/);
  } else {
    ($payload, $checkme) = ($str =~/^(.*)(..)$/);
  }

  $checkdigit = $self->checkdigit($payload);

  return ($checkdigit eq $checkme);
}


=back

=head1 BUGS

None that I know of.  This is really simple.  However, this is mostly untested
as I have no scanner capable of reading them.  It did match up perfectly
with a sample.

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
=head1 SEE ALSO

L<Barcode>

=cut

1;
