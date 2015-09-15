## Overview

Similarly to other programming languages, we document q scripts using in-line comments with simple tags. These allow to produce API documentation in HTML format.

## Documenting your q code

### Available tags

```j
/L/ 'L'icense
/S/ Script 's'ummary
/T/ Script star't'-up command
/A/ 'A'uthor
/D/ 'D'ate
/V/ 'V'ersion
/G/ 'G'lobal
/F/ 'F'unction
/P/ 'P'arameter
/R/ 'R'eturn value
/E/ 'E'xample
```

> **Note:**
> 
> As opposed to other available systems, each line has to contain a tag. For example, this will work:
> 
> ```j
> /F/ Description of the function
> /F/ Some other stuff about this function
> ```
> 
> and both lines  will be include in the documentation, whereas this:
> 
> ```j
> /F/ Description of the function
> // Some other stuff about this function
> ```
> 
> will only include the first line in the output documentation file.

#### License

Provides a license information. Each tag will be shown in html file in separate line and included in the `License` section. 

**Example:**

```j
/L/ Copyright (c) 2011 - 2014 Exxeleron GmbH
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
```

#### Script summary

Brief description of the script. Each tag will be shown in the html file in separate line and included in the `About` section. 

**Example:**

```j
/S/ sampleFile.q
/S/ This is a brief description of the functionality
```

> **Note:**
> 
> If you would like to show code example, start-up command, output from cmd, etc. within summary
> section, **don't use** `/E/` tag within.  Instead use `/S/` tags followed by `(start code)` and
> `(end)`:
> 
> ```j
> /S/ This is a summary section with an example
> /S/ (start code)
> /S/ q)4 4#16?100
> /S/ 56 90 63 28
> /S/ 51 64 68 43
> /S/ 61 11 84 25
> /S/ 31 0  51 29
> /S/ (end)
> /S/ Remaining text
> ```

#### Script start-up command

Command used to start up the script. Each tag will be shown in the html file in separate line.

**Example:**

```j
/T/ q sampleFile.q
/T/ q sampleFile.q -p 5001
```

#### Author

Script author(s). Each tag will be shown in html file in separate line and included in the `About` section. 

**Example:**

```j
/A/ Author1 Name a1.name@email.com
/A/ Author2 Name a2.name@email.com
```

#### Date

Creation date. Single tag included in the `About` section. 

**Example:**

```j
/D/ 2011.11.17
```

#### Version
Script version. Single tag included in the `About` section. 

**Example:**

```j
/V/ 1.0
```

#### Global

Global can be considered as any variable defined outside of the function body. This tag allows to provide a brief description of the global. Tags will be merged to show a single message in the output. Applies to variables without a namespace as  well as to private and non-private variables.

**Examples:**

```j
/G/ this is a typical global
myGlobal:100;

/G/ this is a namespace based global
.ns.var:`no;

/G/ this is a private,
/G/ namespace based global
.ns.p.var:`yes;
```

#### Function

Brief description of the function. Tags will be merged to show a single message in the output. Applies to global, private and non-private functions.

**Examples:**

```j
/F/ Fully global function
init:{[] 
  :2+2;
  };

/F/ Non-private, namespace based function
.ns.init:{[] 
  :2+2;
  };

/F/ Private, namespace based function
.ns.p.func:{[] 
  :2+2;
  };

/F/ Private, namespace based function
/F/ Equivalent to previous function
.ns.p.func:{[] :2+2}
```

> **Note:**
> 
> Please note that 'private' functions will not be included in the generated documentation. More
> details about `private` functions can be found
> [here](Exxeleron-q-coding-conventions#private-variables-and-functions).

#### Parameter

Each function parameter can be described in detail using this tag. The general pattern for each `/P/` tag looks as follows:

```j
/P/ paramName - description
```

Optionally, paramName can contain type of the parameter:

```j
/P/ paramName:dataType - description
```

**Example:**

```j
/F/ This function takes two parameters and adds them
/P/ a - some number
/P/ b:int - some other number of type int
.ns.addAandB:{[a;b]
  :a+b;
  };
```

#### Return value
Indicates function’s return value.

**Example:**

```j
/F/ Function that multiplies two numbers
/P/ first:int - this is a number
/P/ second:int - this is another number of type int
/R/ int - result of multiplication of two input numbers
.ns.multiply:{[first;second]
  :a*b;
  };
```

#### Example

Shows sample variable or sample call related to function definition. 
Each tag will be shown in html file in separate line and included in the `About` section. 

**Example:**

```j
/F/ This function takes three parameters and does nothing
/P/ a - first parameter 
/P/ b - second parameter
/P/ c - third parameter
/E/ .ns.doNothing[1;2;3]
/E/ .ns.doNothing[`sym;1f;()]
.ns.doNothing{[a;b;c]
  };
```

> **Note:**
> 
> This tag **only** applies to examples given for variable and function definitions, please see
> [this note](Documenting-q-code#script-summary)
> for using an example within `Summary` section.
