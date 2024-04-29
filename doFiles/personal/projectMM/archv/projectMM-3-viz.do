pause on
*pause off
log close _all 	/*closes all open log files*/
clear all		/*clears all data in memory*/



***choose data***
loc data "SHARE"
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
// clonevar radyear2 = radyear 
// replace  radyear2=0 if mi(radyear2) // not dead people will have 
egen 	radcohort 	= cut(radage),    at (50,60,70,80,120)
replace radcohort = 0 if everdead==0
la de 	radcohortl 	0 "never dead" 50  "died at 50-59" 60 "died at 60-69" 70 "died at 70-79" 80 "died at 80+"      
la val 	radcohort radcohortl
*tab radage radcohort






** income groups **
*xtile incomegroups = hhinc, nq(3)

*** define locals to apply to entire file ***
set scheme s1color
loc opt_global 	"scheme(s1color)"
loc sample 		"sfull" // sbalanced
loc samplelabel: variable label `sample'


	/** ++ plot prediction of prevalence of each disease over age (smoothes out mortality) ++ **
	loc 	glist 	""
	loc   	y 		"d_any"
	loc 	ylist	"d_any $alldiseases" 
	foreach y of local ylist{
	loc 	ylabel: var label `y'			
		// ignore a variable in ylist if has only missing values)
		qui count if missing(`y')
		if r(N) == _N {
		scatter `y' age, yline(0) title("missing:" "`ylabel'") name(g`y', replace) xla(50(5)100) ytitle("") xtitle("")
		loc glist "`glist' g`y'"
		continue  // Skip logistic regression in next loop for this variable if all values are missing
		}
	qui logit 	`y' male#c.age
		predict xb`y', pr
		loc 	xblist "`xblist' xb`y'"
	qui margins male, at(age=(`agethreshold'(2)100)) 
	marginsplot, title("Logistic Prediction" "(`ylabel')") name(g`y') xla(50(5)100) ytitle("")
	loc glist "`glist' g`y'"
		*graph twoway line xb`y' age, title("Logistic Prediction" "(`ylabel')") lcolor(blue) lwidth(medthick)
	}
	gr combine `glist', ycommon
	gr export 	"$outpath/fig/main/g_byage-male-alldiseases.pdf", replace 
	STOP
	di "`xblist'"
*		twoway connected xbd_any age
	*/


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

