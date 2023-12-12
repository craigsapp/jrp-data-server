#!/usr/bin/perl
#
# Programmer:    Craig Stuart Sapp <craig.stanford.edu>
# Creation Date: Sun 12 Sep 2021 07:37:36 PM PDT
# Last Modified: Mon 05 Sep 2022 05:09:02 AM PDT
# Filename:      jrp-data-server/cgi-bin/jrp-data-server.pl
# Syntax:        perl 5
# vim:           ts=3
#
# Description:   Data server for https://data.josqu.in
#
# Formats that the server can deal with:
#    Indexing resources:
#       jrp-index.json  == JRP browse search index in JSON format.
#    Search indexes:
#       jrp-lyrics-index.txt   == lyrics search index in TXT format.
#       pitch.thema == Melodic pitch search index (all works).
#    Quasi-score ids:
#       random    ==  Get random score from cache.
#    Static cached formats:
#       krn       == Humdrum data file.
#       mei       == Conversion to MEI data.
#       mid       == Conversion to MIDI data.
#       keyscape-abspre  == Keyscape (absolute, preprocessed)
#       keyscape-relpre  == Keyscape (relative, preprocessed)
#       keyscape-abspost == Keyscape (absolute, postprocessed)
#       keyscape-relpost == Keyscape (relative, postprocessed)
#       keyscape-info    == Keyscape image timing info
#       musicxml  == Conversion to MusicXML data.
#          https://data.josqu.in/Jos2721.musicxml
#       incipit   == Conversion to SVG musical incipit.
#          https://data.josqu.in/Jos2721.incipit
#    Dynamically generated formats:
#       lyrics    == Extract lyrics HTML page
#          https://data.josqu.in/Jos2721.lyrics
#          https://data.josqu.in/Jos2721.lyrics-modern
#       info-aton == Basic metadata about the file in ATON format.
#          https://data.josqu.in/Jos2721.aton
#       info-json == Basic metadata about the file in JSON format.
#          https://data.josqu.in/Jos2721.json
#    Debug items:
#       test     == Print environmental variables.
#

use strict;

my $newline = "\r\n";

##############################
##
## Configuration variables:
##

# basedir == The location of the files for the website.
my $basedir    = "/project/data-server-jrp/data-server-jrp";

# logdir == directory where access logs are stored.
my $logdir     =  "/project/data-server-jrp/data-server-jrp/logs";

# cachedir == The absolute path to the cache directory.
my $cachedir   = "$basedir/cache";

# cachedir == The absolute path to the cache index file.
my $cacheIndex = "$cachedir/cache-index.hmd";

# cacheDepth == The number of subdirectories before reaching individual cache directory.
my $cacheDepth = 1;


# Dynamic data generation programs
#
# For SELinux, run these commands on the scripts to allow this CGI script to run them:
#    chcon system_u:object_r:httpd_exec_t:s0 getInfo
# And one time, give permission for this CGI script to run command in OS:
#    setsebool -P httpd_execmem 1
# Use the -Z option on ls to see the SELinux permissions:
#    ls -Z getInfo
#
my $getInfo	= "$basedir/bin/getInfo";   # for basic medatadata about a file.

##
##############################


# Load CGI parameters into %OPTIONS:
use CGI;
my $cgi_form = new CGI;
my %OPTIONS;
$OPTIONS{"id"} = $cgi_form->param("id");
$OPTIONS{"format"} = $cgi_form->param("format");
# "f" is a shortcut for format:
if ($OPTIONS{"format"} =~ /^\s*$/) {
	$OPTIONS{"format"}  = $cgi_form->param("f");
}
splitFormatFromId();

writeLog($logdir, $OPTIONS{"id"}, $OPTIONS{"format"});

# Return requested data:
if ($OPTIONS{"format"} =~ /thema/i) {
	sendThemaIndex($OPTIONS{"id"}, $OPTIONS{"format"});
} elsif ($OPTIONS{"id"} =~ /index/i) {
	sendIndex($OPTIONS{"id"}, $OPTIONS{"format"});
} elsif ($OPTIONS{"id"} eq "test") {
	# id == test :: print ENV and input parameters for debugging and development.
	sendTestPage($OPTIONS{"id"}, $OPTIONS{"format"});
} elsif ($OPTIONS{"id"} eq "random") {
	# id == random :: send a randomly selected work.
	sendRandomWork($OPTIONS{"format"});
} else {
	# ID should refer to a specific file, so return data in requested format:
	processParameters($OPTIONS{"id"}, $OPTIONS{"format"});
}


