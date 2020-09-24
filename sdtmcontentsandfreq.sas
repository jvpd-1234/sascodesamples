libname sdtm "/folders/myfolders/pogram/sdtm";

proc contents data=sdtm._all_ out=sdtm NOPRINT ;
run;

data sdtm;
set sdtm;
keep memname name label lengtH TYPE;
run;

PROC SQL;
SELECT DISTINCT MEMNAME
FROM SDTM;
QUIT;
  

%macro DOMFREQ   (SIN);

data sdtm&sin;
set sdtm;
IF memname="&sin" AND TYPE=2;
IF INDEX(NAME,'DTC') >=1 THEN DELETE;

IF INDEX(NAME,'USUBJID') >=1 THEN DELETE;

IF INDEX(NAME,'STUDYID') >=1 THEN DELETE;

IF INDEX(NAME,'DOMAIN') >=1 THEN DELETE;

IF INDEX(NAME,'IDVARVAL') >=1 THEN DELETE;

IF INDEX(NAME,'LNK') >=1 THEN DELETE;

IF INDEX(NAME,'ORRES') >=1 THEN DELETE;
 
 
IF INDEX(NAME,'RESC') >=1 THEN DELETE;
 
RUN;



%MACRO FRET  (DIN,INP);

proc freq data=&DIN;
tables &INP /list  missing;
run;

%MEND;


%FRET (SDTM&sin  ,TYPE NAME);

PROC SQL NOPRINT;
  select count(*)
into :NObs
 from SDTM&sin;
 QUIT;
 
 %PUT &NOBS;
 
 proc sql NOPRINT;
 select Name
into : Name1-:Name%left(&NObs)
 from SDTM&SIN;
 quit;

%PUT _USER_ ;
TITLE "&SIN";

%MACRO FRESDTM (N);
%DO n = 1 %TO &N;
 

PROC FREQ DATA=SDTM.&sin;
TABLES &&NAME&N ;
RUN;
%END;

%MEND;

%FRESDTM (&NOBS)

TITLE " " ;
%mend;

%domfreq(TR);
OPTION SYMBOLGEN MLOGIC MPRINT;

%domfreq(SUPPTR);

%domfreq(TU);

%domfreq(SUPPTU);

%domfreq(RS);

%domfreq(SUPPRS);
 
