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

********** end TU processing tu_2 tu_2 is merged with Tr records proceesed below 
search for TR + TU  ;

*****merge data from SUPPTR onto TR records ;
** exclude missing visitnum again; 

** process Supptr;

Proc sort data = SDTMData.suppTR out = work.suppTR_in ;
  by USUBJID IDVAR IDVARVAL;
run;

proc transpose data = work.suppTR_in (where=(IDVAR = "TRSEQ"))
               out=work.suppTR_1a;
  by USUBJID IDVAR IDVARVAL;
  var QVAL;
  id QNAM;
  idlabel QLABEL;
run;

Data work.suppTR_1b (drop= IDVAR IDVARVAL _NAME_ _LABEL_);
  Set work.suppTR_1a;
  TRSEQ = input(IDVARVAL, best.);
  rename LSLOC = LSLOC_TR; ****so not to confuse with lsloc of tu; 
Run;

Proc sort data = work.suppTR_1b;
  By USUBJID TRSEQ;
Run;



********* end process supptr;


Proc sort data=SDTMData.TR (where=(not missing(VISITNUM)))
          out = work.TR_in_1;
  By USUBJID TRSEQ;
Run;


******* merge supptr with Tr; 

Data work.TR_in_2;
  Merge work.TR_in_1 (in=inTR)
        work.suppTR_1b
        ;
  By USUBJID TRSEQ;
  If inTR;

  If TRTESTCD = "TUMSTATE" then LSLOC_TR2 = LSLOC_TR;

Run;

Proc sort data = work.TR_in_2
  (keep=USUBJID TRSEQ TREVAL TRLNKID TRLNKGRP TRGRPID TRTESTCD TRTEST TRSCAT
        TRSTRESC TRSTRESN TRREASND TRMETHOD VISITNUM VISIT TRDTC TRBLFL TRLOC TRSTAT
        TRLOCTX LSLOC_TR LSLOC_TR2 REVID TRLOC3 TRLOC4 RDTYPE TRLOC1 TRLOC2
  where=(TRTESTCD in ("LDIAM", "TUMSTATE")
         and TREVAL in ("INVESTIGATOR" ,"INDEPENDENT ASSESSOR")
         and not missing(TRLNKID)
         and not missing(VISITNUM)))
          out = work.TR_in ;
  By USUBJID TREVAL TRLNKID TRLNKGRP TRGRPID TRSCAT TRMETHOD VISITNUM VISIT TRDTC TRBLFL TRLOC;
Run;

Proc sort data = work.TR_in_2;
  By USUBJID TREVAL TRLNKID TRLNKGRP TRGRPID TRSCAT TRMETHOD VISITNUM VISIT TRDTC TRBLFL TRLOC;
Run;



Data work.TR_1;
  Merge work.TR_in (where=((TRGRPID = "TARGET" and TRTESTCD = "LDIAM")
                            or
                           (TRGRPID in ("NEW","NON-TARGET") and TRTESTCD="TUMSTATE")))
        work.TR_in_2 (where=(TRGRPID = "TARGET" and TRTESTCD2 = "TUMSTATE"
                                              and (not missing(LSTATUS) or not missing(TRREASND_2)) )
                    keep=USUBJID TREVAL TRLNKID TRLNKGRP TRGRPID TRSCAT
                         TRSTRESC TRREASND TRMETHOD VISITNUM VISIT TRDTC TRBLFL TRLOC TRSTAT TRTESTCD LSLOC_TR2
                    rename=(TRSTRESC = LSTATUS  TRREASND=TRREASND_2  TRSTAT=TRSTAT_2  TRTESTCD=TRTESTCD2)) ;
  By USUBJID TREVAL TRLNKID TRLNKGRP TRGRPID TRSCAT TRMETHOD VISITNUM VISIT TRDTC TRBLFL TRLOC;

  If TRGRPID= "NEW" and missing(TRSCAT) and not missing(TRLOC) then do;
    If TRLOC = "BRAIN" then TRSCAT = "BRAIN";
    Else TRSCAT = "EXTRACRANIAL";
  End;

  If TRSTAT_2 = "NOT DONE" and missing(TRTESTCD) then do;
    TRTESTCD = "LDIAM";
    TRTEST = "Longest Diameter";
  End;

Run;

*12586 observations read from the data set WORK.TR_IN.;
* There were 6996 observations read from the data set WORK.TR_IN_2.;
*but there are 12788 observations and 34 variables. see why there are 200 extra records;

* Checking for duplicates in TR (from the merge above);
proc sort data= work.TR_in (where=((TRGRPID = "TARGET" and TRTESTCD = "LDIAM")
                            or
                           (TRGRPID in ("NEW","NON-TARGET") and TRTESTCD="TUMSTATE")))
          out=LDIAM
          dupout = dupes_LDIAM
          nodupkey ;
  By USUBJID TREVAL TRGRPID TRSCAT TRLNKID TRLNKGRP VISITNUM TRMETHOD TRDTC  ;
run;


proc sort data= work.TR_in (where=(TRGRPID = "TARGET" and TRTESTCD2 = "TUMSTATE"
                                              and not missing(STATUS) )
                    keep= USUBJID TREVAL TRGRPID TRSCAT TRLNKID TRLNKGRP VISITNUM TRMETHOD
                          TRDTC TRTESTCD TRSTRESC
                    rename=(TRSTRESC = STATUS  TRTESTCD=TRTESTCD2))
          out=TUMSTATE
          dupout = dupes_TUMSTATE
          nodupkey ;
  By USUBJID TREVAL TRGRPID TRSCAT TRLNKID TRLNKGRP VISITNUM TRMETHOD TRDTC  ;
run;
* End TR duplicate check;

Proc sort data = work.TR_1;
  By USUBJID TRSEQ;
Run;

Proc sort data = work.TR_1;
  By USUBJID TREVAL TRSCAT TRMETHOD VISITNUM TRLNKID TRLOC;
Run;

Proc sort data = work.TU_2 ;
  By USUBJID TREVAL TRSCAT TRMETHOD VISITNUM TRLNKID TULOC;
Run;

* TR + TU Individual Tumor records MERGE TR + TU-- then process TR records for the next 500 lines 
and merge with RS later on ;
Data work.TRTU_1;
  Merge work.TR_1 (in=inTR)
        work.TU_2;
  By USUBJID TREVAL TRSCAT TRMETHOD VISITNUM TRLNKID;
  If inTR;
Run;

Data work.TRTU_2;
  Merge work.TRTU_1 (in=inTR)
        ADaMData.ADSL (keep= USUBJID RANDDT TRTSDT);
  By USUBJID;
  If inTR;
Run;


%MACRO FRET  (DIN,INP,wh,tin);

proc freq data=&DIN;
tables &INP /list nocol nocum nopercent norow  missing;
&wh ;
&tin ;
run;
title"";
%MEND;

%fret(trtu_2,trgrpid*trtestcd*SCNINT*SCNINTu ,where TRGRPID in ("NEW","NON-TARGET") and TRTESTCD = "TUMSTATE")


/*** PARAMCD SUMLD1 table work.SUMLD_1c "Sum of Lesion Diameters (mm) Base = Baseline" as PARAM
  Where PARCAT1 = "TARGET" and PARCAT2 = "LESIONS" at baseline
***/

/*** PARAMCD = "SUMLD2" ;
  work.SUMLD_2c    , "Sum of Lesion Diameters (mm) Base = Nadir" as PARAM 
   , sum(AVAL) as AVAL
  From work.TR_IND_1
  Where PARCAT1 = "TARGET" and PARCAT2 = "LESIONS"
*/ 

/*  SUMLD3  , "Sum of Lesion Diameters (mm) Base = Baseline without Lymph Nodes" as PARAM
    , max(ADT) as ADT format=date9.
    , sum(AVAL) as AVAL
  From work.TR_IND_1
  Where PARCAT1 = "TARGET" and PARCAT2 = "LESIONS" and index(ORGAN,"LYMPH NODE") = 0 */

/** TO CHECK FOR MISSING DATES AND NO LESIONS;*/


/*TO COUNT THE NUMBER OF   
* Get a count of non-lymph node target lesion records at Screening basline 
*  * Get a count of non-lymph node target lesion records at each visit ;*/

/*
** used in work.Crit5_EI_1a to create crit5;

** to create work.New_Les_1 with unquivocal;
** to create overall response work.New_Les_1 with unquivocal;
*/


/** USED TO CREATE DATES FOR TARGET/NONTARGET AND NEW LESIONS ALSO LATER ;*/

/*SUBSET work.TRTU_2 Where (TRGRPID = "TARGET" and TRTESTCD = "LDIAM")
     or (TRGRPID in ("NEW","NON-TARGET") and TRTESTCD = "TUMSTATE")
 */
 
Proc SQL;
  Create table work.TR_IND_1 as
  Select USUBJID
      , TRGRPID as PARCAT1
       , "LESIONS" as PARCAT2
       , TREVAL as AEVAL
       , case TRSCAT when "BRAIN" then "INTRACRANIAL"
                     when "EXTRACRANIAL" then "EXTRACRANIAL"
                     else "" end as AREGION
       , case TRGRPID when "TARGET" then catx (" ",TRLNKID,"(mm)")
                      else TRLNKID end as PARAM
                      
