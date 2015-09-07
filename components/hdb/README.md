## **`hdb` component**
`hdb` - historical database component - loading native kdb+ hdb directory.
Component is located in the `ec/components/hdb`.

### Configuration
Note: configure port and component name according to your conventions (core.hdb)

#### system.cfg example
```cfg
  [[core.hdb]]
    command = "q hdb.q"
    type = q:hdb/hdb
    port = ${basePort} + 12
```

#### dataflow.cfg example
```cfg
[template:quote]
  [[core.hdb]]
```

### Startup
start hdb
```bash
> yak start core.hdb
```

### Simple usage example

`.hdb.status[]` returns status of all hdb tables:

```q
q).hdb.status[]
```

### Further reading

- [Lesson 3 - storing data in `hdb`](../../tutorial/Lesson03)
