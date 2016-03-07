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

/A/ DEVnet: Pawel Hudak
/V/ 3.4

/S/ Function documentation loader.

//----------------------------------------------------------------------------//
/F/ Lists available functions with the given function prefix.
/-/ List all functions with the given prefix with the short description, parameters and additional info.
/P/ prefix:SYMBOL - namespace or any part of the function name prefix, ` to list all functions
/R/ TABLE(item:SYMBOL; desc:STRING; params:STRING; ret:STRING; example:STRING; src:SYMBOL)
/E/ .doc.list`
/-/    - list all available functions
/E/ .doc.list`.hnd
/-/    - list all available functions in the namespace .hnd
/E/ .doc.list`.hnd.po        
/-/    - list all available functions in with the prefix .hnd.po
.doc.list:{[prefix]
  select item, itemType, params:header, lib, ns, `char$first'[descr], ret:`char$first'[ret], example:`char$first'[examples], file, docErr from .doc.p.currentList[] where item like (string[prefix],"*")
  };

//----------------------------------------------------------------------------//
/F/ Finds function by keyword. Any part of the function documentation is being analyzed.
/P/ keyword:STRING | SYMBOL - keyword that should be searched in all of the api documentation
/R/ TABLE(item:SYMBOL; desc:STRING; params:STRING; ret:STRING; example:STRING; src:SYMBOL)
/E/ .doc.find`proto         
/-/    - finds all entries matching "*proto*" pattern
/E/ .doc.find`.doc
/-/    - finds all entries matching "*.doc*" pattern
.doc.find:{[keyword]
  pattern:"*",$[-11h=type keyword;string keyword;keyword],"*";
  select item, params:header, lib, ns, `char$first'[descr], `char$first'[ret], `char$first'[examples], file, docErr from .doc.p.currentList[] where (item like pattern) or (any each (descr like\: pattern))
  };

//----------------------------------------------------------------------------//
/F/ Displays detailed information about the function.
/P/ item:STRING or SYMBOL - name of the item to be shown, e.g. function name
/R/ STRING - all information about the function in form of string, including the function body.
/E/ .doc.show`.hnd.hopen
/-/    - displays all available info about .hnd.hopen[] function
/E/ .doc.show `.doc.show
/-/    - displays all available info about .doc.show[] function
.doc.show:{[item]
  d:.doc.p.currentList[][item];
  out:enlist string[item],d[`header];
  out,:enlist "";
  out,:raze exec {r:"/-/",/:y;r[0;1]:first[string x];r}'[lineType;content] from d[`raw] where lineType<>`DEF;
  out,:enlist "";
  out,:enlist "/*/ itemType - ",string d[`itemType];
  if[not d[`docErr]~"";out,:enlist "/*/ projFixture - ",exec "  " sv (string[param],'":",'.Q.s1'[fix]) from d[`proj] where not free];
  out,:enlist "/*/ lib - ",string d[`lib];
  out,:enlist "/*/ file - ",string d[`file];
  out,:enlist "/*/ ns - ",string d[`ns];
  if[not d[`docErr]~"";out,:enlist "/*/ docErr - ",d[`docErr]];
  out,:enlist "";
  if[d[`itemType]~`FUNCTION;
    out,:string[item],":",string value item;
    ];
  "\n" sv out
  };

//----------------------------------------------------------------------------//
//                          private functions                                 //
//----------------------------------------------------------------------------//
.doc.p.all:();

//----------------------------------------------------------------------------//
/E/ .doc.p.currentList[]
.doc.p.currentList:{[]
  .doc.reload[];
  documented:`item xasc select last lib, last descr, last params, last ret, last examples, last file, last raw, last ns, last subNs by item from .doc.p.all;
  inmem:`item xkey `item xasc .doc.p.analyzeMem[];
  res:update docErr:count[i]#enlist"" from inmem uj documented;
  //private items will be hidden
  res:delete from res where item like "*.p.*";
  //selected items are treated in the same way as private functions
  res:delete from res where any item like/: (".par.*";".cr.atomic.*";".cr.v.*";".cr.compound.*";".cr.arith.*");
  //extract errors
  res:update docErr:{e:first where not ""~/:x`parseErr;:"param #",string[e]," ",.Q.s1[x[e]`parName]," - parsing failed:",.Q.s1[x[e]`paramName]}'[params] from res where {not all""~/:x`parseErr}'[params];
  res:update docErr:.doc.p.compareParams'[funcParams;params@'`parName] from res where ""~/:docErr, not {[x;y] (x~y`parName)}'[funcParams;params];
  //generate function header
  res:update header:@[{exec ("[",("; " sv string[paramName],'":",'string[parType]),"]") from x};;::]'[params] from res where ()~/:docErr;
  res:update header:@[{("[",("; " sv string[x]),"]")};;::]'[funcParams] from res where not ()~/:docErr;
  res:update header:count[i]#enlist "", examples:{enlist " ",string x}'[item] from res where not itemType=`FUNCTION;

  res:update descr:{enlist" Main namespace ",string[x],"."}'[ns] from res where itemType=`NAMESPACE, item~'ns;
  res:update descr:{enlist" Sub-namespace of ",string[x],"."}'[ns] from res where itemType=`NAMESPACE, not item~'ns;
  res:update descr:{enlist" Namespace with configuration for ",string[x],"."}'[ns] from res where itemType=`NAMESPACE, item like "*.cfg";
  res:update descr:{enlist" Namespace with private functions and variables for ",string[x],"."}'[ns] from res where itemType=`NAMESPACE, item like "*.p";

  res:res lj select first lib, first file by ns, itemType:`NAMESPACE from res where not null lib;

  `ns xasc `itemType xdesc `item xasc res
  };

