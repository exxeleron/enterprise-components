Configuration files are `INI`-like files that use notion of the sections (`[section]`) and relevant
subsections (`[[subsection]]`). Sections and subsections specify the relationship between various
parts of the system. Main top-level sections used in the configuration are:
- `group` - all settings related to a specific component or group of components
- `table` and `sysTable` - data flow and data model settings
- `user`, `technicalUser`, and `userGroup` – access related parameters

Subsections are context specific but always describe component within the system. Each
configuration variable has to be declared in the schema definition file as a tuple of type and (optionally) the default value, for example:

```qsd
cfg.timeout = <type(INT), default(1000)>
```

- `type` – mandatory part; it is an equivalent of the standard data type declaration; (see below)
- `default` – optional; default value to be used if variable definition is not present in
  appropriate configuration file

  
### Available data types

These are just the typical data types known from the other programming languages that can be used in
type declarations in qsd files (with their Java equivalents, where possible):

- `BOOLEAN` – possible values: TRUE, FALSE, 1, 0
- `SHORT` – Short in Java
- `INT` – Integer in Java
- `LONG` – Long in Java
- `REAL` - Float in Java
- `FLOAT` - Double in Java)
- `GUID` – UUID in Java
- `TIME` – Time in Java
- `TIMESTAMP` – Timestamp in Java
- `TIMESPAN` – Timespan in Java
- `DATETIME` – Timestamp in Java
- `DATE` – Date in Java
- `STRING` - Character array in Java
- `SYMBOL` - String in Java
- `PATH` – path as understood by the kdb+, for example:
    ```cfg
    eodPath = ${EC_SYS_PATH}/data/rtr.hdb
    ```

    where referenced `EC_SYS_PATH` variable is resolved to its value
- `PORT` – integers, such as:

    ```cfg
    port = 5001
    port = ${basePort} + 10 # simple arithmetic operations are allowed
    ```
- `LIST` - a list of atomic types. For example, the following line in a schema (.qsd) file declares a mandatory configuration variable named `cfg.ports` that is a list of integers:
   ```
   cfg.ports = <type(LIST INT)>
   ```
   To assign value to that variable the configuration file needs to contain a line like the following:
   ```
   cfg.ports = 17024,17004,17009,17020,17005,17021,17001,17006
   ```
   
- `TABLE` - the following `dataflow.qsd` definition:

    ```qsd
    model = <type(TABLE), col1(TYPESPEC), col2(TYPESPEC)>
    ```
    Example four-column table definition to use in dataflow.cfg:
    ```cfg
    model = time(TIME), sym(SYMBOL), price(FLOAT), size(LONG)
    ```
- `ARRAY` – array of `TABLE` entries (or a `TABLE` with data). `ARRAY` variables can be defined using following
  syntax:

    ```
    ARRAY = (row1,row2,row3, ... ,rowN)
    ```

    where:
    ```
    rowN = (col1(val1),... , colM(valM))
    ```
    is similar to `TABLE` definition. Example definition of `ARRAY` variable:

    ```
    tab = ((timezone(UTC), descr(Coordinated Universal Time), offset(00:00:00.000)),
           (timezone(CET), descr(Central European Time),      offset(01:00:00.000)))
    ```

    will yield following q table:

    timezone | descr                       | offset
    ---------|-----------------------------|-------------
      UTC    | Coordinated Universal Time  | 00:00:00.000
      CET    | Central European Time       | 01:00:00.000
    
