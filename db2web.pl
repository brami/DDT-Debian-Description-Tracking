#!/usr/bin/perl

use diagnostics;
use strict;

use DBI;

my $start= shift(@ARGV);

my @DSN = ("DBI:Pg:dbname=ddtp", "", "");

my $dbh = DBI->connect(@DSN,
    { PrintError => 0,
      RaiseError => 1,
      AutoCommit => 0,
    });

die $DBI::errstr unless $dbh;



sub output_tags {
	my $description_id= shift(@_);

	my $sth = $dbh->prepare("SELECT tag,date_begin,date_end FROM description_tag_tb WHERE description_id=$description_id");
	$sth->execute;

	my $tag;
	my $date_begin;
	my $date_end;
	print "<a href=\"ddt.cgi?desc_id=$description_id\">$description_id</a>: ";
	while(($tag,$date_begin,$date_end) = $sth->fetchrow_array) {
		print "$tag $date_begin...$date_end; ";
	}
	print "<br>\n";
}

sub output_package {
	my $package= shift(@_);

	print "<h4><a href=\"ddt.cgi?package=$package\">$package</a></h4>\n";

	my $sth = $dbh->prepare("SELECT description_id FROM description_tb WHERE package='$package'");
	$sth->execute;

	my $description_id;
	while(($description_id) = $sth->fetchrow_array) {
		output_tags($description_id);
	}
}

sub get_description_tag_id {
	my $description_id= shift(@_);
	my $distribution= shift(@_);

	my $description_tag_id;

	my $sth = $dbh->prepare("SELECT description_tag_id FROM description_tag_tb WHERE description_id=$description_id and tag='$distribution'");
	$sth->execute;
	($description_tag_id) = $sth->fetchrow_array;
	return $description_tag_id;
}


sub output_packages_by_start {
	my $package_start= shift(@_);

	my $sth = $dbh->prepare("SELECT package FROM description_tb WHERE package ILIKE '$package_start%' GROUP BY package ORDER BY package");
	$sth->execute;

	my $package;
	while(($package) = $sth->fetchrow_array) {
		output_package($package);
	}
}

	print "<HTML>\n";	
	print "<HEAD>\n";	
	print "<TITLE>Debian Description Tracking  --- $start --- </TITLE>\n";	
	print "</HEAD>\n";	
	print "<BODY>\n";	
	print "<h3>$start</h3>\n";	
	output_packages_by_start($start);
	print "</BODY>\n";	

