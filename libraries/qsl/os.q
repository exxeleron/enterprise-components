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

/S/ Shell commands abstraction, covers Linux and Windows

/F/ removes a directory - Linux version
/P/ dirname:STRING
.os.p.L.rmdir:{[dirname]
  dirname:.os.p.fixPath dirname;
  .os.system["rmdir"] "rm -r ",dirname;
  };


/F/ removes a directory Windows version
/P/ dirname:STRING
.os.p.W.rmdir:{[dirname]
  dirname:.os.p.fixPath dirname;
  .os.system["rmdir"] "rmdir /S /Q ",.os.p.q dirname;
  };
  
/F/ removes a file - Linux version
/P/ path:STRING - path to file
.os.p.L.rm:{[path] .os.system["rm"] "rm ",.os.p.fixPath path};

/F/ removes a file - Linux version
/P/ path:STRING - path to file
.os.p.W.rm:{[path] .os.system["rm"] "del /Q ",.os.p.fixPath path};

/F/ copies directory with contents - Linux version
/P/ dir1:STRING - source dir
/P/ dir2:STRING - target dir
.os.p.L.cpdir:{[dir1;dir2]
  dir1:.os.p.fixPath dir1;
  dir2:.os.p.fixPath dir2;
  if[11h~type key hsym `$dir2; 
    // target exists, emulate Windows behavior
    if[0~count dir1;'`$"error: source directory name is empty string or null"];
    if[not "/"~last dir1;dir1,:"/"];
    dir1,:"*"; // we dont surround with quotes as this would not expand "*" 
    .os.system["cpdir"] "cp -rf ",dir1," ",dir2;
    :(::)
    ];
  .os.system["cpdir"] "cp -rf ",(.os.p.q dir1)," ",.os.p.q dir2;
  };
  
