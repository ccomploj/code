pause on
pause off
log close _all 	/*closes all open log files*/
clear all		/*clears all data in memory*/


loc append_estimates "replace" /*replace only at first iteration*/ 
***choose data***
loc data 		"SHARE"
loc datalist 	"SHARE ELSA HRS"
foreach data of local datalist{


***define folder locations***
if "`c(username)'" == "P307344" { // UWP server
loc cv 		"X:/My Documents/XdrvData/`data'/"
loc outloc 	"`cv'" // to save locally 
*loc outloc "\\Client\C$\Users\User\Documents\GitHub\2-projectMM-`data'\" // from UWP save directly to PC
}
else {
loc	cv 		"G:/My Drive/drvData/`data'/" // own PC
loc	outloc 	"C:/Users/User/Documents/GitHub/2-projectMM-`data'" 	
}
gl 	outpath 	"`outloc'/files" /*output folder location*/
loc saveloc 	"main" // main | supplement /*saving location*/
cd  			"`cv'"	
use 			"./`data'data/harmon/H_`data'_panel2-MM.dta", clear	

**define country-specific locals**
if "`data'"=="CHARLS" {
loc agethreshold 	"45"
loc upperthreshold	"75"
loc ptestname 		"cesdr"
loc pthreshold		"3"
*loc t 				"ruralh" // /*categorical variable to split by*/ 	
}
if "`data'"=="SHARE" {
loc agethreshold 	"50" // select survey-specific lower age threshold
loc upperthreshold	"85" // select survey-specific upper age threshold	
loc wavelast 		"8" 	// select survey-specific last wave
loc ptestname 		"eurod"
loc pthreshold		"4"
	drop if wave==3 // is not really a time period, there are no regular variables for this wave
	keep 	if hacohort==1 | hacohort==2 
	drop 	if countryID=="GR" /*relatively imprecise survey*/
}
if "`data'"=="ELSA" {
loc agethreshold 	"50" // select survey-specific lower age threshold
loc upperthreshold	"85" // select survey-specific upper age threshold	
loc wavelast 		"9" 	// select survey-specific last wave
loc ptestname 		"cesdr"
loc pthreshold		"3"
}
if "`data'"=="HRS" {
loc agethreshold 	"51" // select survey-specific lower age threshold
loc upperthreshold	"85" // select survey-specific upper age threshold	
loc wavelast 		"14" 	// select survey-specific last wave
loc ptestname 		"cesdr"
loc pthreshold		"3"
	keep 	if hacohort<=5 	
	keep if wave>=3 & wave<=13 // cognitive measures not consistently available
}	
if "`data'"=="SHAREELSA" {
loc agethreshold 	"50" // select survey-specific lower age threshold
loc upperthreshold	"85" // select survey-specific upper age threshold	
loc wavelast 		"9" 	// select survey-specific last wave
loc ptestname 		"cesdr"
loc pthreshold		"3"
	drop if agemin<50  & dataset=="SHARE"
	drop if agemin<50  & dataset=="ELSA"
	*drop if wave==3    & dataset=="SHARE" // already dropped
	drop if hacohort>2 & dataset=="SHARE"  
}	
loc t "male"
drop if agemin<`agethreshold'	
**********************
loc append_iterationlog "replace" /*short iteration log at the end of the loop*/ 



****************************************************************************************************
*Part 7*: Regression (general)
****************************************************************************************************	
*** additional variables *** 
tab raeducl, gen(raeduclcat)
drop 	raeduclcat1
rename 	raeduclcat2 educ_vocational
rename  raeduclcat3 educ_university

*** definition of global vars ***
loc sample "sfull"
set scheme s1color	
	
/*** packages needed for regression ***
ssc install gologit2 // search and install gologit2
rnethelp "http://fmwww.bc.edu/RePEc/bocode/o/oparallel.sthlp" // for brant test
findit spost13 // needed for -mtable-, but also brant test	
ssc install regoprob2
ssc install seqlogit
search st0359 // DH model (xtdhreg)
findit mdraws // DH model required package
*/

/*** descriptions of new methods ***
*brant test (only for ologit): https://www.statalist.org/forums/forum/general-stata-discussion/general/1335252-ologit-and-brant-test
*/
	

/*** +++ Table: what predicts having any disease? (logit by wave) +++ ***
levelsof time, local(levels)
foreach l of local levels{
eststo d_any`l': qui logit d_any 		c.age c.age#c.age male married i.raeducl*  if time==`l', or //  
eststo d_mm`l' : qui logit d_count_geq2 c.age c.age#c.age male married i.raeducl*  if time==`l', or 
estadd loc time  "`l'" : d_any`l' d_mm`l'
}
loc esttab_opt "la stats(N time) replace nobase"
esttab d_any*, `esttab_opt'
esttab d_any* using "$outpath/reg/o_logitbywaved_any" , `esttab_opt' tex nocons
esttab d_mm* , `esttab_opt'
esttab d_mm* using "$outpath/reg/o_logitbywaved_mm" , `esttab_opt' tex nocons
++
*/
*keep if wave==1 & d_count<4
*** +++ Table: what predicts the count? (ordered model) +++ ***

