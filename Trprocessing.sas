*** TR RESPONSE PROCESSING;
*1) process supptr;
** transpose for frequency with trseq;
****rename location in supptr;
*****merge data from SUPPTR onto TR records ;
** exclude missing visitnum again;
** process Supptr;
libname sdtmdata "/folders/myfolders/pogram/sdtm";
libname adamdata "/folders/myfolders/define3";

Proc sort data=SDTMData.TR (where=(not missing(VISITNUM))) out=work.TR_in_1;
 By USUBJID TRSEQ;
Run;

**Supptr needs to be merged;

Proc sort data=SDTMData.suppTR out=work.suppTR_in;
 by USUBJID IDVAR IDVARVAL;
run;

proc sort data=work.suppTR_in out=teswtr;
 by qnam;
run;

title "tu";
title "supprtr";

%MACRO FRET  (DIN,INP,wh,tin);

proc freq data=&DIN;
tables &INP /list nocol nocum nopercent norow  missing;
&wh ;
&tin ;
run;

%MEND;

%FRET (teswtr, idvar*qnam*qlabel , title "idvarnam");*
%FRET (teswtr, IDVARVAL);
** transpose for frequency with trseq;
/*
IDVAR   QNAM    QLABEL  Frequency
TRSEQ   LSLOC   Lesion Location 6199
TRSEQ   RDTYPE  Read Type   7854
TRSEQ   REVID   Reviewer ID 6199
TRSEQ   TRLOC1  Organ code 1    56
TRSEQ   TRLOC2  Organ code 2    56
TRSEQ   TRLOC3  Organ code 3    136
TRSEQ   TRLOC4  Organ code 4    136
TRSEQ   TRLOCTX Lesion location 3264
*/
proc transpose data=work.suppTR_in (where=(IDVAR="TRSEQ")) out=work.suppTR_1a;
 by USUBJID IDVAR IDVARVAL;
 var QVAL;
 id QNAM;
 idlabel QLABEL;
run;

***rename location;

Data work.suppTR_1b (drop=IDVAR IDVARVAL _NAME_ _LABEL_);
 Set work.suppTR_1a;
 TRSEQ=input(IDVARVAL, best.);
 rename LSLOC=LSLOC_TR;
Run;

%FRET (suppTR_1b, lsloc: trloc: ,where trloc4 ne "");
 
Proc sort data=work.suppTR_1b;
 By USUBJID TRSEQ;
Run;

******* merge supptr with Tr;
**merge back supptr with transposed 
and location renamed for trseq
end of supptr processing;

Data ADAMDATA.TR_IN_2 work.TR_in_2;
 Merge work.TR_in_1 (in=inTR) work.suppTR_1b;
 By USUBJID TRSEQ;
 If inTR;
 If TRTESTCD="TUMSTATE" then
    LSLOC_TR2=LSLOC_TR;
Run;

proc print data=work.tr_in_2;
where trtestcd IN ("LDIAM" "SUMDIAM" "SUMLDNAD" "SUMNLNLD" "SUMNMLD");
RUN ;


%FRET (tr_in_2, TRGRPID*TRTESTCD*TRTEST, title "seeingtumstate"  );
 
 
/*
Table of Contents
The FREQ Procedure
TRGRPID TRTESTCD    TRTEST  Frequency
    TUMSTATE    Tumor State 5
NEW LDIAM   Longest Diameter    18
NEW SUMDIAM Sum of Diameter 245
NEW SUMNLNLD    Sum Diameters of Non Lymph Node Tumors  242
NEW TLNSA   All Target Lymph Node Short Axis < 10mm 331
NEW TUMSTATE    Tumor State 558
NON-TARGET  SUMDIAM Sum of Diameter 2030
NON-TARGET  SUMNLNLD    Sum Diameters of Non Lymph Node Tumors  1963
NON-TARGET  SUMNMLD Sum of Non-missing Lesion Diameters 60
NON-TARGET  TLNSA   All Target Lymph Node Short Axis < 10mm 2517
NON-TARGET  TUMSTATE    Tumor State 5234
TARGET  ACHNAD  Absolute Change From Nadir  2868
TARGET  LDIAM   Longest Diameter    6794
TARGET  PCHGBL  Percent Change From Baseline    2784
TARGET  PCHGNAD Percent Change From Nadir   2867
TARGET  LDIAM SUMDIAM Sum of Diameter 6638
TARGET  SUMLDNAD    Sum of Diameter at Nadir    2833
TARGET  SUMNLNLD    Sum Diameters of Non Lymph Node Tumors  6069
TARGET  SUMNMLD Sum of Non-missing Lesion Diameters 108
TARGET  TLNSA   All Target Lymph Node Short Axis < 10mm 5539
TARGET  TUMSTATE    Tumor State 6996

*/


