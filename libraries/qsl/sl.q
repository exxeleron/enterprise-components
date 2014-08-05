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

/S/ Standard Library:
/S/ Covers loading configurations and libraries, logging and protected evaluation

/T/ \l qsl/lib/sl.q
/T/ .sl.init[`appname]

/G/ Generate xor mask for password hashing. Constant value is used here.
.sl.p.m:32#10011b;
/------------------ Interface -------------------------------------------------/
/F/ Initializes the Standard Library
/P/ appname:SYMBOL - name of the application
.sl.init: {[appname]

  //init sl
  if[.sl.p.defined[`.sl.p.firstRun];:()];
  // .sl.init runs first time, load the configuration for sl
  .sl.appname:appname;
  .sl.p.firstRun:0b;
  .sl.p.libs:`$();

  .sl.p.bootstrapLog[];
  .sl.p.initLibPath[];
  .sl.p.initDllPath[];
  .sl.p.initEtc[];
  .sl.p.initPe[];

  .sl.setConfVar[`.sl.componentId;`EC_COMPONENT_ID;.z.f;{`$x}];

  .sl.p.initLog[];

  // log completely initialized, print banner
  .log.info[`sl] each .sl.p.banner[]; 
  // set remaining sl configuration variables
  .sl.p.initMisc[];
  // we always load some standard libraries
  .sl.lib["qsl/event.q"];
  .sl.lib["qsl/handle.q"];
  .sl.lib["qsl/authorization.q"];
  .sl.lib["qsl/sub.q"];
  };

/F/ Runs initialization code of a component.
/F/  Executes initFunction (with argument arg) as event. Calls log summary afterwards.
/F/  No action performed in case of noinit switch defined by one of:
/F/    -- -noinit - command line option 
/F/    -- .sl.noinit - variable set to 1b
/P/ module:SYMBOL   - module name used for logging
/P/ initFunc:SYMBOL - init function. Function should take zero or one argument.
/P/ arg             - argument for initFunc
.sl.run:{[module;initFunc;arg]
  if[(`noinit in key .Q.opt[.z.x]) or (1b ~ .sl[`noinit]);
    .log.info[`sl] " -noinit option: skipping initialization call:", string[initFunc];
    :();
    ];
  .cr.loadCfg[`THIS];
  .event.at[module;initFunc;arg;`;`info`info`fatal;"initializing ",string[module]," component"];
  .auth.init[];

  .event.at[`sub;`.sub.readCfg;();();`debug`info`error;"Reading subscription configuration for dist server"];
  if[.sub.cfg.autoSubscribe;
    .event.at[`sub;`.sub.init;.sub.cfg.subCfg;();`debug`info`error;"Auto initialization of subscription basing on dataflow configuration"];
    .event.at[`sub;`.sub.hopenSrc;`;();`debug`info`error;"Auto initialization of connection to subscription sources basing on dataflow configuration"];
    ];

  .log.summary[module;"component ",string[module]," initialized with "];
  };

/F/ Load q modules requested from command line
.sl.libCmd:{[]
  if[`commonLibs in key p:.Q.opt[.z.x];.sl.lib each `$p[`commonLibs]];
  if[`libs in key p:.Q.opt[.z.x];.sl.lib each `$p[`libs]];
  if[`lib in key .Q.opt[.z.x];.log.warn[`sl] "obsoleted parameter -lib will be ignored, use -libs instead"];
  };

/F/ Sets log level in run-time
/P/ level:ENUM[`INFO`DEBUG`WARN`ERROR`FATAL] - minimal logging level
/R/ :Enum[`INFO`DEBUG`WARN`ERROR`FATAL] - the previous logging level 
.sl.setLogLevel:{[level]
  p:.log.level;
  .log.level:level;
  .log.p.init[level;.log.dest;.sl.componentId];
  :p;
  };

/F/ Sets a configuration variable. This does not have to be called
/F/ for all configuration variables, just for those for which
/F/ we may have corresponding environment variable and default value.
/F/ The algorithm works as follows:
/F/ - if the variable is already defined, do nothing, it must have been set by <.sl.load[`ETC]>
/F/ - if not, check for the environment variable and set to its parsed (by the provided parser) value
/F/ - if the variable does not exist, use the default
/P/ vn:SYMBOL - the q configuration variable name
/P/ envn:SYMBOL - corresponding environment variable name
/P/ default:ANY - the default value to be used
/P/ conv:FUNTION - a function that converts the string from environment
/P/ variable to the value of configuration variable. 
/R/ :ANY - actually assigned configuration variables
.sl.setConfVar:{[vn;envn;default;conv]
  if[.sl.p.defined[vn];
    `.sl.confStatus insert (vn;val:value vn;`qvariable);
    .log.debug[`sl] "attempt to set variable ",(string vn)," that already exists, ignored", .Q.s1 val;
    :val];
  if[0<count s:getenv envn;
    val: conv s;
    .log.debug[`sl] "variable ",(string vn)," set from environment to",.Q.s1 val; 
    `.sl.confStatus insert (vn;val;`environmment);
    :value vn set val;
    ];
  `.sl.confStatus insert (vn;default;`default);
  .log.debug[`sl] "variable ",(string vn)," set to default ", .Q.s1 default;
  :value vn set default
  };

/F/ Runs <.sl.init> as if it was the first time. This is useful for changing 
/F/ the sl configuration parameters at runtime
.sl.reinit:{[appname] delete firstRun from `.sl.p;.sl.init[appname]};