loc y 			"d_count"
	gen age_male = age*male
	gen age_educ_voc = age*educ_vocational
	gen age_educ_uni = age*educ_university	
loc ctrlsextra "age_male age_educ_voc age_educ_uni"
loc ctrls 		"educ_* male `ctrlsextra' pretreat_workr pretreat_marriedr"
		*preserve 
		*sample 50
		keep if d_count<8
		timer clear 	1 		
		timer on 		1 
		loc timerlist  "1"
	
	
*** Ordinal model with PANEL data: this is NOT considering the panel dimension ***	
** regoprob2 **
timer clear 2 		
timer on 	2 
log using 		"$outpath/logs/log-t-regd_count-age-regoprob2`data'.txt", text replace name(regoprob2) 
eststo regoprob2`data': regoprob2 `y' age `ctrls' if `sample'==1 & dataset=="`data'", i(ID) npl(age) // autofit   
estadd local regtype "regoprob2"
estimates save "$outpath/logs/t-regd_count-age-`data'estimates" , `append_estimates'
loc append_estimates "append"
timer off  	2
timer list  2
loc timerlist "`timerlist' 2"
qui log close regoprob2
esttab regoprob2`data' 			using "$outpath/t_regd_count-age-regoprob2`data'", tex replace
esttab regoprob2`data' 			using "$outpath/t_regd_count-age-regoprob2`data'", html replace
*STOP
*/

*** Ordinal model with Cross-sectional data: this is NOT considering the panel dimension ***	
** gologit2 ** 
timer clear 3 		
timer on 	3 
log using 	"$outpath/logs/log-t-regd_count-age-gologit2`data'.txt", text replace name(gologit2) 
eststo gologit2`data': gologit2 `y' age `ctrls'	if `sample'==1 & dataset=="`data'", vce(cluster ID) gamma npl(age) // autofit // cutpoints (intercept) are identical to ologit (but not xtologit)
estadd local regtype "gologit2"
estimates save "$outpath/logs/t-regd_count-age-`data'estimates" , `append_estimates'
timer off  	3
timer list  3
loc timerlist "`timerlist' 3"
qui log close gologit2
esttab gologit2`data'     		using "$outpath/t_regd_count-age-gologit2`data'", tex replace
esttab gologit2`data'			using "$outpath/t_regd_count-age-gologit2`data'", html replace

