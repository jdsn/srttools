#!/usr/bin/perl -w
use strict;

# this is a port of merge2ass.sh
# to merge two srt files for the same video into one ASS format sub
# with one on top and one on the bottom
# to be played with mplayer -ass

# CPAN install Video::Subtitle::SRT
# zypper in perl-Video-Subtitle-SRT

use Video::Subtitle::SRT;

my @srt=@ARGV;

sub diag {print STDERR @_,"\n"}
#sub diag {}


sub generate_ssa_header()
{
    print "[Script Info]
Title:
Original Script: 
Original Translation:
Original Editing: 
Original Timing: 
Original Script Checking:
ScriptType: v4.00
Collisions: Normal
PlayResY: 1024
PlayDepth: 0
Timer: 100,0000

[V4 Styles]
Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, TertiaryColour, BackColour, Bold, Italic, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, AlphaLevel, Encoding
Style: lang1style,Arial,64,65535,65535,65535,-2147483640,-1,0,1,3,0,6,30,30,30,0,0
Style: lang2style,Arial,64,15724527,15724527,15724527,4144959,0,0,1,1,2,2,5,5,30,0,0

[Events]
Format: Marked, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text 
";
}

sub generate_ssa_dialogs()
{
	my $n=1;
	foreach my $srt (@srt) {
		open(my $fh, "<", $srt) or die "Can not open $srt: $!";
		my $subtitle = Video::Subtitle::SRT->new (sub {
			my $e=shift;
			my $text=$e->{text};
			$text=~s/\r?\n/\\n/g;
			$text=~s/<\/?[ib]>//g;
			my @t=($e->{start_time}, $e->{end_time});
			foreach (@t) {
				s/^0(\d):/$1:/g;
				s/,(\d{3})/".".substr($1,0,2)/ge;
			}
			my $t=join(",", @t);
			print "Dialogue: Marked=0,$t,lang${n}style,Name,000,000,000,,$text  \n";
		});
		$subtitle->parse ($fh);
		$n++;
	}
}

generate_ssa_header;
generate_ssa_dialogs;