/* ASSIGN MM TO TARGET PARAM,BUT NOT TO PARAMCD
%fret(trtu_2,TRLNKID*trgrpid*trtestcd ,where TRGRPID in ("TARGET")  )
options mprint mlogic symbolgen;
%fret(tr_ind_1, param*paramcd*ORGAN*LOCATION*LSTHICK*SCNINTU , where usubjid  not in (" ")  );
*/
                      
       , TRLNKID as PARAMCD length=12
       , input(TRDTC, yymmdd10.) as ADT format=date9.
       , VISIT as AVISIT
       , VISITNUM as AVISITN
       , case TRTESTCD when "LDIAM" then TRSTRESN
                       else . end as AVAL
       , case TRTESTCD when "LDIAM" then strip(put(TRSTRESN,best.))
                       when "TUMSTATE" then TRSTRESC
                       else "" end as AVALC
 /*%fret(trtu_2, TRGRPID*trtestcd*TRSTRESN ,where TRTESTCD in ("LDIAM")  );
 
 %fret(trtu_2, TRGRPID*trtestcd*TRSTRESC ,where TRTESTCD in ("TUMSTATE")  );
options mprint mlogic symbolgen;
%fret(trtu_2, PREVIRP*PREVIR , where usubjid  not in (" ")  );
   */                   
                       
       , case PREVIR when "YES" then "Y"
                     when "NO"  then "N"
                     else "" end as CRIT2FL
       , case PREVIR when "YES" then "Previously Irradiated"
                     when "NO"  then "Previously Irradiated"
                     else "" end as CRIT2
       , case PREVIRP when "YES" then "Y"
                      when "NO"  then "N"
                      else "" end as CRIT3FL
       , case PREVIRP when "YES" then "Previously Irradiated Showing PD"
                      when "NO"  then "Previously Irradiated Showing PD"
              else "" end as CRIT3
       , LSTATUS
       , TRMETHOD as METHOD
       , coalescec(TRLOC, TULOC) as ORGAN
       , coalescec(TULOCTX, LSLOC, LSLOC_TR, LSLOC_TR2) as LOCATION
       , case TRGRPID when "TARGET" then strip(SCNINT)
                      when "NEW"    then strip(SCNINT)
                      else "" end as LSTHICK
       , case TRGRPID when "TARGET" then SCNINTU
                      when "NEW"    then SCNINTU
                      else "" end as SCNINTU
       , input(RADSTDT, yymmdd10.) as RADSTDT format=date9.
       , RADTYPCD
       , MELMALSP
       , RDTYPE
       , case TRGRPID when "TARGET"     then compbl(coalescec(TRREASND, TRREASND_2))
                      when "NON-TARGET" then compbl(coalescec(TRREASND, TRREASND_2))
                      when "NEW"        then compbl(coalescec(TRREASND, TRREASND_2))
                      else "" end as REASND
       , RANDDT
       , TRTSDT
       , TRLNKGRP
  From work.TRTU_2
  Where (TRGRPID = "TARGET" and TRTESTCD = "LDIAM")
     or (TRGRPID in ("NEW","NON-TARGET") and TRTESTCD = "TUMSTATE")
  ;
Quit;


DATA ADAMDATA.TRIND1;
SET work.TR_IND_1;
RUN;

************************************************************************************************************************************************************************************;


*********  SUMLD_1c-->SUMLD_1e-->sumld_1f;
****** from this basline flags are created in BaseFlag_SUMLD1 Baseval_SUMLD1  which goes into goes into -->SUMLD_1e-->sumld_1f;;
***Baseval_SUMLD1 merge into into result of merge between Merge work.SUMLD_1c work.BaseFlag_SUMLD1 ;

*** Sum of Lesion Diameters ***;
* PARAMCD = "SUMLD1" ;
Proc SQL;
  Create table work.SUMLD_1c as
  Select distinct
      USUBJID
    , TRTSDT
    , PARCAT1
    , "DERIVED" as PARCAT2
    , AEVAL
    , AREGION
    , "SUMLD1" as PARAMCD
    , "Sum of Lesion Diameters (mm) Base = Baseline" as PARAM
    , max(ADT) as ADT format=date9.
    , calculated ADT - TRTSDT + (calculated ADT >= TRTSDT) as ADY
    , AVISIT
    , AVISITN
    , sum(AVAL) as AVAL /*SUM OF ALD*/
  From work.TR_IND_1
  Where PARCAT1 = "TARGET" and PARCAT2 = "LESIONS"
  Group by USUBJID, AEVAL, AREGION, AVISITN
  ;
Quit;

proc sort data=adamdata.trind1;

by USUBJId AEVAL AREGION AVISITN ;
PROC PRINT data=adamdata.trind1 ;
by USUBJId AEVAL AREGION AVISITN ;
WHERE usubjid = "BRF117277.000031" and PARCAT1 = "TARGET" and PARCAT2 = "LESIONS";
RUN;


PROC PRINT data=work.SUMLD_1c;
by USUBJID AEVAL AREGION  ;
WHERE usubjid = "BRF117277.000031" ;
title "65 in original shape" ;
RUN;


PROC PRINT data=work.SUMLD_1c;
by USUBJID AEVAL AREGION  ;
WHERE usubjid = "BRF117277.000065" ;
title "65 in original shape" ;
RUN;
************************************************************************************************************************************************************************************;

Proc SQL;
  /* SUMLD1 Baseline Flag */
  Create table work.BaseFlag_SUMLD1 as
    Select distinct USUBJID, AEVAL, AREGION, AVISITN, "SUMLD1" as PARAMCD, "Y" as ABLFL
    From work.SUMLD_1c
    Where AVISITN < 20
    Group by USUBJID, AEVAL, AREGION, AVISITN
    Having ADT = max(ADT)
  ;

  /* SUMLD1 Baseline Value */
  Create table work.BaseVal_SUMLD1 as
    Select distinct USUBJID, AEVAL, AREGION, "SUMLD1" as PARAMCD, AVAL as BASE
    From work.SUMLD_1c
    Where AVISITN < 20
    Group by USUBJID, AEVAL, AREGION
    Having ADT = max(ADT)
  ;
Quit;


PROC PRINT data=BaseVal_SUMLD1;
by USUBJID AEVAL AREGION  ;
WHERE usubjid = "BRF117277.000031" ;
RUN;

proc sort data= work.SUMLD_1c;
  By USUBJID AEVAL AREGION AVISITN PARAMCD ;
Run;


********* goes into -->SUMLD_1e-->sumld_1f;

Data work.SUMLD_1d;
  Merge work.SUMLD_1c
        work.BaseFlag_SUMLD1
        ;
  By USUBJID AEVAL AREGION AVISITN PARAMCD ;
Run;

********* goes into -->sumld_1f ;

Data work.SUMLD_1e;
  Merge work.SUMLD_1d
        work.BaseVal_SUMLD1
        ;
  By USUBJID AEVAL AREGION PARAMCD ;

  BASETYPE = "Last non-missing SLD prior to treatment";
  If nmiss(AVAL,BASE) = 0 and  AVISITN > 10 then CHG = AVAL - BASE;
  If not missing(CHG) then PCHG = CHG/BASE*100;
Run;


* PARAMCD = "SUMLD2" ;
Proc SQL;
  Create table work.SUMLD_2c as
  /* Create table work.SUMLD_2c as nadir as */
  Select distinct
      USUBJID
    , TRTSDT
    , PARCAT1
    , "DERIVED" as PARCAT2
    , AEVAL
    , AREGION
    , "SUMLD2" as PARAMCD
    , "Sum of Lesion Diameters (mm) Base = Nadir" as PARAM
    /* values are same but basetype=nadir smallest no missing prior*/
    , max(ADT) as ADT format=date9.
    , calculated ADT - TRTSDT + (calculated ADT >= TRTSDT) as ADY
    , AVISIT
    , AVISITN
    , sum(AVAL) as AVAL

  From work.TR_IND_1
  Where PARCAT1 = "TARGET" and PARCAT2 = "LESIONS"
  Group by USUBJID, AEVAL, AREGION, AVISITN
  ;
Quit;

PROC PRINT data=adamdata.trind1 ;
by USUBJId AEVAL AREGION   ;
WHERE usubjid = "BRF117277.000031" and PARCAT1 = "TARGET" and PARCAT2 = "LESIONS";
RUN;


PROC PRINT data=work.SUMLD_2c;
by USUBJID AEVAL AREGION  ;
WHERE usubjid = "BRF117277.000031" ;
title "NAdir" ;
RUN;


PROC PRINT data=work.SUMLD_1c;
by USUBJID AEVAL AREGION  ;
WHERE usubjid = "BRF117277.000031" ;
title "Sum of Lesion Diameters (mm) Base = Baseline" ;
RUN;

Proc SQL;
  /* SUMLD2 Baseline Flag Sum of Lesion Diameters (mm) Base = Nadir */
  Create table work.BaseFlag_SUMLD2 as
    Select distinct USUBJID, AEVAL, AREGION, AVISITN, "SUMLD2" as PARAMCD, "Y" as ABLFL
    From work.SUMLD_2c
    Where AVISITN < 20
    Group by USUBJID, AEVAL, AREGION, AVISITN
    Having ADT = max(ADT)
  ;

  /* SUMLD2 Baseline Value Sum of Lesion Diameters (mm) Base = Nadir*/
  Create table work.BaseVal_SUMLD2 as
    Select distinct USUBJID, AEVAL, AREGION, "SUMLD2" as PARAMCD, AVAL as BASE
    From work.SUMLD_2c
    Where AVISITN < 20
    Group by USUBJID, AEVAL, AREGION
    Having ADT = max(ADT)
  ;
