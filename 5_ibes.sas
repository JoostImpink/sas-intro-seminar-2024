/* Funda data */
data getf_1 (keep = gvkey conm fyear key datadate sich cik cusip tic exchg mcap);
set comp.funda;
if fyear > 2010; /* after 2010 */
mcap = prcc_f * csho; /* calculate market cap as stock price x #shares outstanding */
if indfmt='INDL' and datafmt='STD' and popsrc='D' and consol='C' ;
/* gvkey and fyear in a single variable (comes in handy later on) */
key = gvkey || "_" || fyear;
run;

/* Permno as of datadate*/
proc sql; 
  create table getf_2 as 
  select a.*, b.lpermno as permno
  from getf_1 a left join crsp.ccmxpf_linktable b 
    on a.gvkey eq b.gvkey 
    and b.lpermno ne . 
    and b.linktype in ("LC" "LN" "LU" "LX" "LD" "LS") 
    and b.linkprim IN ("C", "P")  
    and ((a.datadate >= b.LINKDT) or b.LINKDT eq .B) and  
       ((a.datadate <= b.LINKENDDT) or b.LINKENDDT eq .E)   ; 
quit; 

/* retrieve historic cusip */
proc sql;
  create table getf_3 as
  select a.*, b.ncusip
  from getf_2 a left join crsp.dsenames b
  on 
        a.permno = b.PERMNO
    and b.namedt <= a.datadate <= b.nameendt
    and b.ncusip ne "";
  quit;
 
/* force unique records 
This doesn't drop anything which is good. Otherwise we would need to investigate */
proc sort data=getf_3 nodupkey; by gvkey fyear;run;
 
/* get ibes ticker (cusip on ibes.idsum is historical) */
proc sql;
  create table getf_4 as
  select distinct a.*, b.ticker as ibes_ticker
  from getf_3 a left join ibes.idsum b
  on 
        a.NCUSIP = b.CUSIP
    and a.datadate > b.SDATES ;
quit;
/* the last step (getting ibes ticker) gave a few duplicate records 
	let's look at how these duplicates look like
*/

/* make a dataset with each key and how many records there are for that key 
only include if multiple */
proc sql;
	create table doubles as 
	select key, count(*) as numObs from getf_4 group by key having numObs > 1;
quit;

/* now get the records that have the doubles */
proc sql;
	create table doubles2 as
	select * from getf_4 where key in (select key from doubles);
quit;


/* force unique records if you don't care about which of the double is the correct one
probably better approach is to keep both, try to get data for both, and see if there are still
any duplicates left  */

/* for now, let's drop the duplicates to our dataset has the same length */
proc sort data=getf_4 nodupkey; by gvkey fyear;run;

/* crsp-ibes gives 45,972 ibes tickers (out of 114,041 firmyears) */
data getf_4nonmis;
set getf_4;
if missing(ibes_ticker) eq 0;
run;

/* lets use iclink macro (creates a permno-ibes ticker linktable) 
copy/paste this code:
https://wrds-www.wharton.upenn.edu/pages/support/research-wrds/macros/wrds-macro-iclink/

copy it into a new sas file (or existing one) and press F3 to run it

*/
/* let's assign a library where to store the output
  make sure this folder exists
 */
libname myLib "~/today";

/* invoke it (note: run the macro code first) 
you can also run: %iclink;
this will create work.iclink (so in the work library)
*/
%iclink(outset=myLIb.iclink);

/* inspect iclink*/

/* merge iclink ibes ticker (so now we have both) */
proc sql;
	create table getf_5 as 
	select a.*, b.ticker as iclink_ibes, b.score as iclink_score
	from getf_4 a left join myLib.iclink b /* or work.iclink if it is in the work folder */
	on a.permno eq b.permno
	and missing(b.ticker) eq 0;
quit;

/* iclink gives 51,621 ibes tickers */
data getf_6;
set getf_5;
if missing(iclink_ibes) eq 0;
run;

/* iclink gives 50,777 ibes tickers with match score of 0 and 1 (arbitrary)*/
data getf_6;
set getf_5;
if missing(iclink_ibes) eq 0;
if iclink_score <= 1;
run;

