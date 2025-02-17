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
loc agethreshold 	"50" // select survey-specific lower age threshold (needed for labels)
}
if "`data'"=="ELSA" {
loc agethreshold 	"50" // select survey-specific lower age threshold
}
if "`data'"=="HRS" {
loc agethreshold 	"51" // select survey-specific lower age threshold
}	
	if "`data'"=="SHAREELSA" {
	loc agethreshold 	"50" // select survey-specific lower age threshold
	}	
	*STOP /*comment to continue running file*/
***********
cd  	"$outpath/tab"
gl  diseasecodelist "hibp diab heart lung depr osteo cancr strok arthr demen" // psych
gl  diseaselist 	"d_hibp d_diab d_heart d_lung d_depr d_osteo d_cancr d_strok d_arthr d_demen"
**# Bookmark #1 I drop the cohortselection in all files except vizualization (when plotting against time)
	drop if cohortselection==0 
	drop if mi(age) // these are missing observations/time periods (should not drop these for survival plot)
	tab hacohort


***************************************************************************************************
*Part 7a*: Regression (define .do file)
***************************************************************************************************
*** define locals to apply to entire file ***
gl sample 			"sfull5" // copy these lines if a specific subsample shall apply to specific plot
gl opt_global 		"" // settings to apply to all graphs 
set scheme s1color
]]


*** check if any condition is perfectly predicted by age (based on age-eligiblity to the question) ***
log using 	"`h_data'/log-diseasebycohort.txt", text replace name(log)
foreach d of local alldiseasesd  {
tab agegrp5 `d'	,m /*if nothing is odd, would seem okay. If we have more people entering later 
(e.g. inw1==0 & inw2==1, or based on hacohort), this could lead to a jump in the graphs */
} 
log close log
*/


***************************************************************************************************
*Part 7b*: Regression (general)
***************************************************************************************************	

*** +++ what predicts having any disease? (logit by wave just to check consistency (not for paper)), then (xt)logit using pooled sample +++ ***
/** logit by wave **
levelsof time, local(levels)
foreach l of local levels{
eststo logit`l': qui logit d_any c.age  male marriedr i.raeducl*  if time==`l', or 
estadd loc time  "`l'" 
}
esttab logit*,  stats(N r2_p time) nobase eform // `esttab_opt'
STOP
*/


** what predicts an earlier onset ? **
sum onset*
	gen  myvar 	= d_any if inrange(age,50,54) 
	bys ID: egen d_anyat50to55 = max(myvar)
	drop myvar 
	la var d_anyat50to55 "had disease at 50-54)"
	gen  myvar 	= smokenr if inrange(age,50,54) 
	bys ID: egen smokeat50to55 = max(myvar)
	drop myvar 	
	la var smokeat50to55 "smoked at 50-54"

loc ctrl "male i.raeducl d_anyat50to55  smokeat50to55"
eststo tobit: tobit onsetage `ctrl' if `sample'==1 &  time==`l', ll(agemin) 
estadd loc time  "`l'", replace
loc    esttab_opt "la nobase nocons stats(N r2_p time) eform"
esttab tobit, `esttab_opt'   // stats(N) 									 
esttab tobit using "$outpath/reg/t_tobit_onsetage_`sample'", `esttab_opt'   tex replace frag // stats(N) 									 
STOP
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

	



	

++++++		STOP // here to not overwrite current output
		

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
	
