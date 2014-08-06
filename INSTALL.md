## Installation

The simplest and recommended method of installation is to download one of the released binaries from the project's [releases](https://github.com/exxeleron/enterprise-components/releases) page. The binaries there contain the needed dependencies (KDB+ and yak). The [tutorial](https://github.com/exxeleron/enterprise-components/tree/master/tutorial) of the project's repository (included in the release binaries) provides a number of predefined configuration files that allow to quickly set up basic types of systems.

Advanced users may wish to assemble the system by themselves, using directly the source hosted on GitHub. Besides [kdb+](http://kx.com/kdb-plus.php) the only dependency is [exxeleron/yak](https://github.com/exxeleron/yak/releases) - the process management tool that Enterprise Components use. 

> :heavy_exclamation_mark: Note:
  
> EC releases typically require specific yak releases. The versions of the yak releases that work with a given EC release are listed in the EC release notes.

We recommend system layout as in the tutorial's [README](https://github.com/exxeleron/enterprise-components/blob/master/tutorial/README.md) document. However one can define an arbitrary system layout by setting `QHOME`, `QLIC`, `YAK_PATH`, `YAK_OPTS`, `EC_QSL_PATH`, `EC_ETC_PATH` environment variables in `env.sh` file and `binPath`, `libPath`, `dllPath`, `dataPath`, `logPath` and `eventPath` variables in `system.cfg` configuration file.
