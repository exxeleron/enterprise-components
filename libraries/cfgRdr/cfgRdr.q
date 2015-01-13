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
 
/A/ DEVnet:  Bartosz Dolecki
/V/ 3.0
 
/S/ Configuration reader library:
/S/ Responsible for:
/S/ - loading of *.cfg configuration files based on *.qsd meta files (q schema definition)

/S/ Supported data types:

/S/ *BOOLEAN*
/S/ (start code)
/S/ qsd:
/S/ cfg.isActive = <type(BOOLEAN)>
/S/ 
/S/ cfg:
/S/ cfg.isActive = 1     // value in q: 1b
/S/ cfg.isActive = 1b    // value in q: 1b
/S/ cfg.isActive = TRUE  // value in q: 1b
/S/ cfg.isActive = 0     // value in q: 0b
/S/ cfg.isActive = 0b    // value in q: 0b
/S/ cfg.isActive = FALSE // value in q: 0b
/S/ (end)

/S/ *CHAR*
/S/ (start code)
/S/ qsd:
/S/ cfg.flag = <type(CHAR)>
/S/ 
/S/ cfg:
/S/ cfg.flag = F // value in q "F" (type -10h)
/S/ (end)

/S/ *DATE*
/S/ (start code)
/S/ qsd:
/S/ cfg.maxMaturity = <type(DATE)>
/S/ 
/S/ cfg:
/S/ cfg.maxMaturity = 2013.05.13
/S/ (end)

/S/ *DATETIME*
/S/ (start code)
/S/ qsd:
/S/ cfg.minTstmp = <type(DATETIME)>
/S/ 
/S/ cfg:
/S/ cfg.minTstmp = 2013.05.13D14:30:00.000  // value in q: 2013.05.13T14:30:00.000
/S/ (end)

/S/ *FLOAT*
/S/ (start code)
/S/ qsd:
/S/ cfg.latency = <type(FLOAT)>
/S/ 
/S/ cfg:
/S/ cfg.timeZone = 12.0   // value in q: 12.0 (type -9h - float) 
/S/ (end)

/S/ *GUID*
/S/ (start code)
/S/ valid with q version > 3.0
/S/ qsd:
/S/ cfg.guid = <type(GUID)>
/S/ 
/S/ cfg:
/S/ cfg.guid = 337714f8-3d76-f283-cdc1-33ca89be59e9 0a369037-75d3-b24d-6721-5a1d44d4bed5
/S/ (end)

/S/ *INT*
/S/ (start code)
/S/ qsd:
/S/ cfg.latency = <type(INT)>
/S/ 
/S/ cfg:
/S/ cfg.latency = 42   // value in q: 42i
/S/ (end)

/S/ *LONG*
/S/ (start code)
/S/ qsd:
/S/ cfg.latency = <type(LONG)>
/S/ 
/S/ cfg:
/S/ cfg.latency = 42    // value in q: 42j
/S/ (end)

/S/ *PATH*
/S/ Environment variables can be used here; empty path must be denoted by NULL 
/S/ (start code)
/S/ qsd:
/S/ cfg.reportDir = <type(PATH)>
/S/ cfg.sourceDir = <type(PATH)>
/S/ 
/S/ cfg:
/S/ cfg.reportDir = /mnt/data/reports
/S/ cfg.sourceDir = ${dataPath}/src/
/S/ (end)

/S/ *REAL*
/S/ (start code)
/S/ qsd:
/S/ cfg.latency = <type(REAL)>
/S/ 
/S/ cfg:
/S/ cfg.timeZone = 12.0e   // value in q: 12.0 (type -8h - real)
/S/ (end)

/S/ *SHORT*
/S/ (start code)
/S/ qsd:
/S/ cfg.latency = <type(SHORT)>
/S/ 
/S/ cfg:
/S/ cfg.latency = 42    // value in q: 42h
/S/ (end)

/S/ *STRING*
/S/ Special characters "<>()" need to be escaped with a "/"; empty string must be denoted by NULL
/S/ (start code)
/S/ qsd:
/S/ cfg.timeZone = <type(SYMBOL), default(UTC)>
/S/ 
/S/ cfg:
/S/ cfg.timeZone = CET      // value in q: "CET"
/S/ cfg.timeZone = "CET"    // value in q: "\"CET\"" (note the double quotes are not removed)
/S/ cfg.timeZone = CET \(Central European Time\)  // value in q: "CET (Central European Time)" 
/S/ cfg.timeZone = NULL     // value in q: ""
/S/ (end)

/S/ *SYMBOL*
/S/ Special characters "<>()" need to be escaped with a "/"; empty symbol must be denoted by NULL
/S/ (start code)
/S/ qsd:
/S/ cfg.timeZone = <type(SYMBOL), default(UTC)>
/S/ 
/S/ cfg:
/S/ cfg.timeZone = CET    // value in q: `CET
/S/ (end)

/S/ *TIME*
/S/ (start code)
/S/ qsd:
/S/ cfg.marketClose = <type(TIME)>
/S/ 
/S/ cfg:
/S/ cfg.marketClose = 17:00:00.000
/S/ (end)

/S/ *TIMESPAN*
/S/ (start code)
/S/ qsd:
/S/ cfg.minTstmp = <type(TIMESPAN)>
/S/ 
/S/ cfg:
/S/ cfg.minTstmp = 12D14:30:00.000 // value in q 12D14:30:00.000000000
/S/ (end)

/S/ *TIMESTAMP*
/S/ (start code)
/S/ qsd:
/S/ cfg.minTstmp = <type(TIMESTAMP)>
/S/ 
/S/ cfg:
/S/ cfg.minTstmp = 2013.05.13D14:30:00.000  // value in q: 2013.05.13D14:30:00.000000000
/S/ (end)

/S/ *LIST <TYPE>*
/S/ For all atomic types (all types listed above), a list of values can be defined by adding "LIST" before type name in *.qsd file; such values are then listed in cfg file with coma as a delimiter
/S/ (start code)
/S/ qsd:
/S/ .cfg.reportTimes = <type(LIST TIME)>
/S/ cfg:
/S/ cfg.reportTimes = 12:00:00.000, 17:00:00.000 // value in q: (12:00:00.000, 17:00:00.000)
/S/ (end)

/S/ *TABLE*
/S/ Returns table with 2 columns
/S/ (start code)
/S/ qsd:
/S/ cfg.enum = <type(TABLE), col1(SYMBOL), col2(INT)>
/S/ 
/S/ cfg:
/S/ cfg.enum = red(1), blue(2), green(3)  
/S/ // value in q
/S/ //    +--------+--------+
/S/ //    +  col1  |  col2  +
/S/ //    +--------+--------+
/S/ //    +  red   |    1   |
/S/ //    +  blue  |    2   |
/S/ //    +  green |    3   |
/S/ //    +--------+--------+
/S/ (end)

/S/ *ARRAY*
/S/ Allows to define more complex tables
/S/ (start code)
/S/
/S/ cfg:
/S/ cfg.tab = <type(ARRAY), model(timezone(SYMBOL), descr(STRING), offset(TIME))>
/S/ cfg:
/S/ cfg.tab = ((timezone(UTC), descr(Coordinated universal time), offset(00:00:00.000)), (timezone(CET), descr(Central European time), offset(01:00:00.000)))
/S/ // value in q
/S/ //  |--------------------------------------------------------|
/S/ //  | timezone | descr                       | offset        |
/S/ //  |----------+-----------------------------+---------------|
/S/ //  |   UTC    | Coordinated universal time  | 00:00:00.000  |
/S/ //  |   CET    | Central European time       | 01:00:00.000  |
/S/ //  |--------------------------------------------------------|
/S/ (end)

/S/ *PORT*
/S/ Used for defining port numbers; value can be arithmetic expression (with "+" and "-" operators) and use basePort variable.
/S/ (start code)
/S/ qsd:
/S/ cfg.port = <type(PORT)>
/S/ 
/S/ cfg:
/S/ cfg.port = ${basePort} + 42
/S/ (end)

/S/ *COMPONENT*
/S/ Used for defining component names; value can be a component symbolic name. 
/S/ If a base name of a clone is used - it will be automatically expanded to a list all its clones.
/S/ (start code)
/S/ qsd:
/S/ cfg.src = <type(COMPONENT)>
/S/ 
/S/ cfg:
/S/ cfg.src = in.tickHF
/S/ (end)

//----------------------------------------------------------------------------//
system"l ",getenv[`EC_QSL_PATH],"/sl.q";
.sl.init[`cfgRdr];
 
.sl.lib["qsl/parseq.q"];
 
//----------------------------------------------------------------------------//
.cr.p.varModel:([] varName:`symbol$(); varVal:(); line:`long$(); col:`long$(); file:`$(); errors:());
 
.cr.p.auxQsdFiles:enlist[`]!enlist[::];
 
.cr.p.auxQsdVars:enlist[`.]!enlist[::];
 
.cr.p.auxQsdMapping:enlist[enlist `]!enlist[enlist `];
 
.cr.p.escapedChars:"<>()";
 
.cr.p.mySpaces:.par.oneOf[" \t"];

//----------------------------------------------------------------------------//
//                              parser                                        //
//----------------------------------------------------------------------------//
 
.cr.p.escChars:{[chrs;ps]
  : .par.oneOf[chrs] .par.char["\\"] ps;
  };
 
.cr.p.escString:{[allowedChars;ps]
  escapedChars:.cr.p.escapedChars  inter allowedChars;
  allowedChars:allowedChars except escapedChars;
  res:.par.many[.par.choice[(.cr.p.escChars[escapedChars];.par.oneOf[allowedChars])]] ps;
  if[null res[`errp];
    if[0=count res[`ast];res[`ast]:""]
    ];
  :res;
  };
 

.cr.p.byte:{[ps]
  res:.par.oneOf["0123456789abcdefABCDEF"] ps;
  if[null res[`errp];
    res[`ast]:lower res[`ast];
    ];
  :res;
  };
 
.cr.p.assignment:{[lineInfo;isqsd;ps]
  if[0N <> ps`errp; :ps];
    res1:.par.many[.cr.p.mySpaces] ps;
    res2:.cr.p.identifier res1;

  if[0N <> res1`errp; :res1];
  if[0N <> res2`errp; :res2];
    varName:res2[`ast];

    res3:.par.many[.cr.p.mySpaces] res2;
    res4:.par.char["="] res3;
    res5:.par.many[.cr.p.mySpaces] res4;

  if[0N <> res3`errp; :res3];
  if[0N <> res4`errp; :res4];
  if[0N <> res5`errp; :res5];

  res6:$[isqsd;
    [
      dt:.cr.p.angleDict[lineInfo] res5;
      res5a:.par.many[.cr.p.mySpaces]  dt;
 
      if[0N <> dt`errp; :dt];
      if[0N <> res5a`errp; :res5a];
      res5a[`ast]:last dt[`ast];
      res5a
      ];
    [ 
       res5a:.par.many[.par.noneOf[enlist "\n"]] res5;
       if[0N <> res5a`errp; :res5a];
       if[10=type res5a[`ast];res5a[`ast]:trim res5a[`ast]];
       res5a
       ]
    ];
  if[0N <> res6`errp; :res6];  
  varVal:res6[`ast];
  if[(0h=type varVal) & (0 = count varVal) & (not isqsd);
     varVal:"";
    ];
  res7:.cr.p.tillEOL res6;
  if[0N <> res7`errp; :res7];
  parseInfo:.cr.p.convertPos[lineInfo;res5[`cp]];
  res7[`ast]:(`assignment;(`varName`varVal`line`col!(`$varName;varVal;parseInfo[`line];parseInfo[`col])));
  :res7;
  };
 
