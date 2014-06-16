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
/A/ DEVnet: Rafal Sytek
/D/ 2011.06.16
/V/ 0.1
/S/ Unit tests for protected evaluation (protect.q)
/E/ q protect_test.q --noquit -p 5001

/------------------------------------------------------------------------------/
/                                 dependencies                                 /
/------------------------------------------------------------------------------/

\l lib/qspec/qspec.q
system"l pe.q";

/------------------------------------------------------------------------------/

.tst.desc["[protect.q] Testing .pe.at"]{
  before{
    .tst.mockFunc[`.log.error;2;""];
    .pe.enable[];
    .tst.f:{[x] :x*x};
    };
  after{
    };
  should["pass the evaluation with the function name"]{
    result:.pe.at[.tst.f;3;`NOT_OK];
    result mustmatch 9;
    };
  should["fail the evaluation with the function name"]{
    result:.pe.at[.tst.f;`3;`NOT_OK];
    result mustmatch `NOT_OK;
    };
  should["pass the evaluation with the function body"]{
    result:.pe.at[value `.tst.f;6;`NOT_OK];
    result mustmatch 36;
    };
  should["fail the evaluation with the function body"]{
    result:.pe.at[value `.tst.f;`6;`NOT_OK];
    result mustmatch `NOT_OK;
    };
  should["pass the evaluation with the function as an error handler"]{
    result:.pe.at[value `.tst.f;6;{[x]:x}];
    result mustmatch 36;
    };
  should["fail the evaluation with the function as an error handler"]{
    result:.pe.at[value `.tst.f;`6;{[x]:x}];
    result mustmatch "type";
    };
  };

.tst.desc["[protect.q] Testing .pe.atLog"]{
  before{
    .tst.mockFunc[`.log.error;2;""];
    .pe.enable[];
    };
  after{
    };
  should["pass the evaluation"]{
    .tst.f:{[x]:x*x};
    arg:3;
    default:`NOT_OK; 
    logLevel:`error;
    result:.pe.atLog[`test;`.tst.f; arg; default; logLevel];
    result mustmatch 9;
    };
  should["custom log signal, fail with the default value"]{
    .tst.f:{[x]'stop}; // in log it shows [stop] as failed signal
    arg:`3;
    default:`NOT_OK; 
    logLevel:`error;
    result:.pe.atLog[`test;`.tst.f; arg; default; logLevel];
    result mustmatch `NOT_OK;
    };
  should["fail with the default value"]{
    .tst.f:{[x]:x*x};
    arg:`3;
    default:`NOT_OK; 
    logLevel:`error;
    result:.pe.atLog[`test;`.tst.f; arg; default; logLevel];
    result mustmatch `NOT_OK;
    };
  };

.tst.desc["[protect.q] Testing .pe.dot"]{
  before{
    .tst.mockFunc[`.log.error;2;""];
    .pe.enable[];
    .tst.f:{[x;y;z] :x*y*z};
    };
  after{
    };
  should["pass the evaluation with the function name"]{
    result:.pe.dot[.tst.f;(2;3;4);`NOT_OK];
    result mustmatch 24;
    };
  should["pass the evaluation with the function body"]{
    result:.pe.dot[value `.tst.f;(2;3;4);`NOT_OK];
    result mustmatch 24;
    };
  should["fail the evaluation with the function name"]{
    result:.pe.dot[.tst.f;(`3;4;5);`NOT_OK];
    result mustmatch `NOT_OK;
    };
  should["fail the evaluation with the function body"]{
    result:.pe.dot[value `.tst.f;(`6;7;8);`NOT_OK];
    result mustmatch `NOT_OK;
    };
  should["pass the evaluation with the function as an error handler"]{
    result:.pe.dot[value `.tst.f;(2;3;4);{[x]:x}];
    result mustmatch 24;
    };
  should["fail the evaluation with the function as an error handler"]{
    result:.pe.dot[value `.tst.f;(2;`3;4);{[x]:x}];
    result mustmatch "type";
    };
  };

.tst.desc["[protect.q] Testing .pe.dotLog"]{
  before{
    .tst.mockFunc[`.log.error;2;""];
    .pe.enable[];
    };
  after{
    };
  should["pass the evaluation"]{
    .tst.f:{[x;y]:x*y};
    args:(3 4);
    default:`NOT_OK; 
    logLevel:`error;
    result:.pe.dotLog[`test;`.tst.f; args; default; logLevel];
    result mustmatch 12;
    };
  should["custom log signal, fail with the default value"]{
    .tst.f:{[x;y]'stop}; // in log it shows [stop] as failed signal
    args:(3 4);
    default:`NOT_OK; 
    logLevel:`error;
    result:.pe.dotLog[`test;`.tst.f; args; default; logLevel];
    result mustmatch `NOT_OK;
    };
  should["fail with the default value"]{
    .tst.f:{[x;y]:x*y};
    args:(enlist "3"; enlist "4");
    default:`NOT_OK; 
    logLevel:`error;
    result:.pe.dotLog[`test;`.tst.f; args; default; logLevel];
    result mustmatch `NOT_OK;
    };
  };

.tst.desc["[protect.q] Testing disabling/enabling"]{
  before{
    .tst.mockFunc[`.log.error;2;""];
    .pe.enable[];
    };
  should["desable pe - .pe.disable"]{
    .pe.disable[];
    .pe.at mustmatch {[func; arg; errH]                  func @ arg};
    .pe.enabled mustmatch 0b;
    };
  should["enable pe - .pe.enable"]{
    .pe.disable[];
    .pe.enable[];
    .pe.at mustnmatch {[func; arg; errH]                  func @ arg};
    .pe.enabled mustmatch 1b;
    };

  };
