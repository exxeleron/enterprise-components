\a

.hnd.h[`kdb.rdb]"count trade"
.hnd.h[`kdb.rdbAggr]"count trade"
.hnd.h[`kdb.rdbSnap]"count tradeSnap"

{[hh;q] .hnd.h[] "count trade"

c:.hnd.h'[`kdb.rdbAggr`kdb.rdb]@\:"count trade";
r: .hnd.h'[`kdb.rdbAggr`kdb.rdb]@\:({x#trade};min c);
r[0]=r[1]
`time`sym xasc (2!select time, sym, price1:price from r[0]) uj (2!select time, sym, price2:price from r[1])


a:.hnd.h[`kdb.rdbAggr]"select last price by time:`time$1 xbar time.minute, sym from trade";
b:.hnd.h[`kdb.rdb]"select last price by time:`time$1 xbar time.minute, sym from trade";
c:.hnd.h[`kdb.rdbSnap]"select last price by time, sym from tradeSnap";
.hnd.h[`kdb.rdbSnap]"`price xdesc select count price by time, sym from tradeSnap"
(~). 400#/:(a;c)
a
b
c



.hnd.h[`kdb.rdbSnap]"select price by time, sym from tradeSnap where sym=`instr14"
t0:.hnd.h[`kdb.rdb]"select from trade where sym=`instr14"
t1:.hnd.h[`kdb.rdbSnap]"select time, sym, priceSnap:price, sizeSnap:size from tradeSnap where sym=`instr14";
`time xasc t0 uj t1
