UTC or local time within the system can be setup using `timestampMode` in the `system.cfg`. The
default value is UTC.

In order to change it from UTC to local add the following line to the `system.cfg` in the global
section:

```
timestampMode = LOCAL
```

Local time will be applied automatically after full restart of system. This change will affect:

- messages' timestamping
- log messages' timestamping and log rotating
- timer callbacks
- end-of-day broadcasting
- `hdb` queries that are using API functions from `qsl/query.q`

To adjust time according to the `timestampMode` please use following API functions that are available in the `qsl/sl.q` library:

- `.sl.zd[]` - return current date, wrapper for `.z.d`/`.z.D`
- `.sl.zt[]` - return current time, wrapper for `.z.t`/`.z.T`
- `.sl.zz[]` - return current datetime, wrapper for `.z.z`/`.z.Z`
- `.sl.zp[]` - return current timestamp, wrapper for `.z.p`/`.z.P`
- `.sl.zn[]` - return current timespan, wrapper for `.z.n`/`.z.N`

Following code example shows updating table with current time and date according to the
`timestampMode` setup:

```
/ timestampMode = UTC in system.cfg
q) table:([] sym:`sym1`sym2)
q) update time:.sl.zt[], date:.sl.zd[] from table
sym  time         date
----------------------------
sym1 14:30:01.236 2013.12.11
sym2 14:30:01.236 2013.12.11
```
