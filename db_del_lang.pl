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
	$dbh->do("DELETE FROM translation_tb WHERE language='pt_PT';");
	$dbh->do("DELETE FROM part_tb WHERE language='pt_PT';");
	$dbh->do("DELETE FROM ppart_tb WHERE language='pt_PT';");
	$dbh->do("DELETE FROM owner_tb WHERE language='pt_PT';");
	$dbh->commit;   # commit the changes if we get this far
};
if ($@) {
	warn "Transaction aborted because $@";
	$dbh->rollback; # undo the incomplete changes
}
