pause on
pause off
log close _all 	/*closes all open log files*/
clear all		/*clears all data in memory*/



***choose data***
*set everything into SHARE output, but dataset used only from SHAREELSA
loc data "SHARE"  // this file uses SHAREELSA data


***define folder locations***
if "`c(username)'" == "P307344" { // UWP server
loc cv 		"X:/My Documents/XdrvData/`data'/"
loc outloc 	"`cv'" // to save locally 
}
else {
loc	cv 		"C:/Users/`c(username)'/Documents/RUG/`data'/"
loc	outloc 	"C:/Users/`c(username)'/Documents/GitHub/2-projectMM-`data'" // do not overwrite existing output in the compiled output	
}
gl 	outpath 	"`outloc'/files" /*output folder location*/
loc saveloc 	"main" // main | supplement /*saving location*/
loc altsaveloc  "allfiles" // saving location of all plots/subplots
cd  			"`cv'"	
use 			"./`data'data/harmon/H_SHAREELSA_panel2-MM.dta", clear	

***********
cd  	"$outpath/tab"
gl  diseasecodelist "hibp diab heart lung depr osteo cancr strok arthr demen" // psych
gl  diseaselist 	"d_hibp d_diab d_heart d_lung d_depr d_osteo d_cancr d_strok d_arthr d_demen"
		bys dataset: tab hacohort cohortselection 
**# Bookmark #1 I drop the cohortselection in all files except vizualization
	drop if cohortselection==0 
	drop if mi(age) // these are missing observations/time periods
	tab hacohort
	


***********************************************************************************************
*Part 7a*: Regression (define .do file)
***********************************************************************************************	
*** define global vars ***
loc sample "sfull5"
loc samplelabel: variable label `sample'
set scheme s1color	


/*** packages needed for regression ***
ssc install gologit2 // search and install gologit2
rnethelp "http://fmwww.bc.edu/RePEc/bocode/o/oparallel.sthlp" // for brant test
findit spost13 // needed for -mtable-, but also brant test	
*brant test (only for ologit): https://www.statalist.org/forums/forum/general-stata-discussion/general/1335252-ologit-and-brant-test
ssc install regoprob2
ssc install seqlogit
search st0359 // DH model (xtdhreg)
findit mdraws // DH model required package
*/

*** additional variables *** 
tab raeducl, gen(raeduclcat) // separate variables needed for regoprob2
drop 	raeduclcat1
rename 	raeduclcat2 educ_vocational
rename  raeduclcat3 educ_university

	// 	*** split by regions ***
	// 	if dataset == "ELSA" {
	// 	gen countryID = "EN"
	// 	}
	// 	gen 	region = "NA"
	// 	replace	region = "North"  		 if (countryID=="AT"|countryID=="Bf"|countryID=="Bn"|countryID=="Cf"|countryID=="Cg"|countryID=="Ci" | countryID=="DE"|countryID=="DK"|countryID=="EE"|countryID=="FI"|countryID=="FR"|countryID=="IE"        |countryID=="Ia" |countryID=="Ih" |countryID=="Ir"     |countryID=="LT"|countryID=="LU"|countryID=="LV" |countryID=="NL" |countryID=="SE"       ///
	// 	| countryID=="EN") // add EN
	// 	replace region = "Center-East"   if (countryID=="BG"|countryID=="CZ"|countryID=="HR"|countryID=="HU"|countryID=="Cf" |countryID=="PL" |countryID=="RO" |countryID=="SI" |countryID=="SK" )
	//  	replace region = "South" 		 if (countryID=="CY"|countryID=="ES"|countryID=="IT"|countryID=="MT"|countryID=="PT")	
	// 	qui log using 	"$outpath/logs/log-regionclassification.txt", text replace name(log) 
	// 	tab countryID region,m
	// 	log close log
	// // 	label 	define regionl 1 "North-East" 2 "East" 3 "Center" 4 "West"
	// // 	*label   define regionl 1 "NE" 2 "E" 3 "C" 4 "W"
	// // 	label	value  region regionl


***************************************************************************************************
*Part 7b*: Regression (general)
***************************************************************************************************


la var d_count_geq2 "$\geq$2 diseases"


	/************************************
	** Mixed Model vs RE model **
	************************************
	/** Mixed Model vs RE model **
	eststo m1: xtreg 	d_count timesincefirstobs male i.raeducl if dataset=="SHARE", re 
	eststo m2: xtmixed 	d_count timesincefirstobs male i.raeducl || ID: if dataset=="SHARE" 
	esttab m1 m2 // these two should be the same I think
	STOP
	*/
	
	** Mixed Model **
	eststo xtmixedSHARE: xtmixed 	d_count timesincefirstobs male i.raeducl || ID: if dataset=="SHARE"
	eststo xtmixedSHARE2: xtmixed 	d_count timesincefirstobs male i.raeducl || ID: timesincefirstobs if dataset=="SHARE"
	
	
	eststo xtmixedELSA: xtmixed 	d_count timesincefirstobs male i.raeducl || ID: if dataset=="ELSA"
	eststo xtmixedELSA2: xtmixed 	d_count timesincefirstobs male i.raeducl || ID: if dataset=="ELSA"	
	esttab xtmixed* 
	*/

/************************************
** Random Effects model **
************************************
reghdfe d_count age male i.raeducl i.countatfirstobs, vce(cl ID) a(rabyear countryID)
eststo m1 
reghdfe d_count age c.age#c.age  	male i.raeducl i.countatfirstobs, vce(cl ID) a(rabyear countryID)
test age c.age#c.age
eststo m2 
esttab m1 m2, nobase
++
*/

************************************
** gologit2 **
************************************

*** Gologit2 dydx effects marginsplot ***
				*preserve
				*keep if d_count<5
				*keep if d_anyatfirstobs==0
			// 		recode d_count (2/3=3 "2 or 3") (4/20=5 "4 or more"), gen(d_count2) // not the idea in ordered logit, we have more thresholds
			// 		loc counter   "1"
			// 		loc labellist "" /*need to delete local if in loop*/		
			// 		loc z 		 "d_count2"
			// 		levelsof `z', local(levels)
			// 		foreach l of local levels{
			// 		loc 	valuel : label (`z') `l'				
			// 		local 	labellist  `labellist' `counter' `"d_count=`valuel'"'   
			// 		loc   	counter = `counter'+1	
			// 		}
