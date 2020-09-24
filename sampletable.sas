/*** Localy Used Macro's***/

 
  
libname sdtmdata "/folders/myfolders/pogram/sdtm";
libname prod  "/folders/myfolders/define3";
libname adb  "/folders/myfolders/define3";
libname adamdata "/folders/myfolders/define3";


 %Macro sort (in=, out=, byvar=,nodupkey=);
      proc sort data = &in out=&out &nodupkey ;
      by &byvar;
      run;
  %Mend;

/***Get ADSL***/
 data adsl ;
     set adamdata.adsl;
     where atsfl='Y';
     keep usubjid atsfl cohortcd cohort trt01a trt01an trt01p trt01pn cohortn;
 run;

   data pop ;
    set adsl;
     cohrt=cohort;
     cohrtcd=cohortcd;
     cohrtn=cohortn;
     output;
     cohrt="Total";
     cohrtcd="T";
     cohrtn=99;
     output;
   run;

   proc freq data=pop noprint;
     table cohrtn*cohrtcd*cohrt/ out=trtbign(drop= percent rename=(count=poptot));
   run;

/***Get ADTTE***/
 data adtte2 ; 
  set adamdata.adtte2; 
 run;

/*Subset with OS and keep required variables*/
 data adtte2_1 ; 
  set adtte2;
  where paramcd eq 'OS';
  if cnsr>0  then cnsr=1;
  keep usubjid paramcd follstat param adt aval cnsr evntdesc dthdt cnsr;
 run;


 /*Merge with pop data*/
 %sort (in=adtte2_1,out=adtte2_1,byvar=usubjid);

 data adtte2_2 ;
  merge adtte2_1(in=a) adsl(in=b);
  by usubjid;
  if a and b;
 run;

 data adtte2_3 ;
  set adtte2_2 ;
     cohrt=cohort;
     cohrtcd=cohortcd;
     cohrtn=cohortn;
     output;
     cohrt="Total";
     cohrtcd="T";
     cohrtn=99;
     output;
 run;

 data adtte2_4;
  set adtte2_3;
  length slb $ 50;
  if  cnsr=0 and evntdesc in ('DEATH')      then do;s1=1;s2=4;slb='Died (event)';end;
  if  cnsr=1 and follstat eq 'Censored, Follow-up Ended'  then do;s1=1;s2=8;slb='Censored, follow-up ended';end;
  if  cnsr=1 and follstat eq 'Censored, Follow-up Ongoing' then do;s1=1;s2=9;slb='Censored, follow-up ongoing';end;
 run;

 data adtte2_4 ;
  set adtte2_4;
  output;
  s1=1;s2=0;slb='n';
  output;
 run;

  proc freq data=adtte2_4 noprint;
     table cohrtn*cohrtcd*cohrt*s1*s2*slb/ out=adtte2_5(drop= percent);
  run;

 /* Percentage Calculation*/

 data adtte2_6;
   merge adtte2_5 trtbign;
   by cohrtn cohrtcd cohrt;
   pct = round((count/poptot)*100,1);
   if slb ne 'n'  then npct=trim(left(put(count,3.))) || ' (' || trim(left(put(pct,3.))) ||'%)';
    else  npct=trim(left(put(count,3.)));
 run;

%sort(in=adtte2_6,out=adtte2_6,byvar=s1 s2 slb);

 proc transpose data= adtte2_6 out=adtte2_7 (drop=_name_);
  by s1 s2 slb;
  var npct;
  id cohrtcd;
 run;


   ods output quartiles=quartiles ; 
      ods listing close;
      proc lifetest data=adtte2_3 Method=PL  /*CONFTYPE=LINEAR */  alpha=0.05;
         time aval*cnsr(1);
         strata cohrtcd ;
      quit; 
        
    ods listing;

