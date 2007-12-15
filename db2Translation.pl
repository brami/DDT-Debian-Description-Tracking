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


my $package;
my $description_md5;

sub get_description_ids {
	my $tag= shift(@_);

	my @description_ids;

	my $sth = $dbh->prepare("SELECT description_id FROM description_tag_tb WHERE tag=? and date_end=CURRENT_DATE ORDER BY description_id");
	$sth->execute($tag);
	while(($description_id) = $sth->fetchrow_array) {
		push @description_ids,$description_id;
	}
	return @description_ids;
}

sub get_translation {
	my $description_id= shift(@_);
	my $lang= shift(@_);

	my $translation;

	my $sth = $dbh->prepare("SELECT translation FROM translation_tb WHERE description_id=? and language=?");
	$sth->execute($description_id,$lang);
	($translation) = $sth->fetchrow_array;
	return $translation;
}

sub get_packageinfos {
	my $description_id= shift(@_);

	my $package;
	my $description_md5;

	my $sth = $dbh->prepare("SELECT package,description_md5 FROM description_tb WHERE description_id=?");
	$sth->execute($description_id);
	($package,$description_md5) = $sth->fetchrow_array;
	return ($package,$description_md5);
}

foreach (get_description_ids($dists)) {
	$description_id=$_;
	$translation=get_translation($description_id,$lang);
	if ($translation) {
		($package,$description_md5)=get_packageinfos($description_id);
		print "Package: $package\n";
		print "Description-md5: $description_md5\n";
		print "Description-$lang: $translation\n";
	}
}
