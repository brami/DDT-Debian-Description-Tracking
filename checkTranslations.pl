#!/usr/bin/perl

use diagnostics;
use strict;

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


sub del_short_translation {
	my $translation;
	my $d_id;
	my $lang;

	my $sth = $dbh->prepare("SELECT translation,description_id,language FROM translation_tb ORDER BY language,description_id");
	$sth->execute();
	while (($translation,$d_id,$lang) = $sth->fetchrow_array) {
		#print "check translation id=$d_id,$lang\n";
		if ($translation and (( $translation =~ tr/\n/\n/ )<2)) {
			undef $translation;
			print "translation ist short id=$d_id,$lang\n";
			$dbh->do("DELETE FROM translation_tb WHERE language='$lang' and description_id='$d_id';");
			$dbh->commit;
		}
	}
}

del_short_translation();

