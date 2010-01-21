package Barcode::Standard2of5;

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

Barcode::Standard2of5 - Create pattern for Standard 2 of 5 (also known as
"2 of 5" or "Industrial 2 of 5" barcodes

=head1 SYNOPSIS

    use Barcode::Standard2of5;
    
    my $bc = new Barcode::Standard2of5;
	 my $text = '123459';
	 my $checkdigit = $bc->checkdigit($text);
	 my $pattern = $bc->barcode($text.$checkdigit);

	 print $pattern,"\n";

=head1 DESCRIPTION

Barcode::Standard2of5 creates the patterns that you need to display
Standard 2 of 5 barcodes.  The pattern returned is a string of 1's and 0's,
where 1 represent part of a black bar and 0 represents a space.  Each
character is a single unit wide, so "111001" is a black bar 3 units wide, a
space two units wide, and a black bar that is one unit wide.  It is up to the
programmer to create code to display the resultant barcode.

Do not use this encoding for a new application.  It is very inefficient.  A
similar encoding that is much better is "Interleaved 2 of 5".

=head1 PREREQUISITES

This module requires C<strict>, C<Exporter>, and C<Carp>.

=head2 EXPORT

None.

=cut


my %patterns = (
	'(' => '22n',
	'0' => 'nnwwn',
	'1' => 'wnnnw',
	'2' => 'nwnnw',
	'3' => 'wwnnn',
	'4' => 'nnwnw',
	'5' => 'wnwnn',
	'6' => 'nwwnn',
	'7' => 'nnnww',
	'8' => 'wnnwn',
	'9' => 'nwnwn',
	')' => '2n2'
);

=head1 CONSTRUCTOR

=over 4

=item C<new(options)>

Create a new Barcode::Standard2of5 object. The different options that can
be set are:

=over 4

=item addcheck

Automatically add a check digit to each barcode

=item barchar

Character to represent bars (defaults to '1')

=item spacechar

Character to represent spaces (defaults to '0')

=back

Example:

	 $bc = new Barcode::Standard2of5(addcheck => 1);

    Create a new Standard 2/5 barcode object that will automatically add check digits.

=back

=cut


sub new {

  my ($class, %opts) = @_;
  my $self = {
    addcheck => 0,
	 barchar => '1',
	 spacechar => '0',
	 wnstr => '',
	 barcode_type => 'Standard 2 of 5',
  };

  foreach (keys %opts) {
    $self->{$_} = $opts{$_};
  }

  bless $self, $class;

  return $self;
}

=head1 OBJECT METHODS

All methods simply croak on errors.  The only error that can occur here is
trying to encode a non-digit.

=over 4

=item C<checkdigit(number)>

Generates the check digit for a number.  There is no possibility of failure
if you assure that only digits are passed in, as there is no other failure
scenario.

Example:

	print $bc->checkdigit('435'),"\n";

	Prints a single 0

=cut


sub checkdigit {

  my $self = shift;
  my $str = shift;
  my $a=0;
  
  if (!$self->validate($str)) {
    croak("Invalid $self->{barcode_type} data: >> $str <<");
  }

  my @str=split(//, $str);

  my $weight=3;  # weight is 3 for even positions, 1 for odd positions

  while (@str) {
    my $digit = pop(@str);
    $a += $digit * $weight;
    $weight = 4 - $weight;
  }

  return ((10-($a%10))%10);
}


=item C<barcode(number)>

Creates the pattern for this number.  If the C<addcheck> option was set, then
the check digit will be computed and appended automatically.  The pattern will
use C<barchar> and C<spacechar> to represent the bars and spaces.  As a side
effect, the "wnstr" property is set to a string of w's and n's to represent the
barcode.

If the string that is passed in contains a non-digit, it will croak.

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
      croak("Invalid checksum for $self->{barcode_type} >>$str<<");
    }
  }

  my $wnstr = '(' . $str . ')';

  $wnstr =~ s/(.)/$patterns{$1}/eg;

  # The patterns have only the code for the bars, so here I'm
  # interleaving the spaces in as n's.
  $wnstr = join('n', split(//, $wnstr));

  # At this point, $wnstr is a string of w's and n's, representing wide
  # (3 units) and narrow (1 unit). As is standard, the first character
  # is a bar, then it alternates between spaces and bars.  Oddly, the
  # guard patterns have bars that are 2 units wide.

  my $retstr;
  my $outdigit;
  for (my $i=0 ; $i<length($wnstr) ; $i++) {
    if ($i&1) {   $outdigit=$self->{'spacechar'};
	 } else {      $outdigit=$self->{'barchar'};
	 }
    if (substr($wnstr,$i,1) eq 'w') {
      $retstr .= ($outdigit x 3);
    } elsif (substr($wnstr,$i,1) eq '2') {
      $retstr .= ($outdigit x 2);
	 } else {
      $retstr .= $outdigit;
	 }
  }

  $self->{'wnstr'} = $wnstr;

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

  my $retstr=sprintf('%d:%s', length($pattern), $self->{'wnstr'});

  $retstr =~ tr/wn/31/;

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
  
  return ($str=~/^\d+$/);
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

The width of wide bars is 2 on the start/stop characters, 3 in the payload.

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

L<Barcode>, L<Barcode::Interleaved2of5>

=cut

1;
