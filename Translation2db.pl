#!/usr/bin/perl

use diagnostics;
use strict;

my $translationfile= shift(@ARGV);
my $lang= shift(@ARGV); 

my $description_id;
my $description_tag_id;

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


sub scan_translation_file {
	my $filename= shift(@_);
	my $lang= shift(@_); 

	my $package;
	my $md5sum;
	my $translation;

	sub get_description_id {
		my $md5sum= shift(@_);

		my $description_id;

		my $sth = $dbh->prepare("SELECT description_id FROM description_tb WHERE description_md5='$md5sum'");
		$sth->execute;
		($description_id) = $sth->fetchrow_array;
		return $description_id;
	}

	sub get_translation_id {
		my $description_id= shift(@_);
		my $lang= shift(@_);

		my $translation_id;

		my $sth = $dbh->prepare("SELECT translation_id FROM translation_tb WHERE description_id=$description_id and language='$lang'");
		$sth->execute;
		($translation_id) = $sth->fetchrow_array;
		return $translation_id;
	}

	sub get_description {
		my $description_id= shift(@_);

		my $description;

		my $sth = $dbh->prepare("SELECT description FROM description_tb WHERE description_id=$description_id");
		$sth->execute;
		($description) = $sth->fetchrow_array;
		return $description;
	}

	sub get_part_id {
		my $part_md5= shift(@_);
		my $lang= shift(@_);

		my $part_id;

		my $sth = $dbh->prepare("SELECT part_id FROM part_tb WHERE part_md5='$part_md5' and language='$lang'");
		$sth->execute;
		($part_id) = $sth->fetchrow_array;
		return $part_id;
	}

	sub save_parts_to_db {
		my $md5sum= shift(@_);
		my $part  = shift(@_);
		my $lang  = shift(@_);

		if ($part and $md5sum) {
			eval {
				my $part_id=get_part_id($md5sum,$lang);
				if (not $part_id) {
					$part=$dbh->quote($part);
					$dbh->do("INSERT INTO part_tb (part_md5, part, language) VALUES ('$md5sum',$part,'$lang');");
					$dbh->commit;   # commit the changes if we get this far
				}
			};
			if ($@) {
				warn "Transaction aborted because $@";
				$dbh->rollback; # undo the incomplete changes
				print $part . "\n" ;
			}
		}
	}

	open (PACKAGES, "$filename") or die "open translationfile failed";
	while (<PACKAGES>) {
		if ($_=~/^$/) {   
			my $description;
			my $translation_orig=$translation;
			$translation=$dbh->quote($translation);
			eval {
				$description_id=get_description_id($md5sum);
				if ($description_id) {
					my $translation_id=get_translation_id($description_id,$lang);
					if (not $translation_id) {
						$dbh->do("INSERT INTO translation_tb (description_id, translation, language) VALUES ($description_id,$translation,'$lang');");
					}
					$description=get_description($description_id);
				}
				$dbh->commit;   # commit the changes if we get this far
			};
			if ($@) {
				warn "Transaction aborted because $@";
				$dbh->rollback; # undo the incomplete changes
			}

			if ($description_id) {
				my @t_parts = desc_to_parts($translation_orig);
				my @e_parts = desc_to_parts($description);

				my @e_parts_md5;
				foreach (@e_parts) {
					push @e_parts_md5,md5_hex($_);					
				}

				if ($#e_parts_md5 = $#t_parts) {
					my $a=0;
					while ($a <= $#e_parts_md5 ) {
						&save_parts_to_db($e_parts_md5[$a],$t_parts[$a],$lang);
						#&add_pparts_to_db($parts[$a],$parts_trans[$a],$lang_postfix);
						$a++
					}
				}
			}


		}
		if (/^Package: (.*)/) { # new item
			$package=$1;
		}
		if (/^Description-md5: (.*)/) { # new item
			$md5sum=$1;
		}
		if (/^Description-$lang: (.*)/) { # new item
			$translation=$1 . "\n";
		}
		if (/^ /) {
			$translation.=$_;
		}
	}
	close PACKAGES or die "translationfile failed";
}

if ( -r $translationfile ) {
	scan_translation_file($translationfile,$lang)
}

