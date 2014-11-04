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

/S/ Connection management library:
/S/ Functionality related to initialization and maintaining connections between q processes.
/S/ The library is loaded automatically in qsl/sl.q (<sl.q>) library.

/S/ Connection state:
/S/ Connection to the client can be in one of the following states :
/S/ `registered - connection is added to status table; no attempt to connect to client was made
/S/ `open - connection to client is open and ready to use
/S/ `close - connection to client was closed by server (e.g. server disconnected)
/S/ `lost - connection to client was lost (e.g. client was terminated)
/S/ `failed - attempt to connect to client failed (e.g. client is not running)


/S/ Callbacks defined by user:
/S/ 
/S/ .hnd.poAdd[server,function] - adds a callback called when a connection to a server is open
/S/ .hnd.pcAdd[server,function] - adds a callback called when a connection to a server is closed
/S/ .hnd.poDel[server,function] - removes a callback called on port open
/S/ .hnd.pcAdd[server,function] - removes a callback called on port close
/S/ 
/S/ where :
/S/ server - a symbol with the name of a server
/S/ function - a symbol which is a name of the function to be run; the function should take one parameter that is a symbol with the server name


.sl.lib[`$"qsl/callback"];
.sl.lib[`$"qsl/timer"];


/------------------------------------------------------------------------------/
/                           interface functions                                /
/------------------------------------------------------------------------------/
/F/ setup connection details; real connection will be initialized only 
/F/ after using <.hnd.h> or <.hnd.ah>
/P/ servers:UNION[(DICTIONARY[SYMBOL;SYMBOL];LIST[SYMBOL]] - either a dictionary
/P/  mapping server names to their connection strings or a list of servers names
/P/  to be read from a etc/system.cfg file
/P/ timeout:INT - the timeout for opening a connection
/P/ flag:ENUM[`lazy`eager] - indicates if we want to immediately open 
/P/  connections or just register servers and open when <.hnd.h> is called
/E/ servers:enlist[`rdb]!enlist[`:localhost:5001]
/E/ servers:`rdb`hdb!(`:localhost:5001;`:localhost:5002)
/E/ servers:`rdb`hdb
/E/ servers:`tickRtr`tickPlus
/E/ servers:`rdb
/E/ tmout:1000i
/E/ tmout:0Ni        (results in tmout=0)
/E/ flag:`lazy
/E/ .hnd.hopen[servers;tmout;flag]
.hnd.hopen:{[servers;tmout;flag]
  .log.debug[`handle] "Initializing handle.q library";
  if[not any (99h;-11h;11h)~\:type servers; '"Parameter: servers. Expected type: dictionary (sym!sym), symbol atom  or a list of symbols"];
  if[not -7h~type tmout;tmout:`int$tmout];
  if[not -6h~type tmout; '"Parameter: tmout. Expected type: int"];
  if[null tmout; tmout: 0];
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

/F/ query server in synchronous mode; opens the connection if not open
/P/ s:SYMBOL - server name
/R/ :UNION[FUNCTION[1];INT] - either a handle or a function that opens a connection and queries the server
.hnd.h:{[s].hnd.status[s;`handle]};

/F/ query server in asynchronous mode; opens the connection if not open
/P/ s:SYMBOL - server name
/R/ :UNION[FUNCTION[1];INT] - either a handle or a function that opens a connection and queries the server
.hnd.ah:{[s].hnd.status[s;`ashandle]};


/F/ add a function called when a connection to the given server is open
/P/ server:SYMBOL - server name
/P/ function:SYMBOL - function name; the function will be called every time
/P/ when a connection is open to a server; the function is passed the server name
.hnd.poAdd:{[server;function]
  .cb.add[`$".hnd.po.",(.hnd.p.remdot server);function];
  };

/F/ add a function called when a port is closed
/P/ server:SYMBOL - server name
/P/ function:SYMBOL - function name; the function will be called every time
/P/ when a connection is open to a server; the function is passed the server name
.hnd.pcAdd:{[server;function]
  .cb.add[`$".hnd.pc.",(.hnd.p.remdot server);function];
  };

/F/ remove a function called when a port is open
/P/ server:SYMBOL - server name
/P/ function:SYMBOL - the name of the function to be removed 
.hnd.poDel:{[server;function]
  .cb.del[`$".hnd.po.",(.hnd.p.remdot server);function];
  };

