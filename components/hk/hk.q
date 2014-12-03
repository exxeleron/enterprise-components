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

/A/ DEVnet: Bartosz Dolecki, Bartosz Kaliszuk
/V/ 3.0

/S/ Housekeeping tool:
/S/ Responsible for:
/S/  - cleaning up KDB system artefacts triggered once a day as per configuration settings (e.g. deletion or compression of old logs, journals etc.)
/S/ 
/S/ Prerequisites:
/S/  - standard Linux tool "find" and bash compliant console
/S/ 
/S/ Housekeeping actions:
/S/ Files to be processed can be selected based on filename patterns and age of the file. List of processed files is 
/S/ defined for each process separately in system.cfg file. For each process you can define variable 'housekeeping' 
/S/ which contains list of actions to undertake during housekeeping. Actions are performed for each process separately, 
/S/ in the same order they were defined in system.cfg. For example
/S/ (start code)
/S/ housekeeping = ( action1, action2, ... , actionN )
/S/ (end)
/S/ where each action is defined as
/S/ (start code)
/S/ action = ( action(ACTION_NAME), dir(START_DIR), age(AGE_IN_DAYS), pattern(PATTERN) )
/S/ (end)
/S/ ACTION_NAME - name of action to invoke on file (either delete or compress)
/S/ START_DIR   - directory in which files will be looked up (one can use variables like $dataPath here)
/S/ AGE_IN_DAYS - minimal age of files (action will be invoked for files that were modified/created at least AGE_IN_DAYS ago)
/S/ PATTERN     - pattern of file name (as in Linux 'find' command)
/S/
/S/ For example, to
/S/ - delete all files from log directory with extension 'out' after 5 days
/S/ - compress all files from log directory with extension 'log' after 10 days
/S/ one would need to write it in the following way
/S/ (start code)
/S/ housekeeping = ( (action(delete),   dir($logPath), age(5),  pattern(*.out)) , 
/S/                  (action(compress), dir($logPath), age(10), pattern(*.log)) )
/S/ (end)
/S/ 
/S/ 'housekeeping' variable is inherited in system.cfg tree and can be defined on
/S/ top level     - this way each process will inherit its value
/S/ group level   - each process in the group will inherit it
/S/ process level - for each process independently
/S/ 
/S/ Value defined on lower level overwrites inherited value. Typical usage of this functionality is to define action 
/S/ for logs on top level so every process will have its logs deleted/compressed after the same amount of time.
/S/ Any other process which requires custom handling can be modified on lower level.
/S/
/S/ Housekeeping scheduling:
/S/ Time of housekeeping start is defined in 'cfg.startAt' variable in housekeeping process section
/S/ (begin code)
/S/ cfg.startAt = 03:00:00 
/S/ (end)
/S/
/S/ Housekeeping tasks:
/S/ List of all housekeeping tasks is held in <.hk.taskList> table.
/S/
/S/ Housekeeping manual run:
/S/ To start housekeeping at any time, please run
/S/ (start code)
/S/ .hk.processAllTasks[.hk.taskList]
/S/ (end)
/S/
/S/ Housekeeping plugins:
/S/ *delete*
/S/ This plugin simply deletes files and directories that match pattern and time criteria
/S/ *compress*
/S/ This plugin performs gzip compression on files/directories. In result original file/directory is deleted and 
/S/ instead compressed file is created (with extension tar.gz).Already compressed files are not processed (based on
/S/ the file extension). On Windows, the zip utility from the Info-ZIP project needs to be available on PATH.
/S/ 
/S/ *Custom plugins*
/S/ In addition to 'delete' and 'compress' plugins, additional actions can be performed by loading custom plugins.
/S/ Each plugin is a function in a namespace .hk.plug (for example <.hk.plug.delete[path]> or 
/S/ <.hk.plug.compress[path]>, that only takes one parameter: path to the file. Once these are loaded, they can be
/S/ used by setting an ACTION_NAME as plugin name (on action list in housekeeping variable). For example, 
/S/ implementation of the 'delete' plugin is done in following way
/S/ (start code)
/S/ 1. .hk.plug.delete:{[path]
/S/ 2.  .log.info[`hk] "deleting: ",string[path];
/S/ 3.  isDir:0<type key hsym path;
/S/ 4.  cmd:"rm",$[isDir;" -r ";" "],string path;
/S/ 5.  .log.debug[`hk] "cmd: ",cmd;
/S/ 6.  system cmd;
/S/ 7. };
/S/ (end)
/S/ Please note that plugin must make distinction between file and directory, in above example it is done in line 3.
/S/ Notes on Linux 'find' tool:
/S/ To search for files 'find' tool is used, for example
/S/ (begin code)
/S/ find -L START_DIR -mtime +AGE_IN_DAYS -name PATTERN -prune
/S/ (end)
/S/ 'find' command follows symbolic links and matches directories as well as files (see -prune option in LINUX find 
/S/ manual). If above commands fails, appropriate message is logged
/S/ (begin code)
/S/ error while calling "find -L /apps/kdb/data/prod2.eodMng -mtime +10 -name "*.gz" -prune". Maybe invalid arguments
/S/ (end)
/S/ It is often helpful to rerun such command manually in a shell to see error reported by operating system.
/S/ Usually errors are caused by invalid START_DIR (START_DIR does not exist). For example, some external processes 
/S/ (like prod2.eodMng) do not have data or log directories and therefore the error in this case will most likely occur.

/T/ q hk.q 

/------------------------------------------------------------------------------/
/                               lib and etc                                    /
/------------------------------------------------------------------------------/
system"l ",getenv[`EC_QSL_PATH],"/sl.q";
.sl.init[`hk];

/---------------------------------------------------------------------------------/

.sl.lib["cfgRdr/cfgRdr"];
.sl.lib["qsl/os"]

/---------------------------------------------------------------------------------/

/F/ function that processes all tasks defined in its argument
/P/ taskList : TABLE - list of actions to perform
/E/ .hk.processAllTasks[.hk.taskList]
.hk.processAllTasks:{[taskList]
  .log.info[`hk] "Processing ",string[count taskList]," tasks.";
  .hk.p.processOneTask each taskList;
  };

.hk.p.processOneTask:{[taskDef]
  plugin:` sv (`.hk.plug;taskDef[`action]);
  files:.os.find[taskDef `dir;taskDef `age;taskDef `pattern];
  if[0~count files;.log.info[`hk] "no files found matching pattern ",(string taskDef `pattern),", skipping task ",string taskDef `action;:(::)];
  .log.info[`hk] "Running ",string[plugin], " for ", string[taskDef[`proc]], " on ",string[count files], " files";
  {[plugin;file] .pe.dot[{x @ y};(plugin;file);{[plugin;file;sig] .log.error[`hk] raze "Signal on plugin: ",string[plugin],", file: ",string[file]," - ",string[sig]}[plugin;file;]]}[plugin;] each files;
  };


.hk.plug.delete:{[path]
  .log.info[`hk] "deleting: ",string[path];
  isDir:0<type key hsym path;
  $[isDir;.os.rmdir string path;.os.rm string path];
  };


.hk.plug.compress:{[path]
  if[path like "*.tar.gz";.log.info[`hk] "compressing: file" ,string[path], " already compressed - skipping";:(::);];
  if[path like "*.zip";.log.info[`hk] "compressing: file" ,string[path], " already compressed - skipping";:(::);];
  .log.info[`hk] "compressing: ",string[path];
  .os.compress string path;
  };

.hk.p.onTimer:{[id]
  .hk.processAllTasks[.hk.taskList];
  };

.sl.main:{[flags]
  .cr.loadCfg[`ALL];
  .hk.taskList:raze exec actions from update actions:proc {update proc:x from y}' housekeeping from .cr.getByProc[enlist `housekeeping];
  startAt:.cr.getCfgField[`THIS;`group;`cfg.startAt];

  .sl.libCmd[];   
  
  .tmr.runAt[startAt;`.hk.p.onTimer;`.hk.p.onTimer];
  };

.sl.run[`hk;`.sl.main;`];




