
%MACRO FRET  (DIN,INP,wh,tin);

proc freq data=&DIN;
tables &INP /list nocol nocum nopercent norow  missing;
&wh ;
&tin ;
run;
title"";
%MEND;
