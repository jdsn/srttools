#!/usr/bin/perl -w
use strict;
our $limit=0.94;

# merge several srt files for the same video into one
# by looking at timestamps and finding the closest ones

# CPAN install Video::Subtitle::SRT
# zypper in perl-Video-Subtitle-SRT perl-String-Similarity

# Copyright 2012 Bernhard M. Wiedemann
# License: GNU General Public License version 2


use Video::Subtitle::SRT "srt_time_to_milliseconds";
use String::Similarity;

my @srt=@ARGV;
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

foreach my $srt (@srt) {
	open(my $fh, "<", $srt);
	my $subtitle = Video::Subtitle::SRT->new (\&callback);
	$subtitle->parse ($fh);
	$n++;$m=0;
}

foreach my $s (@sub) {
	#print scalar @$s,"\n"; # debug
}


# assume srts are sorted
my $first=shift @sub;
my $out=Video::Subtitle::SRT->new;
my @index=();
foreach my $entry (@$first) {
	#foreach(keys %$entry) { print "$_=$entry->{$_}\n"; } #debug
	# gather other entries
	my $time=srt_time_to_milliseconds($entry->{start_time});
	$n=0;
	foreach my $subent (@sub) {
		my $start=$index[$n]||0;
		my $end=$start+900;
		if($end>=@$subent) {$end=@$subent-1}
		my $found=0;
		my $tries=0;
		foreach my $s (@$subent[$start..$end]) {
			my $timediff=srt_time_to_milliseconds($s->{start_time})-$time;
			$tries++;
			if(abs($timediff)<1900) {
				#diag $timediff; # debug
				# merge this one
				if($entry->{text} ne $s->{text} &&
				   similarity($entry->{text}, $s->{text}, $limit)<=$limit) {
					$entry->{text}.="\n".$s->{text};
				}
				$found=1;
				$index[$n]+=$tries;
				last;
			}
			#diag "needed more than one try for $entry->{number} - timediff=$timediff";
			#if(abs($timediff>10000)) {$index[$n]--}
		}
		if(!$found) {
			print STDERR "check entry=$entry->{number}\n";
		}
		$n++
	}
	$out->add($entry);
}

$out->write_file();
