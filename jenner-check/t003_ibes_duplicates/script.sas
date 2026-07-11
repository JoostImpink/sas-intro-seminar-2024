/* Adapted from 5_ibes.sas (JoostImpink/sas-intro-seminar-2025)
   Original matches Compustat firm-years to IBES tickers via a historical
   cusip join against ibes.idsum on WRDS, then investigates and drops the
   duplicate records the join produces. Here getf_3 (their post-CRSP-merge
   working table) and ibes.idsum are supplied as small inline DATA steps
   so the duplicate-detection / dedup logic is unchanged from the source. */

data getf_3;
	length gvkey $6 ncusip $8;
	input gvkey $ fyear datadate :date9. ncusip $;
	format datadate date9.;
	key = gvkey || "_" || fyear;
	datalines;
001004 2011 15MAR2011 02376R10
001004 2012 14MAR2012 02376R10
001045 2011 30JUN2011 38259P50
002001 2012 31DEC2012 45086B10
003210 2013 31JAN2013 74005P10
;
run;

data idsum;
	length cusip $8 ticker $6;
	input cusip $ ticker $ sdates :date9.;
	format sdates date9.;
	datalines;
02376R10 AAL   01JAN2005
02376R10 AALQ  01JAN2011
38259P50 GTC   01JAN1998
45086B10 MMF   01JAN2000
;
run;

/* get ibes ticker (cusip on ibes.idsum is historical) */
proc sql;
  create table getf_4 as
  select distinct a.*, b.ticker as ibes_ticker
  from getf_3 a left join idsum b
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

data getf_4nonmis;
set getf_4;
if missing(ibes_ticker) eq 0;
run;

proc print data=getf_4; title "getf_4: firm-years x matching ibes tickers (has duplicates)"; run;
proc print data=doubles2; title "duplicate keys before dedup"; run;
proc print data=getf_4; title "getf_4 after proc sort nodupkey by gvkey fyear"; run;