exit(0);

###########################################################################


##############################
##
## processParameters -- URLs such as:
##     https://data.josqu.in/004-1a-COC-003.krn for kern file
##     https://data.josqu.in/004-1a-COC-003.mei for MEI file
##     https://data.josqu.in/16xx:1210.krn for kern file
##     https://data.josqu.in/16xx:1210.mei for MEI file
##

sub processParameters {
	my ($id, $format) = @_;

	errorMessage("ID is empty.") if $id =~ /^\s*$/;
	errorMessage("Strange invalid ID \"$id\".") if $id =~ /^[._-]+$/;
	errorMessage("ID \"$id\" contains invalid characters.") if $id =~ /[^a-zA-Z0-9,:_-]/;

	$id =~ s/^[^0-9a-zA-Z:_-]+//;
	$id =~ s/[^0-9a-zA-Z:_-]+$//;
	my @ids = split(/[^0-9a-zA-Z:_-]+/, $id);

	my @md5s = getMd5s($cacheIndex, @ids);
	if (@md5s < 1) {
		if (($id =~ /^rism/i) && ($format =~ /json/i)) {
			# Send an empty JSON object if rism number is unknown:
			my $mime = "application/json" if $format eq "json";
			my $charset = ";charset=UTF-8";
			print "Content-Type: $mime$charset$newline";
			print "$newline";
			print "[]$newline";
			exit(0);
		} 
		errorMessage("Entry for $id :: $format was not found.") if @md5s < 1;
	}

	# cached formats
	if ($format eq "krn") {
		sendDataContent($format, $id, @md5s);
	} elsif ($format eq "mei") {
		sendDataContent($format, $id, @md5s);
	} elsif ($format eq "musicxml") {
		sendDataContent($format, $id, @md5s);
	} elsif ($format eq "incipit") {
		sendDataContent($format, $id, @md5s);
	} elsif ($format eq "keyscape-abspre") {
		sendDataContent($format, $id, @md5s);
	} elsif ($format eq "keyscape-relpre") {
		sendDataContent($format, $id, @md5s);
	} elsif ($format eq "keyscape-abspost") {
		sendDataContent($format, $id, @md5s);
	} elsif ($format eq "keyscape-relpost") {
		sendDataContent($format, $id, @md5s);
	} elsif ($format eq "keyscape-info") {
		sendDataContent($format, $id, @md5s);
	} elsif ($format eq "mid") {
		sendDataContent($format, $id, @md5s);
	} elsif ($format eq "midi") {
		sendDataContent("midi", $id, @md5s);
	} elsif ($format eq "lyrics") {
		sendDataContent("lyrics", $id, @md5s);
	} elsif ($format eq "lyrics-modern") {
		sendDataContent("lyrics-modern", $id, @md5s);
	}

	# dynamic formats
	elsif ($format =~ /^info-(aton|json)/) {
		sendDataContent($format, $id, @md5s);
	} elsif ($format =~ /^(aton|json)/) {
		sendDataContent($format, $id, @md5s);
	}

	errorMessage("Unknown data format: $format");
}



##############################
##
## sendDataContent -- Manages and checks format types for static and dynamic data formats.
##

