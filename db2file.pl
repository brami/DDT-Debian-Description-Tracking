#!/usr/bin/perl

use diagnostics;
use strict;

my $lang= shift(@ARGV); 

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
my $source;
my $index;
my $translation;
my $description_id;

sub get_packageinfos {
	my $description_id= shift(@_);

	my $package;
	my $source;

	my $sth = $dbh->prepare("SELECT package,source FROM description_tb WHERE description_id=$description_id");
	$sth->execute;
	($package,$source) = $sth->fetchrow_array;
	return ($package,$source);
}

my $sth = $dbh->prepare("SELECT description_id,translation FROM translation_tb WHERE language='$lang'");
$sth->execute;
while(($description_id,$translation) = $sth->fetchrow_array) {
	($package,$source)=get_packageinfos($description_id);
	$source =~ s/ .*//;
	$package =~ s/ .*//;
	if ($source =~ /^lib/) {
		($dir) = ($source =~ /^(....)/);
	} else {
		($dir) = ($source =~ /^(.)/);
	}
	mkdir "file";
	mkdir "file/$lang";
	mkdir "file/$lang/$dir";
	mkdir "file/$lang/$dir/$source";
	open  (FILE, ">>file/$lang/$dir/$source/$package:$description_id") or die "po-file";
	print FILE "id: $description_id\n";
	print FILE "$translation\n";
	close (FILE);
}