%FRET (tr_in_2, TRGRPID*TRTESTCD*TRTEST*TRREASND*TRSTAT*LSLOC_TR2 , WHERE TRGRPID="TARGET" and TRTESTCD="TUMSTATE",
  );

 
/*

TARGET AND TUMSTATE
 
TRGRPID    TRTESTCD    TRTEST  TRREASND    TRSTAT  LSLOC_TR2   Frequency
TARGET TUMSTATE    Tumor State             3264
TARGET TUMSTATE    Tumor State         ABDOMINAL WALL  12
TARGET TUMSTATE    Tumor State         ADRENAL GLANDS, LEFT    6
TARGET TUMSTATE    Tumor State         ADRENAL GLANDS, RIGHT   20
TARGET TUMSTATE    Tumor State         BASAL GANGLIA   83
TARGET TUMSTATE    Tumor State         BRAIN VENTRICLE 13
TARGET TUMSTATE    Tumor State         BRAINSTEM   64
TARGET TUMSTATE    Tumor State         BREAST, LEFT    4
TARGET TUMSTATE    Tumor State         CAUDATE NUCLEUS 31
TARGET TUMSTATE    Tumor State         CEREBELLUM  161
TARGET TUMSTATE    Tumor State         CHEST WALL  12
TARGET TUMSTATE    Tumor State         EXTREMITY   7
TARGET TUMSTATE    Tumor State         FRONTAL LOBE    691
TARGET TUMSTATE    Tumor State         LEPTOMENINGES   5
TARGET TUMSTATE    Tumor State         LIVER   371
TARGET TUMSTATE    Tumor State         LUNG, LEFT  209
TARGET TUMSTATE    Tumor State         LUNG, RIGHT 307
TARGET TUMSTATE    Tumor State         LYMPH NODE, ABDOMINAL   28
TARGET TUMSTATE    Tumor State         LYMPH NODE, AXILLARY, LEFT  10
TARGET TUMSTATE    Tumor State         LYMPH NODE, AXILLARY, RIGHT 55
TARGET TUMSTATE    Tumor State         LYMPH NODE, EXTERNAL ILIAC, LEFT    29
TARGET TUMSTATE    Tumor State         LYMPH NODE, EXTERNAL ILIAC, RIGHT   23
TARGET TUMSTATE    Tumor State         LYMPH NODE, HILAR, LEFT 11
TARGET TUMSTATE    Tumor State         LYMPH NODE, HILAR, RIGHT    18
TARGET TUMSTATE    Tumor State         LYMPH NODE, INGUINAL, LEFT  8
TARGET TUMSTATE    Tumor State         LYMPH NODE, INGUINAL, RIGHT 19
TARGET TUMSTATE    Tumor State         LYMPH NODE, MEDIASTINAL 52
TARGET TUMSTATE    Tumor State         LYMPH NODE, MESENTERIC  9
TARGET TUMSTATE    Tumor State         LYMPH NODE, NECK    8
TARGET TUMSTATE    Tumor State         LYMPH NODE, OTHER   10
TARGET TUMSTATE    Tumor State         LYMPH NODE, PELVIC  5
TARGET TUMSTATE    Tumor State         LYMPH NODE, RETROPERITONEAL 37
TARGET TUMSTATE    Tumor State         LYMPH NODE, SUBCARINAL  18
TARGET TUMSTATE    Tumor State         LYMPH NODE, THORACIC    12
TARGET TUMSTATE    Tumor State         MESENTERY   5
TARGET TUMSTATE    Tumor State         MUSCLE  26
TARGET TUMSTATE    Tumor State         OCCIPITAL LOBE  157
TARGET TUMSTATE    Tumor State         OTHER, EXTRANODAL   54
TARGET TUMSTATE    Tumor State         OTHER, SPECIFY  32
TARGET TUMSTATE    Tumor State         PARIETAL LOBE   323
TARGET TUMSTATE    Tumor State         RETROPERITONEUM 22
TARGET TUMSTATE    Tumor State         SKIN    39
TARGET TUMSTATE    Tumor State         SOFT TISSUE 14
TARGET TUMSTATE    Tumor State         SPLEEN  74
TARGET TUMSTATE    Tumor State         SUBCUTANEOUS    114
TARGET TUMSTATE    Tumor State         TEMPORAL LOBE   316
TARGET TUMSTATE    Tumor State         THALAMUS    6
TARGET TUMSTATE    Tumor State NOT ASSESSABLE  NOT DONE    BRAIN VENTRICLE 2
TARGET TUMSTATE    Tumor State NOT ASSESSABLE  NOT DONE    CAUDATE NUCLEUS 1
TARGET TUMSTATE    Tumor State NOT ASSESSABLE  NOT DONE    FRONTAL LOBE    9
TARGET TUMSTATE    Tumor State NOT ASSESSABLE  NOT DONE    LUNG, LEFT  4
TARGET TUMSTATE    Tumor State NOT ASSESSABLE  NOT DONE    LUNG, RIGHT 3
TARGET TUMSTATE    Tumor State NOT ASSESSABLE  NOT DONE    LYMPH NODE, AXILLARY, RIGHT 1
TARGET TUMSTATE    Tumor State NOT ASSESSABLE  NOT DONE    LYMPH NODE, HILAR, LEFT 1
TARGET TUMSTATE    Tumor State NOT ASSESSABLE  NOT DONE    LYMPH NODE, HILAR, RIGHT    1
TARGET TUMSTATE    Tumor State NOT ASSESSABLE  NOT DONE    LYMPH NODE, INGUINAL, RIGHT 1
TARGET TUMSTATE    Tumor State NOT ASSESSABLE  NOT DONE    LYMPH NODE, MEDIASTINAL 1
TARGET TUMSTATE    Tumor State NOT ASSESSABLE  NOT DONE    OCCIPITAL LOBE  2
TARGET TUMSTATE    Tumor State NOT ASSESSABLE  NOT DONE    OTHER, SPECIFY  2
TARGET TUMSTATE    Tumor State NOT ASSESSABLE  NOT DONE    PARIETAL LOBE   3
TARGET TUMSTATE    Tumor State NOT ASSESSABLE  NOT DONE    SOFT TISSUE 1
TARGET TUMSTATE    Tumor State NOT ASSESSABLE  NOT DONE    TEMPORAL LOBE   5
TARGET TUMSTATE    Tumor State NOT ASSESSABLENOT ASSESSABLE - DIFFERENT MODALITY USED AT THIS VISIT TO ASSESS DISEASE  NOT DONE        2
TARGET TUMSTATE    Tumor State NOT ASSESSABLENOT ASSESSABLE - DIFFERENT MODALITY USED FOR DISEASE ASSESSMENT   NOT DONE        1
TARGET TUMSTATE    Tumor State NOT ASSESSABLENOT ASSESSABLE - DIFFERENT MODALITY USED TO ASSESS DISEASE    NOT DONE        1
TARGET TUMSTATE    Tumor State NOT ASSESSABLENOT ASSESSABLE - DIFFERNET MODALITY USED FOR DISEASE ASSESSMENT   NOT DONE        1
TARGET TUMSTATE    Tumor State NOT ASSESSABLENOT ASSESSABLE - LESION PUNCTIFORM    NOT DONE        2
TARGET TUMSTATE    Tumor State NOT ASSESSABLENOT ASSESSABLE - MULTIPLE HEMORRHAGIC AREAS MAKE MEASUREMENT DIFFICULT. MEASUREMENT INCLUDES BOTH HEMORRHAGIC AREAS AND TUMOR.    NOT DONE        1
TARGET TUMSTATE    Tumor State NOT ASSESSABLENOT ASSESSABLE - MULTIPLE HEMORRHAGIC AREAS; HOWEVER, THIS LESION NO LONGER HAS ENHANCEMENT.  NOT DONE        1
TARGET TUMSTATE    Tumor State NOT ASSESSABLENOT ASSESSABLE - NO EVALUABLE NOT DONE        1
TARGET TUMSTATE    Tumor State NOT ASSESSABLENOT ASSESSABLE - NOT CLEARLY VISIBLE ON SCAN IMAGE    NOT DONE        1
TARGET TUMSTATE    Tumor State NOT ASSESSABLENOT ASSESSABLE - NOT EVALUABLE    NOT DONE        2
TARGET TUMSTATE    Tumor State NOT ASSESSABLENOT ASSESSABLE - THE CHANGES ON THE MRI WERE TREATMENT-RELATED. AS THE CHANGES WERE TREATMENT-RELATED, WE ARE UNABLE TO PROVIDE MEASUREMENTS OF NON-TREATMENT-RELATED GROWTH SO I ENTERED NOT DONE        1
TARGET TUMSTATE    Tumor State NOT ASSESSABLENOT ASSESSABLE - THE LESION WAS OPERATED WITH THE APPROVAL OF MEDICAL MONITOR NOT DONE        2
TARGET TUMSTATE    Tumor State NOT ASSESSABLENOT ASSESSABLE - THE SLICE POSITION WAS THE REASON LESION WAS THOUGHT TO HAVE DISAPPEARED - UPON RE-REVIEW, IT WAS CONFIRMED IT WAS PRESENT ALL ALONG-NO MEASUREMENTS PROVIDED    NOT DONE        4
TARGET TUMSTATE    Tumor State SCAN NOT PERFORMED  NOT DONE        30
TARGET TUMSTATE    Tumor State SCAN NOT PERFORMED  NOT DONE    ADRENAL GLANDS, LEFT    1
TARGET TUMSTATE    Tumor State SCAN NOT PERFORMED  NOT DONE    ADRENAL GLANDS, RIGHT   2
TARGET TUMSTATE    Tumor State SCAN NOT PERFORMED  NOT DONE    BASAL GANGLIA   2
TARGET TUMSTATE    Tumor State SCAN NOT PERFORMED  NOT DONE    BRAINSTEM   1
TARGET TUMSTATE    Tumor State SCAN NOT PERFORMED  NOT DONE    BREAST, LEFT    1
TARGET TUMSTATE    Tumor State SCAN NOT PERFORMED  NOT DONE    CAUDATE NUCLEUS 1
TARGET TUMSTATE    Tumor State SCAN NOT PERFORMED  NOT DONE    CEREBELLUM  5
TARGET TUMSTATE    Tumor State SCAN NOT PERFORMED  NOT DONE    FRONTAL LOBE    10
TARGET TUMSTATE    Tumor State SCAN NOT PERFORMED  NOT DONE    LIVER   12
TARGET TUMSTATE    Tumor State SCAN NOT PERFORMED  NOT DONE    LUNG, LEFT  7
TARGET TUMSTATE    Tumor State SCAN NOT PERFORMED  NOT DONE    LUNG, RIGHT 18
TARGET TUMSTATE    Tumor State SCAN NOT PERFORMED  NOT DONE    LYMPH NODE, AXILLARY, LEFT  1
TARGET TUMSTATE    Tumor State SCAN NOT PERFORMED  NOT DONE    LYMPH NODE, AXILLARY, RIGHT 5
TARGET TUMSTATE    Tumor State SCAN NOT PERFORMED  NOT DONE    LYMPH NODE, INGUINAL, RIGHT 1
TARGET TUMSTATE    Tumor State SCAN NOT PERFORMED  NOT DONE    LYMPH NODE, MEDIASTINAL 3
TARGET TUMSTATE    Tumor State SCAN NOT PERFORMED  NOT DONE    LYMPH NODE, MESENTERIC  1
TARGET TUMSTATE    Tumor State SCAN NOT PERFORMED  NOT DONE    LYMPH NODE, NECK    1
TARGET TUMSTATE    Tumor State SCAN NOT PERFORMED  NOT DONE    LYMPH NODE, RETROPERITONEAL 1
TARGET TUMSTATE    Tumor State SCAN NOT PERFORMED  NOT DONE    OCCIPITAL LOBE  5
TARGET TUMSTATE    Tumor State SCAN NOT PERFORMED  NOT DONE    PARIETAL LOBE   8
TARGET TUMSTATE    Tumor State SCAN NOT PERFORMED  NOT DONE    RETROPERITONEUM 1
TARGET TUMSTATE    Tumor State SCAN NOT PERFORMED  NOT DONE    SKIN    2
TARGET TUMSTATE    Tumor State SCAN NOT PERFORMED  NOT DONE    SOFT TISSUE 1
TARGET TUMSTATE    Tumor State SCAN NOT PERFORMED  NOT DONE    SPLEEN  3
TARGET TUMSTATE    Tumor State SCAN NOT PERFORMED  NOT DONE    SUBCUTANEOUS    14
TARGET TUMSTATE    Tumor State SCAN NOT PERFORMED  NOT DONE    TEMPORAL LOBE   8

 TARGET  Tumor State TUMSTATE    SCAN NOT PERFORMED  NOT DONE    TEMPORAL LOBE   8   0.11    6996    100.00
*/


