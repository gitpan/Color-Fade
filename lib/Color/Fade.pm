package Color::Fade;

use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT_OK = qw (
	color_fade
	format_html
	format_css
	format_ubb
	format_aim
);

our @EXPORT = qw(
);

our $VERSION = '0.01b';

sub format_html {
	my @codes = @_;

	my $str = '';
	foreach (@codes) {
		my ($color,$char) = $_ =~ /^<color ([^>]+?)>(.+?)$/i;
		$str .= "<font color=\"$color\">$char</font>";
	}
	return $str;
}
sub format_css {
	my @codes = @_;

	my $str = '';
	foreach (@codes) {
		my ($color,$char) = $_ =~ /^<color ([^>]+?)>(.+?)$/i;
		$str .= "<span style=\"color: $color\">$char</span>";
	}
	return $str;
}
sub format_ubb {
	my @codes = @_;

	my $str = '';
	foreach (@codes) {
		my ($color,$char) = $_ =~ /^<color ([^>]+?)>(.+?)$/i;
		$str .= "[color=$color]$char\[/color]";
	}
	return $str;
}
sub format_aim {
	my @codes = @_;

	my $str = '';
	foreach (@codes) {
		my ($color,$char) = $_ =~ /^<color ([^>]+?)>(.+?)$/i;
		$str .= "<font color=\"$color\">$char";
	}
	return $str;
}

sub color_fade {
	my ($text,@in_colors) = @_;

	# Validate the arguments.
	if (not length $text) {
		warn "You must pass a string with a length > 0 to color_fade.";
		return;
	}
	if (not scalar(@in_colors)) {
		warn "You must pass a series of hexadecimal color codes to color_fade.";
		return;
	}

	# There must be at least two colors.
	if (scalar(@in_colors) < 2) {
		warn "color_fade requires at least two colors.";
		return;
	}

	# Validate and clean up color codes.
	my @nodes = ();
	foreach my $ccode (@in_colors) {
		$ccode =~ s/#//g; # Remove hex indicators.
		if (length $ccode != 6) {
			warn "You must pass 6 digit hexadecimal color codes to color_fade.";
			return;
		}
		if ($ccode =~ /^[^A-Fa-f0-9]$/i) {
			warn "You must pass 6 digit hexadecimal color codes to color_fade.";
			return;
		}
		push (@nodes,$ccode);
	}

	# Get the length of the string.
	my $len = length $text;

	# Divide the length into segments (number of colors - 1)
	my $sectionsWasFrac = 0;
	my $sections = $len / (scalar(@nodes) - 1);
	if ($sections =~ /\./) {
		# If it was a decimal, add one and int it.
		$sectionsWasFrac = 1;
		$sections += 1;
	}
	$sections = int($sections);

	# Split the string into individual characters.
	my @chars = split(//, $text);
	my @faded = ();

	my $nodeStart = 0;
	for (my $i = 0; $i < $len; $i += $sections) {
		# Find the length of this segment.
		my $seglen = ($i + $sections) - $i;

		# Separate the RGB components of the start and end colors.
		my (@RGB_Hex_Start) = $nodes[$nodeStart]     =~ /^(..)(..)(..)$/i; # /^([0-9A-Fa-f]{2}){3}$/i;
		my (@RGB_Hex_End)   = $nodes[$nodeStart + 1] =~ /^(..)(..)(..)$/i; # /^([0-9A-Fa-f]{2}){3}$/i;

		# Convert hexadecimal to decimal.
		my @RGB_Dec_Start = (
			oct ("0x" . $RGB_Hex_Start[0]),
			oct ("0x" . $RGB_Hex_Start[1]),
			oct ("0x" . $RGB_Hex_Start[2]),
		);
		my @RGB_Dec_End = (
			oct ("0x" . $RGB_Hex_End[0]),
			oct ("0x" . $RGB_Hex_End[1]),
			oct ("0x" . $RGB_Hex_End[2]),
		);

		# Find the distances in Red/Green/Blue values.
		my $distR = $RGB_Dec_Start[0] - $RGB_Dec_End[0];
		my $distG = $RGB_Dec_Start[1] - $RGB_Dec_End[1];
		my $distB = $RGB_Dec_Start[2] - $RGB_Dec_End[2];

		$distR < 0 ? $distR = abs($distR) : $distR = -$distR;
		$distG < 0 ? $distG = abs($distG) : $distG = -$distG;
		$distB < 0 ? $distB = abs($distB) : $distB = -$distB;

		# Divide each distance by the length of this segment,
		# so we can find out how many characters to operate on.
		my $charsR = int($distR / $seglen);
		my $charsG = int($distG / $seglen);
		my $charsB = int($distB / $seglen);

		# For each character in this segment...
		my ($r,$g,$b) = @RGB_Dec_Start;
		for (my $c = $i; $c < ($i + $seglen); $c++) {
			next unless defined $chars[$c];
			# Convert each color value back into hex.
			my $hexR = sprintf ("%x", $r);
			my $hexG = sprintf ("%x", $g);
			my $hexB = sprintf ("%x", $b);

			# Zero-pad each value so that the hex is 2 bytes long.
			$hexR = '0' . $hexR until length $hexR == 2;
			$hexG = '0' . $hexG until length $hexG == 2;
			$hexB = '0' . $hexB until length $hexB == 2;

			# Turn the hex values into a color code.
			my $code = join ("", $hexR, $hexG, $hexB);

			# Prepare an easy to parse color marker for this character.
			my $marker = "<color #" . $code . ">" . $chars[$c];

			# Append this color information to the output array.
			push (@faded,$marker);

			# Increment each color by charsR, charsG, and charsB at a time.
			$r += $charsR;
			$g += $charsG;
			$b += $charsB;

			# Keep the numbers within a valid range.
			$r = 0 if $r < 0;
			$g = 0 if $g < 0;
			$b = 0 if $b < 0;
			$r = 255 if $r > 255;
			$g = 255 if $g > 255;
			$b = 255 if $b > 255;
		}

		$nodeStart++;
	}

	return wantarray ? @faded : join ("",@faded);
}

1;
__END__

=head1 NAME

Color::Fade - Perl extension for fading text colors.

=head1 SYNOPSIS

  use Color::Fade qw(color_fade format_html);

  print format_html (color_fade (
    'Jackdaws love my big sphynx of quartz.',
    '#FF0000', '#00FF00', '#0000FF',
  ));

=head1 DESCRIPTION

Color::Fade uses mathematical formulas to take an input string of virtually any length,
and virtually any number of colors, and assign an individual color to each character to
fade between each of the input colors.

In other words, it makes your sentences look really pretty. :)

