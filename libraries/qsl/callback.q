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

/A/ DEVnet: Slawomir Kolodynski
/V/ 3.0

/S/ Callbacks management library.

//----------------------------------------------------------------------------//
//                          interface functions                               //
//----------------------------------------------------------------------------//
/F/ Adds a callback function (fun) to a collection of callbacks executed with given name (cb).
/-/ Takes into account order specified by (.cb.setLast[cb;fun]) function.
/P/ cb:SYMBOL  - name of the collection of callbacks that has to be added to
/P/ fun:SYMBOL - name of the new function that has to be added
/R/ :INT - number of functions added so far to the callback name (cb), including this one
/E/ .cb.add[`.z.exit;`.example.onExit]
/-/     - .example.onExit[] callback function is added to a list of callbacks with name .z.exit
/-/     - .example.onExit[] will be executed once the .z.exit[] is triggered
/E/ .cb.add[`.z.exit;`.example.onExit2]
/-/     - adding second callback function to the same callback name
/-/     - now .z.exit exeuction will trigger two callbacks: .example.onExit[] and .example.onExit2[]
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

//----------------------------------------------------------------------------//
/F/ Removes a callback function (fun) from a collection of callbacks executed with given name (cb).
/P/ cb:SYMBOL  - name of the collection of callbacks that has to be deleted from
/P/ fun:SYMBOL - name of the function that has to be deleted
/R/ :INT - number of functions remaining in a callback name (cb)
/E/ .cb.del[`.z.exit;`.example.onExit]
/-/     - .example.onExit[] is removed from a list of callbacks with name .z.exit
/-/     - .example.onExit[] will no longer be executed once the .z.exit[] is triggered
.cb.del:{[cb;fun]
  if[not cb in key .cb.status;:0i];
  if[0<count w:where (xx:.cb.status[cb;`function])=fun;.cb.status[cb;`function]:xx[(til count xx) except last w]];
  if[0~count .cb.status[cb;`function];.cb.reset[cb];:0i];
  :count .cb.status[cb];
  };

//----------------------------------------------------------------------------//
/F/ Resets a callback. Removes all functions executed with given (cb) name.
/P/ cb:SYMBOL - name of the collection of callbacks that has to be cleared
/R/ no return value
/E/ .cb.reset[`.z.exit]
/-/     - list of callbacks with name .z.exit is empty
.cb.reset:{[cb]
  .cb.status:.cb.status _cb;
  if[cb in key .cb.p.back;cb set .cb.p.back[cb]];
  if[(cb in key .cb.p.back) and (cb in key .cb.p.exceptions) and {}~.cb.p.back[cb]; cb set .cb.p.exceptions cb];
  };

//----------------------------------------------------------------------------//
/F/ Sets (fun) callback function as the first one to be executed when the (cb) callback collection is triggered. 
/-/ This information about the order will persist no matter if this function has been already added or not. 
/-/ *Note:* If the function was marked before as the last one for given callback, 
/-/         then that mark will be removed as it cannot be marked as first and last at the same time.
/P/ cb:SYMBOL  - name of the collection of callbacks
/P/ fun:SYMBOL - name of the function that should be executed as the first one
/R/ :INT - the number of callbacks in the (cb) collection
/E/ .cb.setFirst[`.z.exit;`.example.onExit2]
/-/     - now .example.onExit2 will be executed always as first callback when .z.exit happens
.cb.setFirst:{[cb;fun]
  if[fun~.cb.last[cb];
    .log.warn[`cb] "Function ",string[fun]," was already marked as last for callback ",string[cb], " in .cb.last. It will be removed from .cb.last";
    .cb.last:cb _ .cb.last;
    ];
  if[(cb in key .cb.first) and (not .cb.first[cb]~fun);
    .log.warn[`cb] ".cb.first for callback ",string[cb]," was already set to ",string[.cb.first[cb]], ". It will be overwritten with ", string[fun];
  ];
  .log.debug[`cb] "Plugin ",string[fun]," for callback ",string[cb]," will be always called as first one.";
  .cb.first[cb]:fun;
  if[fun in .cb.status[cb;`function];
    .cb.status[cb;`function]:fun,(.cb.status[cb;`function] except fun);
    :count .cb.status[cb;`function]
    ];
  };

//----------------------------------------------------------------------------//
/F/ Sets (fun) callback function as the last one to be executed when the (cb) callback collection is triggered. 
/-/ This information about the order will persist no matter if this function has been already added or not.
/-/ *Note:* If the function was marked before as the first one for given callback, 
/-/         then this mark will be removed as a function cannot be marked as first and last at the same time.
/P/ cb:SYMBOL  - name of the collection of callbacks
/P/ fun:SYMBOL - name of the function that should be executed as the last one
/R/ :INT - the number of callbacks in (cb) collection
/E/ .cb.setLast[`.z.exit;`.example.onExit]
/-/     - now .example.onExit will be executed always as last callback when .z.exit happens
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

//----------------------------------------------------------------------------//
//                                 private                                    //
//----------------------------------------------------------------------------//
/G/ To create .cb.p namespace.
.cb.p.dummy:0i;

/-------- setting up data structures on the first load ------------------------/

if[not `status in key .cb;
/G/ List of currently defined callbacks, including call count and timestamp of the last call.
/-/  -- callback:SYMBOL      - Callback (collection) name. This is typically a standard q callback like `.z.po or `.z.pc.
/-/  -- function:LIST SYMBOL - A column holding the lists of names of functions to be executed.
/-/  -- lastCall:TIMESTAMP   - The timestamp of the last callback call.
/-/  -- callCount:SHORT      - Counts the number of times the callback was called.
  .cb.status:([callback:`$()] function:();lastCall:`timestamp$();callCount:`int$())
  ];

if[not `first in key .cb;
/G/ Dictionary with mapping: callback -> first function to execute. Managed via .cb.setFirst[].
/-/  -- key:SYMBOL   - Callback (collection) name. This is typically a standard q callback like `.z.po or `.z.pc.
/-/  -- value:SYMBOL - Name of function to be executed as first for the given callback.
  .cb.first:(`symbol$())!(`symbol$())
  ];

if[not `last in key .cb;
/G/ Dictionary with mapping: callback -> last function to execute. Managed via .cb.setLast[].
/-/  -- key:SYMBOL   - Callback (collection) name. This is typically a standard q callback like `.z.po or `.z.pc.
/-/  -- value:SYMBOL - Name of function to be executed as last for the given callback.
  .cb.last:(`symbol$())!(`symbol$())
  ];

if[not `back in key .cb.p;
  .cb.p.back:()!()
  ];

.cb.p.exceptions:(`.z.pw`.z.pg`.z.ps`.z.pi)!({[x;y]1b};value;value;{.Q.s value x});
