#!/usr/bin/perl

use diagnostics;
use strict;

my $count=0;
my $count_trans=0;
my $count_part=0;
my $count_1part=0;

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
	#my $sth = $dbh->prepare("SELECT description,description_id FROM description_tb WHERE description_id in (SELECT description_id FROM active_tb) and description_id not in (SELECT description_id FROM translation_tb WHERE description_id in (SELECT description_id FROM active_tb) and language=?)");

        # check all descriptions... 
	#my $sth = $dbh->prepare("SELECT description,description_id FROM description_tb WHERE description_id not in (SELECT description_id FROM translation_tb WHERE language=?)");
        # only the last descriptions from today
	my $sth = $dbh->prepare("SELECT description,description_id FROM description_tb WHERE description_id in (SELECT description_id from description_tag_tb where date_end=current_date group by description_id) and description_id not in (SELECT description_id FROM translation_tb WHERE language=?)");

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
				warn "completeTranslations.pl: failed to INSERT description_id '$d_id', lang '$lang' into translation_tb: $@\n";
                                $dbh->rollback; # undo the incomplete changes
                        }

		} else {
			if ($translated>0) {
				$count_part++;
				if ($untranslated==1) {
					$count_1part++;
	
					#print "   save_part_milestone_to_db: $d_id milestone: part:$lang \n";
	
					eval {
						$dbh->do("INSERT INTO description_milestone_tb (description_id,milestone) VALUES (?,?);", undef, $d_id, "part:$untranslated-$lang");
						$dbh->commit;   # commit the changes if we get this far
					};
					if ($@) {
						# warn "Packages2db.pl: failed to INSERT Package '$d_id', milestone 'part:$lang' into description_milestone_tb: $@\n";
						$dbh->rollback; # undo the incomplete changes
					}
				}
			}
		}
	}
}

my $lang=shift ;

get_descrition_ids($lang);

print "#checked description:$count #partly translation:$count_part #one missing part:$count_1part #full_trans:$count_trans\n";

