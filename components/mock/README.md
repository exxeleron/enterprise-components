## **`mock` component**
`mock/gen` - Mock Data-stream Generator
Component is located in the `ec/components/mock`.

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

### Startup
start gen component
```bash
> yak start core.gen
```

### Further reading

- [Lesson 1 - basic system](../../tutorial/Lesson01)
