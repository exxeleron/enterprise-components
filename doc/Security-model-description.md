Processes running within Enterprise Components can be restricted to a limited group of users
specified in `access.cfg` file. Such restrictions are turned on using `u*` options in `system.cfg`
file:

- `uOpt` – authorization mode for q process (`u`/`U` command-line options)
- `uFile` – authorization file for q process

> **Note:**
> 
> `uOpt` and `uFile` mechanism is a bridge between Enterprise Components access management and
> internal q mechanism (see `-u`/`-U` description on https://code.kx.com/wiki/Reference/Cmdline)

Example `system.cfg` entry which defines user files’ location and `u`/`U` option to use:

```cfg
uOpt = U
uFile = ${EC_SYS_PATH}/data/shared/security/${EC_COMPONENT_ID}.txt
```

`u*` options can be set on global, group, or process level. Lowest-level definition has precedence
over higher ones.

Sample `access.cfg` below presents users’ definition in some example system. Details on
configuration fields and appropriate values can be found in schema files.

```
+-------------------------------------------+----------------------------------------------|
| Configuration                             | Description                                  |
+-------------------------------------------+----------------------------------------------+
| stopWords = .z.exit,.z.po,.z.pc,.ap.users | Comma-separated list of keywords stopping    |
|                                           | execution when present in the supplied       |
|                                           | command/query                                |
|-------------------------------------------|----------------------------------------------|
| auditView = CONNECTIONS_INFO              | Enables additional logging on open           |
|                                           | connections                                  |
|-------------------------------------------|----------------------------------------------|
| checkLevel = STRICT                       | Query/command checks are strict by default   |
|-------------------------------------------|----------------------------------------------|
| [technicalUser:tu]                        | Technical user assigned to admin group with  |
|   pass = 0x54mp13P455                     | encrypted password. At least one technical   |
|   usergroups = admin                      | user is MANDATORY                            |
|-------------------------------------------|----------------------------------------------|
| [user:queryuser]                          | Ordinary user definition with encrypted      |
|   pass =0x50m354mp13P455                  | password, assigned to group ordinary         |
|   usergroups = ordinary                   |                                              |
|-------------------------------------------|----------------------------------------------|
| [userGroup:admin]                         | Admin group definition. Group has access to  |
|   [[ALL]]                                 | all function namespaces with no checks       |
|   namespaces = ALL                        | performed on supplied commands/queries on    |
|   checkLevel = NONE                       | all components                               |
|-------------------------------------------|----------------------------------------------|
| [userGroup:ordinary]                      | Ordinary user group. Group has access to all |
|   [[access.ap]]                           | functions in .demo namespace. STRICT rule is |
|   namespaces = .demo                      | applied to all queries – only interface      |
|   checkLevel = STRICT                     | calls are allowed (i.e.: users won’t be able |
|                                           | to execute statements from studoForKdb+)     |
+-------------------------------------------+----------------------------------------------+
```

Please refer to (Generating user password)[../components/authentication/] for more details on password
generation.

> **Note:**
>
> Changes in `access.cfg` file have to be applied to the system using `authentication/refreshUFiles`
> utility (See (Refreshing permissions’ settings)[Refreshing-permissions%E2%80%99-settings]).

`auditView` - settings log additional information to the component’s log file. Depending on the
settings, log messages may look like:

```
+-------------------+----------------------------------------------------------------------------------------------------------------+
| auditView value   | Example log message                                                                                            |
+-------------------+----------------------------------------------------------------------------------------------------------------+
| CONNECTIONS_INFO  | INFO 2013.12.12 08:26:44.304 auth - | action=`USER_LOGIN| user=`tu| hnd=8i| ip="192.168.4.168"| addr=`src.host |
|                   | INFO 2013.12.12 08:27:10.029 auth - | action=`USER_LOGOUT| user=`tu| hnd=8i                                    |
|-------------------|----------------------------------------------------------------------------------------------------------------|
| SYNC_ACCESS_INFO  | INFO 2013.12.12 08:27:29.392 auth - | action=`SYNC_STARTED| user=`tu| hnd=8i| asString=1b| query="2+3"         |
|                   | INFO 2013.12.12 08:27:29.392 auth - | action=`SYNC_COMPLETED| resType=-7h| resCount=1                          |
|                   | INFO 2013.12.12 08:31:39.051 auth - | action=`SYNC_STARTED| user=`tu| hnd=9i| asString=0b| query="({x};1)"     |
|                   | INFO 2013.12.12 08:31:39.051 auth - | action=`SYNC_COMPLETED| resType=-7h| resCount=1                          |
|-------------------|----------------------------------------------------------------------------------------------------------------|
| ASYNC_ACCESS_INFO | INFO 2013.12.12 08:29:47.488 auth - | action=`ASYNC_STARTED| user=`tu| hnd=9i| asString=1b| query="2+3"        |
|                   | INFO 2013.12.12 08:29:47.488 auth - | action=`ASYNC_COMPLETED| resType=-7h| resCount=1                         |
+-------------------+----------------------------------------------------------------------------------------------------------------+
```
