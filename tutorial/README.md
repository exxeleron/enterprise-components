[:arrow_forward:](Installation.md)

<!----------------------- https://github.com/exxeleron/enterprise-components/tree/master/tutorial/ -------------------->

#                                                   **Tutorial**

<!--------------------------------------------------------------------------------------------------------------------->

Welcome to the Enterprise Components' Tutorial.

To better understand how Enterprise Components work, we've prepared a DemoSystem and a number of Lessons of 
increasing complexity which will guide you through the ins and outs of our components. 
More details can be found in the [doc](../doc) folder and in the source code 
for each of the [components](../components) and [libraries](../libraries).

Going through the Lessons doesn't require any q knowledge. That said, to fully understand 
Enterprise Components (especially at higher level of complexity) we assume at least 
basic know-how of q and kdb+ concepts. For more details about q please see 
[Q For Mortals](http://code.kx.com/wiki/JB:QforMortals2/contents).

You are welcome to join our [user group](https://groups.google.com/d/forum/exxeleron) for questions, 
discussions and updates. Just click on the Lesson you would like to begin from and follow the instructions. 

Good luck!

<!--------------------------------------------------------------------------------------------------------------------->
## Tutorial content

- DemoSystem
 - [Installation](Installation.md)
 - Troubleshooting ([Linux](Troubleshooting_linux.md))
- Lessons
 - [Lesson 1](Lesson01) - basic system
 - [Lesson 2](Lesson02) - adding `quote` table
 - [Lesson 3](Lesson03) - storing data in `hdb`
 - [Lesson 4](Lesson04) - user queries
 
## DemoSystem
`DemoSystem` for Linux can be downloaded from 
[here](https://github.com/exxeleron/enterprise-components/releases).

<!--------------------------------------------------------------------------------------------------------------------->
### Package content

`DemoSystem` is distributed as ready to install and use bundle containing:

- `ec` - Enterprise Components package containing q conponents, libraries and DemoSystem configuration (tutorial)
- `yak` process manager 32bit binary
- `q` 32bit binary

The package folder structure is ready for direct usage:

```
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
    |   |       |   |-- README.md
    |   |       |   `-- etc
    |   |       |       |-- access.cfg
    |   |       |       |-- dataflow.cfg
    |   |       |       |-- env.sh
    |   |       |       `-- system.cfg
    |   |       |-- Lesson02
    |   |       |   |-- README.md
    |   |       |   `-- etc
    |   |       |       |-- access.cfg
    |   |       |       |-- dataflow.cfg
    |   |       |       |-- env.sh
    |   |       |       `-- system.cfg
    |   |       |-- LessonXX
    |   |       |-- README.md
    |   |       `-- troubleshooting.md
    |   |-- q
    |   `-- yak
    |-- README.md
    |-- Installation.md
    `-- Troubleshooting_linux.md
```

> Note 

> During package preparation `README.md` (along with `Installation.md` and `Troubleshooting_linux.md`) 
is copied from `DemoSystem/bin/ec/tutorial/` to `DemoSystem/` so that files are visible to users 
from the main directory (`DemoSystem`).


<!--------------------------------------------------------------------------------------------------------------------->
## Lessons

Lessons are based on `DemoSystem`. Each Lesson is:
- demonstrating one aspect of system design,
- incremental, containing all features and comments from the previous Lesson,
- described in a dedicated readme file (`bin/ec/tutorial/LessonXX/README.md`)
- defined via its own configuration directory in the package `bin/ec/tutorial/LessonXX/etc/`


<!--------------------------------------------------------------------------------------------------------------------->
### Conventions

1. Conventions used in readme files
    - execute `cd etc` system command from DemoSystem directory:

        ```bash
        DemoSystem> cd etc
        ```
    - execute q command `-100#trade` against `core.rdb` process on designated port number (for example using kdb+ studio):

        ```q
        q)/ execute on process core.rdb, port 17011
        q)-100#trade
        ```
        > Hint:
    
        > To determine port number for a process, see system.cfg for each Lesson (`tutorial/LessonXX/etc/system.cfg`) 
           or when system is running, execute following yak command:
  
        ```bash
        DemoSystem> yak info \*
        ```
    
    - any output resulting from running a command is indented, for example:

        ```bash
        DemoSystem> ls -l
          bin
          etc -> bin/ec/tutorial/Lesson01/etc
          readme.txt
          troubleshooting.txt
        ```

<!--------------------------------------------------------------------------------------------------------------------->
[:arrow_forward:](../wiki/Installation)

