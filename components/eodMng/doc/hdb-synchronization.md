It is possible to synchronize multiple databases between multiple hosts. Minimal configuration for
such synchronization would require `eodMng` configuration in `system.cfg` file. For example:

```
+---------------------------------------------------------------------------+-------------------------------------------+
| Configuration entry                                                       | Description                               |
+---------------------------------------------------------------------------+-------------------------------------------+
| [[core.eodMng]]                                                           | Configuration that is vital for eodMng    |
|   type = q:eodMng/eodMng                                                  | processes communication and               |
|   ...                                                                     | synchronization                           |
|   cfg.eodMngList = ((eodMng(core.eodMng), hdb(core.hdb), rdb(core.rdb)),  |                                           |
|                     (eodMng(prod2.eodMng),hdb(prod2.hdb),rdb(prod2.rdb))) |                                           | 
|---------------------------------------------------------------------------|-------------------------------------------|
|   cfg.syncProcessName = core.hdbSync                                      | Synchronization process to run (as        |
|                                                                           | defined in system.cfg) configuration file |
|---------------------------------------------------------------------------|-------------------------------------------|
| [[prod2.eodMng]]                                                          | Configuration of eodMng process on 2nd    |
|   type = c:eodMng                                                         | production                                |
|   port = 1234                                                             |                                           |
|   host = prod2.internal.eu                                                |                                           |
|---------------------------------------------------------------------------|-------------------------------------------|
|  [[prod2.hdb]]                                                            | Configuration of hdb process on 2nd       |
|    type = c:hdb                                                           | production. EC _DATA_PATH and host        |
|    port = 12345                                                           | required for data synchronization         |
|    host = prod2.internal.eu                                               |                                           |
|    EC_DATA_PATH = /kdb/data/core.hdb                                      |                                           |
+---------------------------------------------------------------------------+-------------------------------------------+
```

### Testing hdb synchronization

It is also possible to run synchronization procedure from command line, specifying synchronization
parameters using command line matching template below:

```bash 
$ yak console core.hdbSync –a "source dest date symBackupLocation [statusLocation]"
```

Where arguments for parameter '–a':
- `source` – location of source database
- `dest` – location of destination database (can be specified in host:directory notation for remote
  hosts)
- `date` – date to synchronize
- `symBackupLocation` – directory where original destination sym file will be stored for backup
  purposes.
- `statusLocation` – optional; path to file to which status information will be written

**Example:**

```bash
$ yak console core.hdbSync -a "/hdb /mirror/hdb 2001.04.23 /data/mirror/backup"
```

> **Note:**
> 
> `hdbSync` is relaying on `rsync` system tool. In order to use it effectively operating system needs
> to be configured properly. Such configurations are out of scope of this document, but please refer
> to on-line manual pages available on your OS (`rsync(1`), `ssh(1)`, `ssh-copy-id(1)`).


> **Note:**
>
> `EC_SYS_PATH` environmental variable will not be resolved in `yak` interactive mode. In this case
> please use absolute paths.
