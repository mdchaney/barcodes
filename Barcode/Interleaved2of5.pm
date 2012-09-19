package Barcode::Interleaved2of5;

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

Barcode::Interleaved2of5 - Create pattern for Interleaved 2 of 5 (also known
as I 2/5 or ITF) barcodes

=head1 SYNOPSIS

    use Barcode::Interleaved2of5;
    
    my $bc = new Barcode::Interleaved2of5;
	 my $text = '123459';
	 my $checkdigit = $bc->checkdigit($text);
	 my $pattern = $bc->barcode($text.$checkdigit);

	 print $pattern,"\n";

=head1 DESCRIPTION

Barcode::Interleaved2of5 creates the patterns that you need to display
Interleaved 2 of 5 (also known as I 2/5) barcodes.  The pattern returned is a
string of 1's and 0's, where 1 represent part of a black bar and 0 represents
a space.  Each character is a single unit wide, so "111001" is a black bar 3
units wide, a space two units wide, and a black bar that is one unit wide.  It
is up to the programmer to create code to display the resultant barcode.

Note that an Interleaved2of5 code requires an even number of digits to encode.
If an odd number of digits is given, a "0" will be prepended to the string.
If this is not desirable for your application, you *must* deal with it
appropriately.

If you are going to use a check digit, then keep in mind that the check digit
must be appended to the string.  Therefore, if you have an even number of
digits, the C<checkdigit> method will prepend a "0" before computing the check
digit.  The "0" will have no effect on the checksum.

=head1 PREREQUISITES

This module requires C<strict>, C<Exporter>, and C<Carp>.

=head2 EXPORT

None.

=cut

# 1 2 4 7 P
my %patterns = (
	'start' => 'nnnn',
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
	'stop' => 'wnn'
);

=head1 CONSTRUCTOR

=over 4

=item C<new(options)>

Create a new Barcode::Interleaved2of5 object. The different options that can
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

	 $bc = new Barcode::Interleaved2of5(addcheck => 1);

    Create a new I 2/5 barcode object that will automatically add check digits.

=back

=cut


sub new {

  my ($class, %opts) = @_;
  my $self = {
    addcheck => 0,
	 barchar => '1',
	 spacechar => '0',
	 barcode_type => 'Interleaved 2 of 5',
	 wnstr => '',
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

Generates the check digit for a number.  If an even number of digits is passed
in, a "0" will be prepended to the string.  There is no possibility of failure
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
    croak("I 2/5 can only encode digits: $str\n");
  }

  my @str=split(//, $str);
  unless (length($str) & 1) {
    unshift @str, '0';
  }

  my $weight=3;  # weight is 3 for even positions, 1 for odd positions

  while (@str) {
    my $digit = shift(@str);
    $a += $digit * $weight;
    $weight = 4 - $weight;
  }

  return ((10-($a%10))%10);
}


=item C<barcode(number)>

Creates the pattern for this number.  If the C<addcheck> option was set, then
the check digit will be computed and appended automatically.  If there is an
odd number of digits, a "0" will be prepended.  The pattern will use C<barchar>
and C<spacechar> to represent the bars and spaces.  As a side effect, the
"wnstr" property is set to a string of w's and n's to represent the barcode.

If the string that is passed in contains a non-digit, it will croak.

=cut


sub barcode {

  my $self = shift;
  my $str = shift;
  
  if (!$self->validate($str)) {
    croak("I 2/5 can only encode digits: $str\n");
  }

  if ($self->{'addcheck'}) {
    unless (length($str) & 1) {
	 	# If we are going to add a check digit, and there are currently an
		# even number of digits, then prepend a "0".  The check digit will
		# later be appended, bringing it back to even.
	 	$str = '0'.$str;
	 }
	 $str .= $self->checkdigit($str);
  } else {
    if (length($str) & 1) {
	 	# If we're not adding a check digit, and there is an odd number of
		# digits, we'll prepend a "0".  This has no effect on the check
		# digit.
	 	$str = '0'.$str;
	 }
	 if (!$self->validate_checksum($str)) {
      croak("Invalid checksum for $self->{barcode_type} >>$str<<");
	 }
  }

  my $wnstr=$patterns{'start'};

  my @str=split(//,$str);
  while (@str) {
    my $bars=$patterns{shift(@str)};
    my $spaces=$patterns{shift(@str)};
    for (my $i=0 ; $i<length($bars) ; $i++) {
	 	$wnstr .= substr($bars,$i,1);
	 	$wnstr .= substr($spaces,$i,1);
	 }
  }

  $wnstr .= $patterns{'stop'};

  # At this point, $wnstr is a string of w's and n's, representing wide
  # (2 units) and narrow (1 unit).  It starts with a black bar, then
  # alternates between spaces and bars, ending of course with another
  # bar.  We're going to turn this into 1 and 0's where 1 are bars and
  # 0's are spaces.

  my $retstr='';
  my $outdigit;
  for (my $i=0 ; $i<length($wnstr) ; $i++) {
    if ($i&1) {   $outdigit=$self->{'spacechar'};
	 } else {      $outdigit=$self->{'barchar'};
	 }
    if (substr($wnstr,$i,1) eq 'w') {
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
  
  if (!$self->validate($str)) {
    croak("Invalid $self->{barcode_type} data: >> $str <<");
  }

  my $pattern=$self->barcode($str);

  my $retstr=sprintf('%d:%s', length($pattern), $self->{'wnstr'});

  $retstr =~ tr/wn/21/;

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

Probably none, the code is pretty simple.

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

L<Barcode>, L<Barcode::Standard2of5>

=cut

1;
