pause on
pause off
log close _all 	/*closes all open log files*/
clear all		/*clears all data in memory*/


***choose data***
loc data 		"SHAREELSA"
loc datalist 	"SHARE ELSA HRS"
*foreach data of local datalist {

***define folder locations***
if "`c(username)'" == "P307344" { // UWP server
loc cv 		"X:/My Documents/XdrvData/`data'/"
loc outloc 	"`cv'" // to save locally 
*loc outloc "\\Client\C$\Users\User\Documents\GitHub\2-projectMM-`data'\" // from UWP save directly to PC (only works with full version of Citrix)
}
else {
*loc cv 		"G:/My Drive/drvData/`data'/" // own PC
loc	cv 		"C:/Users/`c(username)'/Documents/RUG/`data'/"
loc	outloc 	"C:/Users/`c(username)'/Documents/GitHub/2-projectMM-`data'" // do not overwrite existing output in the compiled output	
}
gl 	outpath 	"`outloc'/files" /*output folder location*/
loc saveloc 	"main" // main | supplement /*saving location*/
loc altsaveloc  "allfiles" // saving location of all plots/subplots
cd  			"`cv'"	
use 			"./`data'data/harmon/H_`data'_panel2-MM.dta", clear	
	pause

**define country-specific locals**
if "`data'"=="SHARE" {
// loc ptestname 	"eurod"
// loc pthreshold	"4"
	drop if wave==3 // is not really a time period, there are no regular variables for this wave
	keep 	if hacohort==1 | hacohort==2 
	drop 	if countryID=="GR" /*relatively imprecise survey*/
}
if "`data'"=="ELSA" {
}
if "`data'"=="HRS" {
// 	keep 	if hacohort<=5 	
// 	keep if wave>=3 & wave<=13 // cognitive measures not consistently available 		
}	
if "`data'"=="SHAREELSA" {
// 	drop if hacohort>2 & dataset=="SHARE"  
}	
**********************


***************************************************************************************************
*Part 7a*: Regression (define .do file)
***************************************************************************************************
*cd  	"$outpath/tab"

*** definition of global vars ***
loc sample "sfull5"
loc samplelabel: variable label `sample'
set scheme s1color	


***************************************************************************************************
*Part 7b*: Regression (general)
***************************************************************************************************
**# Bookmark #1 move to part5 
	la var smokenr "curr.smoking"
	

/** xtlogit using all data **
eststo 	xtlogitRE: qui xtlogit d_any 		c.age male married i.raeducl* if `sample'==1, or re vce(cl ID)  
qui 	estadd loc model2 "RE"
eststo 	xtlogitFE: qui xtlogit d_any 		c.age male married i.raeducl* if `sample'==1, or fe 			
qui 	estadd loc model2 "FE"
loc 	esttab_opt "la nobase nocons stats(N r_p model2) nobase eform"
esttab 	xtlogit*, `esttab_opt' 
*esttab 	xtlogitRE using "$outpath/reg/t_xtlogit_d_any" , `esttab_opt'  tex replace
STOP
*/


	/*** what predicts an earlier onset ? *** 
	sum onset*
	loc ctrl "male i.raeducl"
	tobit onsetage `ctrl', ll()
	+
	*/

	
	
	/*** 2y-transition probabilites, conditional on previous value ***
	sum d_count, meanonly 
	loc d_countmax = r(max)
	
	tab d_count d_count_lead, nofreq row  // sample probabilities of transition between states	
	loc i = 1
// 	*forval i = 1/`d_countmax'{
// 	qui ologit d_count_lead d_count if d_count==`i' // no additional options
// 	predict pr`i'to`j', pr // predicted probabilities (cannot use these, unless use ologit)
// 	}
		*preserve
		*recode d_count_lead (99=`r(max)'+1) /*recode for contourplot*/
	// define probabilities as z 
	twoway contour z d_count d_count_lead if cohort==50, title("Contour Plot: Probabilities") xtitle("d_count") ytitle("d_count_lead")
		*restore 
		++
		*/

	
*** +++ b) what predicts the count? (ordered model) +++ ***
loc y 			"d_count"
loc ctrls 		"i.raeducl male" 
*preserve 
timer clear 	1 		
timer on 		1 
loc timerlist  "1"

	
	/*** Gologit2 dydx effects marginsplot ***
	*preserve
	sample 20 
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
	** first with ologit **
	ologit d_count age `ctrls' 	if sfull==1 & dataset=="SHARE", vce(cluster ID)
	margins, dydx(male) at(age=(50(5)90) raeducl=(1/3)) expression(predict(outcome(0)) + predict(outcome(1))) 
	marginsplot, saving(gr1, replace) recast(line) by(raeducl) // recast(scatter) // 	
	gr export 	"$outpath/fig/g_marginsplot_ologit_`sample'_d_count.pdf", replace
	++
	** then with gologit2 ** 
	gologit2 d_count age `ctrls' 	if sfull==1 & dataset=="SHARE", vce(cluster ID) gamma autofit	
	margins, dydx(male) at(age=(50(5)90) raeducl=(1) // expression(predict(outcome(2)) + predict(outcome(3))) 
	marginsplot, saving(gr1, replace) recast(line) by(raeducl) legend(order("none")) // legend(rows(4)) // recast(scatter) // 	
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
	*gologit2 d_count2 age `ctrls' 	if sfull==1 & dataset=="SHARE", vce(cluster ID) gamma autofit // not the idea, should estimate for all categories
	gologit2 d_count age `ctrls' 	if sfull==1 & dataset=="SHARE", vce(cluster ID) gamma autofit	
	*margins, dydx(male) at(age=(`agethreshold'(5)90))
	margins, dydx(age) at(age=(50(5)90) male=(0)) // conditional marginal effects
	marginsplot, by(male)  legend(order(`labellist')) 
	gr export 	"$outpath/fig/main/g_marginsplot_gologit2_`sample'_d_count.pdf", replace
	++
	*/
	



	

