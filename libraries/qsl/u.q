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
/L/ 
/L/ Based on the code from Kx:
/L/ http://code.kx.com/wsvn/code/kx/kdb%2Btick/tick/u.q

/S/ u.q library:
/S/ Provides API for subscription to data publishing in tickHF protocol

/S/ Functionality:
/S/ - maintains subscription lists
/S/ - end-of-day callback to all subribers
/S/ All functions are defined in namespace .u

/------------------------------------------------------------------------------/
.sl.init[`u];

/------------------------------------------------------------------------------/
/2008.09.09 .k -> .q
/2006.05.08 add

\d .u
/F/ initialize subscription dictionary .u.w and tables .u.t
init:{
  .cb.add[`.z.pc;`.u.pc];
  w::t!(count t::tables`.)#()
  }

/F/ delete connection handle from subscription list
/P/ x:INT - connection handle
del:{w[x]_:w[x;;0]?y};

/F/ closed connection callback 
pc:{if[not x in first'[raze value .u.w];:()]; .log.info[`u]"Removing subscription on h:",.Q.s1 x; del[;x]each t};

/F/ get data for specific symbol list
/P/ x:TABLE - data
/P/ y:LIST SYMBOL - list of symbols specified by the subscriber, if ` than select all data
sel:{$[`~y;x;select from x where sym in y]}

/F/ publish data to each connection handles defined in .u.w.  
/F/ Connection handle is usd to call upd function on the client site
/P/ t:SYMBOL - table name
/P/ x:TABLE - data
pub:{[t;x]
  {[t;x;w]if[count x:sel[x]w 1;(neg first w)(`upd;t;x)]}[t;x]each w t
  }

/F/ add connection handle to subscription dictionary
/P/ x:INT - connection handle
/P/ y:SYMBOL - universe list
add:{$[(count w x)>i:w[x;;0]?.z.w;.[`.u.w;(x;i;1);union;y];w[x],:enlist(.z.w;y)];(x;$[99=type v:value x;sel[v]y;0#v])}

/F/ subscription called from the client
/P/ x:TABLE - data
/P/ y:LIST SYMBOL - list of symbols specified by the subscriber, if ` than select all data
sub:{
  if[x~`;
    :sub[;y]each t
    ];
  if[not x in t;'x];
  del[x].z.w;
  .log.info[`u] "Subscription request on h:",(.Q.s1 .z.w),". Table:",(.Q.s1 x),". Sym:",.Q.s1 y;
  add[x;y]
  }

/F/ end-of-day callback that is send to all subribers defined in .u.w
/P/ x:DATE - current date
end:{.log.info[`u] "Broadcasting EOD to subscribers."; (neg union/[w[;;0]])@\:(`.u.end;x)}

/==============================================================================/
\
