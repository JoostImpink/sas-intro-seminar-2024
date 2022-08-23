/*
	matching Compustat and CRSP was covered in the bootcamp (so let's keep it short)

	there is a CCM linktable (ccmxpf_lnkhist), which 'ties' a gvkey to the main permno for any given date
	
*/

/* usage */

/*	Get permno using the CCM merge lookup table
	This is very boilerplate-like, the relevant thing is that this match gives
	the correct permno at date 'boy' (in this case) for a given gvkey */		
proc sql; 
  	create table myCompPermno as 
	  	select a.* , b.lpermno as permno
	  	from getf_1 a
	  	left join
			crsp.ccmxpf_lnkhist b
	  	on a.gvkey = b.gvkey
	  	and b.linktype in ("LC" "LN" "LU" "LX" "LD" "LS")
	  	and b.linkprim in ("C", "P")	  
	  	and ((a.datadate >= b.LINKDT) or b.LINKDT = .B) and
	    	((a.datadate <= b.LINKENDDT) or b.LINKENDDT = .E);
quit;



