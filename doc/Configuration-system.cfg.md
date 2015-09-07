Managing system structure (system.cfg)

There are a few easy steps that need to be taken when adding a new component (based on an existing
component definition; in the example below `accessPoint` schema is used) to the existing Enterprise
Components’ infrastructure.

Configuration for the new component should be included in system configuration files.

1. Add new process definition in `system.cfg` configuration file:
    
    ```cfg
    [group:core]
       [[kdb.newComponent]]
       type=q:accessPoint/accessPoint
       port = ${basePort} +5
       command = "q accessPoint.q"
    ```
1. New sources need to be deployed in a bin directory (See (Deployment
   structure)[../Deployment-structure] for more details):

    ```bash
    bin/ec/components/accessPoint
        accessPoint.q
        accessPoint.qsd
    ```
    
3. Start new process:
    
    ```bash
    $ yak start kdb.newComponent
    ```
