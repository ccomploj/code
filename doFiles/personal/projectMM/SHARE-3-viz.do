pause on
pause off
log close _all 	/*closes all open log files*/
clear all		/*clears all data in memory*/



***choose data***
loc data "SHARE"
loc datalist 	"SHARE HRS ELSA"
foreach data of local datalist{


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
set graphics on 
*set graphics off /*disables graphics*/




			


****************************************************************************************************
*Part 7*: Vizualization (general)
****************************************************************************************************	
cd  	"$outpath/fig"
	*sample 5
	
	
*** define additional variables ***
gen 	agegrp 	= age
replace agegrp 	= `upperthreshold' if agegrp>`upperthreshold' & agegrp<. /*group few very old*/
la var  agegrp 	"age"
*tabstat age, by(agegrp) stats(min max)

*** define locals to apply to entire file ***
set scheme s1color
loc opt_global 	"scheme(s1color)"
loc sample 		"sfull" // sbalanced
loc samplelabel: variable label `sample'


/*** +++++++++++++++++++ histograms of dependent variable +++++++++++++++++++ ***
loc 	y "d_count"
foreach y in "d_count" "diff_d_count" "cognitionstd" {
hist `y'	if `sample'==1, `opt_global' 
gr export 	"$outpath/fig/`saveloc'/g_hist_`sample'_`y'.jpg", replace
}
*STOP
*/

/*** +++++++++++++++++++ raw mean and se by age-group +++++++++++++++++++ ***
loc y 		"d_any"
loc ylist	"pubpenr d_any d_count d_count_index" // 
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
/** method 1: using serrbar: https://www.biostat.jhsph.edu/courses/bio622/misc/graphci_methods_2009_revised.pdf **
serrbar `y'_mean `y'_`se' `x' , scale(1.96) yline(0) ytitle("`ylabel'")  xtitle("`agegrplabel'") 
}
++
*/
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
gr export 	"$outpath/fig/main/g_crude_by`x'_`y'.jpg", replace 
restore	
}
pause
*STOP 
*/	


*** +++++++++++++++++++ scatterplot by age (c.f. Fig 1 in De Nardi) +++++++++++++++++++ ***
gen tempvar = d_count if inw_first==wave // count at baseline
bys ID: egen countatfirstobs = max(tempvar) 
recode countatfirstobs (0 = 0 "0 diseases at baseline") (1 = 1 "1 diseases at baseline") (2 = 2 "2 diseases at baseline") (3 = 3 "3 diseases at baseline") (4/10 = 4 "4+ diseases at baseline"), gen(countatfirstobs2)
drop tempvar countatfirstobs
rename countatfirstobs2 countatfirstobs 

gen tempvar = d_count if timesincefirstonset==0 // count at onset
bys ID: egen countatonset = max(tempvar) 
replace countatonset =. if age<firstage // if first onset not experienced yet, should not include
recode countatonset (1/2 = 1 "1 or 2 diseases at onset") (3/4 = 2 "3 or 4 diseases at onset") (5/15 = 3 "5 or more at onset"), gen(countatonset2)
drop tempvar countatonset
rename countatonset2 countatonset 

loc y "d_count"
loc x "age"
loc ylabel: variable label `y'
	** scatter count by age by baseline count OR onset count **
loc z 	  "countatfirstobs" // countatonset | countatfirstobs
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
twoway `connectedlist', legend(order (`labellist')) // ytitle(`ylabel')
gr export 	"$outpath/fig/main/g_crude_byage-`z'_`sample'_`y'.jpg", replace			
restore
} 
*STOP
*/




