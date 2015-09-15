# **cfgRdr library**
## Quick start
`cfgRdr` - Configuration reader library
Library is located in the `ec/libraries/cfgRdr`

### Functionality

 - loading of *.cfg configuration files based on *.qsd meta files (q schema definition)
 - loading system.cfg, dataflow.cfg, access.cfg into global configuration tree
 - exposing set of configuration accessors (i.e. `.cr.getCfgField[]`, `.cr.getCfgTab[]`, `.cr.getDataModel[]`)

### Simple usage examples

Following call retrieves single configuration `cfg.myField` field from `[group]` section for current component (`THIS`).
```q
q).cr.getCfgField[`THIS;`group;`cfg.myField]
```

Following call retrieves the data model for current component (`THIS`).
```q
q).cr.getDataModel[`THIS]
```

### Further reading
- articles [doc section](../../doc/).
 - [General configuration concept](../../doc/General-configuration-concept.md)
 - [Elements of the configuration file](../../doc/Elements-of-the-configuration-file.md)
 - [Understanding cfg and qsd files correlation](../../doc/Understanding-cfg-and-qsd-files-correlation.md)
 - [Configuration system.cfg](../../doc/Configuration-system-cfg.md)
 - [Configuraiton dataflow.cfg](../../doc/Configuraiton-dataflow.cfg.md)
 - [Configuration access.cfg](../../doc/Configuration-access.cfg.md)
 - [Configuration sync.cfg](../../doc/Configuration-sync.cfg.md)

