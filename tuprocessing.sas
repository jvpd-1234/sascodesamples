/*******************************************************************************
|
| Program Name:    qc_adtr1.sas
|
| Program Purpose: QC for efficacy dataset ADTR1
| 
********************************************************************************/
*
%include libname yu "/folders/myfolders/define3/c_setup.sas";
*
libname qcdata "/arenv/arwork/gsk2118436/brf117277/eos/qc/qc_adam/qc_adamdata" ;

libname sdtmdata "/folders/myfolders/pogram/sdtm";
libname adamdata "/folders/myfolders/define3";

Proc sort data = SDTMData.suppTU out = work.suppTU_in ;
  by USUBJID IDVAR IDVARVAL;
run;

proc sort data=work.suppTU_in out=tesw;
by qnam;

********* THE QVAL IS OF PRIMARY IMPORTANCE FOR PREVIOULSY IRRADIATED IN DERIVING 
CRIT3 and crit2 ;
*also for scintu Scan Interval for target lesion;
*
Only need these for the lcloc from SUPPTR.QNAM in ('TRLOCTX','LSLOC','TRLOC1','TRLOC2','TRLOC3','TRLOC4');
/*SUPPTU.QVAL where QNAM  equal to 'RADSTDT'-- RADIATION START DATE converted to numeric date
SUPPTU.QVAL where QNAM  equal to 'RADTYPCD'- RADIATION TYPE CODE
SUPPTU.QVAL where QNAM  equal to 'MELMALSP'-- Malignancy findings specify
/*

LSLOC   Lesion Location 1314    16.38   1314    16.38
MELMALSP    Malignancy findings specify 77  0.96    1391    17.34
PREVIR  Previously irradiated   526 6.56    1917    23.90
PREVIRP Progressing since previously irradiated 14  0.17    1931    24.08
RADSTDT Start date  12  0.15    1943    24.23
RADTYPCD    Type of radiotherapy code   12  0.15    1955    24.38
RDTYPE  Read Type   1314    16.38   3269    40.76
REVID   Reviewer ID 1314    16.38   4583    57.14
SCNINT  Scan Interval   1118    13.94   5701    71.08
SCNINTU Scan Interval Unit  1118    13.94   6819    85.02
TULOCTX Lesion location 1201    14.98   8020    100.00
*/


proc freq data=tesw;;*
by qnam;
tables qnam*qlabel  /list  missing;
where index (qnam,"PREV") >=0;
TITLE " QVAL IS NOT IMPORTANT AT ALL" ;
run;


proc freq data=tesw;;*
by qnam;
tables IDVAR*qnam*qlabel*qvaL  /list  missing;
where index (qnam,"PREV") >=1 ;
TITLE " QVAL IS IMPORTANT" ;
run;
/***
 IDVAR=TULNK ID IS ONLY IMPORTANT FOR RADIATION START DATE AND TYPE OF RADIOTHERAPY CODE;
TULNKID RADSTDT Start date  12  50.00   12  50.00
TULNKID RADTYPCD    Type of radiotherapy code   12  50.00   24  100.00
*/

proc freq data=tesw;;*
by qnam;
tables IDVAR*qnam*qlabel   /list  missing;
where index (IDVAR,"TULNKID") >=1 ;
TITLE "TULNKID 24 RECORDS ONLY FOR RADIATION RECRODS" ;
run;
title " " ;

/*
IDVAR    VALUES ARE
TULNKID 24  0.30    24  0.30
TUSEQ   7996    99.70   8020    100.00
**/

/*IDVAR= TULNKID IS ONLY FOR THE 24 RADIATION RECORDS*/


proc freq data=tesw;
tables idvar /list  missing;
run;

****** SDTM IS HORIZONTAL NEED TO TRANSPOSE IT UP;
 
proc transpose data = work.suppTU_in (where=(IDVAR = "TUSEQ")) 
/* note tuseeq/tulink is later*/
               out=work.suppTU_1a;
  by USUBJID IDVAR IDVARVAL;
  var QVAL;
  id QNAM;
  idlabel QLABEL;
run;

Data work.suppTU_1b (drop= IDVAR IDVARVAL _NAME_ _LABEL_);
  Set work.suppTU_1a;
  TUSEQ = input(IDVARVAL, best.);
Run;

Proc sort data = work.suppTU_1b;
  By USUBJID TUSEQ;
Run;

PROC FREQ ;
TABLES TUSEQ;
RUN;


***********TU PROCESSING STARTS NOW ;
/*
ADSL.NEXBL  Count of the distinct tumor sites (TU.TULOC) 
where TU.TUSCAT equal 'EXTRACRANIAL' at Screening visit

ADSL.NINNTRBL   Count of the distinct BRAIN NON target lesions 
where TU.TUSCAT equal 'BRAIN'
  and 
TUORRES equal "NON-TARGET" at Screening visit

ADSL.NINTRBL    Count of the distinct BRAIN target lesions 
where TU.TUSCAT equal 'BRAIN' 
 and  
 TUORRES equal "TARGET" at Screening visit

ADSL.NTEXDINV   Set to TU.TUEVAL where TU.TUSCAT equal "EXTRACRANIAL"
 and FAMH.FATESTCD equal "NTLSS" for INVESTIGATOR assessed.

ADSL.NTEXDIRC   Set to TU.TUEVAL 
where TU.TUSCAT equal "EXTRACRANIAL" 
and FAMH.FATESTCD equal "NTLSS" for INDEPENDENT REVIEW COMMITEE assessed.

*/

