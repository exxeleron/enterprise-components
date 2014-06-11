###                                           **Troubleshooting**

<!--------------------------------------------------------------------------------------------------------------------->
`Troubleshooting` document describes known problems and solutions encountered during installation of Enterprise 
Components on Windows operating system.

> Note:
  
> Please use our [google group](https://groups.google.com/d/forum/exxeleron) 
or open a [ticket](https://github.com/exxeleron/enterprise-components/issues) 
in case you enocounter any installation/startup problem which is not covered in this document.

Enterprise Components support for Windows operating systems is experimental at this point and there are some 
functionalities that are known not to work. These include:

1. **hdbSync.q**. This is used for synchronizing data with mirror hosts performed as part of the *End of Day* 
procedure.
1. **hk.q**. This component cleans up  (deletes, compresses, etc.)  KDB system artifacts (such as old logs, journals etc.like journals, log files etc) not related to Hdb.
1. **Monitor component (`monitor.q`)**. This component provides monitoring and profiling of resource usage, process 
state and system events (initialization, subscription, journal replay etc).

