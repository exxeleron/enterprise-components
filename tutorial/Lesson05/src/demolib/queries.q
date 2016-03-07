//----------------------------------------------------------------------------//
/S/ A library with custom queries on quote and trade tables.
/S/ Each query represents one basic financial case. 

//----------------------------------------------------------------------------//
// auxiliary library used for merging rdb and hdb results in .example.ohlcVwap2[] function
.sl.lib["qsl/query"];

//----------------------------------------------------------------------------//
/F/ Returns records number of rdb quote table by hour.
/R/ :TABLE - keyed table with one row for each hour with the data
/-/  -- hh:INT - hour
/-/  -- cnt:LONG - number of records within an hour
/E/ .example.tradeStats[]
.example.tradeStats:{[] .hnd.h[`core.rdb] "select cnt:count i by time.hh from quote"};

//----------------------------------------------------------------------------//
/F/ Returns quote and trade tables records joined based on time and sym columns.
/R/ :TABLE - table with one row for each hour with the data
/-/  -- time:TIME    - timestamp from the trade table
/-/  -- sym:SYMBOL   - instrument name
/-/  -- price:FLOAT  - price from trade table
/-/  -- size:LONG    - size from trade table
/-/  -- bid:FLOAT    - last bid entry from quote table with timestamp just before trade time
/-/  -- bidSize:LONG - last bidSize entry from quote table with timestamp just before trade time
/-/  -- ask:FLOAT    - last ask entry from quote table with timestamp just before trade time
/-/  -- askSize:LONG - last askSize entry from quote table with timestamp just before trade time
/E/ .example.tradeAndQuote[]
.example.tradeAndQuote:{[] .hnd.h[`core.rdb] "aj[`sym`time;trade;quote]"};

//----------------------------------------------------------------------------//
/F/ Returns last price by symbol from rdb trade table.
/R/ :TABLE - keyed table with one row for each instrument
/-/  -- sym:SYMBOL - instrument
/-/  -- price:LONG - last price
/E/ .example.currentPrices[]
.example.currentPrices:{[] .hnd.h[`core.rdb] "select last price by sym from trade"};

//----------------------------------------------------------------------------//
/F/ Returns volume-weighted average price by symbol from rdb.
/R/ :TABLE - table with one row for each instrument
/-/  -- sym:SYMBOL  - instrument
/-/  -- vwawp:FLOAT - vwap
/E/ .example.vwap[]
.example.vwap:{[] .hnd.h[`core.rdb] "select vwap: size wavg price by sym from trade"};

