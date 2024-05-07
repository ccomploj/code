pause on
*pause off
log close _all 	/*closes all open log files*/
clear all		/*clears all data in memory*/



***choose data***
loc data 		"ELSA"
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
cd  "$outpath/fig"


****************************************************************************************************
*Part 7a*: Vizualization (Do File Setup, variable and local definitions) 
****************************************************************************************************	
*** define additional variables ***
*** age groups ***
gen 	agegrp 	= age
replace agegrp 	= `upperthreshold' if agegrp>`upperthreshold' & agegrp<. /*group few very old*/
la var  agegrp 	"age"
*tabstat age, by(agegrp) stats(min max)

*** death year ***
// clonevar radyear2 = radyear 
// replace  radyear2=0 if mi(radyear2) // not dead people will have 
egen 	radcohort 	= cut(radage),    at (50,60,70,80,120)
replace radcohort = 0 if everdead==0
la de 	radcohortl 	0 "never dead" 50  "died at 50-59" 60 "died at 60-69" 70 "died at 70-79" 80 "died at 80+"      
la val 	radcohort radcohortl
*tab radage radcohort

*** generate duration with c conditions ***
gen duration = 0 if d_count>0 & !mi(d_count) // only when count is 1 and not missing 
sum d_count, meanonly
loc d_count_max = r(max) // maximum disease count across i
forval i=1/`d_count_max'{
bys ID (time): replace duration = cond(d_count==`i',   cond(diff_d_count==0, duration[_n-1]+1,1),duration)
	}
replace duration = . if mi(d_count) // if count missing, duration should be missing
la var duration 		"consecutive time periods spent with c conditions"
**show duration correctly generated**
sum duration*
tab duration time
sum time, meanonly 
loc timediff = (r(max)-r(min))/2
di "`timediff'" // should equal to the maximum of duration above
	*	bro ID wave d_count* diff_d_count* duration if ID==10013010
	*	bro ID wave d_count* diff_d_count* duration if ID==10063010
*li ID time d_count duration in 1/50 if !mi(d_count)
	**set durations to missing if left-censored (do not know the 'true' duration)**
	bys ID: egen d_count_min = min(d_count)
		*replace duration = . if d_count_min==d_count // do not know if entered survey already with condition
	gen		 duration_uncens = duration if d_count_min!=d_count
	la var 	 duration_uncens	"consecutive time periods spent with c conditions (uncensored)"
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
	
** income groups **
**# Bookmark #1
*xtile incomegroups = hhinc, nq(3)


*** define locals to apply to entire file ***
set scheme s1color
loc opt_global 		"scheme(s1color)"
*loc jpghighquality  "quality(100)" // for jpg files higher quality
loc sample 			"sfull" // sbalanced
loc samplelabel: variable label `sample'
gl  diseasecodelist "hibp diab heart lung psych osteo cancr strok arthr demen"
	gl  diseaselist 	"d_hibp d_diab d_heart d_lung d_psych d_osteo d_cancr d_strok d_arthr d_demen"


	

****************************************************************************************************
*Part 7b*: Vizualization (Plots)
****************************************************************************************************



*** +++++++++++++++++++ histograms +++++++++++++++++++ ***
/** histograms of main vars ** 
preserve 
bys ID: egen d_countmax= max(d_count)
la var 		 d_countmax "# diseases (max within ID before death)"
loc 	y "duration"
foreach y in "d_count" "d_countmax" "cognitionstd" "onsetage" "onsetage_uncens" "duration" "duration_uncens" {
hist `y'	if `sample'==1, `opt_global' name(h`y')
gr export 	"$outpath/fig/`saveloc'/g_hist_`sample'_`y'.jpg", replace quality(100) 
}
restore
pause
*/


