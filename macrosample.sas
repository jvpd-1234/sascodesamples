%LET ok=yes;

DATA example_1a ; LENGTH check2 $5;

check1 = SYMGET('ok') ;

check2 = SYMGET('ok') ;

check3 = "&ok";

check4 = SYMGET('ok') ;

LENGTH check4 $3 ; RUN;


* Duration of exercise each day of week;

%LET time1=2.0;

%LET time2=1.0;

%LET time3=0.5;

%LET time4=0.6;

%LET time5=0.2;

%LET time6=1.0;

%LET time7=1.2;

* Exercise planned for each day of week ;

%let sport1 =bike;

%let sport2 =walk;

%let sport3 =jog;

%let sport4 =stretch;

%let sport5 =bike;

%let sport6 =swim;

%let sport7 =walk;

%LET hard=650; %LET moderate=375; %LET easy=240;

DATA eachday
wholeweek 
(KEEP = calsofar timesofar RENAME = (calsofar=calperweek timesofar=hrsperweek));
DO day = 1 TO 7;
LENGTH sport intensity $8 ; 
sport = SYMGET('sport'||LEFT(day)) ;
IF sport IN ('bike','swim','jog') THEN intensity = 'hard';
ELSE IF sport IN ('walk','dance') THEN intensity = 'moderate' ;
ELSE IF sport IN ('stretch','golf') THEN intensity = 'easy' ;
put sport intensity day;
cal_num = INPUT(SYMGET(intensity),4.) ;
time = INPUT(SYMGET('time'||LEFT(day)),6.1) ;
totalcal = time*cal_num ; 
calsofar = SUM(calsofar, totalcal) ;
timesofar = SUM(timesofar, time) ; 
RETAIN calsofar timesofar ; 
OUTPUT eachday ;
IF DAY = 7 THEN OUTPUT wholeweek ;
END;
RUN;

proc print;
run;