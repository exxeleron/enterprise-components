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

/S/ Connection management library:
/-/ Functionality related to initialization and maintaining connections between q processes.
/-/ The library is loaded automatically in qsl/sl.q (<sl.q>) library.
/-/
/-/ Connection state:
/-/ Connection to the q server can be in one of the following states:
/-/ `registered - connection is added to status table; no attempt to connect to q process was made
/-/ `open       - connection to q process is open and ready to use
/-/ `closed     - connection to q process was closed using .hnd.hclose[]
/-/ `lost       - connection to q process was lost (e.g. q process was terminated)
/-/ `failed     - attempt to connect to q process failed (e.g. q process is not running)
/-/
/-/ Callbacks defined by user:
/-/ .hnd.poAdd[server; function] - adds a callback called when a connection to a server is open
/-/ .hnd.pcAdd[server; function] - adds a callback called when a connection to a server is closed
/-/ .hnd.poDel[server; function] - removes a callback called on port open
/-/ .hnd.pcAdd[server; function] - removes a callback called on port close
/-/ where:
/-/ server   - a symbol with the name of a server
/-/ function - a symbol which is a name of the function to be run; the function should take one parameter that is a symbol with the server name

.sl.lib[`$"qsl/callback"];
.sl.lib[`$"qsl/timer"];

//----------------------------------------------------------------------------//
//                          interface functions                               //
//----------------------------------------------------------------------------//
/F/ Opens tcp connection to q server(s) in [`eager mode] (=immediately) or [`lazy mode] (=deffered untill first use of .hnd.h or .hnd.ah).
/-/  Connection opening can fail due to following reasons:
/-/   - invalid/unknown server name
/-/   - q server not avaiable (e.g. not running or in different network)
/-/   - authentication failure
/-/   - q server available but busy (e.g. execution of long lasting query) - failure after [timeout]ms
/-/  If connection fails, handle library enters auto-reconnection mode and tries to reconnect to the server on timer.
/-/  Opened connection can be used via .hnd.h[server] and .hnd.ah[server].
/-/  Connection can be cloased via .hnd.hclose[servers] function.
/-/  Connection status is available in the .hnd.status global variable.
/-/  It is possible to add custom callbacks executed on connection open and connection closed (see .hnd.poAdd and .hnd.pcAdd)
/P/ servers:SYMBOL | LIST[SYMBOL] | DICTIONARY[SYMBOL;SYMBOL] - one or more q servers
/-/    There are two ways to specify q servers:
/-/    - logical names of the q servers (must be pre-defined in the etc/system.cfg file)
/-/    - dictionary of server names to their connection strings
/P/ tmout:INT - the timeout for opening a connection, 0Ni results in timeout=0.
/-/    it is used in case the server on specified port is running, however it is occupied with some other tasks (e.g. long running query).
/P/ flag:ENUM[`lazy`eager] - connection opened in one of two modes:
/-/   `eager - try to open connection immediately, already during execution of .hnd.hopen function.
/-/   `lazy - register connection parameters only, real connection is created on first usage of .hnd.h or .hnd.ah
/R/ no return value

/E/ .hnd.hopen[`core.rdb`core.hdb; 100i; `eager]
/-/     - opens immediately (`eager) connection to `core.rdb and `core.hdb processes (core.rdb and core.hdb servers must be defined in system.cfg)
/-/     - opening timeout is 100ms, autoreconnection mode will be activated in case of actual timeout 
/-/     - after exeuction the connection can be used via .hnd.h[`core.rdb] and .hnd.ah[`core.rdb]
/E/ .hnd.hopen[`core.hdb; 100i; `lazy]
/-/     - registers connection to `core.hdb
/-/     - after execution the connection can be used via .hnd.h[`core.hdb] and .hnd.ah[`core.hdb]
/-/     - the real connection will be opened on first usage of .hnd.h[`core.hdb] or .hnd.ah[`core.hdb]
/E/ .hnd.hopen[enlist[`rdb]!enlist[`:localhost:5001]; 100i; `eager]
/-/     - opens immediately connection to q running on localhost on port 5001
/-/     - this process does not have to be defined in the system.cfg
/-/     - after exeuction the connection can be used via .hnd.h[`rdb] and .hnd.ah[`rdb]
/E/ .hnd.hopen[`rdb`hdb!(`:localhost:5001;`:localhost:5002); 100i; `eager]
/-/     - open immediately connections to q running on localhost on port 5001 and 5002
.hnd.hopen:{[servers;tmout;flag]
  .log.debug[`handle] "Initializing handle.q library";
  if[not any (99h;-11h;11h)~\:type servers; '"Parameter: servers. Expected type: dictionary (sym!sym), symbol atom  or a list of symbols"];
  if[not -7h~type tmout;tmout:`int$tmout];
  if[not -6h~type tmout; '"Parameter: tmout. Expected type: int"];
  if[null tmout; tmout: 0];
  /G/ Timeout for connection opening, used in .hnd.hopen[] and during reconnections.
  .hnd.tmout:tmout;
  if[11h~abs type servers;
    servers:exec proc!(`$":",/:host,'":",/:string[port],'":",'(string kdb_user),'":",/:(kdb_password)) from .hnd.p.getTechnicalUser[] where proc in servers;
    ];

  // we don't reopen those that are already open, lost or failed
  servers:(exec server from .hnd.status where state in `open`lost`failed)_servers;
  .log.debug[`handle] "  --Registering servers: ", .Q.s1 key servers;
  `.hnd.status upsert ([server:key servers];timeout:tmout;state:`registered;connstr:value servers;handle:.hnd.p.hopenLazy @/: key servers;ashandle:.hnd.p.asHopenLazy @/: key servers;topen:0Np;tclose:0Np;tlost:0Np;reconn:0;msg:(count servers)#enlist"");
  .hnd.p.cb:sr!`$.hnd.p.remdot each sr:1_exec server from .hnd.status;
  .cb.add[`.z.pc;`.hnd.p.pc];
  .hnd.rec[.hnd.p.cb sr]:.hnd.p.rec @/: sr; 
  if[flag~`eager; .hnd.p.hopenEager each key servers];
  .log.debug[`handle] "  --Setup finished";
  };

//----------------------------------------------------------------------------//
/F/ Provides handle for synchronous queries executed on a remote q server (that was connected using .hnd.hopen[]).
/-/ In case of `lazy connection which is used for the first time - provides anynomous function whch opens connection 
/-/   and immediately executes the epxression, giving the user experience that the connection was already opened.
/-/ In case of `eager connection, or `lazy connection that have been alread used - returns handle value
/-/ In case of connection failure - returns meaningful signal
/P/ s:SYMBOL - server logical name
/R/ :FUNCTION[1] | INT - `item` that should be used to execute the query
/-/  either a handle or a function that opens a connection and queries the server
/E/ .hnd.h[`core.rdb]"tables[]"
/-/     - executes synchronous query in form of string "tables[]" on server `core.rdb
/-/     - call returns list of tables available on the `core.rdb process
/E/ .hnd.h[`core.rdb](+;2;3)
/-/     - executes synchronous query in form of tree (+;2;3) on server `core.rdb
/-/     - call returns 5
.hnd.h:{[s].hnd.status[s;`handle]};

/F/ Provides handle for asynchronous queries executed on remote q server (that was connected using .hnd.hopen[]).
/-/ In case of `lazy connection which is used for the first time - provides anynomous function whch opens connection 
/-/   and immediately executes the epxression, giving the user experience that the connection was already opened.
/-/ In case of `eager connection, or `lazy connection that have been alread used - returns handle value
/-/ In case of connection failure - returns meaningful signal
/P/ s:SYMBOL - server name
/R/ :FUNCTION[1] | INT - `item` that should be used to execute the query
/-/  either a handle or a function that opens a connection and queries the server
/E/ .hnd.ah[`core.rdb]"0N!`remoteAsynchCall"
/-/     - executes asynchronous query in form of string "0N!`remoteAsynchCall" on server `core.rdb
/-/     - standard output of `core.rdb process should contain now `remoteAsynchCall
/-/     - .hnd.ah[] is asynchronous - it does not wait until the executed function is completed
/-/     - .hnd.ah[] is not collecting result from the remote execution
/E/ .hnd.ah[`core.rdb](show;"1 2 3")
/-/     - executes asynchronous query in form of tree (show;"1 2 3") on server `core.rdb
/-/     - standard output of `core.rdb process should contain now 1 2 3
.hnd.ah:{[s].hnd.status[s;`ashandle]};

//----------------------------------------------------------------------------//
/F/ Adds a callback function that will be executed just after connection opening.
/-/ Callback can be removed using .hnd.poDel[]
/P/ server:SYMBOL   - server name
/P/ function:SYMBOL - function name; the function will be called every time
/-/ when a connection is open to a server; the function is passed the server name
/R/ no return value
/E/ .hnd.poAdd[`core.rdb; `.example.onRdbOpen]
/-/     - .example.onRdbOpen function is registered to be called once the `core.rdb connection is open
/-/     - following .example.onRdbOpen implementation retreives list of rdb tables into .example.rdbTabs as soon as rdb connection is opened:
/-/       .example.onRdbOpen:{[componentId] .example.rdbTabs:.hnd.h[componentId]"tables[]"};
.hnd.poAdd:{[server;function]
  .cb.add[`$".hnd.po.",(.hnd.p.remdot server);function];
  };

/F/ Adds a callback function that will be executed just before connection closing.
/-/ Callback can be removed using .hnd.pcDel[]
/P/ server:SYMBOL   - server name
/P/ function:SYMBOL - callback function name; the function will be called every time
/-/     when a connection is open to a server; the callback function will receive the server name
/R/ no return value
/E/ .hnd.pcAdd[`core.rdb; `.example.onRdbClose]
/-/     - .example.onRdbClose function is registered to be called once the `core.rdb connection is closed/lost
/-/     - following .example.onRdbClose implementation retreives clears .example.rdbTabs as soon as rdb connection is closed/lost:
/-/       .example.onRdbOpen:{[componentId] .example.rdbTabs:()};
.hnd.pcAdd:{[server;function]
  .cb.add[`$".hnd.pc.",(.hnd.p.remdot server);function];
  };

/F/ Removes a port open callback function registered via .hnd.poAdd[].
/P/ server:SYMBOL   - server name
/P/ function:SYMBOL - the name of the callback function to be removed 
/R/ no return value
/E/ .hnd.poDel[`core.rdb; `.example.onRdbOpen]
/-/     - removes .example.onRdbOpen from `core.rdb list (see .hnd.poAdd example)
.hnd.poDel:{[server;function]
  .cb.del[`$".hnd.po.",(.hnd.p.remdot server);function];
  };

/F/ Removes a port close callback function registered via .hnd.pcAdd[].
/P/ server:SYMBOL   - server name
/P/ function:SYMBOL - the name of the function to be removed
/R/ no return value
/E/ .hnd.pcDel[`core.rdb; `.example.onRdbClose]
/-/     - removes .example.onRdbClose from `core.rdb list (see .hnd.pcAdd example)
.hnd.pcDel:{[server;function]
  .cb.del[`$".hnd.pc.",(.hnd.p.remdot server);function];
  };

//----------------------------------------------------------------------------//
/F/ Refreshes connections to all servers (applies only to servers with state different than `registered).
/P/ servers:LIST SYMBOL - list of servers to refresh, empty backtick (`) to refresh all
/R/ no return value
/E/ .hnd.refresh[`core.rdb]
/-/     - refreshes connection to `core.rdb
/E/ .hnd.refresh[`core.rdb`core.hdb]
/-/     - refreshes connections to `core.rdb and `core.hdb
/E/ .hnd.refresh[`]  
/-/     - refreshes connections to all servers
.hnd.refresh:{[servers]
  if[`~servers;servers:distinct 1_exec server from .hnd.status where not state=`registered];
  .log.info[`handle] "Refreshing connections";
  .hnd.hclose[servers];
  .hnd.p.hopenEager each servers;
  .log.info[`handle] "Finished";
  };

//----------------------------------------------------------------------------//
/F/ Closes connections to q servers which were previously opened with .hnd.hopen[].
/-/ Disconnect from q servers with status `open, stops reconnect timers, updates status.
/-/ Changes status of closed connections to `closed.
/P/ servers:SYMBOL | LIST[SYMBOL] - a single server or a list of servers to be disconnected, empty backtick (`) to stop all
/R/ :INT - count of servers that had been open and were closed
/E/ .hnd.hclose[`core.hdb`core.rdb]
/-/     - closes connection to `core.hdb and `core.rdb servers
.hnd.hclose:{[servers]
  if[1~count .hnd.status;:0]; // .hmd.hopen has not beed called yet
  if[`~servers;servers:1_distinct exec server from .hnd.status];
  // allow a single server as well
  servers:(),servers;
  .tmr.stop each `$".hnd.rec.",/: .hnd.p.remdot each servers;
  openservs: exec server from .hnd.status where server in servers,state=`open;
  hclose each openh: exec handle from .hnd.status where server in openservs, not handle=0;
  .hnd.status[enlist each servers;`state`tclose]:(count servers;2)#(`closed;.sl.zp[]);
  .hnd.status[enlist each servers;`handle]:.hnd.p.hopenLazy @/: servers;
  .hnd.status[enlist each servers;`ashandle]:.hnd.p.asHopenLazy @/: servers;
  // call user defined port close callbacks for all servers that were open
  .hnd.pc[.hnd.p.cb openservs] @' openservs;
  :count openservs
  };

//----------------------------------------------------------------------------//
/F/ Resets all data to the state (almost) the same as after loading handle.q the for first time.
/R/ no return value
/E/ .hnd.reset[]
.hnd.reset:{[]
  .hnd.hclose[`];
  // remove all callbacks
  .cb.reset each exec callback from .cb.status where callback like ".hnd.p[oc].*";
  .cb.reset `.z.pc;
  .hnd.p.setGlobals[];
  };

//----------------------------------------------------------------------------//
//                             private functions                              //
//----------------------------------------------------------------------------//
.hnd.p.getTechnicalUser:{[]
  proc:0!.cr.getByProc[`host`port];
  tu:select kdb_user:sectionVal, kdb_password:pass from 0!.cr.getGroupCfgPivot[`technicalUser;`pass];
  if[1<count tu;
    tu:1#tu;
    .log.warn[`handle]"Only one technical user is allowed. For internal connections user:",string[first tu`kdb_user], " will be used";
    ];
  proc cross tu
  };

/F/ Opens a connection to given string, updates the handle value in the status,
/-/ and performs a query in synhronous mode. This is called with the first .hnd.h call.
/-/ Note that passwords in the connection string are now hashed using xor with
/-/ mask .sl.p.m (empty when code is not compiled). For development time you
/-/ can use "0x",""sv string `byte$"haslo" to generate hashed password without
/-/ a xor mask.
/P/ s:SYMBOL - logical server name
/P/ q:STRING - query string
/R/ :ANY - result of the query
.hnd.p.hopenLazy:{[s;q]
  dxcsp:{dx:{[p;m] `char$0b sv/:m<>/:0b vs/:`int$p}[;.sl.p.m];
    if[(count last c) and 5=count c:":"vs string x;
      :hsym`$":"sv(-1_c),enlist dx[value last c]];:x};
  connstr:dxcsp[.hnd.status[s;`connstr]];
  h:.pe.at[hopen;(connstr;.hnd.status[s;`timeout]);.hnd.p.errHlazy[s]];
  .hnd.status[s;`handle`ashandle`topen`state]:(h;neg h;.sl.zp[];`open); //we don't get here if err
  .hnd.po[.hnd.p.cb s] s; // run callbacks
  :h q
  };

/F/ Opens a connection to given string, updates the handle value in the status,
/-/ and performs a query in asynhronous. This is called with the first .hnd.h call.
/-/ Note that passwords in the connection string are now hashed using xor with
/-/ mask .sl.p.m (empty when code is not compiled). For development time you
/-/ can use "0x",""sv string `byte$"haslo" to generate hashed password without
/-/ a xor mask.
/P/ s:SYMBOL - logical server name
/P/ q:STRING - query string
.hnd.p.asHopenLazy:{[s;q]
  dxcsp:{dx:{[p;m] `char$0b sv/:m<>/:0b vs/:`int$p}[;.sl.p.m];
    if[(count last c) and 5=count c:":"vs string x;
      :hsym`$":"sv(-1_c),enlist dx[value last c]];:x};
  connstr:dxcsp[.hnd.status[s;`connstr]];
  h:.pe.at[hopen;(connstr;.hnd.status[s;`timeout]);.hnd.p.errHlazy[s]];
  .hnd.status[s;`handle`ashandle`topen`state]:(h;neg h;.sl.zp[];`open); //we don't get here if err
  .hnd.po[.hnd.p.cb  s] @\: s; // run callbacks
  (neg h) q;
  };

/F/ Error handler for opening in the lazy mode.
/P/ s:SYMBOL - server name
/P/ e:SYMBOL - the error (signal)/R/ :Signal 
.hnd.p.errHlazy:{[s;e] 
  sig:"can't open connection to ",string[s],", error: ",e;
  .hnd.status[s;`state`msg]:(`failed;sig);
  .log.warn[`handle] sig;
  // start reconnection only when it is not running (user may call .hnd.h many times)
  if[not (tid:`$".hnd.rec.",.hnd.p.remdot s) in .tmr.status`funid;
    .tmr.start[tid;.hnd.timer;tid]
    ];
  '`$sig
  };

/F/ Opens connection in eager mode. If succesful  .hnd.status
/-/ Note that passwords in the connection string are now hashed using xor with
/-/ mask .sl.p.m (empty when code is not compiled). For development time you
/-/ can use "0x",""sv string `byte$"haslo" to generate hashed password without
/-/ a xor mask.
/P/ s:SYMBOL - server name
.hnd.p.hopenEager:{[s]
  dxcsp:{dx:{[p;m] `char$0b sv/:m<>/:0b vs/:`int$p}[;.sl.p.m];
    if[(count last c) and 5=count c:":"vs string x;
      :hsym`$":"sv(-1_c),enlist dx[value last c]];:x};
  connstr:dxcsp[.hnd.status[s;`connstr]];
  h:.pe.at[hopen;(connstr;.hnd.status[s;`timeout]);.hnd.p.errEager[s]];
  if[not h~0N;
    .hnd.status[s;`handle`ashandle`topen`state]:(h;neg h;.z.p;`open);
    .hnd.po[.hnd.p.cb s] s; // run callbacks
    ];
  };

/F/ Error handler for opening in the lazy mode.
/P/ s:SYMBOL - server name
/P/ e:SYMBOL - the error (signal)
.hnd.p.errEager:{[s;e]
  sig:"can't open connection to ",string[s],", error: ",e;
  .hnd.status[s;`handle`topen`state`msg]:(.hnd.p.hopenLazy[s];0Np;`failed;sig);
  .log.warn[`handle] sig;
  // turn on reconnection. 
  .tmr.start[`$".hnd.rec.",(.hnd.p.remdot s);.hnd.timer;`$".hnd.rec.",(.hnd.p.remdot s)];
  :0N
  };

/F/ Callback connected to standard .z.pc. 
/-/ Updates the status and forwards the callback to user-defined ones.
/P/ h:INT - handle
.hnd.p.pc:{[h]
  // get server name from handle.
  ser:exec server from .hnd.status where handle ~\: h;
  if[not 1~count ser;:()]; // not our handle
  .log.warn[`handle] "Server ",string[first ser], " with handle: ", string[h], " has been disconnected";
  s:first ser;
  // update status
  .hnd.status[s;`handle`ashandle`state`tlost`msg]:(.hnd.p.hopenLazy[s];.hnd.p.asHopenLazy[s];`lost;.sl.zp[];"remote server closed unexpectedly");
  // schedule reconnection timer
  .tmr.start[`$".hnd.rec.",(.hnd.p.remdot s);.hnd.timer;`$".hnd.rec.",(.hnd.p.remdot s)];
  // run user defined port close callbacks
  .hnd.pc[.hnd.p.cb s] s; 
  :()
  };

/F/ Tries to reconnect given server.
/P/ s:SYMBOL - server name
/P/ t:INT - time
.hnd.p.rec:{[s;t]
  .hnd.status[s;`reconn]+:1;
  dxcsp:{dx:{[p;m] `char$0b sv/:m<>/:0b vs/:`int$p}[;.sl.p.m];
    if[(count last c) and 5=count c:":"vs string x;
      :hsym`$":"sv(-1_c),enlist dx[value last c]];:x};
  connstr:dxcsp[.hnd.status[s;`connstr]];
  
  h:.pe.at[hopen;(connstr;.hnd.status[s;`timeout]);{:0N}];
  if[not h~0N;
    .tmr.stop[`$".hnd.rec.",(.hnd.p.remdot s)];
    .hnd.status[s;`handle`ashandle`topen`state]:(h;neg h;.sl.zp[];`open);
    .hnd.po[.hnd.p.cb s] s; // run callbacks
    ];
  };

/F/ Closes a server. Also stop all timers related to it.
/P/ s:SYMBOL - server name
.hnd.p.hclose:{[s]
  if[`open~.hnd.status[s;`state];hclose .hnd.status[s;`handle]];
  .tmr.stop[`$".hnd.rec.",(.hnd.p.remdot s)];
  };

/F/ Converts dots to underscores in a symbol. Useful in handling po and pc callbacks. Note: returns string!
/P/ s:SYMBOL - symbol to be converted
/R/ :STRING
.hnd.p.remdot:{[s]{$[x~".";"_";x]} each string s}

/F/ Sets all needed globals to empty values. Run once while loading and on reset.
.hnd.p.setGlobals:{[]
  /G/ Table with current status of all connections initiated from the process using .hnd.hopen[].
  /-/  -- server:SYMBOL        - a symbol with logical server name
  /-/  -- timeout:LONG         - connection timeout
  /-/  -- state:SYMBOL         -  one of `registered`open`closed`failed`lost
  /-/  -- connstr:SYMBOL       - a symbol with connection string
  /-/  -- handle:LONG|LAMBDA   - an int with handle, valid only if state=`open, otherwise handle column contains a projection of a function that opens connections and performs a synchronous query
  /-/  -- ashandle:LONG|LAMBDA - an int with handle, valid only if state=`open, otherwise handle column contains a projection of a function that opens connections and performs an asynchronous query
  /-/  -- topen:TIMESTAMP      - a timestamp with the last time a port open event action was run, initially null 
  /-/  -- tclose:TIMESTAMP     - a timestamp with the last time a connection was closed (hclose was run), initially null 
  /-/  -- tlost:TIMESTAMP      - a timestamp with the last time a connection was lost (.z.pc action was taken), initially null
  /-/  -- reconn:LONG          - an integer with reconnection count. Reconnection attempts are made on timer when a connection fails
  /-/  -- msg:STRING           - empty list or message thrown as signal when trying to open or close connection 
  /-/  -- remoteHnd:LONG       - an int with remote handle h".z.w"
  /E/ .hnd.status
  .hnd.status:([server:1#`]timeout:1#0N; state:1#`; connstr:1#`; handle:1#();ashandle:1#(); topen:1#0Np; tclose: 1#0Np; tlost:1#0Np; reconn:1#0N; msg:1#(); remoteHnd:1#0N);

  /G/ List of reconnection functions executed on timer.
  .hnd.timer:$["w"~first string .z.o;2000;1000]; // Windows blocks for 1s on unsuccessful connections
  /G/ Namespace for actions that need to be run on port open.
  .hnd.po:enlist[`]!enlist[::];
  /G/ Namespace for actions that need to be run on port close.
  .hnd.pc:enlist[`]!enlist[::];

  /G/ Dictionary of functions that may called on timer to reconnect to server. 
  /-/ These are copies of .hnd.p.rec with the first parameter fixed to server name
  .hnd.rec:()!(); 

  /G/ Dictionary translating server names with dots into internal names where dots are replaced by underscores.
  .hnd.p.cb:()!();
  };

/------------------------------------------------------------------------------/
/                                globals                                       /
/------------------------------------------------------------------------------/
// set up empty globals only once. This is just in case handle.q is loaded
// multiple times, which may happen if loaded with \l or .sl.relib
if[not `status in key .hnd;   .hnd.p.setGlobals[]]; 
