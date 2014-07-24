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
When the pattern specified in the pattern column of the housekeeping table does not match any files the `forfiles` command used to find files on Windows returns an error. In such case the error message from the comand is redirected to a file with extension `.finderr` in the log directory for the hk component. Also, a message is logged on the WARN level.
This does not affect the functionality of the component.
3. [**Monitor**](../components/monitor) component - checking of disk usage and free disk space is currently 
   not working on Windows. (this functionality is originally based on `du` and `df`)
   The rest of the `monitor`'s functionality is working on Windows.
4. The reconnect feature of the [**handle**](../libraries/qsl/handle.q) library may cause a process to be not responsive (busy and not accepting connections) when there are more than two processes to which the process is trying to reconnect.  

<!--------------------------------------------------------------------------------------------------------------------->
#### Issue 1 - insufficient privileges to run mklink
```bash
stderr for component: admin.genPass
# C:\DemoSystem\log\admin.genPass\admin.genPass_2014.07.18T12.35.16.err
You do not have sufficient privilege to perform this operation.
'2014.07.18T14:35:16.349 os
@
.,["\\"]
"mklink \"C:\\DemoSystem\\log\\admin.genPass\\init.log\" admin.genPass.2014.07.18T12.35.16.log"
```

##### Problem
mklink on Windows 7 requires more priviliges
 
##### Solution1
Run 'cmd' as administrator - right clicking and choosing 'run as admin'

##### Solution2
Another workaround is described here:
http://superuser.com/questions/124679/how-do-i-create-a-link-in-windows-7-home-premium-as-a-regular-user


  
