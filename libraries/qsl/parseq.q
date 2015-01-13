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

/A/ DEVnet: Slawomir Kolodynski
/V/ 3.0
/D/ 2013-03-12

/S/ Parseq library:
/S/ Parseq is a Q clone of the Haskell's Parsec, a parser combinator library. Most parser names are the same as in the original, except when colliding with q keywords.

.sl.init[`parq];

\d .par

/S/ Notes:
/S/ All parsers described here take a dictionary describing the parse state with key `s`cp`errp`errs`ast as the last parameter. 
/S/ The meaning of these fields is as follows : 
/S/ -- s - the string under parse. This is not modified by the parser
/S/ -- cp - the cursor position: the index of the next character in s to be parsed
/S/ -- errp - error position. This is integer null (0N) if there is no error. 
/S/ -- errs -  a list of error strings 
/S/ -- ast - the Abstract Syntax Tree: the value returned from parser
/S/ For brevity the parse state parameter is not included in function documentation. 
/S/ All parsers return the parse state dictionary. 
/S/ The return value described in the documentation concerns the `ast field of the parse state dictionary.

/----------- Functions to handle parse state -------------------------------------/

/F/ Creates the initial parse state for a string
/P/ s:STRING - the string to be parsed
/R/ :DICTIONARY[SYMBOL;ANY] - the parse state
initP:{[s] 
  if[()~s;s:""];
  if[10h <> type s;'"error:we can only parse strings"];
  (`s`cp`errp`errs`ast ! (s;0;0N;();())) 
  };

/F/ Adds an error message to a parse state
/P/ ps - a parse state
/P/ s - The errs field of the parse state contains the list of error messages. This string is appended to the list. This allows to build a stack trace of error messages.
/R/ :DICTIONARY[SYMBOL;ANY] - The parse state with the new error message added.
addErr:{[ps;s] ps[`errs],:enlist s;:ps};

/F/ Parses a string with provided parser
/P/ pa - the parser to be run
/P/ s - string to be parsed
parseTest:{[pa;s]
  ps:pa initP s;
  res:();
  if[0N<>ps`errp;:(enlist "error at position ",string ps`errp),ps`errs];
  :ps`ast;
  };

/------------- Basic parsers for characters -------------------------------------/

/F/ A parser that fails without consuming any input. Probably will not be used, but present for compatibility with the original Haskell's Parsec.
pzero:{[ps] :ps[`errp]:ps`cp;:ps};

/F/ Succeeds if the character is one of the given list of characters.
/P/ cs - a string with characters to try. 
/R/ the parsed character.
oneOf:{[cs;ps]
  if[0N <> ps`errp;:ps];
  s:ps`s;
  k:ps`cp;
  if[k>(count s)-1;:(`s`cp`errp`errs`ast)!(s;ps`cp;count s;enlist "oneOf:unexpected end of input";ps`ast)];
  if[any cs = s[k];:(`s`cp`errp`errs`ast)!(s;k+1;0N;();s[k])];
  :(`s`cp`errp`errs`ast)!(s;k;k;enlist "expected one of ", cs;ps`ast)
  };

/F/ Succeeds if the current character is NOT among the given list of characters.
/F/ Fails if the current position is beyond the string boundary.
/P/ cs:STRING - a string with disallowed characters
/R/ the parsed character
noneOf:{[cs;ps] 
  if[0N<>ps`errp;:ps];
  s:ps`s;
  k:ps`cp;
  if[k>-1+count s; // beyond string boundary, fail
    :(`s`cp`errp`errs`ast)!(s;k;k;enlist "noneOf:unexpected end of input";ps`ast)
    ];
  if[all cs<>s[k];:(`s`cp`errp`errs`ast)!(s;k+1;0N;();s[k])];
  :(`s`cp`errp`errs`ast)!(s;k;k;enlist "expected none of ", cs;ps`ast)
  };

/F/ Parses a single character
/P/ c - the character to be matched
/R/ the parsed character
char:{[c;ps]
  if[0N <> ps`errp;:ps];
  s:ps`s;
  k:ps`cp;
  if[k>(count s)-1;
    :(`s`cp`errp`errs`ast)!(s;k;count s;enlist "unexpected end of input";ps`ast)];
  if[c = s[k];:(`s`cp`errp`errs`ast)!(s;k+1;0N;();c)];
  :(`s`cp`errp`errs`ast)!(s;k;k;enlist "expected ",c;ps`ast)
  };


