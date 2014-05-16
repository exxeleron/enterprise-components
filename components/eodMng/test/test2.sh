ulimit -m 1000000
ulimit -v 1000000

yak start kdb.rdb
yak start eod.mng

q test/test2.q

rm -rf tmp
rm -rf log

