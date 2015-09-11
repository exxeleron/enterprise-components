

.testHandle.setUp:{
  .test.start `t.process1;
  };
  
.testHandle.tearDown:{
  .test.stop `t.process1;
  .test.stop `t.process2;
  .test.stop `t.process3;
  };
  
 .testHandle.testSuite:"qsl/handle functional tests";

//----------------------------------------------------------------------------//

.testHandle.test.SetupConnectionLazyMode:{[]
  .test.start `t.process2;
  .hnd.h[`t.process1]".hnd.poAdd[`t.process2;`.tst.hnd.Fun1]";
  .hnd.h[`t.process1]".hnd.hopen[`t.process2`t.process3;1000i;`lazy]";
  .assert.match["port open has not run yet for process2";.hnd.h[`t.process1]".tst.hnd.Fun1Run";0];
  status:.hnd.h[`t.process1]".hnd.status";
  .assert.match["two registered processes";count where `registered=(0!.hnd.h[`t.process1]status)`state;2];
  .hnd.h[`t.process1]".hnd.h[`t.process2] \"2\""; // access process2
  .hnd.h[`t.process1]status:.hnd.h[`t.process1]".hnd.status";
  .assert.match["one registered processes";count where `registered=(0!.hnd.h[`t.process1]status)`state;1];
  .assert.match["one open processes";count where `open=(0!.hnd.h[`t.process1]status)`state;1];
  .assert.match["port open has run once for process2";.hnd.h[`t.process1]".tst.hnd.Fun1Run";1];
  // down and up - see port open running
  .test.stop `t.process2;
  .test.start `t.process2;
  .assert.match["port open has run twice for process2";.hnd.h[`t.process1]".tst.hnd.Fun1Run";2];
  errstr:$["w"~first string .z.o;"timeout";"hop: Connection refused"]; // timeout does not take effect on Linux
  .assert.remoteFail["signal when quering non-running server in lazy mode";
              `t.process1;
              ".hnd.h[`t.process3] \"2\"";
              `$"can't open connection to t.process3, erro: ",errstr];
  };

.testHandle.test.SetupConnectionEagerMode:{[]
  .hnd.h[`t.process1]".hnd.poAdd[`t.process2;`.tst.hnd.Fun1]";
  .hnd.h[`t.process1]".hnd.poAdd[`t.process3;`.tst.hnd.Fun2]";
  .hnd.h[`t.process1]".hnd.poAdd[`t.process2;`.tst.hnd.Fun1]";
  .hnd.h[`t.process1]".hnd.hopen[`t.process2`t.process3;1000i;`eager]";
  .hnd.h[`t.process1]status:.hnd.h[`t.process1]".hnd.status";
  .assert.match["two failed processes";count where `failed=(0!.hnd.h[`t.process1]status)`state;2];
  
  // action 
  .test.start `t.process2;
  .os.sleep 1000; // give time to notice
  //check
  .hnd.h[`t.process1]status:.hnd.h[`t.process1]".hnd.status";
  .assert.match["one failed process";count where `failed=(0!.hnd.h[`t.process1]status)`state;1];
  .assert.match["one open process";count where `open=(0!.hnd.h[`t.process1]status)`state;1];
  .assert.match["port open has run once for process2";.hnd.h[`t.process1]".tst.hnd.Fun1Run";1];
  .assert.match["port open has not run for process3";.hnd.h[`t.process1]".tst.hnd.Fun2Run";0];
  
  // action 
  .test.start `t.process3;
  .os.sleep 1000;
  //check
  .hnd.h[`t.process1]status:.hnd.h[`t.process1]".hnd.status";
  .assert.match["no failed processes";count where `failed=(0!.hnd.h[`t.process1]status)`state;0];
  .assert.match["two open processes";count where `open=(0!.hnd.h[`t.process1]status)`state;2];
  .assert.match["port open has run once for process2";.hnd.h[`t.process1]".tst.hnd.Fun1Run";1];
  .assert.match["port open has run once for process3";.hnd.h[`t.process1]".tst.hnd.Fun2Run";1];
  };

.testHandle.test.PortClose:{
  .test.start `t.process2;
  .hnd.h[`t.process1]".hnd.pcAdd[`t.process2;`.tst.hnd.Fun1]";
  .hnd.h[`t.process1]".hnd.hopen[`t.process2;1000i;`eager]";
  .test.stop `t.process2;
  .os.sleep 1000;
  .assert.match["port close has run once for process2";.hnd.h[`t.process1]".tst.hnd.Fun1Run";1];
  };
