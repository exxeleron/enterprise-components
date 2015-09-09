## **`mock` components set**
`mock` - Set of mock used for various tests
Component is located in the `ec/components/mock`.

### Functionality
  - [mock lib](mock.q) - facility library for writing various mocks
  - [gen](gen.q) - dummy data-stream generator
  - [empty](empty.q) - empty process with configuration loaded
  - [hdbMock](hdbMock.q) - [hdb](hdb) mock
  - [tickHFMock](tickHFMock.q) - [tickHF](tickHF) mock
  - [rdbPluginMock](rdbPluginMock.q) - [rdb](rdb) plugin mock

### `mock/mock` library
Facility for writing various mocks

#### .mock.func[func;argCnt;resCode]
Mock function. Function calls will be placed into .mock.trace dictionary. 
Previous value will be stored on the stack
- func:SYMBOL or STRING    - function name
- argCnt:INT     - number of function argument, arguments will be named a0, a1, a2, etc
- resCode:STRING - additional code used at the end of the function - result from the code will be a result from function

#### .mock.var[varName;varValue]
Mock variable. Previous value will be stored on the stack.
- varName:SYMBOL - variable name
- varValue:ANY - new variable value

#### .mock.trace
Trace of function calls done using mocks created with .mock.func[]
key   - function name
value - table with function calls ([]timestamp, .z.w of the caller, arguments).
 - ts:TIMESTAMP - timestamp of the call
 - w:INT        - handle of the caller (.z.w)
 - args:LIST    - list of the arguments

-------------------------------------------------------------------------------
## `mock/gen` sub-component**
Data-stream generator.

### Functionality
- generating stream of dummy records basing on the data model
- automatic discovery of destination protocol
- support for [tickHF](../tickHF), [tickLF](../tickLF) and [dist](../dist) protocols
 
### Configuration
Note: configure port and component name according to your conventions (core.gen)

#### system.cfg example
```cfg
  [[core.gen]]            
    command = "q gen.q"   
    type = q:mock/gen     
    port = ${basePort} + 9
    memCap = 5000         
    cfg.dst = core.tick   
```

#### dataflow.cfg example
```cfg
[table:quote]
  [[core.gen]]    
    period = 5000 
    pkgSize = 10  
```

-------------------------------------------------------------------------------
## **`mock/empty` sub-component**
Empty process with configuration loaded.

### Functionality
- allows loading custom code
- used for mocking processes in tests
 
### Configuration

#### system.cfg example
```cfg
  [[t.tabs]]
    command = "q empty.q"
    type = q:mock/empty
    port = ${basePort} + 1
    memCap = 10000
    libs = qsl/tabs
```

-------------------------------------------------------------------------------
## **`mock/hdbMock` sub-component**
`mock/hdbMock` - [`hdb` component](../hdb) mock.

### Functionality
- mocking `.hdb.fillMissingTabs` and `.hdb.reload` functions
 
### Configuration

#### system.cfg example
```cfg
  [[t.hdb]]
    command = "q hdbMock.q"
    type = q:mock/hdbMock
    port = ${basePort} + 2
    memCap = 10000
```

-------------------------------------------------------------------------------
## **`mock/tickHFMock` sub-component**
`mock/tickHFMock` - [`tickHF` component](../tickHF) mock.

### Functionality
- mocking `.u.sub`
- simple pub-sub mechanism implementation
 
### Configuration

#### system.cfg example
```cfg
  [[t.tick]] 
    command = "q tickHFMock.q"
    type = q:mock/tickHFMock
    port = ${basePort} + 1
```

-------------------------------------------------------------------------------
## **`mock/rdbPluginMock` sub-component**
`mock/rdbPluginMock` - [`rdb` component](../rdb) plugin mock.

### Functionality
- mocking `.rdb.plug.beforeEod[`beforeEod]` and `.rdb.plug.afterEod[`afterEod]` functions
 
### Configuration

#### system.cfg example
```cfg
   [[t.rdb]]
    command = "q rdb.q"
    type = q:rdb/rdb
    port = ${basePort} + 2
    libPath = ${EC_SYS_PATH}/bin/ec/components/${EC_COMPONENT_PKG}, ${EC_SYS_PATH}/bin/ec/libraries/,${EC_SYS_PATH}/bin/ec/components/mock
    libs = rdbPluginMock.q
```