/F/ Loads configuration file, assumes <.sl.etcpath> is set.
/P/ name:SYMBOL - the name of the configuration file, without the extension.
.sl.etc:{[name]
  name:.sl.p.chopOff[name;".q"]; // removes trailing extension if given
  .log.info[`sl] "Loading ",(string name),".q configuration file...";
  .sl.p.etc[.sl.p.appendName[name;".q"] each .sl.p.slash .sl.etcpath;(string name),".q";.log.warn[`sl]];
  };

/F/ Optionally loads a configuration file. This is the same as <.sl.etc> except
/F/ the in case the file is not found the log is written on the DEBUG level; assumes <.sl.etcpath> is set
/P/ name:SYMBOL - the name of the configuration file, without the extension.
.sl.etcOption:{[name]
  name:.sl.p.chopOff[name;".q"]; // removes trailing extension if given
  .log.info[`sl] "Loading ",(string name),".q configuration file...";
  .sl.p.etc[.sl.p.appendName[name;".q"] each .sl.p.slash .sl.etcpath;(string name),".q";.log.debug[`sl]];
  };

/F/ Loads a q module, assumes .sl.libpath is set.
/P/ name:SYMBOL - the name of the q module file, with or without the extension.
.sl.lib:{[name]
  if[10h=type name; name:`$name];
  name:.sl.p.chopOff[name;".q"];
  if[name in .sl.p.libs;.log.info[`sl] (string name),".q library already loaded";:()];
  .log.info[`sl] "Loading ",(string name),".q library...";
  .log.p.offset+:2;
  if[0<count p:.sl.p.lib[.sl.p.appendName[name;".q"] each .sl.p.slash .sl.libpath;(string name),".q";.log.error[`sl]];
    // succesful load
    .sl.p.libs,:name;
    .log.p.offset-:2;
    .log.info[`sl] p," loaded";
    :();
    ];
  .log.p.offset-:2;
  :();
  };

/F/ Optionally loads a q module, assumes .sl.libpath is set.
/P/ name:SYMBOL - the name of the q module file, with or without the extension.
.sl.libOption:{[name]
  name:.sl.p.chopOff[name;".q"];
  if[name in .sl.p.libs;.log.info[`sl] (string name),".q library already loaded";:()];
  .log.info[`sl] "Loading ",(string name),".q library...";
  .log.p.offset+:2;
  if[0<count p:.sl.p.lib[.sl.p.appendName[name;".q"] each .sl.p.slash .sl.libpath;(string name),".q";.log.debug[`sl]];
    // succesful load
    .sl.p.libs,:name;
    .log.p.offset-:2;
    .log.info[`sl] p," loaded";
    :();
    ];
    .log.p.offset-:2;
    :();
  };

/F/ Forces loading of a q module, even if it has been loaded already
/P/ name:SYMBOL - name of the application
.sl.relib:{[name]
  name:.sl.p.chopOff[name;".q"];
  .sl.p.libs: .sl.p.libs except name;
  :.sl.lib[name];
  };

/F/ Loads a function from a shared object (dll or so depending on OS).
/F/ The shared object is searched for on paths given by <.sl.dllpath>
/P/ fn:SYMBOL - function name
/P/ son:SYMBOL - shared object
/P/ ar:INT - number of parameters the function takes (at least 1)
/R/ :UNION[CODE;FUNCTION] - function code (dynamic dll or a function)
.sl.dll:{[fn;son;ar]
  son:.sl.p.chopOff[son;ext:.sl.p.dllExt[first string .z.o]];
  .log.info[`sl] "Loading ",(string fn)," from ",(string son),ext;
  :.sl.p.dll[.sl.p.slash .sl.dllpath;fn;ar;son]
  };
