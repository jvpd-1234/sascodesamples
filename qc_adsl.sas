/******************************************************************************* 
|
| Program Name:    
|
| Program Version: 
|
| MDP/Protocol ID: 
|
| Program Purpose: 
|
| SAS Version:     
|
| Created By:      Chilukuri, Shalini  (HOSTING01\chiluksh)
| Date:            21-Sep-2016
|
|******************************************************************************* 
|
| Output: 
|
|
|
| Nested Macros: 
|
|
|
|******************************************************************************* 
| Change Log 
|
| Modified By: 
| Date of Modification: 
|
| Modification ID: 
| Reason For Modification: 
|
********************************************************************************/ 


%include "/arenv/arwork/gsk2118436/brf117277/eos/qc/qc_setup.sas";

libname prod "/arenv/arprod/gsk2118436/brf117277/eos/adamdata";
 proc format ; 

value $mon
'01'='JAN' 
'02'='FEB' 
'03'='MAR'
'04'='APR'
'05'='MAY'
'06'='JUN'
'07'='JUL'
'08'='AUG'
'09'='SEP'
'10'='OCT'
'11'='NOV'
'12'='DEC'
;
run;

***********Calling sdtm data information*****************;

proc sort data=sdtmdata.dm out=dm;
    by usubjid;
run ;

proc sort data=sdtmdata.suppdm out=suppdm;
    by usubjid;
run ;

proc transpose data=suppdm out=dm_r(drop=_name_ _label_);
    by usubjid;
    id qnam;
    var qval;
run;

*******Disposition dataset;

proc sort data=sdtmdata.suppds out=suppds(where=(Qnam in( "RANDNUM" "STRATUM")));
    by usubjid;
run ;

proc transpose data=suppds out=ds_r(drop=_name_ _label_);
    by usubjid;
    id qnam;
    var qval;
run;

 data ds_rand(keep= usubjid randdt) ;
    set sdtmdata.ds(where=(dsterm="RANDOMISED"));
    by usubjid;
    randdt=input(dsstdtc,yymmdd10.);
    format randdt  date9.;
 run;

*****exposure dataset trtsdt ;

    data ex_stdt ;
     set sdtmdata.ex (where=( exstdtc ne ' ' ));
       by usubjid ;
 
        trtsdt=input(exstdtc,yymmdd10.);

               proc sort ;
               by usubjid trtsdt;

                   data exstdt_ (keep=usubjid exstdtc trtsdt);
                   set ex_stdt;
                       by usubjid trtsdt;
                       if first.usubjid;
                       format trtsdt date9.;
               run;

 proc sort data=sdtmdata.ex out=ex_subj nodupkey;
    by usubjid ;
 run;

*%let cutdt='28-11-2016';


*****exposure dataset trtedt ;

      data ex_endt(keep=usubjid exstdtc cutoffdt trtedt_ startdt ) ;
       set sdtmdata.ex (where=( EXTPT ne "DAY OF PK")) /*(where=(exendtc ne '' ))*/;
       by usubjid ;
      * cutdt="2016-11-28" ;
       cutoffdt=input("&g_datadate",date9.) ;
       
          startdt=input(exstdtc,yymmdd10.);
          trtedt_=input(exendtc,yymmdd10.); 

        format cutoffdt startdt trtedt_ date9.;
 
               proc sort ;
               by usubjid startdt trtedt_ ;

                   data exendt_ ;
                   set ex_endt;
                       by usubjid startdt trtedt_;
                      if last.usubjid;
                       format trtedt_ date9.;
     run;



****************maximun date of trtsdt********************;

        proc summary data=ex_stdt nway;
          class  usubjid;
          var trtsdt;
          where ((exdose gt 0) and n(trtsdt));
          output out=exp1(drop=_type_ _freq_)
                 min=firstdt
                 max=lastst;
        run;


%tu_adsuppjoin(dsetin=sdtmdata.ds,
                    dsetinsupp=sdtmdata.suppds,
                    dsetout=ds_supp
                    );
data ds;
 set ds_supp ;
    DSSTDT=input(DSSTDTC,yymmdd10.);
    where visitnum eq 1000 and SDIP ne ' ' and DSSTDTC ne ' ' ;
    format DSSTDT date9.;
 run;
proc sort data=ds out=ds_ipdisc  ;
 by usubjid DSSTDT;
run;

 data ds_ipdisc(keep=usubjid);
   set ds_ipdisc;
    by usubjid DSSTDT;
    if last.usubjid;
 run;


        data exp/*(drop=lastst lastend)*/;
          merge exp1
                exendt_ ds_ipdisc(in=ipdisc);
          by usubjid;

         *cutdt="2016-11-28" ;
         cutoffdt=input("&g_datadate",date9.);

          trtedt=max(trtedt_,lastst);
          if ((firstdt eq trtedt) OR (lastst-firstdt)=1 OR (lastst-firstdt)=0) and (TRTEDT EQ .) then trtedt=.;
            
           if trtedt eq . and not(ipdisc) then  trtedt=cutoffdt;
           trtsdt=firstdt;

          format firstdt lastst trtedt cutoffdt date9.;
          diff=trtedt-firstdt;
        run;



data dm1;
length agegrp $25.;
merge dm(in=a) dm_r ds_r ds_rand ex_subj(in=b) exstdt_ ;*/ exendt_ exstdt_ /*trtedt /*vs_r1*/;
by usubjid;
if a ;

 BRTHDT=input(BRTHDTC,4.); 
*format BRTHDT year4.;

 *********Age;

if . < age < 18 then do; agegrp="< 18";agegrpn=1; end;
if  18 =< age =< 64 then do; agegrp="18-64"; agegrpn=2; end;
else if  65 =< age =<74 then do; agegrp="65-74"; agegrpn=3; end;
if age > 74 then do; agegrp=">74 "; agegrpn=4; end;


       if SEX eq "F" then SEXN=2  ;
       else if  SEX eq "M" then SEXN=1; 

        if ETHNIC eq "HISPANIC OR LATINO" then ETHNICN=1  ; 
         else if  ETHNIC eq "NOT HISPANIC OR LATINO" then ETHNICN=2; 

       race1=raceor1;

       /*cohort=stratum;*/
       cohortcd=substr(stratum,7,1);

          if cohortcd eq "A" then do; cohortn= 1 ; cohort="Cohort A"; end; 
            else if cohortcd eq "B" then do; cohortn=2; cohort="Cohort B"; end; 
             else if  cohortcd eq "C" then do; cohortn=3 ; cohort="Cohort C"; end; 
              else if cohortcd  eq "D" then do;  cohortn =4; cohort="Cohort D"; end; 

     ************* Treatment variables;

      if arm not in (' ' "Not Assigned") then  trt01p="Dabrafenib + Trametinib";
       if trt01p="Dabrafenib + Trametinib" then trt01pn=1;

      if actarm not in (' ' "Not Assigned") then  trt01a="Dabrafenib + Trametinib"; 
       if trt01a="Dabrafenib + Trametinib" then trt01an=1;

     ***********************Flagging varibales;

            *Randomised flag;
         if randnum ne ' ' then  do;
             randfl='Y' ;
             randfn=1; end;
         else do;
             randfl ='N';
             randfn=0;
         end;
    
            *All treated subjects;
        if a and b  then do;
            ATSFL='Y';Saffl="Y";
            ATSFN=1;
            end;
        else if a and not b  then do;
              ATSFL='N';saffl='N';
              ATSFN=0;
              end;

            *All subjects flag;

        if a  then do;
            ALLFL='Y';
            ALLFN=1;
            end;
        else do;
              ALLFL='N';
              ALLFN=0;
              end;

             *trtsdt=input(exstdtc,yymmdd10.);
             *trtedt=input(exendtc,yymmdd10.);
             dthdt=input(dthdtc,yymmdd10.);
             if trtsdt ne . and dthdt ne . then dthdy=dthdt-trtsdt+1;

         run;



