## **`tickLF` component**
`tickLF` - tick Low Frequency component, designed for handling reference data
Component is located in the `ec/components/tickLF`.

### Functionality
- handling inserts, overwrites and deletes
- data validating
- supporting journal switching when data image is received (<.tickLF.pubImg> is called) or at the end-of-day
- enabling data enrichment and validation trough custom plugins
- data manipulating at the end-of-day trough <.tickLF.plug.eod> plugin
- protecting data publishing - in case of connection failure or handle corruption to one of subscribers, 
  data publishing is not affected to the others; publishing failure will be logged as an error in the log file
- protecting against loops between publisher-subscriber in case if publisher is also subscribed to the same table; 
  data published by tickLF interface by such process won't be send back to the producer; producer should handle updates that are sent through tickLF on its side

> Note:
> `sym` (type:SYMBOL) column is mandatory in the data model for `tickLF` tables

### Configuration
Note: configure port and component name according to your conventions (core.tickLF)

#### system.cfg example
```cfg
  [[core.tickLF]]
    command = "q tickLF.q"
    type = q:tickLF/tickLF
    port = ${basePort} + 10
```

#### dataflow.cfg example
```cfg
[template:quote]
  [[core.tickLF]]
    jrnSwitch = img,eod
    eodImg2Jrn = TRUE
    memory = TRUE
```

### Startup
start tickLF component
```bash
> yak start core.tickLF
```

### Simple usage example
`.tickLF.status[]` returns table with status information for each table under `tickLF` control:

```q
q).tickLF.status[]
```

#### Plugins:
List of plugins to setup:
- custom data validation, return: signal in case of validation failure
```q
.tickLF.plug.validate[table name:SYMBOL;data as nested list:LIST GENERAL]
```
- data enriching parameters, return: LIST GENERAL
```q
.tickLF.plug.enrich[table name:SYMBOL;data as nested list:LIST GENERAL]
```
- end-of-day plugin
```q
.tickLF.plug.eod[table name:SYMBOL;table name:SYMBOL]
```
Interface for receiving data from tickLF is described in [qsl/sub](../../libraries/qsl/sub.q)

### Further reading

- [`tickHF` component](../tickHF)
- [`dist` component](../dist)