**recode age and timesincefirstobs if too few observations fall in this category and SEs large**
levelsof cohortmin5, local(levels)
foreach  cohort of   local levels {
** group extreme observations (ppl who reach a very high last observed age due to late interview timing) **
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
loc 	timevar 	"age" /*use age dummies*/
loc 	xla 		"xla(50(5)90)" /*needed for separate sub-plots*/
loc 	xlarotate	""	
/** xtline (crude data: identical to predictions (profile plots) from margins, but without CI) **
*preserve // cannot preserve data twice in stata
collapse (mean) `y' = `y' 	(count) `y'_freq = `y' if `sample'==1 `sampleaddition' , by(`cat' `timevar') 
xtset 	 `cat' `timevar'
xtline 	 `y', overlay i(`cat') t(`timevar') ytitle("mean `ylabel'") `opt_global'  title("Collapsed Means `cohortlabel'") note("Notes: The plot shows trends of the collapsed means")  `xla' name(g0_`cohort', replace)
*gr export 	"$outpath/fig/main/g_crude_by`timevar'-`cat'_`sample'_d_count_`cohort'.jpg", replace
*restore
*/
loc 	opt_marginsplot "ytitle("Predicted values (`ylabel')")" // noci  
loc 	ctrls  "`ctrl'"

*overall plot by cohort groups* 
loc 	reg  		reg `y' `timevar'##`cat' `ctrls' if `sample'==1 
qui `reg'
timer on 1
qui margins `timevar'#`cat' 
//qui margins `cat', at(age=(`agethreshold'(1)90)) // this is a lot slower but does the same in this case
marginsplot,  `opt_marginsplot'   `xla' `xlarotate' title("Crude Data `cohortlabel'") note("Sample: `samplelabel' | Controls: `ctrls' (none)" "Model: `reg'") name(g`cat'_`cohort', replace) // by(cohortmin5) 
*gr export 	"$outpath/fig/main/g_reg_by`timevar'-`cat'_`sample'_`y'.jpg", replace		
timer off 1 
timer list 1

	/*by covariate levels ((a) single combined plot of each cohort group)* 
	loc 	 catlist 	"male raeducl countatfirstobs"	
	foreach  cat of local catlist {	
	loc catlabel: var label `cat'
	loc reg  		reg `y' `timevar'##`cat'##cohortmin5 `ctrls' if `sample'==1 & age<90 // set age limit
	qui `reg'
	qui margins `timevar'#`cat'#cohortmin5
	marginsplot,  `opt_marginsplot'   `xla' `xlarotate' by(cohortmin5) byopts(title("Crude Data, by (`catlabel')")) name(g`cat'_`cohort', replace) // ycommon?
	*gr export 	"$outpath/fig/main/g_reg_by`timevar'-`cat'_`sample'_d_count_bycohort.jpg", replace		
	}
	*/

*by covariate levels ((b) separate sub-plots per cohort)*
loc 	 cat 		"male"
loc 	 catlist 	"male raeducl countatfirstobs"	
foreach  cat of local catlist {	
foreach  cohort of   local levels {
loc cohortlabel : label (cohortmin5) `cohort'
loc cohortlabel "(`cohortlabel')"  /*add parentheses if subplots*/
*loc sampleaddition "& cohortmin5==`cohort'" /*needs to be located here*/
loc 	 opt_marginsplot "title("Crude Data `cohortlabel'") ytitle("Prediction (`ylabel')")" // noci   
loc 	 ctrls  "`ctrl'"
loc 	 reg  	reg `y' `timevar'##`cat' `ctrls' if `sample'==1 & cohortmin5==`cohort'
qui `reg'
qui margins `timevar'#`cat'
marginsplot, `opt_marginsplot'  `xla' `xlarotate' title("Crude Data `cohortlabel'") note("Sample: `samplelabel' | Controls: `ctrls' (none)" "Model: `reg'") name(g`cat'_`cohort', replace)  // by(cohortmin5)
*gr export 	"$outpath/fig/main/g_reg_by`timevar'-`cat'_`sample'_d_count_`cohort'.jpg", replace
} 
}

*by mortality*
**# Bookmark #1 can do separately for all countatfirstobs levels (otherwise, include this to plot (b) above)
loc 	 cat 	"radcohort"
loc 	 cohort "50"
foreach  cohort of local levels {
loc cohortlabel :  label (cohortmin5) `cohort'
loc cohortlabel "(`cohortlabel')"  /*add parentheses if subplots*/
loc 	 ctrls  "`ctrl'"			
loc 	 reg  	reg `y' `timevar'##`cat' `ctrls' if `sample'==1 & cohortmin5==`cohort' & countatfirstobs==0
qui `reg'
margins `timevar'#`cat' 					// , at(countatfirstobs=0)
marginsplot		,   `opt_marginsplot'  name(g`cat'_`cohort', replace) `xla' `xlarotate' title("Crude Data `cohortlabel'") note("Sample: `samplelabel' | Controls: `ctrls' (none)" "Model: `reg'")  // by(cohortmin5) 
*gr export 	"$outpath/fig/main/g_reg_by`timevar'-`cat'_`sample'_d_count_`cohort'.jpg", replace
}
pause
*/

/** +++ graph over timesincefirstobs +++ ***
loc 	y 			"d_count"
loc 	ylabel: 	var label `y'
loc 	cat  	  	"cohortmin5" 
loc 	timevar 	"timesincefirstobs" 
loc 	xla 		""
loc 	xlarotate	""	
loc 	opt_marginsplot "ytitle("linear prediction (`ylabel')")" // noci  
loc 	ctrls  		"`ctrl'"
loc 	reg  		xtreg `y' `timevar'##`cat' `ctrls' if `sample'==1 
qui `reg'
qui margins `timevar'#`cat'
marginsplot, `opt_marginsplot'   `xla' `xlarotate'  title("Crude Data `cohortlabel'")  note("Sample: `samplelabel' | Controls: `ctrls' (none)" "Underlying Regression: `reg'") name(g`cat'_`cohort', replace)
*gr export 	"$outpath/fig/main/g_reg_by`timevar'-`cat'_`sample'_d_count.jpg", replace
	**# Bookmark #6 if i want to show that time of entry does not matter, i can show that accumulation is parallel for different inw_first groups. However, do this in a separate graph; for this, use inw_first as a category. For this: use *replace inw_first=. if inw_first>8 (only in HRS)
pause
*/


	** +++ (a) graph over age by first onset time +++ *** (and maybe also do by timesincefirstobs)
**# Bookmark #1 plot same plot also by categories of firstage_mm
* do also with d_count_lead 
	
	egen 	firstagegrp5 = cut(firstage),    at (`agethreshold',55,60,65,70,75, 120) // ,80, 	
	recode  firstagegrp5 (`agethreshold' = 50)
	replace firstagegrp5 = . if d_anyatfirstobs==1 
	loc 	labelname "firstage:"
	la de 	firstagegrp5l 	50  "`labelname' `agethreshold'-54" 55 "`labelname' 55-59" 60 "`labelname' 60-64" 65 "`labelname' 65-69" 70 "`labelname' 70-74" 75 "`labelname' 75+"  
	la val 	firstagegrp5 firstagegrp5l
	*tab firstagegrp5,m
		preserve
	*recode d_count_lead (99=10)

	loc 	y 			"d_count"
	loc 	ylabel: 	var label `y'
	loc 	cat  	  	"firstagegrp5" 
	loc 	timevar 	"timesincefirstobs" 
	loc 	xla 		""
	loc 	xlarotate	""	
	loc 	opt_marginsplot "ytitle("linear prediction (`ylabel')")" // noci  
	loc 	ctrls  		"`ctrl'"
	loc 	reg  		xtreg `y' `timevar'##`cat' `ctrls' if `sample'==1 & countatfirstobs==0 & d_anyatfirstobs==0  // & cohortmin==50
	qui `reg'
	margins `timevar'#`cat'
	marginsplot, `opt_marginsplot'  `xla' `xlarotate' title("Crude Data, by age of first onset, all cohorts")  note("Sample: `samplelabel' | Controls: `ctrls' (none)" "Underlying Regression: `reg'")  name(g`cat'_`cohort', replace) // by(cohortmin5) // 
	*gr export 	"$outpath/fig/main/g_reg_by`timevar'-`cat'_`sample'_d_count.jpg", replace
	pause
		restore 




/*** +++++++++++++++++++ graph over time +++++++++++++++++++ ***
preserve
qui log using 	"$outpath/logs/log-cohortmin5b.txt", text replace name(log) 
/*this log is to show that the generation of cohortmin5b is correct*/
clonevar 	cohortmin5b = cohortmin5
replace 	cohortmin5b = .m if cohortmin5!=cohort5 /*if age is larger than entry cohort age*/	
la de 		cohortmin5bl 50 "ageatfirstobs & age: `agethreshold'-54" 55 "ageatfirstobs & age: 55-59" 60 "ageatfirstobs & age: 60-64" 65 "ageatfirstobs & age: 65-69" .m "current age larger than cohortmin5"
la val 		cohortmin5b cohortmin5bl
bys cohortmin5b: sum age /*cohortmin5 only contains age<=cohortmin5*/
qui log close log 
*tab age cohortmin5 if cohortmin5b>=. // shows that all missing observations are larger than cohort group

loc 	y 			"d_count"
loc 	ylabel: 	var label `y'
loc 	timevar 	"time" // age | time | timesincefirstobs_yr | time | timesincefirstobs
loc 	xla 		"" /*keep this empty for raw plot*/
loc 	xlarotate	"xla(, ang(20))" /*only applies to marginsplot*/
loc 	cat 		"cohortmin5b"
loc 	opt_marginsplot "ytitle("linear prediction (`ylabel')")" // noci  
loc 	ctrls  		"`ctrl'"
loc 	reg  		reg `y' `timevar'##`cat' `ctrls' if `sample'==1 
qui `reg'
qui margins `timevar'#`cat' 
marginsplot, `opt_marginsplot'  name(g`cat'_`cohort', replace) `xla' `xlarotate'  title("Crude Data `cohortlabel'")  note("Sample: `samplelabel' | Controls: `ctrls' (none)" "Underlying Regression: `reg'")
gr export 	"$outpath/fig/main/g_reg_by`timevar'-`cat'_`sample'_d_count.jpg", replace
restore	
pause 
*/
	



/*** +++ prevalence of count by cohort groups / age +++ ***
*preserve 
*rename d_count d_count2
recode d_count (2/3=3 "2 or 3") (4/20=5 "4 or more"), gen(d_count2)
tab d_count2 
**define labels**
loc counter   "1"
loc labellist "" /*need to delete local if in loop*/		
loc z 		 "d_count2"
levelsof `z', local(levels)
foreach l of local levels{
loc 	valuel : label (`z') `l'				
local labellist  `labellist' `counter' `"d_count=`valuel'"'   
loc counter = `counter'+1	
}
*di "`connectedlist' "
*mac list _labellist	 // should not display, but mac list 
loc x 		"age" // cohort5 | age
loc y 		"d_count2"

/**predictions using ologit**
loc reg 	ologit 	 `y' i.`x' if `sample'==1 & age<=90, // vce(cl ID)  /*plot raw data*/
eststo m1: qui `reg'
qui margins `x'	// no dydx
marginsplot, title("Predicted `y' by `x'") note("Sample: `samplelabel' | Controls: `ctrls' (none)" "Model: `reg'") legend(order(`labellist')) recast(line) recastci(rarea)
gr export 	"$outpath/fig/main/g_ologit_by`x'_`y'.jpg", replace
*/
	/** using mgen (does same as "margins" above, but manually and flexible) (needs -c.- on age) **
	loc reg 	ologit 	 `y' c.`x' if `sample'==1 & age<=90, // vce(cl ID)  /*plot raw data*/
	eststo m1: qui `reg'
	di "`reg'"
	mgen, at(age = (51(5)90))  stub(all) replace // -at()- requires continuous var c.age
	list allpr0 allpr1 allpr3 allpr5 allage in 1/15 
	line allpr0 allpr1 allpr3 allpr5 allage, scheme(sj) name(name, replace)
	*/
	/**crude plotting**
	contract cohort5 d_count2 , percent(p)
	twoway connected p cohort5, by(d_count) ycommon
	++
	*/
*/
	

/*** +++ "prevalence of" prob of exiting to another state +++ ***
*bys d_count: tab d_count_lead if sfull==1 & age<=90
loc y 		"d_count_lead"
loc x 		"age"
loc 	i=1
forval  i=1/4{
preserve 
	**labellist needs to be located here after preserving data (some levels are not in some plots)
	keep if d_count==`i'
	loc counter   "1"
	loc labellist "" /*need to delete local if in loop*/		
	loc z 		 "d_count_lead"
	levelsof `z', local(levels)
	foreach l of local levels{
	loc 	valuel : label (`z') `l'				
	local labellist  `labellist' `counter' `"lead=`valuel'"'   
	loc counter = `counter'+1	
	}	
loc reg 	ologit 	 `y' i.`x' if `sample'==1 & age<=90 & d_count==`i', 
eststo m1: qui `reg'
qui margins `x'	// no dydx
marginsplot, title("Predicted `y' by `x', count before transition: `i'") note("Sample: `samplelabel' | Controls: `ctrls' (none)" "Model: `reg'" "")  legend(order(`labellist') cols(3)) recast(line) recastci(rarea) name(g`i') // ylabel(#2) //  yscale(range(0 1))  
gr export 	"$outpath/fig/main/g_ologit_by`x'_`y'_`i'.jpg", replace 
restore
}	
pause
*STOP
*/



*** +++ show if there is any duration dependence +++ ***
	** generate duration with c conditions **
	gen duration = 0  // only generate for cases when count is 1 and not missing 
	/**count from first onset onwards for durations: d_count2 ignores "recovery" **	
	gen 	d_count2 = d_count
	replace d_count2 = d_count - diff_d_count if diff_d_count < 0
	*tab d_count d_count2
	*sort ID time
	bys ID: gen 	diff_d_count2 = d_count2 - L.d_count2
	bro ID wave d_count* diff_d_count* duration if ID==10013010
	*/
sum d_count, meanonly
loc d_count_max = r(max)
forval i=1/`d_count_max'{
bys ID (time): replace duration = cond(d_count==`i',   cond(diff_d_count==0, duration[_n-1]+1,1),duration)
**# Bookmark #2 could correct duration for when people jump down again to lower count - the duration in this case is "wrong"
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
gr export 	"$outpath/fig/main/g_barby`x'_`sample'_`cohort'.jpg", replace	
restore 
*/
// 	loc x "duration"
// 	loc i = 1
// 	forval i=1/4{
// 	loc reg 	ologit 	 d_count_lead i.`x' if `sample'==1 & age<=90 & `cohortvar'==`cohort' & d_count==`i' & countatfirstobs==0, 
// 	eststo m1: qui `reg'
// 	qui margins `x'	// no dydx
// 	marginsplot, title("Predicted `y' by `x', count before transition: `i'") note("Sample: `samplelabel' | Controls: `ctrls' (none)" "Model: `reg'" "")  legend( cols(3)) noci //  recast(line) recastci(rarea) // ylabel(#2) //  yscale(range(0 1))  legend(order(`labellist'):: should not use labellist here bc the legend mislabels then if e.g. outcome 2 is missing
// 	*gr export 	"$outpath/fig/main/g_ologit_by`x'_`y'_`i'.jpg", replace 
// 	}	
}
	** archive code: use if plot separate plots **
	*qui sum d_count_lead if `sample'==1 & d_count_lead!=99 & d_count == `startcount', meanonly 
	*forval startcount = 1/4 { // no 0 bc there is no duration with 0 conditions
*graph bar (mean) d_count_lead_* if `sample'==1 & d_count==`startcount' & cohort==`cohort', over(`x') name(g_trans`startcount', replace) stack title("# diseases before transition: `startcount' | `cohortlabel'")  legend(order(`labellist'))  // do separate for each age cohort // xla(,label("Number of Periods with `startcount' conditions")) // over(d_count)	
	*gr combine g_trans1 g_trans2 g_trans3 g_trans4,
	*}
pause
*/				


// note: currently people might jump back to earlier count and duration drops again; can try to enforce strictly increasing data
// 		// ?? not working with gaps when a period missing but present in dataset (e.g. in SHARE), but this is not a problem if the missing time period is dropped

/**	ologit**
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

*mtable	






+++++++++++++
	*preserve
	loc y "d_count_lead"
	loc z ""
	loc x "duration"
	
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


		