** ologit ** 
log using 		"$outpath/logs/log-t-regd_count-age-ologit`data'.txt", text replace name(ologit) 
eststo ologit`data': 	ologit 	`y' age `ctrls' if `sample'==1 & dataset=="`data'", vce(robust) // ologit using all waves
estadd local regtype "ologit"
estimates save "$outpath/logs/t-regd_count-age-`data'estimates" , `append_estimates'
*brant, detail // brant only works on ologit; not xtologit. xtologit and ologit are not identical when only 1 time period is used; brant does not work with d_count>=8 because of perfect prediction 
qui log close 	ologit 
esttab ologit`data' 	    		using "$outpath/t_regd_count-age-ologit`data'", tex replace
esttab ologit`data'				using "$outpath/t_regd_count-age-ologit`data'", html replace
*STOP
*/


*** xt-ordered logit ***
log using 		"$outpath/logs/log-t-regd_count-age-ologit`data'.txt", text replace name(xtologit) 
eststo xtologit`data': xtologit 	`y' age `ctrls'	if `sample'==1 & dataset=="`data'", vce(cluster ID)  // -vce(cl ID)- is equivalent to -robust-
estadd local regtype "xtologit"
estimates save "$outpath/logs/t-regd_count-age-`data'estimates" , `append_estimates'
qui log close 	xtologit 
esttab xtologit`data' 		    	using "$outpath/t_regd_count-age-xtologit`data'", tex replace
esttab xtologit`data'				using "$outpath/t_regd_count-age-xtologit`data'", html replace

*margins, at(age=(50(2)80))
*margins, dydx(`marginsvar') // at(male = (1 0)) 
*marginsplot 
	 *	predict p0 p1 p2 p3 p4 p5 p6 p7, pr // p9 
	 *	sum 	p?
*mtable, dydx(raeducl) //  at(male = (0 1) raeducl = (1 2 3)) // at(male = (0 1) ) // raeducl = (0 1 2 ))	
*/

*** ols (suitable only if assuming count approximates unobserved health reasonably well) ***	
log using 	"$outpath/logs/log-t-regd_count-age-xtologit`data'.txt", text replace name(xtreg) 
eststo xtreg`data': xtreg `y' age				 `ctrls'  if `sample'==1 & data=="`data'", re
eststo xtreg`data': xtreg `y' c.age##i.cohortmin5 `ctrls'  if `sample'==1 & data=="`data'", re
estadd local regtype "xtreg"
estimates save "$outpath/logs/t-regd_count-age-`data'estimates" , `append_estimates'
qui log close xtreg
esttab xtreg* using "$outpath/t_regd_count-age-xtreg`data'", tex replace
esttab xtreg* using "$outpath/t_regd_count-age-xtreg`data'", html replace
*STOP
*/

esttab *`data' using "$outpath/t_regd_count-age-combined`data'", tex replace stats(N r2 regtype)
esttab *`data' using "$outpath/t_regd_count-age-combined`data'", html replace stats(N r2 regtype)





log using 		"$outpath/logs/iterationlog.txt", text `append_iterationlog' name(iterationlog)
timer 					off  1
timer 					list `timerlist' 
di 						"Loop with `data' completed." 
loc append_iterationlog "append" /*append after this*/ 
log close iterationlog
STOP
}



/*** multinomial logit ***
log using 	"$outpath/logs/log-t-regd_count-age-mlogit`data'.txt", text replace name(mlogit) 
eststo mlog1: mlogit d_count age `ctrls' if `sample'==1 & d_count<7, vce(cluster ID)
log close mlogit
esttab mlog1 using "$outpath/t-regd_count-cohort-mlogit.tex", b se nobase nogaps replace
esttab mlog1 using "$outpath/t-regd_count-cohort-mlogit.html", b se nobase nogaps replace
*STOP
*/

set seed 500
*** +++ Table: transitions +++ ***
*** sequential logit ***
log using 	"$outpath/logs/log-t-regd_count-age-seqlogit`data'.txt", text replace name(seqlogit) 
// tab d_count, gen(d_count)
preserve
keep if d_count<7
	sample 10