**************Baseline heightbl and weightbl derivation***************;

data vs9 ;
merge sdtmdata.vs(where=(vstestcd in ('HEIGHT' 'WEIGHT'))) dm1(keep= usubjid trtsdt);
by usubjid;
    vsdt_=input(vsdtc,yymmdd10.);
        format vsdt_ date9.;
if (vsdt_ =< trtsdt or . < visitnum < 20 ) ;
run;

proc sort data=vs9 out=vs9_;
by usubjid vstestcd  vsdt_;

data vs1_;
set vs9_;
by usubjid vstestcd vsdt_;
if last.vstestcd and vstestcd ne ' ';
run;


proc transpose data=vs1_ out=vs1_t;
by usubjid;
id vstestcd ;
var vsorres;
run;


*********values For height weight and bmi at baseline *********;

data vs1(keep=usubjid heightbl weightbl bmibl);
set vs1_t ;
 bmibl=weight/(height/100)**2;
heightbl=input(height,5.);
 weightbl=input(weight,5.);
   format bmibl 6.2;
run;


****************For deriving status********************;

proc sort data=sdtmdata.dd out=dd nodupkey;
    by usubjid;
run;

proc sort data =sdtmdata.ex out=ex(keep=usubjid)   nodupkey;
 by usubjid;
 run;

data dm_stat ;
length /*trtstat eosreas*/ status $100.;
merge dm1(in=a keep=usubjid randnum dthfl in=a) sdtmdata.ds(in=b) dd(in=c) ex(in=d) ;
by usubjid;

if  /*a and c*/ dthfl eq "Y" then do;statusn=0; status="Died"; end;
 else if a and b /*and d*/ then do;
         if UPCASE(dsscat)eq "STUDY CONCLUSION" and DSTERM ne "COMPLETED"  then do;statusn=1;status="Withdrawn from study";end;
         else if upcase(dsscat)eq "STUDY TREATMENT DISCONTINUATION" and DSSTDTC ne ' '/*and DSTERM ne "COMPLETED"*/ then do;statusn=2;status="Ongoing, In follow-up"; end;
         else if d and randnum ne ''   then do; statusn=3;status ="Ongoing, On study treatment"; end;
   end;
  else if randnum eq " " then do; statusn=3;status="Not randomised";end;
  
/*
if a and b  then do;
 if a and not c then do;
      if upcase(dsscat)eq "STUDY TREATMENT DISCONTINUATION" and dsterm ne "COMPLETED" then trtstat="Discontinued";
     else trtstat="Ongoing";

    end;
 end;*/

     date_con=input(dsstdtc,yymmdd10.);
if status ne '';
  run;

proc sort data=dm_stat ;
    by usubjid statusn ;
run;

*********************Study treatment discontinuation date missing*************************;

proc sort data=dm_stat ;
    by usubjid statusn ;
run;

data dm_stat(keep=usubjid status) ;
    set dm_stat;
    by usubjid statusn;
    if first.usubjid;
run;

********************end of study reason;

proc sort data =sdtmdata.ds out=ds_reas ;
 by usubjid  dsseq;
run;

proc sort data =sdtmdata.suppds out=suppds_sdip ;
    by usubjid  idvarval;
    where QNAM eq "SDIP";

    proc transpose data=suppds_sdip out=suppds_sdip_t ;
     by usubjid idvarval;
     id qnam;
     var QVAL ;
     run;
     
 data suppds_sdip (keep=usubjid dsseq sdip);
   set suppds_sdip_t;
    by usubjid ;
    dsseq=input(idvarval,5.);
run;

    data deosreas(keep=usubjid dsscat dsterm dsdecod deosreas sdip)
         teosreas(keep=usubjid dsscat dsterm dsdecod teosreas sdip);
    merge  ds_reas suppds_sdip;
    by usubjid dsseq;
    
            if SDIP eq "GSK2118436" then do;
                  if DSSCAT ="STUDY TREATMENT DISCONTINUATION" and dsdecod ne "COMPLETED" and DSSTDTC ne ' ' then deosreas=dsdecod;
                     else if DSSCAT ="STUDY TREATMENT DISCONTINUATION" and dsdecod eq "COMPLETED" and DSSTDTC ne ' ' then deosreas=dsterm;
            end;


            if SDIP eq "GSK1120212" then do;
                  if DSSCAT ="STUDY TREATMENT DISCONTINUATION" and dsdecod ne "COMPLETED" and DSSTDTC ne ' '  then teosreas=dsdecod;
                     else if DSSCAT ="STUDY TREATMENT DISCONTINUATION" and dsdecod eq "COMPLETED" and DSSTDTC ne ' ' then teosreas=dsterm;
            end;

    if deosreas ne ' ' then output deosreas;
    if  teosreas ne ' ' then output teosreas;
    run;

    /*data ds_reas;
     set ds_reas;
      by usubjid  ;
       if last.usubjid;
    run;*/

    data _reas1(keep=usubjid subreas);
    set sdtmdata.ds;
    by usubjid;
    if upcase(DSDECOD) in ( "WITHDRAWAL BY SUBJECT" "PHYSICIAN DECISION") then subreas=dsterm;
    if subreas ne ' ' ;
            
    proc sort  ;
         by usubjid ;
     run;

     data  _reas1;
       set _reas1;
        by usubjid ;
        if last.usubjid; 

    run;


 data ds; 
 merge sdtmdata.ds(in=a) ex(in=b) sdtmdata.dm(in=c keep=usubjid dthfl in=c) ;
  by usubjid;
  *if dthfl eq "Y" then  trtstat ="Discontinued";

     if a and b  then do;
        if DSSCAT ="STUDY TREATMENT DISCONTINUATION" and dsterm NE "COMPLETED"  and DSSTDTC ne ' ' then do; 
        trtstat ="Discontinued"; 
       * eosreas=dsdecod; end;
          else do ;trtstat= "Ongoing"; end;
        end;

         else if (a and not b ) or  (c and not b) then do;
             trtstat="Not Treated";

         end;
run;

*****************death reason;

  proc sort data=sdtmdata.dd out=dthreas(keep= usubjid ddorres rename=(ddorres=DEATHRS));
   by usubjid  ;
    where /*ddtestcd eq "DTHUCAUS" and */ddcat eq "PRIMARY CAUSE OF DEATH";
   run;



proc sort data=ds;
    by usubjid trtstat;
run;

