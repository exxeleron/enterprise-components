// Redistribution in source and binary forms prohibited.
//
/A/ DEVnet: Slawomir Kolodynski
/D/ 2013-02-25
/V/ 0.1
/S/ A non-qspec test for timer.q, supposed to be run from the qspec part

system"l sl.q";
system"l pe.q";
system"l timer.q";

.sl.init[`timer_aux1];
system"l event.q";
system"l handle.q";
.test.fcount:0;
.test.frunTime:`timestamp$ 0;
f:{show "f: ",string x;.test.frunTime:x;.test.fcount+:1};
done:1b;
