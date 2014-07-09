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
  dirname:.os.slash dirname;
  system "rm -r ",dirname;
  };


/F/ removes a directory Windows version
/P/ dirname:STRING
.os.p.W.rmdir:{[dirname]
  dirname:.os.slash dirname;
  system "rmdir /S /Q ",.os.p.q dirname;
  };
  
/F/ removes a file - Linux version
/P/ path:STRING - path to file
.os.p.L.rm:{[path] system "rm ",path};

/F/ removes a file - Linux version
/P/ path:STRING - path to file
.os.p.W.rm:{[path] system "del /Q ",path};

/F/ copies directory with contents - Linux version
/P/ dir1:STRING - source dir
/P/ dir2:STRING - target dir
.os.p.L.cpdir:{[dir1;dir2]
  dir1:.os.slash dir1;
  dir2:.os.slash dir2;
  system "cp -rf ",(.os.p.q dir1)," ",.os.p.q dir2;
  };
  
/F/ copies directory with contents - Windows version
/P/ dir1:STRING - source dir
/P/ dir2:STRING - target dir
.os.p.W.cpdir:{[dir1;dir2]
  dir1:.os.slash dir1;
  dir2:.os.slash dir2;
  system "xcopy  ",(.os.p.q dir1)," ",(.os.p.q dir2)," /i/q/k/h/o/y";
  };
  
/F/ creates a directory - Linux version
/P/ dir:STRING - name of the directory to create
.os.p.L.mkdir:{[dir]
  dir:.os.slash dir;
  system "mkdir -p ",.os.p.q dir; 
  };
  
/F/ creates a directory - Windows version
/P/ dir:STRING - name of the directory to create
.os.p.W.mkdir:{[dir]
  dir:.os.slash dir;
  system "mkdir ",.os.p.q dir;
  };
  
/F/ moves a file - Linux version
/P/ source:STRING - the source name
/P/ target:STRING - the target name
.os.p.L.move:{[source;target]
  source:.os.slash source;
  target:.os.slash target;
  system "mv ",source," ",target;
  };
  
  
/F/ moves a file - Windows version
/P/ source:STRING - the source name
/P/ target:STRING - the target name
.os.p.W.move:{[source;target]
  source:.os.slash source;
  target:.os.slash target;
  system "move /y ",source," ",target;
  };

/F/ converts slashes to the correct ones for Linux. Makes it easier to use literal paths 
/P/ p:STRING - a path
.os.p.L.slash:{[p] p[where p="\\"]:"/";:p};

/F/ converts slashes to the correct ones for Linux. Makes it easier to use literal paths 
/P/ p:STRING - a path
.os.p.W.slash:{[p] p[where p="/"]:"\\";:p};

/F/ finds old files - Linux version
/P/ dir:SYMBOL - directory to look into
/P/ age:LONG - age of the files in days
/P/ pattern:SYMBOL - pattern for the file path
/R/ :LIST[SYMBOL] - a list of file paths
.os.p.L.find:{[dir;age;pattern] 
	findCmd:"find -L ",1_(string dir)," -mtime +",(string age), " -name \"",string[pattern],"\" -prune";
	:`$.pe.at[system;findCmd;{[cmd;sig] .log.error[`os] "error while calling \"",cmd,"\". Maybe invalid arguments?"; :`$()}[findCmd;]]
	};

/F/ finds old files - Windows version. Note: on Windows the pattern applies to files only
/P/ dir:SYMBOL - directory to look into
/P/ age:LONG - age of the files in days
/P/ pattern:SYMBOL - pattern for the files
.os.p.W.find:{[dir;age;pattern] 
	findCmd:"forfiles /m ",(string pattern)," /p ",(.os.p.W.slash 1_string dir)," /d -",(string age)," /c \"cmd /c echo @path\"";
	:{x where not null x} `$.pe.at[system;findCmd;{[cmd;sig] .log.warn[`hk] "error while calling \"",cmd,"\". This may be caused by the command not finding any matching files, or invalid arguments"; :()}[findCmd;]]
	};

/F/ Compresses a file or directory - Linux version
/P/ path:STRING - path to the directory to compress
.os.p.L.compress:{[path] 
	system "tar -czvf ",path,".tar.gz ",path," --remove-files --absolute-names"
	};

/F/ Compresses a file or directory - Windows version
/P/ path:STRING - path to the directory or file to compress
.os.p.W.compress:{[path]
	path:.os.p.W.slash path;
	system "zip -q -r ",path,".zip ",path;
	// remove, calling the right function for a directory or file
	$[0<type key hsym `$path;.os.p.W.rmdir path;.os.p.W.rm path];
	};


/F/ surrounds a string with quotation marks
/P/ s:STRING
.os.p.q:{[s] "\"",s,"\""};

/--- stubs for docs generation, overwritten by initialization

/F/ removes a directory 
/P/ dirname:STRING
.os.rmdir:{[dirname] };

/F/ copies directory with contents
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

/--- initialization
$["w"~first string .z.o;.os,:.os.p.W;.os,:.os.p.L];


