## **`authentication` component**
`authentication` - Authentication component - system passwords management.
Component is located in the `ec/components/authentication`.

### Functionality
`authentication` consists of two sub-components:
- genPass
  - interactive tool for generation of encrypted password

- refreshUFiles
  - refresh of the permission files - regeneration of user access files (used with -u/-U options)
  - this script generates one file for each component with permitted users information taken from access.cfg file.
  - files are generated in cfg.userTxtPath specified directory.
  
### Configuration
Note: configure port and component name according to your conventions (core.monitor, core.hdb)

#### system.cfg example
```cfg
[group:admin]
  [[admin.genPass]]         # component 'admin.genPass' (EC_COMPONENT_ID) used for
                            # interactive password generation
    uOpt = NULL             # uOpt and uFile cannot be set on this component. Redefining
    uFile = NULL            # those values here.
    port = 0                # port field has no default value. In order to run process
                            # without port, set it to zero
    type = b:authentication/authentication
    command = "q genPass.q"

  [[admin.refreshUFiles]]   # component 'admin.refreshUFiles' (EC_COMPONENT_ID) refreshing
                            # user files
    uOpt = NULL
    uFile = NULL
    port = 0
    type = b:authentication/authentication
    command = "q refreshUFiles.q"
```

### Usage
In order to generate a new obfuscated password for a user, please run admin.genPass interactive service from yak
```bash
> yak console core.genPass
Please enter new password: USERINPUT
Please re-enter new password: USERINPUT
Your new password is: 0x6160e6574666
```

This new password (`0x6160e6574666`) should be  placed in access.cfg file.

### Further reading

- [Lesson 5 - authorization and authentication](../../tutorial/Lesson05)
- [Security model description](../../doc/Security-model-description.md)
- [access.cfg configuration](../../doc/Configuration-access.cfg.md)
- [qsl/authorization library](../../libraries/qsl/authorization.q)
