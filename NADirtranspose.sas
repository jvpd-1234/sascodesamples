data new8;
  set adamdata.SUMLDlagnad;
  oval=aval;
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
  
 if  usubjid="BRF117277.000065" and TRG_RECS ne Trg_Recs_Base and ^missing(AVAL) then  
put "**just to se pevbSE AND PREVAVAL" aregion=""  TRG_RECS "ne" Trg_Recs_Base adt= base= aval=  ti= prevbase= prevaval=;
 *
 put "**" aregion=""  TRG_RECS "ne" Trg_Recs_Base adt= base= aval=  ti= prevbase= prevaval=;
 CM=nmiss(prevBASE, prevAVAL);
  If nmiss(prevBASE, prevAVAL)<2 then BASE = min(prevBASE, prevAVAL);
  ** base must be minimum of the prevbase and prevaval if either of them is missing or else base=aval  ; 
  
 if  usubjid="BRF117277.000065" and TRG_RECS ne Trg_Recs_Base and ^missing(AVAL) then  
put "** faterf nmiss fofr base" aregion=""  TRG_RECS "ne" Trg_Recs_Base CM= adt= base= aval=  ti= prevbase= prevaval=;
 FCHG=nmiss( BASE,  AVAL);
  BASETYPE = "Smallest non-missing SLD prior to current visit";
  If nmiss(AVAL,BASE) = 0 and  AVISITN > 10 then CHG = AVAL - BASE;
  If not missing(CHG) and BASE not in (0,.) then PCHG = CHG/BASE*100;
  
 if  usubjid="BRF117277.000065" and TRG_RECS ne Trg_Recs_Base and ^missing(AVAL) then  
put "**" aregion=""  TRG_RECS "ne" Trg_Recs_Base FCHG= CM=  adt= base= aval=  ti= prevbase= prevaval=;
  If not missing(AVAL) then prevBASE = BASE;
  If not missing(AVAL) then prevAVAL = AVAL;
  if prevaval ne aval then avne=1;
   if  usubjid="BRF117277.000065" and TRG_RECS ne Trg_Recs_Base and ^missing(AVAL) then  
put "** faterf nmiss fofr base" aregion=""  TRG_RECS "ne" Trg_Recs_Base adt= base= aval=  ti= prevbase= prevaval=;
Run;

proc print;
where usubjid="BRF117277.000065" ;
By USUBJID AEVAL AREGION;
var AVISIT  AVISITN AVAL   Trg_Recs    Trg_Recs_Base   ABLFL   oval    
BASE    prevBASE    prevAVAL aval avne   ti  CM  FCHG       CHG PCHG;
run;


proc print;
where usubjid="BRF117277.000032" ;
By USUBJID AEVAL AREGION;
var AVISIT  AVISITN AVAL   Trg_Recs    Trg_Recs_Base   ABLFL   oval    
 BASE    prevBASE    prevAVAL aval avne   ti  CM  FCHG       CHG PCHG;
run;

   