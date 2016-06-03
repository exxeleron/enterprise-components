/L/ Copyright (c) 2011-2014 Exxeleron GmbH
/-/
/-/ Licensed under the Apache License, Version 2.0 (the "License");
/-/ you may not use this file except in compliance with the License.
/-/ You may obtain a copy of the License at
/-/
/-/   http://www.apache.org/licenses/LICENSE-2.0
/-/
/-/ Unless required by applicable law or agreed to in writing, software
/-/ distributed under the License is distributed on an "AS IS" BASIS,
/-/ WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
/-/ See the License for the specific language governing permissions and
/-/ limitations under the License.

/A/ DEVnet: Bartosz Kaliszuk (b.kaliszuk@devnet.com)
/V/ 3.0
/D/ 2012.06.22

/S/ Password generation component:
/-/ Responsible for:
/-/ - generation of encrypted password for a user
/-/ Usage:
/-/ In order to generate a new obfuscated password for a user, please run admin.genPass interactive service from yak
/-/ 
/-/ (start code)
/-/ $ yak console core.genPass
/-/ Please enter new password: USERINPUT
/-/ Please re-enter new password: USERINPUT
/-/ Your new password is: 0x6160e6574666
/-/ (end)
/-/ 
/-/ This new password (`0x6160e6574666`) should be  placed in access.cfg file.
/-/ Note:
/-/ Please note that kdb+ does not provide high level security measures on its own.
/-/ Therefore, it must be noted that any user with q knowledge and access to the source code will have means of compromising the system.
/-/ One way to prevent it is to compile the source code and use binaries in production environments.

/------------------------------------------------------------------------------/
system"l ",getenv[`EC_QSL_PATH],"/sl.q";
.sl.init[`gp];
.sl.lib["cfgRdr/cfgRdr"]; // necessary now even though we don't use configuration

/------------------------------------------------------------------------------/
.gp.p.dx:{[p;m] `byte$0b sv/:m<>/:0b vs/:`int$p};

/------------------------------------------------------------------------------/
/F/ Generates encrypted password. Should be execuded only when q started in console mode as it requires console interaction.
/R/ no return value
/E/ .gp.genpass[]
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

/------------------------------------------------------------------------------/
.sl.run[`gp;`.gp.genpass;`];
