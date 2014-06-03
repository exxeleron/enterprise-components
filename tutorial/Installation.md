[:arrow_backward:](README.md) | [:arrow_forward:](Lesson01)
<!------------- https://github.com/exxeleron/enterprise-components/tree/master/tutorial/Installation.md --------------->

#                                           **Demo System Installation**

<!--------------------------------------------------------------------------------------------------------------------->
## `DemoSystem` prerequisites

<!--------------------------------------------------------------------------------------------------------------------->
### Operating system
At the moment `DemoSystem` can only be run on Linux operating system.

<!--------------------------------------------------------------------------------------------------------------------->
### Compatibility libraries
In case of 64 bit operating system 32 bit compatibility libraries might need to be installed. For example:
- `lib32z1` on Ubuntu
- `zlib.i686` on Fedora
  
> :white_check_mark: Note:
  
> Our test runs on 'fresh' installation of openSuse 12.3 worked without need for any additional packages

<!--------------------------------------------------------------------------------------------------------------------->
### Kdb+ studio
Instructions in Lessons relay on checking data or status of KDB+ processes, therefore, IDE for kdb+ is required 
(e.g. http://code.kx.com/wiki/StudioForKdb+). Connection might need to be established from `localhost` 
(e.g. when both kdb+ studio and Enterprise Components are deployed locally) or over `TCP` 
(e.g. Enterprise Components on workstation, kdb+ studio on user’s desktop).

<!--------------------------------------------------------------------------------------------------------------------->
### KDB+
`DemoSystem` has self-contained free 32 bit KDB+ v3.1 provided by Kx Systems. However, if needed:
- most current version of KDB+ can be always downloaded from http://kx.com/software-download.php
- KDB+ included in `DemoSystem` can be replaced by full (paid) version of 64 bit KDB+, in this case `QHOME` and `PATH`
  environmental variables have to be adjusted accordingly in `env.sh` file for each Lesson

> :heavy_exclamation_mark: Note:
  
> Please note that we strongly advise to test `DemoSystem` first before making any changes.

<!--------------------------------------------------------------------------------------------------------------------->
## `DemoSystem` installation

1. [Download](https://github.com/exxeleron/enterprise-components/releases) and unpack 
   package ec_vX.X.X_DemoSystem_Linux32bit_Lessons_X-X.tgz
  
    ```bash
    > tar zxvf ec_vX.X.X_DemoSystem_Linux32bit_Lessons_X-X.tgz
    ```
    
1. Create link to configuration for LessonXX
  
    ```bash
    > cd DemoSystem
    DemoSystem> ln -s bin/ec/tutorial/LessonXX/etc
    ```
  
1. Check if `etc` folder is linked to correct Lesson

    ```bash
    DemoSystem> ls -l etc
      etc -> bin/ec/tutorial/LessonXX/etc
    ```
  
1. After installation `DemoSystem` directory should contain `bin` directory and `etc` symbolic link

    ```bash
    DemoSystem> ls -l
      bin
      etc -> bin/ec/tutorial/LessonXX/etc/
      readme.txt
      troubleshooting.txt
    ```

<!--------------------------------------------------------------------------------------------------------------------->
### Troubleshooting
Common installation problems with solutions for [linux](Troubleshooting_linux.md).


<!--------------------------------------------------------------------------------------------------------------------->
## `DemoSystem` startup

1. Source environment

    ```bash
    DemoSystem> source etc/env.sh
    ```
    
1. Start all components in the system (restart command is used just in case the system was already running)

    ```bash
    DemoSystem> yak restart \*
      Stopping components...
        core.gen                      	Skipped
        core.tick                     	Skipped
        core.rdb                      	Skipped
      Starting components...
        core.gen                      	OK
        core.tick                     	OK
        core.rdb                      	OK
    ```
    
1. Check if all components are running

    ```bash
    DemoSystem> yak info \*
      uid                pid   port  status      started             stopped            
      ----------------------------------------------------------------------------------
      core.gen           11235 17009 RUNNING     2014.05.08 07:36:18                    
      core.rdb           11247 17011 RUNNING     2014.05.08 07:36:19                    
      core.tick          11241 17010 RUNNING     2014.05.08 07:36:18                    
    ```
    
1. Check if `data` and `log` directories were created

    ```bash
    DemoSystem> ls -l
      bin
      data
      etc -> bin/ec/tutorial/LessonXX/etc/
      log
      readme.txt
      troubleshooting.txt
    ```
    
    
<!--------------------------------------------------------------------------------------------------------------------->

## Changing `DemoSystem` Lesson

Folder structure for `data` and `lo`g directories remains the same for all Lessons, therefore it is enough to change 
configuration pointer (symbolic link) to change the Lesson.

If you would like to start with fresh set of `data` and `log` directories - these can be removed while the system is 
stopped.

> :heavy_exclamation_mark: Note:

> Make sure that system is really stopped before deleting these directories, otherwise yak will lose its connection details resulting in error described in [Issue 4](../tutorial/Troubleshooting_linux.md#issue-4---startup-failed-address-already-in-use).

1. Stop the system

    ```bash
    DemoSystem> yak stop \*
      Stopping components...
        core.gen                      	OK
        core.tick                     	OK
        core.rdb                      	OK
    ```
        
1. Remove link to configuration for LessonXX

    ```bash
    DemoSystem> ls -l etc
      etc -> bin/ec/tutorial/LessonXX/etc/
    DemoSystem> rm etc
    ```
    
1. Create link to configuration for LessonYY

    ```bash
    DemoSystem> ln -s bin/ec/tutorial/LessonYY/etc
    DemoSystem> ls -l etc
      etc -> bin/ec/tutorial/LessonYY/etc/
    ```
    
1. Start the system again

    ```bash
    DemoSystem> yak start \*
      Starting components...
        core.gen                      	OK
        core.tick                     	OK
        core.rdb                      	OK
    ```

<!--------------------------------------------------------------------------------------------------------------------->
[:arrow_backward:](README.md) | [:arrow_forward:](Lesson01)