proc freq data=TR_in_2;
 tables TRGRPID*trtest*trtestcd*TRREASND*TRSTAT*LSLOC_TR2 /list missing;
 WHERE TRGRPID ^="TARGET" and TRTESTCD ^="TUMSTATE";
 title "NOT TARGET NOT TUMSTATE";
run;
/*
NOT TARGET NOT TUMSTATE
 
TRGRPID TRTEST  TRTESTCD    TRREASND    TRSTAT  LSLOC_TR2    
NEW All Target Lymph Node Short Axis < 10mm TLNSA               331 4.47    331 4.47
NEW Longest Diameter    LDIAM               18  0.24    349 4.71
NEW Sum Diameters of Non Lymph Node Tumors  SUMNLNLD                242 3.27    591 7.98
NEW Sum of Diameter SUMDIAM             245 3.31    836 11.29
NON-TARGET  All Target Lymph Node Short Axis < 10mm TLNSA               2517    33.99   3353    45.27
NON-TARGET  Sum Diameters of Non Lymph Node Tumors  SUMNLNLD                1963    26.51   5316    71.78
NON-TARGET  Sum of Diameter SUMDIAM             2030    27.41   7346    99.19
NON-TARGET  Sum of Non-missing Lesion Diameters SUMNMLD             60  0.81    7406    100.00
*/

