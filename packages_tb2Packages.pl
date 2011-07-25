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

my $DIST = shift || "etch";
my $SECTION = shift || "main";

export_packages();      # Read packages file
exit;

sub export_packages
{
  my ($package,$source,$version,$tag,$priority,$maintainer,$task,$section,$description);

  print STDERR " Export package file \n";
  my $fh = open_stdout( );

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

# Helper for load_packages
sub open_stdout
{
  my $fh;
 
  open $fh, "| bzip2 " or die "Couldn't open stdout ($!)\n";
  
  return $fh;
}