// .cr.p.emptyLine .par.initP "     ","\n"
.cr.p.emptyLine:{[ps]
  if[0N <> ps`errp; :ps];
  res1:.cr.p.tillEOL ps;
  if[0N <> res1`errp; :res1];
    res1[`ast]: enlist `emptyLine;
  :res1;
  };
 
 
// .cr.p.tillEOL .par.initP "      ","\n"
.cr.p.tillEOL:{[ps]
  if[0N <> ps`errp; :ps];
  res1:.par.many[.cr.p.mySpaces] ps;
  if[0N <> res1`errp; :res1];
    :.par.char["\n"] res1;
  };
 
// .cr.p.identifier .par.initP "asd"
.cr.p.identifier:{[ps]
  if[0N <> ps`errp; :ps];
  head:.par.oneOf[.Q.a,.Q.A,"_."] ps;
  res:.cr.p.escString[.Q.a,.Q.A,"_.0123456789"] head;
  if[0N <> head`errp; :head];
  if[0N <> res`errp; :res];
    res[`ast]:head[`ast],res[`ast]; //lower
    :res;
  };
 
 
.cr.p.symIdentifier:{[ps]
  res:.cr.p.identifier ps;
  if[null res[`errp];
    res[`ast]:`$res[`ast];
    ];
  :res;
  };
 
.cr.p.convertPos:{[lineInfo;pos]
  if[pos<lineInfo[0];:`line`col!(1;pos)];
  line:-1+first where 0 < lineInfo-pos ;
  col:pos-lineInfo[line];
  :`line`col!(line+2;col);
  };
 
//----------------------------------------------------------------------------//
//                               templates                                    //
//----------------------------------------------------------------------------//
//templ:templates tmplIds 0
.cr.p.expandOneTemplate:{[tb;templ]
  tb[`vars]:0!(1!templ[`vars]),(1!tb[`vars]);                                                         //merge vars
  if[0=count tb[`subGroups];   
    tb[`subGroups]:templ[`subGroups];
    :tb
    ];
  sg:0!(delete vars from 1!update templateVars:vars from templ[`subGroups])uj(1!tb[`subGroups]);  //joing subGroups
  newGroups:{x[`vars]:0!(1!x[`templateVars]),$[0<>count x[`vars];1!x[`vars];()];`templateVars _ x}each sg;         //merge subGroups
  tb[`subGroups]:`prefix`prefixAux`suffix`suffixAux`groupParseLine`groupParseCol`vars`subGroups`errors xcols newGroups;
  :tb
  };
 
//tb:cfg[`subGroups] 3
.cr.p.expandOneSectionTemplates:{[templates;tb]
  tmpl:exec varVal from tb[`vars] where varName=`template;  //find template
  if[1<count tmpl;
    tb[`errors],:`$"Template field defined twice - only the last one will be taken"l
    ];
  if[0=count tmpl;:tb];
  tmplIds:(`$","vs last tmpl)except `;
  if[any not existing:tmplIds in key[templates][`template];
    tb[`errors],:`$"Template ", .Q.s1[tmplIds], " definition not found";
    ];
  tb:tb (.cr.p.expandOneTemplate)/ reverse templates'[tmplIds where existing];
  //iterate over sub-templates
  if[count tb[`subGroups];
    tb[`subGroups]:.cr.p.expandOneSectionTemplates[templates] each tb[`subGroups];
    ];
  tb
  };
 
.cr.p.expandTemplates:{[cfg]
  templates:select first vars, first subGroups by template:suffix from cfg[`subGroups] where prefix=`template;
  cfg[`subGroups]:.cr.p.expandOneSectionTemplates[templates] each cfg[`subGroups];
  cfg
  };

//----------------------------------------------------------------------------//
//                                   clones                                   //
//----------------------------------------------------------------------------//
.cr.p.clones:(`symbol$())!`int$();
.cr.p.expandClonesSet:{[pr]
  if[`~pr`suffix;:enlist pr]; //no clones
  cloneCn:string[pr`suffix]
  clones:$[`ALL~pr`suffix;;string til "I"$];
  new:count[clones]#enlist pr;
  new[`prefix]:`$string[pr`prefix],/:"_",/:clones;
  new[`vars]:([]varName:`EC_COMPONENT_INSTANCE;varVal:clones;line:pr`groupParseLine;col:pr`groupParseCol;file:`;errors:count[clones]#enlist 0#`),'new[`vars];
  new
  };
//clonesInfo:"12"
.cr.p.expandClonesSet:{[pr]
  clonesInfo:trim string[pr`suffix];
  if[clonesInfo~"";
    //not clone at all
    if[null .cr.p.clones[pr`prefix];:enlist pr];
    ];
  if[not clonesInfo~"";
    if[all clonesInfo in .Q.n;
      .cr.p.clones[pr`prefix]:"I"$clonesInfo;
      ]; 
    if[not all clonesInfo in .Q.n;
      '`$"invalid clones indicator:'",clonesInfo;
      ];
    ];

  clones:string til .cr.p.clones[pr`prefix];
  new:.cr.p.clones[pr`prefix]#enlist pr;
  new[`prefix]:`$string[pr`prefix],/:"_",/:clones;
  new[`vars]:([]varName:`EC_COMPONENT_INSTANCE;varVal:clones;line:pr`groupParseLine;col:pr`groupParseCol;file:`;errors:count[clones]#enlist 0#`),'new[`vars];
  new
  };

//----------------------------------------------------------------------------//
//----------------------------------------------------------------------------//
  
.cr.p.nestedPar:{[ps]
  res1:.par.many[.cr.p.mySpaces] ps;
  res:.par.char["("] res1;
  cnt:1;
  str:"";
  while[(null res[`errp]) & cnt<>0;
    resAux:.par.many[.par.noneOf["()\n"]] res;
    str:str,resAux[`ast];
    res:.par.oneOf["()\n"] resAux;
    str:str,res[`ast];
    if["("~res[`ast];cnt:cnt+1];
    if[")"~res[`ast];cnt:cnt-1];
    if["\n"~res[`ast];
      res[`errp]:res[`cp];];
    if[cnt<0;
      res[`errp]:res[`cp];];
    ];
  res[`ast]:-1_str;
  :res;
  };
 
//t1:`SYMBOL;t2:`SYMBOL
//.cr.p.typedKvPair[`SYMBOL;`SYMBOL;env;qsdInfo] ps
//.cr.p.typedKvPair[`FLOAT;`INT;()!();()!()] .par.initP "1(2)"
.cr.p.typedKvPair:{[t1;t2;env;qsdInfo;ps]
  res1:.par.many[.cr.p.mySpaces] ps;
  k:.cr.p.parseVal[;qsdInfo;env;t1;0b] res1;
  res2:.par.many[.cr.p.mySpaces] k;
  res3:.par.char["("] res2;
  res4:.par.many[.cr.p.mySpaces] res3;
  v:.cr.p.parseVal[;qsdInfo;env;t2;0b] res4;
  res5:.par.many[.cr.p.mySpaces] v;
  res6:.par.char[")"] res5;
  if [null res6[`errp];
    res6[`ast]:(k[`ast];v[`ast]);
    ];
  :res6;
  }; 
 
.cr.p.kvPair:{[parseInfo;ps]
  id:.cr.p.identifier ps;
  res1:.par.many[.cr.p.mySpaces] id;
  val:.cr.p.nestedPar[res1];
  val[`ast]:(`kvpair;`$id[`ast];val[`ast]);
  :val;
  }; 


//.cr.p.kvPair[();] .par.initP "key()"
 
.cr.p.trimmedColon:{[ps]
  res1:.par.many[.cr.p.mySpaces] ps;
  colon:.par.option[1;.par.char[","]] res1;
  res2:.par.many[.cr.p.mySpaces] colon;
  :res2;
  };
 
 
.cr.p.kvPairs:{[lineInfo;ps]
  res1:.par.sepBy[.cr.p.kvPair[lineInfo];.cr.p.trimmedColon] ps;
  if[null res1[`errp];
    ks:{first 1_x} each res1[`ast];
    vals:last each res1[`ast];
    res1[`ast]:(`kvPairs;ks!vals);
    ];
  :res1;
  };
 
//.cr.p.angleDict[()] .par.initP "<type(PATH), default(${EC_SYS_PATH}/data/${EC_COMPONENT_ID})>"
 
.cr.p.angleDict:{[lineInfo;ps]
  res1:.par.many[.cr.p.mySpaces] ps;
  res2:.par.char["<"] res1;
  res3:.par.many[.cr.p.mySpaces] res2;
  dict: .cr.p.kvPairs[lineInfo;] res3;
  res4:.par.many[.cr.p.mySpaces] dict;
  res5:.par.char[">"] res4;
  res6:.par.many[.cr.p.mySpaces] res5;
  if[`kvPairs~first dict[`ast];
    res6[`ast]:(`angleDict;last dict[`ast]);
    ];
  :res6;  
  };
 
 
//----------------------------------------------------------------------------//
//                              qsd and cfg alignment                         //
//----------------------------------------------------------------------------//
 
 
.cr.p.addAuxQsdVars:{[name;tree]
//  if[99h=type tree;
//    if[cols[tree]~`prefix`suffix`vars;
//         vars:tree;
//         base:exec prefix!vars from vars where suffix=`;
//         vars:update vars:{0!x} each (({1!x} each base[prefix]),' {1!x}each vars) from vars where suffix<>`;
//         toDel:exec prefix from vars where suffix<>`;
//         tree:delete from vars where prefix in toDel, suffix=`;
//      ];
//     ];
  .cr.p.auxQsdVars[name]:$[name in key .cr.p.auxQsdVars;
      select raze vars by prefix,suffix from (0!.cr.p.auxQsdVars[name]), 0!tree;
      tree
      ];
  };
 
//name:`core.rdb;qsdPath:`:rdb.qsd;
//name:cfg`prefix;libPaths:paths;qsdPath:first files
.cr.p.readAuxQsd:{[name;libPaths;qsdPath]
  if[qsdPath~`;:`$"QSD_READ_ERROR: no qsd name defined"];
  if[0=count libPaths;:`$"QSD_READ_ERROR: empty libPath"];

  paths:libPaths {` sv (x;y)}\: `$1_string[qsdPath];
  path:first paths where paths ~' key each paths;
  if[`~path;
    .log.debug[`cr] "No qsd file ",string[qsdPath], " found on the libPath";
    :(::)
    ];

  if[not path in key .cr.p.auxQsdFiles;  
    /qsdTree:.pe.dotLog[`cfgRdr;`.cr.parseCfgFile;(qsdPath;1);`error;`error];
    qsdTree:.pe.dot[.cr.parseCfgFile;(path;1);{`$": ",x}];
    errs:.cr.p.getErr[qsdTree];
    if[0<>count errs;:exec first raze errors from errs];
    qsdSections:qsdTree[`subGroups][`prefix],'qsdTree[`subGroups][`suffix];

    {[name;sections]
      $[sections in key .cr.p.auxQsdMapping;
        .cr.p.auxQsdMapping[sections]:.cr.p.auxQsdMapping[sections],name;
        .cr.p.auxQsdMapping[sections]:enlist name
        ];
      }[name;] each qsdSections;

    .cr.p.auxQsdFiles[path]:qsdTree;
    if[-11h=type qsdTree;
      .cr.p.addAuxQsdVars[name;qsdTree];
      :()];
    ];

  if[-11h=type .cr.p.auxQsdFiles[path];
    .cr.p.addAuxQsdVars[name;.cr.p.auxQsdFiles[path]];
    :()];

  aux:.cr.p.auxQsdFiles[path][`subGroups];
  .cr.p.addAuxQsdVars[name;select  last vars by prefix, suffix from aux];
  };

.cr.p.addAuxQsd:{[cfgType;path;cfg;qsd;auxVars]
  tq:type auxVars;
  if[101h~tq;
    :()];
  if[-11h~tq;
    cfg[`errors],:auxVars;
    :();
    ];
 
  if[path~();
    sections:group[.cr.section2file][cfgType];
    allQsd:raze {`section`varName xkey update section:x from y[`vars]}'[sections;auxVars[sections,\:`]];
    auxQsd:select qsd:last varVal, qsdLine:last line, qsdCol:last col, qsdFile:last file, qsdErr:last errors by varName from allQsd;

    uniqueQsdVars:select first[section], location:(string[first file],":",string[first line],":",string[first col]) by varName, varVal from allQsd;
    if[count mismatchingDuplicates:select from uniqueQsdVars where 1<(count;i) fby varName;
      errors:exec first {`$"QSD_MISMATCH: field also declared with different attributes in section [",string[x],"] in ",y, " - ",.Q.s1[z]}'[section;location;varVal] by varName from mismatchingDuplicates;
      auxQsd:update qsdErr:(qsdErr,'errors[varName]) from auxQsd
      ];
    :auxQsd;
    ];

  res:1!select varName, qsd:varVal, qsdLine:line, qsdCol:col, qsdFile:file, qsdErr:errors from auxVars[(first last path),`][`vars];
  res:res,1!select varName, qsd:varVal, qsdLine:line, qsdCol:col, qsdFile:file, qsdErr:errors from auxVars[last path][`vars];
  :res;
  };

.cr.p.componentToQsd:()!();
.cr.p.includeAdditioalQsd:{[path;parentFields;cfg;qsd]
  if[not cfg[`prefix] in key .cr.p.componentToQsd;
	
	//read commonLibs field - take subsection field if available, otherwise take section field
    commonLibsStr:cfg[`vars;`commonLibs;`cfg]; 
    parentLibsStr:$[parentFields~();"";$[()~pComLibs:parentFields[`commonLibs;`cfg];"";pComLibs]];
    libsList:(),trim "," vs $[not(commonLibsStr~"")|(commonLibsStr~());commonLibsStr;parentLibsStr];
	//read libs field - append to libsList
    if[not ()~libsStr:cfg[`vars;`libs;`cfg];
      libsList,:(),trim["," vs libsStr];
      ];
	//read type field - append to libsList
    if[not ()~typeField:cfg[`vars;`type;`cfg];
      libsList:enlist[last"/" vs typeField],libsList;
      ];

    libsList:libsList except ("";"NULL");
    if[0=count libsList;
      //NOTHING TO LOAD
      :cfg;
      ];

    .cr.p.componentToQsd[cfg[`prefix]]:hsym each`$libsList,\:".qsd";
    if[count typeCfg:select from cfg[`vars] where varName=`type;
      new:update varName:enlist`EC_COMPONENT_PKG, {first "/"vs 2_x}each cfg from typeCfg;
      new,:update varName:enlist`EC_COMPONENT_TYPE, {last "/"vs 2_x}each cfg from typeCfg;
      cfg[`vars]:new,cfg[`vars];
      ];
    ];

  paths:(parentFields uj qsd[`vars]) uj cfg[`vars];
  paths:update defaultUsed:1b,cfg:qsd[;`default] from paths where null cfgLine, `default in' key'[qsd];
  paths:update fieldType:`$qsd@\:`type from paths where not null qsdLine;
  paths:update validators:{((key x) inter (key `.cr.v))#x} each qsd from paths;
  paths:.pe.dot[.cr.p.evalVars;(cfg`prefix;paths);{[path;sig]`$"VARS_EVALUATION_FAILED: path: ",.Q.s1[path],", signal: ",sig}[path;]]; // signal should never happen
  paths:$[99=type paths;raze exec varVal from paths where varName=`libPath;`$()];
  res:{[prefix;paths;file] .pe.dot[.cr.p.readAuxQsd;(prefix;paths;file);{`$x}]}[cfg`prefix;paths;] each .cr.p.componentToQsd[cfg[`prefix]];
  cfg[`errors],:res[where -11h=type each res];
  :cfg;
  };

.cr.p.alignTrace:();
.cr.p.align:{[cfgType;path;parentFields;cfg;qsd;services;isSync]
  if[`DEBUG~.log.level;
    .cr.p.alignTrace,::enlist`cfgType`path`parentFields`cfg`qsd`services`isSync!(cfgType;path;parentFields;cfg;qsd;services;isSync); 
    ];
  
  cfg[`vars]:1!select varName, cfg:varVal, cfgLine:line, cfgCol:col, cfgFile:file, cfgErr:errors from cfg[`vars];
  qsd[`vars]:1!select varName, qsd:varVal, qsdLine:line, qsdCol:col, qsdFile:file, qsdErr:errors from qsd[`vars];
  if[(cfgType~`system) & (cfg[`prefix] in `,key[.cr.section2file],services);
    cfg:.cr.p.includeAdditioalQsd[path;parentFields;cfg;qsd];
    ];
  if[1=count path;
    extensions:distinct .cr.p.auxQsdMapping[cfg`prefix`suffix];
    extensions:extensions except $[0<>count cfg[`subGroups];exec prefix from cfg[`subGroups];()];
    cfg[`subGroups]:cfg[`subGroups],{[ext] :`prefix`prefixAux`suffix`suffixAux`groupParseLine`groupParseCol`vars`subGroups`errors!
    (ext;()!();`;()!();0N;0N;.cr.p.varModel;();0#`)} each extensions;
    if[0=count qsd[`subGroups];
      qsd[`subGroups]:enlist `prefix`prefixAux`suffix`suffixAux`groupParseLine`groupParseCol`vars`subGroups`errors!
                               (`;`type`isComponent!(`SYMBOL;"");`;()!();0N;0N;.cr.p.varModel;();0#`)
      ];
    ];
  qsd[`vars],:.cr.p.addAuxQsd[cfgType;path;cfg;qsd;] .cr.p.auxQsdVars[cfg`prefix];

  vars:(parentFields uj qsd[`vars]) uj cfg[`vars];
  vars:update qsd:{[x] ()!()} each qsd  from vars where null qsdLine;
  vars:update defaultUsed:1b,cfg:qsd[;`default] from vars where null cfgLine, `default in' key'[qsd];
  if[count e:select from vars where null cfgLine, null qsdLine ;cfg[`errors],:`$"UNSUPPORTED_FIELDS: `",exec "`" sv string varName from e];
  vars:update fieldType:`$qsd@\:`type from vars where not null qsdLine, 0=count each qsdErr;
  vars:update cfgErr:`$"INVALID_QSD_DEF - cannot parse field" from vars where not null qsdLine, 0<>count each qsdErr;
  vars:update validators:{((key x) inter (key `.cr.v))#x} each qsd from vars where not null qsdLine;
  vars:update validators:{()!()} each qsd from vars where null qsdLine;
  vars:select from vars where {[isSync;x] $[isSync;`syncOnly in key x;not `syncOnly in key x]}[isSync] each validators;

  if[count cfg[`subGroups];
    mergedGroups:([]prefix:cfg[`subGroups][`prefix];cfg:cfg[`subGroups]);
    if[` in qsd[`subGroups][`prefix];
      mergedGroups:mergedGroups cross ([]qsd:select from qsd[`subGroups] where prefix=`);
      ];
    mergedGroups:mergedGroups lj([prefix:qsd[`subGroups][`prefix]]qsd:qsd[`subGroups]);
    if[count e:select from mergedGroups where 0=count each qsd;cfg[`errors],:`$"UNSUPPORTED_GROUPS: `","`" sv string distinct e`prefix];
    cfg[`subGroups]:.cr.p.align[cfgType;path,enlist cfg`prefix`suffix;vars;;;services]'[mergedGroups`cfg;mergedGroups`qsd;isSync];
   ];
  cfg[`vars]:vars;
  :cfg;
  };
 
 
//----------------------------------------------------------------------------//
//                              error messages                                //
//----------------------------------------------------------------------------//
.cr.p.getErrAux:{[prevErrs;cfg]
  errors:update section:cfg`prefix from ([]section:`; errors:cfg[`errors]),prevErrs;
  :$[count cfg[`subGroups];
     raze .cr.p.getErrAux[errors;]'[cfg[`subGroups]];
     errors
    ];
  };
 
.cr.p.getErr:.cr.p.getErrAux[();];

 
//------------------------ATOMIC PARSERS -------------------------------------//
 
/F/ Parses a symbol. Symbol can be any string that does not contain ")", spaces are stripped from both sides
/R/ :SYMBOL - the parsed symbol
.cr.atomic.symbol:{[ps]
  res:.cr.atomic.string ps;
  if[null res[`errp];
    s:res[`ast];
    res[`ast]:`$s
    ];
    :res;
    };
  
/F/ parses a float
.cr.atomic.float:{[ps]
  ps1:.par.many1[.par.oneOf"1234567890."] ps;
  if[0N <> ps1`errp;:.par.addErr[ps1;"failed to parse a float, forbidden character"]];
  .par.p.error:0b;
  val:.pe.at[{`float$ parse x};ps1`ast;{.par.p.error:1b}]; // we may have multiple dots
  if[.par.p.error;
    ps1[`errp]:ps`cp;
    ps1[`ast]:enlist "failed to parse ",(.Q.s1 ps1`ast)," to a float ";
    :ps1
    ];
  ps1[`ast]:val;
  :ps1
  };

.cr.atomic.real:{[ps]
  ps1:.par.many1[.par.oneOf"1234567890."] ps;
  if[0N <> ps1`errp;:.par.addErr[ps1;"failed to parse a float, forbidden character"]];
  .par.p.error:0b;
  val:.pe.at[{`real$ parse x};ps1`ast;{.par.p.error:1b}]; // we may have multiple dots
  if[.par.p.error;
    ps1[`errp]:ps`cp;
    ps1[`ast]:enlist "failed to parse ",(.Q.s1 ps1`ast)," to a float ";
    :ps1
    ];
  ps2:.par.option[1;.par.char["e"]] ps1;
  ps2[`ast]:val;
  :ps2;
  };

  
//float .par.initP "2.3"
//float .par.initP "2.3 " // ok
//float .par.initP "2.3.3 " // error
//float .par.initP "2 .3 " // ok, but parses only 2 to 2.0
 
/F/ parses an int
.cr.atomic.int:{[ps]
  sign:.par.option["+";.par.char["-"]] ps;
  ps1:.par.many1[.par.oneOf"1234567890"] sign;
  if[0N <> ps1`errp;:.par.addErr[ps1;"failed to parse an int, forbidden character"]];
  .par.p.error:0b;
  val:.pe.at[{`int$ parse x};ps1`ast;{.par.p.error:1b}]; // just in case, although probably no way to fail
  if[.par.p.error;
    ps1[`errp]:ps`cp;
    ps1[`ast]:enlist "failed to parse ",(.Q.s1 ps1`ast)," to int ";
    :ps1
    ];
  ps1[`ast]:`int$($[sign[`ast]="+";val;(-1)*val]);
  :ps1
  };
 
