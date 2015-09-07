## Overview

`DevDoc` is written in Perl and allows to document q scripts using simple tags; produced
documentation is in HTML format.

## Installation

In order to use `DevDocs`, following packages need to be installed:

### `NaturalDocs`

Complete package is available for download from (NaturalDocs website)[http://www.naturaldocs.org/download.html] (version
1.52).

Few small modifications are required:
- in file `NaturalDocs.bat` please change one line from:

    ```
    perl NaturalDocs %NaturalDocsParams% 
    ```

    to:

    ```
    perl pathToNaturalDocs\NaturalDocs %NaturalDocsParams%
    ```

    For example, for NaturalDocs located in: `C:\NaturalDocs.1.52`, changed path should read:

    ```
    perl C:\NaturalDocs.1.52\NaturalDocs %NaturalDocsParams%
    ```
- in file: `NaturalDocs.1.52\Modules\NaturalDocs\Menu.pm` change following lines from: 

    ```perl
    use constant MAXFILESINGROUP => 6;
    use constant MINFILESINNEWGROUP => 3;
    ```

    to:
    
    ```perl
    use constant MAXFILESINGROUP => 1;
    use constant MINFILESINNEWGROUP => 1;
    ```
    
    (as per: http://sourceforge.net/projects/naturaldocs/forums/forum/279267/topic/2496639)
    
### Perl

Recommended Perl distribution (ActivePerl) can be downloaded from: http://www.activestate.com/activeperl/downloads. Once it’s installed, please ensure that following packages are installed:

- File-Next
- File-Path
- Log-Log4perl

by searching through Perl Package Manager.

### `DevDocs`

`DevDocs` configuration requires to update the path in the `devDoc.pl` file, which by default is set to:

```perl
# root path to natural docs
my $naturalDocsPath = "NaturalDocs";
```

For example, for `NaturalDocs` located in: `C:\NaturalDocs.1.52`, changed path should read:

```perl
# root path to natural docs
my $naturalDocsPath = "C:/NaturalDocs-1.52"
```

## Documenting your q code

### Available tags

- /L/ <strong>L</strong>icense
- /S/ <strong>S</strong>cript summary
- /T/ Script star<strong>t</strong>-up command
- /A/ <strong>A</strong>uthor
- /D/ <strong>D</strong>ate
- /V/ <strong>V</strong>ersion
- /G/ <strong>G</strong>lobal
- /F/ <strong>F</strong>unction
- /P/ <strong>P</strong>arameter
- /R/ <strong>R</strong>eturn value
- /E/ <strong>E</strong>xample

**Note:**

As opposed to other available systems, each line has to contain a tag. For example, this will work:

```
/F/ Description of the function
/F/ Some other stuff about this function
```

and both lines  will be include in the documentation, whereas this:

```
/F/ Description of the function
// Some other stuff about this function
```

will only include the first line in the output documentation file.

#### License

Provides a license information. Each tag will be shown in html file in separate line and included in the "License" section. 

**Example:**

```
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

Brief description of the script. Each tag will be shown in the html file in separate line and included in the "About" section. 

**Example:**

```
/S/ sampleFile.q
/S/ This is a brief description of the functionality
```

#### Script start-up command

Command used to start up the script. Each tag will be shown in the html file in separate line.

**Example:**

```
/T/ q sampleFile.q
/T/ q sampleFile.q -p 5001
```

#### Author

Script author(s). Each tag will be shown in html file in separate line and included in the "About" section. 

**Example:**

```
/A/ Author1 Name a1.name@email.com
/A/ Author2 Name a2.name@email.com
```

#### Date

Creation date. Single tag included in the "About" section. 

**Example:**

```
/D/ 2011.11.17
```

#### Version
Script version. Single tag included in the "About" section. 

**Example:**

```
/V/ 1.0
```

#### Global

Global can be considered as any variable defined outside of the function body. This tag allows to provide a brief description of the global. Tags will be merged to show a single message in the output. Applies to variables without namespace as  well as to private and non-private variables.

**Examples:**

```
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

```
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

**Note:**

Please note that 'private' functions will not be included in the generated documentation. More details about 'private' functions can be found [here](../Exxeleron-q-coding-conventions#private-variables-and-functions).

#### Parameter

Each function parameter can be described in detail using this tag. The general pattern for each `/P/` tag looks as follows:

```
/P/ paramName - description
```

Optionally, paramName can contain type of the parameter:

```
/P/ paramName:dataType - description
```

**Example:**

```
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

```
/F/ Function that multiplies two numbers
/P/ first:int - this is a number
/P/ second:int - this is another number of type int
/R/ int - result of multiplication of two input numbers
.ns.multiply:{[first;second]
  :a*b;
  };
```

#### Example

Shows sample call related to function definition. Each tag will be shown in html file in separate line and included in the "About" section. 

**Example:**

```
/F/ This function takes three parameters and does nothing
/P/ a - first parameter 
/P/ b - second parameter
/P/ c - third parameter
/E/ .ns.doNothing[1;2;3]
/E/ .ns.doNothing[`sym;1f;()]
.ns.doNothing{[a;b;c]
  };
```

## Running `DevDocs`

### General command format

General command to generate documentation looks as follows:

```
perl devDoc.pl -in inputPath -out outputPath -a 1 -p 0
```

where:

- `in` - input path to folder containing files for processing (mandatory parameter)
- `out` - path to output folder storing temporary files used by `NaturalDocs` and output HTML files containing the actual documentation (mandatory parameter)
- `a` - flag to indicate if tag `/A/` (authors) should be included (1) or omitted (0) (optional parameter)
- `p` - flag to indicate if private variables and functions should be included (1) or omitted (0); it assumes that privates are denoted by `p` in the name, eg. `.namespace.p.varOrFuncName` (optional parameter, default is set to 0 therefore in most cases `p` parameter can be omitted)

### Sample commands

#### Documentation without privates

```
> perl devDoc.pl -in c:\Projects\q\qsl\trunk -out c:\Projects\q\qsl\trunk\docs
```

Alternatively, flag 0 can be used to achieve the same effect:

```
> perl devDoc.pl -in c:\Projects\q\qsl\trunk -out c:\Projects\q\qsl\trunk\docs -p 0
```

Sample log information should include similar details:

```
> perl devDoc.pl -in c:\Projects\q\qsl\trunk -out c:\Projects\q\qsl\trunk\docs
2011/11/18 15:43:44 inPath         = c:\Projects\q\qsl\trunk
2011/11/18 15:43:44 outPath        = c:\Projects\q\qsl\trunk\docs
2011/11/18 15:43:44 handlePrivates = 0
2011/11/18 15:43:44 Found file: c:/Projects/q/qsl/trunk/sl.q
2011/11/18 15:43:44 1 q files found
2011/11/18 15:43:44 creating file from input: c:/Projects/q/qsl/trunk/sl.q
2011/11/18 15:43:44 saving to: c:/Projects/q/qsl/trunk/docs
2011/11/18 15:43:44 starting NaturalDocs
Finding files and detecting changes...
Parsing 4 files...
Building 1 file...
Building 4 indexes...
Done.
2011/11/18 15:43:45 NaturalDocs processing completed
```

#### Documentation with privates and authors

```
> perl devDoc.pl -in c:\Projects\q\qsl\trunk -out c:\Projects\q\qsl\trunk\docs -a 1 -p 1
```


