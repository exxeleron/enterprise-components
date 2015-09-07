`sync.cfg` is a configuration file that contains information that can change, when switching between
master and slave hosts. Eg. `eodMng` process uses this file to determine master and slave hosts (via
`cfg.eodOrder` field). If master site fails, one can easily revert synchronisation order, just by
modifying `sync.cfg` contents of `system.cfg`:

```cfg
...
[group:kdb]
  [[core.eodMng]]
    type = q:eodMng
    qsd = eodMng.qsd
   ...
   .cfg.eodMngList = ((eodMng(core.eodMng), hdb(core.hdb), rdb(core.rdb)),
                     (eodMng(prod2.eodMng), hdb(prod2.hdb), rdb(prod2.rdb))) 
   ...
```

Content of `sync.cfg`:

```cfg
[group:kdb]
  [[core.eodMng]]
    cfg.eodOrder = core.eodMng, prod2.eodMng
```

During each end-of-day, `eodMng` process reads `sync.cfg` and refreshes value of `.cfg.eodOrder`. If
one wants to revert order of hosts, `.cfg.eodOrder` needs to be changed:

```cfg
[group:kdb]
  [[core.eodMng]]
    .cfg.eodOrder = prod2.eodMng, core.eodMng
```

Change will be visible for `eodMng` during nearest end-of-day.

### sync.cfg interface

Variables used in `sync.cfg` are defined in regular `qsd` files. The only difference is that
`sync.cfg` variables have special validator `syncOnly()`:

```qsd
cfg.eodOrder = <type(LIST SYMBOL), isComponent(), syncOnly()>
```

Such validator marks variable to be defined in `sync.cfg` (instead of `system.cfg`). These variables
can be defined only in `sync.cfg` – definig them in any other config file will result in error
message.

`cfgRdr` provides following interface functions to use `sync.cfg`:

Function                                       | Notes
-----------------------------------------------|-------
`.cr.loadSyncCfg[]`                            | Loads sync.cfg. This function can be called every time the file was changed
`.cr.getSyncCfgField[serviceId;section;field]` | Gets field value from sync.cfg. Arguments and result of this function are exactly the same as in .cr.getCfgField

