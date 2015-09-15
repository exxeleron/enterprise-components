Working with data models (dataflow.cfg)

## Adding new tables

When there is a need to extend an existing setup, tables have to be added in `dataflow.cfg`
file. Example definition for `trade` table is described below:

```
+------------------------------------------+----------------------------------------------+
| Configuration                            | Description                                  |
+------------------------------------------+----------------------------------------------+
| [table:trade]                            | Table name                                   |
|------------------------------------------|----------------------------------------------|
|  model = time(TIME), sym(SYMBOL),        | Model definition;                            |
|          price(FLOAT), size(LONG)        | list of column – type pairs                  |
|------------------------------------------|----------------------------------------------|
| [[core.feedCsv]]                         | Table data entry point. This section         |
|   dirSrc = ${EC_SYS_PATH}/data/feedCsv   | specifies process reading data from CSV files|
|   pattern = *trade*                      | with file format from modeland field         |
|   separator = ;                          | separator. Data read this way is then send to|
|                                          | core.tickHF process for distribution (below) |
|------------------------------------------|----------------------------------------------|
| [[core.tickHF]]                          | Table data distribution to subscribers       |
|------------------------------------------|----------------------------------------------|
| [[core.rdb]]                             |                                              |
|   subSrc = core.tickHF                   | Table subscriber definition (with additional |
|   eodClear = 1b                          | component-specific configurations)           |
|   eodPerform = 1b                        |                                              |
|   hdbConn = core.hdb                     |                                              |
|------------------------------------------|----------------------------------------------|
| [[core.mrvs]]                            | Another table subscriber definition          |
|   serverSrc = core.tickHF                |                                              |
+------------------------------------------+----------------------------------------------+
```

### High frequency tables

High frequency data should be distributed using `tickHF` component. This is specified by inserting a
subsection `[[core.tickHF]]` in proper `[table:*]` sections. Please see Adding new tables above.

### Reference data

CSV files are parsed by the `feedCsv` component. Location of the CSV files, proper formats and
destination tables have to be defined in `dataflow.cfg` file.

> **Note:**
> 
> Because `tickHF` and `tickLF` components use different protocols, it is important to run `feedCsv`
> with `tickLFPublisher` protocol enabled if there is a need to publish data to `tickLF`.

### Rdb

Both high frequency and reference data can be captured in `rdb`. In this case please add
subscription to the new table in `dataflow.cfg` file and ensure that end-of-day settings are
correct.

### Hdb

New table will be added to the `hdb` after first end-of-day; all existing days will be filled
automatically.

## Data model changes

Various processes can be affected by data model changes. It is important to identify all influenced
areas before changing table schema.

Data model changes take place in `dataflow.cfg` file. In order to conform to new data model, the
following changes need to be applied:

```
+-------------+--------------------------------------------------------+------------------+
| Component   | Changes required                                       | Config. location |
+-------------+--------------------------------------------------------+------------------+
| feedCsv     | - Add subsection in the dataflow file (if needed)      | dataflow.cfg     |
|             | - Check if enrichment/validation plugins for           |                  |
|             |   appropriate tables are adapted to the new data model |                  |
|-------------|--------------------------------------------------------|------------------|
| tickHF      | - Update journal file to new data model. Please be     |                  |
|             |   aware that journal file written by tickHF contains   |                  |
|             |   update information for all the tables it handles     |                  |
|             | - Alternatively, archive current journal file (move    |                  |
|             |   it to another location or rename). In this case data |                  |
|             |   will be lost.                                        |                  |
|-------------|--------------------------------------------------------|                  |
| tickLF      | - Update journal file to new data model                |                  |
|             | - Alternatively, archive current journal file (move it |                  |
|             |   to another location or rename). In this case data    | No configuration |
|             |   will be lost                                         | changes required |
|             | - Check if enrichment/validation plugins for           |                  |
|             |   appropriate tables are adapted to the new data model |                  |
|-------------|--------------------------------------------------------|                  |
| rdb         | - Review all end-of-day plugins that are using         |                  |
|             |   affected tables                                      |                  |
|-------------|--------------------------------------------------------|                  |
| hdb         | - Run scripts that are adapting hdb data to new        |                  |
|             |   data model                                           |                  |
|-------------|--------------------------------------------------------|                  |
| accessPoint | - Review all user functions that are using             |                  |
|             |   affected tables                                      |                  |
|-------------|--------------------------------------------------------|------------------|
| stream      | - Add subsection in the data flow file (if needed)     |                  |
|             | - Check if enrichment/validation plugins for           |                  |
|             |   appropriate tables are adapted to the new data model |                  |
+-------------+--------------------------------------------------------+------------------+
```

Before applying new changes q processes need to be stopped. Once this is done, please apply your
changes, restart the system and start the integration tests (if any):

```bash
$ yak restart core
```