.cr.atomic.short:{[ps]
   res:.cr.atomic.int ps;
   if[null res[`errp];
     res[`ast]:`short$res[`ast];   
     ];
   :res;
   };
   
   
//int .par.initP "0123 "
 
/F/ parses a long
.cr.atomic.long:{[ps]
  sign:.par.option["+";.par.char["-"]] ps;
  ps1:.par.many1[.par.oneOf"1234567890"] sign;
  if[0N <> ps1`errp;:.par.addErr[ps1;"failed to parse a long, forbidden character"]];
  .par.p.error:0b;
  val:.pe.at[{`int$ parse x};ps1`ast;{.par.p.error:1b}]; // just in case, although probably no way to fail
  if[.par.p.error;
    ps1[`errp]:ps`cp;
    ps1[`ast]:enlist "failed to parse ",(.Q.s1 ps1`ast)," to long";
    :ps1
    ];
  ps1[`ast]:`long$($[sign[`ast]="+";val;(-1)*val]);
  :ps1
  };

.cr.atomic.byte:{[ps]
  '"byte parser not yet implemented!" 
  };

.cr.atomic.second:{[ps]
  '"second parser not yet implemented!"
  };
 
//.cr.atomic.string .par.initP "asd\\(asdasd\\) zxc"
.cr.atomic.clearString:.cr.p.escString[.Q.a,.Q.A,"0123456789!@#$%^&*()<>{}\\/|:;,.-=+_' "];
.cr.atomic.quotedString:{[ps]
  res1:.par.char["\""] ps;
  res2:.cr.p.escString[.Q.a,.Q.A,"0123456789!@#$%^&*()<>{}\\/|:;,.-=+_' "] res1;
  res3:.par.char["\""] res2;
  if[null res3`errp;res3[`ast]:"\"",res2[`ast],"\""];
  :res3;
  };
 
.cr.atomic.string:.par.choice[(.cr.atomic.quotedString;.cr.atomic.clearString)];
 
.cr.atomic.litdir:.cr.p.identifier;
 
// like ${KDB_ROOT} varsd is a dictionary variable name ->  value, we assume fully resolved. If not found, getenv is tried
.cr.atomic.vardir:{[ps]
  ps1:.par.between[.par.pstring"${";.par.char"}";.cr.p.symIdentifier] ps;
  if[0N<>ps1`errp;
  :.par.addErr[ps1;"not a variable"]];
  :ps1;
  };
 
