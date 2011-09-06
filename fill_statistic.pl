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

my $sth;

$sth = $dbh->prepare("DELETE FROM statistic_tb WHERE date=CURRENT_DATE");
$sth->execute();


# global

$sth = $dbh->prepare("SELECT count(description_id),CURRENT_DATE from description_tb");
$sth->execute();
while(my ($count,$date) = $sth->fetchrow_array) {
	eval {
		$dbh->do("INSERT INTO statistic_tb (value,date,stat) VALUES (?,?,?);", undef, $count, $date, "all");
		$dbh->commit;   # commit the changes if we get this far
	};
	if ($@) {
		warn "fill_statistic.pl: failed to INSERT stat 'all': $@\n";
		$dbh->rollback; # undo the incomplete changes
	}
}

$sth = $dbh->prepare("SELECT language,count(description_id),CURRENT_DATE from translation_tb group by language");
$sth->execute();
while(my ($lang,$count,$date) = $sth->fetchrow_array) {
	if ($lang) {
		eval {
			$dbh->do("INSERT INTO statistic_tb (value,date,stat) VALUES (?,?,?);", undef, $count, $date, "all:trans-$lang");
			$dbh->commit;   # commit the changes if we get this far
		};
		if ($@) {
			warn "fill_statistic.pl: failed to INSERT stat 'all:trans-$lang': $@\n";
			$dbh->rollback; # undo the incomplete changes
		}
	}
}

# FIXME all in review/pending


# Dists (sid, testing, stable)

$sth = $dbh->prepare("SELECT tag,count(description_id),CURRENT_DATE from description_tag_tb where date_end=CURRENT_DATE group by tag");
$sth->execute();
while(my ($dist,$count,$date) = $sth->fetchrow_array) {
	eval {
		$dbh->do("INSERT INTO statistic_tb (value,date,stat) VALUES (?,?,?);", undef, $count, $date, "dist:$dist");
		$dbh->commit;   # commit the changes if we get this far
	};
	if ($@) {
		warn "fill_statistic.pl: failed to INSERT stat 'dist:$dist': $@\n";
		$dbh->rollback; # undo the incomplete changes
	}
}

$sth = $dbh->prepare("SELECT tag,translation_tb.language,count(translation_tb.description_id),CURRENT_DATE from description_tag_tb LEFT JOIN translation_tb ON translation_tb.description_id=description_tag_tb.description_id where date_end=CURRENT_DATE group by tag, translation_tb.language");
$sth->execute();
while(my ($dist,$lang,$count,$date) = $sth->fetchrow_array) {
	if ($lang) {
		eval {
			$dbh->do("INSERT INTO statistic_tb (value,date,stat) VALUES (?,?,?);", undef, $count, $date, "dist:$dist:trans-$lang");
			$dbh->commit;   # commit the changes if we get this far
		};
		if ($@) {
			warn "fill_statistic.pl: failed to INSERT stat 'dist:$dist:trans-$lang': $@\n";
			$dbh->rollback; # undo the incomplete changes
		}
	}
}

# FIXME dists in review/pending


# Milestones

$sth = $dbh->prepare("SELECT milestone,count(milestone),CURRENT_DATE from description_milestone_tb group by milestone");
$sth->execute();
while(my ($milestone,$count,$date) = $sth->fetchrow_array) {
	eval {
		$dbh->do("INSERT INTO statistic_tb (value,date,stat) VALUES (?,?,?);", undef, $count, $date, "mile:$milestone");
		$dbh->commit;   # commit the changes if we get this far
	};
	if ($@) {
		warn "fill_statistic.pl: failed to INSERT stat 'mile:$milestone': $@\n";
		$dbh->rollback; # undo the incomplete changes
	}
}

$sth = $dbh->prepare("SELECT description_milestone_tb.milestone,translation_tb.language,count(description_milestone_tb.description_id),CURRENT_DATE from description_milestone_tb LEFT OUTER JOIN  translation_tb ON (description_milestone_tb.description_id=translation_tb.description_id)   group by description_milestone_tb.milestone, translation_tb.language order by translation_tb.language,description_milestone_tb.milestone");
$sth->execute();

