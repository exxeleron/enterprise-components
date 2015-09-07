## **`feedCsv` component**
`feedCsv` - Feed Csv component - parsing csv files into q tables
Component is located in the `ec/components/feedCsv`.

### Functionality
- providing fully customizable and configurable CSV file parser
- enabling automatic detection of CSV input files in specified locations, matching predefined pattern of the file names
- shielding system from corrupted data sets
- publishing parsed files to the TickerPlant in tickLF [tickLF](../tickLF) or [tickHF](../tickHF) protocol
- archiving processed files (optionally)
- parsing pending files - helpful when destination server is inactive and parsed files are marked as pending; 
  in this case reconnecting procedure will try to establish new connection - after it's done pending files will be automatically processed
> Note:
>  Depending on which component is triggered (`.tickLF.pubUpd` or `.tickLF.pubImg`), each file name should be preceded by either `*upd*` or `*img*` respectively. 
  For example: `YYYY.DD.MM.*upd*.table.csv`, `YYYY.DD.MM.*img*.table.csv`.

### Configuration
Note: configure port and component name according to your conventions (core.feedCsv)

#### system.cfg example
FeedCsv library doesn't contain any default protocol to publish parsed files, therefore feedCsv component should be started using following modes

- mode compatible with `tickLF` protocol
```cfg
  [[core.feedCsv]]
    command = "q feedCsv.q"
    libs = tickLFPublisher
    type = q:feedCsv/feedCsv
    port = ${basePort} + 19
```

- mode compatible with `tickHF` protocol
```cfg
  [[core.feedCsv]]
    command = "q feedCsv.q"
    libs = tickHFPublisher
    type = q:feedCsv/feedCsv
    port = ${basePort} + 19
```

- mode compatible with `tickHF` protocol and with *plugins*
```cfg
  [[core.feedCsv]]
    command = "q feedCsv.q"
    libs = tickHFPublisher, plugins/feedCsvPlugin
    type = q:feedCsv/feedCsv
    port = ${basePort} + 19
```

#### dataflow.cfg example
```cfg
[table:universe]
  [[core.feedCsv]]
    dirSrc =  ${dataPath}/universe  
    pattern = *universe*  
    separator = ;  
    fileModel = time(TIME), tmp(STRING)
```

### Startup
start feedCsv component
```bash
> yak start core.feedCsv
```

### Simple usage example

#### Plugins
Defining custom plugins:
Signature for plugin for data enrichment, returns TABLE
```q
.fcsv.plug.enrich[table(SYMBOL)][data(TABLE);fileName(SYMBOL)]
```
Example
```q
.fcsv.plug.enrich[`universe]:{[data;file] update time:file from data}
```

Signature for plugin for data validation, returns signal in case of failed validation
```q
.fcsv.plug.validate[tableName(SYMBOL)][data(TABLE);fileName(SYMBOL)]
```
Example
```q
.fcsv.plug.validate[`universe]:{[data;file] if[not meta[data]~meta universe;'failed]}
```

### Further reading

- [tickHF](../tickHF)
- [tickLF](../tickLF)
