// rdb mock plugin

system"l ",getenv[`EC_QSL_PATH],"/sl.q";
.sl.init[`rdbPlugMock];
.sl.lib["mock"];

.mock.func[".rdb.plug.beforeEod[`beforeEod]"; 1; ""];
.mock.func[".rdb.plug.afterEod[`afterEod]"; 1; ""];
