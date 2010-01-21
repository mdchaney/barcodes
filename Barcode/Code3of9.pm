package Barcode::Code3of9;

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

Barcode::Code3of9 - Create pattern for Code 3 of 9 (Code 39) barcodes

=head1 SYNOPSIS

    use Barcode::Code3of9;
    
    my $bc = new Barcode::Code3of9;
	 my $text = '123459';
	 my $checkdigit = $bc->checkdigit($text);
	 my $pattern = $bc->barcode($text.$checkdigit);

	 print $pattern,"\n";

=head1 DESCRIPTION

Barcode::Code3of9 creates the patterns that you need to display Code 3 of 9
(also known as Code 39 and USD-3) barcodes.  The pattern returned is a string of 1's and
0's, where 1 represent part of a black bar and 0 represents a space.  Each
character is a single unit wide, so "111001" is a black bar 3 units wide, a
space two units wide, and a black bar that is one unit wide.  It is up to the
programmer to create code to display the resultant barcode.

=head2 MISCELLANEOUS INFORMATION

Code 3 of 9 can encode text and digits.  There is also a way to do "full ascii"
mode, but it's not recommended.  Full ascii mode uses some of the characters
as shift characters, so "a" is encoded as "+A".  There's no indication that
full ascii mode is being used, so it has to be handled by the application.
This has been fixed in Code 93, by designation of four special characters which
are used only for shifting.  However, if you need to use a full character set,
Code 128 is probably a better choice.

=head2 RENDERING

Code 3 of 9 may be rendered however the programmer wishes.  Since there is a
simple mapping between number of characters and length of code, a variable
length code should be allowed to grow and shrink to assure the bars are
neither too large or too small.  Code 3 of 9 is often implemented as a font.

There is no standard for human-readable text associated with the code, and
in fact some applications leave out the human-readable element altogether.
The text is typically shown below the barcode where applicable.

=head1 PREREQUISITES

This module requires C<strict>, C<Exporter>, and C<Carp>.

=head2 EXPORT

None.

=cut

my $charseq='0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ-. $/+%';

my %patterns = (
'0'=> {'pos'=>'0',  'wn'=>'nnnwwnwnn', 'bars'=>'101001101101'},
'1'=> {'pos'=>'1',  'wn'=>'wnnwnnnnw', 'bars'=>'110100101011'},
'2'=> {'pos'=>'2',  'wn'=>'nnwwnnnnw', 'bars'=>'101100101011'},
'3'=> {'pos'=>'3',  'wn'=>'wnwwnnnnn', 'bars'=>'110110010101'},
'4'=> {'pos'=>'4',  'wn'=>'nnnwwnnnw', 'bars'=>'101001101011'},
'5'=> {'pos'=>'5',  'wn'=>'wnnwwnnnn', 'bars'=>'110100110101'},
'6'=> {'pos'=>'6',  'wn'=>'nnwwwnnnn', 'bars'=>'101100110101'},
'7'=> {'pos'=>'7',  'wn'=>'nnnwnnwnw', 'bars'=>'101001011011'},
'8'=> {'pos'=>'8',  'wn'=>'wnnwnnwnn', 'bars'=>'110100101101'},
'9'=> {'pos'=>'9',  'wn'=>'nnwwnnwnn', 'bars'=>'101100101101'},
'A'=> {'pos'=>'10', 'wn'=>'wnnnnwnnw', 'bars'=>'110101001011'},
'B'=> {'pos'=>'11', 'wn'=>'nnwnnwnnw', 'bars'=>'101101001011'},
'C'=> {'pos'=>'12', 'wn'=>'wnwnnwnnn', 'bars'=>'110110100101'},
'D'=> {'pos'=>'13', 'wn'=>'nnnnwwnnw', 'bars'=>'101011001011'},
'E'=> {'pos'=>'14', 'wn'=>'wnnnwwnnn', 'bars'=>'110101100101'},
'F'=> {'pos'=>'15', 'wn'=>'nnwnwwnnn', 'bars'=>'101101100101'},
'G'=> {'pos'=>'16', 'wn'=>'nnnnnwwnw', 'bars'=>'101010011011'},
'H'=> {'pos'=>'17', 'wn'=>'wnnnnwwnn', 'bars'=>'110101001101'},
'I'=> {'pos'=>'18', 'wn'=>'nnwnnwwnn', 'bars'=>'101101001101'},
'J'=> {'pos'=>'19', 'wn'=>'nnnnwwwnn', 'bars'=>'101011001101'},
'K'=> {'pos'=>'20', 'wn'=>'wnnnnnnww', 'bars'=>'110101010011'},
'L'=> {'pos'=>'21', 'wn'=>'nnwnnnnww', 'bars'=>'101101010011'},
'M'=> {'pos'=>'22', 'wn'=>'wnwnnnnwn', 'bars'=>'110110101001'},
'N'=> {'pos'=>'23', 'wn'=>'nnnnwnnww', 'bars'=>'101011010011'},
'O'=> {'pos'=>'24', 'wn'=>'wnnnwnnwn', 'bars'=>'110101101001'},
'P'=> {'pos'=>'25', 'wn'=>'nnwnwnnwn', 'bars'=>'101101101001'},
'Q'=> {'pos'=>'26', 'wn'=>'nnnnnnwww', 'bars'=>'101010110011'},
'R'=> {'pos'=>'27', 'wn'=>'wnnnnnwwn', 'bars'=>'110101011001'},
'S'=> {'pos'=>'28', 'wn'=>'nnwnnnwwn', 'bars'=>'101101011001'},
'T'=> {'pos'=>'29', 'wn'=>'nnnnwnwwn', 'bars'=>'101011011001'},
'U'=> {'pos'=>'30', 'wn'=>'wwnnnnnnw', 'bars'=>'110010101011'},
'V'=> {'pos'=>'31', 'wn'=>'nwwnnnnnw', 'bars'=>'100110101011'},
'W'=> {'pos'=>'32', 'wn'=>'wwwnnnnnn', 'bars'=>'110011010101'},
'X'=> {'pos'=>'33', 'wn'=>'nwnnwnnnw', 'bars'=>'100101101011'},
'Y'=> {'pos'=>'34', 'wn'=>'wwnnwnnnn', 'bars'=>'110010110101'},
'Z'=> {'pos'=>'35', 'wn'=>'nwwnwnnnn', 'bars'=>'100110110101'},
'-'=> {'pos'=>'36', 'wn'=>'nwnnnnwnw', 'bars'=>'100101011011'},
'.'=> {'pos'=>'37', 'wn'=>'wwnnnnwnn', 'bars'=>'110010101101'},
' '=> {'pos'=>'38', 'wn'=>'nwwnnnwnn', 'bars'=>'100110101101'},
'$'=> {'pos'=>'39', 'wn'=>'nwnwnwnnn', 'bars'=>'100100100101'},
'/'=> {'pos'=>'40', 'wn'=>'nwnwnnnwn', 'bars'=>'100100101001'},
'+'=> {'pos'=>'41', 'wn'=>'nwnnnwnwn', 'bars'=>'100101001001'},
'%'=> {'pos'=>'42', 'wn'=>'nnnwnwnwn', 'bars'=>'101001001001'},
'*'=> {'pos'=>'0',  'wn'=>'nwnnwnwnn', 'bars'=>'100101101101'}
);

