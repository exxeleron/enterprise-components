// q test/cfgRdr_test.q --noquit -p 5001

\l lib/qspec/qspec.q
\l lib/qsl/sl.q
.sl.init[`test];

//----------------------------------------------------------------------------//
.tst.loadLib:{[lib]
    .sl.noinit:1b;
    .sl.libpath:`:.,.sl.libpath;
    @[system;"l ",string lib;{-1 "ERROR while loading library: ",x}];
    };

.tst.parseResult:{[parser;txt]
   res:parser .par.initP txt;
   :$[not null res`errp;res`errs;res`ast];
   };

//----------------------------------------------------------------------------//
.tst.desc["top level - parsing elements"]{
    before{
        `EC_QSL_PATH setenv "../qsl/";
        .tst.loadLib[`cfgRdr.q];
        };
    after{
        };
    should["trim whitespaces"]{
          (0N;"") mustmatch .cr.p.trim " \n\t";
          (2;enlist "a") mustmatch .cr.p.trim " \na\t";
          (2;"a a") mustmatch .cr.p.trim " \na a\t";
          (0;"a a") mustmatch .cr.p.trim "a a\t";
          (1;"a a") mustmatch .cr.p.trim "\ta a";
        };
    should["parse sections"]{
          (0;enlist"aa") mustmatch .cr.p.parse[`section]"[aa]";
          (1;enlist"aa") mustmatch .cr.p.parse[`section]"[ aa ]";
          (1;("aa";"bb")) mustmatch .cr.p.parse[`section]"[ aa:bb ]";
          (1;("aa";"")) mustmatch .cr.p.parse[`section]"[ aa: ]";
          (1;("";"bb")) mustmatch .cr.p.parse[`section]"[ :bb ]";
        };
    should["parse subsections"]{
          (0;enlist"aa") mustmatch .cr.p.parse[`subsection]"[[aa]]";
          (1;enlist"aa") mustmatch .cr.p.parse[`subsection]"[[ aa ]]";
          (1;("aa";"bb")) mustmatch .cr.p.parse[`subsection]"[[ aa:bb ]]";
          (1;("aa";"")) mustmatch .cr.p.parse[`subsection]"[[ aa: ]]";
          (1;("";"bb")) mustmatch .cr.p.parse[`subsection]"[[ :bb ]]";
        };
    should["parse fields"]{
          (2;(enlist"a";enlist"1")) mustmatch .cr.p.parse[`field]"a=1";
          (2;(enlist"a";"123")) mustmatch .cr.p.parse[`field]"a=123";
          (3;(enlist"a";"123")) mustmatch .cr.p.parse[`field]" a=123 ";
          (5;(enlist"a";"123")) mustmatch .cr.p.parse[`field]" a = 123 ";
          (5;(enlist"a";"123=xx")) mustmatch .cr.p.parse[`field]" a = 123=xx ";
          (7;("a-b";"123=xx")) mustmatch .cr.p.parse[`field]" a-b = 123=xx ";
        };
    should["recongize lines (already trimmed lines)"]{
          `section mustmatch .cr.p.recognize"[a]";
          `section mustmatch .cr.p.recognize"[a321ew d]";
          `subsection mustmatch .cr.p.recognize"[[a321ewd]]";
          `malformed mustmatch .cr.p.recognize"[[a321ewd]";
          `malformed mustmatch .cr.p.recognize"[[a321ewd";
          `malformed mustmatch .cr.p.recognize"[a321ewd";
          `malformed mustmatch .cr.p.recognize"a321ewd";
          `field mustmatch .cr.p.recognize"a321ewd = 23";
          `field mustmatch .cr.p.recognize"[a321ewd = 23";
          `field mustmatch .cr.p.recognize"[[a321ewd = 23";
          `subsection mustmatch .cr.p.recognize"[[a321ewd = 23]]";
        };
    };

//----------------------------------------------------------------------------//
.tst.desc["top level - parsing structure"]{
    before{
        `EC_QSL_PATH setenv "../qsl/";
        .tst.loadLib[`cfgRdr.q];
        `file mock `:test/top_level/top_level_parsing.cfg;
        `top mock .cr.parseCfgFile[file;0b];
        };
    after{
        };
    should["exclude comments"]{
        raw:read0 file;
        noc:.cr.p.excludeComment each raw;
        til[7] mustmatch where not noc ~' raw; // first seven lines contains comments
        noc[0] mustmatch "";
        noc[1] mustmatch "";
        noc[2] mustmatch "a = 11 ";
        noc[3] mustmatch "b = word12 ";
        noc[4] mustmatch "C = ";
        noc[5] mustmatch "DD = ";
        noc[6] mustmatch enlist "d";
        };
    should["parse config without errors"]{
       top[`vars][`varName] mustmatch `a`b`C`DD`d_e`F_F;
       8 mustmatch count top[`errors];
       };
    };

