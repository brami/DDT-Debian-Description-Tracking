#!/usr/bin/perl

use diagnostics;
use strict;

use DBI;
use CGI qw/:standard escape escapeHTML charset/;
use Digest::MD5 qw(md5_hex);
use Text::Diff;

my $start= shift(@ARGV);

my $cgi = new CGI;
$cgi->charset("UTF-8");

my @DSN = ("DBI:Pg:dbname=ddtp", "", "");

my $dbh = DBI->connect(@DSN,
    { PrintError => 0,
      RaiseError => 1,
      AutoCommit => 0,
    });

die $DBI::errstr unless $dbh;

sub print_link_list {
	print "<a href=\"a.html\">a</a> ";
	print "<a href=\"b.html\">b</a> ";
	print "<a href=\"c.html\">c</a> ";
	print "<a href=\"d.html\">d</a> ";
	print "<a href=\"e.html\">e</a> ";
	print "<a href=\"f.html\">f</a> ";
	print "<a href=\"g.html\">g</a> ";
	print "<a href=\"h.html\">h</a> ";
	print "<a href=\"i.html\">i</a> ";
	print "<a href=\"j.html\">j</a> ";
	print "<a href=\"k.html\">k</a> ";
	print "<a href=\"l.html\">l</a> ";
	print "<a href=\"m.html\">m</a> ";
	print "<a href=\"n.html\">n</a> ";
	print "<a href=\"o.html\">o</a> ";
	print "<a href=\"p.html\">p</a> ";
	print "<a href=\"q.html\">q</a> ";
	print "<a href=\"r.html\">r</a> ";
	print "<a href=\"s.html\">s</a> ";
	print "<a href=\"t.html\">t</a> ";
	print "<a href=\"u.html\">u</a> ";
	print "<a href=\"v.html\">v</a> ";
	print "<a href=\"w.html\">w</a> ";
	print "<a href=\"x.html\">x</a> ";
	print "<a href=\"y.html\">y</a> ";
	print "<a href=\"z.html\">z</a> ";
	print "<br>";
};

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

sub own_a_description ($$$) {
	my $desc_id = shift;
	my $lang = shift;
	my $owner = shift;

	eval {
		$dbh->do("INSERT INTO owner_tb (description_id,language,owner,lastsend) VALUES (?,?,?,CURRENT_DATE);", undef, $desc_id,$lang,$owner);
		$dbh->commit;   # commit the changes if we get this far
	};
	if ($@) {
		$dbh->rollback; # undo the incomplete changes
	}
}