=head2 EXPORT

Exports color_fade, format_html, format_css, format_ubb, and format_aim on demand.

=head1 METHODS

=head2 color_fade ($string, @colors)

Fade C<$string> among the colors in C<@colors>, where C<$string> is a string of length
greater than zero, and C<@colors> is an array of colors in six byte hexadecimal format,
with or without the leading octothorpe. C<@colors> must have at least two elements.

When called in array context, the method returns an array in which each element is of
the format:

  <color #xxxxxx>y

For each character, where C<xxxxxx> is a hexadecimal color code and C<y> is one character
from the original string.

When called in scalar context, this array is joined before being returned.

B<Note:> It is perfectly possible to have more colors than you have characters in the
original string. All that will happen is that each character of output will have a color
from the original array, in the order the array was passed in, until there are no characters
left.

=head2 format_html (@codes)

Formats C<@codes> in standard HTML, where C<@codes> is an array returned from C<color_fade>.
Do not pass a scalar into this array; it won't run the way you expect it to.

Outputs a scalar of HTML source code in the format:

  <font color="#xxxxxx">y</font>

=head2 format_css (@codes)

For those of us who try to stay on the W3C's good side and be HTML 4.01 compliant, this
method formats it in code that is HTML 4.01 compliant!

Outputs a scalar of HTML source code in the format:

  <span style="color: #xxxxxx">y</span>

=head2 format_ubb (@codes)

Since so many of us programmers are regular members of message boards, a function was
included to format it for UBB code.

Outputs a scalar of UBB code in the format:

  [color=#xxxxxx]y[/color]

=head2 format_aim (@codes)

This special routine is to format the code for use on AOL Instant Messenger. It is the
same as format_html, but it lacks any of the </font> tags (as these tend to close every
open font tag, not just the most recently opened one).

Outputs a scalar in the format:

  <font color="#xxxxxx">y

=head1 SEE ALSO

I<Cuvou's Text Fader>, an online implementation of this module.
http://www.cuvou.com/wizards/fader.cgi

=head1 AUTHOR

Casey Kirsle, E<lt>casey at cuvou.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Casey Kirsle

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