//----------------------------------------------------------------------------//
/F/ Reloads documentation from source files.
/R/ no return value
/E/ .doc.reload[]
/-/    - loads configuration from source files
.doc.reload:{[]
  .doc.p.all:();
  .pe.atLog[`doc;`.doc.p.load;;();`error] each .sl.libs;
  };

//----------------------------------------------------------------------------//
/F/ Extract documentation tags from the q source file.
/P/ file:PATH - path to the source file
.doc.p.load:{[lib]
  .log.debug[`doc]"Extracting documentation from ",string[lib`file];
  .doc.p.all,:`item`lib xcols update lib:lib`lib, subNs:{first -1_2_` vs x}each item from .doc.p.parse lib`file;
  };

//----------------------------------------------------------------------------//
/F/ Extract documentation tags from the q source file.
/P/ file:SYMBOL or STRING
/E/ .doc.p.parse file:hsym`$getenv[`EC_QSL_PATH],"doc.q"

//TODO: .doc.p.parse file:`:C:/P/ec/development/tests/system/bin/ec/libraries/qsl/event.q
//TODO: .doc.p.parse file:`:C:/P/ec/development/tests/system/bin/ec/libraries/qsl/u.q
//TODO: .doc.p.parse file:`:C:/P/ec/development/tests/system/bin/ec/libraries/qsl/sl.q
//TODO: .doc.p.parse file:`:C:/P/ec/development/tests/system/bin/ec/components/tickHF/tickHF.q
//TODO: .doc.p.parse file:`:C:/P/ec/development/tests/system/bin/ec/libraries/qsl/authorization.q

//TODO: .doc.p.parse file:`:C:/P/ec/development/tests/system/bin/ec/components/hdb/hdb.q
.doc.p.parse:{[file]
  file:hsym $[10h=type file;`$file;file];
  lines:trim read0 file;
  doc:where[lines like "/?/*"];
  comments:where[lines like "/*"];
  //handle standard functions
  fun:where[lines like "*:{*"] except comments;
  //handle projections
  potentialItems:where[lines like "*:*"] except comments;
  nsSwitchLines:where lines like "\\d*";
  items:`row xasc ([]row:nsSwitchLines; lineType:`NS; nsSwitch:`$trim 3_/:lines nsSwitchLines)uj ([]lineType:`DEF;row:potentialItems;content:lines potentialItems);
  items:update fills nsSwitch from items;
  items:select lineType, row, ?[nsSwitch in\: ``.; content; string[nsSwitch],'".",'content] from delete from items where lineType=`NS;

  docItems:([]lineType:`$/:lines[doc][;1];row:doc;content:3_/:lines doc);

  info:`row xasc docItems,items;
  info:select first lineType, row, content by itemId:sums lineType<>\:`$"-" from info;
  info:select from info where not lineType in `L`A`V`D`S;
  info:delete from info where prev[lineType] in ``DEF, lineType=`DEF;
  functions:delete funcId from select 
    item:@[{`$first ":"vs x};;`$]first content'[;0] where lineType=`DEF,
    itemType:(`F`G!`FUNCTION`GLOBAL) first lineType,
    descr:first content where lineType in\: `F`G,
    params:@[.doc.p.parseParams;;{`parName`parType`parDesc`parseErr!(`;`;"";"parsing error:",x)}] each content where lineType=`P,
    ret:first content where lineType=`R,
    examples:first content where lineType=`E,
    file,
    raw:([]lineType;content)
    by funcId:(sums 0b,-1_`DEF = lineType) from info where lineType in `G`F`P`E`R`DEF;
  functions:update params:count[i]#enlist ([]parName:`symbol$();parType:`symbol$();parDesc:();parseErr:()) from functions where params~\:();
  functions:update ns:` sv/: 2#'` vs/:item from functions;
  :functions;
  };

//----------------------------------------------------------------------------//
/F/ Parse function parameters.
.doc.p.parseParams:{[x]
  line0:first x;
  //detect continuation of the description
  if[null colon:first where ":"=line0; :`parName`parType`parDesc`parseErr!(`;`;"";"invalid parameter documentation format")];
  parName:`$trim colon#line0;
  rest:1_colon _ line0;
  dash:first where "-"=rest;
  if[null dash; :`parName`parType`parDesc`parseErr!(parName;`$rest;"";"")];
  :`parName`parType`parDesc`parseErr!(parName;`$trim dash#rest;trim enlist[1_dash _ rest],1_x;"")
  };

//----------------------------------------------------------------------------//
/E/ .doc.p.analyzeMem[]
.doc.p.analyzeMem:{[]
  itemList:([]ns:`.; item:key `.);
  itemList,:update item:?[null item;ns;(` sv' ns,'item)] from ungroup update item:key'[ns] from ([]ns:` sv/:`,/:key[`] except `q`Q`h`o`j);
  itemList:update itemType:`NAMESPACE from itemList where .doc.p.isNs'[item];
  itemList,:ungroup select ns, item:.Q.dd''[item;key'[item]except'`], itemType:` from  itemList where itemType~'`NAMESPACE, not ns~'item;
  itemList:update qType:{type value x}'[item], size:{-22!value x}'[item]  from itemList;
  itemList:update itemType:`FUNCTION from itemList where qType>=100h;
  itemList:update itemType:`GLOBAL from itemList where null itemType;
  itemList:update funcParams:{a:value[value x][1];$[a~enlist`;`symbol$();a]}'[item] from itemList where qType=100h;
  itemList:update proj:{p:value[value x];a:value[p 0][1];m:count[a]-count[p]-1;f:("::"~/:.Q.s1 each 1_p),m#1b;fix:count[a]#(::);fix[where not f]:(1_p)where not f;([]param:a;free:f;fix)}'[item] from itemList where qType=104h;
  itemList:update funcParams:{exec param from x where free}'[proj] from itemList where qType=104h;
  itemList
  };

//----------------------------------------------------------------------------//
.doc.p.isNs:{[name]
  $[99h<>type value name;0b;11h<>type key name;0b;not ` in key name;0b;(::)~name`]
  };

//----------------------------------------------------------------------------//
.doc.p.compareParams:{[mem;doc]
  c:min[count[doc],count[mem]];
  d:first where not (c#doc)~'(c#mem);
  if[not null d;:"parameter #",string[d]," ",.Q.s1[mem d]," is documented as ",.Q.s1[doc d]];
  if[c<count[doc];:"parameter #",string[c]," ",.Q.s1[doc c]," in the documentation is unexpected"];
  if[c<count[mem];:"parameter #",string[c]," ",.Q.s1[mem c]," is missing in the documentation"];
  :""
  };

//----------------------------------------------------------------------------//
/
.test.test:max'
type each ({};{x};{x+y};{x+y}[1];{x+y}[;1];)
