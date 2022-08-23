/*
	Note: below code is for a local install of SAS to work with WRDS

	If you use SAS Studio, you don't need rsubmit, etc
	(because SAS Studio is hosted by WRDS and has 'direct' access to the data

	link to SAS Studio: https://wrds-cloud.wharton.upenn.edu/SASStudio/

*/

/*
  remote access: setup
*/
%let wrds = wrds.wharton.upenn.edu 4016;options comamid = TCP remote=WRDS;
signon username=_prompt_;

/* rsubmit, endrsubmit block */
rsubmit;

	/* this code runs on WRDS */
	%put hi;

endrsubmit;

/* rsubmit, endrsubmit block */
rsubmit;

	/* this code runs on WRDS */
	
	data a_comp (keep = gvkey fyear datadate cik conm sich sale at ni ceq prcc_f csho xrd curcd);
	set comp.funda;
	/* years 2010 and later*/
	if fyear >= 2010;

	/* prevent double records */
	if indfmt='INDL' and datafmt='STD' and popsrc='D' and consol='C' ;
	run;

	proc download data = a_comp out= a_comp;run;

endrsubmit;



/* I often repeat this code with an empty rsubmit block, this 'tests' the connection 
	if there is a timeout (20 minutes or so), then it will throw an error, and the signon will run
	If there is a timeout (but no rsubmit), then signon will not notice (and signon will not do anything)
	the following rsubmit will then fail.
*/
rsubmit; endrsubmit;
%let wrds = wrds.wharton.upenn.edu 4016;options comamid = TCP remote=WRDS;
signon username=_prompt_;


/* remote library assignment: this allows us to browse the remote work folder  */
libname rwork slibref=work server=wrds;

libname rcomp slibref=comp server=wrds;

/* note: the 'view' doesn't refresh when datasets change, navigate out and back in to refresh */
