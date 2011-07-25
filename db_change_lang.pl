#!/usr/bin/perl

use diagnostics;
use strict;

use DBI;
use Digest::MD5 qw(md5_hex);

my @DSN = ("DBI:Pg:dbname=ddtp", "", "");

my $dbh = DBI->connect(@DSN,
    { PrintError => 0,
      RaiseError => 1,
      AutoCommit => 0,
    });

die $DBI::errstr unless $dbh;


eval {
	$dbh->do("UPDATE translation_tb SET language='km' WHERE language='km_KH';");
	$dbh->do("UPDATE part_tb SET language='km' WHERE language='km_KH';");
	$dbh->do("UPDATE ppart_tb SET language='km' WHERE language='km_KH';");
	$dbh->do("UPDATE owner_tb SET language='km' WHERE language='km_KH';");
	$dbh->commit;   # commit the changes if we get this far
};
if ($@) {
	warn "Transaction aborted because $@";
	$dbh->rollback; # undo the incomplete changes
}
