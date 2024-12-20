
pause on
pause off
log close _all 	/*closes all open log files*/
clear all		/*clears all data in memory*/

***choose data***
loc data 		"HRS"

***define folder locations***
if "`c(username)'" == "P307344" { // UWP server
loc cv 		"X:/My Documents/XdrvData/`data'/"
loc outloc 	"`cv'" // to save locally 
*loc outloc "\\Client\C$\Users\User\Documents\GitHub\2-projectMM-`data'\" // from UWP save directly to PC (only works with full version of Citrix)
}
else {
loc	cv 		"C:/Users/`c(username)'/Documents/RUG/`data'/"
loc	outloc 	"C:/Users/`c(username)'/Documents/GitHub/2-projectMM-`data'" 	
}
gl 	outpath 	"`outloc'/files" /*output folder location*/
loc saveloc 	"main" // main | supplement /*saving location*/
loc altsaveloc  "allfigs" // saving location of all plots/subplots
cd  			"`cv'"	
use 			"./`data'data/harmon/H_`data'_panel2-MM.dta", clear	

**define country-specific locals**

***********
cd  	"$outpath/tab"
gl  diseasecodelist "hibp diab heart lung depr osteo cancr strok arthr demen" // psych
gl  diseaselist 	"d_hibp d_diab d_heart d_lung d_depr d_osteo d_cancr d_strok d_arthr d_demen"
**# Bookmark #1 I drop the cohortselection in all files except vizualization (when plotting against time)
	*drop if cohortselection==0 
// 	drop if mi(age) // these are missing observations/time periods (should not drop these for survival plot)
	tab hacohort

	
	
	
***************************************************************************************************
*Part 7a*: Vizualization (Do File Setup, variable and local definitions) 
***************************************************************************************************
*** define locals to apply to entire file ***
// 	gl sample 		"sfullsample" // sfullsample, sbalanced, sfull5 (choose what is best)
// 	gl samplelabel: variable label $sample
gl sample 			"sfullsample" // copy these lines if a specific subsample shall apply to specific plot
gl opt_global 		"" // settings to apply to all graphs 
set scheme s1color

*** define additional variables ***
*** age groups ***
gen 	agegrp 	= age
replace agegrp 	= 85 if agegrp>90 & agegrp<. /*group few very old*/
la var  agegrp 	"age"
*tabstat age, by(agegrp) stats(min max)


/** install packages **
net install transcolorplot , from(http://www.vankerm.net/stata)
net describe transcolorplot
ssc install spgrid // needed for transcolorplot
ssc install spmap // needed for transcolorplot
*/


*************************************************
*** +++ 2-y transition probability +++ *** 
*************************************************

/*** transcolorplot ***
preserve 
sort ID time 
sum d_count, meanonly
loc v = `r(max)'+1
recode d_count_lead (99 = `v')	 // otherwise plot is highly skewed
transcolorplot d_count d_count_lead if !mi(d_count), discrete title("transcolorplot (d_count to d_count_lead)") note("the plot includes d_count_lead==dead")
gr export 	"$outpath/fig/main/g_transcolorplot.jpg", replace quality(100)
restore
STOP
*/

