#!/usr/bin/perl -w
use strict;
use LWP::Simple;
use POSIX qw(strftime);
use Digest::MD5 qw(md5_hex);
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
my $ARCH = shift || "i386";

my %descrmd5;        # $descrmd5{$md5} = $desc_id, represents all known descriptions
my %descrlist;       # $descrlist{$package}{$md5} exists for each package in package file
                     # $descrlist{$package}{priority} = package priority
my %total_counts;    # $total_counts{$priority} = number of packages with that priority
my %important_packages;  # $important_packages{$package}{$md5} exists for packages+description of priority standard or higher

load_packages();      # Read packages file
exit;

sub load_packages
{
  print STDERR "Loading package file Packages_${DIST}_${SECTION}_${ARCH}.bz2";
  my $fh = open_bz2_file( "$data/Packages_${DIST}_${SECTION}_${ARCH}.bz2" );
  parse_header_format( $fh, \&process_package );
  close $fh;
  my $sth = $dbh->prepare("SELECT count(packages_id) FROM packages_tb");
  $sth->execute;
  my ($counter) = $sth->fetchrow_array;
  print STDERR "  -> $counter packages in packages_tb\n";
}

# Helper for load_packages
sub process_package
{
  my $hash = shift;
  my $md5 = md5_hex( $hash->{Description}."\n" );
#  print "$hash->{Package} : $md5\n";
  if (not $hash->{Source}) {
    $hash->{Source} = $hash->{Package};
  }

  eval {
    $dbh->do("INSERT INTO packages_tb (package,source,version,tag,priority,maintainer,task,section,description,description_md5) 
                          VALUES (?,?,?,?,?,?,?,?,?,?);", undef, 
                          $hash->{Package},
			  $hash->{Source},
			  $hash->{Version},
			  $hash->{Tag},
			  $hash->{Priority},
			  $hash->{Maintainer},
			  $hash->{Task},
			  $hash->{Section},
			  $hash->{Description},
			  $md5
			  );
    $dbh->commit;   # commit the changes if we get this far
  };
  if ($@) {
    $dbh->rollback; # undo the incomplete changes
  }
}

sub open_bz2_file
{
  my $file = shift;
 
  my $fh;
 
  open $fh, "bzcat $file |" or die "Couldn't open $file ($!)\n";
  
  return $fh;
}

sub parse_header_format
{
  my $fh = shift;
  my $sub = shift;

  my $lastfield = undef;
  my %hash;
  while(<$fh>)
  {
    chomp;
    if( /^([\w.-]+): (.*)/ )
    {
      $lastfield = $1;
      $hash{$1} = $2;
    }
    elsif( /^( .*)/ )
    {
      $hash{$lastfield} .= "\n$_";
    }
    elsif( /^$/ )
    {
      $sub->( \%hash );
      %hash = ();
      $lastfield = undef;
    }
  }
}



