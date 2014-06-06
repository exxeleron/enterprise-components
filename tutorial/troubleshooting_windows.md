###                                           **Troubleshooting**

<!--------------------------------------------------------------------------------------------------------------------->
`Troubleshooting` document describes known problems and solutions encountered during installation of Enterprise 
Components on Windows operating system.

> Note:
  
> Please use our [google group](https://groups.google.com/d/forum/exxeleron) 
or open a [ticket](https://github.com/exxeleron/enterprise-components/issues) 
in case you enocounter any installation/startup problem which is not covered in this document.

Enterprise Components support for Windows operating systems is experimental at this point and there are some functionalities that are known not to work. These include:

1. **End of day management component (`eodMng.q`)**. This is used to manage `hdb` housekeeping tasks (like deletion, compression 
and conflation of tables) and synchronizing data with mirror hosts performed as part of the *End of Day* procedure.
1. **Housekeeping component (`hk.q`)**. This is a component for tasks similar to the ones above but for files not related directly to `hdb`, like journals, log files etc.
1. **Monitor component (`monitor.q`)**. This component provides monitoring and profiling of resource usage, process state and 
system events (initialization, subscription, journal replay etc).
1. **`streamWdb` plugin for the stream component (`streamWdb.q`)** - a low-memory alternative for the `rdb` component. 
1. On Linux the *`sl.q`* library creates soft links (called `init.log` and `current.log`) to the first and the last log file the 
current run of the process has created. This is not done on Windows.