/*Estimates*/
    data  quartiles1;
     set quartiles;
     if Percent eq 25 then do;s1=4;s2=1;slb='1st Quartile';end;
     if Percent eq 50 then do;s1=4;s2=3;slb='Median';end;
     if Percent eq 75 then do;s1=4;s2=5;slb='3rd Quartile';end;
     estimate_=put(round(estimate,0.1),best.);
    run;

 %sort(in=quartiles1,out=quartiles1_1,byvar=s1 s2 slb);

  proc transpose data= quartiles1_1 out=quartiles1_2 (drop=_name_);
    by s1 s2 slb;
    var estimate_;
    id cohrtcd;
 run;

 data quartiles1_2 ;
  set quartiles1_2;
   if a eq '' then a='NR';if b eq '' then b='NR';if c eq '' then c='NR';if d eq '' then d='NR';if t eq '' then t='NR';
 run;

/*CI*/

 data  quartiles2;
     set quartiles;
     length ci $ 20;
         if LowerLimit = . and UpperLimit = . then ci='(NR,NR)';
         else if UpperLimit = . then ci=compress('('||put(LowerLimit, 11.1)||',NR)');
         else if LowerLimit = . then ci=compress('(NR,'||put(UpperLimit, 11.1)||')');
         else ci=compress('('||put(LowerLimit, 11.1)||','||put(UpperLimit, 11.1)||')');

         if Percent eq 25 then do;s1=4;s2=2;slb='  95% CI';end;
         if Percent eq 50 then do;s1=4;s2=4;slb='  95% CI';end;
         if Percent eq 75 then do;s1=4;s2=6;slb='  95% CI';end;
    run;

 %sort(in=quartiles2,out=quartiles2_1,byvar=s1 s2 slb);

  proc transpose data= quartiles2_1 out=quartiles2_2 (drop=_name_);
    by s1 s2 slb;
    var ci;
    id cohrtcd;
 run;

 /* Post Process*/

 data  qc_t_tte2_os;
     attrib tt_avid   label='';
     attrib tt_avnm   label='~' length=$60 /*format=$60.*/;
     attrib tt_svid   label=''  length=$1  /*format=$1.*/;
     attrib tt_svnm   label='~' length=$40 /*format=$40.*/;
     attrib tt_ac0001 label='Cohort A' length=$40 /*format=$40.*/;
     attrib tt_ac0002 label='Cohort B' length=$40 /*format=$40.*/;
     attrib tt_ac0003 label='Cohort C' length=$40 /*format=$40.*/;
     attrib tt_ac0004 label='Cohort D' length=$40 /*format=$40.*/;
     attrib tt_ac9999 label='Total~(N' length=$40 /*format=$40.*/;
  length a b c d t $ 30;
  set  adtte2_7 quartiles1_2 quartiles2_2; 
   tt_avid=s1;
   if s1=1 then tt_avnm='Number of Subjects';
   else if s1=4 then tt_avnm='Estimates for Time Variable (Months) [1]';
   tt_svid=compress(put(s2,best.));
   if a eq '' then a='0';if b eq '' then b='0';if c eq '' then c='0';if d eq '' then d='0';if t eq '' then t='0';
   tt_svnm=slb;tt_ac0001=compress(a);tt_ac0002=compress(b);tt_ac0003=compress(c);tt_ac0004=compress(d);tt_ac9999=compress(t);
   keep tt_avid  tt_avnm tt_svid tt_svnm tt_ac0001 tt_ac0002  tt_ac0003 tt_ac0004 tt_ac9999;
   if tt_svnm eq 'n' then delete;
 run;
 

proc print data=qc_t_tte2_os;
run;


  /* Get Programer Data*/
   data t_tte2_os ;
      set dddata.t_tte2_os;
      tt_ac0001=compress(tt_ac0001);tt_ac0002=compress(tt_ac0002);tt_ac0003=compress(tt_ac0003);tt_ac0004=compress(tt_ac0004);tt_ac9999=compress(tt_ac9999);
   run;

/*Proc Compare*/
  %sort(in=t_tte2_os,out=t_tte2_os,byvar=tt_avid tt_svid);
  %sort(in=qc_t_tte2_os,out=qc_t_tte2_os,byvar=tt_avid tt_svid);

  proc compare base=t_tte2_os compare=qc_t_tte2_os listall;
   id tt_avid tt_svid;
  run;