** for trtestcd  ldiam and tumstate subset not missing trlinkid

  visitnum set AS TR_IN -- WHICH GOES INTO MERGE LATER BELOW;

Proc sort data=work.TR_in_2
  (keep=USUBJID TRSEQ TREVAL TRLNKID TRLNKGRP TRGRPID TRTESTCD TRTEST TRSCAT 
    TRSTRESC TRSTRESN TRREASND TRMETHOD VISITNUM VISIT TRDTC TRBLFL TRLOC TRSTAT 
    TRLOCTX LSLOC_TR LSLOC_TR2 REVID TRLOC3 TRLOC4 RDTYPE TRLOC1 TRLOC2 
   ) 
    out=work.TR_in;
 By USUBJID TREVAL TRLNKID TRLNKGRP TRGRPID TRSCAT TRMETHOD VISITNUM VISIT 
    TRDTC TRBLFL TRLOC;
     where TRTESTCD in ("LDIAM", "TUMSTATE") 
     and TREVAL in ("INVESTIGATOR" , 
    "INDEPENDENT ASSESSOR") 
    and not missing(TRLNKID) 
    and not missing(VISITNUM) ; 
Run;

Proc sort data=work.TR_in_2;
 By USUBJID TREVAL TRLNKID TRLNKGRP TRGRPID TRSCAT TRMETHOD VISITNUM VISIT 
    TRDTC TRBLFL TRLOC;
