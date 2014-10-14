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
//q test/refreshUFiles.q --noquit -p 9009

system"l lib/qspec/qspec.q";
system "l lib/qsl/sl.q";

.sl.init[`test];
.sl.noinit:1b;
.tst.desc["Refreshing permission files for several processes"]{
  before{
    system "l refreshUFiles.q";
    `.cr.p.procNames mock `access.ap`in.tick;
    `cfgTab mock ([] sectionVal:`admin`admin2`test; 
                     subsection:`ALL`in.tick`access.ap;
                     varName:`namespaces`namespaces`namespaces;
                     finalValue:(enlist `ALL;enlist `ALL;enlist `.test));
    `.cr.getCfgTab mock {[x;y;z] :cfgTab};
    `cfgPivot mock ([sectionVal:`test`tu`tu2] pass:("0xbeafbdbdff";"0xbeafbdbdfc";"0xbeafbdbdfc");usergroups:`test`admin`admin2);
    `.cr.getGroupCfgPivot mock {[x;y] :cfgPivot};
    `refPassDict mock `test`tu`tu2!raze each string each md5 each ("pass1";"pass2";"pass2");
    `.cr.getByProc mock {:([proc:`in.tick`access.ap] uFile:`:test/user.txt`:test/access.ap.txt)};
    `.ru.cfg.userTxtPath mock `:test;
    };
  after{
    .tst.rm `:test/access.ap.txt;
    };
  should["refresh permissions for several processes - .ru.p.init[]"]{
    .ru.p.init[];
    `:test/access.ap.txt mustmatch key `:test/access.ap.txt;
    `:test/user.txt mustmatch key `:test/user.txt;
    passDictAP:(!). ("S*";":")0: `:test/access.ap.txt;
    (2;2) musteq count each ("S*";":")0: `:test/access.ap.txt;
    passDictAP[`tu] mustmatch refPassDict[`tu];
    passDictAP[`test] mustmatch refPassDict[`test];
    passDictTick:(!). ("S*";":")0: `:test/access.ap.txt;
    (2;2) musteq count each ("S*";":")0: `:test/user.txt;
    passDictTick[`tu] mustmatch refPassDict[`tu];
    passDictTick[`test] mustmatch refPassDict[`test];
    };
  };
.tst.desc["Refreshing permission when groups are misconfigured"]{
  before{
    system "l refreshUFiles.q";
    `.cr.p.procNames mock `access.ap`in.tick;
    `cfgTab mock ([] sectionVal:`admin`admin4`test; 
                     subsection:`ALL`in.tick`access.ap;
                     varName:`namespaces`namespaces`namespaces;
                     finalValue:(enlist `ALL;enlist `ALL;enlist `.test));
    `.cr.getCfgTab mock {[x;y;z] :cfgTab};
    `cfgPivot mock ([sectionVal:`test`tu`tu2] pass:("0xbeafbdbdff";"0xbeafbdbdfc";"0xbeafbdbdfc");usergroups:`test`admin`admin2);
    `.cr.getGroupCfgPivot mock {[x;y] :cfgPivot};
    `refPassDict mock `test`tu`tu2!raze each string each md5 each ("pass1";"pass2";"pass2");
    `.cr.getByProc mock {:([proc:`in.tick`access.ap] uFile:`:test/user.txt`:test/access.ap.txt)};
    `.ru.cfg.userTxtPath mock `:test;
    };
  after{
    .tst.rm `:test/access.ap.txt;
    .tst.rm `:test/user.txt;
    };
  should["skip groups with incomplete configuration - .ru.p.init[]"]{
    // for groups that don't have users defined, or for users that are assigned
    // to groups that don't exist - skip password generation
    .ru.p.init[];
    `:test/access.ap.txt mustmatch key `:test/access.ap.txt;
    `:test/user.txt mustmatch key `:test/user.txt;
    passDictAP:(!). ("S*";":")0: `:test/access.ap.txt;
    (2;2) musteq count each ("S*";":")0: `:test/access.ap.txt;
    passDictAP[`tu] mustmatch refPassDict[`tu];
    passDictAP[`test] mustmatch refPassDict[`test];
    passDictTick:(!). ("S*";":")0: `:test/user.txt;
    (1;1) musteq count each ("S*";":")0: `:test/user.txt;
    passDictTick[`tu] mustmatch refPassDict[`tu];
    passDictTick[`test] mustnmatch refPassDict[`test];
    };
  };
/
.gp.p.dx["pass2";.sl.p.m]
