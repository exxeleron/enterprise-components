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

/A/ DEVnet: Slawomir Kolodynski
/V/ 3.0

/S/ Callback library:
/S/ .cb.status - table that handles collection of added callbacks
/S/ - callback - callback (collection) name. This is typically a standard q callback like `.z.po or `.z.pc.
/S/ - function - a column holding the lists of names of functions to be executed
/S/ - lastCall - the timestamp of the last callback call.
/S/ - callCount - counts the number of times the callback was called.


/.sl.init[`cb];

/F/ adds a callback to a collection; takes into account order specified by <.cb.setLast[cb;fun]> function
/P/ cb:SYMBOL - name of the collection of callbacks that has to be added
/P/ fun:SYMBOL - name of the function that we want to add
/R/ :INT - number of functions defined in a callback, including this one
.cb.add:{[cb;fun]
  if[not cb in key .cb.status; // first callback in this collection
    .pe.at[{[x] .cb.p.back[x]:value x;.log.warn[`cb] "overwriting existing variable ",(string cb)," to create a callback collection"};cb;{[x;y].cb.p.back[x]:{}}[cb]];
    .cb.status[cb]:(enlist fun;0Np;0i);
    cb set {[x;y] .cb.status[x;`lastCall]:.sl.zp[];.cb.status[x;`callCount]+:1i;:last .cb.status[x;`function] @\: y}[cb];
    :1i;
    ];
  .cb.status[cb;`function]:(.cb.first[cb],((distinct .cb.status[cb;`function],fun) except .cb.last[cb],.cb.first[cb]),.cb.last[cb]) except `;
  :count .cb.status[cb;`function]
  };

/F/ removes a function from a collection
/P/ cb:SYMBOL - name of the collection of callbacks that has to be deleted
/P/ fun:SYMBOL - name of the function that we want to delete
/R/ :INT - number of functions remaining in a callback
.cb.del:{[cb;fun]
  if[not cb in key .cb.status;:0i];
  if[0<count w:where (xx:.cb.status[cb;`function])=fun;.cb.status[cb;`function]:xx[(til count xx) except last w]];
  if[0~count .cb.status[cb;`function];.cb.reset[cb];:0i];
  :count .cb.status[cb];
  };

/F/ resets a callback; all functions in a callback are removed
/P/ cb:SYMBOL - name of the collection of callbacks
.cb.reset:{[cb]
  .cb.status:.cb.status _cb;
  if[cb in key .cb.p.back;cb set .cb.p.back[cb]];
  if[(cb in key .cb.p.back) and (cb in key .cb.p.exceptions) and {}~.cb.p.back[cb]; cb set .cb.p.exceptions cb];
  };

/F/ sets given function as the first in the callback collection; 
/F/ this information about order will persist no matter if this function has been already added or not; 
/F/ *Note:* if the function was marked before as the last one for given callback, 
/F/       then that mark will be removed as it cannot be marked as first and last at the same time
/P/ cb:SYMBOL - name of the collection of callbacks
/P/ fun:SYMBOL - name of the function 
/R/ :INT - the number of callbacks in this collection
.cb.setFirst:{[cb;fun]
  if[fun~.cb.last[cb];
    .log.warn[`cb] "Function ",string[fun]," was already marked as last for callback ",string[cb], " in .cb.last. It will be removed from .cb.last";
    .cb.last:cb _ .cb.last;
    ];
  if[(cb in key .cb.first) and (not .cb.first[cb]~fun);
    .log.warn[`cb] ".cb.first for callback ",string[cb]," was already set to ",string[.cb.first[cb]], ". It will be overwritten with ", string[fun];
  ];
  .log.info[`cb] "Plugin ",string[fun]," for callback ",string[cb]," will be always called as first one.";
  .cb.first[cb]:fun;
  if[fun in .cb.status[cb;`function];
    .cb.status[cb;`function]:fun,(.cb.status[cb;`function] except fun);
    :count .cb.status[cb;`function]
    ];
  };

/F/ sets given function as the last (the one that return the value) in the callback collection;
/F/ this information about order will persist no matter if this function has been already added or not.
/F/ *Note:* if the function was marked before as the first one for given callback, 
/F/       then this mark will be removed as a function cannot be marked as first and last at the same time
/P/ cb:SYMBOL - name of the collection of callbacks
/P/ fun:SYMBOL - name of the function 
/R/ :INT - the number of callbacks in this collection
.cb.setLast:{[cb;fun]
  if[fun~.cb.first[cb];
    .log.warn[`cb] "Function ",string[fun]," was already marked as first for callback ",string[cb], " in .cb.first. It will be removed from .cb.first";
    .cb.first:cb _ .cb.first;
    ];
  if[(cb in key .cb.last) and (not .cb.last[cb]~fun);
    .log.warn[`cb] ".cb.last for callback ",string[cb]," was already set to ",string[.cb.last[cb]], ". It will be overwritten with ", string[fun];
    ];
  .log.info[`cb] "Plugin ",string[fun]," for callback ",string[cb]," will be always called as last one.";
  .cb.last[cb]:fun;
  if[fun in .cb.status[cb;`function];
    .cb.status[cb;`function]:(.cb.status[cb;`function] except fun),fun;
    :count .cb.status[cb;`function]
    ];
  };

/----------- private ----------------------------------------------------------
/G/ to create .cb.p namespace
.cb.p.dummy:0i;

/-------- setting up data structures on the first load ------------------------

if[not `status in key .cb;.cb.status:([callback:`$()] function:();lastCall:`timestamp$();callCount:`int$())];
if[not `first in key .cb;.cb.first:(`symbol$())!(`symbol$())];
if[not `last in key .cb;.cb.last:(`symbol$())!(`symbol$())];
if[not `back in key .cb.p;.cb.p.back:()!()];
.cb.p.exceptions:(`.z.pw`.z.pg`.z.ps`.z.pi)!({[x;y]1b};value;value;{.Q.s value x});
