As mentioned previously, configuration files contain variables' definitions. Please see description
of the following snippet from example `system.cfg` file and corresponding schema definition
(`system.qsd`):

```cfg
1.  libPath = ${EC_SYS_PATH}/bin/ec/components/${EC_COMPONENT_PKG}, ${EC_SYS_PATH}/bin/ec/libraries/
2.  logLevel = INFO
3.  logDest = FILE, STDERR
...
27. [group:streams]
28.   [[core.mrvs]]
29.     type = q:stream/stream
30.     libs = streamMrvs
31.     requires = core.tick, core.rdb
32.     port = ${basePort} +41
33.     command = "q stream.q"
34.     cfg.serverAux = rtr.rdb
```

In this snippet `libPath`, `logLevel` and `logDest` are global configuration variables. Anything
that follows text `[group:streams]` is related to a `group` section definition.

> **Note:**
>
> Lines 3 to 26 may contain some other sections or variables not relevant for this example, and
> there may be more subsections and sections after line 34.

For the details given in the sample snippet above, the corresponding section in the `qsd` file may
look as follows:

```qsd
1.  libPath = <type(LIST PATH)>
2.  logLevel = <type(SYMBOL)>
3.  logDest = <type(LIST SYMBOL)>

27. [group:<type(SYMBOL)>] 
28.   [[&lt;type(SYMBOL)>]]
29.     type = <type(SYMBOL) >
30.     requires = <type(LIST SYMBOL), default()>
31.     port = <type(PORT)>
32.     host = <type(STRING), default()>
33.     command = <type(STRING)>
```

Going over few important lines in snippets above one can observe connection between definitions in
`qsd` files and declarations in `cfg` files:

```qsd
1.  libPath = <type(LIST PATH)>
```

- `libPath` variable has to be of type `LIST PATH`
- `libPath` is a global: lines not proceeded by a section markup are considered to be global per
  configuration; in this case variables `libPath`, `logLevel`, `logDest` are global

```qsd
2.  logLevel = <type(SYMBOL)>
3.  logDest = <type(LIST SYMBOL)>
```

- `SYMBOL` and `LIST SYMBOL` are used as data types; variables are defined as global values

```cfg
27. [group:streams]
```

- Starts a new section name `stream` related to the user defined group of processes.

```qsd
27. [[&lt;type(SYMBOL)>]]
28.   type = <type(SYMBOL)>
29.   qsd = <type(LIST SYMBOL), default()>
30.   requires =  <type(LIST SYMBOL), default()>
31.   port = <type(PORT)>
32.   host = <type(STRING), default()>
33.   command = <type(STRING)>
```

- `type` field references component level schema file to be used (`stream.qsd` found in `stream`
  directory under `libPath`)

```cfg
29. [[core.mrvs]]
30.   type = q:stream/stream
31.   libs = streamMrvs
32.   requires = core.tickHF, core.tickLF, core.rdb
33.   port = ${basePort} + 41
34.   command = "q stream.q"
35.   cfg.serverAux = core.rdb
```

- line 30 above specifies file to be read for component-level schema (`stream/stream.qsd`); loaded
  file can have the following content:

```cfg
1. [group]
2.   cfg.serverAux = <type(LIST SYMBOL)>
3.   cfg.timeout = <type(INT), default(1000)>
4.   cfg.timer = <type(INT), default(1000)>
5. [table]
6.   serverSrc = <type(procname)>
7. [sysTable]
8. [user]
9. [userGroup]
```

- one only needs to consider schema definition lines for the source group from `system.cfg` file,
  (lines 2-4 for group section from component schema file above)
- lines 2-4 list parameters specific to the operation of the component; as opposed to the parameters
  required for the client’s infrastructure listed in `system.cfg` file

> **Note:**
>
> Definitions that don’t contain default fields **HAVE TO BE** declared in the system configuration file.

- for the sake of completeness, `stream/stream.qsd` file contains also sections indicating
  additional parameters for `dataflow.cfg` (sections `table` and `sysTable`) and `access.cfg`
  (sections `user` and `userGroup`), for example:

```cfg
1.  [table:rtrTrade]
2.    model = time(TIME), sym(SYMBOL), price(FLOAT), size(LONG)
...
15.   [[core.mrvs]]
16.   serverSrc = rtr.tick
```

> **Note:**
>

> As an exercise for the reader schema definition file for loaded plugin `stream/streamMrvs` is
> left for trace without description.

Other parts of the configuration can be traced in similar fashion. One needs to remember about the
connections between sections, values assigned to the type parameter and subsection names. For
example, in case of the `dataflow.cfg` (parameters for the `table` sections) this would be done by:

- going by sections and checking if there are matching subsections in the `system.cfg` file
- if there are common subsections in the `system.cfg` file, then its type is used to check for
  additional variable and schema definitions in the corresponding file schema file (e.g. `rdb.qsd`,
  `feedCsv.qsd`, etc.).