/*** Scatterplot of means by age ***
tab 	d_count d_count_lead, nofreq row matcell(test)
mat li test 
qui log using 		"$outpath/tab/tablogs/t-transitions.txt", text replace name(log) 
xttrans d_count
qui log close log

sum d_count_lead if d_count_lead!=99, meanonly 
loc v = r(max)+2 // 0 and plus one  	
tab d_count_lead, gen(d_count_lead_) // for stacked bar chart
collapse (mean) d_count_lead_* , by(d_count agegrp) 
		unab list: d_count_lead_* 
		di "`list'"
		foreach var of local list {
			loc vla: var la `var'
			loc pos = strpos("`vla'", "_") + 12
			loc number = substr("`vla'", `pos', .)		 
			di "`number'"
		la var `var' "c_{i,t+1}=`number'" 
		}
la var d_count_lead_`v' "c_{i,t+1}=dead" 
twoway (scatter d_count_lead_1 agegrp) (scatter d_count_lead_2 agegrp) (scatter d_count_lead_3 agegrp) (scatter d_count_lead_4 agegrp) (scatter d_count_lead_5 agegrp) (scatter d_count_lead_6 agegrp) (scatter d_count_lead_`v' agegrp)     if inrange(d_count,1,4), by(d_count,  title("Transitions by age conditional on count before transition") legend( position(6)))  scheme(s1color) xla(50(5)90)  legend(cols(4))
gr export 	"$outpath/fig/main/g_transitions_bycount.pdf", replace 
STOP 
*/

		/*preserve  (does the same as above, just much more complicated)
		**start plot**
		forval gamma=0/4{ // only from 4 starting states
			sum d_count if d_count!=99, meanonly 
			loc d_countmax = r(max)
			*loc    j=2
			forval j=0/`d_countmax'{
		// indicator of WHETHER transiting to specific condition
		gen trans_`gamma'to`j' = (d_count == `gamma' & d_count_lead == `j') if !mi(d_count) & !mi(d_count_lead) & d_count==`gamma' 
		tab trans_`gamma'to`j' d_count
		}
		gen trans_`gamma'todead = (d_count == `gamma' & d_count_lead == 99) if !mi(d_count) & !mi(d_count_lead) & d_count==`gamma' 
		}
		sum trans_*	
		// STOP

			set graphic on
			**crude plotting: transition by age**
			loc 	col "gs10"
			loc 	x "age"
			loc 	gamma=2
			forval gamma=0/4{
			preserve
			collapse (mean) y1 = trans_`gamma'to1 (mean) y2 = trans_`gamma'to2 (mean) y3 = trans_`gamma'to3 (mean) y4 = trans_`gamma'to4 (mean) y5 = trans_`gamma'to5 (mean) y6 = trans_`gamma'to6 (mean) dead = trans_`gamma'todead   if age<85, by(`x')
				local labellist  `labellist' `counter' `"d_count=`valuel'"'   
				loc labellist 1  `"trans_`gamma'to1"' 2 `"trans_`gamma'to2"' 3 `"trans_`gamma'to3"' 4 `"trans_`gamma'to4"' 5 `"trans_`gamma'to5"' 6 `"trans_`gamma'to6"' 7 `"trans_`gamma'todead"'
				mac list _labellist 
			twoway 	(scatter y1 `x') (scatter y2 `x') (scatter y3 `x') (scatter y4 `x') (scatter y5 `x') (scatter y6 `x') (scatter dead `x')  (lowess y1 `x', lcolor(`col'))  (lowess y2 `x', lcolor(`col'))  (lowess y3 `x', lcolor(`col'))  (lowess y4 `x', lcolor(`col')) (lowess y5 `x', lcolor(`col')) (lowess y6 `x', lcolor(`col')) (lowess dead `x', lcolor(`col')) ///
			  , title("2-year transition probability: `gamma' to j") xla(50(5)85)  name(g_`gamma', replace)  legend(cols(3) ///
			 order(`labellist')) // ) //  
			*gr export 	"$outpath/fig/main/g_by`x'_transp_`gamma'toj.jpg", replace `jpghighquality'
			restore
			}
			STOP
			*/	
	
	