eststo seqlogit: seqlogit d_count age male i.raeducl if `sample'==1, vce(cluster ID) tree(0:1 2 3 4 5 6, 1:2 3 4 5 6, 2: 3 4 5 6, 3: 4 5 6, 4: 5 6, 5:6) ofinterest(raeducl) over(c.age) or 
*seqlogitdecomp age, table // at(coh 1.5 south 0 paeduc 12) table
seqlogitdecomp, area // at(male 0 educ_vocational 0 educ_university 0)
log close seqlogit
timer 		off  1
timer 		list 1	
STOP
*/


/*** combine results to a single table ***
esttab m1 m2 panel1 using "$outpath/t_regd_count-age`data'", tex replace
esttab m1 m2 panel1 using "$outpath/t_regd_count-age`data'", html replace
*/

* Display the results
//	estat ic		






	*** suggestion of bertrand *** 
	loc ctrls "age male raeducl"
	gen presentintplus1 = !mi(d_count) & !mi(F.d_count) // should work for all pairs
	**
		sum d_count, meanonly
		loc d_countmax = r(max) // not correct diseasemax, but max observed so still correct here
		di "`d_countmax'"
	logit time_c1toc2 `ctrls' if d_count==1 & presentintplus1

	forval c=1/`d_countmax' {
*	logit timetonextdisease2 if d_count==1 
	**time, so should use -reg-**
	**raw margins** 
	reg time_c1toc2  if d_count==`c' & presentintplus1,  
	predict fit_`c', xb
	
	reg time_c1toc2 `ctrls' if d_count==`c' & presentintplus1,  // time_c#toc# considers iwym; ignores missing response, should ideally condition also on being present in both time periods (and having a count in those time periods)	; curr only uses definition of    ; compare this to ordered logit; is this sequential logit?; n
	predict fit_`c', xb
	}
*	logit time_c2toc3 if d_count==2	& presentintplus1
*	logit time_c3toc4 if d_count==3 & presentintplus1
	

	
*** +++ what predicts the count? +++ ***
	tab d_count wave 
	tab d_count male 
	tab d_count married 
	tab d_count raeducl 

	*check if high SE*
	*bys d_count: corr male married raeducl
	*bys d_count: sum male married raeducl	
timer on 1 				// counts the duration of file computation	
log using 	"$outpath/logs/log-t-regd_count-cohort.txt", text replace name(log) 
	*sample 5 // select a ## % random subsample to speed up computation
loc sample 		"sfull  & d_count<8" // & d_count<8
loc agectrls 	 "age" // age c.age##c.age, leaving out cross term solves the issue
loc ctrls	 	"i.male married i.raeducl i.cohortmin5" // i.wave 
loc y 			"d_count"
sum `y' `ctrls' if `sample'==1 & wave==1




	
	

****************************************************************************************************
*Appendix*
****************************************************************************************************	
	
** should we estimate a zero-inflated ordered probit? **
*https://www.stata.com/features/overview/zero-inflated-ordered-probit/

/*Yes, you can predict the category 0 in an ordered probit model. The ordered probit model is designed to handle ordinal dependent variables, so it can certainly predict the lowest category (0 in your case).
However, if you have a large number of 0s in your data (i.e., zero-inflation), a standard ordered probit model might not be the best choice. In this case, you might want to consider a zero-inflated ordered probit (ZIOP) model1. The ZIOP model is used for ordered response variables when the data exhibit a high fraction of observations at the lowest end of the ordering1.
In Stata, you can use the zioprobit command to fit a ZIOP model1. This command applies to ordinal data, where the numeric value of the lowest category need not be zero1. So, you could fit a 0-inflated model with your data1.
To predict the probabilities for each category in an ordered probit model, you can use the cumulative distribution function (CDF) of the standard normal distribution2. The formula for the predicted probability of y = 0 is:
P(y=0∣x)=Φ(α−βx)
where Φ denotes the CDF of the standard normal distribution, α is the threshold parameter for category 0, β is the vector of coefficients, and x is the vector of predictors2.
I hope this helps! Let me know if you have any other questions. 😊
*/


/*
*/
