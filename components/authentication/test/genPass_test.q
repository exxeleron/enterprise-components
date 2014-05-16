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
//q test/genPass_test.q --noquit -p 9009

system "l lib/qspec/qspec.q";
system "l lib/qsl/sl.q";

.sl.init[`test];

.tst.desc["Test password hashing"]{
  before{
    `pass mock "simple_password";
    .sl.noinit:1b;
    system "l genPass.q";
    };
  after{
    };
  should["hash password with no mask - gp.p.dx[]"]{
    0x73696D706C655F70617373776F7264 mustmatch .gp.p.dx[pass;.sl.p.m];
    };
  should["hash password with no mask - gp.p.dx[]"]{
    0x5b414558444d7758495b5b5f475a4c mustmatch .gp.p.dx[pass;01100100001011100101100100101000b];
    };
  };