sub sendDataContent {
	my ($format, $id, @md5s) = @_;
	errorMessage("Not in cache ") if @md5s < 1;
	errorMessage("Bad MD5 tag $md5s[0]") if $md5s[0] !~ /^[0-9a-f]{8}$/;

	# Statically generated data formats:
	if ($format eq "krn") {
		sendHumdrumContent(@md5s);
	} elsif ($format eq "mei") {
		sendMeiContent($md5s[0]);
	} elsif ($format eq "musicxml") {
		sendMusicxmlContent($md5s[0]);
	} elsif ($format eq "incipit") {
		sendMusicalIncipitContent($md5s[0]);
	} elsif ($format =~ /^keyscape-info/) {
		sendKeyscapeInfoContent($md5s[0]);
	} elsif ($format =~ /^keyscape/) {
		sendKeyscapeContent($md5s[0], $format);
	} elsif ($format eq "mid") {
		sendMidiContent($md5s[0]);
	} elsif ($format eq "midi") {
		sendMidiContent($md5s[0]);
	} elsif ($format eq "lyrics") {
		sendLyricsContent($md5s[0]);
	} elsif ($format eq "lyrics-modern") {
		sendLyricsModernContent($md5s[0]);
	}

	# Dynamically generated data formats:
	elsif ($format eq "lyrics") {
		sendLyricsContent($md5s[0]);
	} elsif ($format =~ /info-(aton|json)/) {
		sendInfoContent($format, $id, @md5s);
	} elsif ($format =~ /(aton|json)/) {
		sendInfoContent($format, $id, @md5s);
	}

	errorMessage("Unknown data format B: $format");
}



##############################
##
## sendIndex -- Index content delivery function.
##

sub sendIndex {
	my ($base, $format) = @_;
	$base =~ s/[^a-zA-Z0-9_-]//g;
	$format =~ s/[^a-zA-Z0-9_-]//g;
	my $file = "$cachedir/indexes/$base.$format.gz";
	if (!-r $file) {
		$file = "$cachedir/indexes/$base.$format";
		if (!-r $file) {
			errorMessage("Cannot find index: $base.$format");
		}
	}
	my $charset = ";charset=UTF-8";
	my $mime = "text/plain";
	$mime = "text/x-aton" if $format eq "aton";
	$mime = "application/json" if $format eq "json";
	my $data = `cat "$file"`;
	print "Content-Type: $mime$charset$newline";
	print "Content-Encoding: gzip$newline";
	print "$newline";
	print $data;
	exit(0);
}



##############################
##
## sendThemaIndex -- Music search index content delivery function.
##

sub sendThemaIndex {
	my ($base, $format) = @_;
	$base =~ s/[^a-zA-Z0-9_-]//g;
	$format =~ s/[^a-zA-Z0-9_-]//g;
	my $file = "$cachedir/indexes/$format-$base.txt.gz";
	if (!-r $file) {
		errorMessage("Cannot find music search index: $base.");
	}
	my $charset = ";charset=UTF-8";
	my $mime = "text/plain";
	my $compressQ = 0;
	$compressQ = 1 if $ENV{'HTTP_ACCEPT_ENCODING'} =~ /\bgzip\b/;
	if ($compressQ) {
		# Browser understands gzip compression, so send compressed:
		my $data = `cat "$file"`;
		print "Content-Type: $mime$charset$newline";
		print "Content-Encoding: gzip$newline";
		print "$newline";
		print $data;
	} else {
		# Browser does not understand gzip compression, so send uncompressed:
		my $data = `zcat "$file"`;
		print "Content-Type: $mime$charset$newline";
		print "$newline";
		print $data;
	}
	exit(0);
}



###########################################################################
##
## Static content delivery functions:
##


##############################
##
## sendHumdrumContent -- (Static content) Send Humdrum file for ID.
##

sub sendHumdrumContent {
	my (@md5s) = @_;

	my $filelist = "";
	for (my $i=0; $i<@md5s; $i++) {
		my $cdir = getCacheSubdir($md5s[$i], $cacheDepth);
		my $filename = "$cachedir/$cdir/$md5s[$i].krn";
		if (!-r $filename) {
			errorMessage("Cannot find $cdir/$md5s[$i].krn");
		}
		$filelist .= " $filename";
	}

	# Try to send the data in compressed format, if available:
	my $compressQ = 0;
	$compressQ = 1 if $ENV{'HTTP_ACCEPT_ENCODING'} =~ /\bgzip\b/;
	if ($compressQ) {
		my $data = `cat $filelist | gzip`;
		print "Content-Type: text/x-humdrum;charset=UTF-8$newline";
		print "Content-Disposition: inline; filename=\"$OPTIONS{'id'}.txt\"$newline";
		print "Content-Encoding: gzip$newline";
		print "$newline";
		print $data;
	} else {
		my $data = `cat $filelist`;
		print "Content-Type: text/x-humdrum;charset=UTF-8$newline";
		print "Content-Disposition: inline; filename=\"$OPTIONS{'id'}.txt\"$newline";
		print "$newline";
		print $data;
	}
	exit(0);
}