//----------------------------------------------------------------------------//
/F/ Returns volume-weighted average price by symbol from rdb, functional form.
/R/ :TABLE - keyed table with one row for each instrument
/-/  -- sym:SYMBOL  - instrument
/-/  -- vwawp:FLOAT - vwap
/E/ .example.functionalVwap[]
.example.functionalVwap:{[] .hnd.h[`core.rdb](?;`trade;();(enlist `sym)!enlist `sym;(enlist `vwap)!enlist (wavg;`size;`price))};

//----------------------------------------------------------------------------//
/F/ Returns volume-weighted average price by symbol and date from hdb.
/R/ :TABLE - keyed table with one row for each instrument
/-/  -- sym:SYMBOL  - instrument
/-/  -- date:DATE   - date
/-/  -- vwawp:FLOAT - vwap
/E/ .example.dailyVwap[]
.example.dailyVwap:{[] .hnd.h[`core.hdb] "select vwap: size wavg price by sym,date from trade"};

//----------------------------------------------------------------------------//
/F/ Returns last price in 10 minutes bars for first symbol in rdb trade table.
/R/ :TABLE - keyed table with one row for each minute with the data
/-/  -- minute:MINUTE - minute
/-/  -- price:FLOAT   - last price within the minute
/E/ .example.lastPrice10MinutesBar[]
.example.lastPrice10MinutesBar:{[] .hnd.h[`core.rdb] "select last price by 15 xbar time.minute from trade where sym = first sym"};

//----------------------------------------------------------------------------//
/F/ Returns last price in n minutes bars for symbol sym in rdb trade table.
/P/ n:LONG     - the number of minutes 
/P/ sym:SYMBOL - name of the security symbol
/R/ :TABLE - keyed table with one row for each minute with the data
/-/  -- sym:SYMBOL    - instrument
/-/  -- minute:MINUTE - minute
/-/  -- price:FLOAT   - last price within the n-minutes interval
/E/ .example.functionalLastPriceNMinutesBar[30j; `instr0]
.example.functionalLastPriceNMinutesBar:{[n;sym] .hnd.h[`core.rdb](?;`trade;enlist (=;`sym; enlist sym);(`sym`minute)!(`sym;(xbar;n;`time.minute));(enlist `price)!enlist (last;`price))};

//----------------------------------------------------------------------------//
/F/ Returns orders from rdb quote table for which bid size was greater than average by symbol.
/R/ :TABLE - table with entries from quote table
/-/  -- time:TIME    - timestamp
/-/  -- sym:SYMBOL   - instrument name
/-/  -- bid:FLOAT    - bid
/-/  -- bidSize:LONG - bidSize
/-/  -- ask:FLOAT    - ask
/-/  -- askSize:LONG - askSize
/E/ .example.bigBuyOrders[]
.example.bigBuyOrders:{[] .hnd.h[`core.rdb]"select from quote where bidSize > (avg;bidSize) fby sym"};;

//----------------------------------------------------------------------------//
/F/ Calculates open, high, low, close, volume-weighted average price from hdb trade table.
/P/ sym:SYMBOL   - list of securities symbols
/P/ d:DATE       - list of dates
/P/ sTime:TIME   - start time
/P/ eTime:TIME   - end time
/P/ binSize:LONG - number of seconds in one bin
/R/ :TABLE - data aggreagted by date, symbol and time bars defined by binSize, 
/-/         where date is in d and time between  sTime and eTime, symbol in sym list
/-/  -- date:DATE    - date
/-/  -- sym:SYMBOL   - instrument name
/-/  -- time:TIME    - timestamp
/-/  -- open:FLOAT   - first price within given time-bar
/-/  -- high:FLOAT   - maximum price within given time-bar
/-/  -- low:FLOAT    - minimum price within given time-bar
/-/  -- close:FLOAT  - last price within given time-bar
/-/  -- size:LONG    - total volume within given time-bar
/-/  -- vwap:LONG    - vwap within given time-bar
/E/ .example.ohlcVwap[exec sym from .hnd.h[`core.hdb]("2#select from trade");.z.d; 08:00:00; 20:00:00; 600]
.example.ohlcVwap:{[sym;d;sTime;eTime;binSize]
  aggrs:`open`high`low`close`size`vwap!((first;`price);(max;`price);(min;`price);(last;`price);(sum;`size);(%;(wsum;`size;`price);(sum;`size)));
  bys:`date`sym`time!(`date;`sym;(xbar;binSize;`time.second));
  wheres:((in; `date; d);(in;`sym; enlist sym);(within;`time;(sTime;eTime)));
  .hnd.h[`core.hdb] (?;`trade;wheres;bys;aggrs)
  };

//----------------------------------------------------------------------------//
/F/ Calculates open, high, low, close, volume-weighted average price from rdb and hdb trade table.
/P/ sym:SYMBOL   - list of securities symbols
/P/ d:DATE       - list of dates
/P/ sTime:TIME   - start time
/P/ eTime:TIME   - end time
/P/ binSize:LONG - number of seconds
/R/ :TABLE - data aggreagted by date, symbol and time bars defined by binSize, 
/-/         where date is in d and time between  sTime and eTime, symbol in sym list
/-/  -- date:DATE    - date
/-/  -- sym:SYMBOL   - instrument name
/-/  -- time:TIME    - timestamp
/-/  -- open:FLOAT   - first price within given time-bar
/-/  -- high:FLOAT   - maximum price within given time-bar
/-/  -- low:FLOAT    - minimum price within given time-bar
/-/  -- close:FLOAT  - last price within given time-bar
/-/  -- size:LONG    - total volume within given time-bar
/-/  -- vwap:LONG    - vwap within given time-bar
/E/ .example.ohlcVwap2[exec sym from .hnd.h[`core.hdb]("2#select from trade");(.z.d-2;.z.d); 08:00:00; 20:00:00; 600]    
.example.ohlcVwap2:{[sym;d;sTime;eTime;binSize]
  aggrs: `open`high`low`close`size`vwap!("first price";"max price";"min price";"last price";"sum size";"size wavg price");
  bys:(`sym`time)!(`sym;(xbar;binSize;`time.second));
  wheres:((in;`sym; enlist sym);(within;`time;(sTime;eTime)));
  .query.data[`core.rdb`core.hdb;`trade;wheres;d;bys;aggrs]
  };

//----------------------------------------------------------------------------//