Quit;

* adjust for SUMLD2 values that include records with missing values ;
Proc SQL;
  * Get a count of target lesion records at Screening ;
  Create table work.TRG_Recs_Base as
  Select distinct USUBJID, AEVAL, AREGION, count(PARAMCD) as Trg_Recs_Base
  From work.TR_IND_1
  Where PARCAT1 = "TARGET" and PARCAT2 = "LESIONS" and not missing(AVAL) and AVISITN = 10
  Group by USUBJID, AEVAL, AREGION
  ;

  * Get a count of target lesion records at each visit ;
  Create table work.TRG_Recs as
  Select distinct USUBJID, AEVAL, AREGION, AVISITN, count(PARAMCD) as Trg_Recs
  From work.TR_IND_1
  Where PARCAT1 = "TARGET" and PARCAT2 = "LESIONS" and not missing(AVAL) and AVISITN ^= 10
  Group by USUBJID, AEVAL, AREGION, AVISITN
  ; 
Quit;


Data work.TRG_Recs_2;
  Merge work.TRG_Recs
        work.TRG_Recs_Base
        ;
  By USUBJID AEVAL AREGION;
Run;

proc sort data= work.SUMLD_2c;
  By USUBJID AEVAL AREGION AVISITN ;
Run;

**merge target lesion counts with target lesion sum of diameters;

Data work.SUMLD_2d;
  Merge work.SUMLD_2c
        work.TRG_RECS_2
        ;
  By USUBJID AEVAL AREGION AVISITN;
Run;

proc sort data= work.SUMLD_2d;
  By USUBJID AEVAL AREGION AVISITN PARAMCD ;
Run;


proc print data=sumld_2d;
where Trg_Recs_Base ne Trg_Recs;
title "Trg_Recs_Base ne Trg_Recs";
run;




/*
data one;
   prod='shoes';
   invty=7498;
   sales=23759;
   call missing(of _all_);
   put prod= invty= sales=;
run;
The preceding statements produce this result:
prod= invty=. sales=.

*/
/*
If PARAMCD equal to SUMLD2 then AVAL equal to 
TR.TRSTRESN where TR.TRTESTCD  equal to SUMDIAM.
 Else If there is a record where TR.TRTESTCD equal 
 to SUMNMLD then AVAL equal to TR.TRSTRESN. 
 (If SUMLD2 with missing incorporated greater 
 than 1.2*BASE where PARAMCD equal to SUMLD2 then include. 
 Otherwise, leave blank. 
 Determine missing target lesion measurements by 
 subtracting the count of target lesions where AVAL is missing at a given
 visit for a subject from the count of target 
 lesions at screening for the same subject.


At least a 20% increase in the sum of the diameters of 
intracranial and extracranial target lesions, taking as a reference, 
the smallest sum of intracranial and extracranial diameters
 recorded since the treatment started (e.g., percent change from nadir, where nadir is defined as the smallest 
sum of diameters recorded since treatment start). 
In addition, the sum must have an absolute increase from nadir of 5mm.

*/
/*

SUMLD1  Sum of Lesion Diameters (mm) Base = Baseline
SUMLD2  Sum of Lesion Diameters (mm) Base = Nadir
SUMLD3  Sum of Lesion Diameters (mm) Base = Baseline without Lymph Nodes
*/

proc contents data= Baseflag_sumld2;
proc contents data=SUMLD_2d;
run;
******** check all baseline and then basetype Smallest non-missing SLD prior to current visit;

Data work.SUMLD_2e ; *(drop= TRG_RECS Trg_Recs_Base);
  Merge work.SUMLD_2d
        work.BaseFlag_SUMLD2
        ;
  By USUBJID AEVAL AREGION AVISITN PARAMCD ;
  /* SUMLD2 Baseline Value 
  Sum of Lesion Diameters (mm) Base = Nadir*/
  retain BASE prevBASE prevAVAL;
** set to missing;
  If first.AREGION then call missing(BASE, prevBASE, prevAVAL);
*if  usubjid="BRF117277.000065" and  aEVAL = "INVESTIGATOR"  and AREGION="EXTRACRANIAL" 
then put  USUBJID= AVISITN= PARAMCD= adt= base= prevbase= prevaval=; 
  ** baseline flag if blfl ;
  If ABLFL = "Y" then BASE  = AVAL;  
  **check if aval is less than 1.2 min of prevbase and prevaal if so assign missing;
ti=1.2* min(prevBASE,prevAVAL) ;
  If TRG_RECS ne Trg_Recs_Base and ^missing(AVAL) then do; *, prevBASE)=0 then do;
    If AVAL <= 1.2* min(prevBASE,prevAVAL) then call missing(AVAL);
  End;
  
*if  usubjid="BRF117277.000065" and TRG_RECS ne Trg_Recs_Base and ^missing(AVAL) then  
put "**" aregion=""  TRG_RECS "ne" Trg_Recs_Base adt= base= aval=  ti= prevbase= prevaval=;
 *
 put "**" aregion=""  TRG_RECS "ne" Trg_Recs_Base adt= base= aval=  ti= prevbase= prevaval=;
 
  If nmiss(prevBASE, prevAVAL)<2 then BASE = min(prevBASE, prevAVAL);

  BASETYPE = "Smallest non-missing SLD prior to current visit";
  If nmiss(AVAL,BASE) = 0 and  AVISITN > 10 then CHG = AVAL - BASE;
  If not missing(CHG) and BASE not in (0,.) then PCHG = CHG/BASE*100;

  If not missing(AVAL) then prevBASE = BASE;
  If not missing(AVAL) then prevAVAL = AVAL;
Run;

 
proc print data=sumld_2e;
WHERE usubjid = "BRF117277.000031"  ;* and PARCAT1 = "TARGET" and PARCAT2 = "LESIONS";
run;
data cttrind12;
 set adamdata.trind1 (WHERE=( PARCAT1 = "TARGET" and PARCAT2 = "LESIONS" ) ) ;
; *** individual lesion counts to see where sums of lesions dont match Trg_Recs ne Trg_Rec_base;

CUM=1 ;
RUN;

proc sort  ;
by  usubjid AEVAL AREGION  PARAMCD AVISITN     ;


proc print;
var usubjid AEVAL AREGION AVISITN PARAMCD ;
 where usubjid in ("BRF117277.000221") and aeval="INDEPENDENT ASSESSOR" and  aregion="INTRACRANIAL" ;
run;

/*if First.Vendor then VendorBookings=0;
   VendorBookings + NumberOfBookings;
   
    retain cumulative_profit;
 
 cumulative_profit = sum(profit,cumulative_profit);
 
 
  if first.month then cumulative_actual = actual;
 else cumulative_actual = cumulative_actual + actual;
 */

DATA  cttrind1;
SET  cttrind12;
by  usubjid AEVAL AREGION  PARAMCD AVISITN ;
 RETAIN CUM3 AVALT; 
  
  IF FIRST.parAMCD THEN CUM3=CUM ;
  ELSE CUM3= CUM3 + CUM ;* cum3  + CUM2  ;

  
  IF FIRST.parAMCD THEN avalt=aval ;
  ELSE avalt= avalt + aval;* cum3  + CUM2  ;
 
 retain counter;
 
 if first.parAMCD then counter = 1;
 else counter = counter + 1;
 
* if usubjid in ("BRF117277.000221") and aeval="INDEPENDENT ASSESSOR" and  aregion="INTRACRANIAL" then put    
PARAMCD=  AVISITN= cum3= cum=  
FIRST.PARAMCD= LAST.PARAMCD=   avalt= aval=  COUNTER= ;

if usubjid in ("BRF117277.000221") and aeval="INDEPENDENT ASSESSOR" and  aregion="INTRACRANIAL" then put    
PARAMCD=  AVISITN= 
/*first.usubjid= last.usubjid= FIRST.AVISITN= LAST.AVISITN=*/  
FIRST.PARAMCD= LAST.PARAMCD= cum= CUM3=   
   counter= AVAL= AVALT=   _N_= ;

run;


proc print data=cttrind1;
where aeval="INVESTIGATOR" and AREGION="EXTRACRANIAL " and usubjid="BRF117277.000065" 
and PARCAT1 = "TARGET" and PARCAT2 = "LESIONS" and AVISITN = 10;

var usubjid AEVAL AREGION AVISITN PARAMCD PARCAT: PARAMCD  aval: cum CUM3 AVISITN COUNTER;
title "subj 65 cum total for baseline  look why there is  in week 32 5 in baseline and 4 in post baseline " ;
run;

proc print data=cttrind1;
where aeval="INVESTIGATOR" and AREGION="EXTRACRANIAL " and usubjid="BRF117277.000065" and PARCAT1 = "TARGET" and 
PARCAT2 = "LESIONS"  and AVISITN  = 100;
by  usubjid AEVAL AREGION   ;
var AVISITN PARAMCD PARCAT: aval cUM CUM3;
title "subj 65 cum total post baseline avisitn=100 and aval is missing" ;
run;


proc print data=SUMLD_2C;
where usubjid="BRF117277.000065"  and  aEVAL = "INVESTIGATOR"  and AREGION="EXTRACRANIAL";
*var USUBJID PARAMCD PARAM   ADT ADY AVISIT  AVISITN AVAL    
  Trg_Recs    Trg_Recs_Base ABLFL   BASE    prevBASE    prevAVAL    BASETYPE    CHG PCHG;
  title "BEFORE subj 65 cum " ;
