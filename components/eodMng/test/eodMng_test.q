// q test/eodMng_test.q --noquit -p 5001

\l lib/qsl/sl.q
.sl.init[`eodMng_test];
\l lib/qspec/qspec.q

\c 1000 10000

.tst.desc["test initialization"]{
  before{
    
    .sl.noinit:1b;
    @[system;"l eodMng.q";0N];
    .sl.relib[`$"qsl/handle"];
    `.eodmng.checkServer mock {[x] :`running};
    .eodmng.status:(flip (enlist `host)!enlist `eodMng1`eodMng2)!flip `state`syncDate`timeStamp`db`current`cold`lastSyncHost!(2#`unknown;2#0nd;2#0Np;`:/data/core.hdb`:sampleHost:/data/core_hdb;10b;00b;2#`none);
    `.eodmng.rdbName mock `rdbNamePlaceholder;
    `.eodmng.date mock .z.d;
    `.eodmng.rdbFile mock `noFile;
    `.eodmng.state mock `idle;
    };

  after{
    };

  should["checkStatus test: rdb running"]{
    `.eodmng.checkServer mock {[x] :`running};
    .eodmng.p.checkStatus[];
    
    };
  should["checkStatus test: rdb stopped"]{
    `.eodmng.checkServer mock {[x] :`stopped};
    .eodmng.p.checkStatus[];
    .eodmng.state mustmatch `error;
    };
  should["checkStatus test: rdb error"]{
    `.eodmng.checkServer mock {[x] :`error};
    .eodmng.p.checkStatus[];
    .eodmng.state mustmatch `error;
    };
  should["checkStatus test: rdb undefined"]{
    `.eodmng.checkServer mock {[x] :`running};
    .eodmng.p.checkStatus[];
    .eodmng.state mustmatch `error;
    };
  should["checkStatus test: rdb recovery"]{
    `.eodmng.checkServer mock {[x] :`recovery};
    .eodmng.p.checkStatus[];
    .eodmng.state mustmatch `recovery;
    };
  should["checkStatus test: unknown"]{
    `.eodmng.checkServer mock {[x] :`running};
    };
  should["checkStatus test: unknown, eodBefore"]{
    `.eodmng.state mock `unknown; // state should be in `unknown`idle`eod_during
    `.eodmng.checkServer mock {[x] :`running};
    `.eodmng.p.checkFileStatus mock {[file] :(enlist "eodBefore";.z.d)};
    .eodmng.p.checkStatus[];
    .eodmng.state mustmatch `idle;
    };
  should["checkStatus test: nerror, eodBefore"]{
    `.eodmng.state mock `error; 
    `.eodmng.checkServer mock {[x] :`running};
    `.eodmng.p.checkFileStatus mock {[file] :(enlist "eodBefore";.z.d)};
    .eodmng.p.checkStatus[];
    .eodmng.state mustmatch `error;
    };

  should["checkStatus test: eod_during "]{
    `.eodmng.state mock `idle;
    `.eodmng.checkServer mock {[x] :`running};
    `.eodmng.p.checkFileStatus mock {[file] :(enlist "eodDuring";.z.d)};
    .eodmng.p.checkStatus[];
    .eodmng.state mustmatch `eod_during;
    };
  should["checkStatus test: eod success, noHk"]{
    `.eodmng.cfg.hkProcessName mock "";
    `.eodmng.state mock `idle;
    `.eodmng.checkServer mock {[x] :`running};
    `.eodmng.p.checkFileStatus mock {[file] :(enlist "eodSuccess";.z.d)};
    .eodmng.p.checkStatus[];
    .eodmng.state mustmatch `sync_before;
    };
  should["checkStatus test: eod success, Hk"]{
    `.eodmng.cfg.hkProcessName mock "placeHolder";
    `.eodmng.p.runHkScript mock {[a;b] };
    `.eodmng.state mock `idle;
    `.eodmng.checkServer mock {[x] :`running};
    `.eodmng.p.checkFileStatus mock {[file] :(enlist "eodSuccess";.z.d)};
    .eodmng.p.checkStatus[];
    .eodmng.state mustmatch `housekeeping;
    };

  should["checkStatus test: eod fail"]{
    `.eodmng.state mock `eod_during;
    `.eodmng.checkServer mock {[x] :`running};
    `.eodmng.p.checkFileStatus mock {[file] :(enlist "eodFail";.z.d)};
    .eodmng.p.checkStatus[];
    .eodmng.state mustmatch `error;
    };

  should["processSyncBefore -> 2 machines; master"]{
    `.eodmng.p.hArgs mock `$();
    `.eodmng.p.syncWithCold mock {};
    .eodmng.p.processSyncBefore[`];
    .eodmng.state mustmatch `sync_with_cold;
    };

  should["processSyncBefore -> 2 machines; slave success"]{
    `.eodmng.p.hArgs mock enlist `eodMng1;
    `.eodmng.state mock `sync_before;
    `.eodmng.date mock .z.d;
    `.eodmng.p.getHArgs mock {[]  enlist `eodMng1};
    update state:`idle, syncDate:.z.d+1, current:0b from `.eodmng.status where host in .eodmng.p.hArgs;
    update current:1b from `.eodmng.status where host=`eodMng2;
    `.eodmng.date mock .z.d;
    .eodmng.p.processSyncBefore[`];
    .eodmng.state mustmatch `sync_during;
    };


  should["processSyncBefore -> 2 machines; slave fail1"]{
    `.eodmng.p.hArgs mock enlist `eodMng1;
    `.eodmng.state mock `sync_before;
    `.eodmng.date mock .z.d;
    `.eodmng.p.getHArgs mock {[]  enlist `eodMng1};
    update state:`idle, syncDate:.z.d-1, current:0b from `.eodmng.status where host in .eodmng.p.hArgs;
    update current:1b from `.eodmng.status where host=`eodMng2;
    `.eodmng.date mock .z.d;
    .eodmng.p.processSyncBefore[`];
    .eodmng.state mustmatch `sync_with_cold;
    };

  should["processSyncBefore -> 2 machines; slave fail2"]{
    `.eodmng.p.hArgs mock enlist `eodMng1;
    `.eodmng.state mock `sync_before;
    `.eodmng.date mock .z.d;
    `.eodmng.p.getHArgs mock {[]  enlist `eodMng1};
    update state:`error, syncDate:.z.d, current:0b from `.eodmng.status where host in .eodmng.p.hArgs;
    update current:1b from `.eodmng.status where host=`eodMng2;
    `.eodmng.date mock .z.d;
    .eodmng.p.processSyncBefore[`];
    .eodmng.state mustmatch `sync_with_cold;
    };


  should["processSyncBefore -> 2 machines reverse order; slave"]{
    `.cr.loadSyncCfg mock {};
    `.cr.getSyncCfgField mock {[x;y;z] :`eodMng2`eodMng1};
    update current:not current from `.eodmng.status;
    `.eodmng.p.syncWithCold mock {};
    .eodmng.p.processSyncBefore[`];
    .eodmng.state mustmatch `sync_with_cold;
    };

  should["processSyncBefore -> 2 machines reverse order; master success"]{
    `.cr.loadSyncCfg mock {:(::)};
    `.cr.getSyncCfgField mock {[x;y;z] :`eodMng2`eodMng1};
    `.eodmng.state mock `sync_before;
    `.eodmng.date mock .z.d;
    `.eodmng.p.getHArgs mock {[]  .eodmng.p.hArgs};
    update state:`idle, syncDate:.z.d+1  from `.eodmng.status where host=`eodMng2;
    .eodmng.p.processSyncBefore[`];
    .eodmng.state mustmatch `sync_during;
    };

  should["processSyncBefore -> 2 machines reverse order; master fail"]{
    `.cr.loadSyncCfg mock {:(::)};
    `.cr.getSyncCfgField mock {[x;y;z] :`eodMng2`eodMng1};
    `.eodmng.state mock `sync_before;
    `.eodmng.date mock .z.d;
    `.eodmng.p.getHArgs mock {[]  .eodmng.p.hArgs};
    update state:`error, syncDate:.z.d+1  from `.eodmng.status where host=`eodMng2;
    .eodmng.p.processSyncBefore[`];
    .eodmng.state mustmatch `sync_with_cold;
    };

  should["processHousekeeping -> running"]{
    `.eodmng.hkStatusFile mock `placeholder;
    `.eodmng.cfg.hkProcessName mock `placeholder;
    `.eodmng.state mock `housekeeping;
    `.eodmng.p.checkProcessStatus mock {[x;y] `running};
    .eodmng.p.processHousekeeping[`];
    .eodmng.state mustmatch `housekeeping;
    };

  should["processHousekeeping -> success"]{
    `.eodmng.hkStatusFile mock `placeholder;
    `.eodmng.cfg.hkProcessName mock `placeholder;
    `.eodmng.state mock `housekeeping;
    `.eodmng.p.checkProcessStatus mock {[x;y] `success};
    .eodmng.p.processHousekeeping[`];
    .eodmng.state mustmatch `sync_before;

    };
  should["processHousekeeping -> failure"]{
    `.eodmng.hkStatusFile mock `placeholder;
    `.eodmng.cfg.hkProcessName mock "placeholder";
    `.eodmng.state mock `housekeeping;
    `.eodmng.p.checkProcessStatus mock {[x;y] `failure};
    `.eodmng.date mock .z.d;
    .eodmng.p.processHousekeeping[`];
    .eodmng.state mustmatch `recovery;
    .eodmng.date mustmatch .z.d+1;
    };

  should["processSyncDuring -> running"]{
    `.eodmng.syncStatusFile mock "placeholder";
    `.eodmng.cfg.syncProcessName mock "placeholder";
    `.eodmng.state mock `sync_during;
    `.eodmng.p.checkProcessStatus mock {[x;y] `running};
    .eodmng.p.processSyncDuring[`];
    .eodmng.state mustmatch `sync_during;
    };

  should["processSyncDuring -> success"]{
    `.eodmng.syncStatusFile mock "placeholder";
    `.eodmng.cfg.syncProcessName mock "placeholder";
    `.eodmng.state mock `sync_during;
    `.eodmng.p.checkProcessStatus mock {[x;y] `success};
	  `.eodmng.eodSuccHnd mock 0;
    `.eodmng.date mock .z.d;
    .eodmng.p.processSyncDuring[`];
    .eodmng.state mustmatch `idle;
    .eodmng.date mustmatch .z.d+1;
    };

  should["processSyncDuring -> failure"]{
    `.eodmng.syncStatusFile mock "placeholder";
    `.eodmng.cfg.syncProcessName mock "placeholder";
    `.eodmng.state mock `sync_during;
    `.eodmng.p.checkProcessStatus mock {[x;y] `failure};
    `.eodmng.date mock .z.d;
    .eodmng.p.processSyncDuring[`];
    .eodmng.state mustmatch `error;
    .eodmng.date mustmatch .z.d+1;
    };

  };