data ds_trtstat(keep=usubjid trtstat);
    set ds;
     by usubjid trtstat;
        if first.usubjid;
run;

data dm_fin;
merge dm1(in=a) dm_stat(in=b) ds_trtstat deosreas/*ds_reas*/teosreas _reas1 vs1 dthreas;
by usubjid;
if a ;
run;

proc sort data=sdtmdata.sv out=sv_stdtc;
  by usubjid visitnum;
 run;

*******************macro for getting last contact date**********************;

%macro lcontdt(dsname=,indsname=,cond=,cond1=,dt=,dt1=);
data &dsname( keep=usubjid &dt1 cutoffdt);
set &indsname(&cond);
by usubjid ;
if length(&dt) >=9 then &dt1=input(&dt,yymmdd10.);
       *cutdt="2016-11-28" ;
       cutoffdt=input("&g_datadate",date9.);

if &dt1 > cutoffdt then &dt1=.;
format &dt1 date9.;

proc sort ;
by usubjid &dt1;

data &dsname;
set &dsname(&cond1);
by usubjid;
if last.usubjid;
run;

%mend;




%lcontdt(dsname=ss,indsname=sdtmdata.ss,cond=where=(visitnum=7000),cond1=,dt=ssdtc,dt1=ssdtc_);
%lcontdt(dsname=ae_s,indsname=sdtmdata.ae,cond= ,cond1=,dt=aestdtc,dt1=aestdtc_);
%lcontdt(dsname=ae_e,indsname=sdtmdata.ae,cond= ,cond1=,dt=aeendtc,dt1=aeendtc_);

%lcontdt(dsname=cm_s,indsname=sdtmdata.cm,cond= ,cond1=,dt=cmstdtc,dt1=cmstdtc_);
%lcontdt(dsname=cm_e,indsname=sdtmdata.cm,cond= ,cond1=,dt=cmendtc,dt1=cmendtc_);

%lcontdt(dsname=tr,indsname=sdtmdata.TR,cond= ,cond1=,dt=trdtc,dt1=trdtc_);

%lcontdt(dsname=ex_s,indsname=sdtmdata.ex,cond= ,cond1= ,dt=exstdtc,dt1=exstdtc_);
%lcontdt(dsname=ex_e,indsname=sdtmdata.ex,cond= ,cond1=, dt=exendtc,dt1=exendtc_);

%lcontdt(dsname=pr_s,indsname=sdtmdata.pr,cond= ,cond1=,dt=prstdtc,dt1=prstdtc_);
%lcontdt(dsname=pr_e,indsname=sdtmdata.pr,cond= ,cond1=,dt=prendtc,dt1=prendtc_);


%lcontdt(dsname=lb_d,indsname=sdtmdata.lb,cond=where=(lbtestcd ne 'BRAF') ,cond1=,dt=lbdtc,dt1=lbdtc_);

/*
data lb_d(keep=usubjid lbdtc_ cutoffdt);
set sdtmdata.lb(where=(lbtestcd ne 'BRAF'));
by usubjid ;
if length(lbdtc) >=9 then lbdtc_=input(lbdtc,yymmdd10.);
       cutdt="2016-11-28" ;
       cutoffdt=input(cutdt,yymmdd10.);

if lbdtc_ =< cutoffdt ;
format lbdtc_ date9.;

proc sort ;
by usubjid lbdtc_;

data lb_d;
set lb_d;
by usubjid;
if last.usubjid;
run;*/


%lcontdt(dsname=vs,indsname=sdtmdata.vs,cond= ,cond1=,dt=vsdtc,dt1=vsdtc_);

%lcontdt(dsname=Qs,indsname=sdtmdata.Qs,cond= ,cond1=,dt=Qsdtc,dt1=Qsdtc_);
*%lcontdt(dsname=xi,indsname=sdtmdata.xi,cond= ,dt=xidtc,dt1=xidtc_);

%lcontdt(dsname=eg,indsname=sdtmdata.eg,cond= ,cond1=,dt=egdtc,dt1=egdtc_);
%lcontdt(dsname=rs,indsname=sdtmdata.rs,cond=where=(rstestcd eq "NRADPROG") ,cond1=,dt=rsdtc,dt1=rsdtc_);


%lcontdt(dsname=SV_s,indsname=sdtmdata.SV,cond=,cond1=,dt=SVENDTC,dt1=svendtc_);
%lcontdt(dsname=SV_e,indsname=sdtmdata.SV,cond=,cond1=,dt=SVSTDTC,dt1=svstdtc_);


%lcontdt(dsname=rs_,indsname=sdtmdata.rs,cond=where=(rseval eq "INDEPENDENT ASSESSOR" and rsevalid='NEUROLOGIST' and rstestcd eq 'OVRLRESP' and rsstresc='PD') ,cond1=,dt=rsdtc,dt1=rsdtc1_);


data ltcondt;
merge dm_fin (in=a) ss ae_s ae_e tr cm_s cm_e ex_s ex_e pr_s pr_e lb_d vs qs eg rs rs_ sv_s sv_e  ;
by usubjid;
if a;
lstctdt=max( ssdtc_,aestdtc_,aeendtc_,cmstdtc_,cmendtc_,trdtc_,exstdtc_,exendtc_,prstdtc_,prendtc_,lbdtc_,
               vsdtc_, Qsdtc_,egdtc_,rsdtc_,rsdtc1_,randdt,svendtc_,svstdtc_,randdt);



       /*cutdt="2016-11-28" ;
       cutoffdt=input(cutdt,yymmdd10.);
      if LSTCTDT > cutoffdt  then LSTCTDT=cutoffdt;*/

               format lstctdt date9.;
/*if day(lcontdt+1)>= day(randdt) then Duration=((year(lcontdt+1)-year(randdt))*12 + (month(lcontdt+1)-month(randdt)-1))+1;
else Duration=(year(lcontdt+1)-year(randdt))*12 + (month(lcontdt+1)-month(randdt)-1);*/

run; 

proc sort data= sdtmdata.sv out=svdtc;
 by usubjid visitnum;
 run;


data sv_stdtc ; 
  set sv_stdtc;
  by usubjid visitnum;
  if first.usubjid;
   FSTCTDT=input(svstdtc,yymmdd10.);
  keep usubjid FSTCTDT;
  run;
/*
proc sort data=sdtmdata.sv out=sv_endtc;
  by usubjid visitnum;
 run;

data sv_endtc; 
  set sv_endtc;
  by usubjid visitnum;
  if last.usubjid;
  lstctdt=input(svendtc,yymmdd10.);
  keep usubjid lstctdt;
  run;
*/

*********************ECOG STATUS****************;


data ecog;
  merge sdtmdata.qs ltcondt(keep=usubjid trtsdt) ;
   by usubjid;
  qsdtc_=input(qsdtc,yymmdd10.);
   format qsdtc_ date9.;
    
    if trtsdt>=qsdtc_;

    proc sort ;
     by usubjid qsdtc_;
run;


data ecog ;
 set ecog;
   by usubjid qsdtc_;
    if last.usubjid;
run;


