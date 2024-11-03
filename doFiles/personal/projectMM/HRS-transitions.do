=



// 	*** +++ show if there is any duration dependence +++ ***
// ** duration with c conditions **
// gen duration = 0  // only generate for cases when count is 1 and not missing 
// sum d_count, meanonly
// loc d_count_max = r(max)
// forval i=1/`d_count_max'{
// bys ID (time): replace duration = cond(d_count==`i',   cond(diff_d_count==0, duration[_n-1]+1,1),duration)
// **# Bookmark #2 could correct duration for when people jump down again to lower count
// *bys ID (time): replace duration = cond(d_count==`i'|d_count==`i'-1,   cond(diff_d_count==0|diff_d_count==-1, duration[_n-1]+1,1),duration) // if sb goes from 3 to 2 to 3, the first 3 is considered in calcuation of duration
// }
// replace duration = . if mi(d_count) // if count missing, duration should be missing
//
// *	bro ID wave d_count* diff_d_count* duration if ID==10013010
// *	bro ID wave d_count* diff_d_count* duration if ID==10063010
//
// 	**remove durations if left-censored duration**
// 	bys ID: egen d_count_min = min(d_count)
// 	replace duration = . if d_count_min==d_count // do not know if entered survey already with condition
//
// 	**#use only observations before a transition ** 
// 	bys ID (duration): egen durationmax = max(duration)
// 	replace duration = . if duration!= durationmax	// 
// 	drop durationmax
//
// 	sum duration*
// 	tab duration time
// 	*bro ID time d_count d_count_lead duration

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

		