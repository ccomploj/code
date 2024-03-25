pause on
pause off
log close _all 	/*closes all open log files*/
clear all		/*clears all data in memory*/



***choose data***
loc data "HRS"
loc datalist 	"SHARE ELSA HRS"
*foreach data of local datalist{


***define folder locations***
if "`c(username)'" == "P307344" { // UWP server
loc cv 		"X:/My Documents/XdrvData/`data'/"
loc outloc 	"`cv'" // to save locally 
*loc outloc "\\Client\C$\Users\User\Documents\GitHub\2-projectMM-`data'\" // from UWP save directly to PC (only works with full version of Citrix)
}
else {
loc	cv 		"G:/My Drive/drvData/`data'/" // own PC
	*loc cv 	"C:\Users\User\Documents\RUG/`data'"
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
// loc ptestname 		"cesdr"
// loc pthreshold		"3"
*loc t 				"ruralh" // /*categorical variable to split by*/ 	
}
if "`data'"=="SHARE" {
loc agethreshold 	"50" // select survey-specific lower age threshold
loc upperthreshold	"85" // select survey-specific upper age threshold	
loc wavelast 		"8" 	// select survey-specific last wave
// loc ptestname 		"eurod"
// loc pthreshold		"4"
	drop if wave==3 // is not really a time period, there are no regular variables for this wave
	keep 	if hacohort==1 | hacohort==2 
	drop 	if countryID=="GR" /*relatively imprecise survey*/
}
if "`data'"=="ELSA" {
loc agethreshold 	"50" // select survey-specific lower age threshold
loc upperthreshold	"85" // select survey-specific upper age threshold	
loc wavelast 		"9" 	// select survey-specific last wave
// loc ptestname 		"cesdr"
// loc pthreshold		"4"
}
if "`data'"=="HRS" {
loc agethreshold 	"51" // select survey-specific lower age threshold
loc upperthreshold	"85" // select survey-specific upper age threshold	
loc wavelast 		"14" 	// select survey-specific last wave
// loc ptestname 		"cesdr"
// loc pthreshold		"4"
	keep 	if hacohort<=5 	
	keep if wave>=3 & wave<=13 // cognitive measures not consistently available 		
}	
if "`data'"=="SHAREELSA" {
loc agethreshold 	"50" // select survey-specific lower age threshold
loc upperthreshold	"85" // select survey-specific upper age threshold	
loc wavelast 		"9" 	// select survey-specific last wave
// loc ptestname 		"cesdr"
// need to do correct this accordingly
// loc pthreshold		"3"
	drop if agemin<50  & dataset=="SHARE"
	drop if agemin<50  & dataset=="ELSA"
	*drop if wave==3    & dataset=="SHARE" // already dropped
	drop if hacohort>2 & dataset=="SHARE"  
}	
drop if agemin<`agethreshold'	
**********************
set graphics on 
*set graphics off /*disables graphics (but also -graph combine- commands) */


**# Bookmark #1
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
clonevar radyear2 = radyear 
**# Bookmark #1 check if this is correct for all datasets 
replace  radyear2=0 if mi(radyear2) // not dead people will have 

** countatfirstobs and countatonset ** 
gen 	tempvar = d_count if inw_first==wave 		// count at baseline
bys ID: egen countatfirstobs = max(tempvar) 
recode 	countatfirstobs (0 = 0 "0 diseases at baseline") (1 = 1 "1 disease at baseline") (2/3 = 2 "2 or 3 diseases at baseline") (4/10 = 4 "4+ diseases at baseline"), gen(countatfirstobs2)
drop 	tempvar countatfirstobs
rename 	countatfirstobs2 countatfirstobs 
gen 	tempvar = d_count if timesincefirstonset==0 // count at onset
bys ID: egen countatonset = max(tempvar) 
replace countatonset =. if age<firstage 		// if first onset not experienced yet, should not include
recode 	countatonset (1/2 = 1 "1 or 2 diseases at onset") (3/4 = 2 "3 or 4 diseases at onset") (5/15 = 3 "5 or more at onset"), gen(countatonset2)
drop 	tempvar countatonset
rename 	countatonset2 countatonset 

** income groups **
*xtile incomegroups = hhinc, nq(3)

*** define locals to apply to entire file ***
set scheme s1color
loc opt_global 	"scheme(s1color)"
loc sample 		"sfull" // sbalanced
loc samplelabel: variable label `sample'


/*** +++++++++++++++++++ histograms of dependent variable +++++++++++++++++++ ***
loc 	y "d_count"
foreach y in "d_count" "cognitionstd" {
hist `y'	if `sample'==1, `opt_global' 
gr export 	"$outpath/fig/`saveloc'/g_hist_`sample'_`y'.jpg", replace
}
pause
*STOP
*/



/*** +++++++++++++++++++ raw mean and se by age-group (by category t) +++++++++++++++++++ ***
loc y 		"d_count"
loc ylist	"pubpenr d_any d_count d_count_index" // 
loc t 		"male"
loc x 		"agegrp" // age | agegrp |  time
	loc xlabel : variable label `x'	/*uses variable label of x*/
	loc tlabel1 : label (`t') 1		/*uses value 	label of t*/
	loc tlabel0 : label (`t') 0
foreach y of local ylist { /*repeat graph for each selected variable*/
loc ylabel : variable label `y'		/*uses variable label of y*/	
preserve 		/*collapse dataset temporarily using summary statistics used for plotting*/
drop if `x'==. 	/*x==. will not be used in plots, but may confound axis ranges */
collapse (mean) `y'_mean = `y' (sd) `y'_sd = `y' (semean) `y'_sem = `y' (sebinomial) `y'_seb = `y' (max) `y'_max = `y' (count) `y'_count = `y' if `sample'==1, by(`x' `t') 
	** if max is 1 (i.e. y is binomial/proportion), use seb in calculation of CI, otherwise sem **
	if `y'_max ==1 { 
	loc se "seb"
	}
	else {
	loc se "sem"
	}
sum `y'_`se' 
** method 2: manual using rbar: **	**https://www.statalist.org/forums/forum/general-stata-discussion/general/1421837-create-serrbars-with-multiple-categories-in-one-chart
**https://stats.oarc.ucla.edu/stata/code/graphing-means-and-confidence-intervals-by-multiple-group-variables
**note: in a twoway graph, what is plotted first goes to the background
gen upper = `y'_mean + 1.96 * `y'_`se' /*95% confidence interval*/
gen lower = `y'_mean - 1.96 * `y'_`se' 
loc col1 "black" // green 
loc col2 "gs9" // orange
loc col3 "gs13"
twoway 	///
|| 		rcap upper lower  `x' if `t'==1 , lc(`col1') lpattern(dash)  /// 
||     	rcap upper lower  `x' if `t'==0 , lc(`col2') lpattern(dash)	/// 
	|| 		bar `y'_count `x' if `t'==1, yaxis(2) lcolor(`col3') barwidth(0.8) lwidth(vvthin) fcolor(none) ///
	||		bar `y'_count `x' if `t'==0, yaxis(2) lcolor(`col3') barwidth(0.8) lwidth(vvthin) fcolor(none) ///
||     	scatter `y'_mean  `x' if `t'==1 , mc(`col1') msymbol(square) /// 
||     	scatter `y'_mean  `x' if `t'==0 , mc(`col2') msymbol(T) ///
/*
	||  lfit 	`y'_mean `x'	if `x'< 60 & `t'==1 , lc(`col1') /// 
	||  lfit 	`y'_mean `x'	if `x'< 60 & `t'==0 , lc(`col2') /// 
	||  lfit 	`y'_mean `x'	if `x'>=60 & `t'==1 , lc(`col1') /// 
	||  lfit 	`y'_mean `x'	if `x'>=60 & `t'==0 , lc(`col2') /// 
*/ legend(order(3 "`tlabel1'" 4 "`tlabel0'" )) ///
`opt_global' ytitle("`ylabel'") yla(, ang(h))  ///
 xla(`agethreshold'(5) `upperthreshold') xsc(r(`agethreshold' `upperthreshold')) ytitle("N observations", axis(2)) xline(70, lcolor(gray) lwidth(vthin)) ///  /*uncomment for age-group graph*/ ///
/// yscale(range(0 2000) axis(2)) /// /*adjust scale of 2nd axis*/ 
/*leave this line empty*/
gr export 	"$outpath/fig/main/g_crude_byagegrp-male_`y'.jpg", replace 
restore	
}
pause
*STOP 
*/	


**************************************
*** +++ Count by cohort groups +++ *** 
**************************************
preserve

**recode age and timesincefirstobs if too few observations fall in this category and SEs large**
levelsof cohortmin5, local(levels)
foreach  cohort of   local levels {
** group extreme observations (ppl who reach a very high age due to interview timing) **
qui 	sum time, meanonly 
loc 	timerange = r(max)-r(min)+5 /*maximum time an id is observed (5 added for cohort)*/
di 		"`timerange'"
replace age = `cohort'+`timerange' if age >`cohort'+`timerange' & age<. & cohortmin5==`cohort' 
replace timesincefirstobs = `timerange'-5 if timesincefirstobs<. & timesincefirstobs>`timerange'-5
} 

/*** +++ graph over age +++ ***
loc 	y 			"d_count"
loc 	ylabel: 	var label `y'
loc 	cat  	  	"cohortmin5" // male, raeducl, countatfirstobs
loc 	timevar 	"age" 
loc 	xla 		"xla(50(5)90)" /*needed for separate sub-plots*/
loc 	xlarotate	""	

/** xtline (crude data: identical to adjusted predictions (profile plots) from margins, but without CI) **
*preserve // cannot preserve data twice in stata
collapse (mean) `y' = `y' 	(count) `y'_freq = `y' if `sample'==1 `sampleaddition' , by(`cat' `timevar') 
xtset 	 `cat' `timevar'
xtline 	 `y', overlay i(`cat') t(`timevar') ytitle("mean `ylabel'") `opt_global'  title("Collapsed Means `cohortlabel'") note("Notes: The plot shows trends of the collapsed means") name(g0_`cohort', replace) `xla'
*gr export 	"$outpath/fig/main/g_crude_by`timevar'-`cat'_`sample'_d_count_`cohort'.jpg", replace
*restore
*/
loc 	opt_marginsplot "ytitle("linear prediction (`ylabel')")" // noci  
loc 	ctrls  "`ctrl'"
loc 	reg  		reg `y' `timevar'##`cat' `ctrls' if `sample'==1 
qui `reg'
qui margins `timevar'#`cat'
marginsplot, `opt_marginsplot'  name(g`cat'_`cohort', replace) `xla' `xlarotate' title("Crude Data `cohortlabel'") note("Sample: `samplelabel' | Controls: `ctrls' (none)" "Model: `reg'")  // by(cohortmin5) // 
gr export 	"$outpath/fig/main/g_reg_by`timevar'-`cat'_`sample'_d_count.jpg", replace

	*by covariate levels ((a) single plot)* 
loc 	 catlist 	"male raeducl countatfirstobs"	
foreach  cat of local catlist {	
**# Bookmark #2 set age limit for better vizualization
loc reg  		reg `y' `timevar'##`cat'##cohortmin5 `ctrls' if `sample'==1 & age<85
qui `reg'
qui margins `timevar'#`cat'#cohortmin5
marginsplot,  `opt_marginsplot'  name(g`cat'_`cohort', replace) `xla' `xlarotate' by(cohortmin5) byopts(title("Crude Data")) // 
gr export 	"$outpath/fig/main/g_reg_by`timevar'-`cat'_`sample'_d_count_bycohort.jpg", replace		
} 

	*by covariate levels ((b) separate sub-plots per cohort)*
loc 	 cat 		"male"
loc 	 catlist 	"male raeducl countatfirstobs"	
foreach  cat of local catlist {	
foreach  cohort of   local levels {
loc cohortlabel : label (cohortmin5) `cohort'
loc cohortlabel "(`cohortlabel')"  /*add parentheses if subplots*/
loc sampleaddition "& cohortmin5==`cohort'" /*needs to be located here*/
loc 	 opt_marginsplot "title("Crude Data `cohortlabel'") ytitle("linear prediction (`ylabel')")" // noci   
loc 	 ctrls  "`ctrl'"
loc 	 reg  	reg `y' `timevar'##`cat' `ctrls' if `sample'==1 `sampleaddition'
qui `reg'
qui margins `timevar'#`cat'
marginsplot, `opt_marginsplot'  name(g`cat'_`cohort', replace) `xla' `xlarotate' title("Crude Data `cohortlabel'") note("Sample: `samplelabel' | Controls: `ctrls' (none)" "Model: `reg'") // by(cohortmin5) // 
gr export 	"$outpath/fig/main/g_reg_by`timevar'-`cat'_`sample'_d_count_`cohort'.jpg", replace
} 
}
*/