Run;

*TR_IN- IS FIRST SUBSET OF trtestcd  ldiam and tumstate subset not missing trlinkid
 visitnum;
** for Target+ ldiam;
**for New, NT + tumstate 
19605 -- 12586 recrods set to after ;
**TR_IN IS MUTUALLY EXCLUSIVE FROM TR_IN2  56699--> 6996 records after subset;
*TR_IN_2- IS FULL DATA OF SUPPTR MERGE COMPLETE 
 they rename 4 varibales TRSTRESC = LSTATUS  TRREASND=TRREASND_2  TRSTAT=TRSTAT_2  TRTESTCD=TRTESTCD2;
* TARGET + TUMSTATE ;
* exclude lstatusu and reason nd should not be missing;
*FOUR VARIABLES ARE RENAMED -TRSTRESC = LSTATUS  TRREASND=TRREASND_2  TRSTAT=TRSTAT_2  TRTESTCD=TRTESTCD2;

Data work.TR_1;
 Merge
 
 work.TR_in (where=((TRGRPID="TARGET" and TRTESTCD="LDIAM") or
(TRGRPID in ("NEW",  "NON-TARGET") and TRTESTCD="TUMSTATE"))) 
    
    
    work.TR_in_2 (where=(TRGRPID="TARGET" and TRTESTCD2="TUMSTATE" 
    and (not 
    missing(LSTATUS) or not missing(TRREASND_2)) ) 
    
    keep=USUBJID TREVAL TRLNKID 
    TRLNKGRP TRGRPID TRSCAT TRSTRESC TRREASND TRMETHOD VISITNUM VISIT TRDTC 
    TRBLFL TRLOC TRSTAT TRTESTCD LSLOC_TR2 
    
    rename=(
    TRSTRESC=LSTATUS 
    TRREASND=TRREASND_2 
    TRSTAT=TRSTAT_2 
    TRTESTCD=TRTESTCD2));
    
    
 By USUBJID TREVAL TRLNKID TRLNKGRP TRGRPID TRSCAT TRMETHOD VISITNUM VISIT 
    TRDTC TRBLFL TRLOC;

 If TRGRPID="NEW" and missing(TRSCAT) and not missing(TRLOC) then
    do;

        If TRLOC="BRAIN" then
            TRSCAT="BRAIN";
        Else
            TRSCAT="EXTRACRANIAL";
    End;

 If TRSTAT_2="NOT DONE" and missing(TRTESTCD) then
    do;
        TRTESTCD="LDIAM";
        TRTEST="Longest Diameter";
    End;