##############################
##
## sendMeiContent -- (Static content) Send MEI conversion of Humdrum data.
##

sub sendMeiContent {
	my ($md5) = @_;
	my $cdir = getCacheSubdir($md5, $cacheDepth);
	my $format = "mei";
	my $mime = "text/plain";

	# MEI data is stored in gzip-compressed file.  If the browser
	# accepts gzip compressed data, send the compressed form of the data;
	# otherwise, unzip and send as plain text.
	my $compressQ = 0;
	$compressQ = 1 if $ENV{'HTTP_ACCEPT_ENCODING'} =~ /\bgzip\b/;
	if (!-r "$cachedir/$cdir/$md5.$format.gz") {
		errorMessage("MEI file is missing for $OPTIONS{'id'}.");
	}
	if ($compressQ) {
		my $data = `cat "$cachedir/$cdir/$md5.$format.gz"`;
		print "Content-Type: $mime$newline";
		print "Content-Encoding: gzip$newline";
		print "$newline";
		print $data;
		exit(0);
	}

	my $data = `zcat "$cachedir/$cdir/$md5.$format.gz"`;
	print "Content-Type: $mime$newline";
	print "$newline";
	print $data;
	exit(0);
}



##############################
##
## sendMusicxmlContent -- (Static content) Send MusicXML conversion of Humdrum data.
##

sub sendMusicxmlContent {
	my ($md5) = @_;
	my $cdir = getCacheSubdir($md5, $cacheDepth);
	my $format = "musicxml";
	my $mime = "text/plain";

	# MusicXML data is stored in gzip-compressed file.  If the browser
	# accepts gzip compressed data, send the compressed form of the data;
	# otherwise, unzip and send as plain text.
	my $compressQ = 0;
	$compressQ = 1 if $ENV{'HTTP_ACCEPT_ENCODING'} =~ /\bgzip\b/;
	if (!-r "$cachedir/$cdir/$md5.$format.gz") {
		errorMessage("MusicXML file is missing for $OPTIONS{'id'}.");
	}
	if ($compressQ) {
		my $data = `cat "$cachedir/$cdir/$md5.$format.gz"`;
		print "Content-Type: $mime$newline";
		print "Content-Encoding: gzip$newline";
		print "$newline";
		print $data;
		exit(0);
	}

	my $data = `zcat "$cachedir/$cdir/$md5.$format.gz"`;
	print "Content-Type: $mime$newline";
	print "$newline";
	print $data;
	exit(0);
}



##############################
##
## sendMusicalIncipitContent -- (Static content) Send SVG image of musical incipit.
##

sub sendMusicalIncipitContent {
	my ($md5) = @_;
	my $cdir = getCacheSubdir($md5, $cacheDepth);
	my $format = "svg";
	my $mime = "image/svg+xml";

	# Incipit is stored in gzip-compressed file.  If the browser
	# accepts gzip compressed data, send the compressed form of the data;
	# otherwise, unzip and send as plain text.
	my $compressQ = 0;
	$compressQ = 1 if $ENV{'HTTP_ACCEPT_ENCODING'} =~ /\bgzip\b/;
	if (!-r "$cachedir/$cdir/$md5-incipit.$format.gz") {
		errorMessage("Incipit image is missing for $OPTIONS{'id'}.");
	}
	if ($compressQ) {
		my $data = `cat "$cachedir/$cdir/$md5-incipit.$format.gz"`;
		print "Content-Type: $mime$newline";
		print "Content-Encoding: gzip$newline";
		print "$newline";
		print $data;
		exit(0);
	}

	my $data = `zcat "$cachedir/$cdir/$md5-incipit.$format.gz"`;
	print "Content-Type: $mime$newline";
	print "$newline";
	print $data;
	exit(0);
}



##############################
##
## sendKeyscapeContent -- Return a keyscape of the given format.
##

sub sendKeyscapeContent {
	my ($md5, $format) = @_;
	my $cdir = getCacheSubdir($md5, $cacheDepth);
	my $mime = "image/png";

	my $data = `cat "$cachedir/$cdir/$md5-$format.png"`;
	print "Content-Type: $mime$newline";
	print "$newline";
	print $data;
	exit(0);
}



