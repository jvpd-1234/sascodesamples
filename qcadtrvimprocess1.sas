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
  oval=aval;
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


DATA TR32;
SET sdtmdata.tr;
where usubjid="BRF117277.000032" and TRSTRESN ne .   and TRSCAT="BRAIN" and treVAL ^= "INVESTIGATOR" 
 AND TRGRPID ="TARGET" and TRTESTCD="LDIAM" ;
 RUN;
 
 DATA TR32A;
 SET TR32;
 by  usubjid  VISITNUM;
 RETAIN CUM3 ; 
  
  IF FIRST.VISITNUM THEN CUM3=TRSTRESN ;
  ELSE CUM3= CUM3 + TRSTRESN ;* cum3  + CUM2  ;

 
proc print data=TR32A;
where usubjid="BRF117277.000032" and TRSTRESN ne .   and TRSCAT="BRAIN" and treVAL ^= "INVESTIGATOR" 
 AND TRGRPID ="TARGET" and TRTESTCD="LDIAM" ;
vAR    USUBJID    TRSEQ  TRGRPID TRLNKID TRLNKGRP    
TRTESTCD    TRTEST  TRCAT   TRSCAT  TRORRES    TRBLFL  TREVAL     
 TRACPTFL    VISITNUM  CUM3 TRSTRESN  VISIT   EPOCH   TRDTC   TRDY
  ;
   title "subj 32 raw data" ;
run;
 

proc print data=sdtmdata.tr;
where usubjid="BRF117277.000065" and TRSCAT="EXTRACRANIAL"/** and treVAL ^= "INVESTIGATOR" */
 AND TRGRPID ="TARGET" and TRTESTCD="LDIAM" ;
VAR  USUBJID    TRSEQ   TRGRPID TRLNKID TRLNKGRP    
TRTESTCD    TRTEST  TRCAT   TRSCAT  TRORRES   ;
   title "subj 65 raw data" ;
run;
 