/F/ remove a function called when a port is closed
/P/ server:SYMBOL - server name
/P/ function:SYMBOL - the name of the function to be removed
.hnd.pcDel:{[server;function]
  .cb.del[`$".hnd.pc.",(.hnd.p.remdot server);function];
  };

/------------------------------------------------------------------------------/
/F/ refresh connections to all servers (applies only to servers with state different than `registered)
/P/ server:LIST[SYMBOLS] - list of servers to refresh
/E/ servers:`rdb
/E/ servers:`rdb`hdb
/E/ servers:` - all servers
/E/ .hnd.refresh[servers]
.hnd.refresh:{[servers]
  if[`~servers;servers:distinct 1_exec server from .hnd.status where not state=`registered];
  .log.info[`handle] "Refreshing connections";
  .hnd.hclose[servers];
  .hnd.p.hopenEager each servers;
  .log.info[`handle] "Finished";
  };

/------------------------------------------------------------------------------/
/F/ disconnects from servers with status `open, stops reconnect timers, updates status
/P/ servers:UNION[SYMBOL;LIST[SYMBOL]] - a single server or a list of servers to be disconnected; one can pass backtick to stop all
/R/ :INT - count of servers that had been open and were closed
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

/F/ resets all data to the state (almost) the same as after loading  
// handle.q the for first time
.hnd.reset:{
  .hnd.hclose[`];
  // remove all callbacks
  .cb.reset each exec callback from .cb.status where callback like ".hnd.p[oc].*";
  .cb.reset `.z.pc;
  .hnd.p.setGlobals[];
  };

/------------------------------------------------------------------------------/
/                             private functions                                /
/------------------------------------------------------------------------------/
.hnd.p.getTechnicalUser:{[]
  proc:0!.cr.getByProc[`host`port];
  tu:select kdb_user:sectionVal, kdb_password:pass from 0!.cr.getGroupCfgPivot[`technicalUser;`pass];
  if[1<count tu;
    tu:1#tu;
    .log.warn[`handle]"Only one technical user is allowed. For internal connections user:",string[first tu`kdb_user], " will be used";
    ];
  proc cross tu
  };

/F/ opens a connection to given string, updates the handle value in the status,
/F/ and performs a query in synhronous mode. This is called with the first .hnd.h call.
/F/ Note that passwords in the connection string are now hashed using xor with
/F/ mask .sl.p.m (empty when code is not compiled). For development time you
/F/ can use "0x",""sv string `byte$"haslo" to generate hashed password without
/F/ a xor mask
/P/ s:SYMBOL - logical server name
/P/ q:STRING - query string
/R/ :Any - result of the query
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

/F/ opens a connection to given string, updates the handle value in the status,
/F/ and performs a query in asynhronous. This is called with the first .hnd.h call.
/F/ Note that passwords in the connection string are now hashed using xor with
/F/ mask .sl.p.m (empty when code is not compiled). For development time you
/F/ can use "0x",""sv string `byte$"haslo" to generate hashed password without
/F/ a xor mask
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

/F/ Error handler for opening in the lazy mode
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
/F/ Note that passwords in the connection string are now hashed using xor with
/F/ mask .sl.p.m (empty when code is not compiled). For development time you
/F/ can use "0x",""sv string `byte$"haslo" to generate hashed password without
/F/ a xor mask
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

/F/ Error handler for opening in the lazy mode
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
/F/ Updates the status and forwards the callback to user-defined ones
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

/F/ closes a server. Also stops all timers related to it.
/P/ s:SYMBOL - server name
.hnd.p.hclose:{[s]
  if[`open~.hnd.status[s;`state];hclose .hnd.status[s;`handle]];
  .tmr.stop[`$".hnd.rec.",(.hnd.p.remdot s)];
  };

/F/ converts dots to underscores in a symbol. Useful in handling po and pc callbacks. Note: returns string!
/P/ s:SYMBOL - symbol to be converted
/R/ :String
.hnd.p.remdot:{[s]{$[x~".";"_";x]} each string s}

// Sets all needed globals to empty values. Run once while loading and on reset
.hnd.p.setGlobals:{
  /G/ Connection status table
  /G/ - server - a symbol with logical server name
  /G/ - timeout - connection timeout
  /G/ - state -  one of `registered`open`close`failed`lost
  /G/ - connstr - a symbol with connection string
  /G/ - handle - an int with handle, valid only if state=`open, otherwise handle column contains a projection of a function that opens connections and performs a synchronous query
  /G/ - ashandle - an int with handle, valid only if state=`open, otherwise handle column contains a projection of a function that opens connections and performs an asynchronous query
  /G/ - topen - a timestamp with the last time a port open event action was run, initially null 
  /G/ - tclose - a timestamp with the last time a connection was closed (hclose was run), initially null 
  /G/ - tlost - a timestamp with the last time a connection was lost (.z.pc action was taken), initially null
  /G/ - reconn - an integer with reconnection count. Reconnection attempts are made on timer when a connection fails
  /G/ - msg - empty list or message thrown as signal when trying to open or close connection 
  /G/ - remoteHnd - an int with remote handle h".z.w"
  .hnd.status:([server:1#`]timeout:1#0N; state:1#`; connstr:1#`; handle:1#();ashandle:1#(); topen:1#0Np; tclose: 1#0Np; tlost:1#0Np; reconn:1#0N; msg:1#(); remoteHnd:1#0N);

  /G/ Timers
  .hnd.timer:$["w"~first string .z.o;2000;1000]; // Windows blocks for 1s on unsuccessful connections
  /G/ Namespace for actions that need to be run on port open
  .hnd.po:enlist[`]!enlist[::];
  /G/ Namespace for actions that need to be run on port close
  .hnd.pc:enlist[`]!enlist[::];

  /G/ Dictionary of functions that may called on timer to reconnect to server. 
  /G/ These are copies of .hnd.p.rec with the first parameter fixed to server name
  .hnd.rec:()!(); 

  /G/ Dictionary translating server names with dots into internal names where
  /G/ dots are replaced by underscores
  .hnd.p.cb:()!();
  };
/------------------------------------------------------------------------------/
/                                globals                                       /
/------------------------------------------------------------------------------/
// set up empty globals only once. This is just in case handle.q is loaded
// multiple times, which may happen if loaded with \l or .sl.relib
if[not `status in key .hnd;   .hnd.p.setGlobals[]]; 
