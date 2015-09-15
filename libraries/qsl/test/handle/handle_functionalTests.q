/L/ Copyright (c) 2011-2015 Exxeleron GmbH
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

/A/ DEVnet: Slawomir K.
/V/ 3.0

// Functional tests of the qsl/handle library
// See README.md for details

//----------------------------------------------------------------------------//
.testHandle.testSuite:"qsl/handle functional tests";

.testHandle.setUp:{
  .test.start `t0.proc1;
  };
  
.testHandle.tearDown:{
  .test.stop `t0.proc1;
  .test.stop `t0.proc2;
  .test.stop `t0.proc3;
  };

//----------------------------------------------------------------------------//
.testHandle.test.SetupConnectionLazyMode:{[]
  .test.start `t0.proc2;
  .hnd.h[`t0.proc1]".hnd.poAdd[`t0.proc2;`.tst.hnd.Fun1]";
  .hnd.h[`t0.proc1]".hnd.hopen[`t0.proc2`t0.proc3;1000i;`lazy]";
  .assert.match["port open has not run yet for process2";.hnd.h[`t0.proc1]".tst.hnd.Fun1Run";0];
  status:.hnd.h[`t0.proc1]".hnd.status";
  .assert.match["two registered processes";count where `registered=(0!.hnd.h[`t0.proc1]status)`state;2];
  .hnd.h[`t0.proc1]".hnd.h[`t0.proc2] \"2\""; // access process2
  .hnd.h[`t0.proc1]status:.hnd.h[`t0.proc1]".hnd.status";
  .assert.match["one registered processes";count where `registered=(0!.hnd.h[`t0.proc1]status)`state;1];
  .assert.match["one open processes";count where `open=(0!.hnd.h[`t0.proc1]status)`state;1];
  .assert.match["port open has run once for process2";.hnd.h[`t0.proc1]".tst.hnd.Fun1Run";1];
  // down and up - see port open running
  .test.stop `t0.proc2;
  .test.start `t0.proc2;
  .os.sleep[1000];
  .assert.match["port open has run twice for process2";.hnd.h[`t0.proc1]".tst.hnd.Fun1Run";2];
  errstr:$["w"~first string .z.o;"timeout";"hop: Connection refused"]; // timeout does not take effect on Linux
  .assert.remoteFail["signal when quering non-running server in lazy mode";
              `t0.proc1;
              ".hnd.h[`t0.proc3] \"2\"";
              `$"can't open connection to t0.proc3, error: ",errstr];
  };

.testHandle.test.SetupConnectionEagerMode:{[]
  .hnd.h[`t0.proc1]".hnd.poAdd[`t0.proc2;`.tst.hnd.Fun1]";
  .hnd.h[`t0.proc1]".hnd.poAdd[`t0.proc3;`.tst.hnd.Fun2]";
  .hnd.h[`t0.proc1]".hnd.poAdd[`t0.proc2;`.tst.hnd.Fun1]";
  .hnd.h[`t0.proc1]".hnd.hopen[`t0.proc2`t0.proc3;1000i;`eager]";
  .hnd.h[`t0.proc1]status:.hnd.h[`t0.proc1]".hnd.status";
  .assert.match["two failed processes";count where `failed=(0!.hnd.h[`t0.proc1]status)`state;2];
  
  // action 
  .test.start `t0.proc2;
  .os.sleep 1000; // give time to notice
  //check
  .hnd.h[`t0.proc1]status:.hnd.h[`t0.proc1]".hnd.status";
  .assert.match["one failed process";count where `failed=(0!.hnd.h[`t0.proc1]status)`state;1];
  .assert.match["one open process";count where `open=(0!.hnd.h[`t0.proc1]status)`state;1];
  .assert.match["port open has run once for process2";.hnd.h[`t0.proc1]".tst.hnd.Fun1Run";1];
  .assert.match["port open has not run for process3";.hnd.h[`t0.proc1]".tst.hnd.Fun2Run";0];
  
  // action 
  .test.start `t0.proc3;
  .os.sleep 1000;
  //check
  .hnd.h[`t0.proc1]status:.hnd.h[`t0.proc1]".hnd.status";
  .assert.match["no failed processes";count where `failed=(0!.hnd.h[`t0.proc1]status)`state;0];
  .assert.match["two open processes";count where `open=(0!.hnd.h[`t0.proc1]status)`state;2];
  .assert.match["port open has run once for process2";.hnd.h[`t0.proc1]".tst.hnd.Fun1Run";1];
  .assert.match["port open has run once for process3";.hnd.h[`t0.proc1]".tst.hnd.Fun2Run";1];
  };

.testHandle.test.PortClose:{
  .test.start `t0.proc2;
  .hnd.h[`t0.proc1]".hnd.pcAdd[`t0.proc2;`.tst.hnd.Fun1]";
  .hnd.h[`t0.proc1]".hnd.hopen[`t0.proc2;1000i;`eager]";
  .test.stop `t0.proc2;
  .os.sleep 1000;
  .assert.match["port close has run once for process2";.hnd.h[`t0.proc1]".tst.hnd.Fun1Run";1];
  };

//----------------------------------------------------------------------------//
