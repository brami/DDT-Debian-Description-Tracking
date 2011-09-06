#!/usr/bin/perl -w
use strict;
use LWP::Simple;
use POSIX qw(strftime);
use DBI;
my @DSN = ("DBI:Pg:dbname=ddtp", "", "");

my $dbh = DBI->connect(@DSN,
    { PrintError => 0,
      RaiseError => 1,
      AutoCommit => 0,
    });

die $DBI::errstr unless $dbh;

my $data = "/srv/ddtp.debian.net/Packages/";

my $POPCON = "http://popcon.debian.org/by_vote";

my $POPCON_COUNT = 500;

fetch_data();
load_popcon();        # Read popcon data
exit;

sub fetch_data
{
  my $code = mirror( $POPCON, "$data/popcon.txt" );
  warn "$POPCON: $code\n" if ($code != 200 and $code != 304);
}

# This goes through the package list and compares it against the DDTP.
# Firstly to count the number of each priority, secondly to detect missing
# package entries.

sub load_popcon
{
  my $sth = $dbh->prepare("DELETE FROM description_milestone_tb WHERE milestone like 'popc:%'");
  $sth->execute();

  my $fh;
  open $fh, "$data/popcon.txt" or die "Couldn't read popcon data ($!)\n";
  
  my $count = 0;
  while(<$fh>)
  {
    next if /^#/;
    next unless /^\d+\s+/;
    my @F = split /\s+/;
    $count++;
    if( $count <= 8000 ) { 
      $sth = $dbh->prepare("SELECT package_version_tb.description_id,tag from package_version_tb join description_tag_tb ON description_tag_tb.description_id=package_version_tb.description_id where date_end=CURRENT_DATE and package=? group by package_version_tb.description_id, tag");
      #$sth = $dbh->prepare("SELECT package_version_tb.description_id,tag from package_version_tb join description_tag_tb ON description_tag_tb.description_id=package_version_tb.description_id where date_end='2011-08-16' and package=? group by package_version_tb.description_id, tag");
      $sth->execute($F[1]);


      while(my ($description_id,$tag) = $sth->fetchrow_array) {
        foreach my $maxcount (500,1000,2000,4000,8000) {
          if ($count <= $maxcount) {
            eval {
              $dbh->do("INSERT INTO description_milestone_tb (description_id,milestone) VALUES (?,?);", undef, $description_id, "popc:$tag-$maxcount");
              $dbh->commit;   # commit the changes if we get this far
            };
            if ($@) {
              #warn "popcon2db.pl: failed to INSERT Package '$description_id', milestone 'popc:500' into description_milestone_tb: $@\n";
              $dbh->rollback; # undo the incomplete changes
            }
          }
        }
      }
    }
  }
  
  close $fh;
}