run;


proc print data=SUMLD_2e;
where usubjid="BRF117277.000065"  and  aEVAL = "INVESTIGATOR"  and AREGION="EXTRACRANIAL";
var USUBJID PARAMCD PARAM   ADT ADY AVISIT  AVISITN AVAL    
  Trg_Recs    Trg_Recs_Base ABLFL   BASE    prevBASE    prevAVAL    BASETYPE    CHG PCHG;
  title "subj 65 cum after processing baseline and setting values for missing" ;
run;

proc print data=SUMLD_2e;
where usubjid="BRF117277.000065" and TRG_RECS ne Trg_Recs_Base 
and ^missing(AVAL) and    aEVAL = "INVESTIGATOR"  and AREGION="EXTRACRANIAL";
var USUBJID PARAMCD PARAM   ADT ADY AVISIT  AVISITN AVAL    
Trg_Recs    Trg_Recs_Base   ABLFL   BASE    prevBASE    prevAVAL    BASETYPE    CHG PCHG;
  title "subj 65 cum after processing baseline and setting values for missing" ;
run;

proc print data=sdtmdata.tr;
where usubjid="BRF117277.000065" and TRSCAT="EXTRACRANIAL"  AND TRGRPID ="TARGET" and TRTESTCD="LDIAM" ;
VAR  USUBJID    TRSEQ   TRGRPID TRLNKID TRLNKGRP    
TRTESTCD    TRTEST  TRCAT   TRSCAT  TRORRES   ;
   title "subj 65 raw data" ;
run;
 



* PARAMCD = "SUMLD3" ;
Proc SQL;
  Create table work.SUMLD_3a as
  Select distinct
      USUBJID
    , TRTSDT
    , PARCAT1
    , "DERIVED" as PARCAT2
    , AEVAL
    , AREGION
    , "SUMLD3" as PARAMCD
    , "Sum of Lesion Diameters (mm) Base = Baseline without Lymph Nodes" as PARAM
    , max(ADT) as ADT format=date9.
    , calculated ADT - TRTSDT + (calculated ADT >= TRTSDT) as ADY
    , AVISIT
    , AVISITN
    , sum(AVAL) as AVAL
  From work.TR_IND_1
  Where PARCAT1 = "TARGET" and PARCAT2 = "LESIONS" and index(ORGAN,"LYMPH NODE") = 0
  Group by USUBJID, AEVAL, AREGION, AVISITN
  ;
Quit;


* Add SUMLD# records for subjects with no target lesions at baseline or after;
Proc SQL;
  Create table work.SUMLD3_miss_A as
  Select distinct
      USUBJID
    , PARCAT1
    , "DERIVED" as PARCAT2
    , AEVAL
    , AREGION
    , "SUMLD3" as PARAMCD
    , "Sum of Lesion Diameters (mm) Base = Baseline without Lymph Nodes" as PARAM
    , . as ADT
    , . as ADY
    , AVISIT
    , AVISITN
    , . as AVAL
  From work.TR_IND_1
  Where PARCAT1 = "TARGET" and PARCAT2 = "LESIONS"
  Order by USUBJID, AEVAL, AREGION, AVISITN
  ;
Quit;

Proc SQL;
  Create table work.SUMLD3_miss_dates as
  Select distinct
      USUBJID
    , AEVAL
    , AREGION
    , AVISITN
    , max(ADT) as ADT2 format=date9.
    , calculated ADT2 - TRTSDT + (calculated ADT2 >= TRTSDT) as ADY2
  From work.TR_IND_1
  Where PARCAT1 = "TARGET" and PARCAT2 = "LESIONS"
  Group by USUBJID, AEVAL, AREGION, AVISITN
  ;
Quit;

Data work.SUMLD3_miss_C;
  Merge work.SUMLD3_miss_A (in=inMISS)
        work.SUMLD3_miss_dates
        ;
  By USUBJID AEVAL AREGION AVISITN ;
  If inMISS;
  ADT = coalesce(ADT,ADT2);
  ADY = coalesce(ADY,ADY2);

Run;

Data work.SUMLD_3b;
  Set work.SUMLD_3a
      work.SUMLD3_miss_C
      ;
Run;

Proc sort data= work.SUMLD_3b;
  By USUBJID AEVAL AREGION AVISITN PARAMCD AVAL;
Run;

Data work.SUMLD_3c;
  Set work.SUMLD_3b;
  By USUBJID AEVAL AREGION AVISITN PARAMCD AVAL;
  If last.AVISITN;
Run;


Proc SQL;
  /* SUMLD3 Baseline Flag */
  Create table work.BaseFlag_SUMLD3 as
    Select distinct USUBJID, AEVAL, AREGION, AVISITN, "SUMLD3" as PARAMCD, "Y" as ABLFL
    From work.SUMLD_3c
    Where AVISITN < 20
    Group by USUBJID, AEVAL, AREGION, AVISITN
    Having ADT = max(ADT)
  ;

  /* SUMLD3 Baseline Value */
  Create table work.BaseVal_SUMLD3 as
    Select distinct USUBJID, AEVAL, AREGION, "SUMLD3" as PARAMCD, AVAL as BASE
    From work.SUMLD_3c
    Where AVISITN < 20
    Group by USUBJID, AEVAL, AREGION
    Having ADT = max(ADT)
  ;
Quit;

proc sort data= work.SUMLD_3c;
  By USUBJID AEVAL AREGION AVISITN PARAMCD ;
Run;

Data work.SUMLD_3d;
  Merge work.SUMLD_3c
        work.BaseFlag_SUMLD3
        ;
  By USUBJID AEVAL AREGION AVISITN PARAMCD ;
Run;

proc sort data= work.SUMLD_3d;
  By USUBJID AEVAL AREGION PARAMCD ;
Run;

Data work.SUMLD_3e; /*for 3f*/
  Merge work.SUMLD_3d
        work.BaseVal_SUMLD3
        ;
  By USUBJID AEVAL AREGION PARAMCD ;

  BASETYPE = "Last non-missing SLD (non-Lymph Node) prior to treatment";
  If nmiss(AVAL,BASE) = 0 and  AVISITN > 10 then CHG = AVAL - BASE;
  If not missing(CHG) then PCHG = CHG/BASE*100;
Run;


* adjust for SUMLD1 values that include records with missing values ;
Proc SQL;
  * Get SUMLD2 value per visit ;
  Create table work.SUMLD2_Base as /* for 1f*/
  Select distinct USUBJID, AEVAL, AREGION, AVISITN, BASE as Base_SUMLD2
  From work.SUMLD_2e
  Where AVISITN ne 10
  Order by USUBJID, AEVAL, AREGION, AVISITN
  ;
Run;


*********sumld_1f-- sumld_1e+ trgs_recs_2 and sumld2_base;

Data work.SUMLD_1f;
  Merge work.SUMLD_1e (in=inSUM)
        work.TRG_RECS_2
        work.SUMLD2_Base
        ;
  By USUBJID AEVAL AREGION AVISITN;
  If inSUM;

  If TRG_RECS ne Trg_Recs_Base and not missing(AVAL) then do;
    If AVAL <= 1.2*Base_SUMLD2 then call missing(AVAL, CHG, PCHG);
  End;
Run;

********** adjust for SUMLD3 values that include records with missing values ;
Proc SQL;
  * Get a count of non-lymph node target lesion records at Screening basline ;
  Create table work.TRG_Recs_Base_NLN as /* merge later with non base for 3f*/
  Select distinct USUBJID, AEVAL, AREGION, count(PARAMCD) as Trg_Recs_Base
  From work.TR_IND_1
  Where PARCAT1 = "TARGET" and PARCAT2 = "LESIONS" and not missing(AVAL) and AVISITN = 10
    and index(ORGAN,"LYMPH NODE") = 0
  Group by USUBJID, AEVAL, AREGION
  ;

  * Get a count of non-lymph node target lesion records at each visit ;
  Create table work.TRG_Recs_NLN as
  Select distinct USUBJID, AEVAL, AREGION, AVISITN, count(PARAMCD) as Trg_Recs
  From work.TR_IND_1
  Where PARCAT1 = "TARGET" and PARCAT2 = "LESIONS" and not missing(AVAL) and AVISITN ^= 10
    and index(ORGAN,"LYMPH NODE") = 0
  Group by USUBJID, AEVAL, AREGION, AVISITN
  ;
Quit;

Data work.TRG_Recs_NLN_2;
  Merge work.TRG_Recs_NLN
        work.TRG_Recs_Base_NLN
        ;
  By USUBJID AEVAL AREGION;
Run;


*********sumld_3f-- 3e+ trgs_recs_nln2;


Data work.SUMLD_3f;  *** final 3 for sumld_all;
  Merge work.SUMLD_3e (in=inSUM)
        work.TRG_RECS_NLN_2
        ;
  By USUBJID AEVAL AREGION AVISITN;
  If inSUM;

  If TRG_RECS ne Trg_Recs_Base then call missing(AVAL, CHG, PCHG);
Run;


Data work.SUMLD_all;
  Length PARAM $200
         BASETYPE $60 ;
  Set work.SUMLD_1f
      work.SUMLD_2e (drop=prevAVAL)
      work.SUMLD_3f
      ;

  If not missing(AVAL) then AVALC = strip(put(AVAL, best.));

  *If PARAMCD = "SUMLD2" and missing(Trg_Recs) then call missing(BASE);

