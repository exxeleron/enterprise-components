system"l ",getenv[`EC_QSL_PATH],"/sl.q";
.sl.init[`proc];
.sl.lib["cfgRdr/cfgRdr"];

.sl.main:{
  .log.info[`proc] "starting process";
  };

/F/ Function that can be run, used as port open callbacks
.tst.hnd.Fun1: {[s] .tst.hnd.Fun1Run+:1;};
.tst.hnd.Fun2: {[s] .tst.hnd.Fun2Run+:1;};

/G/ functions run counters
.tst.hnd.Fun1Run:0;
.tst.hnd.Fun2Run:0;

.sl.run[`cell; `.sl.main;`];
