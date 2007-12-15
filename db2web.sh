#!/bin/bash -e

cd ~ddtp

mkdir -p www/source

tar -kczf www/source/ddtp_source_`date +%y%m%d`.tar.gz ddts/[bd]* ddt.cgi Packages2db.* db2Translation.*

cat << EOF > www/index.html.new
<HTML>
<HEAD>
<TITLE>Debian Description Tracking</TITLE>
</HEAD>
<BODY>
EOF
for start in a b c d e f g h i j k l m n o p q r s t u v w x y z
do
	./db2web.pl $start > www/$start.html # 2> /dev/null
	echo "<a href=\"$start.html\">$start</a>  " >> www/index.html.new 
done

echo "<hr>" >> www/index.html.new
echo "<a href=\"http://kleptog.org/cgi-bin/ddtss2-cgi\">to the ddtss (a web interface for the ddtp)<a/><br>" >> www/index.html.new
echo "Daily description translation stats for <a href='stats/stats-etch.html'>Etch</a>, <a href='stats/stats-lenny.html'>Lenny</a> and <a href='stats/stats-sid.html'>Sid</a>" >> www/index.html.new
echo "<hr>" >> www/index.html.new
echo "<a href=\"http://www.debian.org/international/l10n/ddtp\">Documentation about DDTP and DDTSS<a/>" >> www/index.html.new
echo "<hr>" >> www/index.html.new
echo "<img src=\"/gnuplot/ddts-stat.png\">" >> www/index.html.new 
echo "<hr>" >> www/index.html.new
./stat.pl >> www/index.html.new
echo "<hr>" >> www/index.html.new

echo "set terminal png small" > lib/all-stat.gnuplot
echo "set xdata time" >> lib/all-stat.gnuplot
echo "set format x \"%d.%m\\n%Y\"" >> lib/all-stat.gnuplot
echo "set output \"../gnuplot/ddts-stat.png\"" >> lib/all-stat.gnuplot
echo "plot [ ] [0:15000] \\" >> lib/all-stat.gnuplot

echo "set terminal png small" > lib/sid-stat.gnuplot
echo "set xdata time" >> lib/sid-stat.gnuplot
echo "set format x \"%d.%m\\n%Y\"" >> lib/sid-stat.gnuplot

LANGS=`psql ddtp -q -A -t -c "select distinct language from translation_tb"`
for lang in $LANGS
do
  echo "<h3>$lang in sid</h3>" >> www/index.html.new
  echo "<img src=\"/gnuplot/stat-trans-sid-$lang.png\">" >> www/index.html.new

  echo "'stat-$lang' using 1:2 title \"$lang\" with lines,\\" >> lib/all-stat.gnuplot

  echo "set output \"../gnuplot/stat-trans-sid-$lang.png\"" >> lib/sid-stat.gnuplot
  echo "plot 'stat-trans-sid-$lang' using 1:2 title \"Descriptions in sid\" with lines,\\" >> lib/sid-stat.gnuplot
  echo "  'stat-trans-sid-$lang' using 1:3 title \"$lang full trans\" with lines,\\" >> lib/sid-stat.gnuplot
  echo "  'stat-trans-sid-$lang' using 1:4 title \"$lang partly trans\" with lines" >> lib/sid-stat.gnuplot
  echo "" >> lib/sid-stat.gnuplot

done
echo "'stat' using 1:2 title \"descriptions in db\" with lines" >> lib/all-stat.gnuplot

cat << EOF >> www/index.html.new
</BODY>
</HTML>
EOF

cd log
gnuplot ../lib/stat.gnuplot
gnuplot ../lib/sid-stat.gnuplot
gnuplot ../lib/all-stat.gnuplot
cd ..

mv www/index.html.new www/index.html
cp -a ddt.cgi www
mkdir -p www/gnuplot
cp -a gnuplot/* www/gnuplot
