#!/usr/bin/perl

use diagnostics;
use strict;

use DBI;
use CGI qw/:standard/;
use Digest::MD5 qw(md5_hex);
use Text::Diff;

my $start= shift(@ARGV);

my $sec;
my $min;
my $hour;
my $mday;
my $mon;
my $year;
my $wday;
my $yday;
my $isdst;
($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime(time);
$year-=100;
$mon+=1;
my $time="$mday/$mon/$year-$hour:$min";

my $logdir="/org/ddtp.debian.net/log/";

my @DSN = ("DBI:Pg:dbname=ddtp", "", "");

my $dbh = DBI->connect(@DSN,
    { PrintError => 0,
      RaiseError => 1,
      AutoCommit => 0,
    });

die $DBI::errstr unless $dbh;

my $d_count;
my $a_count;
my $t_count;
my $ta_count;
my $pa_count;
my $lang;

my $sth;

$sth = $dbh->prepare("SELECT count(description_id) FROM description_tb");
$sth->execute;

($d_count) = $sth->fetchrow_array ;
	print "$d_count package descriptions;<br>\n";
	print "<br>\n";

	open  (FILE, ">>$logdir/stat")            or die "log-file";
	printf FILE "%s %5d\n", $time, $d_count;
	close (FILE);

$sth = $dbh->prepare("SELECT count(description_id) FROM active_tb");
$sth->execute;

($a_count) = $sth->fetchrow_array ;
	print "$a_count package descriptions are active;<br>\n";
	print "<br>\n";

	open  (FILE, ">>$logdir/stat-uptodate")            or die "log-file";
	printf FILE "%s %5d\n", $time, $a_count;
	close (FILE);


$sth = $dbh->prepare("SELECT L.language FROM translation_tb AS L GROUP BY L.language ORDER BY L.language");
$sth->execute;

while(($lang) = $sth->fetchrow_array) {
	my $sth = $dbh->prepare("SELECT count(translation_id) FROM translation_tb WHERE language='$lang'");
	$sth->execute;

	($t_count) = $sth->fetchrow_array ;

	$sth = $dbh->prepare("SELECT count(description_id) FROM translation_tb WHERE description_id in (SELECT description_id FROM active_tb) and language='$lang'");
	$sth->execute;

	($ta_count) = $sth->fetchrow_array ;

	$sth = $dbh->prepare("SELECT count(package) FROM description_tb WHERE description_id in (SELECT description_id FROM active_tb) and description_id not in (SELECT description_id FROM translation_tb WHERE description_id in (SELECT description_id FROM active_tb) and language='$lang') and package in (SELECT package FROM description_tb WHERE description_id in (SELECT description_id FROM translation_tb WHERE language='$lang') GROUP BY package)");
	$sth->execute;

	($pa_count) = $sth->fetchrow_array ;

	print "lang $lang has $ta_count ($pa_count) active translations from $t_count translations;<br>\n";

	open  (FILE, ">>$logdir/stat-$lang")            or die "log-file";
	printf FILE "%s %5d\n", $time, $t_count;
	close (FILE);

	open  (FILE, ">>$logdir/stat-trans-sid-$lang")            or die "log-file";
	printf FILE "%s %5d %5d %5d\n", $time, $a_count, $ta_count, $pa_count ;
	close (FILE);
}

	print "<br>\n";

$dbh->disconnect;
