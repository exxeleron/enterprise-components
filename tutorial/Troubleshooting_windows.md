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
2. [**hk**](../components/hk) component (housekeeping): The compress functionality requires the [zip](http://www.info-zip.org/) application to be installed and available on PATH.
The OS prints an error message on the console when the pattern specified in the pattern column of the housekeeping table does not match any files. 
This does not affect the functionality of the component.
3. [**Monitor**](../components/monitor) component - checking of disk usage and free disk space is currently 
   not working on Windows. (this functionality is originally based on `du` and `df`)
   The rest of the `monitor`'s functionality is working on Windows.
4. The reconnect feature of the [**handle**](../libraries/qsl/handle.q) library may cause a process to be not responsive (busy and not accepting connections) when there are more than two processes to which the process is trying to reconnect.  