Run;

Proc sort data= work.SUMLD_all;
  By USUBJID AEVAL AREGION AVISITN ;
Run;

***************** start RS processing;


/* Summary data from SDTM.RS */
Proc sort data = SDTMData.suppRS
          out = work.suppRS_in ;

  by USUBJID IDVAR IDVARVAL;
run;

proc transpose data = work.suppRS_in (where=(IDVAR = "RSSEQ"))
               out=work.suppRS_1a;
  by USUBJID IDVAR IDVARVAL;
  var QVAL;
  id QNAM;
  idlabel QLABEL;
run;

Data work.suppRS_1b (drop= IDVAR IDVARVAL _NAME_ _LABEL_);
  Set work.suppRS_1a;
  RSSEQ = input(IDVARVAL, best.);
Run;

Proc sort data = work.suppRS_1b;
  By USUBJID RSSEQ;
Run;

Data RS_SUM_1;
  Merge SDTMData.RS (in=inRS
                     where=(RSTESTCD in ("DRVRESP", "NEWLPROG", "NTRGRESP", "OVRLRESP", "TRGRESP" , "NRADPROG")
                            and RSEVAL in ("INVESTIGATOR","INDEPENDENT ASSESSOR")
                            and RSSCAT in ("BRAIN", "EXTRACRANIAL")
                            and not missing(VISITNUM)))
        work.suppRS_1b ;
  By USUBJID RSSEQ;
  If inRS;

  PARAMCD = RSTESTCD;
  PARAM = RSTEST;

  Select (PARAMCD);
    When ("NTRGRESP") PARCAT1 = "NON-TARGET";
    When ("TRGRESP")  PARCAT1 = "TARGET";
    When ("NEWLPROG") PARCAT1 = "NEW";
    When ("OVRLRESP") PARCAT1 = "OVERALL";
    When ("DRVRESP")  PARCAT1 = "OVERALL";
    Otherwise;
  End;

  PARCAT2 = "DERIVED";
  AEVAL = RSEVAL;

  Select (RSSCAT);
    When ("BRAIN")        AREGION = "INTRACRANIAL";
    When ("EXTRACRANIAL") AREGION = "EXTRACRANIAL";
    Otherwise;
  End;

  AVISIT = VISIT;
  AVISITN = VISITNUM;
  If not missing(RSSTRESC) then AVALC = RSSTRESC;
  Else if RSSTAT = "NOT DONE" then AVALC = "NA";


Run;

* CRIT4 ;
Proc sort data=SDTMdata.RS
            (keep= USUBJID RSEVAL RSSCAT VISITNUM RSSTRESC RSTESTCD RSDTC
             where=(RSTESTCD = "NRADPROG" and not missing(VISITNUM))
             rename=(RSSTRESC = NRADPROG  RSDTC = NRAD_DT))
          out=work.NRADPROG_1 (drop= RSTESTCD) nodupkey;
  By USUBJID RSEVAL RSSCAT VISITNUM;
Run;

Data work.NRADPROG_2;
  Set work.NRADPROG_1;
  RSTESTCD = "OVRLRESP";
Run;

Proc sort data= work.RS_SUM_1;
  By USUBJID RSEVAL RSSCAT RSTESTCD VISITNUM;
Run;

Data work.RS_SUM_2;
  Merge work.RS_SUM_1 (in=inRS)
        work.NRADPROG_2 
        ;
  By USUBJID RSEVAL RSSCAT RSTESTCD VISITNUM;
  If inRS;

  If PARAMCD = "OVRLRESP" and not missing(NRADPROG) then do;
    CRIT4FL = "Y";
    CRIT4 = "Symptomatic Progression";
  End;
Run;

Proc sort data= work.RS_SUM_1;
  By USUBJID RSEVAL RSSCAT RSTESTCD VISITNUM;
Run;

* PARAMCD = "DRVRESP";
Proc sort data = work.RS_SUM_2 (keep= USUBJID AEVAL AREGION AVISIT AVISITN PARAMCD AVALC
                                 where=(PARAMCD in("TRGRESP","NTRGRESP","NEWLPROG")
                                        and AEVAL = "INDEPENDENT ASSESSOR"
                                        and AVISIT ne "SCREENING"))
          out = work.DRV_IND_1
          ;
  By USUBJID AEVAL AREGION AVISITN PARAMCD;
Run;

Proc transpose data = work.DRV_IND_1 out=work.DRV_IND_2;
  By USUBJID AEVAL AREGION AVISITN AVISIT ;
  Var AVALC;
  Id PARAMCD ;
Run;

Data work.DRV_IND_3;
  Set work.DRV_IND_2;
  By USUBJID AEVAL AREGION AVISITN AVISIT ;

  PARCAT1 = "OVERALL";
  PARCAT2 = "DERIVED";

  PARAMCD = "DRVRESP";
  PARAM   = "Derived Response Score";

  Length AVALC $60 ;
  If TRGRESP = "PD" or NTRGRESP = "PD" or NEWLPROG in ("PD", "PD (Downgraded)","UNEQUIVOCAL") then AVALC = "PD";
  Else if TRGRESP = "CR" and NTRGRESP in ("CR", "NA", "") and NEWLPROG ^= "PD" then AVALC = "CR";
  Else if TRGRESP in("CR","PR") and NTRGRESP ^= "PD" and NEWLPROG ^= "PD" then AVALC = "PR";
  Else if TRGRESP = "SD" and NTRGRESP ^= "PD" and NEWLPROG ^= "PD" then AVALC = "SD";
  Else if TRGRESP = "NE" and NTRGRESP ^= "PD" and NEWLPROG ^= "PD" then AVALC = "NE";
  Else if TRGRESP = "NA" then AVALC = "NA";
Run;

Data work.RS_SUM_3A;
  Set work.RS_SUM_2(where=(rsstat^='NOT DONE' or rstestcd in ("NTRGRESP","TRGRESP","NEWLPROG")))
      work.DRV_IND_3 (drop=_NAME_ TRGRESP NTRGRESP NEWLPROG)
      ;
Run;

* CRIT5 ;
Proc SQL;
  Create table work.Crit5_EI_1a as
  Select distinct a.USUBJID, a.AEVAL, a.AREGION, a.AVISITN
                , "OVRLRESP" as PARAMCD
                , "Y" as CRIT5FL
                , "Progression (downgraded)" as CRIT5
  From work.TR_IND_1 a , work.TR_IND_1 b
  Where (a.PARCAT1 = "NEW"     and b.PARCAT1 = "NEW" )
    and (a.PARCAT2 = "LESIONS" and b.PARCAT2 = "LESIONS" )
    and (a.AVALC = "EQUIVOCAL" and index(b.AVALC,"UNEQUIVOCAL") > 0 )
    and a.USUBJID = b.USUBJID
    and a.AEVAL   = b.AEVAL
    and a.AREGION = b.AREGION
    and a.ORGAN   = b.ORGAN
    and a.AVISITN < b.AVISITN
  Order by a.USUBJID, a.AEVAL, a.AREGION, a.AVISITN
  ;
  Create table work.Crit5_EI_1b as
  Select distinct b.USUBJID, b.AEVAL, b.AREGION, b.AVISITN
                , b.PARAMCD
                , "Y" as CRIT5FL
                , "Progression (downgraded)" as CRIT5
  From work.RS_SUM_3A a , work.RS_SUM_3A b
  Where a.PARAMCD = "OVRLRESP" and b.PARAMCD = "OVRLRESP"
    and a.AVALC   = "CR"       and b.AVALC in ("PR","SD","Non-CR/Non-PD")
    and a.USUBJID = b.USUBJID
    and a.AEVAL   = b.AEVAL
    and a.AREGION = b.AREGION
    and a.AVISITN < b.AVISITN
  Order by b.USUBJID, b.AEVAL, b.AREGION, b.AVISITN
  ;
  Create table work.New_Les_1 as
  Select distinct a.USUBJID, a.AEVAL, a.AREGION, a.AVISITN
                , "DRVRESP" as PARAMCD
                , "Y" as New_Les_FL
  From work.TR_IND_1 a
  Where a.PARCAT1 = "NEW"
    and a.PARCAT2 = "LESIONS"
    and index(a.AVALC,"UNEQUIVOCAL") > 0
  Order by a.USUBJID, a.AEVAL, a.AREGION, a.AVISITN
  ;
Quit;

Data work.Crit5_EI_2;
  Set work.Crit5_EI_1a
      work.Crit5_EI_1b
      ;
Run;

Proc sort data=work.Crit5_EI_2;
  By USUBJID AEVAL AREGION PARAMCD AVISITN;
Run;

Proc sort data=work.RS_SUM_3A;
  By USUBJID AEVAL AREGION PARAMCD AVISITN;
Run;

Data work.RS_SUM_3B;
  Merge work.RS_SUM_3A
        work.Crit5_EI_2
        ;
  By USUBJID AEVAL AREGION PARAMCD AVISITN;

  tmpCRIT5FL = CRIT5FL;
  If PARAMCD = "OVRLRESP" and AVALC  = "PD" then call missing(CRIT5, CRIT5FL);
  If PARAMCD = "OVRLRESP" and AVALC ^= "PD" and CRIT5FL = "Y" then AVALC = "PD";
Run;

