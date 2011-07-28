#!/usr/bin/perl -w
use strict;
use DBI;
my @DSN = ("DBI:Pg:dbname=ddtp", "", "");

my $dbh = DBI->connect(@DSN,
    { PrintError => 0,
      RaiseError => 1,
      AutoCommit => 0,
    });

die $DBI::errstr unless $dbh;

my $data = "/org/ddtp.debian.net/Packages/";

my $file = shift;
die "Usage: $0 <Packages>\n" unless defined $file;

export_packages();      # Read packages file
exit;

sub export_packages
{
  my ($package,$source,$version,$tag,$priority,$maintainer,$task,$section,$description);

  print " Export package file \n";
  my $fh;
  open $fh, '>', "$file" or die "Couldn't write to $file ($!)\n";

  my $sth = $dbh->prepare("SELECT package,source,version,tag,priority,maintainer,task,section,description FROM packages_tb ORDER BY package");
  $sth->execute;
  while ( ($package,$source,$version,$tag,$priority,$maintainer,$task,$section,$description) = $sth->fetchrow_array ) {
    print $fh "Package: $package\n";
    print $fh "Source: $source\n";
    print $fh "Version: $version\n";
    print $fh "Tag: $tag\n" if $tag;
    print $fh "Priority: $priority\n";
    print $fh "Maintainer: $maintainer\n";
    print $fh "Task: $task\n" if $task;
    print $fh "Section: $section\n";
    print $fh "Description: $description\n";
    print $fh "\n";
  }
  close $fh;
}