proc transpose data=ecog(where =(upcase(QSCAT) eq "ECOG" )) out=qs_ecog(keep= usubjid ecog rename=(ecog=ecogbl)) ;
 by usubjid;
    id qscat;
     var QSSTRESC ;
 run;
****************Visceral disease at baseline******************;

proc transpose data=sdtmdata.famh(where =(upcase(FATESTCD) eq "DISVIS" /*and FABLFL eq "Y"*/ )) out=mh_vis1 ;
 by usubjid;
    id FASCAT;
     var FASTRESC;
run;


data mh_vis1_(keep=usubjid VISGR1BL VISDSBL);
 set mh_vis1 ;
   
if upcase(BRAIN) eq "VISCERAL" and upcase(EXTRACRANIAL) eq "VISCERAL" then do; VISGR1BL =1;VISDSBL =1; end;
 else if upcase(BRAIN) eq "NON-VISCERAL" and upcase(EXTRACRANIAL) eq "NON-VISCERAL" then do; VISGR1BL =2;VISDSBL =2; end;
 else if upcase(BRAIN) eq "VISCERAL AND NON-VISCERAL" and upcase(EXTRACRANIAL) eq "VISCERAL AND NON-VISCERAL" then do; VISGR1BL =3; VISDSBL =1; end;
  
run;


*******************Number of extracranial disease sites at baseline *****************;

proc sort data=sdtmdata.tu(where=(upcase(tuscat) eq "EXTRACRANIAL" and visit eq "SCREENING")) out=tu(keep=usubjid tuloc) nodupkey ;
 by usubjid tuloc;
run;

proc freq data=tu noprint ;
 tables usubjid /out=num_ex_sites(drop=percent);
run;

data num_ex_sites;
 set  num_ex_sites;
   if count >= 3  then NEXBL=1;
   else  if count =< 2 then NEXBL=0;
run;

****************Number of intracranial target lesions at baseline*****************;



proc sort data=sdtmdata.tu(where=(upcase(tuscat) eq "BRAIN" and TUORRES eq "TARGET" and visit eq "SCREENING")) out=tu(keep=usubjid tuloc) nodupkey ;
 by usubjid tuloc;
run;

proc freq data=tu noprint ;
 tables usubjid /out=num_inc_sites(drop=percent);
run;

data num_inc_sites;
 set  num_inc_sites;
   if count = 5  then NINTRBL=4;
   else if count = 4  then NINTRBL=3;
   else if count = 3  then NINTRBL=2;
   else if count = 2  then NINTRBL=1;
   else if count = 1  then NINTRBL=0;
  
run;


************************Number of intracranial non-target lesions at baseline*******************;
 
proc sort data=sdtmdata.tu(where=(upcase(tuscat) eq "BRAIN" and TUORRES eq "NON-TARGET" and visit eq "SCREENING")) out=tu(keep=usubjid tuloc) nodupkey ;
 by usubjid tuloc;
run;


proc freq data=tu noprint ;
 tables usubjid /out=num_inc_nt_sites(drop=percent);
run;

data num_inc_nt_sites;
 set  num_inc_nt_sites;
   if count >= 5  then NINNTRBL=4;
   else if count = 4  then NINNTRBL=3;
   else if count = 3  then NINNTRBL=2;
   else if count = 2  then NINNTRBL=1;
   else if count = 1  then NINNTRBL=0;
run;


********The time since initial diagnosis of intracranial disease to treatment category****************;


data mh(keep=usubjid mh_dt);
 set sdtmdata.mh (where=(upcase(MHTERM) ='MELANOMA BRAIN' and MHCAT ='DISEASE UNDER STUDY')) ;
  by usubjid ;
     if length(mhstdtc) eq 7 then do; mhdt=strip(mhstdtc)||"-01"; end;
   else if length(mhstdtc) eq 4 then do; mhdt=strip(mhstdtc)||"-01-01";end;
   else if length(mhstdtc) eq 10 then mhdt=strip(mhstdtc);
  * if length(mhstdtc) eq 7 then mhdt=strip(mhstdtc)||"-01"; *else ;
    *if length(mhstdtc) eq 10 then mhdt=strip(mhstdtc);
    mh_dt=input(mhdt,yymmdd10.);

    format mh_dt date9.;



proc sort data=mh ;
 by usubjid mh_dt;
run;

data mh ;
 set mh;
 by usubjid;
  if last.usubjid;
  format mh_dt date9.;

run;


********The time since initial diagnosis of extracranial disease to treatment category****************;

data mh_(keep=usubjid mh_dt1);
 set sdtmdata.mh (where=(upcase(MHTERM) ='MELANOMA EXTRACRANIAL' and MHCAT ='DISEASE UNDER STUDY')) ;
  by usubjid ; 
   if length(mhstdtc) eq 7 then do; mh_dt=strip(mhstdtc)||"-01"; end;
   else if length(mhstdtc) eq 4 then do; mh_dt=strip(mhstdtc)||"-01-01";end;
   else if length(mhstdtc) eq 10 then mh_dt=strip(mhstdtc);
  * if length(mhstdtc) eq 7 then mhdt=strip(mhstdtc)||"-01"; 
  * else if length(mhstdtc) eq 4 then mhdt=strip(mhstdtc)||"-01-01"; 
   *else ;
  *if length(mhstdtc) eq 10 then mh_dt=strip(mhstdtc);
    mh_dt1=input(mh_dt,yymmdd10.);
    format mh_dt1 date9.;


proc sort data=mh_;
 by usubjid mh_dt1;


data mh_ ;
 set mh_;
 by usubjid mh_dt1;
  if last.usubjid;
  format mh_dt1 date9.;

run;


********The time since first diagnosis of metastatic disease ****************;

data mh_meta(keep=usubjid mh_dt3 MEDISDTF);
 set sdtmdata.mh (where=(upcase(MHTERM) ='METASTATIC DISEASE' and MHCAT ='DISEASE UNDER STUDY')) ;
  by usubjid ;
  if length(mhstdtc) eq 7 then do; mh_dt=strip(mhstdtc)||"-01"; MEDISDTF="D"; end;
   else if length(mhstdtc) eq 4 then do; mh_dt=strip(mhstdtc)||"-01-01"; MEDISDTF="M";end;
   else if length(mhstdtc) eq 10 then mh_dt=strip(mhstdtc);
    mh_dt3=input(mh_dt,yymmdd10.);
    format mh_dt3 date9.;
run;

proc sort data=mh_meta;
 by usubjid mh_dt3;


data mh_meta ;
 set mh_meta;
 by usubjid mh_dt3;
  if last.usubjid;
  format mh_dt3 date9.;

run;



********************Time since intial Diagnosis(weeks)******************************;




data mh_2(keep=usubjid mh_dt2);
 set sdtmdata.mh(where =(mhstdtc ne ' ')) ;
  by usubjid ;
     if length(mhstdtc) eq 7 then do; mhdt=strip(mhstdtc)||"-01"; end;
   else if length(mhstdtc) eq 4 then do; mhdt=strip(mhstdtc)||"-01-01";end;
   else if length(mhstdtc) eq 10 then mhdt=strip(mhstdtc);
  * if length(mhstdtc) eq 7 then mhdt=strip(mhstdtc)||"-01"; 
   * else  if length(mhstdtc) eq 4 then mhdt=strip(mhstdtc)||"-01-01" else;
   if length(mhstdtc) eq 10 then mhdt=strip(mhstdtc);
    mh_dt2=input(mhdt,yymmdd10.);