/*** +++ graph over timesincefirstobs +++ ***
loc 	y 			"d_count"
loc 	ylabel: 	var label `y'
	**# Bookmark #6 if i want to show that time of entry does not matter, i can show that accumulation is parallel for different inw_first groups. However, do this in a separate graph; for this, use inw_first as a category
		replace inw_first=. if inw_first>8
loc 	cat  	  	"cohortmin5" // male, raeducl, countatfirstobs
loc 	timevar 	"timesincefirstobs" 
loc 	xla 		""
loc 	xlarotate	""	
loc 	opt_marginsplot "ytitle("linear prediction (`ylabel')")" // noci  
loc 	ctrls  		"`ctrl'"
loc 	reg  		xtreg `y' `timevar'##`cat' `ctrls' if `sample'==1 
qui `reg'
qui margins `timevar'#`cat'
marginsplot, `opt_marginsplot'  name(g`cat'_`cohort', replace) `xla' `xlarotate'  title("Crude Data `cohortlabel'")  note("Sample: `samplelabel' | Controls: `ctrls' (none)" "Underlying Regression: `reg'") // by(cohortmin5) // 
gr export 	"$outpath/fig/main/g_reg_by`timevar'-`cat'_`sample'_d_count.jpg", replace
	*/
restore	

/*** +++++++++++++++++++ graph over time +++++++++++++++++++ ***
*preserve
*	drop if age!= `agethreshold' & age!=55 & age!=60 & age!=65
clonevar 	cohortmin5b = cohortmin5
replace 	cohortmin5b = . if cohortmin5!=cohort5 /*if age is larger than entry cohort age*/	
la de 		cohortmin5bl 50 "ageatfirstobs & age: `agethreshold'-54" 55 "ageatfirstobs & age: 55-59" 60 "ageatfirstobs & age: 60-64" 65 "ageatfirstobs & age: 65-69" 
la val 		cohortmin5b cohortmin5bl
bys cohortmin5b: sum age // check if generation was successful

