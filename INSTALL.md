## Installation

The simplest and recommended method of installation is to download one of the released binaries from the project's 
[releases](https://github.com/exxeleron/enterprise-components/releases) page. 

The [tutorial](/tutorial) of the project's repository (included in the 
release binaries) provides a number of predefined configuration files that allow to quickly set up basic types of systems.

Advanced users may wish to assemble the system by themselves, using directly the source hosted on `GitHub`. 
Besides [`kdb+`](http://kx.com/kdb-plus.php) the only dependency is [`yak`](https://github.com/exxeleron/yak/releases) - the process 
management tool that `enterprise-components` use. 

> :heavy_exclamation_mark: Note:
  
> `enterprise-components` releases typically require specific `yak` releases. The versions of the `yak` releases that work with a given 
`enterprise-components` release are listed in the `ec` release notes.

We recommend system layout as in the tutorial's [README](tutorial/README.md) 
document. However, one can define an arbitrary system layout by setting `QHOME`, `QLIC`, `YAK_PATH`, `YAK_OPTS`, `EC_QSL_PATH`, 
`EC_ETC_PATH` environment variables in `env.sh` file and `binPath`, `libPath`, `dllPath`, `dataPath`, `logPath` and `eventPath` variables 
in `system.cfg` configuration file.

For more details please visit [Demo System Installation](tutorial/Installation.md).
