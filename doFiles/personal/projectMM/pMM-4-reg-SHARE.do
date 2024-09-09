pause on
*pause off
log close _all 	/*closes all open log files*/
clear all		/*clears all data in memory*/


***choose data***
loc data 		"SHARE" // but we store everything in SHARE, but use SHAREELSA data
loc datalist 	"SHARE ELSA"
*foreach data of local datalist {

***define folder locations***
if "`c(username)'" == "P307344" { // UWP server
loc cv 		"X:/My Documents/XdrvData/`data'/"
loc outloc 	"`cv'" // to save locally 
*loc outloc "\\Client\C$\Users\User\Documents\GitHub\2-projectMM-`data'\" // from UWP save directly to PC (only works with full version of Citrix)
}
else {
loc	cv 		"C:/Users/`c(username)'/Documents/RUG/`data'/"
loc	outloc 	"C:/Users/`c(username)'/Documents/GitHub/2-projectMM-`data'" // do not overwrite existing output in the compiled output	
}
gl 	outpath 	"`outloc'/files" /*output folder location*/
loc saveloc 	"main" // main | supplement /*saving location*/
cd  			"`cv'"	
// use 			"./`data'data/harmon/H_`data'_panel2-MM.dta", clear	
use 			"./`data'data/harmon/H_SHAREELSA_panel2-MM.dta", clear	
	*pause

**define country-specific locals**
tab hacohort dataset
if "`data'"=="SHARE" {
// 	drop if hacohort>2 & dataset=="SHARE"  
// 	drop if hacohort>2 & dataset=="ELSA"  
}	
**********************
cd  	"$outpath/tab"


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



/*** +++ what predicts having any disease? (logit by wave just to check consistency (not for paper)), then (xt)logit using pooled sample +++ ***
/** logit by wave **
levelsof time, local(levels)
foreach l of local levels{
eststo logit`l': qui logit d_any c.age  male marriedr i.raeducl*  if time==`l', or 
estadd loc time  "`l'" 
}
esttab logit*,  stats(N r2_p time) nobase eform // `esttab_opt'
*/
		la var d_count_geq2 "has 2+ diseases"
	*export results using only one wave*
	sum time, meanonly 
	loc l = r(min)
loc l = 2004
eststo logit`l': 		qui logit d_any c.age  male i.raeducl* marriedr  if time==`l', or 
eststo logit`l'ctrls: 	qui logit d_any c.age  male i.raeducl* marriedr retempr smokenr if time==`l', or 
eststo logit`l'mm: 		qui logit d_count_geq2 c.age  male i.raeducl* marriedr  if time==`l', or 
eststo logit`l'mmctrls: 	qui logit d_count_geq2 c.age  male i.raeducl* marriedr retempr smokenr if time==`l', or 
estadd loc time  "`l'", replace: logit*
loc    esttab_opt "la nobase nocons stats(N r2_p time) eform"
esttab logit`l'*, 									 `esttab_opt'  
esttab logit`l'* using "$outpath/reg/o_logit_d_any", `esttab_opt' tex replace
STOP
*/




************************************
** Linear model with timesincefirstobs **
************************************

*** Linear Random Effect model (Mixed Model) for SHARE AND ELSA (need data "SHAREELSA") ***	

/**
	*relabel time for narrower table* 
	preserve 
	*keep if d_anyatfirstobs == 0
	*keep if cohortmin==50
	tab d_count
	la var timesincefirstobs "time(sinceb)"
	loc ctrls "male i.raeducl"
eststo xtregSHARE: qui xtreg d_count c.timesincefirstobs i.agegrpmin5 i.agegrpmin5#c.timesincefirstobs `ctrls'	if sfull5==1 & dataset=="SHARE", robust // vce(cl ID) 
eststo xtregELSA:  qui xtreg d_count c.timesincefirstobs i.agegrpmin5 i.agegrpmin5#c.timesincefirstobs `ctrls'	if sfull5==1 & dataset=="ELSA", robust // vce(cl ID) 

loc esttab_opt "nobase compress la se(%9.2f) stats(N controls) mtitles("SHARE" "ELSA")" // r2
	estadd loc controls "yes": xtregSHARE xtregELSA
esttab xtregSHARE xtregELSA , `esttab_opt' 
*esttab xtregSHARE xtregELSA  using "C:/Users/User/Documents/GitHub/2-projectMM-SHARE/files/t_regd_count-timesincefirstobs-xtregSHAREELSA", tex replace  `esttab_opt' note("Controls include `ctrls'") keep(timesincefirstobs *#c.timesincefirstobs)  // stats(N controls)
*/

** with age (instead of time) and cohort dummies **
	*loc interactions "male#c.age i.raeducl#c.age i.countatfirstobs i.countatfirstobs#c.age"
		la var d_count "\# diseases"
loc 	ctrls 	"age male i.raeducl i.countatfirstobs"
eststo xtreg: 	qui xtreg  d_count  `ctrls'	if sfull5==1, robust fe i(rabyear) 

loc 	ctrls 	"age male i.raeducl i.countatfirstobs male#c.age i.raeducl#c.age i.countatfirstobs#c.age"
eststo xtreg2: 	qui xtreg  d_count  `ctrls'	if sfull5==1, robust fe i(rabyear) 

loc 	ctrls 	"age male i.raeducl i.countatfirstobs c.age#c.age"
eststo xtreg3: 	qui xtreg  d_count  `ctrls'	if sfull5==1, robust fe i(rabyear) 

	estadd loc 	controls "yes": *
loc esttab_opt 	"nobase compress la se(%9.2f) stats(N r2 controls)"
esttab xtreg* , `esttab_opt' 
esttab xtreg*  using "$outpath/reg/t_regd_count-age-xtregSHAREELSA", tex replace  `esttab_opt'  //  keep(age *#c.age)   // stats(N controls)
STOP 
*/

	/** (SHARE and ELSA separately) with age (instead of time) and cohort dummies **
		*loc interactions "male#c.age i.raeducl#c.age i.countatfirstobs i.countatfirstobs#c.age"
	loc 	ctrls "age male i.raeducl i.countatfirstobs"
	eststo xtregSHARE: qui xtreg  d_count  `ctrls'	if sfull5==1 & dataset=="SHARE", robust fe i(rabyear) 
	eststo xtregELSA:  qui xtreg  d_count  `ctrls'	if sfull5==1 & dataset=="ELSA",  robust fe i(rabyear) // vce(cl ID) 

	loc 	ctrls "age male i.raeducl i.countatfirstobs male#c.age i.raeducl#c.age i.countatfirstobs#c.age"
	eststo xtregSHARE2: qui xtreg  d_count  `ctrls'	if sfull5==1 & dataset=="SHARE", robust fe i(rabyear) 
	eststo xtregELSA2:  qui xtreg  d_count  `ctrls'	if sfull5==1 & dataset=="ELSA",  robust fe i(rabyear)
		estadd loc controls "yes": *
	loc esttab_opt "nobase compress la se(%9.2f) stats(N r2 controls) mtitles("SHARE" "SHARE" "ELSA" "ELSA")"
	esttab xtregSHARE* xtregELSA* , `esttab_opt' 
	esttab xtregSHARE* xtregELSA*  using "C:/Users/User/Documents/GitHub/2-projectMM-SHARE/files/reg/t_regd_count-age-xtregSHAREELSA", tex replace  `esttab_opt' //  keep(age *#c.age)   // stats(N controls)
	STOP 
	*/

************************************
** Linear model with age of onset **
************************************

*** Linear RE model with first onset, using only healthy at baseline sample (hence no countatfirstobs) ***
preserve
la var d_count "N diseases"
sum onsetage*
	*replace onsetage = . if d_anyatfirstobs>0
sum onsetage_uncens /*this is same as onsetage recoding in previous line*/
la var onsetage_uncens "age of first onset (obs.)"
		tab d_anyever firstagegrp5,m /*d_anyever==0 is causing obs to differ btw two grps*/
loc ctrls "male i.raeducl male#c.age i.raeducl#c.age" // i.firstage
eststo xtregSHARE: qui xtreg  d_count c.age `ctrls'	if sfull5==1 & d_anyatfirstobs==0 & d_anyever==1 & dataset=="SHARE", robust fe i(rabyear) // vce(cl ID) // c.age#c.age
	gen s2 = e(sample)
eststo xtregELSA:  qui xtreg  d_count c.age `ctrls'	if sfull5==1 & d_anyatfirstobs==0 & d_anyever==1 & dataset=="ELSA",  robust fe i(rabyear) // vce(cl ID) // c.age#c.age

loc ctrls "male i.raeducl male#c.age i.raeducl#c.age i.firstagegrp5#c.age" 
eststo xtregSHARE2: qui xtreg  d_count c.age `ctrls' if sfull5==1 & d_anyatfirstobs==0 & dataset=="SHARE", robust fe i(rabyear) // vce(cl ID) // c.age#c.age
	gen s = e(sample)
eststo xtregELSA2:  qui xtreg  d_count c.age `ctrls' if sfull5==1 & d_anyatfirstobs==0 & dataset=="ELSA", robust fe i(rabyear) // vce(cl ID) // c.age#c.age
loc esttab_opt "nobase compress la se(%9.2f) stats(N r2) mtitles("SHARE" "SHARE" "ELSA" "ELSA" )"
esttab xtregSHARE* xtregELSA* , `esttab_opt' 
esttab xtregSHARE* xtregELSA*  using "C:/Users/User/Documents/GitHub/2-projectMM-SHARE/files/reg/t_regd_count-age-xtregSHAREELSA-firstage", tex replace  `esttab_opt'  // keep(age *#c.age) nobase  // stats(N controls) note("Controls include `ctrls'")
restore
STOP
*/



	************************************
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
	
	esttab xtmixed* 
	STOP
	
	eststo xtmixedELSA: xtmixed 	d_count timesincefirstobs male i.raeducl || ID: if dataset=="ELSA"
	eststo xtmixedELSA2: xtmixed 	d_count timesincefirstobs male i.raeducl || ID: if dataset=="ELSA"	


*******************************
** Out of sample predictions **
*******************************
**recode age and timesincefirstobs if too few observations fall in this category and SEs large (for agemin<=70 sample**
levelsof agegrpmin5, local(levels)
foreach  cohort of   local levels {
qui 	sum time, meanonly 
loc 	timerange = r(max)-r(min)+5 /*maximum time an id is observed (5 added for cohort)*/
replace age = `cohort'+`timerange' if age >`cohort'+`timerange' & age<. & agegrpmin5==`cohort' 
replace timesincefirstobs = `timerange'-5 if timesincefirstobs<. & timesincefirstobs>`timerange'-5
} 
di 		"`timerange'"

	*sample 20
loc 	y 			"d_count"
loc 	ylabel: 	var label `y'
loc 	cat  	  	"agegrpmin5" // male, raeducl, countatfirstobs
loc 	timevar 	"c.age" 
*loc 	xla 		"xla(50(5)90)" /*needed for separate sub-plots*/
loc 	opt_marginsplot "ytitle("Predicted (`ylabel')")" // noci  
// loc 	ctrls  "`ctrl'"
	loc ctrls "male i.raeducl"

*overall plot by cohort groups (continuous time)* 
	log using 	"$outpath/logs/log-reg_byage_d_count_outofsample.txt", text replace name(log) 
loc 	reg  		reg `y' `timevar'##`cat' `ctrls'  if `sample'==1 
 `reg'
	log close log
*qui margins `timevar'#`cat' 
qui margins `cat', at(age=(30(5)90)) 
marginsplot,  `opt_marginsplot'   `xla'  title("Prediction from linear fit using age") note("Sample: `samplelabel' | Controls: `ctrls' (none)" "Model: `reg'") name(g`cat'_`cohort', replace) yline(0) // by(agegrpmin5) 
gr export 	"$outpath/fig/main/g_reg_byage_d_count_outofsample.jpg", replace	quality(100)
	STOP
	
	
	
	*** mixed model ***
	xtreg, mle = xtmixed...










