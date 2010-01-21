package Barcode::UPC_E;

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
@EXPORT = qw(upca_to_upce upce_to_upca);
$VERSION = '0.05';

=head1 NAME

Barcode::UPC_E - Create pattern for UPC-E barcodes

=head1 SYNOPSIS

    use Barcode::UPC_E;
    
    my $bc = new Barcode::UPC_E;
	 my $text = '123459';
	 my $checkdigit = $bc->checkdigit($text);
	 my $pattern = $bc->barcode($text.$checkdigit);

	 print $pattern,"\n";

=head1 DESCRIPTION

Barcode::UPC_E creates the patterns that you need to display UPC-E barcodes.
The pattern returned is a string of 1's and 0's, where 1 represent part of a
black bar and 0 represents a space.  Each character is a single unit wide, so
"111001" is a black bar 3 units wide, a space two units wide, and a black bar
that is one unit wide.  It is up to the programmer to create code to display
the resultant barcode.

Unlike some of the other barcodes, e.g. Code 3 of 9, there is no "wnstr" for
EAN & UPC style barcodes because the bars and spaces are variable width from
1 to 3 units.

UPC-E barcodes are 6 digits that are encoded similarly to the left half
of an EAN-13 barcode.  The UPC-E is computed from a UPC-A code via the
exported function upca_to_upce.

=head2 MISCELLANEOUS INFORMATION

A UPC-E barcode has 3 elements:
1. A one-digit "number system" designation, must be "0" or "1"
2. 6 digits of information, some of which are for manufacturer id,
   some for product id, and some for designation of format.
4. A single digit checksum

The number system and checksum digit are encoded together in the
parity pattern of the 6 data digits.

=head2 RENDERING

When rendered, the number system digit is shown to the left and above
the data digits.  The six data digits are shown at the bottom of the code,
aligned with the # bottom of the code.  The checksum digit is shown to
the right of the barcode on the same horizontal line as the initial
number system digit.

=head1 PREREQUISITES

This module requires C<strict>, C<Exporter>, and C<Carp>.

=head2 EXPORT

Exports C<upca_to_upce> and C<upce_to_upca> to convert between the two types.

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

#The keys for the parity pattern are check digit and number system digit
my %parity_patterns = (
'0' => { '0' => 'eeeooo', '1' => 'oooeee'},
'1' => { '0' => 'eeoeoo', '1' => 'ooeoee'},
'2' => { '0' => 'eeooeo', '1' => 'ooeeoe'},
'3' => { '0' => 'eeoooe', '1' => 'ooeeeo'},
'4' => { '0' => 'eoeeoo', '1' => 'oeooee'},
'5' => { '0' => 'eooeeo', '1' => 'oeeooe'},
'6' => { '0' => 'eoooee', '1' => 'oeeeoo'},
'7' => { '0' => 'eoeoeo', '1' => 'oeoeoe'},
'8' => { '0' => 'eoeooe', '1' => 'oeoeeo'},
'9' => { '0' => 'eooeoe', '1' => 'oeeoeo'},
);

my $left_guard_pattern='101';
my $right_guard_pattern='010101';

=head1 CONSTRUCTOR

=over 4

=item C<new(options)>

Create a new Barcode::UPC_E object. The different options that can be set are:

=over 4

=item addcheck

Automatically add a check digit to each barcode

=item barchar

Character to represent bars (defaults to '1')

=item spacechar

Character to represent spaces (defaults to '0')

=back

Example:

	 $bc = new Barcode::UPC_E(addcheck => 1);

    Create a new UPC-E barcode object that will automatically add check digits.

=back

=cut


