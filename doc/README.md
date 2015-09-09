# **ec general documentation**
To start with Enterprise Components, we recommend going through following materials:

#### Tutorial
- [Installation](../tutorial/Installation.md)
- Troubleshooting for [Linux](../tutorial/Troubleshooting_linux.md) and [Windows](../tutorial/Troubleshooting_windows.md)
- [Lesson 1](../tutorial/Lesson01) - basic system
- [Lesson 2](../tutorial/Lesson02) - adding `quote` table 
- [Lesson 3](../tutorial/Lesson03) - storing data in `hdb`
- [Lesson 4](../tutorial/Lesson04) - user queries
- [Lesson 5](../tutorial/Lesson05) - authorization and authentication

#### DemoSystem
The tutorial is based on the DemoSystem.
Most recent DemoSystem package can be downloaded from [releases section](https://github.com/exxeleron/enterprise-components/releases).
The package for the system deployment consists of fully prepared:
  - `bin` directory with all the components, libraries and yak binaries
  - `etc` directory with configuration for the system and `env.sh` (and `env.bat` for Windows) script with environmental settings

#### Ec elements
Components and libraries that are essential part of the ec:
- The [Components](../components) support the efficient construction of kdb+ infrastructure by providing the following functionality 
  - Data feeding
    - [feedCsv](../components/feedCsv) - Generic CSV files reader and publisher
  - Data distribution
    - [tickHF](../components/tickHF) - Publishing and distribution of High Frequency data
    - [tickLF](../components/tickLF) - Distribution of Low Frequency data
  - Data processing and storage
    - [rdb](../components/rdb) - In-memory database 
    - [hdb](../components/hdb) - Historical database
    - [eodMng](../components/eodMng) - End-of-day processing
    - [stream](../components/stream) - Stream-based data processing
  - Data access
    - [accessPoint](../components/accessPoint) - End users entry point
  - System maintenance
    - [yak](https://github.com/exxeleron/yak/) - Process Management Tool
    - [hk](../components/hk) - Housekeeping
  - Monitor server
    -[monitor](../components/monitor) - Server monitoring tool
  - Testing
    -[qtest](../components/qtest) - Test framework
    -[mock](../components/mock) - Set of mocks
- [Libraries] (../libraries)
  - [qsl](../libraries/qsl) Q standard library - set of common libraries used across the system
    - sl - Standard library - common `frame` for all ec q scripts
    - pe - Protected evaluation library - wrapper for invoking functions in protected evaluation
    - event - Event library - execution of q functions as events
    - callback - Callback library - managing callbacks
    - timer - Timer library - abstraction layer for timer
    - handle - Connection management library - abstraction layer for interprocess connections
    - authorization - Authorization library - access restrictions and auditing
    - u - u.q library - extension of [u.q from Kx](http://code.kx.com/wsvn/code/kx/kdb%2Btick/tick/u.q)
    - sub - Subscription management library - abstraction for realtime data subscription
    - store - Store library - data storage in the hdb
    - os - Os library - shell commands abstraction, covers Linux, MacOS and Windows
    - parseq - Parseq library - Parseq is a Q clone of the Haskell's Parsec, a parser combinator library. 
    - tabs - Data model validation - set of functions facilitating data model validation

#### Articles
Set of articles describing various aspects of ec usage:
- Configuration:
 - [General configuration concept](General-configuration-concept.md)
 - [Configuration system.cfg](Configuration-system.cfg.md)
 - [Configuration dataflow.cfg](Configuraiton-dataflow.cfg.md)
 - [Configuration access.cfg](Configuration-access.cfg.md)
 - [Configuration sync.cfg](Configuration-sync.cfg.md)
 - [Elements of the configuration file](Elements-of-the-configuration-file.md)
 - [Understanding cfg and qsd files correlation](Understanding-cfg-and-qsd-files-correlation.md)
- Misc:
 - [Security model description](Security-model-description.md)
 - [Logging concept](Logging-concept.md)
 - [Setup system in UTC or local time](Setup-system-in-UTC-or-local-time.md)
- Development:
 - [Exxeleron q coding conventions](Exxeleron-q-coding-conventions.md) - brief introduction to coding guidelines
 - [Documenting q code](Documenting-q-code.md)
 - [Document generation](Document-generation.md)