##############################
##
## sendKeyscapeInfoContent -- Return timing information for keyscape
##     images.
##

sub sendKeyscapeInfoContent {
	my ($md5) = @_;
	my $cdir = getCacheSubdir($md5, $cacheDepth);
	my $mime = "application/json";

	# MusicXML data is stored in gzip-compressed file.  If the browser
	# accepts gzip compressed data, send the compressed form of the data;
	# otherwise, unzip and send as plain text.
	my $compressQ = 0;
	$compressQ = 1 if $ENV{'HTTP_ACCEPT_ENCODING'} =~ /\bgzip\b/;
	if (!-r "$cachedir/$cdir/$md5-keyscape-info.json.gz") {
		errorMessage("MusicXML file is missing for $OPTIONS{'id'}.");
	}
	if ($compressQ) {
		my $data = `cat "$cachedir/$cdir/$md5-keyscape-info.json.gz"`;
		print "Content-Type: $mime$newline";
		print "Content-Encoding: gzip$newline";
		print "$newline";
		print $data;
		exit(0);
	}

	my $data = `zcat "$cachedir/$cdir/$md5-keyscape-info.json.gz"`;
	print "Content-Type: $mime$newline";
	print "$newline";
	print $data;
	exit(0);
}



##############################
##
## sendMidiContent -- (Static content) Send MIDI conversion of Humdrum data.
##

sub sendMidiContent {
	my ($md5) = @_;
	my $cdir = getCacheSubdir($md5, $cacheDepth);
	my $format = "mid";
	my $mime = "audio/midi";

	my $data = `cat "$cachedir/$cdir/$md5.$format"`;
	print "Content-Type: $mime$newline";
	print "Content-Disposition: attachment; filename=\"data.mid\"$newline";
	print "$newline";
	print $data;
	exit(0);
}



##############################
##
## sendLyricsContent -- Extract lyrics from score and serve as HTML file.
##

sub sendLyricsContent {
	my ($md5) = @_;
	my $cdir = getCacheSubdir($md5, $cacheDepth);
	my $format = "-lyrics.txt";
	my $mime = "text/plain";

	# Lyrics data is stored in gzip-compressed file.  If the browser
	# accepts gzip compressed data, send the compressed form of the data;
	# otherwise, unzip and send as plain text.
	my $compressQ = 0;
	$compressQ = 1 if $ENV{'HTTP_ACCEPT_ENCODING'} =~ /\bgzip\b/;
	if (!-r "$cachedir/$cdir/$md5$format.gz") {
		errorMessage("Lyrics file is missing for $OPTIONS{'id'}.");
	}
	if ($compressQ) {
		my $data = `cat "$cachedir/$cdir/$md5$format.gz"`;
		print "Content-Type: $mime$newline";
		print "Content-Type: $mime;charset=UTF-8$newline";
		print "Content-Encoding: gzip$newline";
		print "$newline";
		print $data;
		exit(0);
	}

	my $data = `zcat "$cachedir/$cdir/$md5$format.gz"`;
	print "Content-Type: $mime;charset=UTF-8$newline";
	print "$newline";
	print $data;
	exit(0);
}



##############################
##
## sendLyricsModernContent -- Extract modernized-character lyrics from score
##    and serve as HTML file.
##

sub sendLyricsModernContent {
	my ($md5) = @_;
	my $cdir = getCacheSubdir($md5, $cacheDepth);
	my $format = "-lyrics-modern.txt";
	my $mime = "text/plain";

	# Lyrics data is stored in gzip-compressed file.  If the browser
	# accepts gzip compressed data, send the compressed form of the data;
	# otherwise, unzip and send as plain text.
	my $compressQ = 0;
	$compressQ = 1 if $ENV{'HTTP_ACCEPT_ENCODING'} =~ /\bgzip\b/;
	if (!-r "$cachedir/$cdir/$md5$format.gz") {
		errorMessage("Lyrics file is missing for $OPTIONS{'id'}.");
	}
	if ($compressQ) {
		my $data = `cat "$cachedir/$cdir/$md5$format.gz"`;
		print "Content-Type: $mime$newline";
		print "Content-Type: $mime;charset=UTF-8$newline";
		print "Content-Encoding: gzip$newline";
		print "$newline";
		print $data;
		exit(0);
	}

	my $data = `zcat "$cachedir/$cdir/$md5$format.gz"`;
	print "Content-Type: $mime;charset=UTF-8$newline";
	print "$newline";
	print $data;
	exit(0);
}


