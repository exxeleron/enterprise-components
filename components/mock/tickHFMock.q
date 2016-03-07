//tickHF mock
//----------------------------------------------------------------------------//
system"l ",getenv[`EC_QSL_PATH],"/sl.q";
.sl.init[`tickHFMock];
.sl.lib["cfgRdr/cfgRdr"];
.cr.loadCfg[`THIS];
//----------------------------------------------------------------------------//
/F/ Returns information about subscription protocols supported by the tickHF component.
/-/  This definition overwrites default implementation from qsl/sl library.
/-/  This function is used by qsl/sub library to choose proper subscription protocol.
/R/ :LIST SYMBOL - returns list of protocol names that are supported by the server - `PROTOCOL_TICKHF
/E/ .sl.getSubProtocols[]
.sl.getSubProtocols:{[] enlist `PROTOCOL_TICKHF};

//----------------------------------------------------------------------------//
/F/ Initializes tick mock instance.
/R/ no return value
/E/ .tickm.init[]
.tickm.init:{[]
   (set) ./:.cr.getModel[`THIS];
   @[;`sym;`g#]each tables[];
   /G/ Dictionary with subscriptions.
   .tickm.w:()!();
   /G/ Journal path.
   .u.L:.Q.dd . .cr.getCfgField[`THIS;`group;`dataPath],`$string[.z.d],getenv[`EC_COMPONENT_ID];
   if[not type key .u.L; .[.u.L;();:;()]];
   /G/ Journal position.
   .u.i:-11!(-2;.u.L);
   /G/ Journal handle.
   .tickm.l:hopen .u.L;
   .cb.add[`.z.pc;`.tickm.pc];   
   };

//----------------------------------------------------------------------------//
/F/ Receives tick update.
/P/ tab:SYMBOL - table name
/P/ data:LIST  - list of columns
/R/ no return value
/E/ .tickm.upd[`trade;tradeData]
.tickm.upd:{[tab;data]
   .tickm.l enlist (`jUpd;tab;value  flip data);
   .u.i+:1;
   neg[.tickm.w[tab]](`upd;tab;data); 
   };

//----------------------------------------------------------------------------//
/F/ Callback executed on port close.
/P/ x:INT - connection handle
/R/ no return value
/E/ .tickm.pc[12i]
.tickm.pc:{[x]
   -1"pc ",string x;
   .tickm.w _:.tickm.w?x;
   };

//----------------------------------------------------------------------------//
/F/ Triggers eod publishing.
/P/ date:DATE - eod date
/R/ no return value
/E/ .tickm.end[.z.d]
.tickm.end:{[date]
  (distinct value .tickm.w)@\:(`.u.end;date);
  };
   
//----------------------------------------------------------------------------//
/F/ Subscribe for updates.
/P/ tab:SYMBOL               - table name
/P/ sym:SYMBOL | LIST SYMBOL - list of symbols 
/R/ :PAIR(SYMBOL;TABLE) - pair with the data model for the subscribed table
/E/ .u.sub[`trade;`]
.u.sub:{[tab;sym]
   -1"re-sub", string .z.w;
   -1 .Q.s1(tab;sym;.z.w);
   .tickm.w[tab]:.z.w;
   :(tab;value tab);
   };

//----------------------------------------------------------------------------//
.tickm.init[];

//----------------------------------------------------------------------------//

