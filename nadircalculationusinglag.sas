/*Lowest SLD recorded up-till (before) the current visit. â This value may (or may not) change at every visit. 
Nadir would be the lowest record (SLD value) during subjectsâ visits. Here, the lowest SLD recorded 
(during all visits) before current visit, since Baseline would be considered the value for Nadir. 
Nadir is a very important
 parameter for Target Response evaluations. For deriving Nadir Subjectâs SLD at every visit is
 programmatically compared with the SLD at previous visit (refer table1) and lower value between 
 them is selected and subsequently used in the next visit as Nadir.
One of the ways to do this is by first making sure that the records are sorted in the order of 
Baseline visit and then the rest of the visits. Now, using retain statement, lag statement, and 
logical conditions - Nadir is assigned as equal to SLD if visit is Baseline, or 
temporary variables are created to check the lower value of SLD and then assign the Nadir. See below code for an example.
*/


Data adamdata.SUMLDlagnad work.SUMLDlagnad ; *(drop= TRG_RECS Trg_Recs_Base);
  Merge work.SUMLD_2d
        work.BaseFlag_SUMLD2;
  By USUBJID AEVAL AREGION AVISITN PARAMCD ;
  run;
  

* Creating temporary test variable for ordering Nadir ; 
data resp5;
 set SUMLDlagnad ; /*For Baseline Visits - assign test as 0*/
 If ABLFL = "Y" then test = 0 ; 
 else test = 1 ; ** EVERYTHING ELSE EXCEPT BASELINE IS ZERO;
 run;

* Re-sorting data to calculate Nadir ;
 proc sort data = resp5 ; 
 by USUBJID AEVAL AREGION  avisitn test   ; *SORT ORDER IS KEY HERE;
 run;

* Computing temporary Nad_1 and Nad_2 variables ; 
data resp6 ; 
set resp5 ; 
by  USUBJID AEVAL AREGION avisitn   test  ; 
retain Nad_1 Nad_2 BASEV NAD_1; **NAD_1 BASLINE VALUE , NAD2 IS LAG OF NAD_1 RETAINED****; 
If   ABLFL = "Y" then do;
basev=aval;
Nad_1 = basev;
end;

if  usubjid="BRF117277.000032" and  aEVAL = "INDEPENDENT ASSESSOR"  and AREGION="INTRACRANIAL" 
then put  USUBJID= AVISITN= PARAMCD= adt=  oval= aval=  Nad_1=   Nad_2=   basev=  ; 
If ABLFL ^= "Y" then do ;* For records where visit is other than Baseline ; 
If (aval < basev) and (Nad_1 > aval) then nad_1 = aval ; 
*IF CURRENT AVAL IS LESS THAN BASE VALUE AND BASE VALUE GT THAN AVAL
THEN NAD1 IS SET TO AVAL OR ELSE WE KEEP CONTINUING THE LOWER ONE;
end ; **************************************; 
If   first.avisitn    AND AVAL > . then do ; 
Nad_2 = lag(Nad_1) ; ** IT IS DONE BY UNIQUE SEQUENCE OF VISIT AND TEST;
end ;

If TRG_RECS ne Trg_Recs_Base and ^missing(AVAL) then do; *, prevBASE)=0 then do;
    If  . < AVAL < = 1.2* min(NAD_1,NAD_2) then call missing(AVAL);
    timissfl=1;
    timissc="aval is <=1.2 *min of prevbase and prevaval" ;
    nadir=. ;
  End;   
if  usubjid="BRF117277.000032" and  aEVAL = "INDEPENDENT ASSESSOR"  and AREGION="INTRACRANIAL" 
then put  USUBJID= AVISITN= PARAMCD= adt=  oval= aval=  timissc Nad_1=   Nad_2=   basev=  ; 

If   ABLFL = "Y" then do;
basev=aval;
Nad_1 = basev;
end;

If   first.avisitn    AND AVAL > . then do ; 
Nad_2 = lag(Nad_1) ; ** IT IS DONE BY UNIQUE SEQUENCE OF VISIT AND TEST;
end ;

if  usubjid="BRF117277.000032" and  aEVAL = "INDEPENDENT ASSESSOR"  and AREGION="INTRACRANIAL" 
then put "********"  USUBJID= AVISITN= PARAMCD= adt=  oval= aval=  timissc Nad_1=   Nad_2=   basev=  ; 

run ;

proc print ;
WHERE usubjid = "BRF117277.000032"  ;
TITLE " CHECK TO SEE AVAL=. AND NOT NE ." ;
RUN;

* Computing final Nadir based on temp {Nad_1 and Nad_2} variables ;

data resp7 ; 
set resp6 ; 
by  USUBJID AEVAL AREGION avisitn   test  ; 
If ABLFL = "Y"   then Nadir = . ; 
If ABLFL ^= "Y"  then do ; /*To assign Nad_2 as final Nadir for visits other than Baseline*/ 
If  test=1 then Nadir = Nad_2 ;
else Nadir = . ; 
end ;
run;

data resp7 ; 
set resp7 ; 
oval=aval;
run;

DATA RESP8;
SET RESP7;
  By USUBJID AEVAL AREGION AVISITN PARAMCD ;** HERE THE FIRST.REGION LEVEL BASE,PREVABSE IS SET;
 retain BASE prevBASE prevAVAL;