%MACRO FRET  (DIN,INP);

proc freq data=&DIN;
tables &INP /list  missing;
run;

%MEND;


%FRET (SDTMDATA.TU,TULOC*TUSCAT);
 

%FRET (SDTMDATA.FAMH,FATEST*FATESTCD);
 
Data work.TU_pre;
  Set SDTMData.TU;
** THERE ARE MISSING TUSCAT FOR BRAIN LOCATIONS HENCE SETTING IT TO BRAIN;
**EVERYTHIGN IS EXTRACRANIAL;
  If missing(TUSCAT) and not missing(TULOC) then do;
    If TULOC = "BRAIN" then TUSCAT = "BRAIN";
    Else TUSCAT = "EXTRACRANIAL";
  End;
Run;



proc freq ;
tables tuloc*tuscat*tucat*tueval*visitnum /list  missing;
run;


%FRET (SDTMDATA.TU,TUEVAL*TUCAT*TULOC*TUSCAT);
*** TUCAT ARE LESION MEASUREMENTS;

%FRET (SDTMDATA.TU,TUEVAL*TUSCAT);
%FRET (SDTMDATA.TU, VISITNUM);

data newtulnkid;
set sdtmdata.tu;
tulnki=scan (tulnkid,1,"_");
run;

%FRET (newtulnkid, tulnki);
%FRET (newtulnkid, TUORRES*TULNKI*tuseq);

/* 
TUeval ***tuscat
INDEPENDENT ASSESSOR  BRAIN   718 27.42   820 31.31
INDEPENDENT ASSESSOR  EXTRACRANIAL    596 22.76   1416    54.07
INVESTIGATOR      227 8.67    1643    62.73
INVESTIGATOR  BRAIN   390 14.89   2033    77.63
INVESTIGATOR  EXTRACRANIAL    586
*/ 

* subset exclude missing visitnum 
missing location 
missing tumor category; 

Proc sort data =  /** FROM TU ABOVE **/
work.TU_pre (keep=USUBJID TUEVAL TUSEQ TUCAT TUSCAT VISITNUM  TULNKID TULOC TUMETHOD
where=((TUCAT = "LESION ASSESSMENTS" 
and TUEVAL = "INVESTIGATOR" 
and TUSCAT in ("BRAIN", "EXTRACRANIAL")
and not missing(VISITNUM))

or
(TUCAT = "LESION ASSESSMENT" and 
TUEVAL = "INDEPENDENT ASSESSOR" 
and not missing(VISITNUM))
                          ))
out = work.TU_in;   By USUBJID TUSEQ;
Run;


%FRET (TU_PRE, TUEVAL*TUCAT*TUSCAT);

** keep only tu records and not supptu first merge with tuseq ; 
****tu_in is not missing visit and tuscat,brain,extracranial;
******supptu_1b-- is transposed where idvarval is tuseq-- merge with TU;
Data work.TU_1;
  Merge work.TU_in (in=inTU)  work.suppTU_1b;
  By USUBJID TUSEQ;
  If inTU;
Run;


** keep only tu records and not supptu 2nd  merge with tulinkid ; 
*****suppTU_in transpose where idvar=tulnkid
24 observations are for raditation;

proc transpose data = work.suppTU_in (where=(IDVAR = "TULNKID"))
               out=work.suppTU_2a;
  by USUBJID IDVAR IDVARVAL;
  var QVAL;
  id QNAM;
  idlabel QLABEL;
run;

******* tulinkid is the 12 radiation records only;

Data work.suppTU_2b (drop= IDVAR IDVARVAL _NAME_ _LABEL_);
  Set work.suppTU_2a;
  If IDVAR = "TULNKID" then TULNKID = IDVARVAL;
Run;

Proc sort data = work.suppTU_2b;
  By USUBJID TULNKID;
Run;

Proc sort data = work.TU_1;
  By USUBJID TULNKID;
Run;

*** merge tu1/seq records with tu2/tulinkid radiation records (12 in number);
*** set to intra/extracranial in  TRSCAt;


Data work.TU_2;
  Merge work.TU_1 (in=inTU)
        work.suppTU_2b;
  By USUBJID TULNKID;
  If inTU;
*** this setups to merge wit TR;
  TREVAL=TUEVAL;
  TRLNKID=TULNKID;
  If not missing(TUSCAT) then TRSCAT=TUSCAT;
  Else If TULOC = "BRAIN" then TRSCAT = "BRAIN";
  Else TRSCAT = "EXTRACRANIAL";

  TRMETHOD = TUMETHOD;

  If TREVAL= "INDEPENDENT ASSESSOR" and missing(TRSCAT) and not missing(TULOC) then do;
    If TULOC = "BRAIN" then TRSCAT = "BRAIN";
    Else TRSCAT = "EXTRACRANIAL";
  End;
Run;
