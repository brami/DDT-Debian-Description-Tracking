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

load_packages();      # Read packages file
exit;

sub load_packages
{
  print " Loading package file ";
  my $fh = open_stdin( );
  parse_header_format( $fh, \&process_package );
  close $fh;
  my $sth = $dbh->prepare("SELECT count(packages_id) FROM packages_tb");
  $sth->execute;
  my ($counter) = $sth->fetchrow_array;
  print "  -> $counter packages in packages_tb\n";
}

# Helper for load_packages
sub process_package
{
  my $hash = shift;
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
			  "0" # This is set as NOT NULL, but should be removed from the sql layout.
			  );
    $dbh->commit;   # commit the changes if we get this far
  };
  if ($@) {
    warn "Packages2packages_tb.pl: failed to INSERT Package '".$hash->{Package}."', Version '".$hash->{Version}."': $@\n";
    $dbh->rollback; # undo the incomplete changes
  }
}

sub open_stdin
{
  my $fh;
 
  open $fh, "</dev/stdin" or die "Couldn't open /dev/stdin ($!)\n";
  
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