//----------------------------------------------------------------------------//
.tst.desc["values parsing"]{
   before{
     `EC_QSL_PATH setenv "../qsl/";
     .tst.loadLib[`cfgRdr.q];
     };
   should["parse BOOLEAN"]{
     .tst.parseResult[.cr.atomic.nullParsers[`BOOLEAN;1b];enlist "0"] mustmatch 0b;
     .tst.parseResult[.cr.atomic.nullParsers[`BOOLEAN;1b];enlist "1"] mustmatch 1b;
     .tst.parseResult[.cr.atomic.nullParsers[`BOOLEAN;1b];"TRUE"] mustmatch 1b;
     .tst.parseResult[.cr.atomic.nullParsers[`BOOLEAN;1b];"FALSE"] mustmatch 0b;
     (type .tst.parseResult[.cr.atomic.nullParsers[`BOOLEAN;1b];"122a"]) mustmatch 0h;
     (type .tst.parseResult[.cr.atomic.nullParsers[`BOOLEAN;1b];"j11"]) mustmatch 0h;
     (type .tst.parseResult[.cr.atomic.nullParsers[`BOOLEAN;1b];""]) mustmatch 0h;

     .tst.parseResult[.cr.atomic.nullParsers[`$"LIST BOOLEAN";1b];"FALSE,TRUE,TRUE,FALSE"] mustmatch 0110b;
     .tst.parseResult[.cr.atomic.nullParsers[`$"LIST BOOLEAN";1b];"0,1,1,0"] mustmatch 0110b;
     .tst.parseResult[.cr.atomic.nullParsers[`$"LIST BOOLEAN";1b];"FALSE,TRUE,TRUE,FALSE,0,1,1,0"] mustmatch 01100110b;

     };

   should["parse INT"]{
     .tst.parseResult[.cr.atomic.nullParsers[`INT;1b];"0Ni"] mustmatch 0Ni;
     .tst.parseResult[.cr.atomic.nullParsers[`INT;1b];"22"] mustmatch 22i;
     .tst.parseResult[.cr.atomic.nullParsers[`INT;1b];enlist "2"] mustmatch 2i;
     (type .tst.parseResult[.cr.atomic.nullParsers[`INT;1b];"22a"]) mustmatch 0h;
     (type .tst.parseResult[.cr.atomic.nullParsers[`INT;1b];"j11"]) mustmatch 0h;
     (type .tst.parseResult[.cr.atomic.nullParsers[`INT;1b];""]) mustmatch 0h;

     .tst.parseResult[.cr.atomic.nullParsers[`$"LIST INT";1b];"22,13,17,42"] mustmatch (22i;13i;17i;42i);
     .tst.parseResult[.cr.atomic.nullParsers[`$"LIST INT";1b];"22  ,  13, 17,42"] mustmatch (22i;13i;17i;42i);
     };

   should["parse LONG"]{
     .tst.parseResult[.cr.atomic.nullParsers[`LONG;1b];"0N"] mustmatch 0Nj;
     .tst.parseResult[.cr.atomic.nullParsers[`LONG;1b];"22"] mustmatch 22j;
     .tst.parseResult[.cr.atomic.nullParsers[`LONG;1b];enlist "2"] mustmatch 2j;
     (type .tst.parseResult[.cr.atomic.nullParsers[`LONG;1b];"22a"]) mustmatch 0h;
     (type .tst.parseResult[.cr.atomic.nullParsers[`LONG;1b];"j11"]) mustmatch 0h;
     (type .tst.parseResult[.cr.atomic.nullParsers[`LONG;1b];""]) mustmatch 0h;

     .tst.parseResult[.cr.atomic.nullParsers[`$"LIST LONG";1b];"22,13,17,42"] mustmatch (22j;13j;17j;42j);
     .tst.parseResult[.cr.atomic.nullParsers[`$"LIST LONG";1b];"22  ,  13, 17,42"] mustmatch (22j;13j;17j;42j);
     };

   should["parse FLOAT"]{
     .tst.parseResult[.cr.atomic.nullParsers[`FLOAT;1b];"0n"] mustmatch 0n;
     .tst.parseResult[.cr.atomic.nullParsers[`FLOAT;1b];enlist "2"] mustmatch 2.0;
     .tst.parseResult[.cr.atomic.nullParsers[`FLOAT;1b];"22"] mustmatch 22.0;
     .tst.parseResult[.cr.atomic.nullParsers[`FLOAT;1b];"22.7"] mustmatch 22.7;
     .tst.parseResult[.cr.atomic.nullParsers[`FLOAT;1b];"2.34"] mustmatch 2.34;
     (type .tst.parseResult[.cr.atomic.nullParsers[`FLOAT;1b];"22a"]) mustmatch 0h;
     (type .tst.parseResult[.cr.atomic.nullParsers[`FLOAT;1b];"j11"]) mustmatch 0h;
     (type .tst.parseResult[.cr.atomic.nullParsers[`FLOAT;1b];""]) mustmatch 0h;

     .tst.parseResult[.cr.atomic.nullParsers[`$"LIST FLOAT";1b];"22,13.5,17.72,42"] mustmatch (22.0;13.5;17.72;42.0);
     .tst.parseResult[.cr.atomic.nullParsers[`$"LIST FLOAT";1b];"22  ,  13.5, 17.72,42"] mustmatch (22.0;13.5;17.72;42.0);
     };

	 should["parse REAL"]{
     .tst.parseResult[.cr.atomic.nullParsers[`REAL;1b];"0Ne"] mustmatch 0ne;
     .tst.parseResult[.cr.atomic.nullParsers[`REAL;1b];enlist "2"] mustmatch 2.0e;
     .tst.parseResult[.cr.atomic.nullParsers[`REAL;1b];"22"] mustmatch 22.0e;
     .tst.parseResult[.cr.atomic.nullParsers[`REAL;1b];"22.7e"] mustmatch 22.7e;
     .tst.parseResult[.cr.atomic.nullParsers[`REAL;1b];"2.34"] mustmatch 2.34e;
     (type .tst.parseResult[.cr.atomic.nullParsers[`REAL;1b];"22a"]) mustmatch 0h;
     (type .tst.parseResult[.cr.atomic.nullParsers[`REAL;1b];"j11"]) mustmatch 0h;
     (type .tst.parseResult[.cr.atomic.nullParsers[`REAL;1b];""]) mustmatch 0h;

     .tst.parseResult[.cr.atomic.nullParsers[`$"LIST REAL";1b];"22,13.5,17.72,42"] mustmatch (22.0e;13.5e;17.72e;42.0e);
     .tst.parseResult[.cr.atomic.nullParsers[`$"LIST REAL";1b];"22  ,  13.5, 17.72,42"] mustmatch (22.0e;13.5e;17.72e;42.0e);
     };

	 
   should["parse STRING"]{
     .tst.parseResult[.cr.atomic.nullParsers[`STRING;1b];"sample_test"] mustmatch "sample_test";
     .tst.parseResult[.cr.atomic.nullParsers[`STRING;1b];"test2"] mustmatch "test2";
     .tst.parseResult[.cr.atomic.nullParsers[`STRING;1b];enlist "t"] mustmatch enlist "t";
     .tst.parseResult[.cr.atomic.nullParsers[`STRING;1b];"escaped_char_like_\\(_works"] mustmatch "escaped_char_like_(_works";
     .tst.parseResult[.cr.atomic.nullParsers[`STRING;1b];"\"spaces in quoted strings\""] mustmatch "\"spaces in quoted strings\"";
     ( .tst.parseResult[.cr.atomic.nullParsers[`STRING;1b];""]) mustmatch "";
     ( type .tst.parseResult[.cr.atomic.nullParsers[`STRING;1b];"single_escaped_characters_like_?_not_allowed"]) mustmatch 0h;


     .tst.parseResult[.cr.atomic.nullParsers[`$"LIST STRING";1b];"one,two,three"] mustmatch ("one";"two";"three");
     .tst.parseResult[.cr.atomic.nullParsers[`$"LIST STRING";1b];"one,two,three,\"four five\""] mustmatch ("one";"two";"three";"\"four five\"");

     };

   should["parse SYMBOL"]{
     .tst.parseResult[.cr.atomic.nullParsers[`SYMBOL;1b];"sample_test"] mustmatch `$"sample_test";
     .tst.parseResult[.cr.atomic.nullParsers[`SYMBOL;1b];"test2"] mustmatch `$"test2";
     .tst.parseResult[.cr.atomic.nullParsers[`SYMBOL;1b];enlist "t"] mustmatch `$enlist "t";
     .tst.parseResult[.cr.atomic.nullParsers[`SYMBOL;1b];"escaped_char_like_\\(_works"] mustmatch `$"escaped_char_like_(_works";
     .tst.parseResult[.cr.atomic.nullParsers[`SYMBOL;1b];"\"spaces in quoted strings\""] mustmatch `$"\"spaces in quoted strings\"";
     ( .tst.parseResult[.cr.atomic.nullParsers[`SYMBOL;1b];""]) mustmatch `;
     ( type .tst.parseResult[.cr.atomic.nullParsers[`SYMBOL;1b];"single_escaped_characters_like_?_not_allowed"]) mustmatch 0h;

     .tst.parseResult[.cr.atomic.nullParsers[`$"LIST SYMBOL";1b];"one,two,three"] mustmatch (`one`two`three);
     .tst.parseResult[.cr.atomic.nullParsers[`$"LIST SYMBOL";1b];"one,two,three,\"four five\""] mustmatch (`one`two`three,`$"\"four five\"");
     };


   should["parse DATE"]{
     .tst.parseResult[.cr.atomic.nullParsers[`DATE;1b];"2013.06.07"] mustmatch 2013.06.07;
     .tst.parseResult[.cr.atomic.nullParsers[`DATE;1b];"2012.12.13"] mustmatch 2012.12.13;
     .tst.parseResult[.cr.atomic.nullParsers[`DATE;1b];"2011.02.12"] mustmatch 2011.02.12;
     ( type .tst.parseResult[.cr.atomic.nullParsers[`DATE;1b];"2013.jan.12"]) mustmatch 0h;
     ( type .tst.parseResult[.cr.atomic.nullParsers[`DATE;1b];"non valid date"]) mustmatch 0h;

     .tst.parseResult[.cr.atomic.nullParsers[`$"LIST DATE";1b];"2013.06.06,   2012.12.13 ,2011.02.12"] mustmatch 2013.06.06 2012.12.13 2011.02.12;
     };

   should["parse TIME"]{
     .tst.parseResult[.cr.atomic.nullParsers[`TIME;1b];"19:00:00"] mustmatch 19:00:00.000;
     .tst.parseResult[.cr.atomic.nullParsers[`TIME;1b];"23:21:22"] mustmatch 23:21:22.0000;
     .tst.parseResult[.cr.atomic.nullParsers[`TIME;1b];"05:06:07.123"] mustmatch 05:06:07.123;
     ( type .tst.parseResult[.cr.atomic.nullParsers[`TIME;1b];"05:ij:12"]) mustmatch 0h;
     ( type .tst.parseResult[.cr.atomic.nullParsers[`TIME;1b];"non valid time"]) mustmatch 0h;

     .tst.parseResult[.cr.atomic.nullParsers[`$"LIST TIME";1b];"19:00:00,   23:21:22  , 05:06:07.123"] mustmatch (19:00:00.000;23:21:22.000;05:06:07.123);
     };

   should["parse DATETIME"]{
     .tst.parseResult[.cr.atomic.nullParsers[`DATETIME;1b];"2013.06.07D19:00:00"] mustmatch `datetime$2013.06.07D19:00:00.000;
     .tst.parseResult[.cr.atomic.nullParsers[`DATETIME;1b];"2013.12.13D23:21:22"] mustmatch `datetime$2013.12.13D23:21:22.000;
     .tst.parseResult[.cr.atomic.nullParsers[`DATETIME;1b];"2011.02.12D05:06:07.123"] mustmatch `datetime$2011.02.12D05:06:07.123;
     ( type .tst.parseResult[.cr.atomic.nullParsers[`DATETIME;1b];"05:ij:12"]) mustmatch 0h;
     ( type .tst.parseResult[.cr.atomic.nullParsers[`DATETIME;1b];"non valid date"]) mustmatch 0h;

     .tst.parseResult[.cr.atomic.nullParsers[`$"LIST DATETIME";1b];"2013.06.07D19:00:00,   2013.12.13D23:21:22 ,2011.02.12D05:06:07.123"] mustmatch (`datetime$2013.06.07D19:00:00.000;`datetime$2013.12.13D23:21:22.000;`datetime$2011.02.12D05:06:07.123);

     };

   should["parse GUID"]{
     .tst.parseResult[.cr.atomic.nullParsers[`GUID;1b];"845d4a11-3082-ecd7-afe8-8c5971b439f4"] mustmatch "G"$"845d4a11-3082-ecd7-afe8-8c5971b439f4";
     .tst.parseResult[.cr.atomic.nullParsers[`GUID;1b];"3889e46d-0f63-48dc-6034-851735b9d0f1"] mustmatch "G"$"3889e46d-0f63-48dc-6034-851735b9d0f1";
     ( type .tst.parseResult[.cr.atomic.nullParsers[`GUID;1b];"388946d-0f63-48dc-6034-85135b9d0f1"]) mustmatch 0h;
     ( type .tst.parseResult[.cr.atomic.nullParsers[`GUID;1b];"3889GG6d-0f63-48dc-6034-851735b9d0f1"]) mustmatch 0h;
     
     .tst.parseResult[.cr.atomic.nullParsers[`$"LIST GUID";1b];"845d4a11-3082-ecd7-afe8-8c5971b439f4, 3889e46d-0f63-48dc-6034-851735b9d0f1"] mustmatch ("G"$"845d4a11-3082-ecd7-afe8-8c5971b439f4";"G"$"3889e46d-0f63-48dc-6034-851735b9d0f1");

     };

   should["parse primitive NULLS"]{
     {[tp] .tst.parseResult[.cr.atomic.nullParsers[tp;1b];"NULL"] mustmatch .cr.atomic.nulls[tp]} each key .cr.atomic.parsers;
     };

   should["parse ARRAY"]{
     env:()!();
     qsdInfo:(enlist `model)!enlist ("ival(INT), fval(FLOAT), tval(TIME), dval(DATE), symval(SYMBOL)");
     txt:"( (ival(5)), (fval(6)), (tval(19:00:00)), (dval(2031.03.04)), (symval(SYMTEST)))";
     .tst.parseResult[.cr.compound.parsers[`ARRAY][env;qsdInfo];txt] mustmatch 
     flip `ival`fval`tval`dval`symval!((5i;0Ni;0Ni;0Ni;0Ni);0n 6.0 0n 0n 0n;(0Nt;0Nt;19:00:00.000;0Nt;0Nt);(0nd;0nd;0nd;2031.03.04;0nd);`````SYMTEST);


     qsdInfo:(enlist `model)!enlist "ival(INT), symval(SYMBOL)";
     txt:"( (ival(1)), (ival(2),symval(b)), (ival(3),symval(c)), (ival(4),symval(d)), (ival(5)))";
     .tst.parseResult[.cr.compound.parsers[`ARRAY][env;qsdInfo];txt] mustmatch 
     flip `ival`symval!((1i;2i;3i;4i;5i);``b`c`d`);
     };

   should["parse TABLE"]{
    qsdInfo:`col1`col2!("INT";"SYMBOL");
    env:()!();
    .tst.parseResult[.cr.compound.parsers[`TABLE][env;qsdInfo];"1(a), 2(b), 3(c)"] mustmatch ([] col1:(1i;2i;3i); col2:`a`b`c);
     };

   };

//----------------------------------------------------------------------------//
.tst.desc["template"]{
    before{
        .tst.loadLib[`cfgRdr.q];
        `ecfg mock .cr.parseCfgFile[file:`:test/template/dataflow.cfg;0];
        };
    after{
        };
    should["expand template for quoteEurope"]{
        t1:exec from ecfg[`subGroups] where suffix = `quoteEurope;
        (1!t1[`vars])[`template][`varVal`line`col] mustmatch ("rtrTable, generalHk";27j;14j);
        (1!t1[`vars])[`freq][`varVal`line`col] mustmatch ("2000";28j;10j); //template freq should be overwritten
        t1[`vars][`varName] mustmatch `model`freq`template;
        t1[`subGroups][`prefix] mustmatch `in.tickHF`in.feedMng`core.wdb`core.HK`core.rdb;
        t1[`subGroups][2][`vars][1][`varVal] mustmatch "${EC_SYS_PATH}/data/hdbEurope";
        t1[`subGroups][3][`vars][0][`varVal] mustmatch "30";
        };
    should["expand template for quoteAsia"]{
        t2:exec from ecfg[`subGroups] where suffix = `quoteAsia;
        (1!t2[`vars])[`template][`varVal`line`col] mustmatch ("rtrTable, generalHk";41j;14j);
        (1!t2[`vars])[`freq][`varVal`line`col] mustmatch ("1000";12j;10j);
        t2[`vars][`varName] mustmatch `model`freq`template;
        t2[`subGroups][`prefix] mustmatch `in.tickHF`in.feedMng`core.wdb`core.HK`core.rdb`core.mrvs;
        t2[`subGroups][2][`vars][1][`varVal] mustmatch "${EC_SYS_PATH}/data/hdbAsia";
        t2[`subGroups][3][`vars][0][`varVal] mustmatch "10";
        };
    should["expand template for quoteArctica"]{
        t3:exec from ecfg[`subGroups] where suffix = `quoteArctica;
        (1!t3[`vars])[`template][`varVal`line`col] mustmatch ("generalHk, rtrTable";54j;14j);
        (1!t3[`vars])[`freq][`varVal`line`col] mustmatch ("1000";12j;10j);
        t3[`vars][`varName] mustmatch `model`freq`template;
        t3[`subGroups][`prefix] mustmatch `core.HK`in.tickHF`in.feedMng`core.wdb;
        t3[`subGroups][0][`vars][1][`varVal] mustmatch "20";
        };
    should["expand template for trade"]{
        t4:exec from ecfg[`subGroups] where suffix = `trade;
        t4[`suffix] mustmatch `trade;
        (1!t4[`vars])[`template][`varVal`line`col] mustmatch ("rtrTable";57j;14j);
        (1!t4[`vars])[`freq][`varVal`line`col] mustmatch ("1000";12j;10j);
        t4[`vars][`varName] mustmatch `model`freq`template;
        t4[`subGroups][`prefix] mustmatch `in.tickHF`in.feedMng`core.wdb`core.HK;
        t4[`subGroups][3][`vars][0][`varVal] mustmatch "20";
        };
    should["section-level template resolving"]{
     tree:.cr.parseCfgFile[`:test/template/dataflow.cfg;0];
     (`rdbTemplate`generalHk`rtrTable!(`srcTickHF`eodPath;0#`;`model`freq)) mustmatch 
          exec suffix!{x`varName} each vars from tree[`subGroups] where prefix=`template;
     (enlist[`core.HK]!enlist[`action`frequency]) mustmatch 
          exec prefix!{x`varName} each vars from exec first subGroups from tree[`subGroups] where suffix=`generalHk;
     (`in.tickHF`in.feedMng`core.wdb`core.HK!(0#`;enlist `serverSrc;`srcTickHF`eodPath;enlist `frequency)) mustmatch 
          exec prefix!{x`varName} each vars from exec first subGroups from tree[`subGroups] where suffix=`rtrTable;
     };
    should["subsection-level template resolving"]{
     tree:.cr.parseCfgFile[`:test/template/dataflow.cfg;0];
     eurSubSect:exec first subGroups from tree[`subGroups] where suffix=`quoteEurope;
     (`srcTickHF`eodPath`template!("in.tickHF";"${EC_SYS_PATH}/data/core.hdb";"rdbTemplate"))mustmatch 
          exec varName!varVal from exec first vars from eurSubSect where prefix=`core.rdb;

     quoteSubSect:exec first subGroups from tree[`subGroups] where suffix=`quoteAsia;
     (`srcTickHF`eodPath`template!("in.tickHF2";"${EC_SYS_PATH}/data/core.hdb";"rdbTemplate"))mustmatch 
          exec varName!varVal from exec first vars from quoteSubSect where prefix=`core.rdb;
     };
    };

//----------------------------------------------------------------------------//
.tst.desc["custom global qsd fields"]{
    before{
        .tst.loadLib[`cfgRdr.q];
        `EC_QSL_PATH setenv "test/custom_qsd/";
        `EC_ETC_PATH setenv "test/custom_qsd/";
        delete cfg from `.cr;
        };
    after{
        };
    should["load configuration for gr1.rdb"]{
        .sl.componentId:`gr1.rdb;
        .cr.loadCfg[`THIS];
        "testTopField1" mustmatch .cr.getCfgField[`THIS;`group;`topField1];
        "testTopField2" mustmatch .cr.getCfgField[`THIS;`group;`topField2];
        "testGrField1" mustmatch .cr.getCfgField[`THIS;`group;`groupField1];
        "testGrField2" mustmatch .cr.getCfgField[`THIS;`group;`groupField2];
        "testComponentField1" mustmatch .cr.getCfgField[`THIS;`group;`componentField1];
        "testComponentField2" mustmatch .cr.getCfgField[`THIS;`group;`componentField2];

        "defaultCustom1" mustmatch .cr.getCfgField[`THIS;`group;`cfg.custom1];
        "topCustom2" mustmatch .cr.getCfgField[`THIS;`group;`cfg.custom2];
        "defaultCustom3" mustmatch .cr.getCfgField[`THIS;`table;`cfg.custom3];
        };
    should["load configuration for gr2.rdb"]{
        .sl.componentId:`gr2.rdb;
        .cr.loadCfg[`THIS];
        "testTopField1" mustmatch .cr.getCfgField[`THIS;`group;`topField1];
        "testTopField2" mustmatch .cr.getCfgField[`THIS;`group;`topField2];
        "testGrField1Override" mustmatch .cr.getCfgField[`THIS;`group;`groupField1];
        "testGr2Field2" mustmatch .cr.getCfgField[`THIS;`group;`groupField2];
        "testGr2ComponentField1" mustmatch .cr.getCfgField[`THIS;`group;`componentField1];
        "testGr2ComponentField2" mustmatch .cr.getCfgField[`THIS;`group;`componentField2];

        "defaultCustom1" mustmatch .cr.getCfgField[`THIS;`group;`cfg.custom1];
        "groupCustom2" mustmatch .cr.getCfgField[`THIS;`group;`cfg.custom2];
        "custom3_tab1" mustmatch .cr.getCfgField[`THIS;`table;`cfg.custom3];
        };
    should["load configuration for gr3.rdb"]{
        .sl.componentId:`gr3.rdb;
        .cr.loadCfg[`THIS];
        "testTopField1" mustmatch .cr.getCfgField[`THIS;`group;`topField1];
        "testTopField2" mustmatch .cr.getCfgField[`THIS;`group;`topField2];
        "testComponentField1" mustmatch .cr.getCfgField[`THIS;`group;`groupField1];
        "testGr3Field2" mustmatch .cr.getCfgField[`THIS;`group;`groupField2];
        "testComponentField1" mustmatch .cr.getCfgField[`THIS;`group;`componentField1];
        "testComponentField2" mustmatch .cr.getCfgField[`THIS;`group;`componentField2];

        "componentCustom1" mustmatch .cr.getCfgField[`THIS;`group;`cfg.custom1];
        "topCustom2" mustmatch .cr.getCfgField[`THIS;`group;`cfg.custom2];
        mustthrow["Field `cfg.custom3 for componentId `THIS for sectionType `table is missing in file dataflow.cfg";
          {.cr.getCfgField[`THIS;`table;`cfg.custom3]}];
        };
    should["load configuration for gr3.rdb, with .sl.componentId set to gr1.rdb"]{
        .sl.componentId:`gr1.rdb;
        .cr.loadCfg[`gr3.rdb];
        "testTopField1" mustmatch .cr.getCfgField[`gr3.rdb;`group;`topField1];
        "testTopField2" mustmatch .cr.getCfgField[`gr3.rdb;`group;`topField2];
        "testComponentField1" mustmatch .cr.getCfgField[`gr3.rdb;`group;`groupField1];
        "testGr3Field2" mustmatch .cr.getCfgField[`gr3.rdb;`group;`groupField2];
        "testComponentField1" mustmatch .cr.getCfgField[`gr3.rdb;`group;`componentField1];
        "testComponentField2" mustmatch .cr.getCfgField[`gr3.rdb;`group;`componentField2];

        "componentCustom1" mustmatch .cr.getCfgField[`gr3.rdb;`group;`cfg.custom1];
        "topCustom2" mustmatch .cr.getCfgField[`gr3.rdb;`group;`cfg.custom2];
        mustthrow["Field `cfg.custom3 for componentId `gr3.rdb for sectionType `table is missing in file dataflow.cfg";
          {.cr.getCfgField[`gr3.rdb;`table;`cfg.custom3]}];
        };
    };

//----------------------------------------------------------------------------//

/
.tst.desc["test error reporting"]{
    before{
        `cfg mock .cr.parseCfgFile[`:test/errors/system.cfg;0];
        `qsd mock .cr.parseCfgFile[`:test/errors/system.qsd;1];
        
        };
    after{
        };
    should["report QSD_READ_ERROR"]{
	    aligned:.cr.p.align[();();cfg;qsd;`error.missingQsd;0b];
        res:.cr.p.getErr[aligned];
        1 mustmatch count res;
		res[`errors][0] mustlike "QSD_READ_ERROR: empty libPath";
        };
		
	should["report error in auxiliarry qsd file"]{
	    aligned:.cr.p.align[();();cfg;qsd;`error.invalidQsdDef;0b];
        aligned:.cr.p.forceEval[aligned;`error.invalidQsdDef;`group];
		res:.cr.p.getErr[aligned];
        1 mustmatch count res;
		res[`errors][0] mustlike "*invalid.qsd*";
	    };
		
    should["report VALUE_PARSING_ERROR"]{
	    aligned:.cr.p.align[();();cfg;qsd;`error.parsingError;0b];
        aligned:.cr.p.forceEval[aligned;`error.parsingError;`group];
		res:.cr.p.getErr[aligned];
        1 mustmatch count res;
		res[`errors][0] mustlike "VALUE_PARSING_ERROR: variable port*";
	    };
    should["report MISSING_QSD_INFO"]{
	    aligned:.cr.p.align[();();cfg;qsd;`error.missingQsdInfo;0b];
        aligned:.cr.p.forceEval[aligned;`error.missingQsdInfo;`group];
		res:.cr.p.getErr[aligned];
        1 mustmatch count res;
		res[`errors][0] mustlike "MISSING_QSD_INFO: missing*";
	    };
    should["report MISSING_TYPE_INFO"]{
	    aligned:.cr.p.align[();();cfg;qsd;`error.missingTypeInfo;0b];
        aligned:.cr.p.forceEval[aligned;`error.missingTypeInfo;`group];
		res:.cr.p.getErr[aligned];
        1 mustmatch count res;
		res[`errors][0] mustlike "MISSING_TYPE_INFO: missingInfo*";
	    };
    should["report MISSING_ENTRY"]{
	    aligned:.cr.p.align[();();cfg;qsd;`error.missingEntry;0b];
        aligned:.cr.p.forceEval[aligned;`error.missingEntry;`group];
		res:.cr.p.getErr[aligned];
        1 mustmatch count res;
		res[`errors][0] mustlike "MISSING_ENTRY: missingEntry*";
	    };
    should["report VALUE_VALIDATING_ERROR"]{
	    aligned:.cr.p.align[();();cfg;qsd;`error.validationError;0b];
        aligned:.cr.p.forceEval[aligned;`error.validationError;`group];
		res:.cr.p.getErr[aligned];
        1 mustmatch count res;
		res[`errors][0] mustlike "VALUE_VALIDATING_ERROR: validationErr*";
	    };
    };

select from .tst.report where result<>`pass