run;


proc sort data=mh_2 ;
 by usubjid mh_dt2;
run;

data mh_2_ ;
 set mh_2;
 by usubjid;
  if last.usubjid;
  format mh_dt2 date9.;
run;




 *******************Child bearing potential**********************;


proc sort data=sdtmdata.rp out=rp(keep=usubjid RPSTRESC rename=(RPSTRESC=chbpot)) ;
 by usubjid ;
run;




******************Measurable Intracranial at base INV***************************;
 /*
proc sort data=sdtmdata.tu out=tu_in(keep=usubjid tueval tuscat) nodupkey;
by usubjid tueval tuscat visit;
where tueval eq "INVESTIGATOR" and visit eq "SCREENING" and tuscat eq "BRAIN";
run;

data famh_1;
 merge tu_in(in=a) sdtmdata.famh(in=b where =(upcase(FATESTCD) eq "MEASDISS" and FASCAT eq "BRAIN" )) ; 
  by usubjid ;
  if a and b;
run;*/

proc transpose data=SDTMDATA.FAMH(where =(upcase(FATESTCD) eq "MEASDISS" and FASCAT eq "BRAIN" )) out=scr_in
(keep=usubjid brain rename=(brain=MINDBLIN));
 by usubjid;
    id FASCAT;
     var FASTRESC;
run;


******************Measurable Intracranial at base IRC***************************;
/*
proc sort data=sdtmdata.tu out=tu_in_irc(keep=usubjid) nodupkey;
by usubjid tueval tuscat visit;
where tueval eq "INDEPENDENT ASSESSOR" and visit eq "SCREENING" and tuloc eq "BRAIN" and TUSTRESC='TARGET';
run;

data famh_1;
 merge tu_in_irc(in=a) sdtmdata.famh ; 
  by usubjid ;
  if a;
run;

proc transpose data=famh_1(where =(upcase(FATESTCD) eq "MEASDISS" and FASCAT eq "BRAIN" )) 
                                out=scr_in_irc(keep=usubjid brain rename=(brain=MINDBLIR));
 by usubjid;
    id FASCAT;
     var FASTRESC;
run;

data scr_in_irc ;
set scr_in_irc ;
if TRSTRESC="PRESENT" and TRGRPID="TARGET" then do;
             MINDBLIR = 'Y'; ord = 1; end;
		else do; MINDBLIR = 'N'; ;
run;
*/
**************************************************************;
***********************************************************************;

proc sort data=sdtmdata.tr out=tr_1 (keep=usubjid TRSEQ visit treval trtestcd trstresc trgrpid trdtc);
by usubjid;
where VISIT="SCREENING" and TREVAL="INDEPENDENT ASSESSOR"  and TRTESTCD="TUMSTATE" AND TRSCAT='BRAIN';
run;

proc sort data=sdtmdata.tr out=tr_2 (keep=usubjid TRSEQ visit treval trtestcd trstresc trgrpid trdtc);
by usubjid;
where VISIT="SCREENING" and TREVAL="INDEPENDENT ASSESSOR"  and TRTESTCD="TUMSTATE" AND TRSCAT='EXTRACRANIAL';
run;

*** Measurable TARGET Disease at baseline (IRC assess) : INTRACRANIAL ***;

data mdirc ;
	length MINDBLIR $100;
	set tr_1;
		if TRSTRESC="PRESENT" and TRGRPID="TARGET" then do;
             MINDBLIR = 'Y'; ord = 1; end;
		else do; MINDBLIR = 'N'; ord = 0; end;
run;
proc sort data = mdirc; by usubjid descending ord; run;
proc sort data = mdirc out=scr_in_irc (keep=usubjid MINDBLIR) nodupkey; by usubjid; run;















*********************Measurable Extracranial Disease at Baseline (INV assess)******************************;

/*
proc sort data=sdtmdata.tu out=tu_in(keep=usubjid) nodupkey;
by usubjid tueval tuscat visit;
where tueval eq "INVESTIGATOR" and visit eq "SCREENING" and tuscat eq "EXTRACRANIAL";
run;

data famh_1;
 merge tu_in(in=a) sdtmdata.famh(in=b ) ; 
  by usubjid ;
  if a and b;
run;
*/
proc transpose data=sdtmdata.famh(where =(upcase(FATESTCD) eq "MEASDISS" and FASCAT eq "EXTRACRANIAL" )) out=scr_ex(keep=usubjid EXTRACRANIAL rename=(EXTRACRANIAL=MEXDBLIN));
 by usubjid;
    id FASCAT;
     var FASTRESC;
run;

/* check for the count;

proc freq data=sdtmdata.famh(where =(upcase(FATESTCD) eq "MEASDISS" and FASCAT eq "EXTRACRANIAL" ))  ;
 tables FAORRES/out=test;
 run;


proc freq data=sdtmdata.famh(where =(upcase(FATESTCD) eq "NTLSS" and FASCAT eq "BRAIN" ))  ;
 tables FAORRES/out=test1;
 run;
*/
*********************Measurable Extracranial Disease at Baseline (IRC assess)******************************;

/*
proc sort data=sdtmdata.tu out=tu_in(keep=usubjid) nodupkey;
by usubjid tueval tuscat visit;
where tueval eq "INDEPENDENT ASSESSOR" and visit eq "SCREENING" and tuloc ne "BRAIN" and TUSTRESC eq "TARGET" ;
run;


data famh_1;
 merge tu_in(in=a) sdtmdata.famh(in=b where =(upcase(FATESTCD) eq "MEASDISS" and FASCAT eq "EXTRACRANIAL" )) ; 
  by usubjid ;
  if a and b ;
run;

proc transpose data=famh_1 out=scr_ex_irc(keep=usubjid EXTRACRANIAL rename=(EXTRACRANIAL=MEXDBLIR));
 by usubjid;
    id FASCAT;
     var FASTRESC;
run;*/
*************************************************************;
*********************************************************************;
data mdirc_1 ;
	length MEXDBLIR $100;
	set tr_2;
		if TRSTRESC="PRESENT" and TRGRPID="TARGET" then do;
             MEXDBLIR = 'Y'; ord = 1; end;
		else do; MEXDBLIR = 'N'; ord = 0; end;
run;
proc sort data = mdirc_1; by usubjid descending ord; run;
proc sort data = mdirc_1 out=scr_ex_irc (keep=usubjid MEXDBLIR) nodupkey; by usubjid; run;





************************NT Intracranial Disease base INV*****************************;


/*
proc sort data=sdtmdata.tu out=tu_in(keep=usubjid) nodupkey;
by usubjid tueval tuscat visit;
    where tueval eq "INVESTIGATOR"  and tuscat eq "BRAIN" and TUSTRESC eq "NON-TARGET";
run;

data famh_1;
 merge tu_in(in=a) sdtmdata.famh (in=b ); 
  by usubjid ;
  if a and b;
run;*/

