/* Adapted from 2_compustat.sas (JoostImpink/sas-intro-seminar-2025)
   Original reads comp.funda from WRDS via a remote libname; here the same
   shape is supplied as a small inline DATA step so the PROC SQL / PROC MEANS
   logic that follows is unchanged from the source script. */

data comp_funda;
	length gvkey $6 conm $32 cusip $9 tic $8;
	input gvkey $ conm $ fyear datadate :date9. sich cik cusip $ tic $ exchg prcc_f csho indfmt $ datafmt $ popsrc $ consol $;
	format datadate date9.;
	datalines;
001004 AIRAMERICA 2001 15MAR2001 4512 . 02376R10 AAL 11 22.50 180.2 INDL STD D C
001004 AIRAMERICA 2002 14MAR2002 4512 320193 02376R10 AAL 11 18.75 181.0 INDL STD D C
001004 AIRAMERICA 2003 13MAR2003 4512 320193 02376R10 AAL 11 12.10 182.4 INDL STD D C
001045 GLOBALTECH 2001 30JUN2001 7372 . 38259P50 GTC 14 5.40 60.0 INDL STD D C
001045 GLOBALTECH 2002 30JUN2002 7372 . 38259P50 GTC 14 6.80 61.5 INDL STD D C
001045 GLOBALTECH 2003 30JUN2003 7372 1234567 38259P50 GTC 14 9.15 63.0 INDL STD D C
002001 MIDCAPMFG 2001 31DEC2001 3559 850001 45086B10 MMF 12 30.00 25.3 INDL STD D C
002001 MIDCAPMFG 2002 31DEC2002 3559 850001 45086B10 MMF 12 28.50 25.9 INDL STD D C
002001 MIDCAPMFG 2003 31DEC2003 3559 850001 45086B10 MMF 12 31.75 26.4 INDL STD D C
002099 SMALLCO   2001 30SEP2001 2836 . 79466L10 SMC 14 2.10 8.0 INDL STD D C
002099 SMALLCO   2002 30SEP2002 2836 . 79466L10 SMC 14 1.85 8.2 INDL STD D C
003210 BIGRETAIL 2001 31JAN2001 5311 909800 74005P10 BIG 11 45.60 210.0 INDL STD D C
003210 BIGRETAIL 2002 31JAN2002 5311 909800 74005P10 BIG 11 51.20 212.5 INDL STD D C
003210 BIGRETAIL 2003 31JAN2003 5311 909800 74005P10 BIG 11 55.00 214.0 INDL STD D C
;
run;

/* Some Compustat Funda data
see 'variables' tab for variable descriptions
https://wrds-web.wharton.upenn.edu/wrds/ds/compd/funda/index.cfm?navId=83
*/
data getf_1 (keep = gvkey conm fyear datadate sich cik cusip tic exchg mcap);
set comp_funda;
if fyear > 2000;
mcap = prcc_f * csho; /* calculate market cap as stock price x #shares outstanding */
if indfmt='INDL' and datafmt='STD' and popsrc='D' and consol='C' ;
run;

/* is CIK a header variable? */
/* first create a table with all unique gvkey-cik combinations */
proc sql;
	create table test as select distinct gvkey, cik from getf_1;
quit;
/* then, count how many ciks for each gvkey */
proc sql;
	create table test2 as select gvkey, count(*) as numCiks from test
	group by gvkey;
quit;
/* tabulate numCiks: how many gvkeys have one cik, two ciks, three ciks, etc */
proc sql;
	create table test3 as select numCiks, count(*) as c from test2 group by numCiks;
quit;

/* how often is cik missing?
check the log: #obs in getf_1 vs #obs in test4
look at the table -- by the way - check variable sich - how does that look like?
*/
data test4;
set getf_1;
if  missing(cik) eq 1; /* keep the obs with missing cik*/
run;

/* are missings less of an issue for larger firms? */
/* compute the by-year median mcap first (same statistic the original
   single-pass remerge query derives), then bring it back onto the detail
   rows -- equivalent two-step form of "mcap > median(mcap) by fyear" */
proc means data=getf_1 noprint;
	where missing(mcap) eq 0;
	class fyear;
	var mcap;
	output out=yearmed(where=(_type_=1) drop=_type_ _freq_) median=med_mcap;
run;

proc sql;
	create table test5 as select a.gvkey, a.fyear, a.datadate, missing(a.cik) as cik_miss,
	/* create dummy variable large, which is 1 if mcap is larger than median mcap (by year)*/
	( a.mcap > b.med_mcap ) as large
	from getf_1 a left join yearmed b
	on a.fyear = b.fyear
	where missing(a.mcap) eq 0;
quit;

/* let's use proc means for descriptive stats */
proc sort data=test5;by large;run;
proc means data=test5 n mean median stddev;
  OUTPUT OUT=test6 n= mean= median= stddev= /autoname;
  var cik_miss;
  by large;
run;

proc print data=test3; title "numCiks per gvkey"; run;
proc print data=test4; title "rows with missing cik"; run;
proc print data=test6; title "cik_miss by large-firm flag"; run;