Proc SQL;
  Create table work.Crit5_EI_3 as
  Select distinct USUBJID, AEVAL, AREGION, AVISITN
                , "DRVRESP" as PARAMCD
                , tmpCRIT5FL
  From work.RS_SUM_3B
  Where PARAMCD = "OVRLRESP" and tmpCRIT5FL = "Y" and RSSTRESC ^= "PD"
  Order by USUBJID, AEVAL, AREGION, AVISITN
  ;
Quit;

Data work.RS_SUM_3C;
  Merge work.RS_SUM_3B (in=inR)
        work.Crit5_EI_3
        work.New_Les_1
        ;
  By USUBJID AEVAL AREGION PARAMCD AVISITN;
  If inR;

  If missing(CRIT5FL) then CRIT5FL = tmpCRIT5FL;
  If PARAMCD = "OVRLRESP" and RSSTRESC  = "PD" then call missing(CRIT5, CRIT5FL);

  If PARAMCD = "DRVRESP" and AVALC  = "PD" then call missing(CRIT5, CRIT5FL);

  If PARAMCD = "DRVRESP" and AVALC ^= "PD" and CRIT5FL = "Y" then AVALC = "PD";
  *If PARAMCD = "DRVRESP" and AVALC ^= "PD" and New_Les_FL = "Y" then AVALC = "PD";

Run;

Proc sort data=work.RS_SUM_3C ;
  By USUBJID AEVAL AREGION PARAMCD AVISITN;
Run;

* ADT ;
Proc SQL;
  Create table work.TRGRESP_Dates as
  Select distinct USUBJID, AEVAL, AREGION, AVISITN, "TRGRESP" as PARAMCD, ADT as TRG_DT
  From work.TR_IND_1
  Where PARCAT1 = "TARGET" and PARCAT2 = "LESIONS" and AVISITN ne 10
  Group by USUBJID, AEVAL, AREGION, AVISITN
  Having ADT = max(ADT)
  ;

  Create table work.NTRGRESP_Dates as
  Select distinct USUBJID, AEVAL, AREGION, AVISITN, "NTRGRESP" as PARAMCD, ADT as NT_DT
  From work.TR_IND_1
  Where PARCAT1 = "NON-TARGET" and PARCAT2 = "LESIONS" and AVISITN ne 10
  Group by USUBJID, AEVAL, AREGION, AVISITN
  Having ADT = max(ADT)
  ;

  Create table work.NEWLPROG_Dates as
  Select distinct USUBJID, AEVAL, AREGION, AVISITN, "NEWLPROG" as PARAMCD, ADT as NEW_DT
  From work.TR_IND_1
  Where PARCAT1 = "NEW" and PARCAT2 = "LESIONS" and AVISITN ne 10
  Group by USUBJID, AEVAL, AREGION, AVISITN
  Having ADT = max(ADT)
  ;

  * OVRLRESP ;
  Create table work.Early_Late_Dt_1 as
  Select distinct USUBJID, AEVAL, AREGION, AVISITN, "OVRLRESP" as PARAMCD, min(ADT) as Early, max(ADT) as Late
  From work.TR_IND_1
  Where PARCAT1 in ("TARGET","NON-TARGET") and PARCAT2 = "LESIONS" and AVISITN ne 10
    and REASND ^= "SCAN NOT PERFORMED"
    /* and missing(REASND) */
    /* and not missing(AVALC) */
  Group by USUBJID, AEVAL, AREGION, AVISITN
  ;
  Create table work.TarDt_1 as
  Select distinct a.USUBJID, a.AEVAL, a.AREGION, a.AVISITN, "OVRLRESP" as PARAMCD, min(a.ADT) as _tardt
  From work.TR_IND_1 a,   work.RS_SUM_3b b
  Where a.USUBJID = b.USUBJID and a.AEVAL = b.AEVAL and a.AVISITN = b.AVISITN
    and a.PARCAT1 = "TARGET"
    and a.PARCAT2 = "LESIONS"
    and a.AVISITN ne 10
    and not missing(a.AVALC)
    and a.ADT > a.TRTSDT
    and b.PARAMCD = "TRGRESP"
    and b.AVALC = "PD"
  Group by a.USUBJID, a.AEVAL, a.AREGION, a.AVISITN
  ;
  Create table work.NonDt_1 as
  Select distinct a.USUBJID, a.AEVAL, a.AREGION, a.AVISITN, "OVRLRESP" as PARAMCD, min(a.ADT) as _nondt
  From work.TR_IND_1 a,   work.RS_SUM_3b b
  Where a.USUBJID = b.USUBJID and a.AEVAL = b.AEVAL and a.AVISITN = b.AVISITN
    and a.PARCAT1 in ("NON-TARGET")
    and a.PARCAT2 = "LESIONS"
    and a.AVISITN ne 10
    and a.AVALC = "UNEQUIVOCAL PROGRESSION"
    and a.ADT > a.TRTSDT
    and b.PARAMCD = "NTRGRESP"
    and b.AVALC = "PD"
  Group by a.USUBJID, a.AEVAL, a.AREGION, a.AVISITN
  ;
  Create table work.NewDt1_1 as
  Select distinct USUBJID, AEVAL, AREGION, AVISITN, "OVRLRESP" as PARAMCD, min(ADT) as _newdt1
  From work.TR_IND_1
  Where PARCAT1 in ("NEW") and PARCAT2 = "LESIONS" and AVISITN ne 10
  Group by USUBJID, AEVAL, AREGION, AVISITN
  ;
  Create table work.NewDt2_1 as
  Select distinct a.USUBJID, a.AEVAL, a.AREGION, a.AVISITN
                , "OVRLRESP" as PARAMCD
                , min(b.ADT) as _newdt2 format=date9.
  From work.TR_IND_1 a , work.TR_IND_1 b
  Where a.PARCAT1 = "NEW"     and b.PARCAT1 = "NEW"
    and a.PARCAT2 = "LESIONS" and b.PARCAT2 = "LESIONS"
    and index(a.AVALC,"UNEQUIVOCAL") > 0 and b.AVALC = "EQUIVOCAL"
    and a.USUBJID = b.USUBJID
    and a.AEVAL   = b.AEVAL
    and a.AREGION = b.AREGION
    and a.ORGAN   = b.ORGAN
    and a.AVISITN > b.AVISITN
  Group by a.USUBJID, a.AEVAL, a.AREGION, a.AVISITN
  ;
Quit;

* Create DRVRESP date records from OVRLRESP date records ;
%macro DRVRESP_DT (newPARAMCD=DRVRESP, DSNin=, DSNout=);
  Data &DSNout. ;
    Set &DSNin. ;
    Output;
    PARAMCD = "&newPARAMCD.";
    Output;
  Run;

  Proc sort data = &DSNout.;
    By USUBJID AEVAL AREGION PARAMCD AVISITN;
  Run;
%mend DRVRESP_DT;

%DRVRESP_DT (DSNin=work.Early_Late_Dt_1, DSNout=work.Early_Late_Dt_2 );
%DRVRESP_DT (DSNin=work.TarDt_1, DSNout=work.TarDt_2 );
%DRVRESP_DT (DSNin=work.NonDt_1, DSNout=work.NonDt_2 );
%DRVRESP_DT (DSNin=work.NewDt1_1, DSNout=work.NewDt1_2 );
%DRVRESP_DT (DSNin=work.NewDt2_1, DSNout=work.NewDt2_2 );

Data work.RS_SUM_4A work.temp_1;
  Merge work.RS_SUM_3C (in=inRS)
        work.TRGRESP_Dates
        work.NTRGRESP_Dates
        work.NEWLPROG_Dates
        work.Early_Late_Dt_2
        work.TarDT_2
        work.NonDt_2
        work.NewDt1_2
        work.NewDt2_2 ;
  By USUBJID AEVAL AREGION PARAMCD AVISITN;
  If not inRS then output temp_1;
  If inRS;

  format EARLY LATE ADT _: date9. ;

    If PARAMCD = "TRGRESP" then ADT = TRG_DT ; *coalesce(TRG_DT,input(RSDTC,yymmdd10.));
    Else if PARAMCD = "NTRGRESP" then ADT = NT_DT ; *coalesce(NT_DT,input(RSDTC,yymmdd10.));
    Else if PARAMCD = "NEWLPROG" then ADT = NEW_DT ; *coalesce(NEW_DT,input(RSDTC,yymmdd10.));
    Else if PARAMCD in ("OVRLRESP","DRVRESP") then do;
      If AVALC in ("SD", "Non-CR/Non-PD", "NE") and CRIT5FL ^= "Y" then ADT = Early ; *coalesce(Early,input(RSDTC,yymmdd10.));
      Else if AVALC in ("CR", "PR") and CRIT5FL ^= "Y" then ADT = Late ; * coalesce(Late,input(RSDTC,yymmdd10.));
      Else if AVALC = "PD" then do;
        If CRIT5FL ^= "Y" then do;
          If nmiss (_tardt, _nondt, _newdt1) ne 3 then ADT = min (_tardt, _nondt, _newdt1 );
        End;
        If CRIT5FL = "Y" then do;
          If nmiss (_tardt, _nondt, _newdt1, _newdt2) ne 4 then ADT = min (_tardt, _nondt, _newdt1, _newdt2);
        End;
     /*   If missing(ADT) then do;
          If not missing(RSDTC) then ADT = input(RSDTC,yymmdd10.);
        End;  */
        If missing(ADT) then ADT = Early;
      End;
    End;
  Output RS_SUM_4A;
Run;