if (param('desc_id') and not param('language') and not param('getuntrans') and not param('getpountrans') ) {

	my $description;
	my $prioritize;
	my $package;
	my $source;

	my $description_id=param('desc_id');

	my $sth = $dbh->prepare("SELECT description,prioritize,package,source FROM description_tb WHERE description_id=?");
	$sth->execute($description_id);

	($description,$prioritize,$package,$source) = $sth->fetchrow_array ;

	print "Content-type: text/html; charset=UTF-8\n";	
	print "\n";	
	print "<HTML>\n";	
	print "<HEAD>\n";	
	print "<meta http-equiv=\"content-type\" content=\"text/html;charset=UTF-8\">";
	print "<TITLE>Debian Description Tracking  --- package: $package - desc_id: $description_id --- </TITLE>\n";	
	print "</HEAD>\n";	
	print "<BODY>\n";	
	print_link_list;
	print "<h3>$package</h3>\n";	
	print "<pre>\n";	
	print "Source: <a href=\"ddt.cgi?source=".escape($source)."\">$source</a>\n";	
	print "Package: <a href=\"ddt.cgi?package=".escape($package)."\">$package</a>\n";	
	print "Prioritize: $prioritize\n";	
	print "Description: ",$cgi->escapeHTML($description);	
	print "</pre>\n";	
	print "<br>\n";

	$sth = $dbh->prepare("SELECT tag,date_begin,date_end FROM description_tag_tb WHERE description_id=?");
	$sth->execute($description_id);

	my $tag;
	my $date_begin;
	my $date_end;
	while(($tag,$date_begin,$date_end) = $sth->fetchrow_array) {
		print "This Description was in $tag from $date_begin to $date_end;<br>";
	}

	print "<br>\n";

	$sth = $dbh->prepare("SELECT B.language,A.language FROM (SELECT language FROM translation_tb WHERE description_id=?) AS A right join (SELECT L.language FROM translation_tb AS L GROUP BY L.language ORDER BY L.language) AS B ON A.language=B.language");
	$sth->execute($description_id);

	my $language;
	my $translated;
	while(($language,$translated) = $sth->fetchrow_array) {
		if ($translated) {
			print "This Description is translated to <a href=\"ddt.cgi?desc_id=$description_id&language=$language\">$language</a> <a href=\"ddt.cgi?desc_id=$description_id&getuntrans=$language\"><img src=\"/icons/quill.png\" border=0 height=13></a> <br>";
		} else {
			print "This Description is not yet translated to $language <a href=\"ddt.cgi?desc_id=$description_id&getuntrans=$language\"><img src=\"/icons/quill.png\" border=0 height=13></a> <br>";
		}

	}

	print "<br>\n";
        
	my @parts=desc_to_parts($description);

	print "parts-md5sum: <br><pre>\n";
	foreach (@parts) {
		print md5_hex($_) . " ";
		$sth = $dbh->prepare("SELECT language FROM part_tb WHERE part_md5=?");
		$sth->execute(md5_hex($_));

		my $language;
		while(($language) = $sth->fetchrow_array) {
			print "<a href=\"ddt.cgi?part_md5=" . md5_hex($_) . "&language=$language\">$language</a> ";
		}

		$sth = $dbh->prepare("SELECT description_id FROM part_description_tb WHERE part_md5=?");
		$sth->execute(md5_hex($_));

		print "    ";
		my $desc_id;
		while(($desc_id) = $sth->fetchrow_array) {
			print "<a href=\"ddt.cgi?desc_id=$desc_id\">$desc_id</a> " if ($description_id!=$desc_id) ;
		}
		print "\n";
	}
	print "</pre>";

	print "<h4>other Descriptions of the $package package:</h4>\n";	

	my $description_id2;
	my $active;

	$sth = $dbh->prepare("SELECT A.description_id,B.description_id FROM description_tb AS A LEFT JOIN active_tb AS B ON A.description_id=B.description_id WHERE package=?");
	$sth->execute($package);

	while(($description_id2,$active) = $sth->fetchrow_array) {
		if ($description_id2 ne $description_id) {
			print "Description: <a href=\"ddt.cgi?desc_id=$description_id2\">$description_id2</a> \n";	
			print "<a href=\"ddt.cgi?diff1=$description_id&diff2=$description_id2\">patch</a><br>\n";

			if ($active) {
				print "This Description is active<br>";
			}

			my $sth2 = $dbh->prepare("SELECT tag,date_begin,date_end FROM description_tag_tb WHERE description_id=?");
			$sth2->execute($description_id2);
	
			my $tag;
			my $date_begin;
			my $date_end;
			while(($tag,$date_begin,$date_end) = $sth2->fetchrow_array) {
				print "This Description was in $tag from $date_begin to $date_end;<br>";
			}
	        	print "<br>\n";
		}
	}

	print "<br><br>";
	print "</BODY>\n";	
} elsif (param('desc_id') and param('language')) {

	my $description;
	my $prioritize;
	my $package;
	my $source;
	my $translation;
	my $part;

	my $description_id=param('desc_id');
	my $language=param('language');

	my $sth = $dbh->prepare("SELECT description,prioritize,package,source FROM description_tb WHERE description_id=?");
	$sth->execute($description_id);

	($description,$prioritize,$package,$source) = $sth->fetchrow_array ;

	print "Content-type: text/html; charset=UTF-8\n";	
	print "\n";	
	print "<HTML>\n";	
	print "<HEAD>\n";	
	print "<meta http-equiv=\"content-type\" content=\"text/html;charset=UTF-8\">";
	print "<TITLE>Debian Description Tracking  --- package: $package - desc_id: $description_id - language: $language --- </TITLE>\n";	
	print "</HEAD>\n";	
	print "<BODY>\n";	
	print_link_list;
	print "<h3>$package</h3>\n";	
	print "<pre>\n";	
	print "Source: <a href=\"ddt.cgi?source=".escape($source)."\">$source</a>\n";	
	print "Package: <a href=\"ddt.cgi?package=".escape($package)."\">$package</a>\n";	
	print "Prioritize: $prioritize\n";	
	print "Description: ",$cgi->escapeHTML($description);	
	print "</pre>\n";	

	print "The $language-translation:<br>\n";
	$sth = $dbh->prepare("SELECT translation FROM translation_tb WHERE description_id=? and language=?");
	$sth->execute($description_id,$language);

	($translation) = $sth->fetchrow_array ;

	print "<pre>\n";	
	print "Description-$language: ",$cgi->escapeHTML($translation);
	print "</pre>\n";	

	print "<br>\n";

	my @parts=desc_to_parts($description);

	print "parts-md5sum: <br><pre>\n";
	foreach (@parts) {
		my $part_md5=md5_hex($_);
		print $part_md5 . " ";
		$sth = $dbh->prepare("SELECT part FROM part_tb WHERE part_md5=? and language=?");
		$sth->execute($part_md5,$language);

		($part) = $sth->fetchrow_array ;
		if ($part) {
			print "translated\n";
		} else {
			print "not translated\n";
		}
	}
	print "</pre>";
	print "<br><br>";
	print "</BODY>\n";	
} elsif (param('desc_id') and param('getuntrans')) {

	my $description;
	my $prioritize;
	my $package;
	my $source;
	my $active;
	my $owner;
	my $translation;
	my $part;

	my $description_id=param('desc_id');
	my $language=param('getuntrans');

	my $sth = $dbh->prepare("SELECT A.description,A.prioritize,A.package,A.source,B.description_id,O.owner FROM (description_tb AS A LEFT JOIN active_tb AS B ON A.description_id=B.description_id) LEFT JOIN (SELECT owner,description_id FROM owner_tb WHERE language=?) AS O ON A.description_id=O.description_id WHERE A.description_id=?");
	$sth->execute($language,$description_id);

	($description,$prioritize,$package,$source,$active,$owner) = $sth->fetchrow_array ;

	print "Content-type: text/plain; charset=UTF-8\n";	
	print "\n";	
	print "# Source: $source\n";	
	print "# Package: $package\n";	
	if ($active) {
		print "# This Description is active\n";
	}
	if ($owner) {
		print "# This Description is owned\n";
	}
	print "# Prioritize: $prioritize\n";	
	print "Description: $description";	

	my @parts=desc_to_parts($description);

	my $num=0;
	foreach (@parts) {
		my $part_md5=md5_hex($_);
		$sth = $dbh->prepare("SELECT part FROM part_tb WHERE part_md5=? and language=?");
		$sth->execute($part_md5,$language);

		($part) = $sth->fetchrow_array ;
		if ($num == 0) {
			print "Description-$language: ";
		}
		if ($part) {
			print "$part";
			if ($num == 0) {
				print "\n";
			}
		} else {
			if ($num == 0) {
				print "<trans>\n";
			} else {
				print " <trans>\n";
			}
		}
		$num+=1;
		if ( ($num>1) and ($num<=$#parts) ) {
			print " .\n";
		}
	}

	print "\n";	
	print "# other Descriptions of the $package package with a translation in $language:\n";	
	print "# \n";	

	my $description_id2;

	$sth = $dbh->prepare("SELECT A.description_id,B.description_id FROM description_tb AS A LEFT JOIN active_tb AS B ON A.description_id=B.description_id WHERE A.package=? and A.description_id in (SELECT description_id FROM translation_tb WHERE language=?)");
	$sth->execute($package,$language);

	while(($description_id2,$active) = $sth->fetchrow_array) {
		if ($description_id2 ne $description_id) {
			print "# Description-id: $description_id2 http://ddtp.debian.net/ddt.cgi?desc_id=$description_id2\n";	
			print "# patch http://ddtp.debian.net/ddt.cgi?diff1=$description_id2&diff2=$description_id&language=$language\n";	
	
			if ($active) {
				print "# This Description is active\n";
			}
	
			my $sth2 = $dbh->prepare("SELECT tag,date_begin,date_end FROM description_tag_tb WHERE description_id=?");
			$sth2->execute($description_id2);
		
			my $tag;
			my $date_begin;
			my $date_end;
			while(($tag,$date_begin,$date_end) = $sth2->fetchrow_array) {
				print "# This Description was in $tag from $date_begin to $date_end;\n";
			}
	        	print "# \n";
		}
	}

} elsif (param('desc_id') and param('getpountrans')) {

	my $description;
	my $prioritize;
	my $package;
	my $source;
	my $active;
	my $owner;
	my $translation;
	my $part;
	my $trans;

	my $description_id=param('desc_id');
	my $language=param('getpountrans');

	my $sth = $dbh->prepare("SELECT A.description,A.prioritize,A.package,A.source,B.description_id,O.owner FROM (description_tb AS A LEFT JOIN active_tb AS B ON A.description_id=B.description_id) LEFT JOIN (SELECT owner,description_id FROM owner_tb WHERE language=?) AS O ON A.description_id=O.description_id WHERE A.description_id=?");
	$sth->execute($language,,$description_id);

	($description,$prioritize,$package,$source,$active,$owner) = $sth->fetchrow_array ;

	my @parts=desc_to_parts($description);

	print "Content-type: text/plain; charset=UTF-8\n";	
	print "\n";	
	print "msgid \"\"\n";
	print "msgstr \"\"\n";
	print "\"Project-Id-Version: ddtp-$description_id\\n\"\n";
	print "\"Report-Msgid-Bugs-To: submit\@bugs.ddtp.debian.net\\n\"\n";
	print "\"POT-Creation-Date: 2005-12-07 20:59-0800\\n\"\n";
	print "\"PO-Revision-Date: 2005-06-21 11:38GMT\\n\"\n";
	print "\"Last-Translator: name <email\@host.tld>\\n\"\n";
	print "\"Language-Team: name <email\@ddtp.debian.net>\\n\"\n";
	print "\"MIME-Version: 1.0\\n\"\n";
	print "\"Content-Type: text/plain; charset=UTF-8\\n\"\n";
	print "\"Content-Transfer-Encoding: 8bit\\n\"\n";
	print "\n";	
	print "\n";	
	print "#: Source: $source\n";	
	print "#: Package: $package\n";	
	if ($active) {
		print "#  This Description is active\n";
	}
	if ($owner) {
		print "#  This Description is owned\n";
	}
	print "#: Prioritize: $prioritize\n";	
	print "# \n";	
	print "# other Descriptions of the $package package with a translation in $language:\n";	
	print "# \n";	

	my $description_id2;

	$sth = $dbh->prepare("SELECT A.description_id,B.description_id FROM description_tb AS A LEFT JOIN active_tb AS B ON A.description_id=B.description_id WHERE package=? and A.description_id in (SELECT description_id FROM translation_tb WHERE language=?)");
	$sth->execute($package,$language);

	while(($description_id2,$active) = $sth->fetchrow_array) {
		if ($description_id2 ne $description_id) {
			print "# Description-id: $description_id2 http://ddtp.debian.net/ddt.cgi?desc_id=$description_id2\n";	
			print "# patch http://ddtp.debian.net/ddt.cgi?diff1=$description_id2&diff2=$description_id&language=$language\n";	
	
			if ($active) {
				print "# This Description is active\n";
			}
	
			my $sth2 = $dbh->prepare("SELECT tag,date_begin,date_end FROM description_tag_tb WHERE description_id=?");
			$sth2->execute($description_id2);
		
			my $tag;
			my $date_begin;
			my $date_end;
			while(($tag,$date_begin,$date_end) = $sth2->fetchrow_array) {
				print "# This Description was in $tag from $date_begin to $date_end;\n";
			}
	        	print "# \n";
		}
	}
	$description =~ s/^Description: //g;
	$description =~ s/\n$//g;
	$description =~ s/\\/\\\\/g;
	$description =~ s/"/\\"/g;
	$description =~ s/$/\\n"/mg;
	$description =~ s/^/"/mg;
	$description =~ s/^ /"/mg;
	print "msgid \"\"\n$description\n";	

	my $num=0;
	foreach (@parts) {
		my $part_md5=md5_hex($_);
		$sth = $dbh->prepare("SELECT part FROM part_tb WHERE part_md5=? and language=?");
		$sth->execute($part_md5,$language);

		($part) = $sth->fetchrow_array ;
		if ($num == 0) {
			$trans.= "Description-$language: ";
		}
		if ($part) {
			$trans.= "$part";
			if ($num == 0) {
				$trans.= "\n";
			}
		} else {
			if ($num == 0) {
				$trans.= "<trans>\n";
			} else {
				$trans.= " <trans>\n";
			}
		}
		$num+=1;
		if ( ($num>1) and ($num<=$#parts) ) {
			$trans.= " .\n";
		}
	}

	$trans =~ s/^Description-$language: //g;
	$trans =~ s/\n$//g;
	$trans =~ s/\\/\\\\/g;
	$trans =~ s/"/\\"/g;
	$trans =~ s/$/\\n"/mg;
	$trans =~ s/^/"/mg;
	$trans =~ s/^ /"/mg;
	print "msgstr \"\"\n$trans\n";	
	print "\n";	

} elsif (param('diff1') and param('diff2')) {

	my $description1;
	my $description2;

	my $diff1=param('diff1');
	my $diff2=param('diff2');
	my $language=param('language');

	my $sth = $dbh->prepare("SELECT description FROM description_tb WHERE description_id=?");
	$sth->execute($diff1);

	($description1) = $sth->fetchrow_array ;

	$sth = $dbh->prepare("SELECT description FROM description_tb WHERE description_id=?");
	$sth->execute($diff2);

	($description2) = $sth->fetchrow_array ;

	print "Content-type: text/html; charset=UTF-8\n";	
	print "\n";	
	print "<HTML>\n";	
	print "<HEAD>\n";	
	print "<meta http-equiv=\"content-type\" content=\"text/html;charset=UTF-8\">";
	print "<TITLE>Debian Description Tracking  --- diff: $diff1 $diff2 --- </TITLE>\n";	
	print "</HEAD>\n";	
	print "<BODY>\n";	
	print_link_list;
	print "<h3>diff from <a href=\"ddt.cgi?desc_id=$diff1\">$diff1</a> and <a href=\"ddt.cgi?desc_id=$diff2\">$diff2</a></h3>\n";	
	print "<pre>\n";	

	print "Description: ",$cgi->escapeHTML($description1);
	print "</pre>\n";	
	print "<pre>\n";	
	print "Description: ",$cgi->escapeHTML($description2);
	print "</pre>\n";	

	my $diff = diff \$description1, \$description2, { FILENAME_A=>"$diff1", MTIME_A=>0, FILENAME_B=>"$diff2", MTIME_B=>0 };
	print "<pre>\n";	
	print $cgi->escapeHTML($diff);
	print "</pre>\n";	
	
	if ($language) {
		print "The $language-translation:<br>\n";
		$sth = $dbh->prepare("SELECT translation FROM translation_tb WHERE description_id=? and language=?");
		$sth->execute($diff1,$language);
	
		my $translation;
		($translation) = $sth->fetchrow_array ;
	
		print "<pre>\n";	
		print "Description-$language: ",$cgi->escapeHTML($translation);
		print "</pre>\n";	
	}

	print "</BODY>\n";	
} elsif (param('part_md5') and param('language')) {

	my $part;

	my $part_md5=param('part_md5');
	my $language=param('language');

	my $sth = $dbh->prepare("SELECT part FROM part_tb WHERE part_md5=? and language=?");
	$sth->execute($part_md5,$language);

	($part) = $sth->fetchrow_array ;

	print "Content-type: text/html; charset=UTF-8\n";	
	print "\n";	
	print "<HTML>\n";	
	print "<HEAD>\n";	
	print "<meta http-equiv=\"content-type\" content=\"text/html;charset=UTF-8\">";
	print "<TITLE>Debian Description Tracking  --- part: $part_md5 language: $language --- </TITLE>\n";	
	print "</HEAD>\n";	
	print "<BODY>\n";	
	print_link_list;
	print "<h3>$part_md5</h3>\n";	
	print "<pre>\n";	
	print "Part:\n",$cgi->escapeHTML($part);
	print "</pre>\n";	

	$sth = $dbh->prepare("SELECT language FROM part_tb WHERE part_md5=?");
	$sth->execute($part_md5);

	print "<h3>Other languages for this part</h3>\n";	
	my $lang;
	while(($lang) = $sth->fetchrow_array) {
		print "<a href=\"ddt.cgi?part_md5=$part_md5&language=$lang\">$lang</a> ";
	}

	print "<br>\n";

	print "</pre>";
	print "<br><br>";
	print "</BODY>\n";	
} elsif (param('source')) {

	my $source=param('source');

	print "Content-type: text/html; charset=UTF-8\n";	
	print "\n";	
	print "<HTML>\n";	
	print "<HEAD>\n";	
	print "<meta http-equiv=\"content-type\" content=\"text/html;charset=UTF-8\">";
	print "<TITLE>Debian Description Tracking  --- source: $source --- </TITLE>\n";	
	print "</HEAD>\n";	
	print "<BODY>\n";	
	print_link_list;
	print "<h3>$source</h3>\n";	

	my $package;

	my $sth = $dbh->prepare("SELECT package FROM description_tb WHERE source=? GROUP BY package ORDER BY package");
	$sth->execute($source);

	while(($package) = $sth->fetchrow_array) {
		print "Package: <a href=\"ddt.cgi?package=".escape($package)."\">$package</a><br>\n";	
	}

	print "</BODY>\n";	
} elsif (param('allpackages')) {

	my $language=param('allpackages');

	my $package;
	my $description_id;
	my $translated;

	print "Content-type: text/html; charset=UTF-8\n";	
	print "\n";	
	print "<HTML>\n";	
	print "<HEAD>\n";	
	print "<meta http-equiv=\"content-type\" content=\"text/html;charset=UTF-8\">";
	print "<TITLE>Debian Description Tracking  --- all aktive packages status for $language --- </TITLE>\n";	
	print "</HEAD>\n";	
	print "<BODY>\n";	
	print "<h3>all aktive packages</h3>\n";	

	my $sth = $dbh->prepare("SELECT A.description_id,A.package,B.description_id FROM (SELECT D.description_id,D.package FROM description_tb AS D WHERE D.package in (SELECT package FROM description_tb GROUP BY package) and D.description_id in (SELECT description_id FROM active_tb) ORDER BY D.package) AS A LEFT JOIN (SELECT description_id FROM translation_tb WHERE language=?) AS B ON A.description_id=B.description_id");
	$sth->execute($language);

	print "<pre>";
	while(($description_id,$package,$translated) = $sth->fetchrow_array) {
		if ($translated) {
			print "<a href=\"ddt.cgi?desc_id=$description_id&language=$language\">$package</a>";
			print "  translated";
			print "\n";
		} else {
			print "<a href=\"ddt.cgi?desc_id=$description_id&getuntrans=$language\">$package</a>";
			print "  untranslated";
			print "\n";
		}
	}
	print "</pre>";
} elsif (param('alltranslatedpackages')) {

	my $language=param('alltranslatedpackages');

	my $package;
	my $description_id;

	print "Content-type: text/html; charset=UTF-8\n";	
	print "\n";	
	print "<HTML>\n";	
	print "<HEAD>\n";	
	print "<meta http-equiv=\"content-type\" content=\"text/html;charset=UTF-8\">";
	print "<TITLE>Debian Description Tracking  --- all aktive packages translated into $language --- </TITLE>\n";	
	print "</HEAD>\n";	
	print "<BODY>\n";	
	print "<h3>all aktive packages translated to $language</h3>\n";	

	my $sth = $dbh->prepare("SELECT description_id,package FROM description_tb WHERE package in (SELECT package FROM description_tb GROUP BY package) and description_id in (SELECT description_id FROM active_tb) and description_id in (SELECT description_id FROM translation_tb WHERE language=?) ORDER BY package");
	$sth->execute($language);

	print "<pre>";
	while(($description_id,$package) = $sth->fetchrow_array) {
		print "<a href=\"ddt.cgi?desc_id=$description_id&language=$language\">$package</a>";
		print "  translated";
		print "\n";
	}
	print "</pre>";
} elsif (param('alluntranslatedpackages')) {

	my $language=param('alluntranslatedpackages');

	my $package;
	my $description_id;

	print "Content-type: text/html; charset=UTF-8\n";	
	print "\n";	
	print "<HTML>\n";	
	print "<HEAD>\n";	
	print "<meta http-equiv=\"content-type\" content=\"text/html;charset=UTF-8\">";
	print "<TITLE>Debian Description Tracking  --- all aktive packages not translated into $language --- </TITLE>\n";	
	print "</HEAD>\n";	
	print "<BODY>\n";	
	print "<h3>all aktive packages not translated to $language</h3>\n";	

	my $sth = $dbh->prepare("SELECT description_id,package FROM description_tb WHERE package in (SELECT package FROM description_tb GROUP BY package) and description_id in (SELECT description_id FROM active_tb) and description_id not in (SELECT description_id FROM translation_tb WHERE language=?) ORDER BY package");
	$sth->execute($language);

	print "<pre>";
	while(($description_id,$package) = $sth->fetchrow_array) {
		print "<a href=\"ddt.cgi?desc_id=$description_id&getuntrans=$language\">$package</a>";
		print "  untranslated";
		print "\n";
	}
	print "</pre>";
} elsif (param('package')) {

	my $package=param('package');

	print "Content-type: text/html; charset=UTF-8\n";	
	print "\n";	
	print "<HTML>\n";	
	print "<HEAD>\n";	
	print "<meta http-equiv=\"content-type\" content=\"text/html;charset=UTF-8\">";
	print "<TITLE>Debian Description Tracking  --- package: $package --- </TITLE>\n";	
	print "</HEAD>\n";	
	print "<BODY>\n";	
	print_link_list;
	print "<h3>$package</h3>\n";	
	
	my $description_id;
	my $active;

	my $sth = $dbh->prepare("SELECT A.description_id,B.description_id FROM description_tb AS A LEFT JOIN active_tb AS B ON A.description_id=B.description_id WHERE package=?");
	$sth->execute($package);

	while(($description_id,$active) = $sth->fetchrow_array) {
		print "Description: <a href=\"ddt.cgi?desc_id=$description_id\">$description_id</a><br>\n";	

		if ($active) {
			print "This Description is active<br>";
		}

		my $sth2 = $dbh->prepare("SELECT tag,date_begin,date_end FROM description_tag_tb WHERE description_id=?");
		$sth2->execute($description_id);

		my $tag;
		my $date_begin;
		my $date_end;
		while(($tag,$date_begin,$date_end) = $sth2->fetchrow_array) {
			print "This Description was in $tag from $date_begin to $date_end;<br>";
		}
	        print "<br>\n";
	}

	print "<br>\n";
	print "</BODY>\n";	
} elsif (param('getone')) {

	my $language=param('getone');

	print "Content-type: text/html; charset=UTF-8\n";	
	print "\n";	
	print "<HTML>\n";	
	print "<HEAD>\n";	
	print "<meta http-equiv=\"content-type\" content=\"text/html;charset=UTF-8\">";
	print "<TITLE>Debian Description Tracking  --- getone : $language --- </TITLE>\n";	
	print "</HEAD>\n";	
	print "<BODY>\n";	
	
	my $sth = $dbh->prepare("SELECT description_id FROM description_tb WHERE description_id in (SELECT description_id FROM active_tb) and description_id not in (SELECT description_id FROM translation_tb WHERE language=?) and description_id not in (SELECT description_id FROM owner_tb WHERE language=?) ORDER BY prioritize DESC");
	$sth->execute($language,$language);

	my $description_id;

	while(($description_id) = $sth->fetchrow_array) {
		print "Get this description from this link: <a href=\"ddt.cgi?desc_id=$description_id&getuntrans=$language\"><img src=\"/icons/quill.png\" border=0 height=13></a> <br>";
		own_a_description($description_id,$language,"test");
		last;
	}

	print "<br>\n";
	print "</BODY>\n";	
} else {
	print "Content-type: text/html; charset=UTF-8\n";	
	print "\n";	
	print "<HTML>\n";	
	print "<HEAD>\n";	
	print "<meta http-equiv=\"content-type\" content=\"text/html;charset=UTF-8\">";
	print "<TITLE>Debian Description Tracking  --- NO PARAM --- </TITLE>\n";	
	print "</HEAD>\n";	
	print "<BODY>\n";	
	print_link_list;
	print "NO PARAM\n";	
	print "</BODY>\n";	
}

