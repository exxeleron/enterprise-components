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
//q test/refreshPerm_test.q --noquit -p 9009

system"l lib/qspec/qspec.q";
system "l lib/qsl/sl.q";

.sl.init[`test];
.sl.noinit:1b;
.tst.desc["Refreshing permission files for processes"]{
  before{
    system "l refreshPerm.q";
    `.cr.p.procNames mock enlist `access.ap;
    `cfgTab mock ([] sectionVal:`admin`admin2`test; subsection:`ALL`ALL`access.ap;
                     varName:`namespaces`namespaces`namespaces;finalValue:(enlist `ALL;enlist `ALL;enlist `.test));
    `.cr.getCfgTab mock {[x;y;z] :cfgTab};
    `cfgPivot mock ([sectionVal:`test`tu`tu2] pass:("0x7061737331";"0x7061737332";"0x7061737332");usergroups:`test`admin`admin2);
    `.cr.getGroupCfgPivot mock {[x;y] :cfgPivot};
    `refPassDict mock `test`tu!raze each string each md5 each ("pass1";"pass2");
    `.rp.cfg.userTxtPath mock `:test;
    };
  after{
    .tst.rm `:test/access.ap.txt;
    };
  should["refresh permissions for one process - .rp.p.init[]"]{
    .rp.p.init[];
    `:test/access.ap.txt mustmatch key `:test/access.ap.txt;
    passDict:(!). ("S*";":")0: `:test/access.ap.txt;
    (3;3) musteq count each ("S*";":")0: `:test/access.ap.txt;
    passDict[`tu] mustmatch refPassDict[`tu];
    passDict[`test] mustmatch refPassDict[`test];
    };
  };

/
.gp.p.dx["pass2";.sl.p.m]
