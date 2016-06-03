/L/ Copyright (c) 2011-2014 Exxeleron GmbH
/-/
/-/ Licensed under the Apache License, Version 2.0 (the "License");
/-/ you may not use this file except in compliance with the License.
/-/ You may obtain a copy of the License at
/-/
/-/   http://www.apache.org/licenses/LICENSE-2.0
/-/
/-/ Unless required by applicable law or agreed to in writing, software
/-/ distributed under the License is distributed on an "AS IS" BASIS,
/-/ WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
/-/ See the License for the specific language governing permissions and
/-/ limitations under the License.
/-/ 
/-/ Based on the code from Kx:
/-/ http://code.kx.com/wsvn/code/kx/kdb%2Btick/tick/u.q

/S/ u.q library:
/-/ Provides API for subscription to data publishing in tickHF protocol

/-/ Functionality:
/-/ - maintains subscription lists
/-/ - end-of-day callback to all subribers
/-/ All functions are defined in namespace .u

/------------------------------------------------------------------------------/
.sl.init[`u];

/------------------------------------------------------------------------------/
/2008.09.09 .k -> .q
/2006.05.08 add

\d .u
/F/ Initializes subscription library, all tables in the top level namespace (`.) become publish-able.
/-/   Tables that can be published can be seen in .u.w.
/R/ no return value
/E/ .u.init[]
init:{[]
  .cb.add[`.z.pc;`.u.pc];
  w::t!(count t::tables`.)#()
  };

/F/ Deletes connection handle from subscription list, invoked automatically on port close (.u.pc).
/P/ x:SYMBOL - table name
/P/ y:INT    - connection handle
/R/ no return value
/E/ .u.del[`trade;.z.w]
del:{[x;y] w[x]_:w[x;;0]?y};

/F/ Handles disconnection of a client, removes all subscriptions using (.u.del). Invoked on (.z.pc) q callback.
/P/ x:INT - connection handle
/R/ no return value
/E/ .u.pc[12i]
/-/     removes client from handle 12i from all subscriptions (for any table that was subscribed).
pc:{[x] if[not x in first'[raze value .u.w];:()]; .log.info[`u]"Removing subscription on h:",.Q.s1 x; del[;x]each t};

/F/ Selects subset of the data. Internal helper function used during data distribution.
/P/ x:TABLE - table with data
/P/ y:ITEM  - list of items that should be subscribed, type should match type of the sym column in the given table
/-/       ` is wildcard for all
/R/ TABLE - if y=` returns entire x table, otherwise returns subset of rows where sym column is limited to y
/E/ .u.sel[`trade;`a]
sel:{[x;y] $[`~y;x;select from x where sym in y]};

/F/ Publishes data to all subscribers asynchronously as upd[tab;data] callback.
/-/    Data is publised according to subscription information stored in .u.w.
/-/    Connection handle is usd to call upd function on the client site functions to publish data.
/P/ t:SYMBOL - table name, must be one of tables initialized with .u.init[]
/P/ x:TABLE  - table data, there is no checking to ensure that the table being published matches the correct table schema 
/-/            that is left up to the programmer!
/R/ no return value
/E/ .u.pub[`trade;([]time:.z.t;price:1 2 3.;size:100 200 300)]
pub:{[t;x]
  {[t;x;w]if[count x:sel[x]w 1;(neg first w)(`upd;t;x)]}[t;x]each w t
  };

/F/ Extends client subscribtion for the given tables/instruments combination.
/P/ x:SYMBOL               - table name
/P/ y:SYMBOL | LIST SYMBOL - list of symbols specified by the subscriber, if ` than select all instruments
/R/ PAIR(SYMBOL;MODEL) - pair (table name;table model as an empty q table)
/E/ .u.add[`trade;enlist`.STOXX50E]
/-/     - adds `.STOXX50E for the `trade subscription, previously subscribed instruments will remain.
add:{$[(count w x)>i:w[x;;0]?.z.w;.[`.u.w;(x;i;1);union;y];w[x],:enlist(.z.w;y)];(x;$[99=type v:value x;sel[v]y;0#v])};

/F/ Subscribes client for the given tables/instruments combination.
/-/   If a subscriber calls (.u.sub) again, the current subscription will be overwritten either for all tables (if a wildcard is used) or the specified table. 
/-/   To add to a subscription (e.g. add more syms to a current subscription) the subscriber can call (.u.add).
/P/ x:SYMBOL               - table name specified by the subscriber, if ` then subscribe all tables
/P/ y:SYMBOL | LIST SYMBOL - list of symbols specified by the subscriber, if ` then subscribe all instruments
/R/ LIST(PAIR(SYMBOL;MODEL)) - list of pairs (table name;table model as an empty q table)
/E/ .u.sub[`;`]
/-/    - subscribe all tables for all instruments
/E/ .u.sub[`trade;`]
/-/    - subscribe trade table for all instruments
/E/ .u.sub[`trade;`.GDAXI`.STOXX]
/-/    - subscribe trade table for `.GDAXI and `.STOXX instruments, previously subscribed instruments will be removed.
sub:{[x;y]
  if[x~`;
    :sub[;y]each t
    ];
  if[not x in t;'x];
  del[x].z.w;
  .log.info[`u] "Subscription request on h:",(.Q.s1 .z.w),". Table:",(.Q.s1 x),". Sym:",.Q.s1 y;
  add[x;y]
  };

/F/ End-of-day callback that is send to all subribers defined in .u.w.
/P/ x:DATE - current date
/R/ no return value
/E/ .u.end[.z.d]
/-/    - triggers end-of-day for today
/-/    - publishes .u.end[] signal to all subscribers
end:{.log.info[`u] "Broadcasting EOD to subscribers."; (neg union/[w[;;0]])@\:(`.u.end;x)};

/==============================================================================/
\
