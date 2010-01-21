package Barcode::Codabar;

# Barcode generation classes
#
# Copyright 2003 Michael Chaney Consulting Corporation
# Written by: Michael Chaney
#
# See enclosed documentation for full copyright and contact information

use strict;
use vars qw($VERSION @ISA @EXPORT);
use Exporter;
use Carp qw(croak confess);

@ISA = qw(Exporter);
@EXPORT = qw();
$VERSION = '0.05';

=head1 NAME

Barcode::Codabar - Create pattern for Codabar barcodes

=head1 SYNOPSIS

    use Barcode::Codabar;
    
    my $bc = new Barcode::Codabar;
	 my $text = 'A123459D';
	 my $checkdigit = $bc->checkdigit($text);
	 my $pattern = $bc->barcode($text.$checkdigit);

	 print $pattern,"\n";

=head1 DESCRIPTION

Barcode::Codabar creates the patterns that you need to display Codabar
(also known as USD-4, NW-7, and 2 of 7 code) barcodes.  The pattern returned is a
string of 1's and 0's, where 1 represent
part of a black bar and 0 represents a space.  Each character is a single unit
wide, so "111001" is a black bar 3 units wide, a space two units wide, and a
black bar that is one unit wide.  It is up to the programmer to create code to
display the resultant barcode.

Codabar does not have a defined check digit, and due to the design of the
barcode, there is no need for one.

=head2 RENDERING

There is no standard for rendering.  Make sure it's readable, remember that
the barcode is variably-sized depending on length, so putting one into
a fixed space without knowing the size may result in huge bars or tiny bars.
The human readable text is typically shown below the barcode.

=head1 PREREQUISITES

This module requires C<strict>, C<Exporter>, and C<Carp>.

=head2 EXPORT

None.

=cut

my %patterns = (
'0'=> {'val'=>0 ,'wn'=>'nnnnnww', 'bars'=>'101010011'},
'1'=> {'val'=>1 ,'wn'=>'nnnnwwn', 'bars'=>'101011001'},
'2'=> {'val'=>2 ,'wn'=>'nnnwnnw', 'bars'=>'101001011'},
'3'=> {'val'=>3 ,'wn'=>'wwnnnnn', 'bars'=>'110010101'},
'4'=> {'val'=>4 ,'wn'=>'nnwnnwn', 'bars'=>'101101001'},
'5'=> {'val'=>5 ,'wn'=>'wnnnnwn', 'bars'=>'110101001'},
'6'=> {'val'=>6 ,'wn'=>'nwnnnnw', 'bars'=>'100101011'},
'7'=> {'val'=>7 ,'wn'=>'nwnnwnn', 'bars'=>'100101101'},
'8'=> {'val'=>8 ,'wn'=>'nwwnnnn', 'bars'=>'100110101'},
'9'=> {'val'=>9 ,'wn'=>'wnnwnnn', 'bars'=>'110100101'},
'-'=> {'val'=>10 ,'wn'=>'nnnwwnn', 'bars'=>'101001101'},
'$'=> {'val'=>11 ,'wn'=>'nnwwnnn', 'bars'=>'101100101'},
':'=> {'val'=>12 ,'wn'=>'wnnnwnw', 'bars'=>'1101011011'},
'/'=> {'val'=>13 ,'wn'=>'wnwnnnw', 'bars'=>'1101101011'},
'.'=> {'val'=>14 ,'wn'=>'wnwnwnn', 'bars'=>'1101101101'},
'+'=> {'val'=>15 ,'wn'=>'nnwnwnw', 'bars'=>'1011011011'},

'T'=> {'val'=>16 ,'wn'=>'nnwwnwn', 'bars'=>'1011001001'},
'N'=> {'val'=>17 ,'wn'=>'nwnwnnw', 'bars'=>'1001001011'},
'*'=> {'val'=>18 ,'wn'=>'nnnwnww', 'bars'=>'1010010011'},
'E'=> {'val'=>19 ,'wn'=>'nnnwwwn', 'bars'=>'1010011001'},

'A'=> {'val'=>16 ,'wn'=>'nnwwnwn', 'bars'=>'1011001001'},
'B'=> {'val'=>17 ,'wn'=>'nwnwnnw', 'bars'=>'1001001011'},
'C'=> {'val'=>18 ,'wn'=>'nnnwnww', 'bars'=>'1010010011'},
'D'=> {'val'=>19 ,'wn'=>'nnnwwwn', 'bars'=>'1010011001'},
);

=head1 CONSTRUCTOR

=over 4

=item C<new(options)>

Create a new Barcode::Codabar object. The different options that can be
set are:

=over 4

=item barchar

Character to represent bars (defaults to '1')

=item spacechar

Character to represent spaces (defaults to '0')

=back

Example:

	 $bc = new Barcode::Codabar();

    Create a new Codabar barcode object that will automatically add
    check digits.

=back

=cut


sub new {

  my ($class, %opts) = @_;
  my $self = {
    addcheck => 0,
	 barchar => '1',
	 spacechar => '0',
	 barcode_type => 'Codabar',
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

Does nothing.  Codabar codes don't need a checksum.

Example:

	print $bc->checkdigit('435'),"\n";

	Prints nothing

=cut


sub checkdigit {

  my $self = shift;
  my $str = shift;

  if (!$self->validate($str)) {
    croak("Invalid $self->{barcode_type} data >> $str <<");
  }

  return undef;
}

=item C<checkdigit_mod10(number)>

Calculates a modulo 10 checksum digit for a Codabar code, apparently this
is sometimes used by libraries (as in, big building with lots of books).
This algorithm really should only be used for purely numeric codes.  This
check digit is correct according to documentation that the author has viewed,
however, the author's barcode scanner doesn't accept it.

=cut

sub checkdigit_mod10 {

  my $self = shift;
  my $str = shift;

  if (!$self->validate($str)) {
    croak("Invalid $self->{barcode_type} data >> $str <<");
  }

  # remove the first & last character if they're the start/stop characters.
  $str=~s/^[A-DTNE\*]?(.*)[A-DTNE\*]?/$1/;

  my @str=split(//,$str);
  my $weight=2;
  my $a=0;

  while (@str) {
    my $digit = $patterns{shift(@str)}{'val'};
    $digit *= $weight;
    $digit -= 9 if ($digit>=10);
    $a += $digit;
    $weight = 3-$weight;
  }

  return ((10-($a%10))%10);
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
    croak("Invalid $self->{barcode_type} data >> $str <<");
  }

  if ($str!~/^[A-DTNE\*]/) {
    $str = 'A'.$str.'B';
  }

  my $retstr=uc($str);

  $retstr =~ s/(.)/$patterns{$1}{'bars'}.'0'/eg;
  # remove the trailing 0
  chop($retstr);

  my $wnstr=uc($str);

  $wnstr =~ s/(.)/$patterns{$1}{'wn'}.'n'/eg;
  chop($wnstr);

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

This routine does not check the validity of the start/stop pair.

=cut

sub validate {

  my $self = shift;
  my $str = shift;
  
  return ($str =~ /^[A-DTNE\*][0-9\-\$\:\/\.\+]+[A-DTNE\*]$/i ||
           		$str =~ /^[0-9\-\$\:\/\.\+]+$/);
}

=back

=head1 BUGS

The checksum algorithm is ill-defined.  One is presented here, however
it is for just one application.

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
