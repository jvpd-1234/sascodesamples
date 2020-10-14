**part2
* PARAMCD = "SUMLD3" ;


libname sdtmdata "/folders/myfolders/pogram/sdtm";
libname adamdata "/folders/myfolders/define3";
*Table WORK.SUMLD_3A created, with 2739 rows and 14 columns.;

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
    , adt as odt
    , max(ADT) as ADT format=date9.
    , calculated ADT - TRTSDT + (calculated ADT >= TRTSDT) as ADY
    , AVISIT
    , AVISITN
    , sum(AVAL) as AVAL
  From adamdata.TRIND1 /*12788 and 30 vars*/ 
  Where PARCAT1 = "TARGET" and PARCAT2 = "LESIONS" and index(ORGAN,"LYMPH NODE") = 0 /*subsets to 6303*/ 
  Group by USUBJID, AEVAL, AREGION, AVISITN
  ;
Quit;

proc print;
where odt ne adt;
run;

PROC PRINT data=adamdata.trind1 ;
by USUBJId AEVAL AREGION AVISITN ;
WHERE usubjid = "BRF117277.000065" and  aeval="INVESTIGATOR" ;
RUN;


 

data vim_sumld_3a;
set adamdata.TRIND1;
by USUBJID AEVAL AREGION AVISITN;
 Where PARCAT1 = "TARGET" and PARCAT2 = "LESIONS" and index(ORGAN,"LYMPH NODE") = 0 ;
run;

data want;
set vim_sumld_3a;
by USUBJID AEVAL AREGION AVISITN;
*keep across rows;
retain madt;

*if first of each Sex group;
if first.aregion then madt=adt;
*other records;
else madt = max(adt, madt);

*if last of grup;
if last.aregion then output;

*keep only relevant variables;
*keep sex age;
run;


proc freq data=want;
tables USUBJID*AEVAL*AREGION*AVISITN*madt /list nocol nocum nopercent norow  missing;
format madt date9.; 

where usubjid in ("BRF117277.000031") ;
run;
 
 
proc freq data=sumld_3a;
tables USUBJID*AEVAL*AREGION*AVISITN*adt /list nocol nocum nopercent norow  missing;
format adt date9.; 
where usubjid in ("BRF117277.000031" );
run;
 
  
proc freq data= adamdata.TRIND1;
tables USUBJID*AEVAL*AREGION*AVISITN*adt /list nocol nocum nopercent norow  missing;
format adt date9.; 
where usubjid in ("BRF117277.000031" );
run;


 
 
%MACRO FRET  (DIN,INP,wh,tin);

proc freq data=&DIN;
tables &inp /list nocol nocum nopercent norow  missing;
&wh ;
&tin ;
run;
title"";
%MEND;

 

DATA work.TR_IND_1;
SET adamdata.TRIND1 ;
RUN;


* Table WORK.SUMLD3_MISS_A created, with 2789 rows and 12 columns. 
dates are set to missing;
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
    , . as ADT  /* SET TO MISSING*/ 
    , . as ADY  /* SET TO MISSING*/ 
    , AVISIT
    , AVISITN
    , . as AVAL  /* SET TO MISSING*/ 
  From work.TR_IND_1
  Where PARCAT1 = "TARGET" and PARCAT2 = "LESIONS"
  Order by USUBJID, AEVAL, AREGION, AVISITN
  ;
Quit;

*Table WORK.SUMLD3_MISS_DATES created, with 2789 rows and 6 columns.;

Proc SQL;
  Create table work.SUMLD3_miss_dates as
  Select distinct
      USUBJID
    , AEVAL
    , AREGION
    , AVISITN
    , max(ADT) as ADT2 format=date9. /** take max date*/
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
  ADT = coalesce(ADT,ADT2);   /** take max date and coalesce with missing dates*/
  *COALESCE ;
  *Returns the first non-missing value from a list of numeric arguments.;
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
        work.BaseFlag_SUMLD3 /* first create and merge flag*/
        ;
  By USUBJID AEVAL AREGION AVISITN PARAMCD ;
Run;

proc sort data= work.SUMLD_3d;
  By USUBJID AEVAL AREGION PARAMCD ;
Run;

Data work.SUMLD_3e; /*for 3f*/
  Merge work.SUMLD_3d
        work.BaseVal_SUMLD3 /* then merge value*/
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

