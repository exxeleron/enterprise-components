# **qsl**

- sl - Standard library - common `frame` for all ec q scripts
  - loading configurations and libraries
  - managing library paths and dependencies
  - automatically load logging, events and protected evaluation libraries
  - framing for q scripts

- pe - Protected evaluation library - wrapper for invoking functions in protected evaluation
  - handling both anonymous and named functions
  - signal handler can be defined by user
  - can be turned on and off during runtime
  - extended log messaging (e.g. function name, args etc.)

- event - Event library - execution of q functions as events
  - function is executed using protected evaluation
  - detailed information about event state is logged using .log.xxx interface - levels can be defined via event API; 
    information is logged using dictionary format (key=value pairs)
  - information about event state is transferred to the monitor server using event files
  - detailed information about event is persisted in event files (the same information as event log message)
  - function execution time is measured

- callback - Callback library - managing callbacks
  - allows adding multiple callbacks under one interface name (e.g. .z.pg, .z.ps, .z.exit, etc.) 
  - counts number of executions of each callback
  - allows flag 'execute as last one'

- timer - Timer library - abstraction layer for timer
  - allows execution of multiple different timers
  - runs a function every number of timer ticks provided per parameter
  - runs the specified function around specified time (10s accuracy)

- handle - Connection management library - abstraction layer for interprocess connections
  - initialization and maintaining connections between q processes
  - using logical components names (host/port/password read from config files)
  - two modes of connection initialization - `lazy and `eager
  - keeping state of each connection (`registered, `open, `close, `lost, `failed)
  - user defined callbacks on port-open and port-close 
  - autoreconnection functionality

- authorization - Authorization library - access restrictions and auditing
  - providing authorization by validating incoming function calls against allowed namespaces and forbidden keywords (stop words); 
  - authorization configuration is described in access.cfg schema file
  - logging access and function calls facilities (audit view) 
  - logging of incoming synchronous and asynchronous function calls and user login/logout; 
  - audit view configuration is described in access.cfg schema file (see <access.qsd>)

- u - u.q library - extension of [u.q from Kx](http://code.kx.com/wsvn/code/kx/kdb%2Btick/tick/u.q)
  - provides API for subscription to data publishing in tickHF protocol
  - maintains subscription lists
  - end-of-day callback to all subribers

- sub - Subscription management library - abstraction for realtime data subscription
  - allows subscription to one of the for subscription to data published in tickHF, tickLF or protocols
  - subscribe and replay the data
  - keep subscription status

- store - Store library - data storage in the hdb
  - data storage as splayed and partition table
  - callback for reloading and filling missing tables in hdb
  - end of day support and integration with eodMng component

- os - Os library - shell commands abstraction, covers Linux, MacOS and Windows
  - directory operations - .os.mkdir, .os.cpdir, .os.rmdir
  - files operations - .os.rm, .os.move
  - find files by age and pattern - .os.find
  - compress file or directory - .os.compress
  - sleep for given number of milliseconds - .os.sleep

- parseq - Parseq library - Parseq is a Q clone of the Haskell's Parsec, a parser combinator library. 
  - Most parser names are the same as in the original, except when colliding with q keywords.
