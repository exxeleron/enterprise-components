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
/S/ A non-qspec test for timer.q, supposed to be run from the qspec part

system"l sl.q";
system"l pe.q";
system"l timer.q";

.sl.init[`timer_aux1];
system"l event.q";
system"l handle.q";
.test.fcount:0;
.test.frunTime:`timestamp$ 0;
f:{show "f: ",string x;.test.frunTime:x;.test.fcount+:1};
done:1b;