*** ++++++++++++ xtline by age group +++++++++ ***
*** +++ graph by TIME: crude plotting and xtreg with and without covariates+++ ***
preserve 
log using "$outpath/logs/log-g_bytime-cohortmin5.txt", text replace name(log)	
loc 	 y 		"d_count"
loc 	 ylabel: var label `y'
** graph: xtline by age group **
loc 	 timevar "timesincefirstobs" // timesincefirstobs_yr | time | timesincefirstobs
collapse (mean) `y' = `y' 	(count) `y'_freq = `y' if `sample'==1, by(cohortmin5 `timevar') // & inw1==1 & everdead==0
xtset 	 cohortmin5 `timevar'
loc 	 y2 	"`y'"	
	di "`y'"
	sum `y'
xtline 	 `y', overlay i(cohortmin5) t(`timevar') ytitle("mean `ylabel'") `opt_global'
*	loc x "timesincefirstobs"
*	twoway (connected `y' `x' if cohortmin5==`agethreshold') (connected `y' `x' if cohortmin5==55) (connected `y' `x' if cohortmin5==60) (connected `y' `x' if cohortmin5==65) , ytitle("mean `ylabel'") legend(order(1 "baseline age 50-54" 2 "baseline age 55-59" 3 "baseline age 60-64" 4 "baseline age 65-69")) // if age>50; only plot 5 
gr export 	"$outpath/fig/main/g_crude_bytime-cohortmin5_`sample'_d_count.jpg", replace
qui log close log
pause	
restore 	
	** plot using margins **
	clonevar radyear2 = radyear 
	recode 	 radyear2 (. = 0)
	loc reg "xtreg `y' i.timesincefirstobs#i.cohortmin5"
	`reg'
	margins i.timesincefirstobs#i.cohortmin5
	marginsplot, ytitle("predicted `ylabel'") note("Notes: This marginsplot uses the following sample: `samplelabel'" "and no controls" "The underlying regression is: `reg'") title("Adjusted Predictions") // noci
	gr export 	"$outpath/fig/main/g_reg_bytime-cohortmin5_`sample'_d_count.jpg", replace
	** plot using margins with controls **
	loc ctrls "male marriedr raeducl i.timesincefirstobs#i.male i.timesincefirstobs#i.raeducl"
	loc reg 	xtreg `y' i.timesincefirstobs#i.cohortmin5 `ctrls'
	`reg' 
	margins i.timesincefirstobs#i.cohortmin5 
	marginsplot, ytitle("predicted `ylabel'") note("Notes: This marginsplot uses the following sample: `samplelabel'" "and the following controls: `ctrls'." "The underlying regression is: `reg'") title("Adjusted Predictions") // noci
	gr export 	"$outpath/fig/main/g_reg_bytime-cohortmin5_`sample'_d_count_adj.jpg", replace
	** plot using margins with controls, adj. for mortality**
	loc ctrls "male marriedr raeducl i.timesincefirstobs#i.male i.timesincefirstobs#i.raeducl i.radyear2"
	loc reg 	xtreg `y' i.timesincefirstobs#i.cohortmin5 `ctrls'
	`reg' 
	margins i.timesincefirstobs#i.cohortmin5 
	marginsplot, ytitle("predicted `ylabel'") note("Notes: This marginsplot uses the following sample: `samplelabel'" "and the following controls: `ctrls'." "The underlying regression is: `reg'") title("Adjusted Predictions") // noci
	gr export 	"$outpath/fig/main/g_reg_bytime-cohortmin5_`sample'_d_count_adj_mortality.jpg", replace
pause
*STOP
*/


*** +++ graph by TIME: vars (with and without controlling for covariates) +++ ***
log using "$outpath/logs/log-g_bytime.txt", text replace name(log)
**# Bookmark #1 Can I do this here with xtologit?
loc 	timevar 	"timesincefirstobs"
loc 	ctrls 		"age male"
loc 	y			"d_count"
loc 	ylist 		"d_count d_count_index timetonextdisease2" //
loc 	reg 		"xtreg" // xtreg | xtologit is very slow; choice may depend on distribution of dependent variable; using index may indeed be the most appropriate.
*foreach sample in 	"sfull" "sneverdead" "shealthyatfirstobs"  { /*first sample defined at top of file*/
	di "Sample is: `sample' and variables are:"
	loc samplelabel: variable label `sample'
	sum `ylist' `timevar' `ctrls' if `sample'	
	*foreach y of local ylist { /*repeat graph for each selected variable*/
loc 	ylabel : variable label `y'		/*uses variable label of y*/	
qui {
**without controls**
	*qui log using "$outpath/logs/log-g_bytime.txt", text replace name(log) // put here if want to close it everytime regardless of running loop
	*di 	"timevar: `timevar' | ctrls `ctrls' | y: `y' | ylist `ylist' | sample `sample'"
	sum `y' `timevar'
`reg' 	`y' i.`timevar'  		if `sample' // without controls
margins 	`timevar', noestimcheck // atmeans
marginsplot, xdimension(`timevar') ytitle("`ylabel'") note("Notes: This marginsplot uses the following sample: `samplelabel' and no controls." "The underlying regression is: `reg'")  // xla(, ang(45))  ytitle("`ylabel'")
gr export 	"$outpath/fig/`saveloc'/g_reg_bytime_`sample'_`y'.jpg", replace
*/
	**with controls (male)**
	`reg'	`y' i.`timevar'##male `ctrls' if `sample' // with controls
	margins 	`timevar'#male, noestimcheck 
	marginsplot, xdimension(`timevar') ytitle("`ylabel'") note("Notes: This marginsplot uses the following sample: `samplelabel'" "and no controls." "The underlying regression is: `reg'") // xla(, ang(45))
	gr export 	"$outpath/fig/`saveloc'/g_reg_bytime-male_`sample'_`y'.jpg", replace
**with controls (educ)**
`reg'	`y' i.`timevar'##raeducl `ctrls' if `sample' // with controls
margins 	`timevar'#raeducl, noestimcheck 
marginsplot, xdimension(`timevar') ytitle("`ylabel'") note("Notes: This marginsplot uses the following sample: `samplelabel'" "and the following controls: `ctrls'." "The underlying regression is: `reg'") // xla(, ang(45))
gr export 	"$outpath/fig/`saveloc'/g_reg_bytime-educ_`sample'_`y'.jpg", replace
*/	
}
qui log close log
}
}
pause
STOP
*/
	
	

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



*** archive ***
	/*** +++ graph by DISEASE COUNT: timetonextdisease2  (with and without covariates) +++  ***
	loc timevar  	"d_count"
	loc ctrls 		"age male"
	loc y 		 	"timetonextdisease2"
	loc 	reg 	"xtreg"
	loc 	sample 	"shealthyatfirstobs"
	foreach sample in "sfull" "shealthyatfirstobs" "sneverdead"  { 
	loc 	ylabel : variable label `y'		/*uses variable label of y*/	
		di "Sample is: `sample'"
		sum `y' `ctrls' if `sample'
	qui {
	**without controls**
	`reg' 		 `y' i.`timevar'  			if `sample'
	margins 	 `timevar', noestimcheck
	marginsplot, xdimension(`timevar') ytitle("`y'") note("Notes: This marginsplot uses the sample: `sample' and no controls." "The underlying regression is: `reg'")  // xla(, ang(45)) ytitle("`ylabel'")
	*gr export 	"$outpath/fig/`saveloc'/g_by`timevar'_`sample'_`y'.jpg", replace
	**with controls**
	`reg' 		 `y' i.`timevar' `ctrls'  	if `sample'
	margins 	 `timevar', noestimcheck
	marginsplot, xdimension(`timevar') ytitle("`y'") note("Notes: This marginsplot uses the sample: `sample' and the controls: `ctrls'." "The underlying regression is: `reg'")  // xla(, ang(45)) ytitle("`ylabel'")
	*gr export 	"$outpath/fig/`saveloc'/g_byd_count_`sample'_`y'_withctrls.jpg", replace
	}
	}
	STOP

		