Run;

*12586 observations read from the data set WORK.TR_IN.;
* There were 6996 observations read from the data set WORK.TR_IN_2.;
*but there are 12788 observations and 34 variables. see why there are 200 extra records;
* Checking for duplicates in TR (from the merge above);

proc sort data=work.TR_in (where=

(

(TRGRPID="TARGET" and TRTESTCD="LDIAM") 
or
(TRGRPID in ("NEW", "NON-TARGET") and TRTESTCD="TUMSTATE")
)
) out=LDIAM dupout=dupes_LDIAM 
    nodupkey;
 By USUBJID TREVAL TRGRPID TRSCAT TRLNKID TRLNKGRP VISITNUM TRMETHOD TRDTC;
run;

proc sort data=work.TR_in (
where=(TRGRPID="TARGET" 
and TRTESTCD2="TUMSTATE" 
and 
not missing(STATUS) 
    ) keep=USUBJID TREVAL TRGRPID TRSCAT TRLNKID TRLNKGRP 
    VISITNUM TRMETHOD TRDTC TRTESTCD TRSTRESC 
    
    rename=(
    TRSTRESC=STATUS 
    TRTESTCD=TRTESTCD2)
    ) out=TUMSTATE dupout=dupes_TUMSTATE nodupkey;
 By USUBJID TREVAL TRGRPID TRSCAT TRLNKID TRLNKGRP VISITNUM TRMETHOD TRDTC;
run;

* End TR duplicate check;

Proc sort data=work.TR_1;
 By USUBJID TRSEQ;
Run;

Proc sort data=work.TR_1;
 By USUBJID TREVAL TRSCAT TRMETHOD VISITNUM TRLNKID TRLOC;
Run;

Proc sort data=work.TU_2;
 By USUBJID TREVAL TRSCAT TRMETHOD VISITNUM TRLNKID TULOC;
Run;