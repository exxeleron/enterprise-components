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

/A/ DEVnet: Bartosz Kaliszuk (b.kaliszuk@devnet.com)
/V/ 3.0
/D/ 2012.06.22

/S/ Password generation component:
/S/ Responsible for:
/S/ - generation of encrypted password for a user
/S/ Usage:
/S/ In order to generate a new obfuscated password for a user, please run admin.genPass interactive service from yak
/S/ 
/S/ (start code)
/S/ $ yak console core.genPass
/S/ Please enter new password: USERINPUT
/S/ Please re-enter new password: USERINPUT
/S/ Your new password is: 0x6160e6574666
/S/ (end)
/S/ 
/S/ This new password (`0x6160e6574666`) should be  placed in access.cfg file.
/S/ Note:
/S/ Please note that kdb+ does not provide high level security measures on its own.
/S/ Therefore, it must be noted that any user with q knowledge and access to the source code will have means of compromising the system.
/S/ One way to prevent it is to compile the source code and use binaries in production environments.

system"l ",getenv[`EC_QSL_PATH],"/sl.q";
.sl.init[`gp];
.sl.lib["cfgRdr/cfgRdr"]; // necessary now even though we don't use configuration
.gp.p.dx:{[p;m] `byte$0b sv/:m<>/:0b vs/:`int$p};
.gp.genpass:{[] 
  1 "\n\n";
  1 "Please enter new password: ";
  p1: read0 0;
  1 "Please re-enter new password: ";
  p2: read0 0;
  if[not p1~p2; -1 "Passwords don't match."; exit[1]];
  -1 "New password is: 0x","" sv string .gp.p.dx[p1;.sl.p.m];
  exit[0];
  };


.sl.run[`gp;`.gp.genpass;`];