//	
//
// *** generate duration with c conditions ***
//
// 	* this generates duration of CONSECUTIVE periods
// 	* problems:
// 	* some people switch 2-1-2-1-2-1, duration here jumps back to 1 
// gen duration = 0 if d_count>0 & !mi(d_count) // only when count is 1 and not missing 
// sum d_count, meanonly
// loc d_count_max = r(max) // maximum disease count across all i
// forval i=1/`d_count_max'{
// bys ID (time): replace duration = cond(d_count==`i',   cond(diff_d_count==0, duration[_n-1]+1,1),duration)
// 	}
// *replace duration = . if mi(d_count) // if count missing, duration should be missing (this line should make 0 changes)
// la var duration 			"(consecutive) t with c conditions"
//
// 	**set duration to missing if left-censored (do not know the 'true' duration)**
// 	bys ID: egen d_count_min = min(d_count)
// 	**# Bookmark #3 problem if count is 2-0-1-1-1-1-, then 1 is taken as min and the first time period is not missing duration
// 		*replace duration = . if d_count_min==d_count // do not know if entered survey already with condition
// 	gen		 duration_uncens = duration if d_count_min!=d_count
// 	la var 	 duration_uncens	"(consecutive) t with c conditions (uncensored)"
//
//	
** check duration correctly generated **
sum duration* 		// max duration should not be larger than time interval 
tab duration time	// should 
sum time, meanonly 
loc timediff = (r(max)-r(min))/2
di "`timediff'" // should equal to the maximum of duration above
		*	bro ID wave d_count* diff_d_count* duration if ID==10013010
		*	bro ID wave d_count* diff_d_count* duration if ID==10063010
	*li ID time d_count duration in 1/50 if !mi(d_count)
		sum duration*
	**# Bookmark #3 check this for SHARE. Sth with duration is generated incorrectly when there is a gap
		*bro ID wave d_count_min d_count duration duration_uncens	
		*++
		*/

	/**count from first onset onwards for durations, ignoring "recovery" **	
	*bys ID (time): replace duration = cond(d_count==`i'|d_count==`i'-1,   cond(diff_d_count==0|diff_d_count==-1, duration[_n-1]+1,1),duration) // if sb goes from 3 to 2 to 3, the first 3 is considered in calcuation of duration
	// 	gen 	d_count2 = d_count
	// 	replace d_count2 = d_count - diff_d_count if diff_d_count < 0
	// 	*tab d_count d_count2
	// 	*sort ID time
	// 	bys ID: gen 	diff_d_count2 = d_count2 - L.d_count2
	// 	bro ID wave d_count* diff_d_count* duration if ID==10013010
	// 	*/

	
	/**crude plotting: transition by duration in state**
	loc 	col "gr10"
	loc 	x "duration"
loc cohortvar "cohort"
loc cohort 		"50"
	loc 	gamma=1
forval gamma=0/4{
**foreach cohort in 50 60 70 80{
*loc cohortlabel: label (`cohortvar') `cohort'
	preserve
*	keep if `cohortvar'==`cohort'
	collapse (mean) y1 = trans_`gamma'to1 (mean) y2 = trans_`gamma'to2 (mean) y3 = trans_`gamma'to3 (mean) y4 = trans_`gamma'to4 (mean) y5 = trans_`gamma'to5 (mean) y6 = trans_`gamma'to6 (mean) dead = trans_`gamma'todead   if age<85, by(`x' cohort)
	twoway 	(connected y1 `x') (connected y2 `x') (connected y3 `x') (connected y4 `x') (connected y5 `x') (connected y6 `x') (connected dead `x') ///
      ,  by(cohort, title("2-year transition probability by `x': `gamma' to j")) name(g_`gamma', replace) legend(cols(3)) 			
	gr export 	"$outpath/fig/main/g_by`x'_transp_`gamma'toj.jpg", replace `jpghighquality'
	restore	
}	
}
	++
	

*** +++ show if there is any duration dependence +++ ***
	*bys d_count: tab d_count_lead if sfull==1 & age<=90
	loc y 		"d_count_lead"
	loc x 		"duration"
	loc 	i=1
	*forval  i=1/4{
	*preserve 
		set seed 200
		*sample 10
		loc sample "sfull"
// 		**labellist needs to be located here after preserving data (some levels are not in some plots)
// 		keep if d_count==`i'
// 		loc counter   "1"
// 		loc labellist "" /*need to delete local if in loop*/		
// 		loc z 		 "d_count_lead"
// 		levelsof `z', local(levels)
// 		foreach l of local levels{
// 		loc 	valuel : label (`z') `l'				
// 		local labellist  `labellist' `counter' `"lead=`valuel'"'   
// 		loc counter = `counter'+1	
// 		}	

// levelsof 	cohort, local(levels)
// loc 		cohort "50"
// *foreach  cohort of   local levels {
// loc cohortlabel : label (agegrpmin5) `cohort'
// loc cohortlabel "(`cohortlabel')"  /*add parentheses if subplots*/
		ologit 	 d_count_lead i.duration if `sample'==1 & cohort==50 & d_count==`i', 