// directory name: literal or from a variable
.cr.atomic.dir:{[ps]
  ps1:.par.many1[(.par.choice (.cr.atomic.litdir;.cr.atomic.vardir));] ps;
  if[0N <> ps1`errp; ps1[`ast]:(enlist "failed to parse directory name"),ps1[`ast]];
  :ps1;
  };
 
// windows specific: path may start from this
.cr.atomic.drive:{[ps]
  ps2:.par.pstring[":/"] ps1:.par.oneOf[.Q.A,.Q.a] ps;
  ps2[`ast]:ps1[`ast],ps2[`ast];
  :ps2
  };
 
.cr.atomic.hostname:{[ps]
  res1: .par.many1[.par.oneOf[.Q.a,.Q.A,"0123456789."]] ps;
  res2: .par.char[":"] res1;
  if[null res2[`errp];
    res2[`ast]:res1[`ast],res2[`ast];
    ];
  :res2;
  };
 
// various possible prefixes
.cr.atomic.prefix:.par.choice (.cr.atomic.drive;.par.pstring["../"];.par.pstring["./"];.par.pstring["//"];.par.pstring[enlist "/"]);
 
/P/ env:DICTIONARY[SYMBOL;STRING] - environment variables
/P/ t:DICTIONARY[SYMBOL;SYMBOL] - column types
.cr.atomic.column:{[model;env;ps]
  ps1:.cr.p.identifier ps;
  if[0N <> ps1`errp;:.par.addErr[ps1;"failed to parse column name"]];
  col:`$ps1`ast;
  if[not col in key model;
    ps1[`errp]:ps`cp;
    :.par.addErr[ps1;"unknown type of column ",string col];
    ];
  ps4:.par.char[")"] .par.spaces ps3:.cr.p.parseVal[;()!();env;model[col];0b] .par.spaces ps2:.par.char["("] ps1;
  if[0N <> ps2`errp;:ps2];
  if[0N <> ps3`errp;:.par.addErr[ps3;"failed to parse string with column value"]];
  if[0N <> ps4`errp;:.par.addErr[ps4;"expected the closing parenthesis"]];
 
  ps4[`ast]:(col;ps3`ast);
  :ps4
  };
 
 
/F/ parses a comma with possibly spaces around
.cr.atomic.separator:{[ps] .par.spaces .par.char[","] .par.spaces ps};
 
/F/ parses a single row
/P/ t:DICTIONARY[SYMBOL;SYMBOL] - a dictionary mapping columns to their types
.cr.atomic.row:{[model;env;ps]
  ps4:.par.char[")"] .par.spaces ps3:.par.sepBy1[.cr.atomic.column[model;env];.cr.atomic.separator] .par.spaces ps2:.par.char["("] ps;
  if[0N <> ps2`errp;:ps2];
  if[0N <> ps3`errp;:.par.addErr[ps3;"expected a list of columns separated by commas"]];
  if[0N <> ps4`errp;:ps4];
  ps4[`ast]:ps3`ast;
  :ps4
  };
 
.cr.atomic.p.twodigits:.par.pcount[2;.par.digit];
 
.cr.atomic.p.frac:{[ps] 
  ps2:.par.many[.par.digit] ps1:.par.char["."] ps;
  if[0N<>ps1`errp;:ps1];
  ps2[`ast]:ps1[`ast],ps2`ast;
  :ps2
  };
 
/frac .par.initP ".0234 "
 
 
.cr.atomic.p.secs:{[ps]
  ps2:.par.option["";.cr.atomic.p.frac] ps1: .cr.atomic.p.twodigits .par.char[":"] ps;
  if[0N<>ps1`errp;ps1[`cp]:ps`cp;:ps1];
  ps2[`ast]:":",ps1[`ast],ps2`ast;
  :ps2
  };
 
/secs .par.initP ":20"
/secs .par.initP ":20.023"
/secs .par.initP "20"
 
.cr.atomic.p.minutes:{[ps]
  ps2:.par.option["";.cr.atomic.p.secs] ps1: .cr.atomic.p.twodigits ps;
  if[0N<>ps1`errp;:ps1];
  ps2[`ast]:ps1[`ast],ps2`ast;
  :ps2
  };
 
/minutes .par.initP "20:30.5"
/minutes .par.initP "20"
 
.cr.atomic.datetime:{[ps]
  date:.cr.atomic.date ps;
  res1:.par.oneOf[" D"] date;
  time:.cr.atomic.time res1;
  if[null time[`errp];
    time[`ast]:`datetime$date[`ast] + time[`ast];
    ];
    :time;
  };
 
.cr.atomic.time:{[ps]
  if[0N<>ps`errp;:ps];
  ps2:.cr.atomic.p.minutes .par.char[":"] ps1:.cr.atomic.p.twodigits ps;
  if[0N<>ps2`errp;ps2[`cp]:ps`cp;:.par.addErr[ps2;"failed to parse time"];:ps2];
  tst:ps1[`ast],":",ps2[`ast];
  .par.p.error:0b;
  val:.pe.at[{`time$ parse x};tst;{.par.p.error:1b}];
  if[.par.p.error;
    ps2[`cp]:ps`cp;
    ps2[`errp]:ps`cp;
    ps2[`errs]:enlist "failed to convert string \"",tst,"\" to time";
    ps2[`ast]:ps`ast;
    :ps2
    ];
  ps2[`ast]:val;
  :ps2
  };
 
.cr.atomic.date:{[ps]
  if[0N<>ps`errp;:ps];
  ps4:.cr.atomic.p.twodigits .par.char["."] ps3:.cr.atomic.p.twodigits .par.char["."] ps2:.cr.atomic.p.twodigits  ps1:.cr.atomic.p.twodigits ps;
  if[0N<>ps4`errp;ps4[`cp]:ps`cp;ps4[`ast]:ps`ast;.par.addErr[ps4;"failed to parse date"];:ps4];
  dst:ps1[`ast],ps2[`ast],".",ps3[`ast],".",ps4[`ast];
  .par.p.error:0b;
  val:.pe.at[{`date$ parse x};dst;{.par.p.error:1b}];
  if[.par.p.error;
    ps[`errp]:ps[`cp];
    ps[`errs]:enlist "failed to convert string \"",dst,"\" to date";
    :ps
    ];
  ps4[`ast]:val;
  :ps4;
  };
 
//.cr.atomic.timestamp .par.initP "2013.04.09D13:21:12.674612000"
.cr.atomic.timestamp:{[ps]
  date:.cr.atomic.date ps;
  r:.par.char["D"] date;
  time: .cr.atomic.time r;
  if[null time[`errp];
    time[`ast]:date[`ast]+time[`ast];
    ];
  :time;
  };
 
.cr.atomic.timespan:{[ps]
  days:.cr.atomic.int ps;
  r:.par.char["D"] days;
  time: .cr.atomic.time r;
  if[null time[`errp];
    time[`ast]:(`timespan$time[`ast]) + 1D*days[`ast];
    ];
  :time;
  };
 
 
.cr.atomic.char:.par.anyChar;
 
.cr.atomic.boolean:{[ps]
  res:.par.choice[(.par.oneOf["01"];.par.pstring["TRUE"];.par.pstring["FALSE"])] ps;
  if[res[`ast]~"TRUE";res[`ast]:"1"];
  if[res[`ast]~"FALSE";res[`ast]:"0"];
  if[null res[`errp];
    res[`ast]:"B"$res[`ast];
    ];
  :res;
  };
 