##
## End of static content delivery functions.
##
###########################################################################
##
## Dynamic content delivery functions:
##


##############################
##
## sendInfoContent -- (Dynamic content) Send basic metadata about a file.  More
##   Than one file's info is allowed to be sent at a time.
##

sub sendInfoContent {
	my ($format, $id, @md5s) = @_;

	my $output = "";
	if (($id =~ /rism/) && ($format =~ /json/i)) {
		$output .= "[\n";
	} else {
		$output .= "[\n" if (@md5s > 1) && ($format =~ /json/i);
	}

	my $debug = "";
	for (my $i=0; $i<@md5s; $i++) {
		my $command = "$getInfo -c \"$cachedir\" -i cache-index.hmd";
		$command .= " -j" if $format =~ /json/i;
		$command .= " $md5s[$i]";
		my $subdir = getCacheSubdir($md5s[$i]);
		my $data = `(cd $cachedir/$subdir && $command)`;
		if (($format =~ /json/i) && ($i < @md5s - 1)) {
			$data =~ s/\s+$//;
			$data .= ",\n";
		} elsif (($format !~ /json/i) && (@md5s > 1)) {
			$data =~ s/^\s+//;
			$data =~ s/\s+$//;
			$data = "\@\@BEGIN:\t\tENTRY\n$data\n\@\@END:\t\t\tENTRY\n\n";
		}
		$output .= $data;
	}

	if (($id =~ /rism/) && ($format =~ /json/i)) {
		$output .= "]\n";
	} else {
		$output .= "]\n" if (@md5s > 1) && ($format =~ /json/i);
	}

	my $mime = "text/x-aton";
	$mime = "application/json" if $format =~ /json/i;
	my $ext = "aton";
	$ext = "json" if $format =~ /json/i;

	print "Content-Type: $mime; charset=utf-8$newline";
	print "Content-Disposition: inline; filename=\"$OPTIONS{'id'}-info.$ext\"$newline";
	print "$newline";
	print $output;
	exit(0);
}

##
## End of dynamic content delivery functions.
##
###########################################################################


##############################
##
## splitFormatFromId -- id.format gets divided into separate parameters.
##

sub splitFormatFromId {
	# id?format=format form
	my $id = $OPTIONS{"id"};
	my $format = $OPTIONS{"format"};

	my $newformat = "";
	if ($id =~ /^([^\/]+)\/([^\/]+)$/) {
		# id/format form
		$id = $1;
		$newformat = $2;
	} elsif ($id =~ s/\.([0-9a-zA-Z_-]+)$//) {
		# id.format form
		$newformat = $1;
	}

	# Store newformat in format if format is not empty.
	if ($newformat !~ /^\s*$/) {
		if ($format =~ /^\s*$/) {
			$format = $newformat;
		}
	}
	# Default format is Humdrum data
	if ($format =~ /^\s*$/) {
		$format = "krn";
	}

	$format = cleanFormat($format);
	$id     = cleanId($id);

	$OPTIONS{"id"} = $id;
	$OPTIONS{"format"} = $format;
}



##############################
##
## getCacheSubdir -- For example 63a45fe4 goes to 6/63a45fe4 when the depth is 1.
##

