package Barcode::C128;

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

Barcode::Code128 - Create pattern for Code 128 barcodes

=head1 SYNOPSIS

    use Barcode::Code128;
    
    my $bc = new Barcode::Code128;
	 my $text = '123459';
	 my $checkdigit = $bc->checkdigit($text);
	 my $pattern = $bc->barcode($text.$checkdigit);

	 print $pattern,"\n";

=head1 DESCRIPTION

Barcode::Code128 creates the patterns that you need to display Code 128
barcodes.  The pattern returned is a string of 1's and
0's, where 1 represent part of a black bar and 0 represents a space.  Each
character is a single unit wide, so "111001" is a black bar 3 units wide, a
space two units wide, and a black bar that is one unit wide.  It is up to the
programmer to create code to display the resultant barcode.

=head2 MISCELLANEOUS INFORMATION

Code 128 can encode text and digits.  It contains 106 printable characters.
Most of the characters encode information, however some of them encode
a control sequence.  There are six control sequences, three to start in one
of three character sets, and three to change the character set in mid-stream.

The term "character set" really refers to a mapping between ASCII/numeric
characters and the 106 printable characters.  The three character sets are
simply called "A", "B", and "C".  Character set C includes simply digit
pairs, from "00" to "99".  Character set A includes all standard ASCII 
characters from 0 (NUL) to 95 (underline).  And character set B includes
all standard ASCII characters from 32 (space) to 127 (DEL).  Additionally,
there are three start codes, one for each character set, and each character
set contains two codes which switch to either of the other two sets.
Finally, there are five other codes, called "SHIFT", "FNC1", "FNC2", "FNC3",
and "FNC4".

=head2 OPTIMIZATION

The idea is to use as few characters as possible, meaning that we should
switch character sets only when necessary.  Hopefully, that won't be often,
but a worst-case scenario would be, for instance, lower-case letters
interspersed with tabs or other low ascii characters.

The overhead of switching character sets is a single character.

Here's the sequence of optimizations:

1. If the entire string is an even number of digits, use set C
2. Use only set A if possible
3. Use only set B if possible
4. Use A & B mixed together, switching only when necessary

5. Now, if we're using A or B, a run of 4 or more digits at either end of the
string, or 6 or more in the middle, should be converted to set C.  If the
number of digits is odd, then the last digit should be encoded in set A or B
before switching.  Because of the switching overhead, there is nothing to be
gained by going to set C for 2 digits.  A run of 4 digits will occupy 4
characters if two switches are necessary, so there's no gain if it's in the
middle of the string.  At the end, a character will be saved since there's
only one switch.

=head2 RENDERING

Code 128 may be rendered however the programmer wishes.  Since there is a
simple mapping between number of characters and length of code, a variable
length code should be allowed to grow and shrink to assure the bars are
neither too large or too small.

There is no standard for human-readable text associated with the code that
the author is aware of.  The text is typically shown below the barcode where
applicable.  Some variants, such as UCC/EAN-128, render the barcode in
a special way.

See http://www.uc-council.org/ for more rendering information.

=head1 PREREQUISITES

This module requires C<strict>, C<Exporter>, and C<Carp>.

=head2 EXPORT

Exports %C128, which contains all of the following elements:

SHIFT
FNC1 - FNC4
CODE_A - CODE_C

=cut

# There are 106 "characters" in Code 128.  This is a rendering of each
# by character position.  Look below to actually map human-readable
# characters to these.  This table includes a 107th, which is the stop
# character and terminator bar.

my @patterns = qw(
11011001100 11001101100 11001100110 10010011000 10010001100 10001001100
10011001000 10011000100 10001100100 11001001000 11001000100 11000100100
10110011100 10011011100 10011001110 10111001100 10011101100 10011100110
11001110010 11001011100 11001001110 11011100100 11001110100 11101101110
11101001100 11100101100 11100100110 11101100100 11100110100 11100110010
11011011000 11011000110 11000110110 10100011000 10001011000 10001000110
10110001000 10001101000 10001100010 11010001000 11000101000 11000100010
10110111000 10110001110 10001101110 10111011000 10111000110 10001110110
11101110110 11010001110 11000101110 11011101000 11011100010 11011101110
11101011000 11101000110 11100010110 11101101000 11101100010 11100011010
11101111010 11001000010 11110001010 10100110000 10100001100 10010110000
10010000110 10000101100 10000100110 10110010000 10110000100 10011010000
10011000010 10000110100 10000110010 11000010010 11001010000 11110111010
11000010100 10001111010 10100111100 10010111100 10010011110 10111100100
10011110100 10011110010 11110100100 11110010100 11110010010 11011011110
11011110110 11110110110 10101111000 10100011110 10001011110 10111101000
10111100010 11110101000 11110100010 10111011110 10111101110 11101011110
11110101110 11010000100 11010010000 11010011100
1100011101011);