Data work.RS_SUM_4B;
  Merge work.RS_SUM_4A
        ADAMData.ADSL (keep=USUBJID TRTSDT)
        ;
  By USUBJID;
Run;

Data work.ADTR1_1;
  Length AVALC $72 PARAM $64 PARAMCD $12 ;
  Set work.RS_SUM_4B
      work.TR_IND_1
      work.SUMLD_all
      ;
  By USUBJID;
  If nmiss(ADT, TRTSDT) = 0 then ADY = ADT - TRTSDT + (ADT >= TRTSDT);
  Else if missing(ADT) then call missing(ADY);
Run;

Proc sort data = work.ADTR1_1 out = work.ADTR1_2 ; * dupout=dupes_1 nodupkey;
  By USUBJID AEVAL PARCAT1 PARCAT2 AREGION PARAMCD AVISITN ADT TRLNKGRP;
Run;

Proc SQL;
  Create table work.BLFL as
  Select distinct USUBJID, AEVAL, PARCAT1, PARCAT2, AREGION, PARAMCD, AVISITN, ADT, "Y" as ABLFL
  From work.ADTR1_2
  Where AVISITN = 10
    /* and nmiss(ADT,TRTSDT) = 0 */
    and not missing(AVISITN)
  Order by USUBJID, AEVAL, PARCAT1, PARCAT2, AREGION, PARAMCD
  /* Group by USUBJID, AEVAL, PARCAT1, PARCAT2, AREGION, PARAMCD
  Having ADT = max(ADT) */
  ;
Quit;

Data work.ADTR1_3;
  Merge work.ADTR1_2
        work.BLFL
        ;
  By USUBJID AEVAL PARCAT1 PARCAT2 AREGION PARAMCD AVISITN ADT;
  If ABLFL = "Y" and PARAMCD in("SUMLD2", "SUMLD3") then call missing(BASE);
Run;


* CRIT6FL ;
Proc SQL;
  Create table work.CRIT6_1A as
  Select USUBJID, AEVAL, AREGION, PARAMCD, AVISITN, ADT
  From work.ADTR1_3
  Where PARAMCD = "OVRLRESP"
    and AVALC in ("CR","PR","SD","Non-CR/Non-PD")
  ;

  Create table work.CRIT6_1B as
  Select distinct USUBJID, AEVAL, AREGION, AVISITN
  From work.ADTR1_3
  Where PARAMCD = "DRVRESP"
    and AVALC in ("CR","PR","SD")
  ;

  Create table work.CRIT6_1C as
  Select distinct a.USUBJID, a.AEVAL, a.AREGION, a.PARAMCD, a.AVISITN, a.ADT
  From work.ADTR1_3 a  ,   work.CRIT6_1B b
  Where a.USUBJID = b.USUBJID
    and a.AEVAL   = b.AEVAL
    and a.AREGION = b.AREGION
    and a.AVISITN = b.AVISITN
    and a.PARAMCD = "OVRLRESP"
    and a.CRIT4FL = "Y"
  ;
Quit;

Data work.CRIT6_2;
  Set work.CRIT6_1A
      work.CRIT6_1C
      ;
  If not missing(ADT);
Run;

Proc sort data= work.CRIT6_2;  By USUBJID AEVAL AREGION PARAMCD ADT;  Run;

Data work.CRIT6_3;
  Set work.CRIT6_2;
  By USUBJID AEVAL AREGION ADT;
  If last.AREGION;
  CRIT6FL = "Y";
  CRIT6 = "Last Adequate Assesment";
Run;

Proc sort data= work.ADTR1_3;  By USUBJID AEVAL AREGION PARAMCD ADT;  Run;

Data work.ADTR1_4;
  Merge work.ADTR1_3
        work.CRIT6_3
        ;
  By USUBJID AEVAL AREGION PARAMCD ADT;

  If AVALC = "PD" then call missing(CRIT6, CRIT6FL);
Run;

* PDORG ;
Proc SQL;
  Create table work.PDORG_Targ as
  Select distinct USUBJID, AEVAL, AREGION, AVISITN, "Target Lesions" as _targ
  From work.ADTR1_4
  Where PARAMCD = "TRGRESP" and AVALC = "PD"
    and USUBJID in (Select distinct USUBJID from work.ADTR1_4 where PARAMCD = "OVRLRESP" and (AVALC = "PD" or CRIT5FL = "Y"))
  ;

  Create table work.PDORG_nonTarg_1 as
  Select distinct USUBJID, AEVAL, AREGION, AVISITN, ORGAN
  From work.ADTR1_4
  Where AVALC = "UNEQUIVOCAL PROGRESSION" and PARCAT1 = "NON-TARGET" and PARCAT2 = "LESIONS"
    and USUBJID in (Select distinct USUBJID from work.ADTR1_4 where PARAMCD = "OVRLRESP" and (AVALC = "PD" or CRIT5FL = "Y"))
  ;

  Create table work.PDORG_New_1 as
  Select distinct USUBJID, AEVAL, AREGION, AVISITN, ORGAN
  From work.ADTR1_4
  Where index(AVALC,"UNEQUIVOCAL") > 0 and PARCAT1 = "NEW" and PARCAT2 = "LESIONS"
    and USUBJID in (Select distinct USUBJID from work.ADTR1_4 where PARAMCD = "OVRLRESP" and (AVALC = "PD" or CRIT5FL = "Y"))
  ;

  Create table work.PDORG_New_2 as
  Select distinct a.USUBJID, a.AEVAL, a.AREGION, a.AVISITN, a.ORGAN
  From work.ADTR1_4 a , work.ADTR1_4 b
  Where a.PARCAT1 = "NEW"     and b.PARCAT1 = "NEW"
    and a.PARCAT2 = "LESIONS" and b.PARCAT2 = "LESIONS"
    and a.AVALC = "EQUIVOCAL" and index(b.AVALC,"UNEQUIVOCAL") > 0
    and a.USUBJID = b.USUBJID
    and a.AEVAL   = b.AEVAL
    and a.AREGION = b.AREGION
    and a.ORGAN   = b.ORGAN
    and a.AVISITN < b.AVISITN
  Order by a.USUBJID, a.AEVAL, a.AVISITN
  ;
Quit;

Proc transpose data= work.PDORG_nonTarg_1
               out= work.PDORG_nonTarg_2 (drop=_NAME_)
               prefix= ORGAN;
  By USUBJID AEVAL AREGION AVISITN;
  Var ORGAN;
Run ;

Data work.PDORG_nonTarg_3 (keep = USUBJID AEVAL AREGION AVISITN _nontarg) ;
  Set work.PDORG_nonTarg_2 ;
  Length _nontarg $99 ;
  _nontarg = catx(": ", "Non-target", catx(", " , of ORGAN: )) ;
Run ;

Data work.PDORG_New_3A;
  Set work.PDORG_New_1
      work.PDORG_New_2
      ;
  By USUBJID AEVAL AREGION AVISITN;
Run ;

Proc transpose data= work.PDORG_New_3A
               out= work.PDORG_New_3B (drop=_NAME_)
               prefix= ORGAN;
  By USUBJID AEVAL AREGION AVISITN;
  Var ORGAN;
Run ;

Data work.PDORG_New_3C (keep = USUBJID AEVAL AREGION AVISITN _new) ;
  Set work.PDORG_New_3B ;
  Length _new $99 ;
  _new = catx(": ", "New", catx(", " , of ORGAN: )) ;
Run ;

Data work.PDORG_1 (keep= USUBJID AEVAL AREGION AVISITN PDORG);
  Merge work.PDORG_targ
        work.PDORG_nontarg_3
        work.PDORG_new_3C
        ;
  By USUBJID AEVAL AREGION AVISITN ;

  Length PDORG $200 ;
  PDORG = catx("; ",_targ, _nontarg, _new);

Run;

Proc sort data= work.ADTR1_4 (where=(PARAMCD= "OVRLRESP" and (AVALC = "PD" or CRIT5FL = "Y")))
          out= work.OVRL_PD;
  By USUBJID AEVAL AREGION AVISITN ;
Run;

Data work.PDORG_2;
  Merge work.OVRL_PD (in=inOV keep=USUBJID PARCAT1 PARCAT2 AEVAL AREGION PARAM PARAMCD ADT ADY AVISIT AVISITN )
        work.PDORG_1
        ;
  By USUBJID AEVAL AREGION AVISITN ;
  If inOV;

  Call missing(PARAM, PARAMCD);
  PARAMCD = "PDORG";
  PARAM =  "Organs of Progression";
  AVALC = PDORG;
Run;

Proc sort data= work.ADTR1_4 ;
  By USUBJID AEVAL AREGION AVISITN ;
Run;