/F/ copies directory with contents - Windows version
/P/ dir1:STRING - source dir
/P/ dir2:STRING - target dir
.os.p.W.cpdir:{[dir1;dir2]
  dir1:.os.remSlash .os.p.fixPath dir1; // xcopy does not like backslash at the path end
  dir2:.os.remSlash .os.p.fixPath dir2;
  // empty source dir, just create the target, this is what Linux does
  if[(`$()) ~ key hsym `$dir1;.os.p.W.mkdir[dir2];:(::)];
  .os.system["cpdir"] "xcopy  ",(.os.p.q dir1)," ",(.os.p.q dir2)," /i/q/k/h/o/y";
  };
  
/F/ creates a directory - Linux version
/P/ dir:STRING - name of the directory to create
.os.p.L.mkdir:{[dir]
  dir:.os.p.fixPath dir;
  .os.system["mkdir"] "mkdir -p ",.os.p.q dir;
  };
  
/F/ creates a directory - Windows version
/P/ dir:STRING - name of the directory to create
.os.p.W.mkdir:{[dir]
  dir:.os.p.fixPath dir;
  if[11h~type key hsym `$dir;:(::)]; // do nothing if directory exists
  .os.system["mkdir"] "mkdir ",.os.p.q dir;
  };
  
/F/ moves a file - Linux version
/P/ source:STRING - the source name
/P/ target:STRING - the target name
.os.p.L.move:{[source;target]
  source:.os.p.fixPath source;
  target:.os.p.fixPath target;
  .os.system["move"] "mv ",source," ",target;
  };

/F/ moves a file - Windows version
/P/ source:STRING - the source name
/P/ target:STRING - the target name
.os.p.W.move:{[source;target]
  source:.os.remSlash .os.p.fixPath source;
  target:.os.remSlash .os.p.fixPath target;
  .os.system["move"] "move /y ",source," ",target;
  };

/F/ finds old files - Linux version
/P/ dir:SYMBOL - directory to look into
/P/ age:LONG - age of the files in days
/P/ pattern:SYMBOL - pattern for the file path
/R/ :LIST[SYMBOL] - a list of file paths
.os.p.L.find:{[dir;age;pattern] 
	findCmd:"find -L ",1_(string dir)," -mtime +",(string age), " -name \"",string[pattern],"\" -prune";
	:`$.pe.at[system;findCmd;{[cmd;sig] .log.error[`os] "error while calling \"",cmd,"\". Maybe invalid arguments?"; :()}[findCmd;]]
	};

/F/ finds old files - Windows version. Note: on Windows the pattern applies to files only
/P/ dir:SYMBOL - directory to look into
/P/ age:LONG - age of the files in days
/P/ pattern:SYMBOL - pattern for the files
/R/ :LIST[SYMBOL] - a list of file paths
.os.p.W.find:{[dir;age;pattern] 
	// construct path to an error file from the log path
	errFile:$[`FILE in .log.dest;((-3)_1_string .log.p.path),"finderr";"NUL"];
	findCmd:"forfiles /m ",(string pattern)," /p ",(.os.p.W.slash 1_string dir)," /d -",(string age)," /c \"cmd /c echo @path\" 2>",errFile;
	:{x where not null x} `$.pe.at[system;findCmd;{[cmd;sig] .log.warn[`hk] "error while calling \"",cmd,"\". This may be caused by the command not finding any matching files, or invalid arguments"; :()}[findCmd;]]
	};

/F/ Compresses a file or directory - Linux (and Mac) version
/P/ path:STRING - path to the directory or file to compress
.os.p.L.compress:{[path]
	mac:"m"~first string .z.o;
	res:.os.system["compress"] "tar -czvPf ",path,".tar.gz ",path,$[mac;"";" --remove-files"];
	if[mac;$[0<type key hsym `$path;.os.p.L.rmdir path;.os.p.L.rm path]];
	:res
	};

/F/ Compresses a file or directory - Windows version
/P/ path:STRING - path to the directory or file to compress
.os.p.W.compress:{[path]
	path:.os.p.fixPath path;
	.os.system["compress"] "zip -q -r ",path,".zip ",path;
	// remove, calling the right function for a directory or file
	$[0<type key hsym `$path;.os.p.W.rmdir path;.os.p.W.rm path];
	};
  
/F/ Sleeps for given number of milliseconds. Linux version, requires Bash
/P/ ms:LONG - number of milliseconds to sleep
.os.p.L.sleep:{[ms]
  system "sleep ",(string ms%1000),"s";
  };
  
/F/ Sleeps for given number of milliseconds. Windows version. Note the resolution on Windows is 1000ms (1s), rounded UP.
/P/ ms:LONG - number of milliseconds to sleep
.os.p.W.sleep:{[ms]
  s:ceiling ms%1000;
  system "ping 127.0.0.1 -n ",(string s+1)," > null";
  };

/F/ Removes the last slash from a string - Windows version
/P/ path:STRING - directory path
/R/ :STRING - the path with slash removed if present
.os.p.L.remSlash:{[path] $["/" ~last path;(-1)_path;path]};
	
/F/ Removes the last slash from a string - Windows version
/P/ path:STRING - directory path
/R/ :STRING - the path with slash removed if present
.os.p.W.remSlash:{[path] $["\\" ~last path;(-1)_path;path]};

/F/ converts slashes to the correct ones for Linux. Makes it easier to use literal paths 
/P/ p:STRING - a path
.os.p.L.slash:{[p] ssr[p;"\\";"/"]};

/F/ converts slashes to the correct ones for Windows. Makes it easier to use literal paths 
/P/ p:STRING - a path
.os.p.W.slash:{[p] ssr[p;"/";"\\"]};

/F/ a wrapper for the system calls. The standard error is redirected to a disk file and thrown as signal.
/P/ cmd:STRING - command string
.os.system:{[origin;cmd]
	// wrap only id we have a valid log path
	if[`dest in key `.log; // we are not running standalone
        if[`FILE in .log.dest;
            errFile:.os.slash (1_string hsym .log.path),"/oserr.txt";
            @[system;cmd," 2>",errFile;{[origin;cmd;errFile;sig]'`$origin," failed with command \"",cmd,"\": ", raze read0 hsym `$errFile}[origin;cmd;errFile]];
            :(::);
            ];
        ];
     @[system;cmd;{[origin;cmd;sig]'`$origin," failed with command \"",cmd,"\""}[origin;cmd]];
	};	
	
/F/ surrounds a string with quotation marks
/P/ s:STRING
.os.p.q:{[s] "\"",s,"\""};

/F/ fixes a path - converts to string if needed and replaces slashes
/P/ path:UNION[STRING;SYMBOL] - a path in the form of string or symbol
/R/ STRING: fixed path in for of string
.os.p.fixPath:{[path] .os.slash  {$[(-11h)~type x;1_string x;x]} path};

/--- stubs for docs generation, overwritten by initialization

/F/ removes a directory 
/P/ dirname:STRING
.os.rmdir:{[dirname] };

/F/ copies directory with contents. On Linux, when dir2 points to an existing directory the 
/F/ actual command executed is cp -rf dir1/* dir2. This way both on Linux and Windows
/F/ the contents of dir1 is written to dir2 when dir2 already exists. 
/P/ dir1:STRING - source dir
/P/ dir2:STRING - target dir
.os.cpdir:{[dir1;dir2] };

/F/ creates a directory
/P/ dir:STRING - name of the directory to create
.os.mkdir:{[dir] };

/F/ moves a file
/P/ source:STRING - the source name
/P/ target:STRING - the target name
.os.move:{[source;target] };

/F/ converts slashes to the correct ones for OS. Makes it easier to use literal paths 
/P/ p:STRING - a path
/R/ :STRING - a path with all wrong slashes converted to correct ones
.os.slash:{[p] };

/F/ returns a command that can be used to find old files
/P/ dir:SYMBOL - directory to look into
/P/ age:LONG - age of the files in days
/P/ pattern:SYMBOL - pattern for the file path
.os.find:{[dir;age;pattern] };

/F/ sleeps given number of milliseconds. On Windows, the resolution is 1000ms (1s)
/P/ t:LONG - time in millisecods. On Windows, this parameter is rounded UP to the nearest multiple of 1000.
.os.sleep:{[t] };

/--- initialization
$["w"~first string .z.o;.os,:.os.p.W;.os,:.os.p.L];