*		predict pr2b, pr equation(#1) // same as equation(0), bc that is the first equation		
		predict phat0, 	pr equation(0)
		predict phat, 	pr outcome(0)
		predict pr1b, 	pr outcome(1)
		predict prdead, pr equation(99)		
*		predict pr4b, pr equation(4,5)	
		predict phat1, pr // what does this line do? Simply predicts the outcomes in the same order as varnames are specified
	*	predict pr0 pr1 pr2 pr3 pr4 pr99, pr // same as -predict phat1b, pr outcome(#) [or equation(#)]-

		sort age
		*bro age pr0
			*twoway line pr0 age // weigh graph **
	qui margins `x'	, predict(outcome(0)) 
	marginsplot, name(gr0, replace) noci
	qui margins `x'	, predict(outcome(1)) 
	marginsplot, name(gr1, replace) noci
	qui margins `x'	, predict(outcome(2)) 
	marginsplot, name(gr2, replace) noci
	*qui margins `x'	, expression(predict(outcome(3)) + predict(outcome(4)) + predict(outcome(5))) 
	*marginsplot, name(gr3, replace) noci
	qui margins `x'	, predict(outcome(99))  
	marginsplot, name(grdead, replace) noci
		qui margins `x'	,   
		marginsplot, name(grall, replace) noci
	gr combine gr0 gr1 gr2 grdead , name(combined, replace)

	, title("Predicted `y' by `x', count before transition: `i'") note("Sample: `samplelabel' | Controls: `ctrls' (none)" "Model: `reg'" "")  legend(order(`labellist') cols(3)) recast(line) recastci(rarea) name(g`i') // ylabel(#2) //  yscale(range(0 1))  
	gr export 	"$outpath/fig/main/g_ologit_by`x'_`y'_`i'.jpg", replace `jpghighquality'
	restore
	}	
	pause
	*STOP
	*/	



tab d_count_lead, gen(d_count_lead_) // for stacked bar chart
**correct  numbering of dummy variables: -tab,gen()- names first category 0 as 1 instead of 0**
sum d_count_lead if d_count_lead!=99 , meanonly
loc d_count_lead_max = r(max) +1 // +1 for 'dead' dummy 
forval i=1/`d_count_lead_max'{
loc j = `i'-1
rename d_count_lead_`i' d_count_lead_`j' // rename dummy to the actual value
}
sum d_count_lead*



		
/*** plot duration dependence: d_count_lead by duration ***
*loc y "d_count_lead"
loc x 	  "duration" // d_count
loc ctrls ""
loc startcount = 1

loc cohortvar "cohort"
loc cohort 		"50"
*foreach cohort in 50 60 70 80{
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
gr export 	"$outpath/fig/main/g_barby`x'_`sample'_`cohort'.jpg", replace `jpghighquality'
restore 
*/
// 	loc x "duration"
// 	loc i = 1
// 	forval i=1/4{
// 	loc reg 	ologit 	 d_count_lead i.`x' if `sample'==1 & age<=90 & `cohortvar'==`cohort' & d_count==`i' & countatfirstobs==0, 
// 	eststo m1: qui `reg'
// 	qui margins `x'	// no dydx
// 	marginsplot, title("Predicted `y' by `x', count before transition: `i'") note("Sample: `samplelabel' | Controls: `ctrls' (none)" "Model: `reg'" "")  legend( cols(3)) noci //  recast(line) recastci(rarea) // ylabel(#2) //  yscale(range(0 1))  legend(order(`labellist'):: should not use labellist here bc the legend mislabels then if e.g. outcome 2 is missing
// 	*gr export 	"$outpath/fig/main/g_ologit_by`x'_`y'_`i'.jpg", replace `jpghighquality'
// 	}	
	** archive code: use if plot separate plots **
	*qui sum d_count_lead if `sample'==1 & d_count_lead!=99 & d_count == `startcount', meanonly 
	*forval startcount = 1/4 { // no 0 bc there is no duration with 0 conditions
*graph bar (mean) d_count_lead_* if `sample'==1 & d_count==`startcount' & cohort==`cohort', over(`x') name(g_trans`startcount', replace) stack title("# diseases before transition: `startcount' | `cohortlabel'")  legend(order(`labellist'))  // do separate for each age cohort // xla(,label("Number of Periods with `startcount' conditions")) // over(d_count)	
	*gr combine g_trans1 g_trans2 g_trans3 g_trans4,
	*}
*pause
*/				





// note: currently people might jump back to earlier count and duration drops again; can try to enforce strictly increasing data
// 		// ?? not working with gaps when a period missing but present in dataset (e.g. in SHARE), but this is not a problem if the missing time period is dropped


*mtable	



	*** +++ "prevalence of" prob of exiting to another state +++ ***
			/** generate exit probabilities as variables ** 
				**should be identical to the probabilities predicted from within the ologit model**
			loc i "1"
			*forval i=1/4{
			*gen prc2givenc1	= 2 if d_count==1
			tab d_count_lead if d_count==1,  // sum(raeducl) // plot
			*tab does not work*
				gen myvar1=1 if d_count==1 & d_count_lead==2 
				gen myvar2=1 if d_count==1 
					bys age: egen myvar1n = _n if myvar1==1
				gen prd1tod2 = myvar1/myvar2 
				+
			*}
			*/
			
			
	/*** ++ ordered logit with duration dependence (will move later to reg file due to duration variable) ++ ***
	** cs data **
	*preserve 
	recode  d_count_lead (99 = . ) // do not model mortality in ordered logit
	replace duration_uncens = 5 if duration_uncens>5 & !mi(duration_uncens) // setting maximum duration dependence T
	*hist duration_uncens
	ologit d_count_lead c.age c.age#c.age c.age#c.d_count c.age#c.age#c.d_count , vce(cl ID)
	*log using 		"$outpath/logs/log-t-regd_count-age-ologitduration.txt", text replace name(ologitduration) 
	ologit d_count_lead i.d_count i.duration_uncens c.age c.age#c.age c.age#c.d_count c.age#c.age#c.d_count if sfull==1, vce(cl ID)
	*log close ologitduration
		margins , dydx(duration_uncens) at(age=(`agethreshold'(5)90) countatfirstobs=0)
		marginsplot, label(order 1 "")	
	++
	
	** panel data **
	xtologit
	
	++
	*/	
	
	
	
	
**** archive ****
/* 
**	ologit**
*loc reg 	xtologit `y' i.`x' if `sample'==1, nolog vce(cl ID)  // c.age#c.age  male married i.raeducl*, 
loc reg 	ologit `y' i.`x'  if `sample'==1 & d_count==`startcount', nolog vce(cl ID) // c.age#c.age  male married i.raeducl*
`reg'
margins i.`x' // , dydx(`x')	
*margins , dydx(`x')	
marginsplot, note("Notes: Sample: `samplelabel'" "Controls: `ctrls' (none)" "Command: `reg'") name(mh1, replace) 
gr export 	"$outpath/fig/main/g_ologit_by`x'_`y'_`startcount'.jpg", replace `jpghighquality'
	loc ctrls "male married i.raeducl*"
	loc reg 	ologit `y' i.`x' `ctrls' if `sample'==1  & d_count==`startcount', nolog vce(cl ID) // c.age#c.age  male married i.raeducl*
	`reg'
	margins `x' // , dydx(`x')	
	marginsplot, note("Notes: Sample: `samplelabel'" "Controls: `ctrls' (none)" "Command: `reg'") name(mh2, replace) 
	gr export 	"$outpath/fig/main/g_ologit_by`x'_`y'_`startcount'_adj.jpg", replace quality(100) 
 	STOP
*/	
		
		
	**
	**using logistic fit (only single outcome allowed (I think, unless able to combine margins to a single marginsplot) - the solution is to predict the margins for the ordered logit)**
	logit trans_1to2 c.age
	margins , at(age=(51(10)90))
	marginsplot 
	STOP
	*/
	