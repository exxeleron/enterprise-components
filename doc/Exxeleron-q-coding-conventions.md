## Overview

This documents presents set of rules and guidelines when working with q+/kdb code.

Every developer is obliged to read and conform to the rules stated in the document.

Any violation to the guide is allowed only if it enhances readability.

## File names
- File name should reflect functionality of the code or module, for example, for handling `hdb`
  functionality, the file should be named `hdb.q`
- In case of longer names the camel casing should be used, (e.g. for `Access Point` -> `accessPoint.q`)

## Structure of the file
- Each file should have some or most of the following sections:
    - License
    - Script summary
    - Script start up command (if applicable)
    - Author(s)
    - Release date
    - Script version
    - List of global variables
    - Global functions
    - Interface functions
    - Private functions
- All of the above sections reflect available tags which must be used for commenting your code and
  creating documentation
    - Please refer to
      [Documenting q code](Documenting-q-code)
      for detailed explanation and examples on code generation
    - For more details about comments, please see section ‘Comments’ below
- Lines should not be longer than 100 columns. 
- Indentation is always 2 (two) spaces. Tab characters are not allowed. 

## Namespaces

- Namespace used in the module should reflect name of the file, for example in module `hdb.q` the
  namespace should also be `hdb`:

```q
/F/ realod hdb directory
.hdb.reload:{[]
  .event.at[`hdb;`.hdb.p.reload;();`;`info`info`fatal;"hdb reloading, hdb dir:", system"cd"];
  };
```

- In case of longer file names (such as `cfgServer.q`) please shorten the namespace to reflect the
  first letters from each part of the file name (`cs`):

```q
/F/ List all configuration tables for the component instance
/P/ instance - Q server instance name
/E/.cs.getCfgNames`feedCsvT
.cs.getCfgNames:{[instance]
  exec name from .cs.status where instance=instId
  };
```

- Whenever possible the namespaces should be limited to maximum of three levels:

```q
/F/ Parses a symbol. Symbol can be any string that does not contain ")", 
/F/ spaces are stripped from both sides
/P/ ps - item to be parsed as symbol
/R/ :SYMBOL - the parsed symbol
.cr.atomic.symbol:{[ps]
  res:.cr.atomic.string ps;
  if[null res[`errp];
    s:res[`ast];
    res[`ast]:`$s]
    ;
  :res;
  };
```

## Functions

- Function body should be always indented
- Function definition should always end with semicolon `;`

## Private variables and private functions

Although q+/kdb doesn’t have a notion of ‘private’ variables or functions, we’ve introduced
private-like notation. In general, all ‘private’ functionality should be using `p` namespace:

```q
/F/ initialization and reload
.hdb.p.init:{[]
  system "cd ",1_string .hdb.cfg.hdbPath;
  .hdb.reload[];
  };
```

These private functions (or variables) are accessible from q level as any other (i.e. - they keep
their ‘global’ scope), however, during code generation they are simply omitted to present end user
with only necessary set of interfacing functionality.

> **Note**
> 
> Although private functions/variables are not parsed during document generation, they should be
> documented in the code.

## Long statements

It is recommended to split long lines of code. It is good if line breaks reflect 
the logical meaning of the code, e.g.:

```q
final:delete parsed from select lineType, varName:parsed[;1;0], varVal:parsed[;1;1], line, col+parsed[;0], file, errors from parsed where lineType<>`empty;
```

to:

```q
final:delete parsed from 
  select lineType, varName:parsed[;1;0], varVal:parsed[;1;1], 
  line, col+parsed[;0], file, errors from parsed where lineType<>`empty;
```

## White spaces
- Tabs are not allowed and should be replaced with spaces
- Tab size should be set to two spaces

## Comments
- In general, the use of comments should be minimized by making the code self-documenting by
  appropriate name choices and an explicit logical structure.
- All comments should be written in English.
- Use `//` for all non-DevDoc comments, including multi-line comments. Using `//` comments ensure that
  it is always possible to comment out entire sections of a file using `/  ...  \` for debugging
  purposes etc.

## Miscellaneous
- The use of magic numbers in the code should be avoided. 
- Try to limit length of each function. As a rule of thumb - if function’s body doesn’t fit in
  visible portion of your IDE, perhaps it should be divided into smaller functions