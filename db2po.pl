#!/usr/bin/perl

use diagnostics;
use strict;

my $dists= shift(@ARGV);
my $lang= shift(@ARGV); 

my $description_id;
my $translation;

use DBI;
use Digest::MD5 qw(md5_hex);

my @DSN = ("DBI:Pg:dbname=ddtp", "", "");

my $dbh = DBI->connect(@DSN,
    { PrintError => 0,
      RaiseError => 1,
      AutoCommit => 0,
    });

die $DBI::errstr unless $dbh;

my $dir;
my $package;
my $description;
my $source;
my @parts;
my @tparts;
my $index;

sub get_description_ids {
	my $tag= shift(@_);

	my @description_ids;

	my $sth = $dbh->prepare("SELECT description_id FROM description_tag_tb WHERE tag='$tag' and date_end=(SELECT max(date_end) FROM description_tag_tb WHERE tag='$tag')");
	$sth->execute;
	while(($description_id) = $sth->fetchrow_array) {
		push @description_ids,$description_id;
	}
	return @description_ids;
}

sub get_translation {
	my $description_id= shift(@_);
	my $lang= shift(@_);

	my $translation;

	my $sth = $dbh->prepare("SELECT translation FROM translation_tb WHERE description_id=$description_id and language='$lang'");
	$sth->execute;
	($translation) = $sth->fetchrow_array;
	return $translation;
}

sub get_packageinfos {
	my $description_id= shift(@_);

	my $package;
	my $source;
	my $description;

	my $sth = $dbh->prepare("SELECT package,source,description FROM description_tb WHERE description_id=$description_id");
	$sth->execute;
	($package,$source,$description) = $sth->fetchrow_array;
	return ($package,$source,$description);
}

sub desc_to_parts ($) {
        my $desc = shift;

        my @parts;
        my $part;
        my @lines=split(/\n/, $desc);

        foreach (@lines) {
                if (not @parts) {
                        push @parts,$_;
                        $part="";
                        next;
                }
                if ($_ ne " .") {
                        $part.="\n" if ($part ne "");
                        $part.=$_;
                } else {
                        push @parts,$part if ($part ne "");
                        $part="";
                }
        }
        push @parts,$part if ($part ne "");

        return @parts;
}

foreach (get_description_ids($dists)) {
	$description_id=$_;
	# print "id: $description_id\n";
	$translation=get_translation($description_id,$lang);
	($package,$source,$description)=get_packageinfos($description_id);
	(@parts)=desc_to_parts($description);
	@tparts=();
	if (not $translation) {
		foreach (@parts) {
			push @tparts," ";
		}
	} else {
		(@tparts)=desc_to_parts($translation);
		if ($#tparts!=$#parts) {
			@tparts=();
			foreach (@parts) {
				push @tparts," ";
			}
		}
	}
	# print "\n";
	$source =~ s/ .*//;
	$package =~ s/ .*//;
	if ($source =~ /^lib/) {
		($dir) = ($source =~ /^(....)/);
	} else {
		($dir) = ($source =~ /^(.)/);
	}
	#print "Source: $source\n";
	#print "Package: $package\n";
	#print "Dir: $dir\n";
	mkdir "pos";
	mkdir "pos/$lang";
	mkdir "pos/$lang/$dists";
	mkdir "pos/$lang/$dists/$dir";
	mkdir "pos/$lang/$dists/$dir/$source";
	open  (FILE, ">pos/$lang/$dists/$dir/$source/$package.po") or die "po-file";
	print FILE "msgid \"\"\n";
	print FILE "msgstr \"\"\n";
	print FILE "\"Project-Id-Version: $package\\n\"\n";
	print FILE "\"Report-Msgid-Bugs-To: \\n\"\n";
	print FILE "\"POT-Creation-Date: \\n\"\n";
	print FILE "\"PO-Revision-Date: \\n\"\n";
	print FILE "\"Last-Translator: \\n\"\n";
	print FILE "\"Language-Team: German \\n\"\n";
	print FILE "\"MIME-Version: 1.0\\n\"\n";
	print FILE "\"Content-Type: text/plain; charset=UTF-8\\n\"\n";
	print FILE "\"Content-Transfer-Encoding: 8bit\\n\"\n";
	print FILE "\"X-Generator: db2po.pl ddtp \\n\"\n";
	print FILE "\n";
	foreach $index (0 .. $#parts) {
		$parts[$index] =~ s/^$//mg;
		$parts[$index] =~ s/\\/\\\\/mg;
		$parts[$index] =~ s/"/\\"/mg;
		$parts[$index] =~ s/^/\"/mg;
		$parts[$index] =~ s/$/\\n\"/mg;
		if ($translation) {
			$tparts[$index] =~ s/^$//mg;
			$tparts[$index] =~ s/\\/\\\\/mg;
			$tparts[$index] =~ s/"/\\"/mg;
			$tparts[$index] =~ s/^/\"/mg;
			$tparts[$index] =~ s/$/\\n\"/mg;
		}
		print FILE "msgid \"\"\n";
		print FILE "$parts[$index]\n";
		print FILE "msgstr \"\"\n";
		print FILE "$tparts[$index]\n" if ($translation);
		print FILE "\n";
	}
	close (FILE);
}
