#!/usr/bin/perl -w
use strict;

# adjust one srt file timestamps with an offset

# CPAN install Video::Subtitle::SRT
# zypper in perl-Video-Subtitle-SRT

# Copyright 2012 Bernhard M. Wiedemann
# License: GNU General Public License version 2


use Video::Subtitle::SRT qw"milliseconds_to_srt_time srt_time_to_milliseconds";

my $inputfile=shift;
my $offset=shift;
my $rules=shift||"";
our @sub;
our $n=0;
our $m=0;

sub diag {print STDERR @_,"\n"}
#sub diag {}
sub callback
{
	my $entry=shift;
	#foreach(keys %$entry) { print "$_=$entry->{$_}\n"; } #debug
	$sub[$n][$m++]=$entry;
}

foreach my $srt ($inputfile) {
	open(my $fh, "<", $srt);
	my $subtitle = Video::Subtitle::SRT->new (\&callback);
	$subtitle->parse ($fh);
	$n++;$m=0;
}

foreach my $s (@sub) {
	#print scalar @$s,"\n"; # debug
}


my $first=shift @sub;
my $out=Video::Subtitle::SRT->new;
my @index=();
foreach my $entry (@$first) {
	my $t=srt_time_to_milliseconds($entry->{start_time});
	eval($rules);
	$entry->{start_time}=milliseconds_to_srt_time($t+$offset);
	$entry->{end_time}=milliseconds_to_srt_time(srt_time_to_milliseconds($entry->{end_time})+$offset);
	#diag $time;
	$out->add($entry);
}

$out->write_file();
