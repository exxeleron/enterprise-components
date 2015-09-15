![Overview](img/Slide7.PNG)

### Configuration Files
System based on Enterprise Components is defined using configuration files (`*.cfg`). Following configuration files are available:

1. `system.cfg` - defines system structure, components that are used within the system, system layout on disk, ports, dependencies between components and other general configuration parameters.
1. `dataflow.cfg` - defines tables present in the system, their schemas (models) and lifecycle.
1. `access.cfg` - defines user rights, passwords and access groups.
1. `sync.cfg` - configuration file used during the failover procedure.

Configuration files are `INI`-like files that use notion of the sections (`[section]`) and relevant
subsections (`[[subsection]]`). Sections and subsections specify the relationship between various parts of the system. 

#### Section 

Meaning of the section depends on section type:
- `system.cfg` with:
  - `[group]` - section defining group of components
- `dataflow.cfg` with: 
  - `[template]` - section defining table templates
  - `[table]` - section defining user tables
  - `[sysTable]` - section defining system tables
- `access.cfg` with:
  - `[user]` section defining users
  - `[technicalUser]` - section defining technical users
  - `[userGroup]` - section defining user groups
- `sync.cfg` 

#### Subsection 

Subsections are context specific but always describe component within the system .e.g `[[core.rdb]]`. 
In some special cases (see `access.cfg` file) subsection can point to all components `[[ALL]]`.

#### Fields
Fields are simply key-value pairs
```cfg
cfg.timeout = 100
```
Fields are inherited from top-down, i.e. top level fields are inherited by all sections, section fields are inherited by all of its subsections.

### qsd Files

`qsd` files specify sections and fields that can be used to configure the system.

Each configuration field has to be declared in the schema definition file as a tuple of type and (optionally) the default value, for example:

```qsd
cfg.timeout = <type(INT), default(1000)>
```

- `type` – mandatory part; it is an equivalent of the standard data type declaration; (please see
  [Available data types](Available-data-types) for a list of all available data types);
- `default` – optional; default value to be used if variable definition is not present in
  appropriate configuration file

#### Main qsd files

There are three main `.qsd` files located in `qsl` package 
- `qsl/system.qsd` defining general layout of `etc/system.cfg` file,
- `qsl/dataflow.qsd` defining general layout of `etc/dataflow.cfg` file,
- `qsl/access.qsd` defining general layout of `etc/access.cfg` file,

#### Additional qsd files
Additional component-specific configuration is defined in component-specific `.qsd` file 
e.g. `rdb/rdb.qsd` contains rdb specific fields.
