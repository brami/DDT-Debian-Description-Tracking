#!/usr/bin/perl

use diagnostics;
use strict;

use DBI;
use CGI qw/:standard escape/;
use Digest::MD5 qw(md5_hex);
use Text::Diff;

my $start= shift(@ARGV);

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

sub print_translated {
        my $description_id = shift;
        my $lang = shift;
        my $package = shift;

	my $sth;

	if (not ($lang)) {
		$sth = $dbh->prepare("SELECT B.language,A.language FROM (SELECT language FROM translation_tb WHERE description_id=?) AS A right join (SELECT L.language FROM translation_tb AS L GROUP BY L.language ORDER BY L.language) AS B ON A.language=B.language");
		$sth->execute($description_id);
	} else {
		$sth = $dbh->prepare("SELECT '$lang',language FROM translation_tb WHERE description_id=? and language=?  ");
		$sth->execute($description_id,$lang);
	}

	my $language;
	my $translated;
	my $istranslated=0;
	while(($language,$translated) = $sth->fetchrow_array) {
		if ($translated) {
			print "<a href=\"ddt.cgi?desc_id=$description_id&language=$language\">$language</a> ";
	                $istranslated++;
		} else {
			#print "<a href=\"ddt.cgi?desc_id=$description_id&getuntrans=$language\"><strike>$language</strike></a> ";
			print "<strike>$language</strike> ";

		}

	}

	if (($lang)and($istranslated==0)) {
		my $description_id2;
	
		$sth = $dbh->prepare("SELECT description_id FROM description_tb WHERE package=? and description_id in (SELECT description_id FROM translation_tb WHERE language=?)");
		$sth->execute($package,$lang);
	
		while(($description_id2) = $sth->fetchrow_array) {
			print "<a href=\"ddt.cgi?desc_id=$description_id2\">old translation</a>|";
			print "<a href=\"ddt.cgi?diff1=$description_id2&diff2=$description_id&language=$lang\">diff</a> ";
		}
	}
};



print "Content-type: text/html; charset=UTF-8\n";	
print "\n";	
print "<HTML>\n";	
print "<HEAD>\n";	
print "<meta http-equiv=\"content-type\" content=\"text/html;charset=UTF-8\">";
print "<TITLE>Debian Description Tracking  --- NO PARAM --- </TITLE>\n";	
print "</HEAD>\n";	
print "<BODY>\n";	
print_link_list;
print "<HR>\n";	

	my $sth = $dbh->prepare("SELECT prioritize,description_id,package FROM description_tb WHERE description_id in (SELECT description_id FROM active_tb) ORDER BY prioritize DESC");
	$sth->execute();

	my $prioritize;
	my $description_id;
	my $package;

	print "<pre>";
	print "<table>";
	print "<tr><th>Prio</th><th>id</th><th>Package</th><th>Languages</th></tr>";
	while(($prioritize,$description_id,$package) = $sth->fetchrow_array) {
		print "<tr><td>$prioritize</td>";
		print "<td><a href=\"ddt.cgi?desc_id=$description_id\">$description_id</a></td>";
		print "<td>$package</td> <td>";
                if (param('language')) {
			&print_translated($description_id,param('language'),$package);
		} else {
			&print_translated($description_id);
		}
		print "</td></tr>\n";
	}
	print "</table>";
	print "</pre>";

print "</BODY>\n";	

