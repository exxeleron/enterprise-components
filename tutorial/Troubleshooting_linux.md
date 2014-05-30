<!-----------  https://github.com/exxeleron/enterprise-components/edit/master/tutorial/Troubleshooting_linux.md ------>

###                                           **Troubleshooting**

<!--------------------------------------------------------------------------------------------------------------------->
`Troubleshooting` document describes known problems and solutions encountered during installation of Enterprise 
Components on Linux operating system.

> Note:
  
> Please use our [google group](https://groups.google.com/d/forum/exxeleron) 
or open a [ticket](https://github.com/exxeleron/enterprise-components/issues) 
in case you enocounter any installation/startup problem which is not covered in this document.


<!--------------------------------------------------------------------------------------------------------------------->
#### Issue 1 - 32bit compatibility on some versions of 64-bit Ubuntu
```bash
> yak restart \*
bash: (...)/DemoSystem/bin/yak/yak: No such file or directory
```

##### Problem
This is related to Bug #852101 "32-bit applications do not start on 64".
 
##### Solution
A workaround is to reinstall `libc6-i386`:

```bash
DemoSystem> sudo apt-get install --reinstall libc6-i386
```
  
  
<!--------------------------------------------------------------------------------------------------------------------->
#### Issue 2 - 32bit compatibility on some versions of 64-bit Fedora
```bash
> yak restart \*
bash: (...)/DemoSystem/bin/yak/yak: /lib/ld-linux.so.2: bad ELF interpreter: No such file or directory
```

##### Problem
Most likely zlib.i686 is missing (please see DemoSystem Prerequisites 0.2.2) 
 
##### Solution
`zlib.i686` needs to be installed:

```bash
DemoSystem> sudo yum install zlib.i686
```


<!--------------------------------------------------------------------------------------------------------------------->
#### Issue 3 - yak: "Permission denied"
```bash
> yak
-bash: DemoSystem/bin/yak/yak: Permission denied
```

##### Problem
`yak` is missing execution permission

##### Solution
```bash
DemoSystem> chmod +x bin/yak/yak
```


<!--------------------------------------------------------------------------------------------------------------------->
#### Issue 4 - Startup failed: "Address already in use"
```bash
> yak start core.rdb
Starting components...
        core.rdb                        Failed: ComponentError: Component core.rdb finished prematurely with code 1
--------------------------------------------------------------------------------
stderr for component: core.rdb
# DemoSystem/log/core.rdb/core.rdb_2014.04.28T10.52.17.err
'2014.04.28T12:52:17.072 17011: Address already in use
--------------------------------------------------------------------------------
```

##### Problem
Port for `core.rdb` is already used by the os (17011 in this particular case)

##### Solution 1
Free required port in the os. Find the process name: 

```bash
> netstat -anp tcp | grep 17011
  tcp        0      0 0.0.0.0:17009           0.0.0.0:*               LISTEN      3261/q        
```

Kill process 3261

```bash
> kill 3261 
```

##### Solution 2 
In file `etc/system.cfg` modify `basePort` field to another number
  
  
<!--------------------------------------------------------------------------------------------------------------------->
#### Issue 5 - Missing libz library
```bash
> yak err core.rdb
libz.so.1: cannot open shared object file: No such file or directory zlib
```

##### Problem
32 bit q requires 32 bit `zlib` installed 

##### Solution
Install 32 bit `zlib`, for example in Ubuntu

```bash
> apt-get install zlib1g
```

<!--------------------------------------------------------------------------------------------------------------------->
