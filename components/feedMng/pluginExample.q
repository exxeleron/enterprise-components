/L/ Copyright (c) 2011-2014 Exxeleron GmbH
/L/
/L/ Licensed under the Apache License, Version 2.0 (the "License");
/L/ you may not use this file except in compliance with the License.
/L/ You may obtain a copy of the License at
/L/
/L/   http://www.apache.org/licenses/LICENSE-2.0
/L/
/L/ Unless required by applicable law or agreed to in writing, software
/L/ distributed under the License is distributed on an "AS IS" BASIS,
/L/ WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
/L/ See the License for the specific language governing permissions and
/L/ limitations under the License.

/A/ DEVnet:  Joanna Jarmulska
/V/ 3.0

/S/ Plugin example for feedMng:
/S/ sysUniverse is derived from universe table
/S/ (start code)
/S/ universe:([] time:();sym();flag:();instrGroup:()) - data model
/S/ (end)
/S/ 1. - Define <.feedMng.plug.jrn[]> that creates initial state of the sysUniverse
/S/ (start code)
/S/ return table that should match sysUniverse:
/S/ .feedMng.plug.jrn:{select time, sym:.example.flagMapping[flag], instrumentGroup:instrGroup, instrument:sym, subItem:sym from universe}
/S/ (end)
/S/ 2. - Define plugins to update sysUniverse during real-time updates received from tickLF
/S/ (start code)
/S/ .feedMng.plug.img[`universe][data] - data image
/S/ .feedMng.plug.upd[`universe][data] - data inserts
/S/ .feedMng.plug.ups[`universe][(data;constraints;bys;aggregates)] - data upserts
/S/ .feedMng.plug.del[`universe][constraints;bys;aggregates)] - deletes
/S/ (end)

system"l ",getenv[`EC_QSL_PATH],"/sl.q";

.sl.init[`feedMngExample];

/G/ mapping flag to feed id
/E/ .example.flagMapping:(`instrClass1`instrClass2`instrClass3`instrClass4!`kdb.feedRtr`kdb.feedRtr`kdb.feedRtr2`kdb.feedRtr2);
.example.flagMapping:(`instrClass1`instrClass2`instrClass3`instrClass4!`kdb.feedRtr`kdb.feedRtr`kdb.feedRtr2`kdb.feedRtr2);

/F/ plugin for handling images
/E/ .feedMng.plug.img[`universe]:{[data]
/E/   new:select time, sym:.example.flagMapping[flag], instrumentGroup:instrGroup, instrument:sym, subItem:sym from data;
/E/   uni:.feedMng.compareUni[sysUniverse;new];
/E/   if[count  uni`del;.feedMng.del[`time xcols update time:.z.t from uni`del]];
/E/   if[count  uni`upd;.feedMng.upd[`time xcols update time:.z.t from uni`upd]];
/E/   };
.feedMng.plug.img[`universe]:{[data]
  new:select time, sym:.example.flagMapping[flag], instrumentGroup:instrGroup, instrument:sym, subItem:sym from data;
  uni:.feedMng.compareUni[sysUniverse;new];
  if[count  uni`del;.feedMng.del[`time xcols update time:.sl.zt[] from uni`del]];
  if[count  uni`upd;.feedMng.upd[`time xcols update time:.sl.zt[] from uni`upd]];
  };

/F/ plugin for handling updates   
/E/ .feedMng.plug.upd[`universe]:{[data]
/E/     new:select time, sym:.example.flagMapping[flag], instrumentGroup:instrGroup, instrument:sym, subItem:sym from data;
/E/   .feedMng.upd[new];
/E/   };

.feedMng.plug.upd[`universe]:{[data]
  new:select time, sym:.example.flagMapping[flag], instrumentGroup:instrGroup, instrument:sym, subItem:sym from data;
  .feedMng.upd[new];
  };

/F/ plugin for handling upserts
/E/ .feedMng.plug.ups[`universe]:{[x]
/E/   new:select time, sym:.example.flagMapping[flag], instrumentGroup:instrGroup, instrument:sym, subItem:sym from universe;
/E/   uni:.feedMng.compareUni[sysUniverse;new];
/E/   if[count  uni`del;.feedMng.del[`time xcols update time:.z.t from uni`del]];
/E/   if[count  uni`upd;.feedMng.upd[`time xcols update time:.z.t from uni`upd]];
/E/   };

.feedMng.plug.ups[`universe]:{[x]
  new:select time, sym:.example.flagMapping[flag], instrumentGroup:instrGroup, instrument:sym, subItem:sym from universe;
  uni:.feedMng.compareUni[sysUniverse;new];
  if[count  uni`del;.feedMng.del[`time xcols update time:.sl.zt[] from uni`del]];
  if[count  uni`upd;.feedMng.upd[`time xcols update time:.sl.zt[] from uni`upd]];
  };

/F/ plugin for handling deletes   
/E/ .feedMng.plug.del[`universe]:{[x]
/E/   c:x 0;b:x 1;a:x 2;
/E/   toDel:?[.feedMng.prev.universe;c;b;a];
/E/   toDel:select time, sym:.example.flagMapping[flag], instrumentGroup:instrGroup, instrument:sym, subItem:sym from toDel;
/E/   .feedMng.del[toDel];
/E/   };
.feedMng.plug.del[`universe]:{[x]
  c:x 0;b:x 1;a:x 2;
  toDel:?[.feedMng.prev.universe;c;b;a];
  toDel:select time, sym:.example.flagMapping[flag], instrumentGroup:instrGroup, instrument:sym, subItem:sym from toDel;
  .feedMng.del[toDel];
  };


/F/ recreate inintial state of the sysUniverse
/R/ return table that should match sysUniverse
/E/ .feedMng.plug.jrn:{[]
/E/   select time, sym:.example.flagMapping[flag], instrumentGroup:instrGroup, instrument:sym, subItem:sym from universe
/E/   };

.feedMng.plug.jrn:{[]
  select time, sym:.example.flagMapping[flag], instrumentGroup:instrGroup, instrument:sym, subItem:sym from universe
  };

