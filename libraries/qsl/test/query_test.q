/L/ Copyright (c) 2011-2014 Exxeleron GmbH
/L/
/L/ Licensed under the Apache License, Version 2.0 (the "License");
/L/ you may not use this file except in compliance with the License.
/L/ You may obtain a copy of the License at
/L/
/L/   http://www.apache.org/licenses/LICENSE-2.0
/L/
/L/ Unless required by applicable law or agreed to in writing, software
/L/ distributed under the License is distributed on an "AS IS" BASIS,
/L/ WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
/L/ See the License for the specific language governing permissions and
/L/ limitations under the License.

// Usage:
// q test/query_test.q --noquit -p 5001

system"l lib/qspec/qspec.q";
system "l sl.q";
system "l pe.q";
system "l event.q";
.sl.init[`test_query];
system "l handle.q";
.tst.desc["[query.q] query data - .query.data"]{
  before{
    system "l query.q";
    delete h from `.hnd;
    `.data.rdb mock  ([] sym:`a`b`a`b; price:1 2 10 20; size:til 4);
    `.data.hdb mock  ([] date:(4#.z.d-2),4#.z.d-1; sym:`a`b`a`b`a`b`a`b; price:1 2 10 20 3 4 30 40; size:til 8);
    `.hnd.h.rdb mock {`trade set .data.rdb;0 x};
    `.hnd.h.hdb mock {`trade set .data.hdb;0 x};
    `.hnd.h.test mock {'undefined};
    };
  should["select data from rdb"]{
    (`date xcols update date:.z.d from .data.rdb) mustmatch .query.data[servers:`rdb`hdb;`trade;();.z.d;0b;()];
    };
  should["select data from hdb for one day"]{
    (-4#.data.hdb) mustmatch .query.data[servers:`rdb`hdb;tab:`trade;cond:();day:.z.d-1;gr:0b;col:()];
    };
  should["select data from hdb for more then one day"]{
    .data.hdb mustmatch .query.data[servers:`rdb`hdb;tab:`trade;cond:();day:.z.d-(1;2);gr:0b;col:()];
    };
  should["select data from rdb and hdb"]{
    ((-4#.data.hdb),`date xcols update date:.z.d from .data.rdb) mustmatch .query.data[servers:`rdb`hdb;tab:`trade;cond:();day:.z.d-(0;1);gr:0b;col:()];
    };
  should["select data from rdb with constraints"]{
    (`date xcols update date:.z.d from .data.rdb[0 2]) mustmatch .query.data[servers:`rdb`hdb;`trade;((=;`sym;enlist `a);(>;`price;0));.z.d;0b;()];
    };
  should["select data from hdb with constraints"]{
    .data.hdb[4 6] mustmatch .query.data[servers:`rdb`hdb;`trade;((=;`sym;enlist `a);(>;`price;0));.z.d-1;0b;()];
    };
  should["select data from hdb for more then one day with constraints"]{
    .data.hdb[0 2 4 6] mustmatch .query.data[servers:`rdb`hdb;`trade;((=;`sym;enlist `a);(>;`price;0));.z.d-(1;2);0b;()];
    };
  should["select data from rdb and hdb with constraints"]{
    (.data.hdb[4 6],(`date xcols update date:.z.d from .data.rdb[0 2])) mustmatch .query.data[servers:`rdb`hdb;`trade;((=;`sym;enlist `a);(>;`price;0));.z.d-(0;1);0b;()];
    };
  should["select data from rdb with grouping"]{
    (2!`date xcols update date:.z.d from .data.rdb[2 3]) mustmatch .query.data[servers:`rdb`hdb;`trade;();.z.d;enlist[`sym]!enlist `sym;()];
    (2!`date xcols update date:.z.d from delete size from .data.rdb[2 3]) mustmatch .query.data[servers:`rdb`hdb;`trade;();.z.d;enlist[`sym]!enlist `sym;(enlist `price)!enlist (last;`price)];
    };
  should["select data from hdb with grouping"]{
    (2!.data.hdb[6 7]) mustmatch .query.data[servers:`rdb`hdb;`trade;();.z.d-1;enlist[`sym]!enlist `sym;()];
    (2!delete size from .data.hdb[6 7]) mustmatch .query.data[servers:`rdb`hdb;`trade;();.z.d-1;enlist[`sym]!enlist `sym;(enlist `price)!enlist (last;`price)];
    };
  should["select data from hdb for more then one day with grouping"]{
    (2!.data.hdb[2 3 6 7]) mustmatch .query.data[servers:`rdb`hdb;`trade;();.z.d-(1;2);enlist[`sym]!enlist `sym;()];
    (2!delete size from .data.hdb[2 3 6 7]) mustmatch .query.data[servers:`rdb`hdb;`trade;();.z.d-(1;2);enlist[`sym]!enlist `sym;(enlist `price)!enlist (last;`price)];
    };
  should["select data from rdb and hdb with grouping"]{
    ((2!.data.hdb[6 7]),(2!`date xcols update date:.z.d from .data.rdb[2 3])) mustmatch .query.data[servers:`rdb`hdb;`trade;();.z.d-(0;1);enlist[`sym]!enlist `sym;()];
    ((2!delete size from .data.hdb[6 7]),  (2!`date xcols update date:.z.d from delete size from .data.rdb[2 3])) mustmatch .query.data[servers:`rdb`hdb;`trade;();.z.d-(0;1);enlist[`sym]!enlist `sym;(enlist `price)!enlist (last;`price)];
    };
  should["select data from rdb with specified columns"]{
    (`date xcols update date:.z.d from delete price from .data.rdb) mustmatch .query.data[servers:`rdb`hdb;`trade;();.z.d;0b;(`sym`size)!`sym`size];
    };
  should["select data from hdb with specified columns"]{
    (delete price from -4#.data.hdb) mustmatch .query.data[servers:`rdb`hdb;`trade;();.z.d-1;0b;(`sym`size)!`sym`size];
    };
  should["select data from hdb for more then one day with specified columns"]{
    (delete price from .data.hdb) mustmatch .query.data[servers:`rdb`hdb;`trade;();.z.d-(1;2);0b;(`sym`size)!`sym`size];
    };
  should["select data from rdb and hdb with specified columns"]{
    ((delete price from -4#.data.hdb), (`date xcols update date:.z.d from delete price from .data.rdb)) mustmatch .query.data[servers:`rdb`hdb;`trade;();.z.d-(0;1);0b;(`sym`size)!`sym`size];
    };
  should["select data from rdb and hdb with constraints, grouping and specified columns"]{
    ((2!delete size from .data.hdb[2 6]),  (2!`date xcols update date:.z.d from delete size from .data.rdb[enlist 2])) mustmatch .query.data[servers:`rdb`hdb;`trade;enlist (=;`sym;enlist `a);.z.d-(0;2);enlist[`sym]!enlist `sym;(enlist `price)!enlist (last;`price)];
    };
  should["throw error if data cannot be retrieved from rdb"]{
    `.hnd.h.rdb mock .hnd.h.test;
    mustthrow["rdb[`rdb] signals '[undefined] after query: (?;`trade;,();0b;())";{.query.data[servers:`rdb`hdb;`trade;();.z.d;0b;()]}];
    };
  should["throw error if data cannot be retrieved from hdb"]{
    `.hnd.h.hdb mock .hnd.h.test;
    mustthrow["hdb[`hdb] signals '[undefined] after query: (?;`trade;,,(within;`date;2011.01.01 2011.01.01);0b;())";{.query.data[servers:`rdb`hdb;`trade;();2011.01.01;0b;()]}];
    };
  };
