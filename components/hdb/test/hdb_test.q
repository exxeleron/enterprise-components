// q test/hdb_test.q --noquit -p 5001

\l lib/qsl/sl.q
.sl.init[`hdb_test];
\l lib/qspec/qspec.q

.tst.desc["test statistics - .hdb.dataVolumeHourly"]{
  before{
    .sl.noinit:1b;
    @[system;"l hdb.q";0N];
    `tabTime mock ([] date:.z.d;time:asc 20?.z.t;col1:1 );
    `tabDaily mock ([] date:.z.d;col1:20#1 );
    };
  should["return hourly statistics"]{
    24 mustmatch count .hdb.dataVolumeHourly[`tabTime;.z.d];
    
    };
  should["return daily statistics"]{
    1 mustmatch count .hdb.dataVolumeHourly[`tabDaily;.z.d];
    };
  should["return the same model for hourly and daily statistics"]{
    meta[.hdb.dataVolumeHourly[`tabTime;.z.d]] mustmatch meta[ .hdb.dataVolumeHourly[`tabDaily;.z.d]];
    };
  };