# Code 128 contains a few characters that don't have ASCII equivalents.
# These are basically FNC1 - FNC4, Shift, START-A, START-B, START-C,
# and CODE-A, CODE-B, and CODE-C.  The "CODE" characters are used to
# switch characters sets after the start of the barcode.  Because they
# don't have ASCII equivalents, we're doing the ghetto hack of simply
# assigning them to high (above 127) values.
#
# I could have used constants, but I prefer to pollute the caller's
# namespace minimally.

my %C128 = (SHIFT => "\x80",
FNC1 => "\x81", FNC2 => "\x82", FNC3 => "\x83", FNC4 => "\x84",
CODE_A => "\x85", CODE_B => "\x86", CODE_C => "\x87",
START_A => "\x88", START_B => "\x89", START_C => "\x8a",
STOP => "\x8b",
shift => "\x80",
fnc1 => "\x81", fnc2 => "\x82", fnc3 => "\x83", FNC4 => "\x84",
code_a => "\x85", code_b => "\x86", code_c => "\x87",
start_a => "\x88", start_b => "\x89", start_c => "\x8a",
stop => "\x8b");

# subtract 128 from the index before looking up in this array
my @C128_chars = ('{SHIFT}', '{FNC1}', '{FNC2}', '{FNC3}', '{FNC4}',
'{CODE_A}', '{CODE_B}', '{CODE_C}', '{START_A}', '{START_B}', '{START_C}',
'{STOP}');

# Now, the mapping of ASCII characters in the individual character sets
# to the character codes (0-105) in Code 128.

my %mapping = (
'a' => pack("C*",ord(" ")..ord("_"),0..31).
			$C128{'FNC3'}.$C128{'FNC2'}.$C128{'SHIFT'}.
			$C128{'CODE_C'}.$C128{'CODE_B'}.
			$C128{'FNC4'}.$C128{'FNC1'}.
			$C128{'START_A'}.$C128{'START_B'}.$C128{'START_C'}.
			$C128{'STOP'},

'b' => pack("C*",ord(" ")..127).
			$C128{'FNC3'}.$C128{'FNC2'}.$C128{'SHIFT'}.
			$C128{'CODE_C'}.$C128{'FNC4'}.
			$C128{'CODE_A'}.$C128{'FNC1'}.
			$C128{'START_A'}.$C128{'START_B'}.$C128{'START_C'}.
			$C128{'STOP'},

'c' => pack("C*",0..99).
			$C128{'CODE_B'}.$C128{'CODE_A'}.$C128{'FNC1'}.
			$C128{'START_A'}.$C128{'START_B'}.$C128{'START_C'}.
			$C128{'STOP'},
);

my @low_ascii=qw(
NUL SOH STX ETX EOT ENQ ACK BEL BS HT LF VT FF CR SO SI DLE DC1 DC2 DC3 DC4 NAK SYN ETB CAN EM SUB ESC FS GS RS US
);
=head1 CONSTRUCTOR

=over 4

=item C<new(options)>

Create a new Barcode::Code128 object. The different options that can be
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

	 $bc = new Barcode::C128(addcheck => 1);

    Create a new Code 128 barcode object that will automatically add
    check digits.

=back

=cut