while(my ($milestone,$lang,$count,$date) = $sth->fetchrow_array) {
	if ($lang) {
		eval {
			$dbh->do("INSERT INTO statistic_tb (value,date,stat) VALUES (?,?,?);", undef, $count, $date, "mile:$milestone:trans-$lang");
			$dbh->commit;   # commit the changes if we get this far
		};
		if ($@) {
			warn "fill_statistic.pl: failed to INSERT stat 'mile:$milestone:trans-$lang': $@\n";
			$dbh->rollback; # undo the incomplete changes
		}
	}
}

# FIXME Milestones in review/pending


# Users

# $sth = $dbh->prepare("SELECT username,counttranslations,CURRENT_DATE from users_tb;");
$sth = $dbh->prepare("SELECT *,CURRENT_DATE from ddtss where key like 'aliases/%/counttranslations'");
$sth->execute();
# while(my ($user,$count,$date) = $sth->fetchrow_array) {
while(my ($key,$count,$date) = $sth->fetchrow_array) {
	if ( $key =~ /aliases\/([a-zA-Z0-9_]*)\/counttranslations/ ) {
	my $user = $1;
 		eval {
 			$dbh->do("INSERT INTO statistic_tb (value,date,stat) VALUES (?,?,?);", undef, $count, $date, "user:translations-$user");
 			$dbh->commit;   # commit the changes if we get this far
 		};
 		if ($@) {
 			warn "fill_statistic.pl: failed to INSERT stat 'user:translations-$user': $@\n";
 			$dbh->rollback; # undo the incomplete changes
 		}
	}
	
}

# $sth = $dbh->prepare("SELECT username,countreviews,CURRENT_DATE from users_tb;");
$sth = $dbh->prepare("SELECT *,CURRENT_DATE from ddtss where key like 'aliases/%/countreviews'");
$sth->execute();
# while(my ($user,$count,$date) = $sth->fetchrow_array) {
while(my ($key,$count,$date) = $sth->fetchrow_array) {
	if ( $key =~ /aliases\/([a-zA-Z0-9_]*)\/countreviews/ ) {
	my $user = $1;
 		eval {
 			$dbh->do("INSERT INTO statistic_tb (value,date,stat) VALUES (?,?,?);", undef, $count, $date, "user:reviews-$user");
 			$dbh->commit;   # commit the changes if we get this far
 		};
 		if ($@) {
 			warn "fill_statistic.pl: failed to INSERT stat 'user:reviews-$user': $@\n";
 			$dbh->rollback; # undo the incomplete changes
 		}
	}
	
}



# lang pending

my @lang;

$sth = $dbh->prepare("select distinct language from translation_tb where description_id>1");
$sth->execute();
while(my ($lang) = $sth->fetchrow_array) {
	push (@lang,$lang);
}

foreach my $lang (@lang) {
	$sth = $dbh->prepare("SELECT count(*),CURRENT_DATE from ddtss where value='forreview' and key like ?");
	$sth->execute("$lang%");
	while(my ($count,$date) = $sth->fetchrow_array) {
		eval {
			$dbh->do("INSERT INTO statistic_tb (value,date,stat) VALUES (?,?,?);", undef, $count, $date, "lang:pendingreview-$lang");
			$dbh->commit;   # commit the changes if we get this far
		};
		if ($@) {
			warn "fill_statistic.pl: failed to INSERT stat 'lang:pendingreview-$lang': $@\n";
			$dbh->rollback; # undo the incomplete changes
		}
	}

	$sth = $dbh->prepare("SELECT count(*),CURRENT_DATE from ddtss where value like 'untranslated,%' and key like ?");
	$sth->execute("$lang%");
	while(my ($count,$date) = $sth->fetchrow_array) {
		eval {
			$dbh->do("INSERT INTO statistic_tb (value,date,stat) VALUES (?,?,?);", undef, $count, $date, "lang:pendingtranslation-$lang");
			$dbh->commit;   # commit the changes if we get this far
		};
		if ($@) {
			warn "fill_statistic.pl: failed to INSERT stat 'lang:pendingtranslation-$lang': $@\n";
			$dbh->rollback; # undo the incomplete changes
		}

	}

}
