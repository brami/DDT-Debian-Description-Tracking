#!/usr/bin/perl

use diagnostics;
use strict;

my $dists= shift(@ARGV);
my $lang= shift(@ARGV); 

use DBI;

my @DSN = ("DBI:Pg:dbname=ddtp", "", "");

my $dbh = DBI->connect(@DSN,
    { PrintError => 0,
      RaiseError => 1,
      AutoCommit => 0,
    });

die $DBI::errstr unless $dbh;


sub get_translation {
	my $description_id= shift(@_);
	my $lang= shift(@_);

	my $translation;

	my $sth = $dbh->prepare("SELECT translation FROM translation_tb WHERE description_id=? and language=?");
	$sth->execute($description_id,$lang);
	($translation) = $sth->fetchrow_array;
	if ($translation and (( $translation =~ tr/\n/\n/ )<2)) {
		undef $translation;
	}
	return $translation;
}

sub get_packageinfos {
	my $description_id= shift(@_);

	my $description_md5;

	my $sth = $dbh->prepare("SELECT description_md5 FROM description_tb WHERE description_id=?");
	$sth->execute($description_id);
	($description_md5) = $sth->fetchrow_array;
	return ($description_md5);
}

sub make_translation_file {
	my $tag= shift(@_);

	my %seen_package_and_description_ids;
	my $package;
	my $version;
	my $translation;
	my $description_md5;
	my $description_id;

	open (PACKAGELIST, "<Packages/packagelist-$tag");
	while (<PACKAGELIST>) {
		chomp;
		($package,$version) = split (/ /);
		#print "^$package^$version^";
		my $sth = $dbh->prepare("SELECT description_id FROM description_tb WHERE description_id in (SELECT description_id FROM package_version_tb WHERE package=? and version=?)");
		$sth->execute($package,$version);
		while(($description_id) = $sth->fetchrow_array) {
			#print "  -> $description_id\n";
			unless ($seen_package_and_description_ids{"$package $description_id"}) {
				$translation=get_translation($description_id,$lang);
				if ($translation) {
					($description_md5)=get_packageinfos($description_id);
					print "Package: $package\n";
					print "Description-md5: $description_md5\n";
					print "Description-$lang: $translation\n";
				}
				$seen_package_and_description_ids{"$package $description_id"}=1;
			}
		}
	}
	close (PACKAGELIST);
}

make_translation_file($dists);
