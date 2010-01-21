package Barcode::Code93;

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

Barcode::Code93 - Create pattern for Code 93 barcodes

=head1 SYNOPSIS

    use Barcode::Code93;
    
    my $bc = new Barcode::Code93;
	 my $text = 'HELLO';
	 my $checkdigit = $bc->checkdigit($text);
	 my $pattern = $bc->barcode($text.$checkdigit);

	 print $pattern,"\n";

=head1 DESCRIPTION

Barcode::Code93 creates the patterns that you need to display Code 93
barcodes.  The pattern returned is a string of 1's and 0's, where 1 represent
part of a black bar and 0 represents a space.  Each character is a single unit
wide, so "111001" is a black bar 3 units wide, a space two units wide, and a
black bar that is one unit wide.  It is up to the programmer to create code to
display the resultant barcode.

=head2 MISCELLANEOUS INFORMATION

In Code 93, there are four special "shift" characters which take the
place of the regular shift characters of Code 3 of 9 ($, /, +, and %).
They are shown as ($), (/), (%), and (+) in my documentation, but
that's ugly and difficult to handle in strings.  So I'm using the four
opening brackets to indicate the shift characters:

<  is ($), character 43
[  is (%), character 44
{  is (/), character 45
(  is (+), character 46

These are used internally for the single character ascii
representations above, however, they won't be displayed.

This module will automatically promote the string to full-ascii representation
if it can't be rendered otherwise.

=head2 RENDERING

As with Code 3 of 9, there is no standard.  Just make sure the bars aren't
so small that they can't be scanned.  The human-readable text may appear below
the barcode, again, there is not standard.

=head1 PREREQUISITES

This module requires C<strict>, C<Exporter>, and C<Carp>.

=head2 EXPORT

None.

=cut

my $charseq='0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ-. $/+%<[{(';

my %patterns = (
'0'=> {'pos'=>'0',  'disp'=>'0', 'bars'=>'100010100'}, 
'1'=> {'pos'=>'1',  'disp'=>'1', 'bars'=>'101001000'}, 
'2'=> {'pos'=>'2',  'disp'=>'2', 'bars'=>'101000100'}, 
'3'=> {'pos'=>'3',  'disp'=>'3', 'bars'=>'101000010'}, 
'4'=> {'pos'=>'4',  'disp'=>'4', 'bars'=>'100101000'}, 
'5'=> {'pos'=>'5',  'disp'=>'5', 'bars'=>'100100100'}, 
'6'=> {'pos'=>'6',  'disp'=>'6', 'bars'=>'100100010'}, 
'7'=> {'pos'=>'7',  'disp'=>'7', 'bars'=>'101010000'}, 
'8'=> {'pos'=>'8',  'disp'=>'8', 'bars'=>'100010010'}, 
'9'=> {'pos'=>'9',  'disp'=>'9', 'bars'=>'100001010'}, 
'A'=> {'pos'=>'10', 'disp'=>'A', 'bars'=>'110101000'}, 
'B'=> {'pos'=>'11', 'disp'=>'B', 'bars'=>'110100100'}, 
'C'=> {'pos'=>'12', 'disp'=>'C', 'bars'=>'110100010'}, 
'D'=> {'pos'=>'13', 'disp'=>'D', 'bars'=>'110010100'}, 
'E'=> {'pos'=>'14', 'disp'=>'E', 'bars'=>'110010010'}, 
'F'=> {'pos'=>'15', 'disp'=>'F', 'bars'=>'110001010'}, 
'G'=> {'pos'=>'16', 'disp'=>'G', 'bars'=>'101101000'}, 
'H'=> {'pos'=>'17', 'disp'=>'H', 'bars'=>'101100100'}, 
'I'=> {'pos'=>'18', 'disp'=>'I', 'bars'=>'101100010'}, 
'J'=> {'pos'=>'19', 'disp'=>'J', 'bars'=>'100110100'}, 
'K'=> {'pos'=>'20', 'disp'=>'K', 'bars'=>'100011010'}, 
'L'=> {'pos'=>'21', 'disp'=>'L', 'bars'=>'101011000'}, 
'M'=> {'pos'=>'22', 'disp'=>'M', 'bars'=>'101001100'}, 
'N'=> {'pos'=>'23', 'disp'=>'N', 'bars'=>'101000110'}, 
'O'=> {'pos'=>'24', 'disp'=>'O', 'bars'=>'100101100'}, 
'P'=> {'pos'=>'25', 'disp'=>'P', 'bars'=>'100010110'}, 
'Q'=> {'pos'=>'26', 'disp'=>'Q', 'bars'=>'110110100'}, 
'R'=> {'pos'=>'27', 'disp'=>'R', 'bars'=>'110110010'}, 
'S'=> {'pos'=>'28', 'disp'=>'S', 'bars'=>'110101100'}, 
'T'=> {'pos'=>'29', 'disp'=>'T', 'bars'=>'110100110'}, 
'U'=> {'pos'=>'30', 'disp'=>'U', 'bars'=>'110010110'}, 
'V'=> {'pos'=>'31', 'disp'=>'V', 'bars'=>'110011010'}, 
'W'=> {'pos'=>'32', 'disp'=>'W', 'bars'=>'101101100'}, 
'X'=> {'pos'=>'33', 'disp'=>'X', 'bars'=>'101100110'}, 
'Y'=> {'pos'=>'34', 'disp'=>'Y', 'bars'=>'100110110'}, 
'Z'=> {'pos'=>'35', 'disp'=>'Z', 'bars'=>'100111010'}, 
'-'=> {'pos'=>'36', 'disp'=>'-', 'bars'=>'100101110'}, 
'.'=> {'pos'=>'37', 'disp'=>'.', 'bars'=>'111010100'}, 
' '=> {'pos'=>'38', 'disp'=>' ', 'bars'=>'111010010'}, 
'$'=> {'pos'=>'39', 'disp'=>'$', 'bars'=>'111001010'}, 
'/'=> {'pos'=>'40', 'disp'=>'/', 'bars'=>'101101110'}, 
'+'=> {'pos'=>'41', 'disp'=>'+', 'bars'=>'101110110'}, 
'%'=> {'pos'=>'42', 'disp'=>'%', 'bars'=>'110101110'}, 
'<'=> {'pos'=>'43', 'disp'=>'($)', 'bars'=>'100100110'}, 
'['=> {'pos'=>'44', 'disp'=>'(%)', 'bars'=>'111011010'}, 
'{'=> {'pos'=>'45', 'disp'=>'(/)', 'bars'=>'111010110'}, 
'('=> {'pos'=>'46', 'disp'=>'(+)', 'bars'=>'100110010'}, 
'*'=> {'pos'=>'0', 'disp'=>'*', 'bars'=>'101011110'}, 
);

# Basically, using the ascii code as the offset into this array
# will yield the replacement string.  It's simple to do this with an
# s///eg substitution.
#
# Note that DEL (ascii 127) may be encoded as %T, %X, %Y, or %Z (now '%'
# has been replaced with '[').  That information is of interest only
# when decoding.

my @full_ascii=(
'[U', '<A', '<B', '<C', '<D', '<E', '<F', '<G', '<H', '<I', '<J', '<K', '<L', '<M', '<N', '<O', '<P', '<Q', '<R', '<S', '<T', '<U', '<V', '<W', '<X', '<Y', '<Z', '[A', '[B', '[C', '[D', '[E', ' ', '{A', '{B', '{C', '{D', '{E', '{F', '{G', '{H', '{I', '{J', '{K', '{L', '-', '.', '{O', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '{Z', '[F', '[G', '[H', '[I', '[J', '[V', 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', '[K', '[L', '[M', '[N', '[O', '[W', '(A', '(B', '(C', '(D', '(E', '(F', '(G', '(H', '(I', '(J', '(K', '(L', '(M', '(N', '(O', '(P', '(Q', '(R', '(S', '(T', '(U', '(V', '(W', '(X', '(Y', '(Z', '[P', '[Q', '[R', '[S', '[T'
);

=head1 CONSTRUCTOR

=over 4

=item C<new(options)>

Create a new Barcode::Code93 object. The different options that can be
set are:

=over 4

=item addcheck

Automatically add a check digit to each barcode (defaults to false)

=item autopromote

Automatically promote to the full-ascii representation if needed.  If you
have "addcheck" set to false, then you cannot automatically promote as the
check digit will change. (defaults to false)

=item barchar

Character to represent bars (defaults to '1')

=item spacechar

Character to represent spaces (defaults to '0')

=back

Example:

	 $bc = new Barcode::Code93(addcheck => 1);

    Create a new Code 93 barcode object that will automatically add
    check digits.

=back

=cut


sub new {

  my ($class, %opts) = @_;
  my $self = {
    addcheck => 0,
	 autopromote => 0,
	 barchar => '1',
	 spacechar => '0',
	 barcode_type => 'Code93',
  };

  foreach (keys %opts) {
    $self->{$_} = $opts{$_};
  }

  if ($self->{autopromote} && !$self->{addcheck}) {
    croak("$self->{barcode_type} can only autopromote if addcheck is true");
  }

  bless $self, $class;

  return $self;
}

=head1 OBJECT METHODS

All methods croak on bad characters, that's it for errors.

=over 4

=item C<checkdigit(number)>

Generates the check digits for a string.  This method will croak if a non-valid
value is passed to it.  You may avoid this if you assure that only correct
strings are passed in, as there is no other failure scenario.  Allowable
characters are 0-9 A-Z - . $ / + % and space.

Example:

	print $bc->checkdigit('HELLO'),"\n";

	Prints the check digits

=cut


sub checkdigit {

  my $self = shift;
  my $str = shift;
  
  # If there are bad characters, this will croak.  Of course, the
  # problem is that we have to allow opening brackets which aren't
  # allowable in the barcode type but are used internally as indicators
  # for the shift characters.  We might fix that another way later.
  if ($str!~/^[0-9A-Z\-\. \$\/\+\%\<\[\{\(]*$/) {
    croak("Bad characters for $self->{barcode_type} during checksum in >>$str<<");
  }

  my @str=split(//, $str);

  my $weight=1;
  my $a=0;

  while (@str) {
  	$a += ($patterns{pop(@str)}{'pos'} * $weight);
	$weight++;
	$weight=1 if $weight>20;
  }

  my $check_c = substr($charseq, $a % 47, 1);

  my @str=split(//, $str.$check_c);

  my $weight=1;
  my $a=0;

  while (@str) {
  	$a += ($patterns{pop(@str)}{'pos'} * $weight);
	$weight++;
	$weight=1 if $weight>15;
  }

  my $check_k = substr($charseq, $a % 47, 1);

  return $check_c.$check_k;
}


=item C<barcode(string)>

Creates the pattern for this string.  If the C<addcheck> option was set, then
the check digits will be computed and appended automatically.  The pattern will
use C<barchar> and C<spacechar> to represent the bars and spaces.  As a side
effect, the "wnstr" property is set to a string of w's and n's to represent the
barcode.

If the string that is passed in contains a non-valid character, this will
"croak".

=cut


sub barcode {

  my $self = shift;
  my $str = shift;
  
  if ($self->{'addcheck'}) {
    if ($self->{'autopromote'}) {
      $str =~ s/(.)/$full_ascii[ord($1)]/seg;
	 }
	 $str .= $self->checkdigit($str);
  } else {
    if (!$self->validate_checksum($str)) {
      croak("Invalid checksum for $self->{barcode_type}: >>$str<<");
    }
  }

  $str= '*' . $str . '*';

  my $retstr=$str;

  $retstr =~ s/(.)/$patterns{$1}{'bars'}/eg;
  $retstr .= '1';

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
  if (!$self->{'addcheck'} && !$self->validate_checksum($str)) {
    croak("Invalid checksum for $self->{barcode_type}: >>$str<<");
  }

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
in this barcode type or false if not.  In the case of Code93, we're going
to automatically promote to "full ascii" if a given string cannot be
encoded in the base character set.  So this always returns "true".

=cut

sub validate {

  my $self = shift;
  my $str = shift;
  
  if ($self->{'addcheck'} && $self->{'autopromote'}) {
    return 1;
  } else {
    return ($str=~/^[0-9A-Z\-\. \$\/\+\%\<\[\{\(]*$/);
  }
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

The character checking looks for the substitute shift characters < [ { and (,
but the characters themselves aren't valid.  It would be ugly to actually
try to do anything about it.

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

L<Barcode>, L<Barcode::Code3of9>

=cut

1;
