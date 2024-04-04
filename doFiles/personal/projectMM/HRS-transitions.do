pause on
*pause off
log close _all 	/*closes all open log files*/
clear all		/*clears all data in memory*/



***choose data***
loc data "HRS"


***define folder locations***
if "`c(username)'" == "P307344" { // UWP server
loc cv 		"X:/My Documents/XdrvData/`data'/"
loc outloc 	"`cv'" // to save locally 
*loc outloc "\\Client\C$\Users\User\Documents\GitHub\2-projectMM-`data'\" // from UWP save directly to PC (only works with full version of Citrix)
}
else {
loc	cv 		"G:/My Drive/drvData/`data'/" // own PC
loc	outloc 	"C:/Users/User/Documents/GitHub/2-projectMM-`data'" 	
}
gl 	outpath 	"`outloc'/files" /*output folder location*/
loc saveloc 	"main" // main | supplement /*saving location*/
cd  			"`cv'"	
use 			"./`data'data/harmon/H_`data'_panel2-MM.dta", clear	

if "`data'"=="HRS" {
loc agethreshold 	"51" // select survey-specific lower age threshold
loc upperthreshold	"85" // select survey-specific upper age threshold	
loc wavelast 		"14" 	// select survey-specific last wave
// loc ptestname 		"cesdr"
// loc pthreshold		"4"
	keep 	if hacohort<=5 	
	keep if wave>=3 & wave<=13 // cognitive measures not consistently available 		
}	
drop if agemin<`agethreshold'	
**********************
set graphics on 
*set graphics off /*disables graphics (but also -graph combine- commands) */
cd  	"$outpath/fig"


****************************************************************************************************
*Part 7a*: Vizualization (general)
****************************************************************************************************	
	
*** define additional variables ***
** age groups **
gen 	agegrp 	= age
replace agegrp 	= `upperthreshold' if agegrp>`upperthreshold' & agegrp<. /*group few very old*/
la var  agegrp 	"age"
*tabstat age, by(agegrp) stats(min max)

** death year **
// clonevar radyear2 = radyear 
// replace  radyear2=0 if mi(radyear2) // not dead people will have 
egen 	radcohort 	= cut(radage),    at (50,60,70,80,120)
replace radcohort = 0 if everdead==0
la de 	radcohortl 	0 "never dead" 50  "died at 50-59" 60 "died at 60-69" 70 "died at 70-79" 80 "died at 80+"      
la val 	radcohort radcohortl
*tab radage radcohort


*** define locals to apply to entire file ***
set scheme s1color
loc opt_global 	"scheme(s1color)"
loc sample 		"sfull" // sbalanced
loc samplelabel: variable label `sample'







	*** +++ show if there is any duration dependence +++ ***
** duration with c conditions **
gen duration = 0  // only generate for cases when count is 1 and not missing 
sum d_count, meanonly
loc d_count_max = r(max)
forval i=1/`d_count_max'{
bys ID (time): replace duration = cond(d_count==`i',   cond(diff_d_count==0, duration[_n-1]+1,1),duration)
**# Bookmark #2 could correct duration for when people jump down again to lower count
*bys ID (time): replace duration = cond(d_count==`i'|d_count==`i'-1,   cond(diff_d_count==0|diff_d_count==-1, duration[_n-1]+1,1),duration) // if sb goes from 3 to 2 to 3, the first 3 is considered in calcuation of duration
}
replace duration = . if mi(d_count) // if count missing, duration should be missing

*	bro ID wave d_count* diff_d_count* duration if ID==10013010
*	bro ID wave d_count* diff_d_count* duration if ID==10063010

	**remove durations if left-censored duration**
	bys ID: egen d_count_min = min(d_count)
	replace duration = . if d_count_min==d_count // do not know if entered survey already with condition

	**#use only observations before a transition ** 
	bys ID (duration): egen durationmax = max(duration)
	replace duration = . if duration!= durationmax	// 
	drop durationmax

	sum duration*
	tab duration time
	*bro ID time d_count d_count_lead duration

tab d_count_lead, gen(d_count_lead_) // for stacked bar chart
**correct  numbering of dummy variables: -tab,gen()- names first category 0 as 1 instead of 0**
forval i=1/11{
loc j = `i'-1
rename d_count_lead_`i' d_count_lead_`j'
}
sum d_count_lead*
		
*** +++ plot duration dependence: d_count_lead by duration +++ ***
*loc y "d_count_lead"
loc x 	  "duration" // d_count
loc ctrls ""
loc startcount = 1

loc cohortvar "cohort"
loc cohort 		"50"
foreach cohort in 50 60 70 80{
loc cohortlabel: label (`cohortvar') `cohort'
**bar graph**
	** adapt legend (i.e. include "dead") ** 
	*tab  duration d_count_lead 
	*tab  duration d_count_lead if sfull==1 & d_count==`startcount'
	qui sum d_count_lead if `sample'==1 & d_count_lead!=99, meanonly // exclude value of "dead"
	loc d_count_lead_max  = r(max) // maximum d_count_lead excluding dead status
	loc d_count_lead_dead = r(max)+2 // +2 bc first level of d_count_lead is 0	
	loc labellist 	""
	loc counter 	"1"
	forval i = 0/`d_count_lead_max'{
	loc labellist  	`labellist' `counter' `"d_count_lead=`i'"' 
	loc counter = 	`counter'+1	
	}
	loc labellist `labellist' `d_count_lead_dead' `"dead at t+1"' // add dead status to legend
	mac list _labellist	 // should not use -display-, but mac list 
	preserve
	la de  d_countl2 1 "count before transition: 1" 2 "count before transition: 2" 3 "count before transition: 3" 4 "count before transition: 4" 5 "count before transition: 5" 6 "count before transition: 6"
	la val d_count d_countl2
	*keep if countatfirstobs==0
 	keep if d_count<=6 // only do for first 4 startcounts
graph bar (mean) d_count_lead_* if `sample'==1  & `cohortvar'==`cohort', over(`x') name(g_trans`cohort', replace) stack  legend(order(`labellist') col(3)) by(d_count, title("2y transition, by # periods spent with C conditions" "(`cohortlabel')") note("Only observations before a transition are used")) ytitle(" probability")  // note("Disease count by number of periods spent with C conditions") // xla(,label("Number of Periods with `startcount' conditions")) // over(d_count)	
*gr export 	"$outpath/fig/main/g_barby`x'_`sample'_`cohort'.jpg", replace	
restore 
}
pause
*/				

		