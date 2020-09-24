data have;

array d1_p(7);

array d1_s(7);

do i=1 to 5;

do j=1 to 7;

   d1_p(j) = ceil(50*ranuni(1234));

   d1_s(j) = ceil(50*ranuni(1234));

end;

   output;

end;

drop i j;

run;

proc print data=have;

run;

* add new variables x1-x49 based on the values of d1_p and d1_s;

data want;

array p(7)   d1_p1-d1_p7;

array s(7)   d1_s1-d1_s7;

* as suggested by KSharp ... array with two dimensions;

array x(7,7) x1-x49;

put  x1 -x5 ;

set have;

do i=1 to 7;

do j=1 to 7;

* logical 1s (condition true) and 0s (condition false) ;

   x(i,j) = p(i) * s(j) ;

end;

end;

put  x1= d1_p1= d1_s1=;

*drop i j;

run;

proc print data=want;

run;