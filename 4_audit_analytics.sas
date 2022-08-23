
/* Merging Compustat and Audit Analytics (audit fee) 
	cik on Audit Analytics is company_fkey
	there is also auditor_fkey, which is not related to ciks
	
	End of fiscal year date in Audit fee dataset is 'fiscal_year_ended'
*/

proc sql;
	create table aa_fee as
		select a.*, b.audit_fees, b.FISCAL_YEAR, b.AUDITOR_FKEY as fee_AUDITOR_FKEY
		from getf_1 a left join audit.auditfees b
		on a.cik = b.COMPANY_FKEY 
		and missing(a.cik) eq 0
	  	and missing(b.audit_fees) eq 0
      	and a.datadate - 7 < b.fiscal_year_ended < a.datadate + 7;
quit;

data aa_fee_nonmiss;
set aa_fee;
if missing(audit_fees) eq 0;
run;
proc sort data=aa_fee_nonmiss ; by gvkey fyear;run;
/* note rows 21, 22 */

/* unique firm-years: keep highest audit fee */
proc sort data = aa_fee; by gvkey fyear descending audit_fees; run;
proc sort data = aa_fee nodupkey; by gvkey fyear ; run;

/* 212,380 obs in getf_1, 131,285 obs with audit fee */
data nonmiss2;
set aa_fee;
if missing(audit_fees) eq 0;
run;

/* missing audit fee data by exchange 
https://wrds-web.wharton.upenn.edu/wrds/ds/compd/funda/index.cfm?navId=83
variable exchg has '?' => specifies what the numbers mean
11: nyse, 12: amex, 14: nasdaq
*/
data aa_exchg (keep = gvkey fyear exchg miss_audit_fees);
set aa_fee;
miss_audit_fees = missing(audit_fees); /* 1 if missing, 0 otherwise */
run;

proc sql;
	create table aa_exchg2 as 
		select exchg, count(*) as numFirms, sum(miss_audit_fees) / count(*) as perc_miss
		from aa_exchg
		group by exchg
		order by numFirms; 
quit;


/* note: you would typically merge in other datasets:
- audit.auditopin: has the audit opinion (signing auditor, going concern, date of audit completed)
- audit.ACCFILER: accelerated filer status 
- audit.AUDITSOX404: material weakness internal controls
- audit.nt: late filings

Some datasets are better more up to date on Audit Analytics website
(restatements, bankruptcy data) (so you would download these from their website)
*/