.cr.atomic.stringList:{[ps]
  res:.par.sepBy[.par.many1[.par.noneOf[enlist ","]];.par.char[","]] ps;
  if[null res[`errp];
    res[`ast]:trim each res[`ast];
    ];
  :res;
  };
 
.cr.atomic.symbolList:{[ps]
  res:.cr.atomic.stringList ps;
  if[null res[`errp];
    res[`ast]:`$res[`ast];
    ];
  :res;
  };
 
.cr.p.trimmingComa:{[ps]
  res1:.par.many[.cr.p.mySpaces] ps;
  res2:.par.try[.par.char[","]] res1;
  res3:.par.many[.cr.p.mySpaces] res2;
  :res3;
  };
 
 
.cr.atomic.guid:{[ps]
  part1:.par.pcount[8;.cr.p.byte] ps;
  sep1:.par.char["-"] part1;
  part2:.par.pcount[4;.cr.p.byte] sep1;
  sep2:.par.char["-"] part2;
  part3:.par.pcount[4;.cr.p.byte] sep2;
  sep3:.par.char["-"] part3;
  part4:.par.pcount[4;.cr.p.byte] sep3;
  sep4:.par.char["-"] part4;
  part5:.par.pcount[12;.cr.p.byte] sep4;
  if[null part5[`errp];
    part5[`ast]:"G"$part1[`ast],"-",part2[`ast],"-",part3[`ast],"-",part4[`ast],"-",part5[`ast];
    ];
  :part5;
  };
 
// dictionary mapping types to parsers. The path parser expands variables, provided in env
.cr.atomic.parsers:()!();
.cr.atomic.parsers[`SYMBOL]:.cr.atomic.symbol;
.cr.atomic.parsers[`FLOAT]:.cr.atomic.float;
.cr.atomic.parsers[`REAL]:.cr.atomic.real;
.cr.atomic.parsers[`STRING]:.cr.atomic.string;
.cr.atomic.parsers[`INT]:.cr.atomic.int;
.cr.atomic.parsers[`SHORT]:.cr.atomic.short;
.cr.atomic.parsers[`LONG]:.cr.atomic.long;
.cr.atomic.parsers[`DATE]:.cr.atomic.date;
.cr.atomic.parsers[`TIME]:.cr.atomic.time;
.cr.atomic.parsers[`DATETIME]:.cr.atomic.datetime;
.cr.atomic.parsers[`TIMESTAMP]:.cr.atomic.timestamp;
.cr.atomic.parsers[`TIMESPAN]:.cr.atomic.timespan;
.cr.atomic.parsers[`CHAR]:.cr.atomic.char;
.cr.atomic.parsers[`BOOLEAN]:.cr.atomic.boolean;
.cr.atomic.parsers[`GUID]:.cr.atomic.guid;
.cr.atomic.parsers[`BYTE]:.cr.atomic.byte;
.cr.atomic.parsers[`SECOND]:.cr.atomic.second;
 
// required for feedCsv
.cr.p.simpleDataTypes:`BOOLEAN`SHORT`INT`LONG`REAL`FLOAT`CHAR`SYMBOL`TIME`DATE`DATETIME`TIMESTAMP`TIMESPAN`GUID`BYTE`SECOND!("B";"H";"I";"J";"E";"F";"C";`;"T";"D";"Z";"P";"N";"G";"X";"V");
 
// adding list support
.cr.atomic.parsers,:({`$" LIST ",string[x]} each (key .cr.atomic.parsers) except `STRING`SYMBOL)!{[ps] .par.sepBy[ps;.cr.p.trimmingComa]} each .cr.atomic.parsers[(key .cr.atomic.parsers) except `STRING`SYMBOL];
.cr.atomic.parsers[`$"LIST STRING"]:.cr.atomic.stringList;
.cr.atomic.parsers[`$"LIST SYMBOL"]:.cr.atomic.symbolList;
 
// dictionary mapping types to q null values
.cr.atomic.nulls:()!();
.cr.atomic.nulls[`STRING]:"";
.cr.atomic.nulls[`SYMBOL]:`;
.cr.atomic.nulls[`FLOAT]:0n;
.cr.atomic.nulls[`REAL]:0ne;
.cr.atomic.nulls[`INT]:0Ni;
.cr.atomic.nulls[`SHORT]:0Nh;
.cr.atomic.nulls[`LONG]:0Nj;
.cr.atomic.nulls[`DATE]:0Nd;
.cr.atomic.nulls[`TIME]:0Nt;
.cr.atomic.nulls[`DATETIME]:0Nz;
.cr.atomic.nulls[`TIMESTAMP]:0Np;
.cr.atomic.nulls[`TIMESPAN]:0Nn;
.cr.atomic.nulls[`CHAR]:" ";
.cr.atomic.nulls[`BOOLEAN]:0b;
.cr.atomic.nulls[`GUID]:0Ng;
.cr.atomic.nulls[`BYTE]:0x00;
.cr.atomic.nulls[`SECOND]:0Nv;

.cr.atomic.nulls,:({`$" LIST ",string[x]} each key .cr.atomic.nulls)!{0#.cr.atomic.nulls[x]} each key .cr.atomic.nulls;
 
.cr.atomic.nullParsers:{[tp;eol;ps]
  /try to parse null first
  res1:.par.many[.cr.p.mySpaces] ps;
  res2:.par.choice[(.par.pstring["NULL"];.par.pstring[.Q.s1[.cr.atomic.nulls[tp]]])] res1;
  res3:.par.many[.cr.p.mySpaces] res2;
  res4:$[eol;.par.eof res3;res3];
  if[null res4[`errp];
    res4[`ast]:.cr.atomic.nulls[tp];
    :res4;
    ];
  
  // not null value
  res2:.cr.atomic.parsers[tp;ps];
  res3:.par.many[.cr.p.mySpaces] res2;
  res4:$[eol;.par.eof res3;res3];
  $[null res4[`errp];
    res4[`ast]:res2[`ast];
    res4[`errs]:enlist "parsing failed"
    ];
  :res4;
  };
//-------------------------- ARITHMETIC PARSER -------------------------------//
 
.cr.arith.number: {[ps]
  ps1: .par.many1[.par.digit] ps;
  if[0N <> ps1`errp; 
    ps1[`ast]:(enlist "number parsing failed"),ps1[`ast];
    :ps1];
  ps1[`ast]:value ps1`ast;
  :ps1;
  };

.cr.arith.variable:{[ps]
  ps1:.par.pstring["${"] ps;
  ps2:.cr.p.symIdentifier ps1;
  ps3:.par.char["}"] ps2;
  if[0N <> ps1`errp; :ps1];
  if[0N <> ps2`errp; :ps2];
  if[0N <> ps3`errp; :ps3];
  ps3[`ast]:ps2`ast;
  :ps3
  };
 
.cr.arith.trimmedPar:{[par;ps]
  res1:.par.many[.par.oneOf[" \t"]] ps;
  res2:par res1;
  res3:.par.many[.par.oneOf[" \t"]] res2;
  if[null res3[`errp];
    res3[`ast]:res2[`ast];
    ];
  :res3;
  };

.cr.arith.atom:.cr.arith.trimmedPar[.par.choice (.cr.arith.variable;.cr.arith.number)];

.cr.arith.mulop:{[ps]
  ps1:(.cr.arith.trimmedPar[.par.char "*"]) ps;
  if[0N <> ps1`errp; :ps1];
  ps1[`ast]:{(`$"*";(x;y))};
  :ps1;
  };

.cr.arith.addop:{[ps]
  ps1:.cr.arith.trimmedPar[.par.choice (.par.char "+";.par.char "-")] ps;
  if[0N <> ps1`errp; :ps1];
  ps1[`ast]:$["+"~ps1[`ast];{(`$"+";(x;y))};{(`$"-";(x;y))}];
  :ps1;
  };

.cr.arith.prod:{[ps]
  ps1: .par.chainl1[.cr.arith.atom;.cr.arith.mulop] ps;
  if[0N <> ps1`errp; 
    ps1[`ast]:(enlist "prod: parse error"),ps1[`ast];
    :ps1
    ];
  :ps1
  };

.cr.arith.expr:{[ps]
  ps2:.par.eof ps1:.par.chainl1[.cr.arith.prod;.cr.arith.addop] ps;
  if[0N <> ps1`errp; 
    ps1[`errs]:(enlist "expression parse error"),ps1[`errs];
    :ps1];
  if[0N <> ps2`errp;
    ps2[`errs]:(enlist "arithmetic expression parsing failed");
    :ps2];
  :ps1
  };

.cr.arith.p.funcMapping:(`$"*";`$"+";`$"-")!(*;+;-);
 
.cr.arith.eval:{[vars;expr]
  t:type expr;
  if [-11=t; // variable
    $[expr in key vars;
      :vars[expr];
      :`$"variable ",string[expr]," not in environment"
     ];
       ];
    if[t>=0;  // compound expression
    op:first expr;
    if[not op in key .cr.arith.p.funcMapping;
      :`$"function operator \"",string[op], "\"not recognized";
      ];
    args: .cr.arith.eval[vars;] each expr[1];
    errs:args where -11h=type each args;
    if[0<>count errs;:errs];
    :.[.cr.arith.p.funcMapping[op];args];
    ];
  :expr; // presumably number
  };
 
.cr.arith.port:{[env;ps]
  res:.cr.arith.expr ps;
  if [null res[`errp];
    e:.cr.arith.eval[env;res[`ast]];
    $[11h=type e;
      [
        res[`errs]:res[`errs],string each e;
        res[`errp]:res[`cp];
        ];
      res[`ast]:e
      ];
    ];
  :res;
  };
 
//------------------------ COMPOUND PARSERS -------------------------------------//
 
/F/ parses a table as a list of rows separated by commas
/model:mdl
/env
/ps:aps
.cr.compound.array:{[env;qsdInfo;ps]
  model:qsdInfo[`model];
  md:.par.sepBy[.cr.p.typedKvPair[`STRING;`STRING;env;qsdInfo];.cr.p.trimmingComa] .par.initP model;
  if[not null md[`errp];:md];
  model:(`$first each md[`ast])!(`$last each md[`ast]);
  ps4:.par.char[")"] .par.spaces ps3:.par.sepBy[.cr.atomic.row[model;env];.cr.atomic.separator] .par.spaces ps2:.par.char["("] ps;
  if[0N <> ps2`errp;:ps2];
  if[0N <> ps3`errp;:.par.addErr[ps3;"expected a list of rows separated by commas"]];
  if[0N <> ps4`errp;:ps4];
 
 
  nd:(key model)!.cr.atomic.nulls[value model]; 
  // empty table case
  if[0 = count ps3`ast;
    ps4[`ast]:0#flip (key model)!enlist each .cr.atomic.nulls[value model];
    :ps4;
    ];
  ps4[`ast]: nd ,/: {[L] ({x[0]} each L)!({x[1]} each L)} each ps3`ast;
  :ps4
  };

// env:()!(); qsdInfo:()!(); ps: .par.initP "/asd/zxc"
// .cr.compound.path[env;qsdInfo;ps]
// the main parser for path, note this does not force the end of file
.cr.compound.path:{[env;qsdInfo;ps]
  isNull:.par.eof .par.spaces .par.pstring["NULL"] ps;
  if[null isNull[`errp];isNull[`ast]:`$":";:isNull];
  path:.par.many1[.par.noneOf[",\n<>()"]] ps;
  if[0N <> path`errp;path[`errs]:(enlist "failed to parse a path ",(.Q.s1 ps`s)),path[`ast];:path];
  path[`ast]:hsym `$ trim ssr[path[`ast];enlist "\\";enlist "/"];
  :path;
  };

.cr.compound.pathList:{[env;qsdInfo;ps]
  paths:.par.sepBy[.cr.compound.path[env;qsdInfo;];.cr.p.trimmingComa] ps;
  :paths;
  };
 
.cr.compound.component:{[env;qsdInfo;ps]
  isNull:.par.eof .par.spaces .par.pstring["NULL"] ps;
  if[null isNull[`errp];isNull[`ast]:`;:isNull];
  comp:.par.many1[.par.noneOf[",\n<>()"]] ps;
  if[0N <> comp`errp;comp[`errs]:(enlist "failed to parse COMPONENT ",(.Q.s1 ps`s)),comp[`ast];:comp];
  comp[`ast]:`$comp[`ast];
  :comp;
  };
 
.cr.compound.componentType:{[env;qsdInfo;ps]
  isNull:.par.eof .par.spaces .par.pstring["NULL"] ps;
  if[null isNull[`errp];isNull[`ast]:`;:isNull];
  comp:.par.many1[.par.noneOf[",\n<>()"]] ps;
  if[0N <> comp`errp;comp[`errs]:(enlist "failed to parse COMPONENT ",(.Q.s1 ps`s)),comp[`ast];:comp];
  comp[`ast]:`$comp[`ast];
  :comp;
  };

.cr.compound.componentList:{[env;qsdInfo;ps]
  comps:.par.sepBy[.cr.compound.component[env;qsdInfo;];.cr.p.trimmingComa] ps;
  comps[`ast]:raze {$[x in key .cr.p.clones;`$string[x],/:"_",/:string til .cr.p.clones[x];x]} each comps[`ast]; 
  :comps;
  };

.cr.compound.componentTypeList:{[env;qsdInfo;ps]
  comps:.par.sepBy[.cr.compound.componentType[env;qsdInfo;];.cr.p.trimmingComa] ps;
  comps[`ast]:raze {$[x in key .cr.p.clones;`$string[x],/:"_",/:string til .cr.p.clones[x];x]} each comps[`ast]; 
  :comps;
  };

.cr.compound.port:{[env;qsdInfo;ps] .cr.arith.port[env;ps]};
 
//qsdInfo:qq
//ps:p
//env:e
.cr.compound.table:{[env;qsdInfo;ps]
  if[not all `col1`col2 in key qsdInfo;
    res3[`errs]:res3[`errs],"Lacking col1 & col2 definitions";
    ];
  col1Type:`$qsdInfo[`col1];
  col2Type:`$qsdInfo[`col2];
  res:.par.sepBy[.cr.p.typedKvPair[col1Type;col2Type;env;qsdInfo];.cr.p.trimmingComa] ps;
  ps2:.par.spaces res;
  ps3:.par.eof ps2;
  ps3[`ast]:res[`ast];
  $[null ps3[`errp];
    ps3[`ast]:([] col1:first each ps3[`ast];col2:last each ps3[`ast]);
    ps3[`errs]:enlist "table parsing failed"
    ];
  :ps3;
  };

.cr.compound.parsers:()!();
.cr.compound.parsers[`PATH]:.cr.compound.path;
.cr.compound.parsers[`$"LIST PATH"]:.cr.compound.pathList;
.cr.compound.parsers[`COMPONENT]:.cr.compound.component;
.cr.compound.parsers[`COMPONENT_TYPE]:.cr.compound.componentType;
.cr.compound.parsers[`$"LIST COMPONENT"]:.cr.compound.componentList;
.cr.compound.parsers[`$"LIST COMPONENT_TYPE"]:.cr.compound.componentTypeList;
.cr.compound.parsers[`PORT]:.cr.compound.port;
.cr.compound.parsers[`TABLE]:.cr.compound.table;
.cr.compound.parsers[`ARRAY]:.cr.compound.array;
 
 
// ====================================================
 
//txt:varText
//tp:varType
//qsdInfo:varQsd
//ps: .par.initP txt
 
.cr.p.parseVal:{[ps;qsdInfo;env;tp;eol]
  isAtomic:tp in key .cr.atomic.parsers;
  isCompound:tp in key .cr.compound.parsers;
  if[not isAtomic | isCompound; ps[`errp]:ps[`cp];:.par.addErr[ps;"type ",string[tp], " unknown"]];
  parser:$[isAtomic;.cr.atomic.nullParsers[tp;eol];.cr.compound.parsers[tp;env;qsdInfo]];
  res:parser ps;
  :res;
  };
 
.cr.p.eval:{[ps;qsdInfo;env;tp;debugInfo]
  res:.cr.p.parseVal[ps;qsdInfo;env;tp;1b];
  if[not null res[`errp];
    res[`ast]:.cr.atomic.nulls[tp];
    error:"VALUE_PARSING_ERROR: variable ",string[debugInfo[`varName]],": ",", " sv res[`errs];
    if[not null debugInfo[`cfgFile];
      error:error,", defined in ",string[debugInfo[`cfgFile]],":",string[debugInfo[`cfgLine]],",",string[debugInfo[`cfgCol] + res[`errp]];
      ];
    if[not null debugInfo[`qsdFile];
      error:error,", imposed by schema ",string[debugInfo[`qsdFile]],":",string[debugInfo[`qsdLine]],",",string[debugInfo[`qsdCol]];
      ];
    res[`errs]:enlist error;
    ];
  
  :`val`err!(res[`ast];res[`errs]);
  };
 
/F/ takes a shortcut resolving vars textually without parsing
/P/ env:DICTIONARY[SYMBOL;STRING] - a dictionary from variable name to value
/P/ text:STRING - the input string
/R/ :STRING the string with resolved variables
.cr.p.resolveVars:{[env;text]
  if[0~count text;:""];
  //first position of "${"
  didx:({[txt;i] "${"~txt(i;i+1)}[text] each til -1 + count text)?1b;
  if[didx~-1+count text;:text];
  clidx:(didx _text)?"}"; // closing } position
  if[clidx~count didx _text;:text]; // error, did not find closing "}", return as is
  vname:`$2_(didx _text) til clidx;
  if[vname in key env;
    env[vname]:raze string env[vname];
    res:(text til didx),env[vname],.cr.p.resolveVars[env;(1+didx+clidx)_text];
    :res;
    ];
    // not in env, try to get from environment
  if[0<count val:getenv vname;:(text til didx),val,.cr.p.resolveVars[env;(1+didx+clidx)_text]];
  // unresolved, leave as is
  :(text til (1+didx+clidx)),.cr.p.resolveVars[env;(1+didx+clidx)_text]
  };

.cr.p.evalVars:{[componentId;vars]
  res:([varName:enlist `] varVal:enlist (); parseErr:enlist ());
  env:(enlist `EC_COMPONENT_ID)!(enlist string[componentId]);
  i:0;
  while[i<count vars;
    v:(value vars)[i];
    varId:(key vars)[i;`varName];
    v[`varName]:varId;
    r:.cr.p.evalOneVar[v;env];
    res:res,1!flip flip enlist `varName`varVal`parseErr!(varId;r[`val];`$r[`err]);
    env:env,(enlist varId)!(enlist $[v[`fieldType]~`PATH; `$1_string r[`val];r[`val]]); //exception for PATH type -> ":" prefix removed for env vars resolving
    i:i+1;
    ];
    vars:vars lj res;
    vars:$[0=count vars;update validationErr:` from 0!vars;.cr.p.validate each 0!vars];
    :1!vars;
  };
 
.cr.p.evalOneVar:{[v;env]
  varId:v[`varName];
  varType:v[`fieldType];
  varText:.cr.p.resolveVars[env;v[`cfg]];
  varQsd:v[`qsd];
  debugInfo:`cfgFile`cfgLine`cfgCol`qsdFile`qsdLine`qsdCol`varName!v[`cfgFile`cfgLine`cfgCol`qsdFile`qsdLine`qsdCol`varName];
  //varText:.cr.p.resolveVars[env;varText];

  r:$[null varType;
      $[null debugInfo`qsdLine;
        `val`err!(`$();enlist "MISSING_QSD_INFO: ", string[varId], ", defined in  ",1_string[debugInfo`cfgFile],":",string[debugInfo`cfgLine]);
        `val`err!(`$();enlist "MISSING_TYPE_INFO: ", string[varId], ", imposed by schema ",1_string[debugInfo`qsdFile],":" ,string[debugInfo`qsdLine])
        ];
      .pe.dot[.cr.p.eval;(.par.initP varText;varQsd;env;varType;debugInfo);{`$x}]
      ];
  if[-11h=type r;
    r:`val`err!(`$();enlist "VAR_EVALUATION_FAILED: ",string[debugInfo`varName],": ",string[r],.cr.p.genErrorLoc[debugInfo]);     
    ];
  if[(not null debugInfo`qsdLine) & (not v[`defaultUsed]) & (null debugInfo`cfgLine);
    r[`err]:enlist  raze "MISSING_ENTRY: ", string[varId]," for service ",string[env[`EC_COMPONENT_ID]], ", imposed by schema ",1_string[debugInfo`qsdFile],":" ,string[debugInfo`qsdLine];
    ];
  :r;
  };
   
.cr.p.genErrorLoc:{[debugInfo]
  :$[null debugInfo[`cfgFile];"";", defined in ",string[debugInfo[`cfgFile]],":",string[debugInfo[`cfgLine]],",",string[debugInfo[`cfgCol]]]
    ,$[null debugInfo[`qsdFile];"";", imposed by schema ",string[debugInfo[`qsdFile]],":",string[debugInfo[`qsdLine]],",",string[debugInfo[`qsdCol]]]
  };
// -----------------------------------------------------------------
//     functions for lazy vars evaulation 
// -----------------------------------------------------------------
.cr.p.getEvalPath:{[cfgFile;componentId;sectionTypes]
  level1:select from cfgFile[`subGroups] where (prefix in sectionTypes) or (prefix=`ALL);
  res:raze {[componentId;g]
             $[count g[`subGroups];
               exec (enlist[(g[`prefix];g[`suffix])] ,/: enlist each (prefix,'suffix)) from g[`subGroups] where (prefix=componentId);
               enlist enlist[(g[`prefix];g[`suffix])]
             ]
           }[componentId] each level1;
  :res
  };
 
.cr.p.forceEval:{[cfgFile;componentId;sectionTypes]
  evalPaths:.cr.p.getEvalPath[cfgFile;componentId;sectionTypes];
  if[0=count evalPaths;:cfgFile];
  query:{[x;y] .cr.p.forceEvalOneSubGroup[x;enlist[``],y]};
  res:.pe.dot[query/;(cfgFile;evalPaths);{[paths;sig]`$"VARS_FORCE_EVALUATION_FAILED: paths: ",.Q.s1[paths],", signal: ",sig}[evalPaths;]]; // signal should never happen
  :res;
  };

 
.cr.p.forceEvalOneSubGroup:{[cfgFile;path]
  pref:first path[0];
  path:1_path;
  // execute only if not already evaluated
  if[not `varVal in cols cfgFile[`vars];
    evaluated:.pe.dot[.cr.p.evalVars;(pref;cfgFile[`vars]);{[path;sig]`$"VARS_SUBGROUP_EVALUATION_FAILED: path: ",.Q.s1[path],", signal: ",sig}[path;]]; // signal should never happen
    if[-11h<>type evaluated;
      cfgFile[`errors]:cfgFile[`errors],raze exec validationErr from evaluated  where 0=count each parseErr, 0<>count each validationErr;
      cfgFile[`errors]:cfgFile[`errors],raze exec parseErr from evaluated
      ];
 
    $[-11h=type evaluated;cfgFile[`errors],:evaluated;cfgFile[`vars]:evaluated];
    ];
 
  if[0<>count path;
    pref:first path[0];
    suff:last path[0];
    subGroups:cfgFile[`subGroups];
    idxs:exec i from subGroups where prefix=pref, suffix=suff;
    subGroups[idxs]:.cr.p.forceEvalOneSubGroup[;path] each subGroups[idxs];
    cfgFile[`subGroups]:subGroups;
    ];
  :cfgFile;
  };
 
// -----------------------------------------------------------------------------
// getters
// -----------------------------------------------------------------------------
/F/ Returns configuration details
/P/ componentId : SYMBOL - name of process (`THIS and `ALL can be used as well)
/P/ secType : SYMBOL | SYMBOL LIST - type of section (`group,`table etc.)
/P/ fields : LIST SYMBOL - list of variables to fetch
/R/ table with columns sectionVal, subsection, varName, finalValue
/E/ .cr.getCfgTab[`ALL;`group;`var1`var2]
/E/ .cr.getCfgTab[componentId;`sysTable`table;`model]
.cr.getCfgTab:{[componentId;secType;fields]
  componentId:$[`THIS~componentId;.sl.componentId;componentId];
  fields:`$(),string fields; 
  secType:(),secType;
  services:$[`ALL~componentId;distinct raze {raze {x[`prefix]} each .cr.cfg[x][`subGroups][`subGroups]} each key .cr.cfg;(),componentId,`ALL];
  //force evaluation of necessary parts of config;
  query:{[cfg;sid;sec] .cr.cfg[cfg]:.cr.p.forceEval[.cr.cfg[cfg];sid;sec]};
  query {[f;args] .[f;args]}/: ((key .cr.cfg) cross services cross secType);

  groups:raze {[k;secType] select sectionVal:suffix, subGroups from .cr.cfg[k][`subGroups] where prefix in secType}[;secType] each key .cr.cfg;
  if[0=count groups;'"groups ", .Q.s1[secType], " are missing"];
  processes:raze (exec subGroups from groups) {[subGroup;section] select prefix, section:section, vars from subGroup}' (exec sectionVal from groups);
  processesAll:$[`ALL in processes`prefix;
    update prefix:componentId from  raze (count[p];count[componentId])#p:select from processes where prefix=`ALL;
    0#processes
    ];
  processes:processesAll,(delete from processes where prefix=`ALL);
  processes:$[`ALL~componentId;processes; 0!select by prefix, section from processes where prefix in services];

  processes:raze {[d] update componentId:d[`prefix], section:d[`section] from 0!d[`vars]}each processes;
  if[0=count processes;:([] sectionVal:`$(); subsection:`$(); varName:`$(); finalValue:0#(::))];
  :select sectionVal:section, subsection:componentId, varName, finalValue:varVal from processes where varName in fields;
  };

/F/ Returns configuration details, similar to <.cr.getCfgTab>, but returns values on the group level
/P/ secType : SYMBOL | SYMBOL LIST - type of section (`group,`table etc.)
/P/ fields : LIST SYMBOL - list of variables to fetch
/R/ table with columns sectionVal, subsection, varName, finalValue
/E/ .cr.getGroupCfgTab[`group;`var1`var2]
/E/ .cr.getGroupCfgTab[`sysTable`table;`model]
.cr.getGroupCfgTab:{[secType;fields]
  paths: raze  {[cfg;pref] enlist[cfg]!enlist (enlist ``),/: exec enlist each (prefix,'suffix) from .cr.cfg[cfg][`subGroups] where prefix in pref}[;secType] each key .cr.cfg;
  //force evaluation of necessary subgroups;
  (key paths) {.cr.cfg[x]:.cr.cfg[x] .cr.p.forceEvalOneSubGroup/ y}' (value paths);
  vars: raze raze (key paths) {[x;y] exec (prefix,'suffix) {update section:first x, sectionVal:last x  from 0!y}' vars from .cr.cfg[x][`subGroups] where (prefix,'suffix) in last each y}' (value paths);
  if[not count vars;'"missing group(s):",.Q.s1[secType]];
  :select sectionVal,section,varName, finalValue:varVal from vars where varName in fields;
  };
   
/F/ Returns detailed info on values. Similar to .cr.getCfgPivot, but works on a group level
/P/ secType : SYMBOL | SYMBOL LIST - type of section (`group,`table etc.)
/P/ fields : LIST SYMBOL - list of variables to fetch
/R/ Table with columns sectionVal, field1, field2, fieldN keyed on sectionVal; 
/R/ in each column are values of given field for given sections.
.cr.getGroupCfgPivot:{[sectionTypes;fields]
  exec ((),fields)#(varName!finalValue) by sectionVal:sectionVal from .cr.getGroupCfgTab[sectionTypes;fields]
  };
  
/F/ Checks if given field is defined 
/P/ componentId : SYMBOL - name of process (`THIS and `ALL can be used as well)
/P/ secType : SYMBOL - type of section (`group,`table etc.)
/P/ field : SYMBOL - variable which existence is checked
/R/ table with columns sectionVal,subsection,varName,finalValue
/E/ .cr.getCfgTab[`ALL;`group;`var1]
/E/ .cr.getCfgTab[componentId;`sysTable;`model]  
/R/ 1b if variable is defined, 0b otherwise
.cr.isCfgFieldDefined:{[componentId;sectionType;field]
  :0<>count res:.cr.p.getVar[.cr.section2file[sectionType];componentId;sectionType;field];
  };   
  
 
/F/ Returns models of tables for given process
/P/ componentId : SYMBOL - name of the process (`THIS may be ussed for current process)
/R/ list of pairs (TABLE_NAME,TABLE_MODEL); table model is an empty table 
.cr.getModel:{[componentId]
  componentId:$[`THIS~componentId;.sl.componentId;componentId];
  tabs1:.cr.getCfgTab[componentId;`sysTable`table;`model];
  sources:.cr.getCfgTab[componentId;`sysTable;`modelSrc];
  .cr.loadCfg each (),exec finalValue from sources;
  tabs2:.cr.getCfgTab[;`sysTable;`model] (exec finalValue from sources) except componentId;
  tabs:tabs1,tabs2;
  res:.pe.at[.cr.p.convertModel;;{x}] each tabs:tabs1,tabs2;
  if[count where invalid:10=type each res; (tabs where invalid) {[tab;err].log.error[`cr] "Cannot retreive model for table ",string[tab`sectionVal],", error: ",err}' (res where invalid)];
  :res where not invalid;
  };
 
.cr.p.readSourceTabs:{[cfg]
  tName:cfg`sectionVal;
  pName:cfg`finalValue;
  vars:.cr.p.auxQsdVars[pName];
  vars:raze exec vars from vars[(`sysTable;tName)];
  info:exec first varVal from vars where varName=`model;
  model:.pe.dot[.cr.p.parseVal;(.par.initP info`default;info;()!();`$info`type;1b);{()}];
  :`sectionVal`subsection`varName`finalValue!(tName;pName;`model;$[null model[`errp];model[`ast];()]);
  };
 
.cr.p.convertModel:{[info]
  model:info[`finalValue];
  model:model[`col1]!model[`col2];
  if[not all (value model) in key .cr.atomic.nulls;
    '"Model contains unsupported types: ", .Q.s1[value[model] where not value[model] in key .cr.atomic.nulls]];
  :(info[`sectionVal];flip (key model)!{$[0h<type x;0#enlist x;0#x]} each .cr.atomic.nulls[value model]);
  };
 
/F/ Returns values for given variables for all processes; 
/F/ searches for values only in system.cfg
/P/ attributes : LIST SYMBOL - list of attributes to fetch
/R/ table with columns: proc, attributes (each attribute has its own column)
.cr.getByProc:{[attributes]
  exec attributes#(varName!finalValue) by proc:subsection from .cr.getCfgTab[`ALL;`group;attributes]
  };
 
//.cr.getCfgPivot[`core.tick;`group;`hk`asd`kromsiale]
/F/ Returns configuration details
/P/ componentId : SYMBOL - name of process (`THIS can be used as well)
/P/ secType : SYMBOL | SYMBOL LIST - type of section (`group,`table etc.)
/P/ fields : LIST SYMBOL - list of variables to fetch
/R/ Table with columns sectionVal, field1, field2, fieldN keyed on sectionVal; 
/R/ in each column are values of given field for given sections.
.cr.getCfgPivot:{[componentId;sectionTypes;fields]
  exec ((),fields)#(varName!finalValue) by sectionVal:sectionVal from .cr.getCfgTab[componentId;sectionTypes;fields]
  };
 
/F/ Returns dictionary of variable names and corresponding values
/P/ componentId : SYMBOL - name of process (`THIS and `ALL can be used as well)
/P/ secType : SYMBOL | SYMBOL LIST - type of section (`group,`table etc.)
/P/ fields : LIST SYMBOL - list of variables to fetch
/R/ dictionary varName -> varValue
.cr.getCfgDict:{[componentId;sectionTypes;fields]
  exec varName!finalValue from .cr.getCfgTab[componentId;sectionTypes;fields]
  };
 
/F/ Returns value of given variable for given process
/P/ componentId : SYMBOL - name of service (or `THIS for current process)
/P/ sectionType : SYMBOL - name of section in which value exists (`group for system.cfg, `table/`sysTable for dataflow.cfg etc.)
/P/ field : SYMBOL - name of variable
/E/ .cr.getCfgField[`core.tick;`group;`cfg.timeout]
/E/ .cr.getCfgField[`THIS;`group;`cfg.timeout]
.cr.getCfgField:{[componentId;sectionType;field]
  if[0=count res:.cr.p.getVar[file:.cr.section2file[sectionType];componentId;sectionType;field];
    '"Field ",.Q.s1[field], " for componentId ", .Q.s1[componentId], " for sectionType ",.Q.s1[sectionType]," is missing in file ",string[file],".cfg";
    ];
  :res[`varVal];
  };
 
//.cr.p.getVar[`system;`core.tick;`group;`asd]
.cr.p.getVar:{[cfgFile;componentId;sectionType;field]
  componentId:$[`THIS=componentId;.sl.componentId;componentId];
   .cr.cfg[cfgFile]:.cr.p.forceEval[.cr.cfg[cfgFile];componentId;sectionType]; 
   if[not componentId in .cr.p.procNames;'"process ",.Q.s1[componentId]," not defined";];
   field:`$string[field];
   res:exec subGroups from .cr.cfg[cfgFile][`subGroups] where prefix=sectionType;
   if[0=count res;:()!()];
   vars:raze exec {0!x} each vars from (raze res) where prefix=componentId;
   if[0=count vars;:()!()];
   vars:select by varName from vars where not null qsdFile;
   :$[field in key vars;vars[field];()!()];
   };
 
//----------------------------------------------------------------------------//
// sync config                                                                //
//----------------------------------------------------------------------------//
/F/ Loads additional sync.cfg file; 
/F/ used in components that synchronize/communicate with other systems. 
/F/ If sync.cfg does not exist it will throw a signal.
.cr.loadSyncCfg:{[]
  qsdPath:`$":",getenv[`EC_QSL_PATH],"/system.qsd";
  cfgPath:`$":",getenv[`EC_ETC_PATH],"/sync.cfg";
  
  qsd:.cr.parseCfgFile[qsdPath;1b];
  cfg:.cr.parseCfgFile[cfgPath;0b];
  
  .cr.cfg[`sync]:.cr.p.align[`system;();();cfg;qsd;.sl.componentId;1b];
  };
 
/F/ Returns field value from sync.cfg file
/F/ Usage is the same as for <.cr.getCfgField>
/P/ componentId : SYMBOL - name of service (or `THIS for current process)
/P/ sectionType : SYMBOL - name of section in which value exists (`group for system.cfg, `table/`sysTable for dataflow.cfg etc.)
/P/ field : SYMBOL - name of variable
.cr.getSyncCfgField:{[componentId;sectionType;field]
  cfg:$[`sync in key .cr.cfg;`sync;'"sync config not loaded"];
  if[0=count res:.cr.p.getVar[cfg;componentId;sectionType;field];
    '"MISSING_ENTRY ",.Q.s1[field], "in sync.cfg:[",.Q.s1[sectionType],"][[",.Q.s1[componentId],"]].";
    ];
  :res[`varVal];
  };
 
//----------------------------------------------------------------------------//
// Validators                                                                 //
//----------------------------------------------------------------------------//
 
.cr.p.validate:{[valInfo]
  //debugInfo:`cfgFile`cfgLine`cfgCol`qsdFile`qsdLine`qsdCol`varName!v[`cfgFile`cfgLine`cfgCol`qsdFile`qsdLine`qsdCol`varName];

  if[0<>count valInfo[`parseErr];
    valInfo[`validationErr]:`$"VALUE_PARSING_ERROR: validation not preformed";
    :valInfo;
    ];
 
  validate:{[validator;tp;args;val;valInfo]
    fun:` sv (`.cr.v;validator);
    res:.pe.dot[value fun;(tp;args;val);`$"VALUE_VALIDATING_ERROR: unexpected error for args: ",.Q.s1[(validator;tp;args;val)]];
    :$[res=`;
      res;
      `$"VALUE_VALIDATING_ERROR: ",string[valInfo[`varName]]," = ",.Q.s1[val],", validator:",string[validator], ", msg:",string[res]
        ,.cr.p.genErrorLoc[valInfo]
      ];
   
     }[;valInfo[`fieldType];;valInfo[`varVal];valInfo];
  res:(key valInfo[`validators]) validate' (value valInfo[`validators]);
  valInfo[`validationErr]:res where res<>`;
  :valInfo;
  };
 
/F/ Checks if a parameter is within the range of allowed values; applies only to numeric types 
/P/ allowedParams - two element list of numbers
/P/ checkParam - parameter to be checked
/R/ 1b if element is within the allowed range (inlusive), 0b otherwise
/E/ .cr.v.within[(-10;10);1]
/E/ .cr.v.within[(-10;10);-10]
/E/ .cr.v.within[(-10;10);10]
/E/ .cr.v.within[(-10;10);-11]
/E/ .cr.v.within[(-10;10);11]
/E/ 
/E/ // in qsd file
/E/ cfg.param = <type(INT), within(0,10)>

.cr.v.within:{[tp;allowedParams;checkParam]
  if[not tp in `INT`FLOAT`REAL`SHORT;:`$"validator \"within\" can be used only for numeral types"];
  res:.cr.atomic.parsers[`$"LIST ",string[tp]] .par.initP allowedParams;
  if[not null res[`errp];:`"validator arguments parse error :",.Q.s1[res[`errs]]];
  params:res[`ast];
  if[2<>count params;:`"validator \"within\" should have 2 arguments"];
  :$[all checkParam within allowedParams;`;`$"should be within (",(", " sv string[allowedParams]),")"];
  };
 
//----------------------------------------------------------------------------//
 
/F/ Checks if an element is in the list of other allowed elements (one of many)
/P/ allowedParams - list of parameters that are chosen from
/P/ checkParam - parameter to be checked
/R/ 1b if element is within allowed parameters, 0b otherwise
/E/ .cr.v.in[(1 2 3);1]
/E/ .cr.v.in[(1 2 3);5]
/E/ .cr.v.in[`a`b`c;`a]
/E/ .cr.v.in[`a`b`c;`d]
/E/ 
/E/ // in qsd file
/E/ cfg.param = <type(INT), within(1,2,3)>
.cr.v.in:{[tp;allowedParams;checkParam]
  listType:$[tp like "LIST*";tp;`$"LIST ",string[tp]];
  if[not listType in key .cr.atomic.parsers;:`$"validator \"in\" can be used only on atomic listable types"];
  res:.cr.atomic.parsers[listType] .par.initP allowedParams;
  if[not null res[`errp];:`"validator arguments parse error :",.Q.s1[res[`errs]]];
  params:res[`ast];
  :$[all checkParam in params;`;`$"should be in (",(", " sv .Q.s2[params]),")"];
  };
 
//----------------------------------------------------------------------------//
 
/F/ Checks if given component is present within the system
/P/ component - component to be verified
/R/ 1b if present, 0b otherwise
/E/ // in qsd file
/E/ cfg.param = <type(SYMBOL), isComponent()> 
.cr.v.isComponent:{[tp;dummy;component]
  if[not tp in (`COMPONENT; `$"LIST COMPONENT";`SYMBOL;`$"LIST SYMBOL";`STRING;`$"LIST STRING");:`$"validator \"isComponent\" can be used only for SYMBOL and STRING types"];
  if[tp in (`STRING;`$"LIST STRING");component:`$component];
  :$[all component in `,.cr.p.procNames;`;`$"component \"", .Q.s1[component] ,"\" missing in the system"];
  };
//----------------------------------------------------------------------------//
 
/F/ Checks if given component is present within the system
/P/ component - component to be verified
/R/ 1b if present, 0b otherwise
/E/ // in qsd file
/E/ cfg.param = <type(SYMBOL), isComponentType()> 
//component:"c:tick"
.cr.v.isComponentType:{[tp;dummy;component]
  if[tp<>`COMPONENT_TYPE;:`$"validator \"isComponentType\" can be used only for SYMBOL type"];
  :$[(component like "[a-z]:*") or (component like "[a-z][a-z][a-z]:*"); `; `$"component type should be in following format 'x:type' or 'cmd:type'"];    // subsection in .cr.p.cfgTable, section type=`group, componentName
  };

//----------------------------------------------------------------------------//
 
/F/ Checks if given path exists
/P/ path : PATH | LIST PATH - path(s) to be checked
/R/ 0b if path exists, 1b otherwise
/E/ .cr.v.pathExist[`;`:test/data/bin/kdb.accessPoint]
/E/ // in qsd file
/E/ cfg.param = <type(PATH), pathExist()> 
.cr.v.pathExist:{[tp;dummy;path]
  if[not tp in (`PATH;`$"LIST PATH");:`$"validator \"pathExists\" can be used only for PATH types"];
  :$[()~key path; `$"path does not exist"; `];
  };
 
//----------------------------------------------------------------------------//
 
/F/ Checks if y is greater than x
/P/ x - number (as string)
/P/ y - number
/E/ .cr.v.greater["1";2]
/E/ .cr.v.greater["2";1]
/E/ .cr.v.greater["2";2]
/E/ // in qsd file
/E/ cfg.param = <type(INT), greater(5)> 
.cr.v.greater:{[tp;x;y]
  if[not tp in `INT`FLOAT`REAL`SHORT;:`$"validator \"greater\" can be used only for numeral types"];
  nr:.cr.atomic.parsers[tp] .par.initP x;
  if[not null nr[`errp];:`$"validator arguments parse error: ",.Q.s1[nr[`errs]]];
  val:nr[`ast];
  :$[val<y;`;`$"should be greater than (",(string[val]),")"];
  };
 
/F/ Marks fields that are defined in sync.cfg file only.
/F/ Field marked with this validator will not be visible for <.cr.getCfgField>.
/F/ To get value of such field please use <.cr.getSyncCfgField>.
/E/ // in qsd file
/E/ cfg.param = <type(INT), syncOnly()> 
.cr.v.syncOnly:{[tp;dummy;val]
  :`;
  };
 
// ---------------------------------------------------------------------------//
 
 
.cr.p.initEnv:{[services]
  if[not `cfg in key `.cr;
    .cr.qsdFile:()!();
    .cr.cfgFile:()!();
    .cr.cfgTab:()!();
    .cr.qsdTab:()!();
 
    .cr.qsdFile[`system]:`$":",getenv[`EC_QSL_PATH],"/system.qsd";
    .cr.qsdFile[`dataflow]:`$":",getenv[`EC_QSL_PATH],"/dataflow.qsd";
    .cr.qsdFile[`access]:`$":",getenv[`EC_QSL_PATH],"/access.qsd";    
 
    .cr.cfgFile[`system]:`$":",getenv[`EC_ETC_PATH],"/system.cfg";
    .cr.cfgFile[`dataflow]:`$":",getenv[`EC_ETC_PATH],"/dataflow.cfg";
    .cr.cfgFile[`access]:`$":",getenv[`EC_ETC_PATH],"/access.cfg";
 
    .log.info[`cr] "Parsing qsd files";
    {[t] .cr.qsdTab[t]:.cr.parseCfgFile[.cr.qsdFile[t];1b]} each key .cr.qsdFile;
    .log.info[`cr] "Parsing cfg files";
    {[t] .cr.cfgTab[t]:.cr.parseCfgFile[.cr.cfgFile[t];0b]} each key .cr.cfgFile;
 
    .cr.cfgTab[`system;`subGroups]:update {raze .cr.p.expandClonesSet each x}each subGroups from .cr.cfgTab[`system;`subGroups];
    .cr.cfgTab[`dataflow;`subGroups]:update {$[count x;raze .cr.p.expandClonesSet each x;x]}each subGroups from .cr.cfgTab[`dataflow;`subGroups];
    .cr.cfgTab[`access;`subGroups]:update {$[count x;raze .cr.p.expandClonesSet each x;x]}each subGroups from .cr.cfgTab[`access;`subGroups];

    .cr.section2file:raze {[t] 
      sections:exec distinct prefix from .cr.cfgTab[t][`subGroups];
      :sections!(count sections)#t;
      } each key .cr.cfgTab;
 
    .cr.p.procNames:exec prefix from raze .cr.cfgTab[`system][`subGroups][`subGroups];
    //procDefs:exec prefix(,)'suffix from raze .cr.cfgTab[`system][`subGroups][`subGroups];
    //.cr.p.procNames:raze {if[x[1]~`;:x[0]];:`$string[x 0],/:"_",/:string til "I"$string[x 1];} each procDefs;
    ];
 
  componentId:.sl.componentId;
 
  services[where `THIS=services]:(count where `THIS=services)#componentId;
  if[`ALL in services;services:.cr.p.procNames];
 
  nonExistentProcs:services except .cr.p.procNames;
  if[0<>count nonExistentProcs;'"processes ",.Q.s1[nonExistentProcs]," not defined";];
 
  .cr.cfg:()!();
  {[services;t] 
    .log.debug[`cr] "Aligning ",string[t], " config files";
    .pe.dot[{[t;cfg;qsd;services] .cr.cfg[t]:.cr.p.align[t;();();cfg;qsd;services;0b]};(t;.cr.cfgTab[t];.cr.qsdTab[t];services);{[t;x] .log.fatal[`cr] "Failed to align: ",string[t]," , signal: ",x}[t;]]}[services;] each key .cr.cfgTab;
 
  // evaluate vars for services - to report errors 
  {[s] sect:group `template _ .cr.section2file; {[s;k;v] .cr.cfg[k]:.cr.p.forceEval[.cr.cfg[k];s;v]}[s]'[key sect;value sect]}each services;
  };

/F/ Loads configuration for given service(s). 
/F/ It is necessary to load configuration for specific service before it's fields can be obtained. 
/P/ services: SYMBOL | SYMBOL LIST - list of services for which configuration will be loaded
.cr.loadCfg:{[services]
  services:(),services;
  .cr.p.initEnv[services];
  services[where `THIS=services]:(count where `THIS=services)#.sl.componentId;
 
  errors:exec errors from .cr.p.getErr[.cr.cfg[`system]] where section in services;
  errors:errors,exec errors from .cr.p.getErr[.cr.cfg[`dataflow]] where section in services;
  errors:errors,exec errors from .cr.p.getErr[.cr.cfg[`access]];
  .log.error[`cr] each string distinct errors;
  };

//----------------------------------------------------------------------------// 
//                            top level parsing                               //
//----------------------------------------------------------------------------// 
.cr.p.trim:{p:(first;last)@\:where not any x=/:" \t\n"; p[0],enlist $[null p[0];"";p[0]_(p[1]+1)#x]};
.cr.p.recognize:{ first where x like/: `section`subsection`field`empty`malformed!("[\\[][^[]*]";"[\\[][\\[]*]]";"*=*";"";enlist"*") };

.cr.p.parse:()!();
.cr.p.parse[`section]:{r:.cr.p.trim -1_1_ x;r[0],enlist ":" vs r[1]};
.cr.p.parse[`subsection]:{r:.cr.p.trim -2_2_ x;r[0],enlist ":" vs r[1]};
.cr.p.parse[`field]:{eq:first where "="=x; r:.cr.p.trim each (0;eq;eq+1)_ x;(1+eq+r[2;0];r[0 2;1])};

//----------------------------------------------------------------------------// 
//lineType:``section`subsection;x:final
//x:last cuts _ x;lineType:nextType
.cr.p.buildTree:{[lineType;x]
  res:`prefix`prefixAux`suffix`suffixAux`groupParseLine`groupParseCol`vars`subGroups`errors!(`;()!();`root;()!();0Nj;0Nj;();();`symbol$());
  nextType:1_lineType;
  cuts:where[first[nextType]=x`lineType];
  vars:$[count cuts;first[cuts]#x;x];
  if[count[vars] and vars[0][`lineType]=lineType[0];
    res[`prefix`suffix]:`$vars[0][`varName`varVal];
    res[`groupParseLine`groupParseCol]:vars[0][`line`col];
    vars:1_vars;
    ];
  //collect all pending errors as this level errors
  if[count bad:select from vars where 0<>count each errors;
    res[`errors]:`$exec ("PARSING_ERRORS "(,)/:(","sv/: string[errors]),'", defined in ",/:string[file],'":",'string[line],'",",'string[col]) from bad;
    ];
  res[`vars]:update `$varName from delete lineType from select from vars where 0=count each errors;
  if[count nextType; //not last level 
    res[`subGroups]:.cr.p.buildTree[nextType] each cuts _ x;
    if[0=count res[`subGroups];
      res[`subGroups]:flip key[res]!count[res]#();
      ];
    ];
  res
  };

.cr.p.excludeComment:{$[null c:first where "#"=x;x;c#x]};
.cr.p.isVarNameValid:{(count[x]=0) or (count[x]<>.cr.p.identifier[.par.initP x]`cp)};

//file:.cr.cfgFile`system;
//.cr.parseCfgFileOld[file:`:test/full/system.qsd;1b]
/F/ Parses configuration file
/P/ file: SYMBOL - path to file
/P/ flag:BOOL - 0b if cfg file, 1b for qsd file
.cr.parseCfgFile:{[file;flag]
  raw:read0 file;
  raw:.cr.p.excludeComment each raw;
  trimmed:.cr.p.trim each raw;
  lines:([]raw:trimmed[;1]; file; line:1+til count trimmed; col:1+0^trimmed[;0]);
  recognized:update lineType:.cr.p.recognize each raw, errors:count[i]#enlist`symbol$() from lines;
  recognized:update errors:(errors,\:`$"invalid line") from recognized where lineType=`malformed;

  parsed:update parsed:.cr.p.parse[lineType]@'raw from recognized where lineType in `field`section`subsection;
  final:delete parsed from select lineType, varName:parsed[;1;0], varVal:parsed[;1;1], line, col+parsed[;0], file, errors from parsed where lineType<>`empty;
  final:update errors:(errors,'`$"invalid varName:",/:varName) from final where lineType=`field, .cr.p.isVarNameValid each varName;
  cfg:.cr.p.buildTree[``section`subsection;final];

  if[flag; 
    cfg:.cr.p.asQsd[file;cfg];
    ];

  $[flag;cfg;.cr.p.expandTemplates[cfg]]
  };

.cr.p.asQsd:{[file;cfg]
  cfg[`vars]:(0#cfg[`vars]),.cr.p.parseQsdFields each cfg[`vars];
  if[0<>count cfg[`subGroups];
    cfg[`subGroups]:(0#cfg[`subGroups]),.cr.p.asQsd[file;] each cfg[`subGroups];
    ];
  prefix:string[cfg[`prefix]];
  suffix:string[cfg[`suffix]];
   
  gPrefix:$[prefix[0]="<";.cr.p.angleDict[();];.par.many[.par.noneOf["[]:<>"]]] .par.initP prefix;
  gSuffix:$[suffix[0]="<";.cr.p.angleDict[();];.par.many[.par.noneOf["[]<>"]]] .par.initP suffix;
  $[null gPrefix`errp; 
    $[`angleDict~first gPrefix[`ast];
      cfg[`prefix`prefixAux]:(`;last gPrefix[`ast]);
      cfg[`prefix`prefixAux]:($[0=count gPrefix[`ast];`;`$gPrefix[`ast]];()!())
      ];
    cfg[`errors]:cfg[`errors],`$"PREFIX_PARSE_ERROR ",("," sv gPrefix`errs),", in file: ",1_string[file],":",string[cfg[`groupParseLine]],",",string[cfg[`groupParseCol]+gPrefix[`errp]]
    ];
  $[null gSuffix`errp;
    $[`angleDict~first gSuffix[`ast];
      cfg[`suffix`suffixAux]:(`;last gSuffix[`ast]);
      cfg[`suffix`suffixAux]:($[0=count gSuffix[`ast];`;`$gSuffix[`ast]];()!())
      ];
    cfg[`errors]:cfg[`errors],`$"SUFFIX_PARSE_ERROR ",("," sv gSuffix`errs),", in file: ",1_string[file],":",string[cfg[`groupParseLine]],",",string[cfg[`groupParseCol]+gSuffix[`errp]+1+count prefix]
    ];
  :cfg;
  };


.cr.p.parseQsdFields:{[row]
  res:.cr.p.angleDict[();.par.initP row[`varVal]];
  $[null res[`errp];
    row[`varVal]:last res[`ast];
    [
      row[`errors]:row[`errors], `$"VALUE_PARSING_ERROR ",string[row[`varName]],":",("," sv res[`errs]),", in file ",string[row[`file]],",:",string[row[`col]];
      row[`varVal]:(`symbol$())!();
      ]
    ];
  
  :row; 
  };

  
//----------------------------------------------------------------------------// 
/
.cr.p.getErr[a]
 
 
