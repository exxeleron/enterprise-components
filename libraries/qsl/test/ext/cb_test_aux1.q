system "l sl.q";
system "l pe.q";

.sl.init[`cb_test_aux1];
system "l callback.q";
f:{2};
g:{1+value x};

.cb.add[`.z.pg;`g];
.cb.add[`.z.pg;`f];
.cb.setLast[`.z.pg;`g];
done:1b;

