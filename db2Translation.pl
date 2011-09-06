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

my $sth = $dbh->prepare("SELECT package,description_md5,translation FROM description_tag_tb join translation_tb ON description_tag_tb.description_id=translation_tb.description_id join description_tb ON description_tb.description_id=translation_tb.description_id  WHERE tag=? and date_end=CURRENT_DATE and language=? order by translation_tb.description_id");
$sth->execute($dists,$lang);
while(my ($package,$description_md5,$translation) = $sth->fetchrow_array) {
	print "Package: $package\n";
	print "Description-md5: $description_md5\n";
	print "Description-$lang: $translation\n";
}

