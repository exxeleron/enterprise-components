------------------------------------------------------------------------------------------------------------------------
0.1 DemoSystem package content

  DemoSystem is designed to show how to use Enterprise Components.

  It is distributed as ready to install and use bundle with the following folder structure:
  
    DemoSystem
    |-- bin
    |   |-- ec                                  
    |   |   |-- components                      
    |   |   |   |-- accessPoint
    |   |   |   |-- dist
    |   |   |   |-- eodMng
    |   |   |   |-- .....
    |   |   |-- libraries
    |   |   |   |-- cfgRdr
    |   |   |   `-- qsl
    |   |   `-- tutorial
    |   |       |-- Lesson01
    |   |       |   |-- readme_Lesson01.txt
    |   |       |   `-- etc
    |   |       |       |-- access.cfg
    |   |       |       |-- dataflow.cfg
    |   |       |       |-- env.sh
    |   |       |       `-- system.cfg
    |   |       |-- Lesson02
    |   |       |   |-- readme_Lesson02.txt
    |   |       |   `-- etc
    |   |       |       |-- access.cfg
    |   |       |       |-- dataflow.cfg
    |   |       |       |-- env.sh
    |   |       |       `-- system.cfg
    |   |       |-- LessonXX
    |   |       |-- readme.txt
    |   |       `-- troubleshooting.txt 
    |   |-- q
    |   `-- yak
    |-- readme.txt
    `-- troubleshooting.txt
  
  The main parts contain:
  - enterprise components package (including DemoSystem configuration)
  - yak process manager 32bit linux binary
  - q 32bit linux binary
 
0.1.1 Tutorial organization - Lessons

  The tutorial is divided into several Lessons of increasing complexity.

  Each Lesson is:
  - demonstrating one aspect of system design
  - incremental, containing all features and comments from the previous Lesson
  - described in a dedicated readme file - readme_LessonXX.txt
  - defined via its own configuration directory in the package:
      bin/ec/tutorial/LessonXX/etc/
 
0.1.2 Currently available Lessons:

  Lesson01 - Initial DemoSystem with one table (trade) and three components (data generator (gen), data distributor
            (tickHF) and realtime database (rdb)
 
  Lesson02 - Adding new table using template
 
  Lesson03 - Adding historical database component (hdb) and data historization configuration
  
  LessonNN - coming soon
  
0.2 Notes on readme files

0.2.1 During package preparation readme.txt (along with troubleshooting.txt) is copied from

  DemoSystem/bin/ec/tutorial/ to DemoSystem/
  
  so that files are visible to users from the main directory (DemoSystem)
    
0.2.2 Numbering used in all readme files denotes file in which it has been used:

  -  0.X.X - this readme.txt file
  -  1.X.X - readme_Lesson01.txt file
  -  2.X.X - readme_Lesson02.txt file
  - NN.X.X - readme_LessonNN.txt file
    
  For example:
  - point 0.5.1 (Stop the system) is located in readme.txt file
  - point 1.3.8 (Check content of trade table) is located in readme_Lesson01.txt
  - point 3.3.1 (Manually trigger artificial eod) is located in readme_Lesson03.txt
  
0.2.3 Conventions used in readme files

  - execute 'pwd' system command from DemoSystem directory:
    
      DemoSystem> pwd
    
  - execute q command '-100#trade' against 'core.rdb' process on designated port number (for example using kdb+ studio):
    
      core.rdb) -100#trade
      
      Hint:
        To determine port number for a process, see system.cfg for each Lesson (tutorial/LessonXX/etc/system.cfg) or,
        when system is running, execute following yak command:
          
        DemoSystem> yak info \*
    
  - any output resulting from running a command is indented, for example:
      
      DemoSystem> ls -l
        bin
        etc -> bin/ec/tutorial/Lesson01/etc
        readme.txt
        troubleshooting.txt
        
------------------------------------------------------------------------------------------------------------------------
0.3 DemoSystem prerequisites

0.3.1 Linux operating system

0.3.2 32bit compatibilities libraries in case of 64bit operating system, for example:
  - lib32z1 on Ubuntu
  - zlib.i686 on Fedora
  
  Note:
  - Our test runs on 'fresh' installation of openSuse 12.3 worked without the need for any additional packages
  
0.3.3 Kdb+ studio
  
  Instructions in Lessons relay on checking data or status of q processes, therefore, IDE for kdb+ is required 
  (e.g. http://code.kx.com/wiki/StudioForKdb+). Connection might need to be established from localhost (e.g. when 
  both kdb+ studio and Enterprise Components are deployed locally) or over TCP (e.g. Enterprise Components on 
  workstation, kdb+ studio on user’s desktop).
  
0.3.4 Q
  
  DemoSystem has self-contained free 32 bit Linux v3.1 of q provided by Kx Systems. However, if needed:
  - most current version of q can be always downloaded from http://kx.com/software-download.php
  - q included in DemoSystem can be replaced by full (paid) version of 64 bit Linux, in this case QHOME and PATH 
    environmental variables have to be adjusted accordingly in env.sh for each Lesson

  Please note that we strongly advise to test DemoSystem first before making any changes.

------------------------------------------------------------------------------------------------------------------------
0.4 DemoSystem installation

0.4.1 Download and unpack package ec_DemoSystem_l32_vX.XX.tgz

  > tar zxvf ec_DemoSystem_l32_vX.XX.tgz

0.4.2 Create link to configuration for LessonXX

  > cd DemoSystem
  DemoSystem> ln -s bin/ec/tutorial/LessonXX/etc
  
0.4.3 Check if etc folder is linked to correct Lesson

  DemoSystem> ls -l etc
    etc -> bin/ec/tutorial/LessonXX/etc
  
0.4.4 After the installation DemoSystem directory should contain bin directory and etc link

  DemoSystem> ls -l
    bin
    etc -> bin/ec/tutorial/LessonXX/etc/
    readme.txt
    troubleshooting.txt

------------------------------------------------------------------------------------------------------------------------
0.5 DemoSystem system startup

0.5.1 Source environment

  DemoSystem> source etc/env.sh

0.5.2 Start all components in the system (restart command is used just in case the system was already running)

  DemoSystem> yak restart \*
    Stopping components...
      core.gen                      	OK
      core.tick                     	OK
      core.rdb                      	OK
    Starting components...
      core.gen                      	OK
      core.tick                     	OK
      core.rdb                      	OK

0.5.3 Check if all components are running

  DemoSystem> yak info \*
    uid                pid   port  status      started             stopped            
    ----------------------------------------------------------------------------------
    core.gen           11235 17009 RUNNING     2014.05.08 07:36:18                    
    core.rdb           11247 17011 RUNNING     2014.05.08 07:36:19                    
    core.tick          11241 17010 RUNNING     2014.05.08 07:36:18                    

0.5.4 Check if data and log directories were created

  DemoSystem> ls -l
    bin
    data
    etc -> bin/ec/tutorial/LessonXX/etc/
    log
    readme.txt
    troubleshooting.txt

------------------------------------------------------------------------------------------------------------------------
0.6 Changing DemoSystem Lesson

  Folder structure for data and log directories remains the same for all Lessons, therefore it is enough to change 
  configuration pointer (symbolic link) to change the Lesson.
  
  If you would like to start with fresh set of data and log directories - these can be removed while the system is 
  stopped.
  
  Note:
  - Make sure that system is really stopped before deleting these directories, otherwise yak will lose its connection
    details resulting in error described in 'Issue 4' (troubleshooting.txt).

0.6.1 Stop the system

  DemoSystem> yak stop \*
    Stopping components...
      core.gen                      	OK
      core.tick                     	OK
      core.rdb                      	OK
  
0.6.2 Remove link to configuration for LessonXX

  DemoSystem> ls -l etc
    etc -> bin/ec/tutorial/LessonXX/etc/
  DemoSystem> rm etc

0.6.3 Create link to configuration for LessonYY

  DemoSystem> ln -s bin/ec/tutorial/LessonYY/etc
  DemoSystem> ls -l etc
    etc -> bin/ec/tutorial/LessonYY/etc/

0.6.4 Start the system again

  DemoSystem> yak start \*
    Starting components...
      core.gen                      	OK
      core.tick                     	OK
      core.rdb                      	OK

------------------------------------------------------------------------------------------------------------------------