** histogram of first onset, for each disease separately **
preserve // bc generates new vars
loc 	grlist ""
local 	templist "$diseasecodelist" // always check chosen diseases are up to date
foreach y of local templist {
la var radiag`y' "self-rep. onset: `y'"
la var onsetd_`y' "observed onset: `y'"
hist radiag`y'	if `sample'==1, `opt_global' name(h`y')
loc  histlist 	"`histlist' h`y'"		
	hist onsetd_`y'			if `sample'==1, `opt_global' name(h2`y')
	loc  histlist_observed 	"`histlist_observed' h2`y'"		
kdensity  radiag`y', gen(point`y' density`y') bw(2) nograph 
loc kdenlist 	"`kdenlist' (line density`y' point`y')"
	kdensity  onsetd_`y', gen(point`y'_obs density`y'_obs) bw(2) nograph 
	loc kdenlist_observed 	"`kdenlist_observed' (line density`y'_obs point`y'_obs)"
}
di	 		"`histlist'"
gr combine `histlist', 				 title("histogram: 	first onset by disease (self-reported)") name(h1)
gr export 	"$outpath/fig/`saveloc'/g_hist_`sample'_radiagonsetalld.jpg", replace quality(100)
	di	 		"`histlist_observed'"
	gr combine `histlist_observed',  title("histogram: 	first onset by disease (observed)") name(h2)
	gr export 	"$outpath/fig/`saveloc'/g_hist_`sample'_onsetalld.jpg", replace quality(100)
di 			"`kdenlist'"
twoway 		`kdenlist', xla(0(10)80) title("density: 	first onset by disease (self-reported)") name(k1)
gr export 	"$outpath/fig/`saveloc'/g_kden_`sample'_radiagonsetalld.jpg", replace quality(100)
	di 			"`kdenlist_observed'"
	twoway 		`kdenlist_observed', title("density: 	first onset by disease (observed)") name(k2)
	gr export 	"$outpath/fig/`saveloc'/g_kden_`sample'_onsetalld.jpg", replace quality(100)
**# Bookmark #2 could add here a similar density plot now, but with (different) combinations of diseases for each age
restore 
pause 
*/

**bar chart with ever had condition 
loc templist ""
di "$diseasecodelist"
foreach d of global diseasecodelist {
loc barlist "`barlist' d_`d'ever" 
}
di "`barlist'"
graph bar `barlist', title("% of IDs ever reporting each disease (across time)")
gr export 	"$outpath/fig/`saveloc'/g_bar_alld.jpg", replace quality(100)
*could add here a stacked plot that shows: % of ppl with value 1, 0, and third category missing*
pause 
*/

	/** histogram of duration in each health state **
		gen 	myvar = d_count if inrange(age,55,56)
		bys ID: egen countat55to56 = max(myvar)
		drop myvar
	hist duration_uncens if inrange(age,57,65), by(countat55to56)
	+
	*/
		
