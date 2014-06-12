###                                           **Troubleshooting**

<!--------------------------------------------------------------------------------------------------------------------->
`Troubleshooting` document describes known problems and solutions encountered during installation of Enterprise 
Components on Windows operating system.

> Note:
  
> Please use our [google group](https://groups.google.com/d/forum/exxeleron) 
or open a [ticket](https://github.com/exxeleron/enterprise-components/issues) 
in case you encounter any installation/startup problem which is not covered in this document.

Enterprise Components support for Windows operating systems is experimental at this point and there are some 
functionalities that are known not to work. These include:

1. [**eodMng/hdbSync**](../components/eodMng/hdbSync.q) component (hdb synchronization) is currently not working on Windows 
   (core functionality is originally based on `rsync`).
2. [**hk**](../components/hk) component (housekeeping) is currently not working on Windows 
   (core functionality is originally based on `find`).
3. [**Monitor**](../components/monitor) component - checking of disk usage and free disk space is currently 
   not working on Windows. (this functionality is originally based on `du` and `df`)
   The rest of the `monitor`'s functionality is working on Windows.
   

