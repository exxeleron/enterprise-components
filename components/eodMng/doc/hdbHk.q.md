### Hdb housekeeping tool

#### Responsible for
* performing predefined tasks such as deletion, compression, conflation, etc. enabled through
  plugins
* providing functionality (through dedicated API) to write custom plugins

#### Input parameters for the script
`hdbHk.`q is invoked from `eodMng.q` process and receives following input parameters
* `hdb` - path to hdb
* `hdbConn` - name of hdb process to be reloaded after housekeeping procedure
* `date` (optional) - date for which housekeeping will be performed, if not specified then current date is used
* `status` (optional) - path to file which housekeeping status is written (required for `eodMgn` communication)

**Sample command using yak**
```bash
yak start batch.core_hdbHk -a "-hdb ${EC_SYS_PATH}/data/core.hdb -hdbConn core.hdb -date 2013.01.01 -status ${EC_SYS_PATH}/data/core.eodMng/hkStatus"
```

#### Workflow
1. Load configuration file with list of tasks
1. Tasks from the file are loaded into `.hdbHk.cfg.taskList` table
1. Tasks are executed based on the order in the configuration file / `.hdbHk.cfg.taskList` table

> **Notes:**
> 
> 1. Please remember to order the tasks correctly, for example conflation before compression
> 2. Each plugin call is logged and wrapped in protected evaluation
> 3. Before modification each table partition is backed up in `cfg.bckDir` directory
>    * update this part
>    * dsaf adsf

#### Overview

Housekeeping script (`hdbHk.q`) is part of the `eodMng` that manages hdb housekeeping and can be
extended through plugins. Tasks to be performed by this script are in the `.hdbHk.cfg.taskList`
table:

plugin     | table           | day_in_past | param1 | param2 | . . .  | param6
-----------|-----------------|-------------|--------|--------|--------|-------
`compress` | tab1,tab2,tab3  | 30          | arg_1  | arg_2  |        |
`delete`   | tab1,tab2       | 50          |        |        |        |

where:

* `plugin` - name of the plugin (symbol - all plugins exist in `.eodsnc.hk.plugins` namespace)
* `table` - list of tables on which plugins will be operating (``enlist ` `` for all tables)
* `day_in_past` - distance (in days) between *current date*, and date of partition that will be
  modified by plugin (1 for previous day, 2 for two days ago etc.)
* `param[1-6]` - additional parameters passed to plugin (up to 6 parameters)

For the given table, `hdbHk.q` would execute following function calls:

```q
.eodsnc.hk.plugins.compress[date;`tab1;arg1;arg2;arg3];
.eodsnc.hk.plugins.compress[date;`tab2;arg1;arg2;arg3];
.eodsnc.hk.plugins.compress[date;`tab3;arg1;arg2;arg3];
.eodsnc.hk.plugins.delete[date;`tab1;arg`;arg2;arg3];
.eodsnc.hk.plugins.delete[date;`tab2;arg`;arg2;arg3];
```