proc transpose data=sdtmdata.famh(where =(upcase(FATESTCD) eq "NTLSS" and FASCAT eq "BRAIN" )) out=nt_inv(keep=usubjid brain rename=(brain=NTINDINV));
 by usubjid;
    id FASCAT;
     var FASTRESC;
run;



************************NT Intracranial Disease base IRC*****************************;



proc sort data=sdtmdata.tu out=tu_in(keep=usubjid) nodupkey;
by usubjid tueval tuscat visit;
    where tueval eq "INDEPENDENT ASSESSOR" and visit eq "SCREENING" and tuloc eq "BRAIN" and TUSTRESC eq "NON-TARGET";
run;

data famh_1;
 merge tu_in(in=a) sdtmdata.famh(in=b where =(upcase(FATESTCD) eq "NTLSS" and FASCAT eq "BRAIN" ))  ; 
  by usubjid ;
  if a and b ;
run;

proc transpose data=famh_1 out=nt_irc(keep=usubjid brain rename=(brain=NTINDIRC));
 by usubjid;
    id FASCAT;
     var FASTRESC;
run;




************************NT EXtracranial Disease base INV*****************************;


/*
proc sort data=sdtmdata.tu out=tu_in(keep=usubjid) nodupkey;
by usubjid tueval tuscat visit;
    where tueval eq "INVESTIGATOR" and visit eq "SCREENING" and tuloc ne "BRAIN" and TUSTRESC eq "NON-TARGET";
run;

data famh_1;
 merge tu_in(in=a) sdtmdata.famh(in=b ) ; 
  by usubjid ;
  if a and b;
run;*/

proc transpose data=SDTMdata.famh(where =(upcase(FATESTCD) eq "NTLSS" and FASCAT eq "EXTRACRANIAL" )) out=nt_ex_inv(keep=usubjid EXTRACRANIAL rename=(EXTRACRANIAL=NTEXDINV));
 by usubjid;
    id FASCAT;
     var FASTRESC;
run;


************************NT EXtracranial Disease base IRC*****************************;



proc sort data=sdtmdata.tu out=tu_in(keep=usubjid) nodupkey;
by usubjid tueval tuscat visit;
    where tueval eq "INDEPENDENT ASSESSOR" and visit eq "SCREENING" and tuloc ne "BRAIN" and TUSTRESC eq "NON-TARGET";
run;

data famh_1;
 merge tu_in(in=a) sdtmdata.famh(in=b where =(upcase(FATESTCD) eq "NTLSS" and FASCAT eq "EXTRACRANIAL" )) ; 
  by usubjid ;
  if a and b ;
run;

proc transpose data=famh_1 out=nt_ex_irc(keep=usubjid EXTRACRANIAL rename=(EXTRACRANIAL=NTEXDIRC));
 by usubjid;
    id FASCAT;
     var FASTRESC;
run;



*******************Prior Brain Local therapy ******************;

proc transpose data=sdtmdata.famh (where =(upcase(FATESTCD) eq "PRIORLT" and  FASCAT eq "BRAIN" )) out=pr_lth(keep=usubjid PRIORLT rename=(PRIORLT=PRBRTH));
 by usubjid;
    id FATESTCD;
     var FASTRESC;
run;



*******************STage******************;

proc sort data=sdtmdata.famh out=FA_STAGE(KEEP=usubjid FASTRESC RENAME=(FASTRESC=STAGE)) NODUPKEY;
    by usubjid;
    where fatestcd='STAGE';
    run;

proc transpose data=sdtmdata.famh (where =(upcase(FATESTCD) eq "STAGE" and FASCAT eq "BRAIN" )) out=stagein(keep=usubjid stage rename=(Stage=stagein));
 by usubjid;
    id FATESTCD;
     var FASTRESC;
run;



proc transpose data=sdtmdata.famh (where =(upcase(FATESTCD) eq "STAGE" and FASCAT eq "EXTRACRANIAL" )) out=stageex(keep=usubjid stage rename=(stage=STAGEEX));
 by usubjid;
    id FATESTCD;
     var FASTRESC;
run;

*******************Histology INTRACARNIAL******************;

proc sort data=sdtmdata.famh out=FA_HIST(KEEP=USUBJID FASTRESC RENAME=(FASTRESC=HIST)) NODUPKEY;
    by usubjid;
    where fatestcd='HIST';
    run;

proc transpose data=sdtmdata.famh (where =(upcase(FATESTCD) eq "HIST" and FASCAT eq "BRAIN" )) out=histin(keep=usubjid HIST rename=(hist=histin));
 by usubjid;
    id FATESTCD;
     var FASTRESC;
run;


*******************Histology EXTRACRANIAL ******************;

proc transpose data=sdtmdata.famh (where =(upcase(FATESTCD) eq "HIST" and FASCAT eq "EXTRACRANIAL" )) out=histex(keep=usubjid HIST rename=(hist=histex));
 by usubjid;
    id FATESTCD;
     var FASTRESC;
run;


*******************Primary tumor type ******************;
proc sort data=sdtmdata.famh out=prm_tu_ty nodupkey ;
 by usubjid;
  where index(UPCASE(faobj),"MELANOMA");
run;


data  prm_tu_ty(keep=usubjid PRTUTY);
 set prm_tu_ty;
  PRTUTY="Y";
run;

data mh_inidt(keep= usubjid INDIAGDT INDIADTC/* IDIAGDTC  IDIAGDTF*/ );
set sdtmdata.mh(where =(mhcat="DISEASE UNDER STUDY" and mhterm = "MELANOMA BRAIN"/*and visit='SCREENING'*/));
by usubjid;

  if length(mhstdtc) eq 7 then do; mhdt=strip(mhstdtc)||"-01"; end;
   else if length(mhstdtc) eq 4 then do; mhdt=strip(mhstdtc)||"-01-01";end;
   else if length(mhstdtc) eq 10 then mhdt=strip(mhstdtc);

  INDIAGDT=input(mhdt,yymmdd10.);
 format INDIAGDT date9.;
           year=scan(mhstdtc,1);
           month=put(strip(scan(mhstdtc,2,'-')),$mon.);
           day=scan(mhstdtc,3);
           
        
     if  year ne ' ' and month ne ' ' and day ne ''  then INDIADTC=strip(day)||strip(month)||strip(year);
     if  year ne ' ' and month ne ' ' and day eq .  then INDIADTC='--'||strip(month)||strip(year);

     if  year ne ' ' and month eq ' ' and day eq .  then INDIADTC='-----'||strip(year);
