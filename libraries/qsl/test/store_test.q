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

// Usage:
//q test/store_test.q --noquit -p 9009

system"l lib/qspec/qspec.q";

.tst.desc["Notification functions tests"]{
  / .store.notifyStoreBegin:{.store.p.notifyFile["eodDuring";x];}
  / .store.notifyStoreSuccess:{.store.p.notifyFile["eodSuccess";x];}
  / .store.notifyStoreBefore
  before{
    system "l store.q";
    `.store.comFile mock `:test/eod/eodStatus;
    `fullComFile mock hsym `$string[.store.comFile],string .z.d;
    `.sl.eodSyncedDate mock {.z.d};
    };
  after{
    .tst.rm `:test/eod;
    };
  should["Begin store - .store.notifyStoreBegin[]"]{
    .store.notifyStoreBegin[.z.d];
    content: read0 fullComFile;
    1 musteq count content;
    first[content] mustlike "eodDuring*";
    };
  should["Before store - .store.notifyStoreBefore[]"]{
    .store.notifyStoreBefore[.z.d];
    content: read0 fullComFile;
    1 musteq count content;
    first[content] mustlike "eodBefore*";
    };
  should["Before store - .store.notifyStoreBefore[]"]{
    .store.notifyStoreSuccess[.z.d];
    content: read0 fullComFile;
    1 musteq count content;
    first[content] mustlike "eodSuccess*";
    };
  };
.tst.desc["Storing, splaying and clearing - internal functions"]{
  before{
    // populate dummy data
    `quote mock ([] a:til 20; sym:20?`3);
    `quotek mock ([sym:20?`3] a:til 20);
    `eodPath mock `:test/eod;
    `.store.tabs mock ([] table:`quote`quotek;hdbPath:eodPath;hdbName:`hdb;memoryClear:1b;store: 1b;attrCol:`sym);
    // hdb reloading mocks
    `.hnd.h mock ()!();
    .hnd.h[`hdb]:0;
    `.store.reloadHdb mock {[] system "l ",1_string eodPath};
    `cwd mock system["cd"];
    `.sl.eodSyncedDate mock {.z.d};
    };
  after{
    .tst.rm eodPath;
    system "cd ", cwd;
    };
  should["clear in memory table and set `g# attribute- .store.p.clear[]"]{
    .store.p.clear[`quote;`sym];
    0 musteq count quote;
    ``g mustmatch exec a from value meta quote;
    };
  should["splay a table to the eodPath - .store.p.splay[]"]{
    .store.p.splay[.z.d;`quote;eodPath;`sym];
    sv[`;eodPath,`sym] mustmatch key ` sv eodPath,`sym;
    asc[exec sym from quote] mustmatch asc get ` sv eodPath,`sym;
    (`$string[.z.d]) mustin key eodPath;
    `quote mustin key hp:` sv eodPath,`$string .z.d;
    cols[quote] mustin get key ` sv hp,`quote,`.d;
    };
  should["splay a keyed table to the eodPath - .store.p.splay[]"]{
    tablekeys:keys `quotek;
    .store.p.splay[.z.d;`quotek;eodPath;`sym];
    sv[`;eodPath,`sym] mustmatch key ` sv eodPath,`sym;
    asc[exec sym from quotek] mustmatch asc get ` sv eodPath,`sym;
    (`$string[.z.d]) mustin key eodPath;
    `quotek mustin key hp:` sv eodPath,`$string .z.d;
    cols[quotek] mustin get key ` sv hp,`quotek,`.d;
    tablekeys mustmatch .store.tmp.eodKeys;
    };
  should["store table with mem clear - .store.p.store[]"]{
    .store.p.store[.z.d;first .store.tabs];
    sv[`;eodPath,`sym] mustmatch key ` sv eodPath,`sym;
    asc[exec sym from quote] mustnmatch asc get ` sv eodPath,`sym;
    (`$string[.z.d]) mustin key eodPath;
    `quote mustin key hp:` sv eodPath,`$string .z.d;
    cols[quote] mustin get key ` sv hp,`quote,`.d;
    0 musteq count quote;
    };
  should["store table without mem clear - .store.p.store[]"]{
    update memoryClear:0b from `.store.tabs;
    .store.p.store[.z.d;first .store.tabs];
    sv[`;eodPath,`sym] mustmatch key ` sv eodPath,`sym;
    asc[exec sym from quote] mustmatch asc get ` sv eodPath,`sym;
    (`$string[.z.d]) mustin key eodPath;
    `quote mustin key hp:` sv eodPath,`$string .z.d;
    cols[quote] mustin get key ` sv hp,`quote,`.d;
    20 musteq count quote;
    };
  should["reload hdb after store - .store.reloadHdb[]"]{
    .store.p.store[.z.d;first .store.tabs];
    delete quote from `.;
    .store.reloadHdb[];
    `quote mustin .Q.pt;
    .z.d mustin date;
    20 musteq count quote;
    };
  };

.tst.desc["Storing of tables"]{
  before{
    `cwd mock system["cd"];
    `.store.comFile mock ` sv hsym[`$cwd],`test`eodStatus;
    `quote mock ([] a:til 20; sym:20?`3);
    `quotek mock ([sym:20?`3] a:til 20);
    `eodPath mock ` sv hsym[`$cwd],`test`eod;
    `dataPath mock hsym[`$cwd],`test;
    `config mock ([] table:`quote`quotek;hdbPath:2#eodPath;hdbName:`hdb`hdb;memoryClear:10b;store:11b);
    // hdb reloading mocks
    `.hnd.h mock ()!();
    .hnd.h[`hdb]:0;
    `.store.reloadHdb mock {[] system "l ",1_string eodPath};
    `.sl.eodSyncedDate mock {.z.d};
    };
  after{
    system "cd ", cwd;
    .tst.rm `$string[.store.comFile],string .z.d;
    .tst.rm `$string[.store.comFile],string .z.d+1;
    .tst.rm eodPath;
    };
  should["Init and store tables in hdb - .store.run[]"]{
    .store.init[config;1b;0b;dataPath];
    // initialization is already finished
    ("eodBefore ",string .z.d) mustlike first read0 `$string[.store.comFile],string .z.d;
    .store.run[.z.d];
    ("eodSuccess ",string .z.d) mustlike first read0 `$string[.store.comFile],string .z.d;
    ("eodBefore ",string .z.d+1) mustlike first read0 `$string[.store.comFile],string .z.d+1;
    `quote`quotek mustin .Q.pt;
    mustthrow["type";{exec from quote}];
    sv[`;eodPath,`sym] mustmatch key ` sv eodPath,`sym;
    (`$string[.z.d]) mustin key eodPath;
    `quote`quotek mustin key hp:` sv eodPath,`$string .z.d;
    cols[quote] mustin `date,get key ` sv hp,`quote,`.d;
    20 musteq count quote;
    20 musteq count quotek;
    };
  };