sub new {

  my ($class, %opts) = @_;
  my $self = {
    addcheck => 0,
	 barchar => '1',
	 spacechar => '0',
	 barcode_type => 'UPC-E',
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
  
  if (!$self->validate($str,1)) {
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
    if (length($str)==12) {
      if (!$self->validate_checksum($str)) {
        croak("Invalid checksum for $self->{barcode_type}: >>$str<<");
      }
    } elsif (length($str)==8) {
      if (!$self->validate_checksum(upce_to_upca($str))) {
        croak("Invalid checksum for $self->{barcode_type}: >>$str<<");
      }
	 }
  }

  if (length($str)==12) {
    # It's a UPC-A, we'll have to split it up into a UPC-E
    $str = upca_to_upce($str);
  }

  my ($number_system, $payload, $checksum)=unpack('a1a6a1',$str);

  my $retstr;

  $retstr=$left_guard_pattern;

  # Encode the payload
  for (my $i=0 ; $i<6 ; $i++) {
    $retstr .= $patterns{substr($payload,$i,1)}{substr($parity_patterns{$checksum}{$number_system},$i,1)};
  }

  $retstr.=$right_guard_pattern;

  my @pattern = ($self->{'spacechar'}, $self->{'barchar'});
  $retstr =~ s/(.)/$pattern[$1]/eg;

  return $retstr;
}

=item C<upca_to_upce(string)>

Converts a UPC-A number to a UPC-E.  If it cannot, it will croak.

=cut

sub upca_to_upce {

  my $str = shift;

  if (length($str)==11) {
    $str .= checkdigit('',$str);
  } elsif (length($str)!=12) {
    croak("The length of the UPC-A data must be 11 or 12 digits: $str\n");
  }

  my ($number_system, $payload, $checksum) = unpack('a1a10a1',$str);

  my %conversions = (
    /(\d)(\d)([012])0000(\d)(\d)(\d)/ => '${1}${2}${4}${5}${6}${3}',
    /(\d)(\d)([3-9])00000(\d)(\d)/    => '${1}${2}${3}${4}${5}3',
    /(\d)(\d)(\d)(\d)00000(\d)/       => '${1}${2}${3}${4}${5}4',
    /(\d)(\d)(\d)(\d)(\d)0000([5-9])/ => '${1}${2}${3}${4}${5}${6}',
  );

  if ($payload =~ /(\d)(\d)([012])0000(\d)(\d)(\d)/) {
    $payload = "${1}${2}${4}${5}${6}${3}";
  } elsif ($payload =~ /(\d)(\d)([3-9])00000(\d)(\d)/) {
    $payload = "${1}${2}${3}${4}${5}3";
  } elsif ($payload =~ /(\d)(\d)(\d)(\d)00000(\d)/) {
    $payload = "${1}${2}${3}${4}${5}4";
  } elsif ($payload =~ /(\d)(\d)(\d)(\d)(\d)0000([5-9])/) {
    $payload = "${1}${2}${3}${4}${5}${6}";
  } else {
    croak("Can't turn $str into a UPC-E");
  }

  return $number_system.$payload.$checksum;
}

=item C<upce_to_upca(string)>

Converts a UPC-E number to the UPC-A equivalent.

=cut

sub upce_to_upca {

  my $str = shift;

  if (length($str)<7 || length($str)>8) {
    croak("The length of the UPC-E code must be 7 or 8 digits >>$str<<");
  }

  my ($number_system, $payload, $checksum) = unpack('a1a6a1',$str);
  my $ret;

  if ($payload=~/^(\d\d)(\d\d\d)([012])/) {
    $ret="${1}${3}0000${2}";
  } elsif ($payload=~/^(\d\d\d)(\d\d)(3)/) {
    $ret="${1}00000${2}";
  } elsif ($payload=~/^(\d\d\d\d)(\d)(4)/) {
    $ret="${1}00000${2}";
  } elsif ($payload=~/^(\d\d\d\d\d)([5-9])/) {
    $ret="${1}0000${2}";
  }

  return $number_system.$ret.$checksum;
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

  my $addcheck;

  if (@_) {
    $addcheck = shift;
  } else {
    $addcheck = $self->{'addcheck'};
  }

  if ($str!~/^[0-9]+$/) {
    return 0;
  }

  if ($addcheck) {
    if (length($str)!=11) {
      return 0;
	 }
  } else {
    if (length($str)!=8 && length($str)!=12) {
      return 0;
	 }
  }

  return 1;
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

Because of the nature of these, the barcode method won't automatically
validate the checksum unless the payload is 11 digits long.  At some
point, I'll write a upce_to_upca routine which will then allow us to check
the checksum.

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

L<Barcode>, L<Barcode::UPC_A>, L<Barcode::EAN_13>, L<Barcode::EAN_8>

=cut

1;
