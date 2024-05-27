pause on
*pause off
log close _all 	/*closes all open log files*/
clear all		/*clears all data in memory*/


***choose data***
loc data 		"SHARE"
	*loc append_iterationlog "replace" 		
	/*short iteration log at the end of the loop*/ 
loc datalist 	"SHARE ELSA HRS"
*foreach data of local datalist {

***define folder locations***
if "`c(username)'" == "P307344" { // UWP server
loc cv 		"X:/My Documents/XdrvData/`data'/"
loc outloc 	"`cv'" // to save locally 
*loc outloc "\\Client\C$\Users\User\Documents\GitHub\2-projectMM-`data'\" // from UWP save directly to PC (only works with full version of Citrix)
}
else {
loc	cv 		"G:/My Drive/drvData/`data'/" // own PC
	*loc cv 	"C:\Users\User\Documents\RUG/`data'"
loc	outloc 	"C:/Users/User/Documents/GitHub/2-projectMM-`data'" // do not overwrite existing output in the compiled output	
}
gl 	outpath 	"`outloc'/files" /*output folder location*/
loc saveloc 	"main" // main | supplement /*saving location*/
cd  			"`cv'"	
use 			"./`data'data/harmon/H_`data'_panel2-MM.dta", clear	
	pause

**define country-specific locals**
if "`data'"=="CHARLS" {
loc agethreshold 	"45"
loc upperthreshold	"75"
// loc ptestname 	"cesdr"
// loc pthreshold	"3"
*loc t 				"ruralh" // /*categorical variable to split by*/ 	
}
if "`data'"=="SHARE" {
loc agethreshold 	"50" // select survey-specific lower age threshold
loc upperthreshold	"85" // select survey-specific upper age threshold	
loc wavelast 		"8" 	// select survey-specific last wave
// loc ptestname 	"eurod"
// loc pthreshold	"4"
	drop if wave==3 // is not really a time period, there are no regular variables for this wave
	keep 	if hacohort==1 | hacohort==2 
	drop 	if countryID=="GR" /*relatively imprecise survey*/
}
if "`data'"=="ELSA" {
loc agethreshold 	"50" // select survey-specific lower age threshold
loc upperthreshold	"85" // select survey-specific upper age threshold	
loc wavelast 		"9" 	// select survey-specific last wave
// loc ptestname 	"cesdr"
// loc pthreshold	"4"
}
if "`data'"=="HRS" {
loc agethreshold 	"51" // select survey-specific lower age threshold
loc upperthreshold	"85" // select survey-specific upper age threshold	
loc wavelast 		"14" 	// select survey-specific last wave
// loc ptestname 	"cesdr"
// loc pthreshold	"4"
	keep 	if hacohort<=5 	
	keep if wave>=3 & wave<=13 // cognitive measures not consistently available 		
}	
if "`data'"=="SHAREELSA" {
loc agethreshold 	"50" // select survey-specific lower age threshold
loc upperthreshold	"85" // select survey-specific upper age threshold	
loc wavelast 		"9" 	// select survey-specific last wave
// loc ptestname 	"cesdr"
// need to do correct this accordingly
// loc pthreshold	"3"
	drop if agemin<50  & dataset=="SHARE"
	drop if agemin<50  & dataset=="ELSA"
	*drop if wave==3    & dataset=="SHARE" // already dropped
	drop if hacohort>2 & dataset=="SHARE"  
}	
drop if agemin<`agethreshold'	
**********************


****************************************************************************************************
*Part 7a*: Regression (define .do file)
****************************************************************************************************	

*cd  	"$outpath/tab"


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



*** additional variables *** 
tab raeducl, gen(raeduclcat) // separate variables needed for regoprob2
drop 	raeduclcat1
rename 	raeduclcat2 educ_vocational
rename  raeduclcat3 educ_university


*** definition of global vars ***
loc sample "sfull"
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


****************************************************************************************************
*Part 7b*: Regression (general)
****************************************************************************************************	
	
/*** +++ what predicts having any disease? (logit by wave just to check consistency (not for paper)), then (xt)logit using pooled sample +++ ***
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
	pause
*/

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

	*/
	*** +++ transitions +++ ***
	loc ctrls "i.raeducl i.male" // i.countatfirstobs
	
	
	
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
	
/*** Linear Random Effect model (Mixed Model) for SHARE AND ELSA (need data "SHAREELSA") ***	
	*relabel time for narrower table* 
	preserve 
	*keep if d_anyatfirstobs == 0
	*keep if cohortmin==50
	tab d_count
	la var timesincefirstobs "time(sinceb)"
	loc ctrls "male i.raeducl"
eststo xtregSHARE: qui xtreg d_count c.timesincefirstobs i.cohortmin5 i.cohortmin5#c.timesincefirstobs `ctrls'	if sfull==1 & dataset=="SHARE", robust // vce(cl ID) 
eststo xtregELSA:  qui xtreg d_count c.timesincefirstobs i.cohortmin5 i.cohortmin5#c.timesincefirstobs `ctrls'	if sfull==1 & dataset=="ELSA", robust // vce(cl ID) 

loc esttab_opt "nobase compress la se(%9.2f) stats(N controls) mtitles("SHARE" "ELSA")" // r2
	estadd loc controls "yes": xtregSHARE xtregELSA
esttab xtregSHARE xtregELSA , `esttab_opt' 
*esttab xtregSHARE xtregELSA  using "C:/Users/User/Documents/GitHub/2-projectMM-SHARE/files/t_regd_count-timesincefirstobs-xtregSHAREELSA", tex replace  `esttab_opt' note("Controls include `ctrls'") keep(timesincefirstobs *#c.timesincefirstobs)  // stats(N controls)

** with age (instead of time) and cohort dummies **
	loc interactions "male#c.age i.raeducl#c.age i.countatfirstobs i.countatfirstobs#c.age"
	loc ctrls "`ctrls' `interactions'"
eststo xtregSHARE:  xtreg  d_count c.age `ctrls'	if sfull==1 & dataset=="SHARE", robust fe i(rabyear) // fe due to cohort dummies // vce(cl ID) // c.age#c.age
eststo xtregELSA: qui xtreg   d_count c.age `ctrls'	if sfull==1 & dataset=="ELSA",  robust fe i(rabyear) // fe due to cohort dummies  // vce(cl ID) 
loc esttab_opt "nobase compress la se(%9.2f) stats(N r2 controls) mtitles("SHARE" "ELSA")"
	estadd loc controls "yes": xtregSHARE xtregELSA
esttab xtregSHARE* xtregELSA , `esttab_opt' 
*esttab xtregSHARE xtregELSA  using "C:/Users/User/Documents/GitHub/2-projectMM-SHARE/files/t_regd_count-age-xtregSHAREELSA", tex replace  `esttab_opt' note("Controls include `ctrls'")  keep(age *#c.age)   // stats(N controls)
STOP 
*/


	/*** Linear RE model with first onset ***
		preserve
			hist firstage 
			hist firstage if d_anyatfirstobs==0
		replace firstage = . if d_anyatfirstobs>0

			loc firstagel: var label firstage 
			la var firstage "`firstagel' - Healthy-at-baseline sample"
			*gr export 	"$outpath/fig/main/g_hist_firstage.jpg", as(jpg) replace 
		loc ctrls "male i.raeducl  male#c.age i.raeducl#c.age i.countatfirstobs i.countatfirstobs#c.age  c.firstage#c.age   " // i.firstage
	eststo xtregSHARE: qui xtreg  d_count c.age `ctrls'	if sfull==1 & dataset=="SHARE", robust fe i(rabyear) // vce(cl ID) // c.age#c.age
	eststo xtregELSA: qui xtreg  d_count c.age `ctrls'	if sfull==1 & dataset=="ELSA" , robust fe i(rabyear) // vce(cl ID) // c.age#c.age
	loc esttab_opt "nobase compress la se(%9.2f) stats(N r2 controls) mtitles("SHARE" "ELSA")"
	esttab xtregSHARE xtregELSA , `esttab_opt' 
	esttab xtregSHARE xtregELSA  using "C:/Users/User/Documents/GitHub/2-projectMM-SHARE/files/t_regd_count-age-xtregSHAREELSA-firstage", tex replace  `esttab_opt' note("Controls include `ctrls'")  keep(age *#c.age)   // stats(N controls)
	STOP
	*/

	** ordered logic as De nardi
	loc ctrls "i.duration"
	ologit 	`y' age c.age#c.age `ctrls' if `sample'==1 & dataset=="`data'", vce(robust)
	

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
esttab regoprob2`data' 			using "$outpath/t_regd_count-age-regoprob2`data'", tex replace
esttab regoprob2`data' 			using "$outpath/t_regd_count-age-regoprob2`data'", html replace
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
esttab gologit2`data'     		using "$outpath/t_regd_count-age-gologit2`data'", tex replace
esttab gologit2`data'			using "$outpath/t_regd_count-age-gologit2`data'", html replace
*/

** ologit ** 
log using 		"$outpath/logs/log-t-regd_count-age-ologit`data'.txt", text replace name(ologit) 
eststo ologit`data': 	ologit 	`y' age `ctrls' if `sample'==1 & dataset=="`data'", vce(robust) // ologit using all waves
estadd local regtype "ologit"
estimates save "$outpath/logs/t-regd_count-age-`data'estimates" , append //  `append_estimates'
*brant, detail // brant only works on ologit; not xtologit. xtologit and ologit are not identical when only 1 time period is used; brant does not work with d_count>=8 because of perfect prediction 
qui log close 	ologit 
esttab ologit`data' 	    	using "$outpath/t_regd_count-age-ologit`data'", tex replace
esttab ologit`data'				using "$outpath/t_regd_count-age-ologit`data'", html replace
*STOP
*/


*** xt-ordered logit (again considering panel dimension) ***
log using 		"$outpath/logs/log-t-regd_count-age-ologit`data'.txt", text replace name(xtologit) 
eststo xtologit`data': xtologit 	`y' age `ctrls'	if `sample'==1 & dataset=="`data'", vce(cluster ID)  // -vce(cl ID)- is equivalent to -robust-
estadd local regtype "xtologit"
estimates save "$outpath/logs/t-regd_count-age-`data'estimates" , append // `append_estimates'
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




*di "`append_iterationlog'" // could have single file if path specified as single location
log using 				"$outpath/logs/iterationlog.txt", text replace name(iterationlog) 
*loc append_iterationlog "append" /*append after this*/ 
timer 					off  1
di "`timerlist'"
foreach t of local timerlist {
timer	list `t' // timers have to be listed sequentially
}
di 						"Loop with `data' completed." 
estimates dir
log close iterationlog
restore
}

STOP

++










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

	/*** sequential logit ***
	*log using 	"$outpath/logs/log-t-regd_count-age-seqlogit`data'.txt", text replace name(seqlogit) 
	set seed 500
	// tab d_count, gen(d_count)
	preserve
		keep if d_count<7
		sample 10
	eststo seqlogit: seqlogit d_count age male i.raeducl if `sample'==1 if d_count==1, vce(cluster ID) tree(0:1 2 3 4 5 6, 1:2 3 4 5 6, 2: 3 4 5 6, 3: 4 5 6, 4: 5 6, 5:6) ofinterest(raeducl) over(c.age) or 
	*seqlogitdecomp age, table // at(coh 1.5 south 0 paeduc 12) table
	seqlogitdecomp, area // at(male 0 educ_vocational 0 educ_university 0)
	*log close seqlogit
	timer 		off  1
	timer 		list 1	
	STOP
	*/
	
	
		/*** multinomial logit ***
	*https://www.stata.com/features/overview/panel-data-multinomial-logit/
	sample 1
	count 
	*log using 	"$outpath/logs/log-t-regd_count-age-mlogit`data'.txt", text replace name(mlogit) 
		xtset ID
		keep if d_count_lead<4
	eststo mlog1: xtmlogit d_count_lead  `ctrls' age  if `sample'==1 , base(1) nolog rrr vsquish re // vce(cluster ID) & d_count==1 covariance(unstructured) rrr // fe for conditional fixed effects 
	
	margins raeducl, at (age=(50(5)85))
	marginsplot, by(_predict) 
	log close mlogit
	++
	predict p1 p2 p3 p4 p5 p6 p7 p8 p9	
	*predict p1 p2 p3 p4 p5 p6 p7 p8 p9 p10 p11
	twoway (line p1 age if raeducl==1) (line p1 age if raeducl==2) (line p1 age if raeducl==3) 
	twoway (line p2 age if raeducl==1) (line p2 age if raeducl==2) (line p2 age if raeducl==3)	
	*margins 
	*marginsplot	
	*esttab mlog1 using "$outpath/t-regd_count-cohort-mlogit.tex", b se nobase nogaps replace
	*esttab mlog1 using "$outpath/t-regd_count-cohort-mlogit.html", b se nobase nogaps replace
	STOP
		* should do this for every count before transition, for every ____, also do a marginsplot
		
		marginsplot 
		
	*/
	
