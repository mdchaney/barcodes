#!/usr/bin/perl

use PostScript::BasicTypesetter;
use PostScript::Resources;

my $tr = new PostScript::BasicTypesetter("/usr/share/wx/gs_afm/Helv.afm");

print STDOUT ("%!PS-Adobe-3.0\n",
		"%%DocumentResources: font ",
		$tr->metrics->FontName, " ",
		"%%Pages: 1\n",
		$tr->ps_preamble,
		"%%EndPrologue\n",
		"%%Page 1 1\n");

$tr->fontsize(150, 200);
print STDOUT ($tr->ps_textbox (mm(10), 0, mm(200), mm(180),
			"Perl Rules!", "c"));

print STDOUT ("showpage\n",
		"%%Trailer\n",
		"%%EOF\n");

# Convert millimeters to PostScript units.
sub mm { ($_[0] * 720) / 254 }
