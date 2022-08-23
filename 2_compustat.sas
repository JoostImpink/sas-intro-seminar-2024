
/* Some Compustat Funda data 
see 'variables' tab for variable descriptions
https://wrds-web.wharton.upenn.edu/wrds/ds/compd/funda/index.cfm?navId=83
*/
data getf_1 (keep = gvkey conm fyear datadate sich cik cusip tic exchg mcap);
set comp.funda;
if fyear > 2000;
mcap = prcc_f * csho; /* calculate market cap as stock price x #shares outstanding */
if indfmt='INDL' and datafmt='STD' and popsrc='D' and consol='C' ;
run;

/* inspect */

/* cusip american airlines: 02376R102 - starting at row 53 */

/* let's look that up in crsp.dsenames */

/* first take a look at crsp.dsenames
https://wrds-www.wharton.upenn.edu/data-dictionary/crsp_a_stock/dsenames/
 */
data dse;
set crsp.dsenames;
run;

/* note that there is ncusip and cusip in crsp.dsenames
cusip: current cusip
ncusip: historical cusip

both have length 8 
digits 1-6: identifies firm
digits 7-8: identifies security (class A, class B, a loan, etc)
digit 9: checksum (catches typos)
*/

data dse_amr;
set crsp.dsenames;
if cusip eq "02376R10"; /* dropped the checksum */
run;

/* look at ticker symbol, company name, and ncusip -- changing quite a bit */

/* Compustat has header (current) variables, showing todays values for all records
(so a change in one year leads to updates to the new value in all prior years)
=> this is a good reason not to use many variables in Compustat!
(when you want to match with a dataset that has historical variables) */

/* how can you tell if some variable is a header variable or not?
-> it will have the same value for all years for each firm */

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
	create tabele test3 as select numCiks, count(*) as c from test2 group by numCiks;
quit;

/* how often is cik missing? 
check the log: #obs in getf_1 vs #obs in test4
look at the table -- by the way - check variable sich - how does that look like?
*/ 
data test4;
set getf_1;
if  missing(cik) eq 1; /* keep the obw with missing cik*/
run;

/* are missings less of an issue for larger firms? */
proc sql;
	create table test5 as select gvkey, fyear, datadate, missing(cik) as cik_miss, 
	/* create dummy variable large, which is 1 if mcap is larger than median mcap (by year)*/
	( mcap > median(mcap) ) as large
	from getf_1 
	where missing(mcap) eq 0
	group by fyear;
quit;

/* let's use proc means for descriptive stats */
proc sort data=test5;by large;run;
proc means data=test5 n mean median stddev;
  OUTPUT OUT=test6 n= mean= median= stddev= /autoname;
  var cik_miss;
  by large;
run;

/* We are subscribed to SEC WRDS Analytics Suite. It allows free text search in SEC filings,
but it also has linktables (gvkey -> CIK, etc)
Let's see if we can get some of the missing CIKs with that table: wrdssec.wciklink_gvkey 
https://wrds-web.wharton.upenn.edu/wrds/ds/sec/wciklink_gvkey/gvkeycik.cfm?navId=360

need to get cik for gvkey with datadate between:
DATADATE1	DATE	First Date of Compustat Data	
DATADATE2	DATE	Last Date of Compustat Data
*/

/* get large firms with missing cik: 13,369 obs */
data test7;
set test5;
if large eq 1 and cik_miss eq 1;
run;

/* get cik on linktable -- 1,247 match */
proc sql;
	create table test8 as select a.*, b.cik 
	from test7 a, wrdssec.wciklink_gvkey b
	where a.gvkey = b.gvkey
	/* datadate needs to be in the date range */
	and b.datadate1 <= a.datadate <= b.datadate2
	/* we don't want to get missing ciks */
	and missing(b.cik) eq 0;
quit;

/* dataset with filing details 
R:\FSOA-Folders\DataLibrary\datasets\SEC 10K Filings

*/

