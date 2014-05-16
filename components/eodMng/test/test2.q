/use test2.sh instead

system "c 1000 1000";

rdb0:`:192.168.4.30:9020;
rdb2:`:192.168.4.31:9020;

eod0:`:192.168.4.30:9007;
eod2:`:192.168.4.31:9007;

copyHdbPar:{[h;dt]
	h "hdbPath:getenv[`EC_SYS_PATH],\"/data/kdb.hdb\"";
	h "firstPar:hdbPath,\"/\", string[first key hsym `$hdbPath]";
	h "lastPar:hdbPath,\"/",string[dt],"\"";
    h "system[\"rm -rf \",lastPar,\"/\"]"; 
    h "system[\"cp -r \",firstPar,\" \",lastPar]"; 
	};

prepareRdb:{[h]
    h "causeWsFull:{[] til each til 1000000i;  }";
    h "makeWSFULL : 0b";
    h "makeFAIL   : 0b";
    h "notifyEodBegin:{[date]  .store.notifyStoreBegin[date];}";
    h "notifyEodFail:{[date]   makeFAIL :: 1b; }";
    h "notifyEodSuccess:{[date] .store.notifyStoreSuccess[date];}";
    h "notifyEodRecovery:{[date]makeWSFULL :: 1b;}";
    h "notifyEodBefore:{[date] .store.notifyStoreBefore[date]; }";
    h "wsFullTest:{[t] if[makeWSFULL;  causeWsFull[];  ]; }";
    h "wsFailTest:{[t] if[makeFAIL; system \"yak stop kdb.rdb\"; ]; }";
    h ".tmr.start[`wsFullTest;200i;`wsFullTest]";
    h ".tmr.start[`wsFailTest;200i;`wsFailTest]";
    };


h0: hopen rdb0;
h2: hopen rdb2;



e0: hopen eod0;
e2: hopen eod2;

prepareRdb each (h0;h2);

begin   :{y "notifyEodBegin[" , (string x) , "]"};
fail    :{y "notifyEodFail[" , (string x) , "]"};
recovery:{y "notifyEodRecovery[" , (string x) , "]"};
before  :{y "notifyEodBefore[" , (string x) , "]"};
success :{
   y "notifyEodSuccess[" , (string x) , "]";
   y "notifyEodBefore[" , (string x+1) , "]";
   };
   
d: .z.d;

counter:0;

getPort:{[s]
    ps: ":" vs s;
	: "I"$last ps;
	}
	
fin:{
    show "Total time : ",string .z.t-startTime;
	system "t 0";
	s0:e0 "(.eodmng.state;.eodmng.lastSyncHost)";
	s2:e2 "(.eodmng.state;.eodmng.lastSyncHost)";
	lst:( s0;s2);
	aswr:createAnswer[tests[testCounter]];
	answer:`int$lst~aswr;
	answersVector[testCounter]::`int$answer;
	show $[answer;"PASSED";"FAILED"];
	
	if[not answer;
		show "   Expected : ";
		show aswr;
		show "   Given : ";
		show lst;
		];
		
	resets :: not (`idle~) each (s0[0];s2[0]);
	resets :: resets | (`noeod~) each tests[testCounter][0 1];
	
	
	date::date+1;
	
	if[testCounter<count tests;
	    testCounter::testCounter+1;
		runTest[testCounter];
		];
	if[testCounter>=count tests;
		system "t 0";
		r:min answersVector;
		rr:{[x] x~1i} each answersVector;
		show "--------------------------------------------------";
		show "Overall Result : PASSED ", (string sum rr) , "/", string count tests;
		@[e2;"exit 0";()];
		exit 0;
		];
	};
	
.z.ts:{
        /show "tick ",(string 1+counter),"/",string 1+count storyLine;
	counter::counter+1;
	@[storyLine[counter-1][counter-1];();()];
 	if[counter > count storyLine; fin[]];
	};

date:.z.d;


ins:{[list;x;n] 
	(n#list), x , n _list
	};
	
insertAll:{[list;elem]
	{[x;y;z] :ins[x;y;z]}[list;elem;] each til 1+count list
	};

permutations:{[list]
	if [0~count list; :enlist ()];
	head:first list;
	raze {insertAll[x;y]}[;head] each permutations[1_list]
	};

tests:raze `succ`rec`noeod`fail ,/:\: raze `succ`rec`noeod`fail ,/:\: permutations[10 12]

prepareCase:{[handle;segment;action;story]
		if[action~`succ;story[segment]:{[x;h;z] x[]; success[date;h]}[story[segment];handle;];];
		if[action~`fail;story[segment]:{[x;h;z] x[]; .[fail;(date;h);()]}[story[segment];handle;];];
		if[action~`rec ;story[segment]:{[x;h;z] x[]; .[recovery;(date;h);()]}[story[segment];handle;];];
		story
	}

prepareTest:{
		story:40#{};

		ranks:x[2 3];
		story[1]:{[x;y] begin[date;] each (h0;h2) where {[t] not t~`noeod} each x[0 1]}[x;];
		story:prepareCase[h0;ranks[0];x[0];story];
		story:prepareCase[h2;ranks[1];x[1];story];
		
		:story;
	}

prepareTests:{prepareTest each x};

createAnswer:{[states]
	highest:`none;
	if[states[1]~`succ;highest:`prod2.eodMng];
	if[states[0]~`succ;highest:`prod1.eodMng];
	sts:stateConvert each 2#states;
	ports:portSet[;highest] each 2#states;
	if[not highest~`none;
		ports[$[highest~`prod1.eodMng;0;1]]:`none;
		];
	:sts ,' ports
	};
	
stateConvert:{[s]
	if[s in `succ`noeod; :`idle];
	if[s in `fail`rec`loop; :`error];
	}

portSet:{[s;highest]
	if[s~`succ;:highest];
	if[s~`rec; :highest];
	if[s in `loop`fail`noeod; :`none];	
	};

startTest:{[]

	testCounter::0; 
	answersVector:(count tests)#enlist -1i;
	runTest[testCounter]
	};

resets:111b;
	
answersVector:(count tests)#enlist -1i;
	
	
runTest:{[n]    
    startTime::.z.t;
    show "-------------------------------------------------";
	if[resets[0];
		e0 "system \"yak stop kdb.rdb\"";
		e0 "system \"yak start kdb.rdb\"";
		system "sleep 1";
		h0:: hopen rdb0;
		prepareRdb[h0];
		
		];
	
	if[resets[1];
		e2 "system \"yak stop kdb.rdb\"";
		system "sleep 1";
		e2 "system \"yak start kdb.rdb\"";
		system "sleep 1";
		h2:: hopen rdb2;
		prepareRdb[h2];
		];

	before[date;] each (h0;h2);

	if[resets[0];
		e0 ".eodmng.p.restart[]";
		e0 ".eodmng.date:",string date;
		];
	
	if[resets[1];
		e2 ".eodmng.p.restart[]";
		e2 ".eodmng.date:",string date;
		];
		
    copyHdbPar[e0;date];
    copyHdbPar[e2;date];

	neg[e0] ".eodmng.lastSyncHost:`none";
	neg[e2] ".eodmng.lastSyncHost:`none";

	storyLine::prepareTest[tests[n]];

	counter::0;
	
	show " TEST ",(string n)," : [", (raze (" , ",) each string tests[n]),"] started";
	
	system "t 700";
	};
	
	startTest[];