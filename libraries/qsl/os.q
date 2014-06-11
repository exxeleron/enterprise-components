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
.os.rmdirL:{[dirname]
  system "rmdir -r ",dirname;
  };


/F/ removes a directory Windows version
/P/ dirname:STRING
.os.rmdirW:{[dirname]
  system "rmdir /S /Q ",.os.p.q dirname;
  };
  
  
/F/ copies directory with contents - Linux version
/P/ dir1:STRING - source dir
/P/ dir2:STRING - target dir
.os.cpdirL:{[dir1;dir2]
  system "cp -rf ",(.os.p.q dir1)," ",.os.p.q dir2;
  };
  
/F/ copies directory with contents - Linux version
/P/ dir1:STRING - source dir
/P/ dir2:STRING - target dir
.os.cpdirW:{[dir1;dir2]
  system "xcopy  ",(.os.p.q dir1)," ",(.os.p.q dir2)," /i/q/k/h/o/y";
  };
  
/F/ creates a directory - Linux version
/P/ dir:STRING - name of the directory to create
.os.mkdirL:{[dir]
  system "mkdir -p ",.os.p.q dir; 
  };
  
/F/ creates a directory - Windows version
/P/ dir:STRING - name of the directory to create
.os.mkdirW:{[dir]
  system "mkdir ",.os.p.q dir;
  };
  
/F/ moves a file - Linux version
/P/ source:STRING - the source name
/P/ target:STRING - the target name
.os.moveL:{[source;target]
  system "mv ",source," ",target;
  };
  
/F/ moves a file - Windows version
/P/ source:STRING - the source name
/P/ target:STRING - the target name
.os.moveL:{[source;target]
  system "mv ",source," ",target;
  };
  
/F/ moves a file - Windows version
/P/ source:STRING - the source name
/P/ target:STRING - the target name
.os.moveW:{[source;target]
  system "move /y ",source," ",target;
  };
  

/F/ surrounds a string with quotation marks
/P/ s:STRING
.os.p.q:{[s] "\"",s,"\""};


/S/ initialization
$["w"~first string .z.o;
  [.os.rmdir:.os.rmdirW;
   .os.cpdir:.os.cpdirW;
   .os.mkdir:.os.mkdirW;
   .os.slash:"\\";
   .os.move:.os.moveW
   ];
  [.os.rmdir:.os.rmdirL;
   .os.cpdir:.os.cpdirL;
   .os.mkdir:.os.mkdirL;
   .os.slash:"/";
   .os.move:.os.moveL
   ]
  ];