loc sample "sfull5"
	// & dataset=="SHARE"	
loc ctrls "male i.raeducl"
	/** first with ologit **
	ologit d_count age `ctrls' 	if `sample'==1, vce(cluster ID)
	margins, dydx(male) at(age=(50(5)90) raeducl=(1/3)) expression(predict(outcome(0)) + predict(outcome(1))) 
	marginsplot, saving(gr1, replace) recast(line) by(raeducl) // recast(scatter) // 	
	gr export 	"$outpath/fig/g_marginsplot_ologit_d_count.pdf", replace
	++
	*/ 
	
** then with gologit2 ** 
gologit2 d_count age `ctrls' 	if `sample'==1, vce(cluster ID) gamma npl(age) // autofit	
eststo m1 
esttab m1
margins, dydx(male) at(age=(50(5)80) raeducl=(1)) // expression(predict(outcome(2)) + predict(outcome(3)))
	*margins, dydx(male) at(age=(`agethreshold'(5)90))
// 	margins, dydx(age) at(age=(50(5)90) male=(0)) // conditional marginal effects
	marginsplot, by(male)  legend(order(`labellist'))  
]]
	*marginsplot, saving(gr1, replace) recast(line) by(raeducl) legend(order("none")) // legend(rows(4)) // recast(scatter) // 	
	gr export 	"$outpath/fig/g_marginsplot_ologit_`sample'_d_count.pdf", replace
	gr export 	"$outpath/fig/g_marginsplot_ologit_`sample'_d_count", replace 	
	++
	
	*margins, dydx(age) at(age=(50(5)90) male=(0/1)) predict(outcome(1)) predict(outcome(1))
	*margins, dydx(raeducl) at(age=(50(5)90) male=(0/1)) // for ME of educ by group

	*di "`connectedlist' "
	*mac list _labellist	 // should not display, but mac list 
	*marginsplot, legend(order(`labellist')) by(male)
	*mchange
	++

	gr export 	"$outpath/fig/main/g_marginsplot_gologit2_`sample'_d_count.pdf", replace
	++
	*/
	





	
***************************************************************************************************
*Part 7b*: Archive section
***************************************************************************************************	
******************
** Other models **
******************
	
/*** Ordinal model with PANEL data ***	
** regoprob2 **
timer clear 2 		
timer on 	2 
log using 		"$outpath/logs/log-t-regd_count-age-regoprob2`data'.txt", text replace name(regoprob2) 
eststo regoprob2`data': regoprob2 `y' age `ctrls' if `sample'==1 & dataset=="`data'", i(ID) autofit // npl(age) // autofit   
estadd local regtype "regoprob2"
	*loc append_estimates "replace" /*replace only at first iteration (only works when same file name and run through full loop)*/ 
estimates save "$outpath/logs/t-regd_count-age-`data'estimates" , replace // `append_estimates'
	*loc append_estimates "append" /*after this, append estimates to same file (for each dataset)*/
timer off  	2
timer list  2
loc timerlist "`timerlist' 2"
qui log close regoprob2
esttab regoprob2`data' 			using "$outpath/reg/t_regd_count-age-regoprob2`data'", tex replace
esttab regoprob2`data' 			using "$outpath/reg/t_regd_count-age-regoprob2`data'", html replace
*STOP
*/

*** Ordinal model with Cross-sectional data: this is NOT considering the panel dimension ***	
/** gologit2 ** 
timer clear 3 		
timer on 	3 
log using 	"$outpath/logs/log-t-regd_count-age-gologit2`data'.txt", text replace name(gologit2) 
eststo gologit2`data': gologit2 `y' age `ctrls'	if `sample'==1 & dataset=="`data'", vce(cluster ID) gamma autofit // npl(age) // autofit // cutpoints (intercept) are identical to ologit (but not xtologit)
estadd local regtype "gologit2"
estimates save "$outpath/logs/t-regd_count-age-`data'estimates" , append // `append_estimates'
timer off  	3
timer list  3
loc timerlist "`timerlist' 3"
qui log close gologit2
esttab gologit2`data'     		using "$outpath/reg/t_regd_count-age-gologit2`data'", tex replace
esttab gologit2`data'			using "$outpath/reg/t_regd_count-age-gologit2`data'", html replace
*/

/** ologit ** 
log using 		"$outpath/logs/log-t-regd_count-age-ologit`data'.txt", text replace name(ologit) 
eststo ologit`data': 	ologit 	`y' age `ctrls' if `sample'==1 & dataset=="`data'", vce(robust) // ologit using all waves
estadd local regtype "ologit"
estimates save "$outpath/logs/t-regd_count-age-`data'estimates" , append //  `append_estimates'
*brant, detail // brant only works on ologit; not xtologit. xtologit and ologit are not identical when only 1 time period is used; brant does not work with d_count>=8 because of perfect prediction 
qui log close 	ologit 
esttab ologit`data' 	    	using "$outpath/reg/t_regd_count-age-ologit`data'", tex replace
esttab ologit`data'				using "$outpath/reg/t_regd_count-age-ologit`data'", html replace
*STOP
*/


/*** xt-ordered logit (again considering panel dimension) ***
log using 		"$outpath/logs/log-t-regd_count-age-ologit`data'.txt", text replace name(xtologit) 
eststo xtologit`data': xtologit 	`y' age `ctrls'	if `sample'==1 & dataset=="`data'", vce(cluster ID)  // -vce(cl ID)- is equivalent to -robust-
estadd local regtype "xtologit"
estimates save "$outpath/logs/t-regd_count-age-`data'estimates" , append // `append_estimates'
qui log close 	xtologit 
esttab xtologit`data' 		    	using "$outpath/reg/t_regd_count-age-xtologit`data'", tex replace
esttab xtologit`data'				using "$outpath/reg/t_regd_count-age-xtologit`data'", html replace

*margins, at(age=(50(2)80))
*margins, dydx(`marginsvar') // at(male = (1 0)) 
*marginsplot 
	 *	predict p0 p1 p2 p3 p4 p5 p6 p7, pr // p9 
	 *	sum 	p?
*mtable, dydx(raeducl) //  at(male = (0 1) raeducl = (1 2 3)) // at(male = (0 1) ) // raeducl = (0 1 2 ))	
*/


	
*** moved this below bc did have sync issues	
	*export results using only one wave*
	sum time, meanonly 
	loc l = r(min)
loc sample "sfull5"
loc l = 2004
** what predicts having any disease? ** 
eststo logit`l': 		qui logit d_any c.age  male i.raeducl* marriedr  						if `sample'==1 &  time==`l', or 
eststo logit`l'ctrls: 	qui logit d_any c.age  male i.raeducl* marriedr retempr smokenr 		if `sample'==1 &  time==`l', or 
eststo logit`l'mm: 		qui logit d_count_geq2 c.age  male i.raeducl* marriedr  				if `sample'==1 &  time==`l', or 
eststo logit`l'mmctrls: qui logit d_count_geq2 c.age  male i.raeducl* marriedr retempr smokenr 	if `sample'==1 &  time==`l', or 
estadd loc time  "`l'", replace: logit*
loc    esttab_opt "la nobase nocons stats(N r2_p time) eform"
esttab logit`l'*, 									 `esttab_opt'  
esttab logit`l'* using "$outpath/reg/t_logit_d_any", `esttab_opt' tex replace frag
STOP
*/


*export results using only one wave*
	sum time, meanonly 
	loc l = r(min)
loc sample "sfull5"
loc l = 2004
** what predicts having any disease? ** 
loc ctrls "retempr smokenr"
loc data2 "SHARE"
loc y 		"d_any"
eststo `data2'_logit`l': 		qui logit `y' c.age  male i.raeducl* marriedr  				if `sample'==1 &  time==`l' & dataset=="`data2'", or 
eststo `data2'_logit`l'ctrl: 	qui logit `y' c.age  male i.raeducl* marriedr `ctrls' 		if `sample'==1 &  time==`l' & dataset=="`data2'", or 
estadd loc estadddata "`data2'": `data2'*
loc data2 "ELSA" 
eststo `data2'_logit`l': 		qui logit `y' c.age  male i.raeducl* marriedr  				if `sample'==1 &  time==`l' & dataset=="`data2'", or 
eststo `data2'_logit`l'ctrl: 	qui logit `y' c.age  male i.raeducl* marriedr `ctrls' 		if `sample'==1 &  time==`l' & dataset=="`data2'", or 
estadd loc estadddata "`data2'": `data2'*
loc    esttab_opt "la nobase nocons stats(N r2_p time estadddata) eform title("Logit Regression, any disease") "
estadd loc time  "`l'", replace: SHARE* ELSA* 
esttab SHARE* ELSA*, 									 `esttab_opt'  
esttab SHARE* ELSA* using "$outpath/reg/t_logit_`y'", 	`esttab_opt' tex replace 


	