/F/ Parses a sequence of character. This corresponds to the string parser in Parsec, bits "string" is a keyword in q, hence pstring. 
/P/ st - the string to be matched
/R/ The parsed string. If failure, the error position indicates number of characters matched
pstring:{[st;ps]
  if[0N <> ps`errp;:ps];
  s:ps`s;
  k:ps`cp;
  m:count st;
  / length of the matched string exceeds the remaining input length 
  if[k>(count s)-m;
    :(`s`cp`errp`errs`ast)!(s;k;count s;enlist "unexpected end of input";ps`ast)];
  / succesful parse
  if[st~s[k+til m];:(`s`cp`errp`errs`ast)!(s;k+m;0N;();st)];
  / if not, how far we can go in matching
  n:(st[til l]=s[k+til l:min(count st;(count s)-k)])?0b;
  :(`s`cp`errp`errs`ast)!(s;k;k+n;enlist "expected ", st;ps`ast)
  };


/F/ Parses exactly one character satisfying certain condition.
/P/ p - a predicate that takes a character
/P/ err1 - error string for tracing 
/P/ err2 - error string for parser failure 
/R/ the parsed character
oneChar:{[p;err1;err2;ps]
  if[0N <> ps`errp;:ps];
  s:ps`s;
  k:ps`cp;
  if[k>(count s)-1; / we are at the end of the string
    ps[`errp]:count s;
    ps[`errs]:enlist "unexpected end of input";
    :ps;
    ];
  if[p[s[k]];:(`s`cp`errp`errs`ast)!(s;k+1;0N;();s[k])];  // succesful parse
  :(`s`cp`errp`errs`ast)!(s;k;k;enlist err1,err2;ps`ast) // failed parse
  };

/F/ Parses any printable character.
/R/ the character parsed.
anyChar:{[ps]
  :oneChar[{(" " <= x) and "~" >= x};"anyChar:";"expected a printable character";ps]
  };

/----------------------- helper functions --------------------------------------
/F/ Returns 1b for digits
isdigit:{("0" <= x) and "9" >= x};

/F/ Returns 1b for white space characters (i.e. " \f\t\r\n\v")
isspace:{any " \t\r\n\011\012" = x};

/F/ number of charaters of string starting from index that satisfies a condition
/P/ s:STRING - string to be checked
/P/ k:LONG - starting position
/P/ f:FUNCTION - a predicate taking a character
/R/ :LONG - number of prefix characters in k_s that satisfy f
/E/ skipIf["abc    d";3;{x=" "}]=4
skipIf:{[s;k;f] :k+(f each k _ s)?0b};
/---------------------------------------------------------------------
/F/ Parses a lower or upper case alphabetic character
letter:{[ps]
  ps1:oneOf[.Q.A,.Q.a] ps;
  if[0N<>ps1`errp;ps1[`errs]:enlist "expected an upper case or lower case character"];
  :ps1;
  };

/F/ Parses a lower or upper case hex digit
hexDigit:{[ps]
  ps1:oneOf["1234567890abcdefABCDEF"] ps;
  if[0N<>ps1`errp;ps1[`errs]:enlist "expected a hex digit"];
  :ps1;
  };

/F/ Parses a decimal digit
digit:{[ps]
  ps1:oneOf["1234567890"] ps;
  if[0N<>ps1`errp;:addErr[ps1;"expected a decimal digit"]];
  :ps1
  };

/F/ Parses a newline character ('\n'). 
/R/ a newline character. 
newline:{[ps]
  :oneChar[{x="\n"};"newline:";"expected the \\n character"]
  };

/F/ Parses a tab character ('\t'). Returns a tab character.
tab:{[ps]
  :oneChar[{x="\t"};"tab:";"expected the \\t character"]
  };

/F/ Parses the space character 
/R/ the parsed character.
space:{[ps]
  :oneChar[{x~" "};"space:";"expected a space";ps]
  };

/F/ Parses a white space character (any character in " \t\r\n\v\f"). 
/R/ the parsed character.
whiteChar:{[ps]
  :oneChar[isspace;"whiteChar:";"expected a white space character";ps]
  };

/F/ Skips zero or more spaces. Does not change the AST. 
spaces:{[ps]
  if[0N <> ps`errp;:ps];
  s:ps`s;
  k:skipIf[s;ps`cp;{x~" "}];
  :(`s`cp`errp`errs`ast ! (s;k;0N;();ps`ast))
  };