Data work.ADTR1_5 (keep=USUBJID PARCAT1 PARCAT2 PARCAT3 AEVAL AREGION PARAM PARAMCD ADT ADY AVISIT AVISITN
                        AVAL AVALC CRIT1 CRIT1FL CRIT2 CRIT2FL CRIT3 CRIT3FL CRIT4 CRIT4FL CRIT5 CRIT5FL
                        CRIT6 CRIT6FL ABLFL BASE BASETYPE CHG PCHG LSTATUS METHOD ORGAN LOCATION LSTHICK
                        SCNINTU RADSTDT RADTYPCD MELMALSP CLSY RDTYPE REASND
                        TRLNKGRP ) ;
  Attrib PARCAT1  label= "Parameter Category 1"
         PARCAT2  label= "Parameter Category 2"
         PARCAT3  label= "Parameter Category 3"
         AEVAL    label= "Evaluator"
         AREGION  label= "Lesion Region"
         PARAM    label= "Parameter"
         PARAMCD  label= "Parameter Code"
         ADT      label= "Analysis Date"
         ADY      label= "Analysis Relative Day"
         AVISIT   label= "Analysis Visit"
         AVISITN  label= "Analysis Visit (N)"
         AVAL     label= "Analysis Value"
         AVALC    label= "Analysis Value (C)"                        length= $200
         CRIT1    label= "Analysis Criterion 1"
         CRIT1FL  label= "Criterion 1 Evaluation Result Flag"
         CRIT2    label= "Analysis Criterion 2"
         CRIT2FL  label= "Criterion 2 Evaluation Result Flag"
         CRIT3    label= "Analysis Criterion 3"
         CRIT3FL  label= "Criterion 3 Evaluation Result Flag"
         CRIT4    label= "Analysis Criterion 4"
         CRIT4FL  label= "Criterion 4 Evaluation Result Flag"
         CRIT5    label= "Analysis Criterion 5"
         CRIT5FL  label= "Criterion 5 Evaluation Result Flag"
         CRIT6    label= "Analysis Criterion 6"
         CRIT6FL  label= "Criterion 6 Evaluation Result Flag"
         ABLFL    label= "Baseline Record Flag"
         BASE     label= "Baseline Value"
         BASETYPE label= "Baseline Type"                            length= $60
         CHG      label= "Change From Baseline"
         PCHG     label= "Percent Change from Baseline"
         LSTATUS  label= "Lesion Status"
         METHOD   label= "Method"
         ORGAN    label= "Organ"
         LOCATION label= "Location"
         LSTHICK  label= "Slice Thickness"                          length= $3
         SCNINTU  label= "Scan Interval Unit"
         RADSTDT  label= "Start date"
         RADTYPCD label= "Type of radiotherapy code"
         MELMALSP label= "Malignancy findings specify"
         CLSY     label= "Clinical symptoms progression and method" length= $91
         RDTYPE   label= "Read Type"
         REASND   label= "Reason Not Done"
         ;

  Set work.ADTR1_4
      work.PDORG_2
      ;
  By USUBJID AEVAL AREGION AVISITN;
  PARCAT3 = "REGIONAL";

  If PARCAT1 = "TARGET" and PARCAT2 = "LESIONS" and index(ORGAN, "LYMPH NODE") > 0 then do;
    If AVAL < 10 then CRIT1FL = "Y";
    Else if AVAL >= 10 then CRIT1FL = "N";
  End;
  Else call missing(CRIT1FL);
  If CRIT1FL in ("Y","N") then CRIT1 = "All target lymph node short axis < 10mm";

  If PARCAT2 = "LESIONS" and AVISITN = 10 and missing(ABLFL) then ABLFL = "Y";
Run;

Data work.ADTR1_6 ;
  Merge ADAMData.ADSL(in=inADSL /*keep= STUDYID USUBJID SUBJID SITEID RANDDT AGE AGEGRP AGEGRPN SEX RACE STAGE
                                      ATSFL ATSFN COHORT COHORTN TRT01A TRT01AN TRT01P TRT01PN TRTSDT TRTEDT DTHDT
                                      ECOGBL VISGR1BL VISDSBL NEXBL NINTRBL NINNTRBL GENCOV
                                      AGECATBL TSIRDIAG RACECAT TSEXDIAG NANTYDT NANTYFL*/
                      Where=(ATSFL="Y"))
        work.ADTR1_5 (in=inADTR )
        ;
  By USUBJID;
  If inADSL and inADTR;

   TRTP=TRT01P;
   TRTPN=TRT01PN;
   TRTA=TRT01A;
   TRTAN=TRT01AN;
  ;

  * drop screening records for Response items;
  If PARAMCD in("TRGRESP","NTRGRESP","OVRLRESP") and AVISITN = 10 then delete;

  * drop PARAMCD = PDORG for the interim;
  /*If PARAMCD = "PDORG" then delete;*/

  *If PARAMCD in ("SUMLD1", "SUMLD3") and missing(AVAL) then delete;

  If PARAMCD in ("SUMLD2", "SUMLD3") and AVISITN <= 10 then delete;

  If PARCAT1 in ("NEW","NON-TARGET") and PARCAT2 = "LESIONS" then do;
    If missing(LSTATUS) then LSTATUS = AVALC;
  End;

  LOCATION = compbl(LOCATION);

  If PARAMCD = "DRVRESP" then call missing(CRIT5, CRIT5FL);

Run;


data ADTR1_6_ ;
length avisit $ 20 avalc $ 72 BASETYPE $ 56  organ $ 22 LOCATION $ 72 SCNINTU $ 10 RADTYPCD $ 31 MELMALSP $ 1 CLSY $ 91 RDTYPE $ 183 REASND $ 500;
set ADTR1_6 ;
label
                    RANDDT    =  'Date of Randomization'
                     ATSFL     =  'ATS Population'
                     TRT01A    =  'Actual Treatment Period 01'
                     TRT01AN   =  'Actual Treatment (N) Period 01'
                     TRT01P    =  'Planned Treatment Period 01'
                     TRT01PN   =  'Planned Treatment (N) Period 01'
                     PARCAT1   =  'Parameter Category'
                     AREGION   =  'Region'
                     PARAMCD   =  'Parameter code'
                     ADT       =  'Analysis Start Date'
                     ADY       =  'Analysis Start Relative Date'
                     AVAL      =  'Analysis Value Numeric'
                     CRIT1     =  'Analysis Criteria 1'
                     CRIT1FL   =  'Analysis Criteria 1 Flag'
                     CRIT2     =  'Analysis Criteria 2'
                     CRIT2FL   =  'Analysis Criteria 2 Flag'
                     CRIT3     =  'Analysis Criteria 3'
                     CRIT3FL   =  'Analysis Criteria 3 Flag'
                     CRIT4     =  'Analysis Criteria 4'
                     CRIT4FL   =  'Analysis Criteria 4 Flag'
                     CRIT5     =  'Analysis Criteria 5'
                     CRIT5FL   =  'Analysis Criteria 5 Flag'
                     CRIT6     =  'Analysis Criteria 6'
                     CRIT6FL   =  'Analysis Criteria 6 Flag'
                     ABLFL     =  'Analysis Baseline Flag'
                     PCHG      =  'Percentage Change From Baseline'  ;
run;


 %tu_attrib(
           dsetin          = ADTR1_6_,
           dsetout         = ADTR1_7_,
           dsplan          = /arenv/arprod/gsk2118436/brf117277/eos/adamdata/adtr1_spec.txt
          );


Proc sort data=ADTR1_7_ out=QC_ADTR1 (drop=/*TRLNKGRP*/); 
  By USUBJID AEVAL AREGION PARAMCD AVISITN ORGAN ADT METHOD LOCATION LSTATUS AVALC REASND ;
  *where subjid='31';
Run;

/* Final Compare ;
Proc compare base = ADAMData.ADTR1 compare= QCDATA.QC_ADTR1  listall ;
Run;
*/


libname arwork "/arenv/arwork/gsk2118436/brf117277/eos/adamdata" ;
/*
proc SQL;
  create table work.ADTR1_ADAM as
  select STUDYID, USUBJID, SUBJID, SITEID, RANDDT, AGE, AGEGRP, AGEGRPN, SEX, RACE, STAGE,
         ATSFL, ATSFN, COHORT, COHORTN, TRT01A, TRT01AN, TRT01P, TRT01PN, TRTSDT, TRTEDT, DTHDT,
         ECOGBL, VISGR1BL, VISDSBL, NEXBL, NINTRBL, NINNTRBL, GENCOV,
         AGECATBL, RACECAT, NANTYDT, NANTYFL,
         TSEXDIAG, TSIRDIAG,
         PARCAT1, PARCAT2, PARCAT3, AEVAL, AREGION length=12, PARAM, PARAMCD, ADT, ADY, AVISIT, AVISITN,
         AVAL, AVALC, CRIT1, CRIT1FL, CRIT2, CRIT2FL, CRIT3, CRIT3FL, CRIT4, CRIT4FL, CRIT5, CRIT5FL,
         CRIT6, CRIT6FL, ABLFL, BASE, BASETYPE, CHG, PCHG, LSTATUS, METHOD, ORGAN, LOCATION, LSTHICK,
         SCNINTU, RADSTDT, RADTYPCD, MELMALSP, CLSY, RDTYPE, REASND
  from adamdata.adtr1
  /*where PARAMCD not in("PDORG", "NRADPROG")  */
  /*order by USUBJID, AEVAL, AREGION, PARAMCD, AVISITN, ORGAN, ADT, METHOD, LOCATION, LSTATUS, AVALC, REASND
  ; 
quit;*/
 



proc sort data= /* arwork.adtr1vim*/   adamdata.adtr1 out=work.ADTR1_ADAM;
  By USUBJID AEVAL AREGION PARAMCD AVISITN ORGAN ADT METHOD LOCATION LSTATUS AVALC REASND ; 
run; 

Proc compare base = work.ADTR1_ADAM compare= QC_ADTR1  maxprint=(300,10000) listall ;
 Id USUBJID AEVAL AREGION PARAMCD AVISITN Organ ADT METHOD LOCATION LSTATUS AVALC REASND;
Run;