* else if length(mhstdtc) eq 7 then INDIAGDT=input(mhstdtc,date9.);;
 run;


 data mh_exidt(keep= usubjid EXDIAGDT EXDIADTC  year month day/* IDIAGDTC  IDIAGDTF*/ );
    set sdtmdata.mh(where =(mhcat="DISEASE UNDER STUDY" and mhterm = "MELANOMA EXTRACRANIAL"/*and visit='SCREENING'*/));
    by usubjid;

  if length(mhstdtc) eq 7 then do; mhdt=strip(mhstdtc)||"-01"; end;
   else if length(mhstdtc) eq 4 then do; mhdt=strip(mhstdtc)||"-01-01";end;
   else if length(mhstdtc) eq 10 then mhdt=strip(mhstdtc);

    EXDIAGDT=input(mhdt,yymmdd10.); 
    format EXDIAGDT date9.;

           year=scan(mhstdtc,1);
           month=put(strip(scan(mhstdtc,2,'-')),$mon.);
           day=scan(mhstdtc,3);
           
        
     if  year ne ' ' and month ne ' ' and day ne ''  then EXDIADTC=strip(day)||strip(month)||strip(year);
     if  year ne ' ' and month ne ' ' and day eq .  then EXDIADTC='--'||strip(month)||strip(year);

     if  year ne ' ' and month eq ' ' and day eq .  then EXDIADTC='-----'||strip(year);
 run;

/*if MHCAT = "DISEASE UNDER STUDY"  then  do;
if length(mhstdtc) eq 10 then do;
 IDIAGDT=input(mhstdtc,yymmdd10.);
 end;


if length(mhstdtc) eq 7 then  do;
 INDIAGDT=input(strip(mhstdtc)||"-01",yymmdd10.);
 IDIAGDTF='D';
end;

if length(mhstdtc) eq 4 then do;
    IDIAGDT=input(strip(mhstdtc)||"-01-01",yymmdd10.);
    IDIAGDTF='M';
    end;
end;


format INDIAGDT date9.;


proc sort data=mh_inidt ;
  by usubjid IDIAGDT;

   data  mh_inidt;
     set mh_inidt;
     by usubjid IDIAGDT;
     if last.usubjid;
     keep usubjid IDIAGDTC INDIAGDT IDIAGDTF;
run;*/


*************************LDH;

data lb2(keep=usubjid lbtestcd lborres lbblfl LBORNRHI lbdt trtsdt);
 merge sdtmdata.lb  /*prod.adsl*/  exp (keep=usubjid trtsdt);
  by usubjid;
  lbdt=input(lbdtc,yymmdd10.);
        if lbtestcd='LDH' and /*LBBLFL eq 'Y'*/ lbdt <= trtsdt ;
run;

data lb2_/*(keep=USUBJID LDH)*/;
    attrib ldh length=$25;
    set lb2;
        *High = lbstresn*1;

            if LBORRES>LBORNRHI then ldh="ABOVE ULN"; 
             else if LBORRES <= LBORNRHI then ldh="EQUAL TO OR BELOW ULN";
              *else  ldh="UNKNOWN";
    keep usubjid lbtestcd lbdt ldh;
    *if ldh ne ' ';
run;


proc sort data=lb2_ out=lb2_ ;
    by usubjid lbtestcd lbdt;

     data lb2_ ;
       set lb2_;
        by usubjid lbtestcd lbdt;
        if last.usubjid;
        keep usubjid LDH;
    run;

******************************************;

  data qc_adsl_;
  length DTHSTSC $50.;
  merge  ltcondt/*dm_fin*/(in=a) sv_stdtc /*sv_endtc*/ qs_ecog mh_vis1_ num_ex_sites num_inc_sites num_inc_nt_sites mh mh_ rp 
    scr_in scr_in_irc scr_ex scr_ex_irc nt_inv nt_irc nt_ex_inv nt_ex_irc pr_lth FA_STAGE stagein stageex FA_HIST histin histex prm_tu_ty 
    mh_2_ mh_inidt mh_exidt lb2_ ds_ipdisc(in=x) exendt_(in=t) mh_meta(in=meta)/*ds_tredt*/;
   by usubjid;
   if a;

   if SEX eq "F" then gencov=1;
     else if SEX eq "M" then gencov=0;

    if age >= 65 then AGECATBL =1;
     else if age < 65 then AGECATBL =0;

*****************Time since intial diagnosis of intracranial disease;


     if trtsdt < mh_dt then diff = (trtsdt-mh_dt);
      else if trtsdt >= mh_dt then diff =(trtsdt-mh_dt+1);
        TSIRDIAG=round((diff/7),0.01);

*****************Time since intial diagnosis of extracranial disease;
      if trtsdt < mh_dt1 then diff1 = (trtsdt-mh_dt1);
      else if trtsdt >= mh_dt1 then diff1 =(trtsdt-mh_dt1+1);
        TSEXDIAG =round((diff1/7),.01);

*****************Time since first diagnosis of metastatic disease;

       if trtsdt < mh_dt3 then diff2 = (trtsdt-mh_dt3);
      else if trtsdt >= mh_dt3 then diff2 =(trtsdt-mh_dt3+1);
       METDISDT=round((diff2/7),.01);


***********Metastatic disease at screening;

   if meta and mh_dt3 ne . then MEDISSCR="Y";
     else if meta and mh_dt3 eq . then MEDISSCR="N";

   /* if TSIRDIAG_ >= 1  then TSIRDIAG=1;
         else if . < TSIRDIAG_ < 1  then TSIRDIAG=0;

                 if TSEXDIAG_ >= 1  then TSEXDIAG=1;
         else if . < TSEXDIAG_ < 1  then TSEXDIAG=0;*/

           if trtsdt < mh_dt2 then diff2 = (trtsdt-mh_dt2);
      else if trtsdt >= mh_dt2 then diff2 =(trtsdt-mh_dt2+1);
       INDIAG =round((diff2/7),.01);

 
   if upcase(race) eq "WHITE" then racecat=0;
   else if upcase(race) eq "AFRICAN-AMERICAN" then racecat=1;
    else if upcase(race) eq "OTHER" then racecat=2;


    *cutdt="2016-11-28" ;
         cutoffdt=input("&g_datadate",date9.);

  if RFXENDTC ne ' ' and upcase(trtstat) ne "ONGOING" then trtedt=input(RFXENDTC,yymmdd10.);
  if upcase(trtstat) eq "ONGOING" and not(x) and TRTEDT_ NE .  then trtedt=TRTEDT_;
  if UPCASE(TRTSTAT) EQ "ONGOING" and not(x) and TRTEDT_ EQ .  then trtedt=cutoffdt;
  if trtsdt ne . and trtedt eq . and not( x )then  trtedt=cutoffdt;
  if trtedt > cutoffdt then trtedt=cutoffdt;
  if trtedt eq cutoffdt then trtedtf ="Y";



         ******************Last contact date updated **********************;
         if dthfl eq "Y" and lstctdt > dthdt then lstctdt=dthdt;



    fodur= lstctdt-trtsdt+1;
  
