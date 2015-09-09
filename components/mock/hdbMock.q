//hdb mock
//----------------------------------------------------------------------------//
system"l ",getenv[`EC_QSL_PATH],"/sl.q";
.sl.init[`hdbMock];
.sl.lib["cfgRdr/cfgRdr"];
.sl.lib["mock"];
.cr.loadCfg[`THIS];
//----------------------------------------------------------------------------//
.hdb.cfg.hdbPath:.cr.getCfgField[`THIS;`group;`cfg.hdbPath];

system "cd ", 1_string .hdb.cfg.hdbPath;

.mock.func[`.hdb.fillMissingTabs; 0; ".Q.chk[`:.]"];
.mock.func[`.hdb.reload; 0; "system\"l .\""];

//----------------------------------------------------------------------------//

