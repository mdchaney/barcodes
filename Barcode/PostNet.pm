package Barcode::PostNet;

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

Barcode::PostNet - Create pattern for PostNet barcodes

=head1 SYNOPSIS

    use Barcode::PostNet;
    
    my $bc = new Barcode::PostNet;
	 my $text = '123459';
	 my $checkdigit = $bc->checkdigit($text);
	 my $pattern = $bc->barcode($text.$checkdigit);

	 print $pattern,"\n";

=head1 DESCRIPTION

Barcode::PostNet creates the patterns that you need to display PostNet
barcodes.  The pattern returned is a string of 1's and 0's, where 1 represent
a tall line and 0 represents a short line.  Each character is a single unit
wide, so "111001" is a 3 tall bars, 2 short bars, and finally 1 tall bar.
It is up to the programmer to create code to display the resultant barcode.

PostNet barcodes always include a check digit at the end.

=head2 MISCELLANEOUS INFORMATION

PostNet barcodes may be 5, 9, or 11 digits long, plus a checksum
digit.  The checksum is computed by summing the digits, then
subtracting the result from the next multiple of 10.

=head2 RENDERING

The US Postal Service has great documentation regarding the rendering
and placement requirements for PostNet barcodes on mail.  Please be sure
to read their documentation and follow their instructions.  If you misplace
the PostNet barcode, they will simply put another one on the envelope from
an automatic address reader, meaning that your efforts will be wasted.

=head1 PREREQUISITES

This module requires C<strict>, C<Exporter>, and C<Carp>

=head2 EXPORT

None.

=cut

# patterns to create the bar codes:

# 7 4 2 1 P - encoded as tall "1" and short "0" bars
my %patterns=(
'0' => '11000',
'1' => '00011',
'2' => '00101',
'3' => '00110',
'4' => '01001',
'5' => '01010',
'6' => '01100',
'7' => '10001',
'8' => '10010',
'9' => '10100',
'|' => '1'  # guard patterns
);

=head1 CONSTRUCTOR

=over 4

=item C<new(options)>

Create a new Barcode::PostNet object. The different options that can be set are:

=over 4

=item addcheck

Automatically add a check digit to each barcode

=item barchar

Character to represent bars (defaults to '1')

=item spacechar

Character to represent spaces (defaults to '0')

=back

Example:

	 $bc = new Barcode::PostNet(addcheck => 1);

    Create a new PostNet barcode object that will automatically add check digits.

=back

=cut


sub new {

  my ($class, %opts) = @_;
  my $self = {
    addcheck => 0,
	 barchar => '1',
	 spacechar => '0',
	 barcode_type => 'PostNet',
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
that only digits are passed in, as there is no other failure scenario.

Example:

	print $bc->checkdigit('47834'),"\n";

	Prints a single 0

=cut


sub checkdigit {

  my $self = shift;
  my $str = shift;

  my $a=0;
  
  if (!$self->validate($str,1)) {
    croak("Invalid $self->{barcode_type} data: >> $str <<");
  }

  $str =~ s/[^\d]//g;

  my @str=split(//, $str);

  while (@str) {
    my $digit = pop(@str);
    $a += $digit;
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

  $str =~ s/[^\d]//g;

  if ($self->{'addcheck'}) {
	 $str .= $self->checkdigit($str);
  } else {
    if (!$self->validate_checksum($str)) {
      croak("Invalid checksum for $self->{barcode_type} >>$str<<");
	 }
  }

  my $retstr = '|' . $str . '|';

  $retstr =~ s/(.)/$patterns{$1}/eg;

  my @pattern = ($self->{'spacechar'}, $self->{'barchar'});
  $retstr =~ s/(.)/$pattern[$1]/eg;

  return $retstr;
}

=item C<barcode_rle(string)>

This method is fairly pointless for Postnet, since each bar is drawn separately.
The code to render this is no simpler, and probably more complex, than just
looking at each line individually.  This is presented so that the classes
are all consistent.

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

  if ($str!~/^[0-9\-]+$/) {
    return 0;
  }

  $str =~ s/[^\d]//g;

  if ($addcheck) {
    if (length($str)!=5 && length($str)!=9 && length($str)!=11) {
      return 0;
    }
  } else {
    if (length($str)!=6 && length($str)!=10 && length($str)!=12) {
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

L<Barcode>

=cut

1;