/F/ Skips one or more space.
spaces1:{[ps]
  if[0N <> ps`errp;:ps];
  s:ps`s;
  k:ps`cp;
  ps1:spaces space ps;
  if[0N<>ps1`errp;:(`s`cp`errp`errs`ast)!(s;k;k;ps1`errs;ps`ast)];
  :(`s`cp`errp`errs`ast ! (s;ps1`cp;0N;();ps`ast))
  };

/F/ Skips zero or more white space characters. Does not change the AST. 
whiteChars:{[ps]
  if[0N <> ps`errp;:ps];
  s:ps`s;
  k:skipIf[s;ps`cp;isspace];
  :(`s`cp`errp`errs`ast ! (s;k;0N;();ps`ast))
  };

/F/ Skips one or more white space characters.
whiteChars1:{[ps]
  if[0N <> ps`errp;:ps];
  s:ps`s;
  k:ps`cp;
  ps1:whiteChars whiteChar ps;
  if[0N<>ps1`errp;:(`s`cp`errp`errs`ast) ! (s;k;k;ps1`errs;ps`ast)];
  ps1[`ast]:ps`ast;
  :ps1;
  };

/F/ Succeeds iff we are at the end of input. Does not change the cursor position. 
/R/ :ANY - unchanged AST.
eof:{[ps]
  if[0N <> ps`errp;:ps];
  / succesful parse
  if[(ps`cp) >= count ps`s;:ps];
  / unsuccesful parse
  ps[`errp`errs]:(ps`cp;enlist "Not the end of input");
  :ps
  };

/F/ Consumes and returns the next character, if it satisfies the specified predicate.
/P/ p:FUNCTION - a boolean function defined on characters.
/R/ the character that is actually parsed.
satisfy:{[p;ps]
  :oneChar[p;"satisfy:";"expected a character satisfying the predicate";ps]
  };

/F/ Applies a parser zero or more times, ignoring the result (just incrementing the cursor position). Doses not modify AST. Always succeeds.
/P/ pa - the parser for the string to be ignored.
/R/ The AST passed as argument
skipMany:{[pa;ps]
  if[0N<>ps`errp;:ps];
  res:1_{(0N~x`errp) and (count x`s)>x`cp} pa\ ps;
  // last should be dropped only if parser failed
  if[0N<>last res`errp;res:(-1)_res];
  cp:$[0~count res;ps`cp;last res`cp]; //parser may fail at first try, then count res=0
  :(`s`cp`errp`errs`ast)!(ps`s;cp;0N;();ps`ast);
  };

/F/ Applies a parser one or more times, skipping its result and not modifying the AST. 
/P/ pa - the parser for the text to be skipped
/R/ The last parsed AST.
skipMany1:{[pa;ps]
  if[0N<>ps`errp;:ps];
  s:ps`s;
  k:ps`cp;
  ps1:pa[ps];
  if[(ps1`errp)<>0N;:(`s`cp`errp`errs`ast)!(s;k;k;ps1`errs;ps`ast)];
  ps2:skipMany[pa] ps1;
  :(`s`cp`errp`errs`ast)!(s;ps2`cp;0N;();ps`ast)
  };

/F/ Tries to apply the parsers in the list ps in order, until one of them succeeds.
/P/ pas - a list of parsers to try
/R/ the value of the succeeding parser. 
choice:{[pas;ps]
  if[0N <> ps`errp;:ps];
  iok:(0N=(res:pas@\:ps)`errp)?1b;
  if[iok=count pas;ps[`errp]:ps`cp;ps[`errs]:(raze res`errs),(enlist "all choces failed");:ps];
  :res[iok]
  };

/F/ Parses n occurrences of a pattern in sequence. 
/P/ n - number of occurences of the pattern
/P/ pa - the parser for the pattern
/R/ :LIST[ANY] - list of values returned by pa. If n is smaller or equal to zero, the parser returns the empty list.
pcount:{[n;pa;ps]
  if[0N <> ps`errp;:ps];
  s:ps`s;
  k:ps`cp;
  if[n <= 0;:(`s`cp`errp`errs`ast)!(k;0N;();())];
  res:();
  ps1:ps;
  while[n>0;
    ps1:pa ps1;
    if[0N <> ps1`errp;:(`s`cp`errp`errs`ast)!(s;k;ps1`errp;ps1`errs;ps`ast)];
    res:res,enlist ps1`ast;
    n-:1
    ];
  :(`s`cp`errp`errs`ast)!(s;ps1`cp;ps1`errp;ps1`errs;res)
  };

/F/ Parser between[open;close;pa] parses open, followed by p and finally close. 
/P/ open - the opening parser
/P/ close - the closing parser
/P/ pa - parser for the pattern
/R/ the value returned by pa
between:{[open;close;pa;ps]
  if[0N <> ps`errp;:ps];
  s:ps`s;
  k:ps`cp;
  ps1:open ps;
  if[0N <> ps1`errp;:(`s`cp`errp`errs`ast)!(s;k;ps1`errp;ps1`errs;ps`ast)];
  ps2:pa ps1;
  if[0N <> ps2`errp;:(`s`cp`errp`errs`ast)!(s;k;ps2`errp;ps2`errs;ps`ast)];
  ps3:close ps2;
  if[0N <> ps3`errp;:(`s`cp`errp`errs`ast)!(s;k;ps3`errp;ps3`errs;ps`ast)];
  :(`s`cp`errp`errs`ast ! (s;ps3`cp;0N;();ps2`ast))
  };

/F/ Applies a parser, returning its output if succefsul, or the default ast if failure. 
/P/ a - the default ast, returned when pa fails
/P/ pa - the parser to be tried
/R/ If the parser pa fails it returns value in a, otherwise the value returned by pa. Always succeeds.
option:{[a;pa;ps]
  if[0N <> ps`errp;:ps];
  s:ps`s;
  k:ps`cp;
  ps1:pa ps;
  if[0N <> ps1`errp;:(`s`cp`errp`errs`ast ! (s;k;0N;();a))];
  :ps1
  };


// this implementation of many is a bit shorter than the one below and does not use while, but is about 5% slower
many:{[pa;ps]
  if[0N <> ps`errp;:ps];
  res:{(0N~x`errp) and (count x`s)>x`cp} pa\ ps;
  if[1~count res;:(`s`cp`errp`errs`ast)!(ps`s;ps`cp;0N;();())];
  res:1_res;
  // last should be dropped only if parser failed
  if[0N<>last res`errp;
    if[1~count res;:(`s`cp`errp`errs`ast)!(ps`s;ps`cp;0N;();())]; //parser may fail at first try, then count res=1 here
    res:(-1)_res;
    ];
  :(`s`cp`errp`errs`ast)!(ps`s;last res`cp;0N;();res`ast);
  };

/F/ Parses zero or more occurrences of the given pattern. Always succeeds.
/P/ pa - the parser to be repeatedly applied
/R/ :LIST[ANY] - the list of the AST's returned by pa. 
many:{[pa;ps]
  if[0N <> ps`errp;:ps];
  s:ps`s;
  k:ps`cp;
  ps1:pa[ps];
  res:();
  while[0N=ps1`errp;
    k:ps1`cp;
    res:res,(enlist ps1`ast);
    / stop if we are beyond the string boundary. This protects against
    / using many on parsers that succeed on space. Q returns space
    / when a string is accessed beyond its boundary.
    if[(ps1`cp)>-1+count s;:(`s`cp`errp`errs`ast)!(s;k;0N;();res)];
    ps1:pa[ps1]
    ];
  :(`s`cp`errp`errs`ast)!(s;ps1`cp;0N;();res)
  };

/F/ Parses one or more occurrences of the given pattern.
/P/ pa - the parser to be repeatedly applied
/R/ LIST[ANY] - the list of ASTs returned by pa.
many1:{[pa;ps]
  if[0N <> ps`errp;:ps];
  s:ps`s;
  k:ps`cp;
  ps1:pa[ps];
  if[(ps1`errp) <> 0N;:(`s`cp`errp`errs`ast)!(s;k;ps1`errp;ps1`errs;ps`ast)];
  ps2:many[pa] ps1;
  :(`s`cp`errp`errs`ast)!(s;ps2`cp;0N;();(enlist ps1`ast),ps2`ast)
  };


/F/ Parses zero or more occurrences of a pattern, separated by a separator.
/P/ pa - the parser to be repeatedly applied 
/P/ sep - parser for the separator
/R/ :LIST[ANY] - list of values returned by pa.
sepBy:{[pa;sep;ps]
  if[0N <> ps`errp;:ps];
  s:ps`s;
  k:ps`cp;
  ps1:pa[ps];
  res:();
  while[(ps1`errp) = 0N;
    k:ps1`cp;
    res:res, (enlist ps1`ast);
    ps1:pa sep ps1
    ];
  :(`s`cp`errp`errs`ast)!(s;k;0N;();res)
  };

/F/ Parses one or more occurrences of a pattern, separated by a separator.
/P/ pa - the parser to be applied repeatedly
/P/ sep - parser for the separator
/R/ :LIST[ANY] - list of values returned by pa.
sepBy1:{[pa;sep;ps]
  if[0N <> ps`errp;:ps];
  s:ps`s;
  k:ps`cp;
  ps1:pa ps;
  if[(ps1`errp) <> 0N;:(`s`cp`errp`errs`ast)!(s;k;ps1`errp;ps1`errs;ps`ast)];
  res:();
  while[(ps1`errp)=0N;
    k:ps1`cp;
    res:res,(enlist ps1`ast);
    ps1:pa sep ps1
    ];
  :(`s`cp`errp`errs`ast)!(s;k;0N;();res)
  };
  
/F/ parses a list of parsers sequentially. Fails if any of the parsers fails.
/P/ lpars:LIST[FUNCTION} - a list of parsers
/R/ :LIST[ANY] - list of results returned by lpars
sequence:{[lpars;ps]
    if[0N<>ps`errp;:ps];
    if[0~count lpars;ps[`ast]:();:ps];
    ps1:(first lpars) ps;
    if[0N<>ps1`errp;:ps1];
    ps2:sequence[1_lpars] ps1;
    if[0N<>ps2`errp;:ps2];
    ps2[`ast]:(enlist ps1`ast),ps2`ast;
    :ps2
    };

/F/ Parses zero or more occurrences of a pattern, seperated and ended by a separator. Always succeeds.
/P/ pa - the parser to be applied repeatedly
/P/ sep - parser for the separator
/R/ :LIST[ANY] - list of values returned by pa
endBy:{[pa;sep;ps]
  if[0N<>ps`errp;:ps];
  s:ps`s;
  k:ps`cp;
  res:();
  ps2:sep ps1:pa ps;
  while[(ps2`errp) = 0N;
    res:res, (enlist ps1`ast);
    ps2:sep ps1:pa ps2
    ];
  :(`s`cp`errp`errs`ast)!(s;ps2`cp;0N;();res)
  };

/F/ Parses one or more occurrences of a pattern, separated and ended by a separator.
/P/ pa - the parser to be applied repeatedly
/P/ sep - parser for the separator
/R/ :LIST[ANY] - list of values returned by pa
endBy1:{[pa;sep;ps]
  if[0N <> ps`errp;:ps];
  s:ps`s;
  k:ps`cp;
  res:();
  ps2:sep ps1:pa ps;
  if[(ps2`errp)<>0N;:(`s`cp`errp`errs`ast)!(s;k;ps2`errp;ps2`errs;ps`ast)];
  while[(ps2`errp) = 0N;
    j:ps2`cp;
    res:res,(enlist ps1`ast);
    ps2:sep ps1:pa ps2
    ];
  :(`s`cp`errp`errs`ast)!(s;j;0N;();res)
  };

/F/ Parses zero or more occurrences of a pattern, separated and optionally ended by separator.
/P/ pa - the parser to be applied repeatedly
/P/ sep - the parser for the separator
/R/ :LIST[ANY] - list of values returned by pa. This parser always succeeds.
sepEndBy:{[pa;sep;ps]
  if[0N <> ps`errp;:ps];
  s:ps`s;
  ps1:sepBy[pa;sep;ps];
  j:ps1`cp;
  ps2:sep ps1;
  if[0N <> ps2`errp;j:ps2`cp];
  :(`s`cp`errp`errs`ast ! (s;j;0N;();ps1`ast))
  };

/F/ Parses one or more occurrences of a pattern, separated and optionally ended by separator.
/P/ pa - the parser to be applied repeatedly
/P/ sep - the parser for the separator
/R/ :LIST[ANY] - list of values returned by pa
sepEndBy1:{[pa;sep;ps]
  if[0N <> ps`errp;:ps];
  s:ps`s;
  ps1:sepBy1[pa;sep;ps];
  if[0N <> ps1`errp;:(`s`cp`errp`errs`ast)!(s;ps`cp;ps1`errp;ps1`errs;ps`ast)];
  j:ps1`cp; 
  ps2:sep ps1;
  if[0N <> ps2`errp;j:ps2`cp];
  :(`s`cp`errp`errs`ast)!(s;j;0N;();ps1`ast)
  };

/F/ Parses zero or more occurrences of a pattern, separated by another one. Always succeeds.
/P/ pa - parser for the pattern
/P/ op - a parser for the separator. This parser should return dyadic (binary) function (in the ast field).
/P/ x0 - default value to be returned in case no pa is matched
/R/ Returns:a value obtained by a left associative application of all functions returned by op to the values returned by pa. If there are zero occurrences of pa, the value x0 is returned. 
chainl:{[pa;op;x0;ps]
  if[0N <> ps`errp;:ps];
  s:ps`s;
  k:ps`cp;
  ps1:pa[ps];
  / zero occurences of pa
  if[0N <> ps1`errp;:(`s`cp`errp`errs`ast ! (s;k;0N;();x0))];
  / we have at least one value
  res:ps1`ast;
  j:ps1`cp; / last known good position
  ps1:pa psop:op ps1;
  while[0N = ps1`errp;
    res:(psop`ast)[res;ps1`ast];
    j:ps1`cp;
    ps1:pa psop:op ps1;
    ];
  :(`s`cp`errp`errs`ast ! (s;j;0N;();res))
  };

/F/ Parses one or more occurrences of a pattern, separated by another one.
/P/ pa - parser for the pattern
/P/ op - parser for the separator. This parser should return dyadic (binary) function (in the ast field).
/R/ a value obtained by a left associative application of all functions returned by op to the values returned by pa. 
chainl1:{[pa;op;ps]
  if[0N <> ps`errp;:ps];
  s:ps`s;
  k:ps`cp;
  ps1:pa[ps];
  if[0N <> ps1`errp;
    :(`s`cp`errp`errs`ast)!(s;k;k;enlist "chainl1:no initial value found";ps`ast)
    ];
  :chainl[pa;op;0;ps]
  };

/F/ Applies a list of operations to a list of arguments (this is not a parser)
/P/ ops -  a list of dyadic (binary) operations - one shorter than the list of arguments. This condition is not checked.
/P/ args - a list of arguments
/R/ the result of the right-associative application of the operation to the list of arguments. 
/E/ applyChainr[(f0;f1;f2);(x0;x1;x2;x3)] = x0 f0 (x1 f1 (x2 f2 x3)) (writing f's infix)
/E/ applyChainr[({x-y};{x*y};{x+y};(3;2;1;0)] = 1 
  applyChainr:{[ops;args]
    oa:reverse ops {(x;y)}' args[til count ops];
    f:{[a;p] p[0][p[1];a] };
    :(last args) f/ oa
    };

/R/ Parses zero or more occurrences of a pattern, separated by another one. This parser always succeeds.
/P/ pa - parser for the pattern
/P/ op -  parser for the separator. This parser must return a dyadic (binary) function in the ast field.
/P/ x0 - default value to be returned when no pa is matched
/R/ a value obtained by a right associative application of all functions returned by op to the values returned by pa. Returns x0 if there are no occurrences of the pattern.
chainr:{[pa;op;x0;ps]
  if[0N <> ps`errp;:ps];
  s:ps`s;
  k:ps`cp;
  ps1:pa[ps];
  / zero occurences of pa
  if[0N <> ps1`errp;:(`s`cp`errp`errs`ast)!(s;k;0N;();x0)];
  pas:enlist ps1`ast; / the list of arguments
  ops:(); / the list of operations
  j:ps1`cp; / last known good position
  ps1:pa psop:op ps1;
  while[0N = ps1`errp;
    ops,:enlist psop`ast;
    pas,:enlist ps1`ast;
    j:ps1`cp;
    ps1:pa psop:op ps1;
    ];
  :(`s`cp`errp`errs`ast ! (s;j;0N;();applyChainr[ops;pas]))
  };

/F/ Parses one or more occurrences of a pattern, separated by another one.
/P/ pa - parser for the pattern
/P/ op -  parser for the separator. This parser must return a dyadic (binary) function in the ast field.
/R/ a value obtained by a right associative application of all functions returned by op to the values returned by p. 
chainr1:{[pa;op;ps]
  if[0N <> ps`errp;:ps];
  s:ps`s;
  k:ps`cp;
  ps1:pa[ps];
  / zero occurences of pa
  if[0N <> ps1`errp;
    :(`s`cp`errp`errs`ast)!(s;k;k;enlist "chainr1:no initial value found";ps`ast)
    ];
  :chainr[pa;op;0;ps]
  };

/F/ Applies a parser zero or more times until the other parser succeeds.
/P/ pa - parser for the pattern to be repeated
/P/ end - parser for the ending pattern
/R/ :LIST[ANY] - The list of values returned by pa. Note that if the end parser may parses some patterns that are parsed by pa, this will stop the parsing.
manyTill:{[pa;end;ps]
  if[0N <> ps`errp;:ps];
  s:ps`s;
  k:ps`cp;
  ps1:end ps;
  ps2:pa ps;
  res:enlist ps2`ast;
  while[0N <> ps1`errp;
    if[(ps1`errp) > -1 + count s; // end of string, the end parser fails
      :(`s`cp`errp`errs`ast)!(s;k;ps1`errp;enlist "manyTill:input ended, end pattern not found";ps`ast)];
    ps2:pa ps2;
    if[0N <> ps2`errp; // both the end parser and the pattern parser fail
      :(`s`cp`errp`errs`ast)!(s;k;ps2`errp;enlist "manyTill:end mark not found when pattern failed";ps`ast)];
    res:res, (enlist ps2`ast);
    ps1:end ps2
    ];
  :(`s`cp`errp`errs`ast ! (s;ps1`cp;0N;();res))
  };

/F/ Succeeds when the parser given as argument fails. Does not consume any input.
/F/ This parser is not included in Parsec. Probably can be composed from other parsers, but still handy to have. 
/R/ unchanged AST
notFollowedBy:{[pa;ps]
  if[0N <> ps`errp;:ps];
  s:ps`s;
  k:ps`cp;
  ps1:pa ps;
  / succesful parse:pa failed
  if[0N <> ps1`errp;:ps];
  :(`s`cp`errp`errs`ast)!(s;k;k;enlist "notFollowedBy:excluded end pattern encountered";ps`ast)
  };

/F/ Succeeds only if another parser fails. This parser is not included in Parsec.
/P/ pa1 - parser to be parsed
/P/ pa2 - parser to fail.
/R/ Result from parsing pa1 if pa2 fails, fails otherwise.
butNot:{[pa1;pa2;ps]
  ps1:pa2 ps;
  if[0N <> ps1`errp;:pa1 ps];
  ps[`errp]:ps`cp;
  :addErr[ps;"butNot:unexpected pattern"];
  };

/F/ Runs a parser and supresses error if it fails. Should be rarely used as in this Parsec implementation parsers that fail don't consume input.
/P/ pa - a parser to run
/R/ the result of parsing pa if no error, otherwise unchanged parse state.
try:{[pa;ps]
  ps1:pa ps;
  if[0N <> ps1`errp;:ps];
  :ps1
  };

\d .