/F/ Function that shows the values of environment configuration variables. The 
/F/ `name column shows the name of the (shell) configuration variable and `source
/F/ shows if the value was taken from a q variable (usually set in a configuration 
/F/ file), environment or was taken as default in the absence of both.
/R/ :TABLE[name(SYMBOL),val(SYMBOL),source(SYMBOL)]
.sl.getConfStatus:{[]
  .sl.confStatus
  };
/----------------  sl init stages---------        ------------------------------------/

/F/ sets temporary variables mostly for logging until the actual ones can be used
.sl.p.bootstrapLog:{
  .log.p.offset:0;
  .log.p.time:`.z.z;
  .sl.zd:{.z.d};
  .sl.zt:{.z.t};
  .sl.zz:{.z.z};
  .sl.zp:{.z.p};
  .sl.zn:{.z.n};
  .log.p.init[`WARN;`CONSOLE;.z.f]; // temporarily set log to default values
  .log.status:(`FATAL`ERROR`WARN`INFO`DEBUG)!5#0; // message counters for log levels
  };

/F/ initializes the paths from which q libraries are loaded
.sl.p.initLibPath:{
  libdflt:$[0=count syspath:getenv[`EC_SYS_PATH];enlist `:./lib/;(`:./lib/;`$":",syspath,"/bin/ec/libraries/")];
  .sl.setConfVar[`.sl.libpath;`EC_LIB_PATH;libdflt;.sl.p.pathParse];
  };

/F/ initializes the paths from which shared object libraries (dll's) are loaded
.sl.p.initDllPath:{
  dlldflt:$[0=count syspath:getenv[`EC_SYS_PATH];enlist `:./dll/;(`:./dll/;`$":",syspath,"/bin/ec/libraries/")];
  .sl.setConfVar[`.sl.dllpath;`EC_DLL_PATH;dlldflt;.sl.p.pathParse];
  };

/F/ initializes paths where the configuration is searched for
.sl.p.initEtc:{
  etcdflt:$[0=count syspath:getenv[`EC_SYS_PATH];enlist `:./etc/;(`:./etc/;`$":",syspath,"/etc/")];
  .sl.setConfVar[`.sl.etcpath;`EC_ETC_PATH;etcdflt;.sl.p.pathParse];
  };

/F/ initializes protected execution wrappers
.sl.p.initPe:{
  .pe.at:@[;;];
  .sl.lib["qsl/pe.q"];
  .sl.setConfVar[`.pe.enabled;`EC_SL_PE;1b;{$[x~"ENABLED";1b;0b]}];
  .pe.init[.pe.enabled];
  };

/F/ Initializes the log functionality. This overrides the values used for bootstrapping
.sl.p.initLog:{
  .sl.setConfVar[`.log.maxHistSize;`EC_LOG_MAXHIST;10000;{`long$parse x}];
  .sl.setConfVar[`.log.path;`EC_LOG_PATH;`:./log;{x[where x="\\"]:"/";`$x}]; // replace \ by / because Windows
  .sl.setConfVar[`.log.dest;`EC_LOG_DEST;enlist `CONSOLE;{`$"," vs x}];
  .sl.setConfVar[`.log.level;`EC_LOG_LEVEL;`INFO;{`$x}];
  .sl.setConfVar[`.log.time;`EC_TIMESTAMP_MODE;`.z.z;{$[x~"LOCAL";`.z.Z;`.z.z]}];
  .sl.setConfVar[`.log.rotate;`EC_LOG_ROTATE;0Nt;{"T"$x}];
  .log.p.time:.log.time;
  // reinit log to actual parameters
  .log.p.init[.log.level;.log.dest;.sl.componentId];
  if[(.sl.p.defined `.log.dest) and .sl.p.defined `.log.p.path;
    -1 "Logging to file: ", 1_string  .log.p.path];
  };

/F/ Sets some miscalenous sl configuration variables
.sl.p.initMisc:{
  .sl.setConfVar[`.sl.eodDelay;`EC_EOD_DELAY;00:00:00.000;{"T"$x}];
  .sl.eodDelay:00:00:00.000+.sl.eodDelay;
  .sl.setConfVar[`.sl.timestampMode;`EC_TIMESTAMP_MODE;`UTC;{`$x}];
  // Current day according to EC_TIMESTAMP_MODE(LOCAL or UTC) and EC_EOD_DELAY
  .sl.eodSyncedDate:$[`UTC~.sl.timestampMode;{$[.z.t<.sl.eodDelay;.z.d-1;.z.d]};{$[.z.T<.sl.eodDelay;.z.D-1;.z.D]}];
  // Current day according to EC_TIMESTAMP_MODE(LOCAL or UTC) 
  .sl.zd:$[`UTC~.sl.timestampMode;{.z.d};{.z.D}];
  // Current time according to EC_TIMESTAMP_MODE(LOCAL or UTC)
  .sl.zt:$[`UTC~.sl.timestampMode;{.z.t};{.z.T}];
  // Current datetime according to EC_TIMESTAMP_MODE(LOCAL or UTC)
  .sl.zz:$[`UTC~.sl.timestampMode;{.z.z};{.z.Z}];
  // Current timestamp according to EC_TIMESTAMP_MODE(LOCAL or UTC)
  .sl.zp:$[`UTC~.sl.timestampMode;{.z.p};{.z.P}];
  // Current timespan according to EC_TIMESTAMP_MODE(LOCAL or UTC)
  .sl.zn:$[`UTC~.sl.timestampMode;{.z.n};{.z.N}];
  };


/---               Logging                 ------------------------------------/

/F/ Initializes the logger
/P/ level:ENUM[`INFO`DEBUG`WARN`ERROR`FATAL] - minimal logging level. Logging
/P/ levels are (in the order from low to high): DEBUG,INFO,WARN,ERROR,FATAL.
/P/ out:UNION[Enum[`FILE`CONSOLE`STDERR];List[Enum[`FILE`CONSOLE`STDERR]]] - 
/P/ the destination (or a list of destinations where the log is to be written). 
/P/ cid:SYMBOL - component id
.log.p.init:{ [level;out;cid]
  if[`FILE in out;
    .log.p.h:hopen .log.p.path:.log.p.insertTs[.log.path;cid];
    if[(string .z.o) like "l*";
      system "ln -f -s ",((1+count string hsym .log.path)_string .log.p.path)," ",1_(string hsym .log.path),"/init.log";
      system "ln -f -s ",((1+count string hsym .log.path)_string .log.p.path)," ",1_(string hsym .log.path),"/current.log"
    ];
    if[not .log.rotate~0Nt;
      .sl.lib["qsl/timer"];
      .tmr.runAt[.log.rotate;`.log.p.rotate;`.log.p.rotate]
      ];
    ];
  .log.error:.log.debug:.log.warn:.log.info:{};
  .log.fatal: .log.p.out[out;`FATAL;"FATAL ";];
  if[level~`FATAL;:()];
  .log.error: .log.p.out[out;`ERROR;"ERROR ";];
  if[level~`ERROR;:()];
  .log.warn: .log.p.out[out;`WARN;"WARN  ";];
  if[level~`WARN;:()];
  .log.info: .log.p.out[out;`INFO;"INFO  ";];
  if[level~`INFO;:()];
  .log.debug: .log.p.out[out;`DEBUG;"DEBUG ";];
  };
  
/F/ a helper function replacing forward slashes to backslashes for use on Windows
/P/ s:STRING - string to be converted
/R/ :STRING - s with / replaced with \
.sl.p.winsl:{[s] s[where s="/"]:"\\";:s};

/F/ Rotates logs
.log.p.rotate:{
  nextpath: .log.p.insertTs[.log.path;.sl.componentId];
  //(neg .log.p.h) (string value .log.p.time)[.log.p.pattern], " log continues in ", 1_string nextpath;
  .log.info[`sl] " log continues in ", 1_string nextpath;
  hclose .log.p.h;
  prevpath:.log.p.path;
  .log.p.h:hopen .log.p.path:nextpath;
  //(neg .log.p.h) (string value .log.p.time)[.log.p.pattern], " log continued from ", 1_string prevpath;
  .log.info[`sl] " log continued from ", 1_string prevpath;
  if[(string .z.o) like "l*";
    system "ln -f -s ",((1+count string hsym .log.path)_string .log.p.path)," ",1_(string hsym .log.path),"/current.log"
    ];
  };

/F/ Trims the .log.hist buffer, removing a given part of it, starting 
/F/ from low priority levels. 
/P/ part:FLOAT - the part that needs to be removed
.log.p.trim:{[part]
  levs:`FATAL`ERROR`WARN`INFO`DEBUG;
  levc:0!update s:sums[c] from `level xdesc select c:count i by levs?level from .log.hist;
  toleave: (levc`level) toleaveidx:((levc`s)>part*.log.maxHistSize)?1b; // the greates level to be at least partially left
  delete from `.log.hist where level in (toleave+1) _ levs; // delete those that need to be completely deleted
  // one level needs to be partially removed, how many to remove from it?
  delpart:levc[toleaveidx;`s]-`int$part*.log.maxHistSize;
  // level name that needs to be partially removed
  partlev:levs levc[toleaveidx;`level];
  // remove some entries fro the level that needs to be partially removed
  delete from `.log.hist  where (delpart>sums level=partlev) and level=partlev;
  };

/G/ pattern mask to "filter" time string
.log.p.pattern:0 1 2 3 4 5 6 7 8 9 23 11 12 13 14 15 16 17 18 19 20 21 22;

//------------------- Appenders ------------------------------------------------
/G/ Field separator characters. Characters used to separate key=value pairs when
/G/ dictionary is used as argument to logger functions.
.log.fieldSeparator:"| ";
.log.p.dictToStr:{.log.fieldSeparator,.log.fieldSeparator sv string[key x],'"=",'.Q.s1 each value x};

/F/ Function used to print to console
.log.p.consoleAppender:{[level;levelStr;src;message] 
  -1 levelStr, (string value .log.p.time)[.log.p.pattern],(.log.p.srcStr src),(.log.p.offset#" "),$[10=type message;message;99=type message;.log.p.dictToStr message;.Q.s1 message];
  };

.log.p.fileAppender:{[level;levelStr;src;message]
  (neg .log.p.h) levelStr, (string value .log.p.time)[.log.p.pattern],(.log.p.srcStr src),(.log.p.offset#" "),$[10=type message;message;99=type message;.log.p.dictToStr message;.Q.s1 message];
  };

/G/ stderrAppender logs ERROR and FATAL messages to stderr, ignores others
.log.p.stderrAppender:()!();
.log.p.stderrAppender[`ERROR`FATAL]:{[levelStr;src;message]
  -2 levelStr, (string value .log.p.time)[.log.p.pattern],(.log.p.srcStr src),$[10=type message;message;99=type message;.log.p.dictToStr message;.Q.s1 message];
  };

//------------------- table appender
.log.p.tableAppender:{[level;levelStr;src;message]
  if[.log.maxHistSize<s:count .log.hist;
    .log.p.trim 0.3; // remove 1/3 of the entries starting from low priority levels
    .log.warn[`log] ".log.hist table too large[",(string s),"], dropping [",string[`int$0.3*s],"] messages from .log.hist";
    ];
  `.log.hist insert (.z.t;level;src;$[10=type message;message;99=type message;.log.p.dictToStr message;.Q.s1 message]);
  };

//logging appender `table without specific modules (`event`audit)
.log.hist:([]time:`time$(); level:`symbol$(); module:`symbol$(); msg:());

/F/ Removes all entries from the in-memory log table (.log.hist)
/R/ the state of in-memory log table before to was cleaned
.log.flushLogHist:{[]
  tmp:.log.hist; 
  delete from `.log.hist; 
  tmp
  };

//------------------ stderr appender //

.log.p.stderrAppender[`DEBUG`INFO`WARN]:{[levelStr;src;message] };


/F/ a dictionary of functions used for printing to different destinations
.log.p.allAppenders: `CONSOLE`FILE`STDERR`TABLE!(.log.p.consoleAppender;.log.p.fileAppender;.log.p.stderrAppender;.log.p.tableAppender);

//------------------------End Appenders ----------------------------------------

/F/ prints to all destinations specified in the first parameter
.log.p.out:{[output;level;levelStr;src;message]
  .log.status[level]+:1;
  .log.p.allAppenders[output] .\:(level;levelStr;src;message);
  };

/F/ Creates a path to file from the directory path, component ID and timestamp. 
/F/ The file name is created as <path>/<componentId>.timestamp.log
/P/ p:SYMBOL - directory path, may or may not have the last /
/P/ cid:SYMBOL - component ID
/R/ :HANDLE - a symbol with the file path
.log.p.insertTs:{[p;cid]
  if[not ps[last ps:string p]~"/";p:`$ps,"/"];
  d:(-4)_string value .log.time;
  d[where d=":"]:".";
  hsym`$(string p),(string cid),".",d,".log"
  };

/F/ formats the log source: cuts/pads to exactly 6 chars, adds a dash etc.
/P/ src:SYMBOL - the log source ( the file from which the log comes
/R/ :STRING - the string to be inserted before the pad.
/E/ (.log.p.srcStr `sl) ~ " sl    - "
.log.p.srcStr:{[src] :" ",$[5>=cs:count s:string src;s,(cs-6)#" ";(6-cs)_s],"- "};

/F/ Log summary with number of `fatal`error`warn messages
.log.summary:{[src;message]
  .log[lower first where[0<>-2_.log.status],`INFO][src]
      message
      ,.Q.s1[.log.status`FATAL], " fatals, "
      ,.Q.s1[.log.status`ERROR], " errors, "
      ,.Q.s1[.log.status`WARN], " warnings";
  };

/----------- miscellaneous helper functions --------------------------/

/F/ checks if a variable exists in a given namespace
/P/ v:SYMBOL - fully qualified variable name (for example .log.p.somevar)
/P/ will check if somevar is present in namespace .log.p
/P/ warning: the namespace has to exist already
.sl.p.defined:{[v] :(last p) in key value ` sv (-1)_p:` vs v};

/-------------------------  private functions ---------------------------------/
/------------------------------------------------------------------------------/

/---------------- loading configuration files, libraries and  shared objects ---------------/

/G/ :Dictionary[Char;String] - a dictionary of extensions of shared objects for given OS 
/G/ (first character of return from .z.o)
.sl.p.dllExt:("w";"l")!(".dll";".so");

/F/ Interprets string with a list of paths as a list of symbols with Q paths, 
/P/ s:STRING -  string listing paths as obtained from environment variable
.sl.p.pathParse:{[s] s[where s="\\"]:"/";:hsym each `$"," vs s}; // replace \ by / in case we are on Windows


/F/ Recursively checks if file in the parameter exists and attempts to load it
/P/ fs:LIST[HandleSymbol] - a list of paths for files to check 
/P/ name:STRING - name of the configuration file, used in error messages.
/P/ logf:FUNCTION[1] - the log function used to signal errors
.sl.p.etc:{[fs;name;logf]
  if[0~count fs;logf "Could not find ",name;:0b];
  if[()~key fs[0];:.sl.p.etc[1_fs;name;logf]];
  if[101h~type .pe.at[system;"l ",1_string fs[0];.sl.p.loadError[1_string fs[0]]];
    .log.info[`sl] (1_string fs[0])," loaded";
    :1b];
  :0b;
  };

/F/ Recursively checks if file in the parameter exists and attempts to load it
/P/ fs:LIST[HandleSymbol] - a list of paths for files to check 
/P/ name:STRING - name of the script file, used in error messages.
/P/ logf:FUNCTION[1] - the log function used to signal errors
/R/ :String path of the file loaded, empty if not found 
.sl.p.lib:{[fs;name;logf]
  if[0~count fs;logf "Could not find ",name;:""];
  if[()~key fs[0];:.sl.p.lib[1_fs;name;logf]];
  if[101h~type .pe.at[system;"l ",p:1_string fs[0];.sl.p.loadError[1_string fs[0]]];
    :p];

  :"";
  };

/F/ Recursively attempts to load a function from a given file at different paths
/P/ ps:LIST[Path] - a list of paths to search for shared object file. Paths must end with "/".
/P/ fn:SYMBOL - the name of function
/P/ ar:INT - number of parameters for the function
/P/ name:SYMBOL - name of the shared object file
/R/ :CODE - a code of function - either the one loaded or one that throws a signal with error message
.sl.p.dll:{[ps;fn;ar;name]
  if[0~count ps;
    .log.error[`sl] err:"Could not find ",(string name),.sl.p.dllExt[first string .z.o]," to load ",(string fn);
    :.sl.p.genErr[ar;err]
    ];
  if[()~key file:.sl.p.appendName[name;.sl.p.dllExt[first string .z.o];ps[0]]; // no file on path
    :.sl.p.dll[1_ps;fn;ar;name]
    ];
  // there is a file, attempt to load the function
  curdir:system "cd";
  // get path in name (pin)
  pin:(neg (reverse string name)?"/")_string name;
  system "cd ",1_(string ps[0]),pin;
  res:.pe.dot[2:;(`$(count pin)_string name;(fn;ar));.sl.p.dllLoadErr[file;fn]];
  system "cd ",curdir;
  if[112h~type res;.log.info[`sl] (string fn)," loaded from ",string file;:res];
  :.sl.p.genErr[ar;"function ",(string fn), " was not found in ",string file];
  };

/F/ Generates a function of given arity that does nothing but throws a signal
/P/ ar:INT - arity, should be less than 8
/P/ err:STRING - the error text
.sl.p.genErr:{[ar;err] 
  :value "{[",(";" sv "x",/:string til ar),"] '`$\"",err,"\"}"
  };

/F/ Function that logs a load error - to be used as parameter to .pe.at
/P/ name:PATH - name of the file to be loaded
/P/ err:STRING - the string passed by .pe.at
/R/ :BOOL - always 0b
.sl.p.loadError:{[name;err]
  .log.error[`sl] "signal \"",err,"\" while loading ",name;
  :0b;
  };

/F/ Function that logs an error  while loading a function from dll
/P/ name:STRING - name of the shared object file
/P/ fn:SYMBOL - name of the function
/P/ err:STRING - error string
/R/ :BOOL - always 0b
.sl.p.dllLoadErr:{[name;fn;err]
  .log.error[`sl] "signal \"",err,"\" while loading ",(string fn)," from ",string name;
  :0b;
  };

/F/ appends a file name with q extension to path
/P/ name:SYMBOL - file name
/P/ ext:STRING - extension
/P/ path:SYMBOL - a symbol with path
/R/ :SYMBOL - a symbol with file name appended
/F/ It is assumed that path ends with a "/"
/E/ .sl.p.appendName[`conf;".q";`:./] ~ `:./conf.q
/E/ .sl.p.appendName[`conf;".q",`:./lib] ~ `:./lib/conf.q
.sl.p.appendName:{[name;ext;path] `$(string path),(string name),ext};

/F/ removes trailing extension. Allows to provide the name with extension, 
/F/ a common mistake
/P/ name:SYMBOL - the name
/P/ ext:STRING - the extension to be detected and removed
/R/ :SYMBOL - the name with the extension removed
.sl.p.chopOff:{[name;ext]
  if[(count ext)>count ns:string name;:name];
  if[ext~((count ns)-2)_ns;:`$(neg count ext)_ns];
  :name;
  };

/F/ adds a missing "/" to path names
/P/ paths:LIST[Symbol] - a list of paths that may or may not end with "/"
/R/ :List[Symbol] - a list of paths with "/" added when needed
.sl.p.slash:{[ps] {$["/"~last string x;x;`$(string x),"/"]} each ps};

/F/ returns basic starting info as a list of strings
.sl.p.banner:{
    s1:"KDB+ ver: ",(string .z.K)," rel: ",(string .z.k)," OS: ",(string .z.o), " PID: ",(string .z.i);
    s2:$[()~.z.l;"no license found";"KDB+ license: ",.Q.s1 .z.l];
    s3:"user: ",(string .z.u)," host: ",(string .z.h)," port: ",(string system"p");
    s4:"dir: ",(system "cd" ),$[`~.z.f;"";" file: ",(string .z.f)];
    s5:$[()~.z.x;"no command line parameters";"args: ", (" " sv .z.x)]; 
    s6:"GMT: ",(string .z.z)," loc. time: ",(string .z.Z);
    s7:$[""~getenv `QHOME;"QHOME not defined";"QHOME: ", getenv`QHOME];
    licTerms:@[value;`.sl.p.terms;()];
    if[count licTerms;
        helper:string `date$"I"$.sl.p.terms;
        lic:"EC license start date: ", helper[`StartDate];
        lic,:" expiry date: ", helper[`ExpiryDate];
        lic,:" terminal date: ", helper[`TerminalDate];
        lic,:" customer: ", .sl.p.terms[`CustomerId];
        :(s1;s2;lic;s3;s4;s5;s6;s7)
        ];
    :(s1;s2;s3;s4;s5;s6;s7)
    };

/F/ Information about subscription protocols supported by the component (if the are any).
/F/ This function should be overwritten by the component code in order to return proper values.
/F/ This function is used by qsl/sub library to choose proper subscription protocol.
/R/ SYMBOL: returns list of protocol names that are supported by the server:
/R/  - `PROTOCOL_TICKHF - see tickHF, stream and monitor components
/R/  - `PROTOCOL_TICKLF - see tickLF component
/R/  - `PROTOCOL_DIST   - see dist component
/R/  - or other custom protocol
/R/ SYMBOL: returns `symbol$() if it is not possible to subscribe to the server.
.sl.getSubProtocols:{[] `symbol$()};

if[not `confStatus in key .sl;
  .sl.confStatus:([] name:enlist  `;val:enlist ();source:enlist `);
  ];

/ 
/code below does not execute. used only for documentation generation
// below is the API documentation of basic sl funtions
/F/ Current day according to EC_TIMESTAMP_MODE and EC_EOD_DELAY values (configured in system.cfg/<system.qsd>) 
/R/ :DATE
.sl.eodSyncedDate:{.z.d};
/F/ Current day according to EC_TIMESTAMP_MODE and EC_EOD_DELAY values (configured in system.cfg/<system.qsd>) 
/R/ :DATE
.sl.zd:{.z.d};
/F/ Current time according to EC_TIMESTAMP_MODE and EC_EOD_DELAY values (configured in system.cfg/<system.qsd>) 
/R/ :TIME
.sl.zt:{.z.t};
/F/ Current datetime according to EC_TIMESTAMP_MODE and EC_EOD_DELAY values (configured in system.cfg/<system.qsd>) 
/R/ :DATETIME
.sl.zz:{.z.z};
/F/ Current timestamp according to EC_TIMESTAMP_MODE and EC_EOD_DELAY values (configured in system.cfg/<system.qsd>) 
/R/ :TIMESTAMP
.sl.zp:{.z.p};
/F/ Current timespan according to EC_TIMESTAMP_MODE and EC_EOD_DELAY values (configured in system.cfg/<system.qsd>) 
/R/ :TIMESPAN
.sl.zn:{.z.n};

// below is the API documentation of basic log funtions

/F/ Logs a message at the FATAL level
/P/ origin:SYMBOL - the source of the message. This is typically some name that allows to identify the module where the message is generated. Truncated to 6 characters.
/P/ message:STRING - the log message.
/E/ .log.fatal[`tmr] "spacetime warp detected, exiting";
.log.fatal:{[origin;message] };

/F/ Logs a message at the ERROR level
/P/ origin:SYMBOL - the source of the message. This is typically some name that allows to identify the module where the message is generated. Truncated to 6 characters.
/P/ message:STRING - the log message.
/E/ .log.error[`tmr] "miscalculated 2+2, please check";
.log.error:{[origin;message] };

/F/ Logs a message at the WARN level
/P/ origin:SYMBOL - the source of the message. This is typically some name that allows to identify the module where the message is generated. Truncated to 6 characters.
/P/ message:STRING - the log message.
/E/ .log.warn[`tmr] "configuration file not found, defaults have been assumed";
.log.warn:{[origin;message] };

/F/ Logs a message at the INFO level
/P/ origin:SYMBOL - the source of the message. This is typically some name that allows to identify the module where the message is generated. Truncated to 6 characters.
/P/ message:STRING - the log message.
/E/ .log.info[`tmr] "configuration file loaded succesfully";
.log.info:{[origin;message] };

/F/ Logs a message at the DEBUG level
/P/ origin:SYMBOL - the source of the message. This is typically some name that allows to identify the module where the message is generated. Truncated to 6 characters.
/P/ message:STRING - the log message.
/E/ .log.debug[`tmr] "q parameter: ", .Q.s1 q;
.log.debug:{[origin;message] };
