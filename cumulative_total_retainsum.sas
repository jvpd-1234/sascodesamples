
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