** set to missing;
  If first.AREGION then call missing(BASE, prevBASE, prevAVAL);
   If ABLFL = "Y" then BASE  = AVAL; ** set base to aval or whole equation is belly up;
if  usubjid="BRF117277.000031" /*and  aEVAL = "INVESTIGATOR"  and AREGION="EXTRACRANIAL" */
then put  USUBJID= AVISITN= PARAMCD= adt= base= prevbase= prevaval=; 
  ** baseline flag if blfl ; 
  **check if aval is less than 1.2 min of prevbase and prevaal if so assign missing;
   ti=1.2* min(prevBASE,prevAVAL) ;
   timin=min(prevbase,prevaval) ;
  If TRG_RECS ne Trg_Recs_Base and ^missing(AVAL) then do; *, prevBASE)=0 then do;
    If prevbase > . and prevaval > . and . < AVAL < = 1.2* min(prevBASE,prevAVAL) then call missing(AVAL);
    timissfl=1;
    timissc="aval is <=1.2 *min of prevbase and prevaval" ;
    nadir=. ;
  End;       
  If nmiss(prevBASE, prevAVAL)<2 then BASE = min(prevBASE, prevAVAL);

  BASETYPE = "Smallest non-missing SLD prior to current visit";
  If nmiss(AVAL,NADIR) = 0 and  AVISITN > 10  AND AVAL > . then CHG = AVAL - NADIR;
  If not missing(CHG) and NADIR not in (0,.)  AND AVAL > . then PCHG = CHG/NADIR*100;

If not missing(AVAL) then prevBASE = BASE;
If not missing(AVAL) then prevAVAL = AVAL;
 
 *drop test Nad_1 Nad_2 ;
 run ;
 
 proc sort;
 by  USUBJID AEVAL AREGION avisitn  ;
 run;
 
proc print ;
WHERE usubjid = "BRF117277.000032"  ;* and PARCAT1 = "TARGET" and PARCAT2 = "LESIONS";
var  USUBJID PARAMcd  TRG_RECS  Trg_Recs_Base    ADT   AVISIT  AVISITN oval AVAL ABLFL 
  timissc ti timin  test  oval aval  Nad_1   Nad_2   basev  
 Nadir  BASE    prevBASE    prevAVAL   CHG PCHG; 
 *ABLFL  nad: ;
 title "subj 31 cum after processing baseline and setting values for missing in our dataset" ;
run;

proc print ;
WHERE   timissfl=1; ;* and PARCAT1 = "TARGET" and PARCAT2 = "LESIONS";
var  USUBJID PARAMcd  TRG_RECS  Trg_Recs_Base    ADT   AVISIT  AVISITN oval AVAL ABLFL 
  timissc ti timin  test  oval aval  Nad_1   Nad_2   basev  
 Nadir  BASE    prevBASE    prevAVAL  CHG PCHG; 
 *ABLFL  nad: ;
 title "all people who had a missing postbaseline record
 processing baseline and setting values for missing in our dataset" ;
run;


proc print data=SUMLD_2e;
where usubjid="BRF117277.000032"   
and ^missing(AVAL) ;*and    aEVAL = "INVESTIGATOR"  and AREGION="EXTRACRANIAL";
var USUBJID PARAMcd   ADT  AVISIT  AVISITN   oval AVAL   ABLFL    BASE    prevBASE    prevAVAL        CHG PCHG;
  title "subj 31 cum after processing baseline and setting values for missing in original" ;
run;


DATA CHK;
MERGE SUMLD_2E RESP8 (RENAME=(CHG=CHGL PCHG=PCHGL) KEEP=USUBJID AEVAL AREGION 
avisitn oval PCHG CHG TEST Nad_1   Nad_2   BASEV   Nadir  );
by  USUBJID AEVAL AREGION avisitn ;
RUN;
 
 DATA CHK2;;
 SET CHK; 
 IF AVAL=. THEN DO;
 PCHGL=.;
 CHGL=.;
 END;
 IF CHG^=CHGL OR PCHG^=PCHGL THEN FLAG=1;
 RUN;
 
 proc sort;
 by  usubjid  AEVAL  AREGION;
 run;
 
 PROC PRINT;
 WHERE   usubjid="BRF117277.000032" and  AEVAL ="INDEPENDENT ASSESSOR" and AREGION="INTRACRANIAL" ;
 by usubjid  AEVAL  AREGION;
 TITLE "CHECK INDIVIDUAL SUBJECT" ;
 VAR USUBJID    AEVAL  AREGION PARAMCD ADT  AVISITN    Trg_Recs    Trg_Recs_Base   ABLFL  AVAL oval   BASE  
 prevBASE    prevAVAL    ti    FLAG CHG PCHG    CHGL    PCHGL  test  AVAL oval  Nad_1   Nad_2   BASEV   Nadir  ;
 RUN;
 
 PROC PRINT;
 TITLE "CHECK ALL NON MATCH";
 WHERE CHG^=CHGL OR PCHG^=PCHGL ;
 by usubjid  AEVAL  AREGION;
 VAR PARAMCD ADT  AVISITN AVAL  Trg_Recs    Trg_Recs_Base   ABLFL   BASE  
 prevBASE    prevAVAL    ti       CHG PCHG    test    Nad_1   Nad_2   BASEV   Nadir   CHGL    PCHGL ;
 RUN;
 