# I'm not doing anything with this yet, but this is the mapping to full
# ascii.  Basically, using the ascii code as the offset into this array
# will yield the replacement string.  It's simple to do this with an
# s///eg substitution.

my @full_ascii=(
'%U', '$A', '$B', '$C', '$D', '$E', '$F', '$G', '$H', '$I', '$J', '$K', '$L', '$M', '$N', '$O', '$P', '$Q', '$R', '$S', '$T', '$U', '$V', '$W', '$X', '$Y', '$Z', '%A', '%B', '%C', '%D', '%E', ' ', '/A', '/B', '/C', '/D', '/E', '/F', '/G', '/H', '/I', '/J', '/K', '/L', '-', '.', '/O', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '/Z', '%F', '%G', '%H', '%I', '%J', '%V', 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', '%K', '%L', '%M', '%N', '%O', '%W', '+A', '+B', '+C', '+D', '+E', '+F', '+G', '+H', '+I', '+J', '+K', '+L', '+M', '+N', '+O', '+P', '+Q', '+R', '+S', '+T', '+U', '+V', '+W', '+X', '+Y', '+Z', '%P', '%Q', '%R', '%S', '%T'
);

=head1 CONSTRUCTOR

=over 4

=item C<new(options)>

Create a new Barcode::Code3of9 object. The different options that can be
set are:

=over 4

=item addcheck

Automatically add a check digit to each barcode

=item barchar

Character to represent bars (defaults to '1')

=item spacechar

Character to represent spaces (defaults to '0')

=back

Example:

	 $bc = new Barcode::Code3of9(addcheck => 1);

    Create a new Code 3 of 9 barcode object that will automatically add
    check digits.

=back

=cut


sub new {

  my ($class, %opts) = @_;
  my $self = {
    addcheck => 0,
	 barchar => '1',
	 spacechar => '0',
	 barcode_type => 'Code 3 of 9',
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

Generates the check digit for a string.  This method will croak if a non-valid
value is passed to it.  You may avoid this if you assure that only correct
strings are passed in, as there is no other failure scenario.  Allowable
characters are 0-9 A-Z - . $ / + % and space.

Example:

	print $bc->checkdigit('435'),"\n";

	Prints a single 0

=cut


sub checkdigit {

  my $self = shift;
  my $str = shift;

  my $a=0;
  
  if (!$self->validate($str)) {
    croak("Invalid string for $self->{barcode_type}: >>$str<<");
  }

  my @str=split(//, $str);

  while (@str) {
  	$a += $patterns{shift(@str)}{'pos'};
  }

  $a %= 43;

  return substr($charseq,$a,1);
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
    croak("Invalid string for $self->{barcode_type}: >>$str<<");
  }

  if ($self->{'addcheck'}) {
	 $str .= $self->checkdigit($str);
  } else {
    if (!$self->validate_checksum($str)) {
      croak("Invalid checksum for $self->{barcode_type}: >>$str<<");
    }
  }

  $str= '*' . $str . '*';

  my $retstr=$str;

  $retstr =~ s/(.)/$patterns{$1}{'bars'}.'0'/eg;
  chop($retstr);

  my $wnstr=$str;

  $wnstr =~ s/(.)/$patterns{$1}{'wn'}.'n'/eg;
  chop($wnstr);

  $self->{'wnstr'} = $wnstr;

  my @pattern = ($self->{'spacechar'}, $self->{'barchar'});
  $retstr =~ s/(.)/$pattern[$1]/eg;

  return $retstr;
}

=item C<fullascii(string)>

Performs necessary character substitutions to turn this string into a "full
ascii" representation, suitable for feeding to "barcode".

=cut

sub fullascii {

  my $self = shift;
  my $str = shift;

  $str =~ s/(.)/$full_ascii[ord($1)]/seg;

  return $str;
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
  
  return ($str=~/^[0-9A-Z\-\. \$\/\+\%]*$/);
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

L<Barcode>, L<Barcode::Code93>

=cut

1;
