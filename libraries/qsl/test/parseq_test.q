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

/S/ A test suite for functions defined in the <parseq.q> file.
/A/ SKO
/D/ 2013.03.16
/V/ 1.2
/T/ q test/parseq_test.q --noquit -p 5001

system "l sl.q";
system "l pe.q";
system "l event.q";
system "l parseq.q";
system "l lib/qspec/qspec.q";

.sl.init[`parseq_test];

\d .par

.tst.desc["[parseq.q] pstring, noneOf, oneOf, letter, anyChar, hexDigit, spaces"]{
  before{};
  after{};
  should["parse fixed strings"]{
    (pstring["end"] pstring["ble"] initP "blend") mustmatch (`s`cp`errp`errs`ast)!("blend";3;5; enlist "unexpected end of input";"ble");
    (pstring["end"] noneOf["abc"] oneOf["abc"] initP "blend") mustmatch (`s`cp`errp`errs`ast)!("blend";5;0N;();"end");
    (letter anyChar initP "a_b") mustmatch (`s`cp`errp`errs`ast)!("a_b";1;1;enlist "expected an upper case or lower case character";"a");
    (oneOf["0123456789abcdefABCDEF"] pstring["0x"] spaces1 pstring["A:"] initP "A: 0xA") mustmatch (`s`cp`errp`errs`ast)!("A: 0xA";6;0N;();"A");
    (spaces pstring["K:"] initP "K: ") mustmatch (`s`cp`errp`errs`ast)!("K: ";3;0N;();"K:");
    //noneOf fails on the end of the string
    (noneOf["abc"] pstring["efg"] initP "efg") mustmatch (`s`cp`errp`errs`ast)!("efg";3;3; enlist "noneOf:unexpected end of input";"efg");
    };
  };


.tst.desc["[parseq.q] many, many1,skipMany1, sepBy, sepBy1,sepEndBy,sepEndBy1,pcount,between,choice,manyTill,parseTest"]{
  before{};
  after{};
  should["parse examples"]{
    (pstring["end"] spaces1 many["digit"] spaces1 pstring["begin"] initP "begin12 end") mustmatch (`s`cp`errp`errs`ast)!("begin12 end";5;5;(enlist "space:expected a space");"begin");
    (many1[hexDigit] pstring["0x"] initP "0x23ABC") mustmatch (`s`cp`errp`errs`ast)!("0x23ABC";7;0N;();"23ABC");
    .dbg.skipMany1:(skipMany1[char["a"]] pstring["bc"] initP "bca");
    (skipMany1[char["a"]] pstring["bc"] initP "bca") mustmatch (`s`cp`errp`errs`ast)!("bca";3;0N;();"bc");
    (sepBy[hexDigit;char[","]] initP "A,B,C,1,2,3") mustmatch (`s`cp`errp`errs`ast)!("A,B,C,1,2,3";11;0N;();"ABC123");
    (sepBy1[hexDigit;char[","]] spaces pstring["K:"] initP "K:") mustmatch (`s`cp`errp`errs`ast)!("K:";2;2; enlist "expected a hex digit";"K:");
    // parses nonepty sequences of digits, with the sequences (not digits) separated by semicolons, 
      // the last sequence has to end with a semicolon. In this example
    // the parser consumes "01;" and stops, setting the current position at 3. 
    (endBy1[many1 digit;char ";"] initP "01;02") mustmatch (`s`cp`errp`errs`ast)!("01;02";3;0N;();enlist "01");
    // last separator is optional in sepEndBy
    (sepEndBy[many1 digit;char ";"] initP "01;02") mustmatch (`s`cp`errp`errs`ast)!("01;02";5;0N;();("01";"02"));
    (sepEndBy[many1 digit;char ";"] initP "01;02;") mustmatch (`s`cp`errp`errs`ast)!("01;02;";5;0N;(); ("01";"02"));
    // sepEndBy allows for zero occurences of the pattern (many1 digit in this case)
    (sepEndBy[many1 digit;char ";"] initP ";01") mustmatch (`s`cp`errp`errs`ast)!(";01";0;0N;();());
    // sepEndBy1 requires at least one pattern. Here no input is consumed
    // as the pattern (many1 digit) was not matched at the start of the string
    (sepEndBy1[many1 digit;char ";"] initP ";01") mustmatch (`s`cp`errp`errs`ast)!(";01";0;0;("expected one of 1234567890";"expected a decimal digit");());
    (pcount[3;pstring"ab"] initP "ababab") mustmatch (`s`cp`errp`errs`ast)!("ababab";6;0N;();("ab";"ab";"ab"));
    (between[char"(";char")";pstring"abc"] initP "(abc)") mustmatch (`s`cp`errp`errs`ast)!("(abc)";5; 0N;();"abc");
    (pstring["abc"] option["no space";char" "] initP "abc") mustmatch (`s`cp`errp`errs`ast)!("abc";3; 0N;();"abc");
    (pstring["abc"] option["no space";char" "] initP " abc") mustmatch (`s`cp`errp`errs`ast)!(" abc";4;0N;();"abc");
    (choice[(pstring"abc";pstring"de")] initP "abc") mustmatch (`s`cp`errp`errs`ast)!("abc";3;0N;();"abc");
    (choice[(pstring"abc";pstring"de")] initP "def") mustmatch (`s`cp`errp`errs`ast)!("def";2; 0N;();"de");
    (manyTill[char["a"]; char["b"]] initP "aaab") mustmatch (`s`cp`errp`errs`ast)!("aaab";4;0N;();"aaa");
    (manyTill[char["a"]; char["b"]] initP "aaa") mustmatch (`s`cp`errp`errs`ast)!("aaa";0;3;enlist "manyTill:input ended, end pattern not found";());
    //the end parser takes precedense when both the main and end parsers succeed
    (manyTill[anyChar; char["b"]] initP "aaba") mustmatch (`s`cp`errp`errs`ast)!("aaba";3;0N;();"aa");
    // but see this: the end pattern is not noticed bc it is consumed by the main pattern
    (manyTill[pstring["ab"];char["b"]] initP "abab") mustmatch (`s`cp`errp`errs`ast) ! ("abab";0;4;enlist "manyTill:input ended, end pattern not found";());
    parseTest[butNot[pstring["abc"];pstring["abcd"]]; "abcde"] mustmatch ("error at position 0"; "butNot:unexpected pattern");
    parseTest[{ char["a"] try[pstring"abc"] x}; "ab"] mustmatch "a";
    parseTest[{eof pstring["abc"] x}; "abc"] mustmatch "abc";
    parseTest[{eof pstring["abc"] x}; "abc "] mustmatch ("error at position 3"; "Not the end of input");
    parseTest[{notFollowedBy[eof] pstring["abc"] x}; "abc "] mustmatch "abc";
    parseTest[{notFollowedBy[eof] pstring["abc"] x}; "abc"] mustmatch ("error at position 3";"notFollowedBy:excluded end pattern encountered");
    // oneChar and empty string
    (parseTest[butNot[anyChar;char")"]] "") mustmatch ("error at position 0";"unexpected end of input");
    (parseTest[.par.anyChar] "") mustmatch ("error at position 0";"unexpected end of input");
    (parseTest[{.par.between[.par.pstring["${"];.par.char["}"];digit] x }] "test") mustmatch ("error at position 0";"expected ${");
    (parseTest[{.par.between[.par.pstring["${"];.par.char["}"];digit] x }] "${3}") mustmatch "3";
    (parseTest[sequence(digit;pstring" is a digit")] "3 is a digit") mustmatch ("3";" is a digit");
    (parseTest[sequence(char"(";pstring"abc";char")")] "(abc)") mustmatch ("(";"abc";")");
 
    };
  };

.tst.desc["[parseq.q] chainl,chainl1,chainr"]{
  before{
    // Chains are tricky to test. Lest write some parsers
    // Function: digval
    // Parses a digit and returns its value
    //
    // Returns: an integer that is the value of the digit.
    .tst.par.digval: { [ps]
      ps1: digit ps;
      if[0N <> ps1`errp; :ps1];
      ps1[`ast]:value ps1`ast;
      :ps1;
      };

    // Function: add
    // Parses addition. 
    //
    // Returns: a function that adds two numbers
    .tst.par.add: { [ps]
      ps1: char["+"] ps;
      if[0N <> ps1`errp; :ps1];
      / succesful parse
      ps1[`ast]:{x+y};
      :ps1;
      };

    // Function: mul
    // Parses multiplication. 
    //
    // Returns: a function that multiplies two numbers
    .tst.par.mul: { [ps]
      ps1: char["*"] ps;
      if[0N <> ps1`errp; :ps1];
      / succesful parse
      ps1[`ast]:{x*y};
      :ps1;
      };

    // Function: operation
    // Parses a choice of "+" or "-"
    //
    // Returns: a function that multiplies or adds two numbers. 
    .tst.par.operation: { [ps]
      if[0N <> ps`errp; :addErr[ps;"operation"]];
      :choice[(.tst.par.add;.tst.par.mul)] ps;
      };
    }; // before
  after{};
  should["parse expressions"]{
    / now we can parse expressions
    parseTest[chainl[.tst.par.digval;.tst.par.operation;0];"1+2*3"] mustmatch 9;
    parseTest[chainl1[.tst.par.digval;.tst.par.operation];"  "] mustmatch ("error at position 0"; "chainl1:no initial value found");
    parseTest[chainr[.tst.par.digval;.tst.par.operation;0];"1+2*3"] mustmatch 7;
    };
  };


\d .
