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

//
/A/ DEVnet: Slawomir Kolodynski
/D/ 2013-02-25
/V/ 0.1
/S/ Unit tests for timer (timer.q)
/E/ q test/cb_test.q --noquit -p 5001

system "l lib/qspec/qspec.q";
system "l sl.q";
system "l pe.q";
.sl.init[`cb_test];


/F/ starts a q process on the specified port and executes a script
/P/ offset:INT - the process is started at the offset from te current port
/P/ script:STRING - the name of script, without the q extension
/R/ :HANDLE - a handle to the running q process
.tst.cb.exect:{[offset;script]
  port:.z.i+1024;
  if[.z.o in `w32`w64; system "start q -p ",(string port+offset)];
  if[.z.o in `l32`s32`v32`l64`s64`v64;system "q -p ",(string port+offset)];
  system "sleep 2"; // to give time to start
  h:hopen `$":localhost:",string offset+port;
  h "system\"l ",script,".q\"";
  :h
  };

.tst.desc["[callback.q] adding and removing callbacks - .cb.add[], .cb.del[]"]{
  before{
    system "l callback.q";
    .tst.cb.fc:0;
    .tst.cb.f:{.tst.cb.fc+:x+1;};
    .tst.cb.gc:0;
    .tst.cb.g:{.tst.cb.gc+:x+2};
    .cb.add[`.t.t;`.tst.cb.f];
    .cb.add[`.t.t;`.tst.cb.g];
    .t.t[1];
    .cb.del[`.t.t;`.tst.cb.g];
    .t.t[1];
    };
  after{
    };
  should["add and execute some callbacks"]{
    .tst.cb.fc mustmatch 4;
    .tst.cb.gc mustmatch 3;
    };
  };

.tst.desc["[callback.q] and return value - .cb.setLast[]"]{
  before{
    system "l callback.q";
    .tst.cb.f:{x};
    .tst.cb.g:{x+1};
    .cb.add[`.t.t;`.tst.cb.f];
    .cb.add[`.t.t;`.tst.cb.g];
    .tst.cb.retg:.t.t[0];
    .cb.setLast[`.t.t;`.tst.cb.f];
    .tst.cb.retf:.t.t[0];
    };
  after{    
    };
  should["add and execute some callbacks"]{
    .tst.cb.retg mustmatch 1;
    .tst.cb.retf mustmatch 0;
    };
  };

.tst.desc["[callback.q] and callbacks on .z.pg -.cb.setLast[]"]{
  before{
    system "l callback.q";
    `.tst.cb.h mock .tst.cb.exect[1;"test/ext/cb_test_aux1"];
    `.tst.cb.pid mock .tst.cb.h `.z.i;
    };
  after{
    @[.tst.cb.h;"exit 0";`$"closed remote process"];
    };
  should["overwrite .z.pg correctly"]{
    4 mustmatch .tst.cb.h "3"; // .z.pg in cb_test_aux1 adds one
    .tst.cb.h ".cb.del[`.z.pg;`f]";
    .tst.cb.h ".cb.del[`.z.pg;`g]";
    3 mustmatch .tst.cb.h "3";
    };

  };
\
