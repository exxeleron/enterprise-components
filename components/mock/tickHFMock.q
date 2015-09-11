//tickHF mock
//----------------------------------------------------------------------------//
system"l ",getenv[`EC_QSL_PATH],"/sl.q";
.sl.init[`tickHFMock];
.sl.lib["cfgRdr/cfgRdr"];
.cr.loadCfg[`THIS];
//----------------------------------------------------------------------------//
.sl.getSubProtocols:{[] enlist `PROTOCOL_TICKHF};

.tickm.init:{[]
   (set) ./:.cr.getModel[`THIS];
   @[;`sym;`g#]each tables[];
   .tickm.w:()!();
   .u.L:.Q.dd . .cr.getCfgField[`THIS;`group;`dataPath],`$string[.z.d],getenv[`EC_COMPONENT_ID];
   if[not type key .u.L; .[.u.L;();:;()]];
   .u.i:-11!(-2;.u.L);
   .tickm.l:hopen .u.L;
   .cb.add[`.z.pc;`.tickm.pc];   
   };


.tickm.upd:{[tab;data]
   .tickm.l enlist (`jUpd;tab;value  flip data);
   .u.i+:1;
   neg[.tickm.w[tab]](`upd;tab;data); 
   };

.tickm.pc:{[x]
   -1"pc ",string x;
   .tickm.w _:.tickm.w?x;
   };

.tickm.end:{[date]
  (distinct value .tickm.w)@\:(`.u.end;date);
  };
   
.u.sub:{[tab;sym]
   -1"re-sub", string .z.w;
   -1 .Q.s1(tab;sym;.z.w);
   .tickm.w[tab]:.z.w;
   :(tab;value tab);
   };

.tickm.init[];
//----------------------------------------------------------------------------//