++++++		STOP // here to not overwrite current output
		
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

** ologit ** 
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


*** xt-ordered logit (again considering panel dimension) ***
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

*** xtols *** (suitable if assuming count approximates unobserved health reasonably well)
log using 	"$outpath/logs/log-t-regd_count-age-xtologit`data'.txt", text replace name(xtreg) 
eststo xtreg`data': xtreg  `y' age				`ctrls'  if `sample'==1 & data=="`data'", re
eststo xtreg`data'2: xtreg `y' age##cohortmin5 	`ctrls'  if `sample'==1 & data=="`data'", re // (not sure if it makes sense above also to interact with cohortmin5)
estadd local regtype "xtreg"
estimates save "$outpath/logs/t-regd_count-age-`data'estimates" , append // `append_estimates'
qui log close xtreg
esttab xtreg* using "$outpath/t_regd_count-age-xtreg`data'", tex replace
esttab xtreg* using "$outpath/t_regd_count-age-xtreg`data'", html replace
*STOP
*/

esttab *`data' using "$outpath/t_regd_count-age-combined`data'", tex replace stats(N r2 regtype)
esttab *`data' using "$outpath/t_regd_count-age-combined`data'", html replace stats(N r2 regtype)



timer 					off  1
di "`timerlist'"
foreach t of local timerlist {
timer	list `t' // timers have to be listed sequentially
}
di 						"Loop with `data' completed." 
estimates dir
STOP
++

	
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
loc sample 		"sfull5  & d_count<8" // & d_count<8
loc agectrls 	 "age" // age c.age##c.age, leaving out cross term solves the issue
loc ctrls	 	"i.male married i.raeducl i.cohortmin5" // i.wave 
loc y 			"d_count"
sum `y' `ctrls' if `sample'==1 & wave==1



**************************************************************************************************
*Appendix*
**************************************************************************************************	


	** pre-treatment variables (before onset) ** 
	// currently using same time period to not lose observations
	loc baselinevars "workr marriedr"
	foreach v of local baselinevars{
	gen 	myvar =  `v' 	if timesinceonset == 0
	bys ID: egen `v'_baseline = max(myvar)
	drop myvar
	}

/*** +++ (full code) what predicts having any disease? (logit by wave just to check consistency (not for paper)), then (xt)logit using pooled sample +++ ***
** logit by wave **
levelsof time, local(levels)
foreach l of local levels{
eststo logit`l': qui logit d_any c.age  male marriedr i.raeducl*  if time==`l', or 
estadd loc time  "`l'" 
}
esttab logit*,  stats(N r2_p time) nobase eform // `esttab_opt'
	*export results using wave 1 only*
	sum time, meanonly 
	loc l = r(min)
	eststo logit`l': qui logit d_any c.age  male i.raeducl* marriedr  if time==`l', or 
	eststo logit`l'ctrls: qui logit d_any c.age  male i.raeducl* marriedr retempr smokenr if time==`l', or 
	estadd loc time  "`l'", replace: logit*
	loc    esttab_opt "la nobase nocons stats(N r2_p time) eform"
	esttab logit`l'*, 									 `esttab_opt'  
	esttab logit`l'* using "$outpath/reg/o_logit_d_any", `esttab_opt' tex replace
	STOP
*/
	