loc 	y 			"d_count"
loc 	ylabel: 	var label `y'
loc 	timevar 	"time" // age | time | timesincefirstobs_yr | time | timesincefirstobs
loc 	xla 		"" /*keep this empty for raw plot*/
loc 	xlarotate	"xla(, ang(20))" /*only applies to marginsplot*/
loc 	cat 		"cohortmin5b"
loc 	opt_marginsplot "ytitle("linear prediction (`ylabel')")" // noci  
loc 	ctrls  		"`ctrl'"
loc 	reg  		xtreg `y' `timevar'##`cat' `ctrls' if `sample'==1 
qui `reg'
qui margins `timevar'#`cat' 
marginsplot, `opt_marginsplot'  name(g`cat'_`cohort', replace) `xla' `xlarotate'  title("Crude Data `cohortlabel'")  note("Sample: `samplelabel' | Controls: `ctrls' (none)" "Underlying Regression: `reg'")
gr export 	"$outpath/fig/main/g_reg_by`timevar'-`cat'_`sample'_d_count.jpg", replace
restore	
*/
	

	
//	
// ** plot using margins with controls, adj. for mortality (needs to be outside subplots loop) **
// * combine plots ** 
// *gr combine g1_50 g1_55 g1_60 g1_65, ycommon // cols(1)
// *gr export 	"$outpath/fig/main/g_reg_by`timevar'-`cat'comb_`sample'_d_count.jpg", replace
// }	



