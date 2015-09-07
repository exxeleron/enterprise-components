## **`dist` component**
`dist` - data distribution component
Component is located in the `ec/components/dist`.

### Functionality
- handling inserts, upserts, deletes and eod signals, where each of these actions has to be assigned to a table and sector combination 
- journal roll-outs:
  - journal can be rolled independently for every table/sector combination using `.dist.rollJrn[tab;sector;newDir]`
  - journal directory can be rolled independently
- there is no restriction regarding column naming

`dist` data is kept in the following directory structure
```
   [root] / [table] / [sector] / [tsDir] / [current journals]
```

### Configuration
Note: configure port and component name according to your conventions (core.dist)

#### system.cfg example
```cfg
  [[core.dist]]
    command = "q dist.q"
    type = q:dist/dist
    port = ${basePort} + 10
```

#### dataflow.cfg example
```cfg
[template:quote]
  [[core.dist]]
    sectors = SEC0, SEC1, SEC2, SEC3   # list of supported sectors
```

### Startup
start dist component
```bash
> yak start core.dist
```

### Simple usage example

`.dist.status` contains table with status information for each table under `dist` control:

```q
q).dist.status
```

### Further reading

- [`tickHF` component](../tickHF)
- [`tickLF` component](../tickLF)
