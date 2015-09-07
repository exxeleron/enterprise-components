`hdb` housekeeping (Enterprise Components 3.0 EodMng->hdbHk.q) is a plug-in
based process that handles deletion of old partitions, data compression, snapshots etc., after
end-of-day process, but before `hdb` synchronization between sites. It is triggered from `eodMng`.

Each housekeeping task is a named action defined in housekeeping process (`core.hdbHk`). Each such
task is executed according to defined task queue and table assignment in `dataflow.cfg`. Plugin is
executed on specific date in the past (please see `dayInPast` parameter).

Following example will illustrate most recent values (`mrvs`) plugin integration: `mrvs` code is
predefined in `core.hdbHk`, custom plugins can be loaded via `libs` field in
`system.cfg`. Predefined version has the following code:

```q
.hdbHk.plug.action[`mrvs]:{[date;tableHnd;args]
  columns:cols[tableHnd];
  lasts:columns except `sym;
  result:columns xcols 0!?[tableHnd; () ; (enlist `sym)!enlist `sym ; ()];
  tableHnd set result;
  @[tableHnd;`sym;`p#];
  };
```

Table `quote` is defined in housekeeping process in `dataflow.cfg` file (there might be more
housekeeping jobs defined per table). Given setup will execute plugin `mrvs` on partition with date
`EOD_DATE-30`, and execute plugin delete on partition with date `EOD_DATE-120`:

```cfg
[table:quote]
  [[core.hdbHk]]
    hdbHousekeeping = ((action(mrvs),dayInPast(30)), (action(delete),dayInPast(120)))
```

where:

- `action` – housekeeping plugin to run (e.g. `mrvs`)
- `dayInPast` – specifies the date in the past (`EOD` date minus `dayInPast`) 

In order to activate defined housekeeping job, `eodMng` needs to be configured properly in
`system.cfg` configuration file (example configuration entry below):

```cfg
[group:core]
  [[core.eodMng]]
    ...
    cfg.hkProcessName = core.hdbHk
```

### Testing housekeeping procedure

To start housekeeping script please call `yak` command and pass proper parameters using `–a`
argument:

```bash
$ yak console core.hdbHk -a "-hdb ${EC_SYS_PATH}/data/core.hdb -hdbConn core.hdb -date 2012.01.01 -status ${EC_SYS_PATH}/data/core.eodMng/hkStatus noexit"
```

Where arguments for parameter `–a`:

- `hdb` – location of source database
- `hdbConn` – name of hdb process to reload after housekeeping procedure
- `date` – (optional) date for which housekeeping will be performed, if not specified then current
  date is used
- `status` – (optional) path to file which housekeeping status is written (required for eodMgn
  communication)
- `noexit` - by omitting this option, the process will terminate automatically

Description of command line parameters can be found in Enterprise Components 3.0 Developers'
Documentation (EodMng->hdbHk.q).

This process will load `dataflow.cfg`, `system.cfg` configuration files and call all defined
plugins.