format lstctdt FSTCTDT trtedt dthdt  date9.;


 if upcase(status) eq "DIED" then do;DTHSTSN=1;DTHSTSC="Dead" ;end;
    else if upcase(status) ne "DIED" and (status) eq "Withdrawn from study"  then do;DTHSTSN=2; DTHSTSC="Alive at last contact, follow-up ended"; end;
    else  if status ne "Not randomised" then do;DTHSTSN=3; DTHSTSC="Alive at last contact, follow-up Ongoing"; end;
	 
 /*if upcase(status) eq "DIED" then do;DTHSTSN=1;DTHSTSC="Dead" ;end;
	else if upcase(status) eq "NOT RANDOMISED" and trtstat eq "Not Treated"   then do;DTHSTSN=.; DTHSTSC=""; end;
     else if upcase(status) ne "DIED" and trtstat eq "Discontinued"  then do;DTHSTSN=2; DTHSTSC="Alive at last contact, follow-up ended"; end;
     else if upcase(status) ne "DIED" and trtstat eq "Ongoing"  then do;DTHSTSN=3;DTHSTSC="Alive at last contact, follow-up ongoing"; end;
      else if upcase(status) eq "" and trtstat eq 'Not Treated' then do; DTHSTSN=3;DTHSTSC="Alive at last contact, follow-up ongoing"; end;
	else if upcase(status) ne "Withdrawn from study" and trtstat eq "Not Treated"   then do;DTHSTSN=2; DTHSTSC="Alive at last contact, follow-up ended"; end;*/
	 
 	if dthdt ne . and trtsdt ne . then ELTMLIP=dthdt-trtsdt+1;
            if upcase(status) eq "DIED" then do;
        if ELTMLIP <= 28 then do; ELLIPCCD=1 ;DFDDYCT="<= 28 days"; end;
         else if ELTMLIP > 28 then do; ELLIPCCD=2;DFDDYCT="> 28 days";end;
         end;
      

	if dthdt ne . and trtedt ne . then ELTMLIP=dthdt-trtedt+1;
            if upcase(status) eq "DIED" then do;
        if ELTMLIP <= 28 then do; ELLIPCCD=1 ;DLDDYCT="<= 28 days"; end;
         else if ELTMLIP > 28 then do; ELLIPCCD=2;DLDDYCT="> 28 days";end;
         end;


****************imputation for last contact date ******************;

        /* if trtedt eq . and trtsdt ne . then trtedt_=min(dthdt,dsstdt_lst,"&g_datadate");
          else if trtedt ne . then trtedt_=trtedt;
         drop trtedt;
         rename trtedt_=trtedt;*/

*keep usubjid lstctdt FSTCTDT trtedt trtsdt dthdt fodur;

 run;

proc freq data=qc_adsl_ noprint;;
tables DTHSTSC;
run;

/*Derivation of New Anti-cancer therapy date*/


PROC SORT DATA = SDTMDATA.CM OUT= CM;
    BY USUBJID CMSTDTC;
    WHERE CMCAT NE ('PRIOR CANCER THERAPY') AND CMSCAT NOT IN('BLOOD PRODUCT',
                    'CONCOMITANT MEDICATION OF INTEREST','GENERAL CONCOMITANT MEDICATION')
    AND CMSTDTC NE '' ;
RUN;

proc sort data=sdtmdata.cm out=cm_1;
    by usubjid cmstdtc;
    where cmscat='GENERAL CONCOMITANT MEDICATION' and cmcat='PERMITTED MEDICATIONS' and cmdecod='RADIOTHERAPY'  AND CMSTDTC NE '' ;;
    run;


proc sort data=sdtmdata.pr out=pr_rad (keep = usubjid prstdtc prcat rename=(prcat=cmcat prstdtc=cmstdtc));
by usubjid;
/*
where prcat not in ('BIOMARKER','ONCOLOGY SCANS','PHARMACOGENETICS','PRIOR RADIOTHERAPY','PRIOR SURGICAL PROCEDURE') and prstdtc ne '';
*/
 where prcat in ("FOLLOW-UP RADIOTHERAPY", "RADIOTHERAPY" ) and prstdtc ne '';
run;


**************************************************************;

data supp1;
    set sdtmdata.supppr;
    prseq=input(idvarval,best12.);
            if qnam = "PRLLTCD";
run;

proc transpose data=supp1 out=supp2(drop=_:);
    by usubjid prseq;
    var qval;
    id qnam;
    idlabel qlabel;
run;

proc sort data = SDTMData.PR (keep = USUBJID DOMAIN PRSEQ PRSTDTC PRCAT PRSCAT
                   where=(index(PRCAT, 'SURGICAL PROCEDURE')and index(PRCAT,"PRIOR")=0))
                   out= pr;
    by usubjid prseq;
run;

data pr1;*(rename = prlltcd1 = prlltcd);
    merge pr(in=x) supp2(in=y);
    by usubjid prseq;
    *prlltcd1 = input(prlltcd,best.); 
    if x;
    *drop prlltcd;
run;

proc import datafile = '/arenv/arprod/gsk2118436/brf117277/primary/documents/BRF117277 surgery on or post treatment.xls'
    out= ctxsurg replace dbms = xls ;getnames = yes; datarow = 2;
run;

data surg(rename = (Non_diagnostic_surgery_that_need = ancnsurg));
   length usubjid $16. subj1 $ 5. ;
    set ctxsurg;
    subj1 = compress(put(subjid,best.));
    if length(subj1) = 2 then usubjid = cats(studyid,'.0000',subj1);
    if length(subj1) = 3 then usubjid = cats(studyid,'.000',subj1);
    where Non_diagnostic_surgery_that_need = 'yes';
    prlltcd = compress(put(splltcd,best.));
run;

proc sort data = surg(keep = usubjid ancnsurg prlltcd);
    by usubjid prlltcd;
run;
proc sort data = pr1 nodupkey;
    by usubjid prlltcd;
    where prlltcd ne '';
run;

data pr_surg( keep= usubjid prstdtc prcat rename=(prstdtc=cmstdtc prcat=cmcat));
    merge pr1(in=x) surg(in=y);
    by usubjid prlltcd;
    if x=y;
run;

************************************************************************;

data cm_all;
set cm cm_1 pr_rad  pr_surg;

if cmstdtc ne '' then do;

  if length (cmstdtc) eq 10 then do;
            nantydt_=cmstdtc;
  end;

  if length (cmstdtc) eq 7 then do;
            nantydt_=compress(cmstdtc||'-'||'01');
            nantyfl='Y';
  end;

  if length (cmstdtc) eq 4 then do;
            nantydt_=compress(cmstdtc||'-'||'01'||'-'||'01');
            nantyfl='Y';
  end;
end;

proc sort; by usubjid nantydt_;
run;

data th_date (keep=usubjid nantydt_ nantyfl);
set cm_all;
by usubjid nantydt_;
if first.usubjid;
run;

*************************************************************************;

proc sort data=qc_adsl_;
by usubjid;
run;

proc sort data=th_date;
by usubjid;
run;

data qc_adsl_1;
format nantydt date9.;
merge qc_adsl_ (in=a) th_date (in=b);
by usubjid;
if a;
nantydt=input(nantydt_,??yymmdd10.);
run;

 

%tu_attrib(
           dsetin          = qc_adsl_1,
           dsetout         = qc_adsl,
           dsplan          = /arenv/arprod/gsk2118436/brf117277/eos/adamdata/adsl_spec.txt
          );

libname dev "/arenv/arprod/gsk2118436/brf117277/eos/adamdata";

proc sort data = qc_adsl out = val/*(drop=stage hist)*/;
 by usubjid ;
run;

*proc sort data = dev.adsl(drop=stage hist) out = dev;
* by  usubjid;
*run;

 
proc compare b = adamdata.adsl c = val listall criterion=0.0001 ; 
 *   id usubjid ;
run;

