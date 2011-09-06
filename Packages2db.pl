#!/usr/bin/perl

use diagnostics;
use strict;

my $packagefile= shift(@ARGV);
my $distribution= shift(@ARGV);

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

sub scan_packages_file {
	my $filename= shift(@_);
	my $distribution= shift(@_);

	my $package;
	my $prioritize;
	my $description;

	my $tag;
	my $source;
	my $priority;
	my $section;
	my @task;
	my @tag;
	my $version;

	sub get_old_description_id {
		my $package= shift(@_);

		my $old_description_id;

		#my $sth = $dbh->prepare("SELECT description_id FROM description_tb WHERE package=?");
		#my $sth = $dbh->prepare("SELECT description_id from package_version_tb where package=?");
		# better without LIMIT ?
		my $sth = $dbh->prepare("SELECT description_id from package_version_tb where package=? order by description_id DESC LIMIT 1");
		$sth->execute($package);
		($old_description_id) = $sth->fetchrow_array;
		return $old_description_id;
	}

	sub get_description_id {
		my $description_orig= shift(@_);
		my $description_id;

		my $md5=md5_hex($description_orig);
		my $sth = $dbh->prepare("SELECT description_id FROM description_tb WHERE description_md5=?");
		$sth->execute($md5);
		($description_id) = $sth->fetchrow_array;
		return $description_id;
	}

	sub get_description_tag_id {
		my $description_id= shift(@_);
		my $distribution= shift(@_);

		my $description_tag_id;

		my $sth = $dbh->prepare("SELECT description_tag_id FROM description_tag_tb WHERE description_id=? and tag=?");
		$sth->execute($description_id, $distribution);
		($description_tag_id) = $sth->fetchrow_array;
		return $description_tag_id;
	}

	sub is_description_id_active {
		my $description_id= shift(@_);

		my $sth = $dbh->prepare("SELECT description_id FROM active_tb WHERE description_id=?");
		$sth->execute($description_id);
		if ($sth->fetchrow_array) {
			return 1;
		}
		return 0;
	}

	sub save_active_to_db {
		my $description_id= shift(@_);

		eval {
			$dbh->do("INSERT INTO active_tb (description_id) VALUES (?);", undef, $description_id);
			$dbh->commit;   # commit the changes if we get this far
		};
		if ($@) {
			warn "Packages2db.pl: failed to INSERT description_id '$description_id' into active_tb: $@\n";
			$dbh->rollback; # undo the incomplete changes
		}
	}

	sub save_version_to_db {
		my $description_id= shift(@_);
		my $version= shift(@_);
		my $package= shift(@_);

		my $package_version_id;

		my $sth = $dbh->prepare("SELECT package_version_id FROM package_version_tb WHERE description_id=? and package=? and version=?");
		$sth->execute($description_id, $package, $version);
		($package_version_id) = $sth->fetchrow_array;

		if (not $package_version_id) {
			eval {
				$dbh->do("INSERT INTO package_version_tb (description_id,package,version) VALUES (?,?,?);", undef, $description_id, $package, $version);
				$dbh->commit;   # commit the changes if we get this far
			};
			if ($@) {
				warn "Packages2db.pl: failed to INSERT Package '$package', Version '$version' into package_version_tb: $@\n";
				$dbh->rollback; # undo the incomplete changes
			}
		}

		my $version_id;

		$sth = $dbh->prepare("SELECT version_id FROM version_tb WHERE description_id=? and version=?");
		$sth->execute($description_id, $version);
		($version_id) = $sth->fetchrow_array;

		if (not $version_id) {
			eval {
				$dbh->do("INSERT INTO version_tb (description_id,version) VALUES (?,?);", undef, $description_id, $version);
				$dbh->commit;   # commit the changes if we get this far
			};
			if ($@) {
				warn "Packages2db.pl: failed to INSERT description_id '$description_id', version '$version' into version_tb: $@\n";
				$dbh->rollback; # undo the incomplete changes
			}
		}
	}

	sub save_milestone_to_db {
		my $description_id= shift(@_);
		my $priority= shift(@_);
		my $section= shift(@_);
		my @task= @_;

		my $sth = $dbh->prepare("DELETE FROM description_milestone_tb WHERE description_id=?  and 
                                                                                    not milestone like 'rtrn:%' and 
                                                                                    not milestone like 'popc:%' and 
                                                                                    not milestone like 'part:%'");
		$sth->execute($description_id);

		eval {
			$dbh->do("INSERT INTO description_milestone_tb (description_id,milestone) VALUES (?,?);", undef, $description_id, "prio:$priority");
			$dbh->commit;   # commit the changes if we get this far
		};
		if ($@) {
			warn "Packages2db.pl: failed to INSERT Package '$description_id', milestone 'prio:$priority' into description_milestone_tb: $@\n";
			$dbh->rollback; # undo the incomplete changes
		}

		eval {
			$dbh->do("INSERT INTO description_milestone_tb (description_id,milestone) VALUES (?,?);", undef, $description_id, "sect:$section");
			$dbh->commit;   # commit the changes if we get this far
		};
		if ($@) {
			warn "Packages2db.pl: failed to INSERT Package '$description_id', milestone 'sect:$section' into description_milestone_tb: $@\n";
			$dbh->rollback; # undo the incomplete changes
		}

		foreach (@task) {
			eval {
				$dbh->do("INSERT INTO description_milestone_tb (description_id,milestone) VALUES (?,?);", undef, $description_id, "task:$_");
				$dbh->commit;   # commit the changes if we get this far
			};
			if ($@) {
				warn "Packages2db.pl: failed to INSERT Package '$description_id', milestone 'task:$_' into description_milestone_tb: $@\n";
				$dbh->rollback; # undo the incomplete changes
			}
		}
	}

	sub save_tag_milestone_to_db {
		my $description_id= shift(@_);
		my @tags= @_;

		my @splittags;

                foreach my $in (@tags) {
			#print "  $description_id task: $in\n";
	                if ($in =~ m/^([^{]*)\{([^}]*)\}(.*)$/) {
		                my $prefix  = $1;
		                my $postfix = $3;
		                my @list = split /,/,$2;
		                foreach my $o (@list) {
			                push @splittags, $prefix.$o.$postfix;
			                }
	                } else {
		                push @splittags, $in;
	                }
                }

		#print "$description_id task: " . join(" ", @splittags) . "\n";

		foreach (@splittags) {
			eval {
				$dbh->do("INSERT INTO description_milestone_tb (description_id,milestone) VALUES (?,?);", undef, $description_id, "tags:$_");
				$dbh->commit;   # commit the changes if we get this far
			};
			if ($@) {
				warn "Packages2db.pl: failed to INSERT Package '$description_id', milestone 'tags:$_' into description_milestone_tb: $@\n";
				$dbh->rollback; # undo the incomplete changes
			}
		}
	}

	sub save_oldtranslang_milestone_to_db {
		my $description_id= shift(@_);
		my @oldtranslangs = @_;

		print "     save_oldtranslang_milestone_to_db: $description_id task: " . join(" ", @oldtranslangs) . " #:$#oldtranslangs\n";

		foreach (@oldtranslangs) {
			eval {
				$dbh->do("INSERT INTO description_milestone_tb (description_id,milestone) VALUES (?,?);", undef, $description_id, "rtrn:$_");
				$dbh->commit;   # commit the changes if we get this far
			};
			if ($@) {
				warn "Packages2db.pl: failed to INSERT Package '$description_id', milestone 'oldtranslangs:$_' into description_milestone_tb: $@\n";
				$dbh->rollback; # undo the incomplete changes
			}
		}
	}

	sub save_part_description_to_db {
		my $description_id= shift(@_);
		my $part_md5      = shift(@_);

		eval {
			$dbh->do("INSERT INTO part_description_tb (description_id,part_md5) VALUES (?,?);", undef, $description_id,$part_md5);
			$dbh->commit;   # commit the changes if we get this far
		};
		if ($@) {
			warn "Packages2db.pl: failed to INSERT description_id '$description_id', part_md5 '$part_md5' into part_description_tb: $@\n";
			$dbh->rollback; # undo the incomplete changes
		}
	}

	open (PACKAGES, "$filename") or die "open packagefile failed";
	while (<PACKAGES>) {
		if ($_=~/^$/) {
			my $description_orig=$description;
			my @oldtranslang;
			eval {
				$description_id=get_description_id($description_orig);
				if ($description_id) {
					$description_tag_id=get_description_tag_id($description_id,$distribution);
					if ($description_tag_id) {
						$dbh->do("UPDATE description_tag_tb SET date_end = CURRENT_DATE WHERE description_tag_id=? AND date_end <> CURRENT_DATE;", undef, $description_tag_id);
					} else {
						$dbh->do("INSERT INTO description_tag_tb (description_id, tag, date_begin, date_end) VALUES (?,?,CURRENT_DATE,CURRENT_DATE);", undef, $description_id, $distribution);
					}
					# Track changes in priority. Here we update the details of the description if one of:
					# - A package with this description comes along with a higher priority (could still be same package)
					# - The current package has a different (possibly lower) priority than before
					$dbh->do("UPDATE description_tb SET prioritize = ?, package = ?, source = ? WHERE description_id = ? AND CASE WHEN package = ? THEN prioritize <> ? ELSE prioritize < ? END", undef,
								$prioritize, $package, $source, $description_id, $package, $prioritize, $prioritize );
				} else {
					my $old_description_id=get_old_description_id($package);
					if ($old_description_id) {
						print "   changed description from $package ($source)\n" ;
                                                # search for translations of the old description:
	                                        # SELECT language FROM translation_tb where description_id=
						my $lang;
						my $sth = $dbh->prepare("SELECT language FROM translation_tb where description_id=?");
						$sth->execute($old_description_id);
						while(($lang) = $sth->fetchrow_array) {
							#print "       old description was translated in $lang\n" ;
							push @oldtranslang,$lang;
						}
					}
					my $md5=md5_hex($description_orig);
					$dbh->do("INSERT INTO description_tb (description_md5, description, package, source, prioritize) VALUES (?,?,?,?,?);", undef, $md5,$description,$package,$source,$prioritize);
					$description_id=get_description_id($description_orig);
					$dbh->do("INSERT INTO description_tag_tb (description_id, tag, date_begin, date_end) VALUES (?,?,CURRENT_DATE,CURRENT_DATE);", undef, $description_id,$distribution);
					print "   add new description from $package ($source) with $prioritize\n" ;
				}
				$dbh->commit;   # commit the changes if we get this far
			};
			if ($@) {
				warn "Packages2db.pl: Transaction aborted because $@";
				$dbh->rollback; # undo the incomplete changes
			}
			if (($description_id)) {
				save_version_to_db($description_id,$version,$package);
			}
			if (($description_id)) {
				save_milestone_to_db($description_id,$priority, $section, @task);
				save_tag_milestone_to_db($description_id,@tag);
				if ($#oldtranslang>=0) {
					save_oldtranslang_milestone_to_db($description_id,@oldtranslang);
				}
			}
			if (($description_id) and ($distribution eq 'sid')) {
				if (! is_description_id_active($description_id)) {
					save_active_to_db($description_id);

					my @parts = desc_to_parts($description);

					my @parts_md5;
					foreach (@parts) {
						push @parts_md5,md5_hex($_);
					}

					my $a=0;
					while ($a <= $#parts_md5 ) {
						&save_part_description_to_db($description_id,$parts_md5[$a]);
						$a++
					}
				}
			}


		}
		if (/^Package: ([\w.+-]+)/) { # new item
			$package=$1;
			$source=$1;
			$prioritize=40;
			$version="1";
			$prioritize -= 1 if $package =~ /^(linux|kernel)-/i;
			$prioritize -= 1 if $package =~ /^(linux|kernel)-source/i;
			$prioritize -= 2 if $package =~ /^(linux|kernel)-patch/i;
			$prioritize -= 3 if $package =~ /^(linux|kernel)-header/i;
			$prioritize += 3 if $package =~ /^(linux|kernel)-image/i;
			$prioritize -= 3 if $package =~ /lib/i;
			$prioritize -= 1 if $package =~ /-doc$/i;
			$prioritize -= 6 if $package =~ /-dev$/i;
		}
		if (/^Source: ([\w.+-]+)/) { # new item
			$source=$1;
		}
		if (/^Version: ([\w.+:~-]+)/) { # new item
			$version=$1;
		}
		if (/^Tag: (.+)/) { # new item
			@tag=split(',? +',$1);
			$tag=$1;
			$prioritize += 1;
			$prioritize += 2 if $tag =~ /role[^ ]+program/i;
			$prioritize += 1 if $tag =~ /role[^ ]+metapackage/i;
			$prioritize -= 2 if $tag =~ /role[^ ]+devel-lib/i;
			$prioritize -= 2 if $tag =~ /role[^ ]+source/i;
			$prioritize -= 1 if $tag =~ /role[^ ]+shared-lib/i;
			$prioritize -= 1 if $tag =~ /role[^ ]+data/i;
		}
		if (/^Priority: (\w+)/) { # new item
			$priority=$1;
			if ($priority  =~ /extra/i ) {
				$prioritize+=0;
			} elsif ($priority  =~ /optional/i ) {
				$prioritize+=5;
			} elsif ($priority  =~ /standard/i ) {
				$prioritize+=10;
			} elsif ($priority  =~ /important/i ) {
				$prioritize+=15;
			} elsif ($priority  =~ /required/i ) {
				$prioritize+=20;
			}
			if ($distribution  =~ /sid/i ) {
				$prioritize+=2;
			}
			if ($distribution  =~ /lliurex/i ) {
				$prioritize-=20;
			}
		}
		if (/^Maintainer: (.*)/) { # new item
		}
		if (/^Task: (.*)/) { # new item
			@task=split('[, ]+',$1);
			$prioritize+=2;
		}
		if (/^Section: (\w+)/) { # new item
			$section="$1";
			if ($section  =~ /devel/i ) {
				$prioritize-=3;
			} elsif ($section  =~ /net/i ) {
				$prioritize-=2;
			} elsif ($section  =~ /oldlibs/i ) {
				$prioritize-=3;
			} elsif ($section  =~ /libs/i ) {
				$prioritize-=3;
			}
		}
		if (/^Description: (.*)/) { # new item
			$description=$1 . "\n";
		}
		if (/^ /) {
			$description.=$_;
		}
	}
	close PACKAGES or die "packagefile failed";
}

if ( -r $packagefile ) {
	scan_packages_file($packagefile,$distribution)
}