/** ++ logistic prediction over age for each disease type ((?)smoothes out mortality) ++ **
loc 	glist 	""
loc 	connectedlist ""
loc   	y 		"d_any"
loc 	ylist	"d_any $diseaselist" 
foreach y of local ylist{
loc 	ylabel: var label `y'			
	**ignore a variable in ylist if has only missing values)**
	qui count if missing(`y')
	if r(N) == _N {
	scatter `y' age, yline(0) title("missing: `y'") name(g`y', replace) xla(50(5)100) ytitle("") xtitle("")
	loc glist "`glist' g`y'" // still add to glist
	continue  // Skip next loop (logistic-reg) for this variable if all values are missing
	}
qui logit 	`y' male#c.age
	**generate predictions for each level of x's (same as -margins- above, but can combine predictions)**
	predict xb`y', pr
	loc 	xblist 			"`xblist' xb`y'"
	loc 	connectedlist 	"`connectedlist' (connected xb`y' age)"
qui margins male, at(age=(`agethreshold'(5)100)) 
marginsplot, title("Logistic Prediction" "(`ylabel')") name(g`y') xla(50(5)100) ytitle("") 
loc glist "`glist' g`y'"
}
gr combine `glist', ycommon name(logitby)
gr export 	"$outpath/fig/main/g_logit_byage-male-`sample'-alld.jpg", replace quality(100)
	*gr export "C:\Users\User\Documents\GitHub\2-projectMM-SHARE\files/figELSA/g_byage-male-alldiseases.pdf", `jpghighquality' 
	** plot xbvalues above **
	preserve // plot mean predictions from above
	collapse (mean) `xblist', by(age)
	twoway `connectedlist', title("Logistic predictions of age") name(xb)
	gr export 	"$outpath/fig/main/g_logit_byage-`sample'-alld-xb.jpg", replace quality(100)
	restore 
pause 
*/



		

	
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
gr export 	"$outpath/fig/main/g_crude_byagegrp-male_`y'.jpg", replace `jpghighquality'
restore	
}
pause
*STOP 
*/	




*******************************************
*** +++ Disease count over age/time +++ *** 
*******************************************

**recode age and timesincefirstobs if too few observations fall in this category and SEs large**
levelsof cohortmin5, local(levels)
foreach  cohort of   local levels {
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
*gr export 	"$outpath/fig/main/g_crude_by`timevar'-`cat'_`sample'_d_count_`cohort'.jpg", replace `jpghighquality'
*restore
*/
loc 	opt_marginsplot "ytitle("Predicted (`ylabel')")" // noci  
loc 	ctrls  "`ctrl'"

*overall plot by cohort groups* 
loc 	reg  		reg `y' `timevar'##`cat' `ctrls' if `sample'==1 
qui `reg'
timer on 1
qui margins `timevar'#`cat' 
//qui margins `cat', at(age=(`agethreshold'(1)90)) // this is a lot slower but does the same in this case
marginsplot,  `opt_marginsplot'   `xla' `xlarotate' title("Crude Data `cohortlabel'") note("Sample: `samplelabel' | Controls: `ctrls' (none)" "Model: `reg'") name(g`cat'_`cohort', replace) // by(cohortmin5) 
*gr export 	"$outpath/fig/main/g_reg_by`timevar'-`cat'_`sample'_`y'.jpg", replace	`jpghighquality'	
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
	*gr export 	"$outpath/fig/main/g_reg_by`timevar'-`cat'_`sample'_d_count_bycohort.jpg", replace	`jpghighquality'	
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
loc 	 opt_marginsplot "title("Crude Data `cohortlabel'") ytitle("Predicted (`ylabel')")" // noci   
loc 	 ctrls  "`ctrl'"
loc 	 reg  	reg `y' `timevar'##`cat' `ctrls' if `sample'==1 & cohortmin5==`cohort'
qui `reg'
qui margins `timevar'#`cat'
marginsplot, `opt_marginsplot'  `xla' `xlarotate' title("Crude Data `cohortlabel'") note("Sample: `samplelabel' | Controls: `ctrls' (none)" "Model: `reg'") name(g`cat'_`cohort', replace)  // by(cohortmin5)
*gr export 	"$outpath/fig/main/g_reg_by`timevar'-`cat'_`sample'_d_count_`cohort'.jpg", replace `jpghighquality'
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
*gr export 	"$outpath/fig/main/g_reg_by`timevar'-`cat'_`sample'_d_count_`cohort'.jpg", replace `jpghighquality'
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
loc 	opt_marginsplot "ytitle("Predicted (`ylabel')")" // noci  
loc 	ctrls  		"`ctrl'"
loc 	reg  		xtreg `y' `timevar'##`cat' `ctrls' if `sample'==1 
qui `reg'
qui margins `timevar'#`cat'
marginsplot, `opt_marginsplot'   `xla' `xlarotate'  title("Crude Data `cohortlabel'")  note("Sample: `samplelabel' | Controls: `ctrls' (none)" "Model: `reg'") name(g`cat'_`cohort', replace)
*gr export 	"$outpath/fig/main/g_reg_by`timevar'-`cat'_`sample'_d_count.jpg", replace
	**# Bookmark #6 if i want to show that time of entry does not matter, i can show that accumulation is parallel for different inw_first groups. However, do this in a separate graph; for this, use inw_first as a category. For this: use *replace inw_first=. if inw_first>8 (only in HRS)
pause
*/


	** +++ (a) graph over age by first onset time +++ *** (and maybe also do by timesincefirstobs), timesincefirstobs does not make sense until i group categories by time, not by agegrps anymore
**# Bookmark #1 plot same plot also by categories of firstage_mm
* do also with d_count_lead 
	*preserve // bc replace firstage
	egen 	firstagegrp5 = cut(firstage),    at (`agethreshold',55,60,65,70,75, 120) // ,80, 	
	recode  firstagegrp5 (`agethreshold' = 50)
	replace firstagegrp5 = . if d_anyatfirstobs==1 
	loc 	labelname "firstage:"
	la de 	firstagegrp5l 	50  "`labelname' `agethreshold'-54" 55 "`labelname' 55-59" 60 "`labelname' 60-64" 65 "`labelname' 65-69" 70 "`labelname' 70-74" 75 "`labelname' 75+"  
	la val 	firstagegrp5 firstagegrp5l
	*tab firstagegrp5,m
	*recode d_count_lead (99=10)
	
// 	**define labels**
// 	loc counter   "1"
// 	loc labellist "" /*need to delete local if in loop*/		
// 	loc z 		 "firstagegrp5"
// 	levelsof `z', local(levels)
// 	foreach l of local levels{
// 	loc 	valuel : label (`z') `l'				
// 	local labellist  `labellist' `counter' `"`valuel'"'   
// 	loc counter = `counter'+1	
// 	}
// 	mac list _labellist	 // should not display, but mac list 	

	loc 	y 			"d_count"
	loc 	ylabel: 	var label `y'
	loc 	cat  	  	"firstagegrp5" 
	loc 	timevar 	"age" 
	loc 	xla 		""
	loc 	xlarotate	""	
	loc 	opt_marginsplot "ytitle("Predicted (`ylabel')")" // noci  
	loc 	ctrls  		"`ctrl'"
loc cohortvar 	"cohortmin5"
loc cohort 		"50"
foreach cohort in 50 55 60 65 {
loc cohortlabel: label (`cohortvar') `cohort'
	loc 	reg  		xtreg `y' `timevar'##`cat' `ctrls' if `sample'==1 & countatfirstobs==0 & d_anyatfirstobs==0   & `cohortvar'==`cohort'
	qui `reg'
	qui margins `timevar'#`cat'
	marginsplot, `opt_marginsplot'  `xla' `xlarotate' title("Crude Data, by age of first onset (`cohortlabel')") legend(order(`labellist')) note("Sample: `samplelabel' | Controls: `ctrls' (none)" "Model: `reg'")  name(g`cat'_`cohort', replace)  // by(cohortmin5) // 
	gr export 	"$outpath/fig/main/g_by`timevar'-`cat'_`sample'_`y'_`cohort'.jpg", replace `jpghighquality'
		*gr export 	"C:\Users\User\Documents\GitHub\2-projectMM-SHARE\files\figELSA/g_reg_by`timevar'-`cat'_`sample'_`y'.jpg", replace // also copy into presentation location
}
	pause
		restore 
	*/



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
loc 	opt_marginsplot "ytitle("Predicted (`ylabel')")" // noci  
loc 	ctrls  		"`ctrl'"
loc 	reg  		reg `y' `timevar'##`cat' `ctrls' if `sample'==1 
qui `reg'
qui margins `timevar'#`cat' 
marginsplot, `opt_marginsplot'  name(g`cat'_`cohort', replace) `xla' `xlarotate'   title("`ylabel' over calendar time")  note("Sample: `samplelabel' | Controls: `ctrls' (none)" "Model: `reg'")
gr export 	"$outpath/fig/main/g_reg_by`timevar'-`cat'_`sample'_`y'.jpg", replace `jpghighquality'
restore	
pause 
*/
	



/*** +++ prevalence of count by cohort groups / age +++ ***
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

**predictions using ologit**
loc reg 	ologit 	 `y' i.`x' if `sample'==1 & age<=90, // vce(cl ID)  /*plot raw data*/
eststo m1: qui `reg'
qui margins `x'	// no dydx
marginsplot, title("Predicted `y' by `x'") note("Sample: `samplelabel' | Controls: `ctrls' (none)" "Model: `reg'") legend(order(`labellist')) recast(line) recastci(rarea)  yla(0 0.8)
gr export 	"$outpath/fig/main/g_ologit_by`x'_`y'.jpg", replace `jpghighquality'
	*gr export 	"C:\Users\User\Documents\GitHub\2-projectMM-SHARE\files\figELSA/g_ologit_by`x'_`y'.pdf", replace `jpghighquality' // also copy into presentation location
	+
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


	*** +++ 2-y transition probability +++ ***
	*preserve 
	gen 	d_count2 = d_count
	replace d_count2 = 99 if dead==1 
	la de  	d_count2l 99 "dead" // add dead label to 99
	la val 	d_count2 d_count2l
	tab 	d_count2 
**# Bookmark #2 need to set d_count2 to missing after first period dead
	tab 	d_count d_count_lead, nofreq row matcell(test)
	mat li test 
	xttrans d_count2
	**start plot**
	forval gamma=0/4{ // only from 4 starting states
		sum d_count if d_count!=99, meanonly 
		loc d_countmax = r(max)
		*loc    j=2
		forval j=0/`d_countmax'{
	gen trans_`gamma'to`j' = (d_count == `gamma' & d_count_lead == `j') if !mi(d_count) & !mi(d_count_lead) & d_count==`gamma' // indicator of WHETHER transiting to specific condition
	tab trans_`gamma'to`j' d_count
	}
	gen trans_`gamma'todead = (d_count == `gamma' & d_count_lead == 99) if !mi(d_count) & !mi(d_count_lead) & d_count==`gamma' // indicator of WHETHER transiting to specific condition	
	}
	sum trans_*	
	
	**
	/**using logistic fit (only single outcome allowed (I think, unless able to combine margins to a single marginsplot) - the solution is to predict the margins for the ordered logit)**
	logit trans_1to2 c.age if sfull==1
	margins , at(age=(51(10)90))
	marginsplot 
	*/
	
	/**crude plotting: transition by age**
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
	gr export 	"$outpath/fig/main/g_by`x'_transp_`gamma'toj.jpg", replace `jpghighquality'
	restore
	}
	pause
	*/	
	
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
// loc cohortlabel : label (cohortmin5) `cohort'
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

/**	ologit**
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
	gr export 	"$outpath/fig/main/g_ologit_by`x'_`y'_`startcount'_adj.jpg", replace `jpghighquality'	
*/

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
	
	
++++

*** cross-country differences in d_count in SHARE *** 
tab countryID, sum(d_count)



***Single-record-per-subject survival data (time until first disease)***	
// stset timevar [if] [weight] , id(idvar) failure(failvar[==numlist]) [multiple_options]
// streset [if] [weight] [, multiple_options]
// streset, {past|future|past future}
// st [, nocmd notable]
// stset, clear
	// by disease count
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


		/*** +++ selective attrition +++ *** 
		*** split by regions ***
		if dataset == "ELSA" {
		gen countryID = "EN"
		}
		gen 	region = "N.A."
		replace	region = "North"  		 if (countryID=="AT"|countryID=="Bf"|countryID=="Bn"|countryID=="Cf"|countryID=="Cg"|countryID=="Ci" | countryID=="DE"|countryID=="DK"|countryID=="EE"|countryID=="FI"|countryID=="FR"|countryID=="IE"        |countryID=="Ia" |countryID=="Ih" |countryID=="Ir"     |countryID=="LT"|countryID=="LU"|countryID=="LV" |countryID=="NL" |countryID=="SE"       ///
		| countryID=="EN") // add EN
		replace region = "Center-East"   if (countryID=="BG"|countryID=="CZ"|countryID=="HR"|countryID=="HU"|countryID=="Cf" |countryID=="PL" |countryID=="RO" |countryID=="SI" |countryID=="SK" )
		replace region = "South" 		 if (countryID=="CY"|countryID=="ES"|countryID=="IT"|countryID=="MT"|countryID=="PT")	
		qui log using 	"$outpath/logs/log-regionclassification.txt", text replace name(log) 
		tab countryID region,m
		log close log
	// 	label 	define regionl 1 "North-East" 2 "East" 3 "Center" 4 "West"
	// 	*label   define regionl 1 "NE" 2 "E" 3 "C" 4 "W"
	// 	label	value  region regionl	
		*keep if region=="North"
		
		
		tab d_count d_miss
		sum hibper diaber hearter lunger psycher osteoer cancrer stroker arthrer demener if sfull==1 & dead==0	
		gen d_missany = d_miss!=0 & !mi(d_miss)
		tab d_miss d_missany   	if sfull==1 & dead==0,m
		count 					if sfull==1 & dead==0
		
		*why are there so many missing diseases
		* why is not everybody asked this question on diseases?
		*count if dead==0
		*sum hibper diaber cancrer psycher  if dead==0
		*maybe bc countries entered later?
		*egen 	d_miss2 	= rowmiss(`alldiseases') /*counts number of diseases "missing" for each observation (row)*/ in hrs need to adjust this cuz osteo is missing
		
		tab 	age d_missany 
			tab 	age d_missany if d_missany==1, nofreq col
		tab 	age d_miss 
		tab 	d_missany inwt
			tab 	d_missany inwt
		logit 	d_missany c.age c.age#c.age 
		margins , at(age=(51(5)90))
		marginsplot 
		
			preserve 
			collapse (mean) y = d_missany, by(age region)
			scatter y age, by(region)
			restore
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


		