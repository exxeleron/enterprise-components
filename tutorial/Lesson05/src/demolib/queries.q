/S/ A library with custom queries on quote and trade tables.
/S/ Each query represents one basic financial case. 

// auxiliary library used for merging rdb and hdb results in .example.ohlcVwap2[] function
.sl.lib["qsl/query"];

/F/the records number of rdb quote table by hour
/E/.example.tradeStats[]
.example.tradeStats:{[] .hnd.h[`core.rdb] "select cnt:count i by time.hh from quote"};

/F/rdb quote and trade tables records joined based on time and sym columns
/E/.example.tradeAndQuote[]
.example.tradeAndQuote:{[] .hnd.h[`core.rdb] "aj[`sym`time;trade;quote]"};

/F/last price by symbol from rdb trade table
/E/.example.currentPrices[]
.example.currentPrices:{[] .hnd.h[`core.rdb] "select last price by sym from trade"};

/F/volume-weighted average price by symbol from rdb
/E/.example.vwap[]
.example.vwap:{[] .hnd.h[`core.rdb] "select vwap: size wavg price by sym from trade"};

/F/volume-weighted average price by symbol from rdb, functional form
/E/.example.functionalVwap[]
.example.functionalVwap:{[] .hnd.h[`core.rdb](?;`trade;();(enlist `sym)!enlist `sym;(enlist `vwap)!enlist (wavg;`size;`price))};

/F/volume-weighted average price by symbol and date from hdb
/E/.example.dailyVwap[]
.example.dailyVwap:{[] .hnd.h[`core.hdb] "select vwap: size wavg price by sym,date from trade"};

/F/last price in 10 minutes bars for first symbol in rdb trade table 
/E/.example.lastPrice10MinutesBar[]
.example.lastPrice10MinutesBar:{[] .hnd.h[`core.rdb] "select last price by 15 xbar time.minute from trade where sym = first sym"};

/F/last price in n minutes bars for symbol sym in rdb trade table 
/P/n:LONG - the number of minutes 
/P/sym:SYMBOL - name of the security symbol
/E/.example.functionalLastPriceNMinutesBar[30j; `instr0]
.example.functionalLastPriceNMinutesBar:{[n;sym] .hnd.h[`core.rdb](?;`trade;enlist (=;`sym; enlist sym);(`sym`minute)!(`sym;(xbar;n;`time.minute));(enlist `price)!enlist (last;`price))};

/F/orders from rdb quote table for which bid size was greater than average by symbol 
/E/.example.bigBuyOrders[]
.example.bigBuyOrders:{[] .hnd.h[`core.rdb]"select from quote where bidSize > (avg;bidSize) fby sym"};;

/F/open, high, low, close, volume-weighted average price from hdb trade table
/F/aggreagted by date, symbol and time bars defined by binSize
/F/where date is in d and time between  sTime and eTime, symbol in sym list
/P/sym:SYMBOL - list of securities symbols
/P/d:DATE - list of dates
/P/sTime:TIME - start time
/P/eTime:TIME - end time
/P/binSize:LONG - number of seconds
/E/syms: exec sym from .hnd.h[`core.hdb]("2#select from trade");    
/E/.example.ohlcVwap[syms;.z.d; 08:00:00; 20:00:00; 600]
.example.ohlcVwap:{[sym;d;sTime;eTime;binSize]
 aggrs:`open`high`low`close`size`vwap!((first;`price);(max;`price);(min;`price);(last;`price);(sum;`size);(%;(wsum;`size;`price);(sum;`size)));
  bys:`date`sym`time!(`date;`sym;(xbar;binSize;`time.second));
  wheres:((in; `date; d);(in;`sym; enlist sym);(within;`time;(sTime;eTime)));
  .hnd.h[`core.hdb] (?;`trade;wheres;bys;aggrs)
  };

/F/open, high, low, close, volume-weighted average price from rdb and hdb trade table
/F/aggreagted by date, symbol and time bars defined by binSize
/F/where date is in d and time between  sTime and eTime, symbol in sym list
/P/sym:SYMBOL - list of securities symbols
/P/d:DATE - list of dates
/P/sTime:TIME - start time
/P/eTime:TIME - end time
/P/binSize:LONG - number of seconds
/E/syms: exec sym from .hnd.h[`core.hdb]("2#select from trade");    
/E/.example.ohlcVwap2[syms;(.z.d-2;.z.d); 08:00:00; 20:00:00; 600]    
.example.ohlcVwap2:{[sym;d;sTime;eTime;binSize]
  aggrs: `open`high`low`close`size`vwap!("first price";"max price";"min price";"last price";"sum size";"size wavg price");
  bys:(`sym`time)!(`sym;(xbar;binSize;`time.second));
  wheres:((in;`sym; enlist sym);(within;`time;(sTime;eTime)));
  .query.data[`core.rdb`core.hdb;`trade;wheres;d;bys;aggrs]
  };

