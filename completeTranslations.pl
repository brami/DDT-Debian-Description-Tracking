#!/usr/bin/perl

use diagnostics;
use strict;

my $count=0;
my $count_trans=0;

use DBI;
use Digest::MD5 qw(md5_hex);

my @DSN = ("DBI:Pg:dbname=ddtp", "", "");

my $dbh = DBI->connect(@DSN,
    { PrintError => 0,
      RaiseError => 1,
      AutoCommit => 0,
    });

die $DBI::errstr unless $dbh;

sub desc_to_parts ($) {
        my $desc = shift;

        my @parts;
        my $part;
        my @lines=split(/\n/, $desc);

        foreach (@lines) {
                if (not @parts) {
                        push @parts,$_;
                        $part="";
                        next;
                }
                if ($_ ne " .") {
                        $part.=$_;
                        $part.="\n";
                } else {
                        push @parts,$part if ($part ne "");
                        $part="";
                }
        }
        push @parts,$part if ($part ne "");

        return @parts;

}



sub get_descrition_ids {
	my $lang=shift ;

	#my $sth = $dbh->prepare("SELECT description,description_id FROM description_tb WHERE description_id in (SELECT description_id FROM active_tb) and description_id not in (SELECT description_id FROM translation_tb WHERE description_id in (SELECT description_id FROM active_tb) and language=?) and package in (SELECT package FROM description_tb WHERE description_id in (SELECT description_id FROM translation_tb WHERE language=?) GROUP BY package)");
	my $sth = $dbh->prepare("SELECT description,description_id FROM description_tb WHERE description_id in (SELECT description_id FROM active_tb) and description_id not in (SELECT description_id FROM translation_tb WHERE description_id in (SELECT description_id FROM active_tb) and language=?)");

	#$sth->execute($lang,$lang);
	$sth->execute($lang);
	while (my ($description,$d_id) = $sth->fetchrow_array) {
		#print "check translation id=$d_id,$lang\n";
		$count++;

		my @parts=desc_to_parts($description);
		my $untranslated=0;
		my $translated=0;

		my $translation=undef;

		#print "parts-md5sum: \n";
		foreach (@parts) {
			my $part_md5=md5_hex($_);
			#print $part_md5 . " ";
			my $sth2 = $dbh->prepare("SELECT part FROM part_tb WHERE part_md5=? and language=?");
			$sth2->execute($part_md5,$lang);

			my ($part) = $sth2->fetchrow_array ;
			if ($part) {
				#print "translated\n";
				if ($translated<2) {
					$translation.=$part;
					$translation.="\n" if ($translated==0);
				} else {
					$translation.=" .\n";
					$translation.=$part;
				}
				$translated++;
			} else {
				#print "not translated\n";
				$untranslated++;
			}
		}
		
		if ($untranslated==0) {
			#print "  $d_id is full translated\n";
			$count_trans++;
			#print "$translation";
                        eval {
                                my $sth2 = $dbh->prepare("INSERT INTO translation_tb (description_id, translation, language) VALUES (?,?,?);");
				$sth2->execute($d_id,$translation,$lang);
                                $dbh->commit;   # commit the changes if we get this far
                        };
                        if ($@) {
                                warn "Transaction aborted because $@";
                                $dbh->rollback; # undo the incomplete changes
                        }

		}
	}
}

get_descrition_ids(shift);

print "#p_trans: $count #full_trans: $count_trans\n";