/*** prevalence of count by cohort groups ***
** plot sth similar with prob of exiting to another state **
preserve 
rename d_count d_count2
recode d_count2 (2/3=3 "2 or 3") (4/20=5 "4 or more"), gen(d_count)
tab d_count 
**define labels**
loc z "d_count"
loc counter   "1"
loc labellist "" /*need to delete local if in loop*/		
levelsof `z', local(levels)
foreach l of local levels{
loc 	valuel : label (`z') `l'				
local labellist  `labellist' `counter' `"d_count=`valuel'"'   
loc counter = `counter'+1	
}
*di "`connectedlist' "
mac list _labellist	 // should not display, but mac list 
loc x 		"cohort5"
loc y 		"d_count"
loc reg 	ologit 	 `y' i.cohort5 if `sample'==1, // vce(cl ID)  /*plot raw data*/
eststo m1: qui `reg'
margins `x'	// no dydx
marginsplot, title("Predicted `y' by `x'") note("Sample: `samplelabel' | Controls: `ctrls' (none)" "Model: `reg'") legend(order(`labellist')) 
gr export 	"$outpath/fig/main/g_ologit_by`x'_`y'.jpg", replace 
	// 	loc ctrls "male i.raeducl"
	// 	loc reg 	ologit 	 `y' i.cohort5 `ctrls' if `sample'==1, vce(cl ID) 
	// 	eststo m1: qui `reg'
	// 	margins `x'	// no dydx
	// 	marginsplot, note("Notes: Sample: `samplelabel'" "Controls: `ctrls' (none)" "Command: `reg'") legend(order(`labellist')) 
	// 	gr export 	"$outpath/fig/main/g_ologit_by`x'_`y'_adj.jpg", replace 
	*gr combine c1 c2 c3
	*esttab m1 m2
restore
*STOP





*margins `x'
*mtable	
*/
++++	

	*** show if there is any duration dependence ***
	*xtset ID time
	*sample 20 // gives not sorted error, need to sample below each other
	bys ID: gen  	d_count_lead = f.d_count 
	bys ID: replace d_count_lead = f2.d_count if d_count_lead ==.
		// it jumps basically here bc 1 gap is allowed
	la var d_count_lead "count in next period (gaps are ignored)"
	sort ID time 
	*bro ID time d_count*
	*bys ID: gen periodswithcount1 = 
	*gen duration = 0
	gen duration = 0 // only generate for cases when count is 1
	*			bys ID (time): replace duration = cond(ind==1,cond(_n>1,duration[_n-1]+1,1),0)
	bys ID (time): replace duration = cond(d_count==1,cond(diff_d_count==0, duration[_n-1]+1,1),0)
	bys ID (time): replace duration = cond(d_count==2,cond(diff_d_count==0, duration[_n-1]+1,1),duration)
	bys ID (time): replace duration = cond(d_count==3,cond(diff_d_count==0, duration[_n-1]+1,1),duration)
	bys ID (time): replace duration = cond(d_count==4,cond(diff_d_count==0, duration[_n-1]+1,1),duration)
	bys ID (time): replace duration = cond(d_count==5,cond(diff_d_count==0, duration[_n-1]+1,1),duration)
	bys ID (time): replace duration = cond(d_count==6,cond(diff_d_count==0, duration[_n-1]+1,1),duration)
	bys ID (time): replace duration = cond(d_count==7,cond(diff_d_count==0, duration[_n-1]+1,1),duration)
	bys ID (time): replace duration = cond(d_count==8,cond(diff_d_count==0, duration[_n-1]+1,1),duration)
	bys ID (time): replace duration = cond(d_count==9,cond(diff_d_count==0, duration[_n-1]+1,1),duration)
	bys ID (time): replace duration = cond(d_count==10,cond(diff_d_count==0, duration[_n-1]+1,1),duration)
	
	gen duration2 = 0 
	forval i=1/10{
	bys ID (time): replace duration = 
	}
	
	// currently people might jump back to earlier count and duration drops again

	*			bys ID (time): replace duration = cond(d_count==3,cond(diff_d_count==0, duration[_n-1]+1,1),0)
	replace duration = . if mi(d_count)
		** use only observations with highest duration within count (last time period) ** 
		bys ID (duration): egen durationmax = max(duration)
		replace duration = . if duration!= durationmax		
		tab d_count_lead, gen(d_count_lead_) // for stacked bar chart

	*bro ID time d_count duration 
	*++
// 		// ?? not working with gaps when a period missing but present in dataset (e.g. in SHARE), but this is not a problem if the missing time period is dropped
loc y "d_count_lead"
loc x "d_count" // d_count
loc ctrls ""
	*** ologit by count before jump ***
	*loc reg 	xtologit `y' i.`x' if `sample'==1, nolog vce(cl ID)  // c.age#c.age  male married i.raeducl*, 
	loc reg 	ologit `y' i.`x'  if `sample'==1 & d_count<9, nolog vce(cl ID) // c.age#c.age  male married i.raeducl*
	`reg'
	margins `x' // , dydx(`x')	
	*margins `x', dydx(`x')	
	marginsplot, note("Notes: Sample: `samplelabel'" "Controls: `ctrls' (none)" "Command: `reg'") name(c3, replace) 
	gr export 	"$outpath/fig/main/g_ologit_by`x'_`y'.jpg", replace 
		loc ctrls "male married i.raeducl*"
		loc reg 	ologit `y' i.`x' `ctrls' if `sample'==1, nolog vce(cl ID) // c.age#c.age  male married i.raeducl*
		`reg'
		margins `x' // , dydx(`x')	
		marginsplot, note("Notes: Sample: `samplelabel'" "Controls: `ctrls' (none)" "Command: `reg'") name(c4, replace) 
		gr export 	"$outpath/fig/main/g_ologit_by`x'_`y'_adj.jpg", replace 			
		++
		*/

*** do the same now with duration ***		
loc y "d_count_lead"
loc x "duration" // d_count
loc ctrls ""
forval startcount = 1/4 { // no 0 bc there is no duration with 0 conditions

/**ologit**
*loc reg 	xtologit `y' i.`x' if `sample'==1, nolog vce(cl ID)  // c.age#c.age  male married i.raeducl*, 
loc reg 	ologit `y' i.`x'  if `sample'==1 & d_count==`startcount', nolog vce(cl ID) // c.age#c.age  male married i.raeducl*
`reg'
margins i.`x' // , dydx(`x')	
*margins , dydx(`x')	
marginsplot, note("Notes: Sample: `samplelabel'" "Controls: `ctrls' (none)" "Command: `reg'") name(mh1, replace) 
gr export 	"$outpath/fig/main/g_ologit_by`x'_`y'_`startcount'.jpg", replace 
	loc ctrls "male married i.raeducl*"
	loc reg 	ologit `y' i.`x' `ctrls' if `sample'==1  & d_count==`startcount', nolog vce(cl ID) // c.age#c.age  male married i.raeducl*
	`reg'
	margins `x' // , dydx(`x')	
	marginsplot, note("Notes: Sample: `samplelabel'" "Controls: `ctrls' (none)" "Command: `reg'") name(mh2, replace) 
	gr export 	"$outpath/fig/main/g_ologit_by`x'_`y'_`startcount'_adj.jpg", replace 			
*/

**bar graph**
graph bar (mean) d_count_lead_* if `sample'==1 & d_count==`startcount', over(`x') name(g1, replace) stack title("Disease Count before count transition: `startcount'") // xla(,label("Number of Periods with `startcount' conditions")) // over(d_count)	
gr export 	"$outpath/fig/main/g_barby`x'_`sample'_`y'_`startcount'.jpg", replace		
}
*/				



+++++++++++++
	** plot the same using crude data now **
	*scatter d_count_lead d_count if `sample'==1
	
	*preserve
	loc y "d_count_lead"
	loc z ""
	loc x "duration"
	
		egen freq = count(d_count_lead), by(d_count_lead)
		egen total = total(freq), by(d_count_lead)
		gen prob = freq / total		
	*graph bar (mean) d_count_lead if `sample'==1 & d_count==1, over(duration) name(g1, replace) stack // over(d_count)

	++
	collapse (mean) `y'=`y' if `sample'==1 & d_count==1, by(`z' `x')  
	tab `y' `x' 
	graph bar d_count_lead, over(duration)
	*twoway `connectedlist', legend(order (`labellist'))  // ytitle(`ylabel')
		ologit d_count_lead i.d_count##i.duration if d_count==1
		margins i.d_count#i.duration
		marginsplot 
	restore	
	
	
++++
***Single-record-per-subject survival data (time until first disease)***	
// stset timevar [if] [weight] , id(idvar) failure(failvar[==numlist]) [multiple_options]
// streset [if] [weight] [, multiple_options]
// streset, {past|future|past future}
// st [, nocmd notable]
// stset, clear
stset wave, failure(dead)
stdes	
tab timesincefirstobs wave,m	
	
***survival curves***
gl 		sample "sfull & agemin==50"
gl 		sample "sbalanced & agemin==50"
gl 		sample "sbalanced"
loc 	ctrl 	""

sts graph if $sample, survival  // default
gr export 	"$outpath/fig/supplement/g_survival_km_`sample'_.jpg", replace
sts graph if $sample, hazard
sts graph if $sample, cumhaz
sts list, survival
sts graph if $sample, survival by(cohortmin) legend(pos(6) rows(1))
gr export 	"$outpath/fig/supplement/g_survival_km_bycohortmin.jpg", replace
sts graph if $sample, survival by(raeducl) legend(pos(6) rows(3))
gr export 	"$outpath/fig/supplement/g_survival_km_byraeducl.jpg", replace
*sts graph if $sample, survival by(higovr)
sts test raeducl
++
streg `ctrl' , nohr dist(exponential) // there is no outcome variable to define // interpret coefficients in opposite way
streg `ctrl' , dist(exponential) // gives hazard rated (no nohr)
// interpretation is in diff-to-1 in % change in (hazard) rates

streg `ctrl', dist(weibull) // gompertz

stcox `ctrl', nohr // stcox, semiparametric
stcox `ctrl'

*/



*** ARCHIVE *** 
	*(below graph is essentially equivalent in essence the same as all the others)
	*** +++++++++++++++++++ scatterplot by age by categories (c.f. Fig 1 in De Nardi) +++++++++++++++++++ 	
	/*** (this is the same as xtline below)
	loc y "d_count"
	loc x "agegrp"
	** (crude) scatter count over AGE by BASELINE COUNT or ONSET COUNT**
	loc z 	  "male" // countatonset | countatfirstobs
	loc zlist "countatfirstobs countatonset"
	foreach z of local zlist{
		**define labels**
		loc counter   "1"
		loc connectedlist "" /*clear content of connectedlist*/
		loc labellist "" /*need to delete local if in loop*/		
		levelsof `z', local(levels)
		foreach l of local levels{
		loc 	valuel : label (`z') `l'				
		di "`y'"
		local connectedlist "`connectedlist'  (connected `y' `x' if `z'==`l')"
		local labellist  `labellist' `counter' `"`valuel'"'   
		loc counter = `counter'+1	
		}
		di "`connectedlist' "
		mac list _labellist	 // should not display, but mac list 
	preserve
	collapse (mean) `y'=`y' if `sample'==1, by(`z' `x')  
	twoway `connectedlist', legend(order (`labellist'))  // ytitle(`ylabel')
	gr export 	"$outpath/fig/main/g_crude_byagegrp-`z'_`sample'_`y'.jpg", replace			
	restore
	} 
	pause
	*STOP
	*/


		