sub getCacheSubdir {
	my ($md5, $depth) = @_;
	$depth = 1 if $depth < 1;
	$depth = 3 if $depth > 3;
	my @pieces = split(//, $md5);
	my $output = "";
	for (my $i=0; $i<$depth; $i++) {
		$output .= "$pieces[$i]/";
	}
	$output .= "$md5";
	return $output;
}



##############################
##
## getMd5 -- Input an ID and return an MD5 8-hex-digit cache ID.
##    pmsids and rismids are not unique and multiple MD5s may be
##    returned for a single pmsid.
##

sub getMd5s {
	my ($cacheIndex, @ids) = @_;
	my @output;
	for (my $i=0; $i<@ids; $i++) {
		push(@output, getMd5($cacheIndex, $ids[$i]));
	}
	return @output;
}

sub getMd5 {
	my ($cacheIndex, $id) = @_;
	open (FILE, $cacheIndex) or errorMessage("Cannot find cache index $cacheIndex.");
	my @headings;
	if (($id =~ /^pms:/) || ($id =~ /^rism:/)) {
		# Multiple IDs possible for PMS and RISM IDs since they
		# refer to works or collections.
		my @output;
		while (my $line = <FILE>) {
			next if $line =~ /^!/;
			chomp $line;
			if ($line =~ /^\*\*/) {
				my @headings = split(/\t+/, $line);
				next;
			}
			next if $line =~ /^\*/;
			next if $line =~ /^\s*$/;
			next if $line !~ /^([^\t]+).*\t($id)(\t|$)/;
			$output[@output] = $1;
		}
		close FILE;
		return @output;
	} else {
		while (my $line = <FILE>) {
			next if $line =~ /^!/;
			chomp $line;
			if ($line =~ /^\*\*/) {
				my @headings = split(/\t+/, $line);
				next;
			}
			next if $line =~ /^\*/;
			next if $line =~ /^\s*$/;
			next if $line !~ /^([^\t]+).*\t($id)(\t|$)/;
			close FILE;
			return ($1);
		}
	}
	close FILE;
	# Did not find ID in list.  Check to see if it is an md5 ID:
	if ($id =~ /^[0-9a-f]{8}$/) {
		my $cdir = getCacheSubdir($id, $cacheDepth);
		my $cachedir   = "$basedir/cache";
		if (-d "$cachedir/$cdir") {
			return ($id);
		}
	}
	return "";
}



##############################
##
## errorMessage --
##

sub errorMessage {
	my ($message) = @_;
	print "Content-Type: text/html;charset=UTF-8$newline";
	print "$newline";
	print <<"EOT";
<html>
<head>
<title> ERROR </title>
</head>
<body>
<h1> ERROR </h1>
$message
</body>
</html>
EOT
	exit(0);
}



##############################
##
## sendTestPage -- Used for debugging.
##

sub sendTestPage {
	my ($id, $format) = @_;

	print "Content-Type: text/html;charset=UTF-8$newline";
	print "$newline";
	print <<"EOT";
<html>
<head>
<title> INFO </title>
</head>
<body>
<h1> INFO </h1>
<ul>
<li> id: $id </li>
<li> format: $format </li>
</ul>
<h1> ENV </h1>
<table>
EOT

	foreach my $key (sort keys %ENV) {
		print "<tr>\n";
		print "<td>$key</td>\n";
		print "<td>$ENV{$key}</td>\n";
		print "</tr>\n";
	}
	print "</table>\n</body>\n</html>\n";
	exit(0);
}



##############################
##
## sendRandomWork -- The URL:
##      https://data.josqu.in/random
##   will return random kern data.  Also, specific format can be given:
##      https://data.josqu.in/random.krn
##   and random data translations
##      https://data.josqu.in/random.mei
##      https://data.josqu.in/random.musicxml
##      https://data.josqu.in/random?format=krn
##      https://data.josqu.in/random?format=mei
##      https://data.josqu.in/random?format=mid
##      https://data.josqu.in/random?format=musicxml
##
##  Loading random file into VHV:
##      https://verovio.humdrum.org/?file=https://data.josqu.in/random
##

sub sendRandomWork {
	my ($format) = @_;
	my @list = getMd5List($cacheIndex);
	if (@list == 0) {
		errorMessage("Cannot find MD5 list");
	}
	my $randIndex =  int(rand(@list));
	my $md5 = $list[$randIndex];
	my $id = "";
	sendDataContent($md5, $id, $format);
}



##############################
##
## getMd5List --
##

sub getMd5List {
	my ($cacheIndex) = @_;
	open (FILE, $cacheIndex) or errorMessage("Cannot find cache index $cacheIndex for MD5list.");
	my @headings;
	my @output;
	my $md5index = -1;
	while (my $line = <FILE>) {
		next if $line =~ /^!/;
		chomp $line;
		if ($line =~ /^\*\*/) {
			my @headings = split(/\t+/, $line);
			for (my $i=0; $i<@headings; $i++) {
				$md5index = $i if $headings[$i] eq "**md5";
			}
			next;
		}
		next if $line =~ /^\*/;
		next if $line =~ /^\s*$/;
		next if $md5index < 0;
		my @data = split(/\t+/, $line);
		$output[@output] = $data[$md5index];
	}
	close FILE;
	return @output;
}



##############################
##
## cleanFormat -- Change aliases to primary forms.
##

sub cleanFormat {
	my ($format) = @_;

	# Remove any surrounding spaces
	$format =~ s/^\s+//;
	$format =~ s/\s+$//;

	# Merge aliases for .krn ending:
	$format = "krn" if $format =~ /^krn$/i;
	$format = "krn" if $format =~ /^kern$/i;
	$format = "krn" if $format =~ /^hmd$/i;
	$format = "krn" if $format =~ /^humdrum$/i;

	# Merge aliases for .mei ending:
	$format = "mei" if $format =~ /^mei$/i;

	# Merge aliases for .musicxml ending:
	$format = "musicxml" if $format =~ /^musicxml$/i;
	$format = "musicxml" if $format =~ /^xml$/i;

	return $format;
}



##############################
##
## cleanId -- Remove format information and optional _composer--work from POPC-2 filename-based IDs.
##

sub cleanId {
	my ($id) = @_;

	# Remove any spaces around ID:
	$id =~ s/^\s+//;
	$id =~ s/\s+$//;

	# Remove any format appendix
	$id =~ s/\.[a-zA-Z0-9_-]+$//;

	# Remove _composer--title information for POPC-2:
	if ($id =~ /^(pl-[^_]+)_.*$/) {
		$id = $1;
	}

	return $id;
}



##############################
##
## writeLog -- It is presumed that the log directory is writable by this script;
##     otherwise, no logs will be written.  Access logs are split by day to
##     allow archiving or deleting old logs as necessary.
##

sub writeLog {
	my ($logdir, $id, $format) = @_;

	# Do not log favicon.ico requests:
	return if ($id eq "favicon") && ($format eq "ico");

	my %date = getDate();
	my $logfile = "$logdir/$date{'year'}$date{'month'}$date{'day'}.log";
	my $datestring = $date{"year"};
	$datestring .= $date{"month"};
	$datestring .= $date{"day"};
	$datestring .= $date{"hour"};
	$datestring .= $date{"min"};
	$datestring .= $date{"sec"};
	my $ipaddress = $ENV{"REMOTE_ADDR"};
	my $entry = "$datestring\t$ipaddress\t$format\t$id\n";
	if (open(LOGFILE, ">>$logfile")) {
		print LOGFILE $entry;
		close LOGFILE;
	}
}



##############################
##
## getDate --
##

sub getDate {
   my $cyear;     # current year
   my $cmonth;    # current month (zero-padded)
   my $cday;      # current day (zero-padded)
   my $chour;     # current hour (zero-padded)
   my $cmin;      # current minute (zero-padded)
   my $csec;      # current second (zero-padded)
   my $weekday;   # current weekday
   my $dayofyear; # current day of year
   my $isdst;     # current timezone

   ($csec, $cmin, $chour, $cday, $cmonth, $cyear,
         $weekday, $dayofyear, $isdst) = localtime(time);

   $cmonth += 1;     # fix month so that it is in the range [
   $cyear += 1900;   # fix year so that it is actual year.

   if ($cmonth < 10) {
      $cmonth = int($cmonth);
      $cmonth = "0$cmonth";
   }
   if ($cday < 10) {
      $cday = int($cday);
      $cday = "0$cday";
   }
   if ($chour < 10) {
      $chour = int($chour);
      $chour = "0$chour";
   }
   if ($cmin < 10) {
      $cmin = int($cmin);
      $cmin = "0$cmin";
   }
   if ($csec < 10) {
      $csec = int($csec);
      $csec = "0$csec";
   }

	my %output;
	$output{"year"} = $cyear;
	$output{"month"} = $cmonth;
	$output{"day"} = $cday;
	$output{"hour"} = $chour;
	$output{"min"} = $cmin;
	$output{"sec"} = $csec;
	$output{"weekday"} = $weekday;
	$output{"dayofyear"} = $dayofyear;
	$output{"timezone"} = $isdst;
	return %output;
}



