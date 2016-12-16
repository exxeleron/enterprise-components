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

/A/ DEVnet: Bartosz Dolecki, Bartosz Kaliszuk
/V/ 3.0

/S/ Housekeeping tool:
/-/ Responsible for:
/-/  - cleaning up KDB system artefacts triggered once a day as per configuration settings (e.g. deletion or compression of old logs, journals etc.)
/-/ 
/-/ Prerequisites:
/-/  - standard Linux tool "find" and bash compliant console
/-/ 
/-/ Housekeeping actions:
/-/ Files to be processed can be selected based on filename patterns and age of the file. List of processed files is 
/-/ defined for each process separately in system.cfg file. For each process you can define variable 'housekeeping' 
/-/ which contains list of actions to undertake during housekeeping. Actions are performed for each process separately, 
/-/ in the same order they were defined in system.cfg. For example
/-/ (start code)
/-/ housekeeping = ( action1, action2, ... , actionN )
/-/ (end)
/-/ where each action is defined as
/-/ (start code)
/-/ action = ( action(ACTION_NAME), dir(START_DIR), age(AGE_IN_DAYS), pattern(PATTERN) )
/-/ (end)
/-/ ACTION_NAME - name of action to invoke on file (either delete or compress)
/-/ START_DIR   - directory in which files will be looked up (one can use variables like $dataPath here)
/-/ AGE_IN_DAYS - minimal age of files (action will be invoked for files that were modified/created at least AGE_IN_DAYS ago)
/-/ PATTERN     - pattern of file name (as in Linux 'find' command)
/-/
/-/ For example, to
/-/ - delete all files from log directory with extension 'out' after 5 days
/-/ - compress all files from log directory with extension 'log' after 10 days
/-/ one would need to write it in the following way
/-/ (start code)
/-/ housekeeping = ( (action(delete),   dir($logPath), age(5),  pattern(*.out)) , 
/-/                  (action(compress), dir($logPath), age(10), pattern(*.log)) )
/-/ (end)
/-/ 
/-/ 'housekeeping' variable is inherited in system.cfg tree and can be defined on
/-/ top level     - this way each process will inherit its value
/-/ group level   - each process in the group will inherit it
/-/ process level - for each process independently
/-/ 
/-/ Value defined on lower level overwrites inherited value. Typical usage of this functionality is to define action 
/-/ for logs on top level so every process will have its logs deleted/compressed after the same amount of time.
/-/ Any other process which requires custom handling can be modified on lower level.
/-/
/-/ Housekeeping scheduling:
/-/ Time of housekeeping start is defined in 'cfg.startAt' variable in housekeeping process section
/-/ (begin code)
/-/ cfg.startAt = 03:00:00 
/-/ (end)
/-/
/-/ Housekeeping tasks:
/-/ List of all housekeeping tasks is held in <.hk.taskList> table.
/-/
/-/ Housekeeping manual run:
/-/ To start housekeeping at any time, please run
/-/ (start code)
/-/ .hk.processAllTasks[.hk.taskList]
/-/ (end)
/-/
/-/ Housekeeping plugins:
/-/ *delete*
/-/ This plugin simply deletes files and directories that match pattern and time criteria
/-/ *compress*
/-/ This plugin performs gzip compression on files/directories. In result original file/directory is deleted and 
/-/ instead compressed file is created (with extension tar.gz).Already compressed files are not processed (based on
/-/ the file extension). On Windows, the zip utility from the Info-ZIP project needs to be available on PATH.
/-/ 
/-/ *Custom plugins*
/-/ In addition to 'delete' and 'compress' plugins, additional actions can be performed by loading custom plugins.
/-/ Each plugin is a function in a namespace .hk.plug (for example <.hk.plug.delete[path]> or 
/-/ <.hk.plug.compress[path]>, that only takes one parameter: path to the file. Once these are loaded, they can be
/-/ used by setting an ACTION_NAME as plugin name (on action list in housekeeping variable). For example, 
/-/ implementation of the 'delete' plugin is done in following way
/-/ (start code)
/-/ 1. .hk.plug.delete:{[path]
/-/ 2.  .log.info[`hk] "deleting: ",string[path];
/-/ 3.  isDir:0<type key hsym path;
/-/ 4.  cmd:"rm",$[isDir;" -r ";" "],string path;
/-/ 5.  .log.debug[`hk] "cmd: ",cmd;
/-/ 6.  system cmd;
/-/ 7. };
/-/ (end)
/-/ Please note that plugin must make distinction between file and directory, in above example it is done in line 3.
/-/ Notes on Linux 'find' tool:
/-/ To search for files 'find' tool is used, for example
/-/ (begin code)
/-/ find -L START_DIR -mtime +AGE_IN_DAYS -name PATTERN -prune
/-/ (end)
/-/ 'find' command follows symbolic links and matches directories as well as files (see -prune option in LINUX find 
/-/ manual). If above commands fails, appropriate message is logged
/-/ (begin code)
/-/ error while calling "find -L /apps/kdb/data/prod2.eodMng -mtime +10 -name "*.gz" -prune". Maybe invalid arguments
/-/ (end)
/-/ It is often helpful to rerun such command manually in a shell to see error reported by operating system.
/-/ Usually errors are caused by invalid START_DIR (START_DIR does not exist). For example, some external processes 
/-/ (like prod2.eodMng) do not have data or log directories and therefore the error in this case will most likely occur.

/-----------------------------------------------------------------------------/
/                               lib and etc                                   /
/-----------------------------------------------------------------------------/
system"l ",getenv[`EC_QSL_PATH],"/sl.q";
.sl.init[`hk];

/-----------------------------------------------------------------------------/
.sl.lib["cfgRdr/cfgRdr"];
.sl.lib["qsl/os"]

/-----------------------------------------------------------------------------/
/                              tasks processing                               /
/-----------------------------------------------------------------------------/
/F/ Processes all requested housekeeping tasks.
/P/ taskList:TABLE - list of actions to perform
/-/  -- proc:SYMBOL    - process name
/-/  -- action:SYMBOL  - name of action to invoke on file (either delete or compress)
/-/  -- dir:SYMBOL     - directory in which files will be looked up (one can use variables like $dataPath here)
/-/  -- age:INT        - minimal age of files (action will be invoked for files that were modified/created at least AGE_IN_DAYS ago)
/-/  -- pattern:SYMBOL - pattern of file name (as in Linux 'find' command)
/R/ no return value
/E/ .hk.processAllTasks[.hk.taskList]
.hk.processAllTasks:{[taskList]
  .log.info[`hk] "Processing ",string[count taskList]," tasks.";
  .hk.p.processOneTask each taskList;
  };

/-----------------------------------------------------------------------------/
.hk.p.processOneTask:{[taskDef]
  plugin:` sv (`.hk.plug;taskDef[`action]);
  if[0~count key taskDef[`dir];
    .log.warn[`hk]"Given directory ",string[taskDef[`dir]], " is missing. Hk will skip this task. Please check if process ", string[taskDef[`proc]], " was properly started";:(::)];
  files:.os.find[taskDef `dir;taskDef `age;taskDef `pattern];
  if[0~count files;.log.info[`hk] "no files found matching pattern ",(string taskDef `pattern),", skipping task ",string taskDef `action;:(::)];
  .log.info[`hk] "Running ",string[plugin], " for ", string[taskDef[`proc]], " on ",string[count files], " files";
  {[plugin;file] .pe.dot[{x @ y};(plugin;file);{[plugin;file;sig] .log.error[`hk] raze "Signal on plugin: ",string[plugin],", file: ",string[file]," - ",string[sig]}[plugin;file;]]}[plugin;] each files;
  };

/-----------------------------------------------------------------------------/
/                               housekeeping plugins                          /
/-----------------------------------------------------------------------------/
/F/ Housekeeping `delete plugin. Deletes given path including its content.
/P/ path:SYMBOL - path to the file or directory
/R/ no return value
/E/ .hk.plug.delete `:/data/archive/2012.02.02/
/E/ .hk.plug.delete `:/data/tick/journal2015.02.02
.hk.plug.delete:{[path]
  .log.info[`hk] "deleting: ",string[path];
  isDir:0<type key hsym path;
  $[isDir;.os.rmdir string path;.os.rm string path];
  };

/-----------------------------------------------------------------------------/
/F/ Housekeeping `compress plugin. Compresses given path including its content.
/P/ path:SYMBOL - path to the file or directory
/R/ no return value
/E/ .hk.plug.compress `:/data/archive/2012.02.02/
/E/ .hk.plug.compress `:/data/tick/journal2015.02.02
.hk.plug.compress:{[path]
  if[path like "*.tar.gz";.log.info[`hk] "compressing: file" ,string[path], " already compressed - skipping";:(::);];
  if[path like "*.zip";.log.info[`hk] "compressing: file" ,string[path], " already compressed - skipping";:(::);];
  .log.info[`hk] "compressing: ",string[path];
  .os.compress string path;
  };

/-----------------------------------------------------------------------------/
/                                implementation                               /
/-----------------------------------------------------------------------------/
/F/ Timer function, executes .hk.processAllTasks[].
/P/ ts:TIME - time, not used.
/R/ no return value
/E/ .hk.p.onTimer .z.t
.hk.p.onTimer:{[ts]
  .hk.processAllTasks[.hk.taskList];
  };

/-----------------------------------------------------------------------------/
/F/ Component initialization entry point.
/P/ flags:LIST - nyi
/R/ no return value
/E/ .sl.main`
.sl.main:{[flags]
  .cr.loadCfg[`ALL];

  /G/ Housekeeping tasks, loaded from `housekeeping field from the system.cfg
  /-/  -- proc:SYMBOL    - process name
  /-/  -- action:SYMBOL  - name of action to invoke on file (either delete or compress)
  /-/  -- dir:SYMBOL     - directory in which files will be looked up (one can use variables like $dataPath here)
  /-/  -- age:INT        - minimal age of files (action will be invoked for files that were modified/created at least AGE_IN_DAYS ago)
  /-/  -- pattern:SYMBOL - pattern of file name (as in Linux 'find' command)
  .hk.taskList:raze exec actions from update actions:proc {update proc:x from y}' housekeeping from .cr.getByProc[enlist `housekeeping];
  startAt:.cr.getCfgField[`THIS;`group;`cfg.startAt];

  .sl.libCmd[];   
  
  .tmr.runAt[startAt;`.hk.p.onTimer;`.hk.p.onTimer];
  };

/-----------------------------------------------------------------------------/
.sl.run[`hk;`.sl.main;`];