sub new {

  my ($class, %opts) = @_;
  my $self = {
    addcheck => 1,
	 barchar => '1',
	 spacechar => '0',
	 barcode_type => 'Code 128',
	 wnstr => '',
  };

  foreach (keys %opts) {
    $self->{$_} = $opts{$_};
  }

  foreach (keys %C128) {
    $self->{$_} = $C128{$_};
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

  my @str=unpack('C*', $str);

  my $weight=1;
  my $a=shift(@str);

  while (@str) {
  	$a += shift(@str) * $weight;
	$weight++;
  }

  $a %= 103;

  return chr($a);
}


=item C<barcode(string)>

Creates the pattern for this string.  Note that a check digit will always be
added, unlike the other barcode classes.  The pattern will
use C<barchar> and C<spacechar> to represent the bars and spaces.  As a side
effect, the "wnstr" property is set to a string of w's and n's to represent the
barcode.

=cut


sub barcode {

  my $self = shift;
  my $str = shift;
  
  if (!$self->validate($str)) {
    croak("Invalid string for $self->{barcode_type}: >>$str<<");
  }

  my $codedstr = $self->encode_string($str);

  # now, map the string to actual bars

  my $retstr = $codedstr;
  $retstr =~ s/(.)/$patterns[ord($1)]/seg;

  my @pattern = ($self->{'spacechar'}, $self->{'barchar'});
  $retstr =~ s/(.)/$pattern[$1]/seg;

  #print decode_string($codedstr),"\n";

  #print join('|',unpack('a11' x (1+int(length($retstr)/11)),$retstr)),"\n\n";

  return $retstr;
}


=item C<encode_string(string)>

This method will take a standard string of characters, and encode it to
the character offsets (0 - 105, plus 106 as "stop") of code 128.  It'll
just spew junk if you try to print it; instead, run it through the
C<decode_string> method.

=cut

sub encode_string {

  my $self = shift;
  my $str = shift;
  my $debugme = shift;

  # See comments in pod doc for optimization methodology explanation.

  # We'll use the string "map" to keep track of which character set to
  # use for each character.  There are a lot of "prints" in here that
  # you can use if you want to see what's going on.

  # Let's see if it's an even number of all digits, then we can make the
  # whole thing in char set C.

  my ($map, $amap,$bmap,$cmap);

  if ($str=~/^${C128{FNC1}}?(\d\d)+${C128{FNC1}}?$/) {
    $map='c' x length($str);
  } else {

    # Can it all fit in char set A?

    $amap = join('', map {index($mapping{'a'}, $_)>=0?'a':'-'} split(//,$str));
    $bmap = join('', map {index($mapping{'b'}, $_)>=0?'b':'-'} split(//,$str));

    # We'll now make the cmap, but it'll be different.  We'll only
    # map runs of 6 or more digits internal to the string, or 4 or
    # more at the end either end.
	 #
	 # I don't let the expression here match at the start of a line,
	 # because I want for all start of line matches to start with the
	 # first character.  It's specifically made so that an odd run will
	 # let the first digit be picked up by A or B.  That would cause a
	 # catastrophe at the start, since we'd waste a character or two in
	 # the conversion.

    $cmap = '-' x length($str);
    while ($str =~ /\G.*?[^\d${C128{FNC1}}](\d\d\d\d(?:\d\d)+${C128{FNC1}}*)(\d?)/g) {
      my ($digits,$odd) = ($1,$2);
      substr($cmap,pos($str)-length($digits),length($digits)) = 'c' x length($digits);
    }
    # Must make sure these two don't overlap.
	 if ($str =~ /^(${C128{FNC1}}*\d+)\d${C128{FNC1}}*$/) {
      # This must be an odd number of digits, otherwise te first check
		# way up there would have hit.  So, we'll set it all to c except
		# the last digit.  For safety sake, I only add the last "-" if
		# there were an odd number of digits.
      my $runlen=length($1);
		$cmap = ('c' x $runlen).('-' x (length($str)-$runlen));
	 } else {
      # Check for 4 at the end
      if ($str =~ /(\d\d\d\d${C128{FNC1}}*)$/ && $cmap !~ /cccc$/) {
        substr($cmap,length($cmap)-length($1),length($1)) = 'c' x length($1);
      }
	   # Check for 4 or more at the start
      if ($str =~ /^(${C128{FNC1}}*\d\d(?:\d\d)+)/) {
        substr($cmap,0,length($1)) = 'c' x length($1);
	   }
    }

    # C takes absolute precedence over A or B.  Between A & B, we'll
    # choose whichever has the longest run based on the starting
    # position of the run.

    $map=$cmap;

	 while ($cmap =~ /\G.*?(-+)/g) {
	   my $runstart = pos($cmap)-length($1);
		my $runlen = length($1);
		my $newstart=$runstart;
		my $leftover=$runlen;
		my $run='';
		while (length($run)<$runlen) {
		  my ($alen, $blen) = (0,0);
        if (substr($amap,$newstart,$leftover) =~ /^(a+)/) {
		    $alen = length($1);
		  }
        if (substr($bmap,$newstart,$leftover) =~ /^(b+)/) {
		    $blen = length($1);
		  }
		  if ($alen>=$blen) {
		    $run .= 'a' x $alen;
			 $leftover -= $alen;
			 $newstart += $alen;
		  } else {
		    $run .= 'b' x $blen;
			 $leftover -= $blen;
			 $newstart += $blen;
		  }
	   }
		if (length($run) != $runlen) {
		  croak("Run length different than allotted space");
		} else {
		  substr($map, $runstart, $runlen) = $run;
		}
	 }

    if ($debugme) {
      my $prtstr=$str;
		$prtstr=~s/([\x00-\x1f])/'{'.$low_ascii[ord($1)].'}'/seg;
		$prtstr=~s/([\x80-\x8f])/$C128_chars[ord($1)-128]/eg;
      print "\n   $prtstr\n   $map\nA: $amap\nB: $bmap\nC: $cmap\n\n";
    }
  }

  my $current_charset=substr($map,0,1);
  my $codedstr=chr(index($mapping{$current_charset},$C128{"start_${current_charset}"}));
  my $current_char;

  #print "Adding: start $current_charset\n";

  my @map=split(//, $map);
  my @str=split(//, $str);

  for (my $i=0 ; $i<length($str) ; $i++) {
    # change character set if we need to
    if ($map[$i] ne $current_charset) {
      $codedstr .= chr(index($mapping{$current_charset}, $C128{"code_${map[$i]}"}));
      $current_charset=$map[$i];
  		#print "Adding: code $current_charset\n";
	 }
    # Now, stick the current character onto codedstr.  If this is
	 # charset C, we'll have to grab the next character, too.
	 if ($current_charset eq 'c' && $str[$i] ge '0' && $str[$i] le '9') {
	   $current_char = substr($str,$i,2)+0;
		$i++;
	 } else {
	   $current_char = index($mapping{$current_charset}, $str[$i]);
	 }
	 if ($current_char<0) {
	   croak("Unexpected character at $i in $str: $str[$i] doesn't exist in charset $current_charset");
	 }
	 #print "Adding: $current_char\n";
    $codedstr .= chr($current_char);
  }

  $codedstr .= $self->checkdigit($codedstr);

  # stop really isn't part of a charset, just doing this for
  # convenience.
  $codedstr .= chr(index($mapping{$current_charset}, $C128{'stop'}));

  print $self->decode_string($codedstr),"\n" if $debugme;

  return $codedstr;
}

=item C<decode_string(string)>

Show a printable version of a coded string

=cut

sub decode_string {

  my $self = shift;
  my $str = shift;
  my $charset='a';
  my $retstr='';

  #for (my $i=0 ; $i<length($str) ; $i++) {
  #  printf("%d ", ord(substr($str, $i, 1)));
  #}
  #print "\n";

  for (my $i=0 ; $i<length($str) ; $i++) {
    my $thischar = substr($mapping{$charset},ord(substr($str,$i,1)),1);
	 if ($thischar eq $C128{'START_A'}) {
	   $charset='a';
	 } elsif ($thischar eq $C128{'START_B'}) {
	   $charset='b';
	 } elsif ($thischar eq $C128{'START_C'}) {
	   $charset='c';
	 } elsif ($thischar eq $C128{'CODE_A'}) {
	   $charset='a';
	 } elsif ($thischar eq $C128{'CODE_B'}) {
	   $charset='b';
	 } elsif ($thischar eq $C128{'CODE_C'}) {
	   $charset='c';
	 }
	 if (ord($thischar)>127) {
      $retstr .= $C128_chars[ord($thischar)-128];
	 } elsif ($charset eq 'c') {
	   $retstr .= sprintf('(%02d)', ord($thischar));
	 } else {
      $retstr .= $thischar;
	 }
  }
  $retstr=~s/([\x00-\x1f])/'{'.$low_ascii[ord($1)].'}'/seg;
  $retstr=~s/(\x7f)/{DEL}/g;
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

  ($payload, $checkme) = ($str =~/^(.*)(.)$/s);

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
