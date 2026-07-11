/* Adapted from 4_audit_analytics.sas (JoostImpink/sas-intro-seminar-2025)
   Original joins Compustat firm-years to Audit Analytics audit fee data
   (audit.auditfees) via a remote WRDS libname; here the same table shape
   is supplied as a small inline DATA step so the join / sort / aggregate
   logic below is unchanged from the source script. */

data getf_1;
	length gvkey $6;
	input gvkey $ fyear datadate :date9. cik exchg;
	format datadate date9.;
	datalines;
001004 2001 15MAR2001 320193 11
001004 2002 14MAR2002 320193 11
001045 2001 30JUN2001 1234567 14
001045 2002 30JUN2002 1234567 14
002001 2001 31DEC2001 850001 12
002001 2002 31DEC2002 850001 12
003210 2001 31JAN2001 909800 11
003210 2002 31JAN2002 909800 11
;
run;

data auditfees;
	input company_fkey fiscal_year_ended :date9. fiscal_year auditor_fkey audit_fees;
	format fiscal_year_ended date9.;
	datalines;
320193 12MAR2001 2001 501 850000
320193 10MAR2002 2002 501 875000
320193 08MAR2002 2002 502 50000
1234567 27JUN2001 2001 610 210000
850001 28DEC2001 2001 720 640000
850001 27DEC2002 2002 720 655000
;
run;

/* Merging Compustat and Audit Analytics (audit fee)
	cik on Audit Analytics is company_fkey
	there is also auditor_fkey, which is not related to ciks

	End of fiscal year date in Audit fee dataset is 'fiscal_year_ended'
*/

proc sql;
	create table aa_fee as
		select a.*, b.audit_fees, b.FISCAL_YEAR, b.AUDITOR_FKEY as fee_AUDITOR_FKEY
		from getf_1 a left join auditfees b
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
/* note rows with multiple audit fee candidates for the same firm-year */

/* unique firm-years: keep highest audit fee */
proc sort data = aa_fee; by gvkey fyear descending audit_fees; run;
proc sort data = aa_fee nodupkey; by gvkey fyear ; run;

data nonmiss2;
set aa_fee;
if missing(audit_fees) eq 0;
run;

/* missing audit fee data by exchange
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

proc print data=aa_fee_nonmiss; title "firm-years matched with a non-missing audit fee"; run;
proc print data=aa_exchg2; title "missing audit fee rate by exchange"; run;
