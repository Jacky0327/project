dm 'log;clear;output;clear';
proc datasets lib=Work kill;quit;

/*TABEL2*/
proc import datafile = "C:\Users\USER\Desktop\deriviative\Data for Replicating Qin et al. (2019).xlsx" out = data1 dbms = xlsx replace;
	sheet = "All Variables";
	getnames = YES;
run;

proc univariate data = data1;
	title TABEL2(OSE);
	var FUTURESRET;
	/*output out = TABEL2 mean = Mean std = SD skewness = Skewness kurtosis = Kurtosis N = n;*/
run; 

proc univariate data = data1;
	title TABEL2(S);
	var SPOTRET;
	/*output out = TABEL2 mean = Mean std = SD skewness = Skewness kurtosis = Kurtosis N = n;*/
run; 


/*TABEL3*/
data data3;
	set data1;
	DATE1 = COMPRESS(Date, "-");
	MATURITY1 = COMPRESS(Maturity, "-");
	YEAR = year(Date);
	MONTH = month(Date);
run;

proc sort data = data3;
	by YEAR;
run;

proc import datafile = "C:\Users\USER\Desktop\deriviative\Nikkie 225 dividend yield from Bloomberg From 1996.xlsx" out=div dbms = xlsx replace;
	sheet = "工作表1";
	getnames = YES;
run;

data div1 ;
	set div;
	DATE1 = COMPRESS(Date, "/");
	YEAR = year(Date);
	DIVY = 0.01*EQY_DVD_YLD_12M;
	drop EQY_DVD_YLD_12M;
run;

proc sort data = div1;
	by YEAR;
run;

data test;
	merge div1 data3;
	by YEAR;
	if SPOT='.' then delete;
run;

data test;
	set test;
	Ft = SPOT*EXP((0.01*VAR4-DIVY)*((MATURITY1-DATE1)/365));/*VAR4是RISKFREE的LABEL名*/
	Mist = (FUTURES-Ft)/SPOT;
run;

proc sort data = test;
	by YEAR;
run;

data try;
	set test;
	by YEAR ;
	if last.YEAR then DIVSPOT = SPOT;
	if DIVSPOT ='.' then delete;
run;

proc sort data = try;
	by YEAR;
run;

data test;
	merge try test;
	by YEAR;
run;

data test;
	set test;
	DIV = DIVSPOT*(DIVY/20);
run;

proc sort  data = test;
	by Date MONTH;
run;

data test;
	set test;
	if  MONTH not in (6,12) then DIV =0;
run;


data tt;
	set test;
	where (MONTH in (12));
run;

data tt1;
	set tt;
	by YEAR MONTH;
	if first.MONTH then no = 0;
	no+1;
run;

data tt2;
	set tt1;
	where(1<=no<=10 & 1996<=YEAR<=2014) ;
	TDIV=DIV*EXP(0.01*VAR4*((MATURITY1-DATE1)/365));
run;

proc sort data = tt2;
	by YEAR descending no ;
run;

data tt2;
set tt2;
by YEAR descending no ;
retain total 0 ;
IF first.YEAR then total= TDIV;
else total = TDIV+total;/*計算12月發放股利的日子*/
run;


proc sort data= tt2;
	by Date MONTH;
run;

data tt3;
	merge tt2 test;
	by Date MONTH;
run;


data tt4;
	set test;
	where (MONTH in (6));
run;

proc sort data= tt4;
	by descending Date1 ;
run;

data tt5;
	set tt4;
	by descending YEAR MONTH;
	if first.MONTH then no = 0;
	no+1;
run;

data tt6;
	set tt5;
	where(1<=no<=10 & 1996<=YEAR<=2014) ;
	TDIV=DIV*EXP(0.01*VAR4*((MATURITY1-DATE1)/365));
run;

proc sort data = tt6;
	by YEAR no ;
run;

data tt6;
set tt6;
by YEAR no ;
retain total 0 ;
IF first.YEAR then total= TDIV;
else total = TDIV+total;/*計算6月發放股利的日子*/
run;

proc sort data= tt6;
	by Date MONTH;
run;

data tt7;
	merge tt6 test;
	by Date MONTH;
run;

data tt8;
	merge tt3 tt7;
	by Date MONTH;
run;

data tt9;
	merge tt6 tt2;
	by MONTH;
run;

proc sort data= tt9;
	by Date MONTH;
run;


data tt10;
	merge tt9 test;
	by Date MONTH ;
run; 

data COC2;
	set tt10;
	if no = '.' then DIV=0;
run;
	
data  maturity12;
	set test;
	MATURITY2 = lag30(MATURITY1);
	if MATURITY2 >= DATE1 then TDIV1=DIV*EXP(0.01*VAR4*((MATURITY2-DATE1)/365));
run;

data maturity12;
	set maturity12;
	where(MONTH in (12) & TDIV1> 0);
run;

data maturity12;
	set maturity12;
	by notsorted YEAR;
	retain total1 0 ;
	IF first.YEAR then total1= TDIV1;
	else total1 = TDIV1+total1;
run;


proc sort data= maturity12;
	by YEAR;
run;

data maturity12;
	set maturity12;
	by YEAR;
	if last.YEAR;
	MATURITY1 = MATURITY2;
	alldiv= total1;/*12月到期前，若有經過12月發放股利的日子，則計入該期間。並把MATURITY2改成MATURITY1以合併*/
run;


data maturity6;
	set tt6;
	by notsorted YEAR;
	if first.YEAR;
	alldiv2= total ;/*6月發放股利前，受該股利總和影響的日子*/
run;

proc sort data = maturity6;
	by YEAR ;
run;

proc sort data = COC2;
	by MATURITY1 ;
run;

data COC22;
	merge maturity12 COC2;
	by MATURITY1;
run;

proc sort data = COC22;
	by MATURITY1 ;
run;

data COC222;
	merge  maturity6 COC22 ;
	by MATURITY1;
run;

data COC222;
	set COC222;
	if no>0 then alldiv2 = 0;
	if MONTH not  in(6) then alldiv2 =0;
run;
	
data COC2222;
	set COC222;
	Ft1 = SPOT*EXP(0.01*VAR4*((MATURITY1-DATE1)/365)) ;
	if total>0 then  
	Ft1 = SPOT*EXP(0.01*VAR4*((MATURITY1-DATE1)/365))-total;
	else if alldiv2>0 then 
	Ft1 = SPOT*EXP(0.01*VAR4*((MATURITY1-DATE1)/365))-alldiv2;
	else if alldiv>0 then
	Ft1 = SPOT*EXP(0.01*VAR4*((MATURITY1-DATE1)/365))-alldiv;
	DIFFERENCE = Ft - Ft1;
	Mist1 = (FUTURES-Ft1)/SPOT; 
	DIFFERENCE1 = Mist - Mist1;
run;


proc univariate data = COC2222;
	title TABEL3(Difference_in_fair_price);
	var DIFFERENCE;
	/*output out = TABEL3 mean = Mean std = SD skewness = Skewness N = n  median =Mid ;*/
run; 


proc univariate data = COC2222 ;
	title TABEL3(Difference_in_futures_mispricing);
	var DIFFERENCE1;
	/*output out = TABEL33 mean = Mean std = SD skewness = Skewness N = n  median =Mid ;*/
run; 

/*TABEL4*/

data TABEL4;
	set COC2222;
	if (MONTH in(6)) and (no = 10) then D1 = 1;
	else D1 = 0;
	if (MONTH in(6)) and (no = 9) then D2 = 1;
	else D2 = 0;
	if (MONTH in(6)) and (no = 8) then D3 = 1;
	else D3  = 0;
	if (MONTH in(6)) and (no = 7) then D4 = 1;
	else D4 = 0;
	if (MONTH in(6)) and (no = 6) then D5 = 1;
	else D5  = 0;
	if (MONTH in(6)) and (no = 5) then D6 = 1;
	else D6  = 0;
	if (MONTH in(6)) and (no = 4) then D7 = 1;
	else D7  = 0;
	if (MONTH in(6)) and (no = 3) then D8 = 1;
	else D8  = 0;
	if (MONTH in(6)) and (no = 2) then D9 = 1;
	else D9  = 0;
	if (MONTH in(6)) and (no = 1) then D10 = 1;
	else D10  = 0;
	if (MONTH in(12)) and (no = 1) then D11 = 1;
	else D11  = 0;
	if (MONTH in(12)) and (no = 2) then D12= 1;
	else D12  = 0;
	if (MONTH in(12)) and (no = 3) then D13 = 1;
	else D13  = 0;
	if (MONTH in(12)) and (no = 4) then D14 = 1;
	else D14  = 0;
	if (MONTH in(12)) and (no = 5) then D15 = 1;
	else D15 = 0;
	if (MONTH in(12)) and (no = 6) then D16 = 1;
	else D16  = 0;
	if (MONTH in(12)) and (no = 7) then D17 = 1;
	else D17  = 0;
	if (MONTH in(12)) and (no = 8) then D18 = 1;
	else D18 = 0;
	if (MONTH in(12)) and (no = 9) then D19 = 1;
	else D19  = 0;
	if (MONTH in(12)) and (no = 10) then D20 = 1;
	else D20  = 0;
run;


proc reg data=TABEL4;
title TABLE4(unrestrictedCOC1);
model Mist= D1 D2 D3 D4 D5 D6 D7 D8 D9 D10 D11 D12 D13 D14 D15 D16 D17 D18 D19 D20 /CLB; 
run;

proc reg data=TABEL4;
title TABLE4(restrictedCOC1);
model Mist= D1 D2 D3 D4 D5 D6 D7 D8 D9 D10  /CLB; 
run;

proc reg data=TABEL4;
title TABLE4(restrictedCOC1);
model Mist1=D11 D12 D13 D14 D15 D16 D17 D18 D19 D20 /CLB; 
run;

proc reg data=TABEL4;
title TABLE4(unrestrictedCOC2);
model Mist1= D1 D2 D3 D4 D5 D6 D7 D8 D9 D10 D11 D12 D13 D14 D15 D16 D17 D18 D19 D20 /CLB; 
run;

proc reg data=TABEL4;
title TABLE4(restrictedCOC2);
model Mist1= D1 D2 D3 D4 D5 D6 D7 D8 D9 D10  /CLB; 
run;

proc reg data=TABEL4;
title TABLE4(restrictedCOC2);
model Mist1=D11 D12 D13 D14 D15 D16 D17 D18 D19 D20 /CLB; 
run;

/*TABEL8*/

data TABEL8;
	set COC2222;
	if Mist1>=0 then VALUE = 'pos';
	else VALUE = 'neg';
	KEEP YEAR Mist1 VALUE ;
run;

proc means data = TABEL8 n mean std maxdec = 6;
	title TABLE8(YEAR);
	class YEAR ;
	var Mist1;
run;



proc means data = TABEL8 n mean  maxdec = 6;
	title TABLE8(YEAR_neg_pos);
	class YEAR VALUE ;
	var Mist1;
run;


proc means data = TABEL8 n mean std maxdec = 6;
	title TABLE8(OVERALL);
	var Mist1;
run;

proc means data = TABEL8  n mean  maxdec = 6;
	title TABLE8(OVERALL_neg_pos);
	class VALUE ;
	var Mist1;
run;
