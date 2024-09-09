pause on
pause off
log close _all 	/*closes all open log files*/
clear all		/*clears all data in memory*/

**# Bookmark #1 note: in HRS, _uncens variables are not OK since I drop waves 1 and 2 only later!!


***choose data***
loc data 		"SHARE"
loc datalist 	"SHARE ELSA HRS"
*foreach data of local datalist{


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
if "`data'"=="SHARE" {
loc agethreshold 	"50" // select survey-specific lower age threshold
}
if "`data'"=="ELSA" {
loc agethreshold 	"50" // select survey-specific lower age threshold
}
if "`data'"=="HRS" {
loc agethreshold 	"51" // select survey-specific lower age threshold
// 	keep if wave>=3 & wave<=13 // cognitive measures not consistently available 		
}	
	if "`data'"=="SHAREELSA" {
	loc agethreshold 	"50" // select survey-specific lower age threshold
		drop if agemin<50  & dataset=="SHARE"
		drop if agemin<50  & dataset=="ELSA"
		*drop if wave==3    & dataset=="SHARE" // already dropped
			drop if hacohort>2 & dataset=="SHARE"  
	}	
	*STOP /*comment to continue running file*/
**********************
cd  "$outpath/fig"



***************************************************************************************************
*Part 7a*: Vizualization (Do File Setup, variable and local definitions) 
***************************************************************************************************
*** define locals to apply to entire file ***
// 	gl sample 		"sfullsample" // sfullsample, sbalanced, sfull5 (choose what is best)
// 	gl samplelabel: variable label $sample
loc sample 		"sfull5" // copy these lines if a specific subsample shall apply to specific plot
loc samplelabel: variable label `sample'
set scheme s1color
gl opt_global 		"" // settings to apply to all graphs 
gl  diseasecodelist "hibp diab heart lung depr osteo cancr strok arthr demen" // psych
gl  diseaselist 	"d_hibp d_diab d_heart d_lung d_depr d_osteo d_cancr d_strok d_arthr d_demen"


*** define additional variables ***
*** age groups ***
gen 	agegrp 	= age
replace agegrp 	= 85 if agegrp>85 & agegrp<. /*group few very old*/
la var  agegrp 	"age"
*tabstat age, by(agegrp) stats(min max)


	
/** income groups **
loc temp "5"
xtile 	qitoth = itoth, nq(`temp')
la var 	qitoth "quantile (`temp') of itoth"
*pctile  pctile = itoth, nq(3) genp(perc)
*xtile 	incomegroups2 = itoth, cutpoints(pctile) // same, but can be based on another variable
*pctile pct = mpg [w=weight], nq(10) genp(percent) // could add weights
*/

	** install packages **
	*net install transcolorplot , from(http://www.vankerm.net/stata)
	*net describe transcolorplot

***************************************************************************************************
*Part 7b*: Vizualization (Plots)
***************************************************************************************************
/*** +++ distribution (hist) of main variables +++ ***
loc sample 	"sfull5" // copy these lines if a specific subsample shall apply to specific plot
foreach sample in "sfullsample" "sfull5" {
preserve 
loc slabel: variable label `sample'
loc histlist ""
bys ID: egen d_countmax = max(d_count)
la var 		 d_countmax "# diseases (max. before death)"
loc 	y "duration"
foreach y in "d_count" "d_countmax" "ageatfirstobs" "onsetage" "onsetage_uncens" {
	di "`slabel'"
hist `y'	if `sample'==1, name(h`y', replace) title(`ylabel') note("`slabel'")
gr export 	"$outpath/fig/`altsaveloc'/g_hist_`sample'_`y'.jpg", replace quality(100) 
loc histlist "`histlist' h`y'" 
}
di	 		"`histlist'"
loc slabel: var label `sample'
gr combine `histlist', title("`slabel'")
gr export 	"$outpath/fig/main/g_hist_`sample'_combined.pdf", replace
restore
}
STOP
*/


/***********************************************************************
*** +++ Histogram/Density of onset, for each disease separately +++ *** 
***********************************************************************
local 	templist "$diseasecodelist" // always check chosen diseases are up to date
foreach y of local templist {
la var radiag`y' 	"sr.onset `y'"
la var onsetd_`y'	"obs.onset: `y'"
// la var onsetd_`y'_uncens	"obs.onset: `y' (uncens)" // too long in combined graph
}

*** histogram of onset ***
**# Bookmark #1 plot of sfull5healthy is unnecessary here for the radiag vars (same for density below), can also add to notes of each grapth the number of observations present in each distribution
loc opt_local "" // scheme(s2mono) : not used bc does not fit
loc sample 		"sfullsample" // copy these lines if a specific subsample shall apply to specific plot
	loc sample 		"sfull5" // copy these lines if a specific subsample shall apply to specific plot
	
	loc opt_local "" // scheme(s2mono) : not used bc does not fit
	
	capture program drop myhistogram
	program define myhistogram 
		args varname
			loc templist "hibp diab heart lung"
		foreach y of local templist {
			di "`y'"
			hist `varname'
		}	
	end
	myhistogram onsetd_hibp
	
	++
	di "`histlist'"
	gr combine `histlist', title("histogram: first onset by disease (self-reported)" "`samplelabel'") name(h1`sample', replace) `opt_local'
// 	gr export "`outpath'/fig/main/g_hist_`sample'_radiagonsetalld.pdf", replace 
++


foreach sample in "sfull5" "sfull5healthy" {
preserve
loc samplelabel: variable label `sample'
loc histlist 			""
loc histlist_observed 	""
foreach y of local templist {
hist radiag`y'	if `sample' == 1, `opt_global'  name(h`y', replace) `opt_local'
loc  histlist 	"`histlist' h`y'"		
hist onsetd_`y'	if `sample' ==1, `opt_global' name(h2`y', replace) `opt_local'
loc  histlist_observed 	"`histlist_observed' h2`y'"		
}	
di	 		"`histlist'"
gr combine `histlist', 			 title("histogram: first onset by disease (self-reported)" "`samplelabel'") name(h1`sample', replace) `opt_local'
gr export 	"$outpath/fig/main/g_hist_`sample'_radiagonsetalld.pdf", replace 
di	 		"`histlist_observed'"
gr combine `histlist_observed',  title("histogram: first onset by disease (observed)" "`samplelabel'") name(h2`sample', replace) `opt_local'
gr export 	"$outpath/fig/main/g_hist_`sample'_onsetalld.pdf", replace 
restore 
}
STOP
*/

/*** density (non sex-specific) ***
**# Bookmark #3 also here too many unnecessary plots, should consider separating radiag from the rest, but then also consider sex-specific
// loc sample 		"sfull5"  
foreach sample in "sfull5" "sfull5healthy" {
preserve
loc samplelabel: variable label `sample'
loc kdenlist 			""
loc kdenlist_obs 		""
loc kdenlist_obs_uncens ""
foreach y of local templist {
// radiag
kdensity  radiag`y'  if `sample' == 1, gen(point`y' density`y') bw(2) nograph 
loc kdenlist 	"`kdenlist' (line density`y' point`y')"
// observed (censored)
kdensity  onsetd_`y' if `sample' == 1, gen(point`y'_obs density`y'_obs) bw(2) nograph // only for healthy at baseline sample
loc kdenlist_obs 	"`kdenlist_obs' (line density`y'_obs point`y'_obs)"
// observed (uncensored-separately for each disease)
kdensity  onsetd_`y'_uncens if `sample' == 1, gen(point`y'_obs_uncens density`y'_obs_uncens) bw(2) nograph // excluding onset ages which are left-cencored (for each disease separately) 
loc kdenlist_obs_uncens  "`kdenlist_obs_uncens' (line density`y'_obs_uncens point`y'_obs_uncens)"
** change label of resulting densities **
loc 	radiag`y'label: var label radiag`y'
la var 	density`y' "`radiag`y'label'"
loc 	onsetd_`y'label: var label onsetd_`y'
la var 	density`y'_obs "`onsetd_`y'label'"
loc 	onsetd_`y'_uncenslabel: var label onsetd_`y'_uncens
la var 	density`y'_obs_uncens "`onsetd_`y'_uncenslabel'"
}
di 			"`kdenlist'" /*for non-sex-specific*/
twoway 		`kdenlist', xla(0(10)80) title("density: first onset by disease (self-reported)"  "`samplelabel'") name(k1,replace) 
gr export 	"$outpath/fig/main/g_kden_`sample'_radiagonsetalld.pdf", replace 
di 			"`kdenlist_obs'"
twoway 		`kdenlist_obs', title("density: first onset by disease (observed)"  "`samplelabel'") name(k2, replace) 
gr export 	"$outpath/fig/main/g_kden_`sample'_onsetalld.pdf", replace 
di 			"`kdenlist_obs_uncens'"
twoway 		`kdenlist_obs_uncens', title("density: first onset by disease (observed)" "(uncensored part on each disease)"  "`samplelabel'") name(k3, replace)
gr export 	"$outpath/fig/supplement/g_kden_`sample'_onsetalld_uncens.pdf", replace 
restore
}
STOP
*/

/*** density (sex-specific) ***	
**# Bookmark #4 here do this only for one sample (but for radiag need full sample (not only healthy))
loc sample 			"sfull5healthy" 
	foreach sample in "sfull5" "sfull5healthy" {
	preserve 
	foreach y of local templist {
	la var onsetd_`y'	"onset: `y'"
	}
	loc kdenlistmale 		""
	loc kdenlistfemale 		""
	loc kdenlist_obsmale 	""
	loc kdenlist_obsfemale 	""
loc samplelabel: variable label `sample'
gen 	sex = "male" 	if male==1
replace sex = "female" 	if male==0
foreach sex in male female {
foreach y of local templist {	
kdensity radiag`y' if `sample' == 1 & sex == "`sex'", gen(point`y'`sex' density`y'`sex') bw(2) nograph 
loc kdenlist`sex' 		"`kdenlist`sex'' 	 (line density`y'`sex' point`y'`sex')"
kdensity onsetd_`y' if `sample' == 1 & sex == "`sex'", gen(point`y'_obs`sex' density`y'_obs`sex') bw(2) nograph 
loc kdenlist_obs`sex' 	"`kdenlist_obs`sex'' (line density`y'_obs`sex' point`y'_obs`sex')"
** change label of resulting densities **
loc 	radiag`y'label: var label radiag`y'
la var 	density`y'`sex' "`radiag`y'label'"
loc 	onsetd_`y'label: var label onsetd_`y'
la var 	density`y'_obs`sex' "`onsetd_`y'label'"
}
}
di "`kdenlistmale'"
twoway `kdenlistmale', 	 xla(0(10)80) 	title("male") name(k1male, replace)
twoway `kdenlistfemale', xla(0(10)80) 	title("female") name(k1female, replace)
gr combine k1male k1female, title("density: first onset by disease (self-reported)"  "`samplelabel', `data'") ycommon name(k1bysex, replace)
gr export 	"$outpath/fig/main/g_kden_`sample'_radiagonsetalld_bysex.pdf", replace 
twoway `kdenlist_obsmale',  	title("male") name(k2male, replace)
twoway `kdenlist_obsfemale', 	title("female") name(k2female, replace)
gr combine k2male k2female, title("density: first onset by disease (observed)"  "`samplelabel', `data'") ycommon name(k2bysex, replace)
gr export 	"$outpath/fig/main/g_kden_`sample'_onsetalld_bysex.pdf", replace 
restore 
	}
STOP
*/

	/*** density of higher order onset ***	
	** generate higher order onset (self-reported) ** 
	sum radiag* 
	sum onsetage_g2 // 1st onset 
	des onsetage_g2

	// now define the 2nd onset age (using radiag)
// 	loc  diseasecodelist "$diseasecodelist" 
	di 	"`diseasecodelist'"
	
	loc 	radiaglist "" 
	foreach v of global diseasecodelist {
    gen second_onset_age_`v' = radiag`v' if radiag`v' > onsetage_g2 
}
	egen onsetage_g2_2th = rowmin(second_onset_age_*)

	foreach v of global diseasecodelist {
    gen third_onset_age_`v' = radiag`v' if radiag`v' > onsetage_g2_2th 
}
	egen onsetage_g2_3th = rowmin(third_onset_age_*)

	sum onsetage_g2 second_* third_*
	drop second_* third_* 
	// now define if the disease first emerged at the same time as the 2nd (3rd) disease (for each disease a variable)
	foreach v of global diseasecodelist {
	gen radiag2th`v' = radiag`v'  if radiag`v'  == onsetage_g2_2th 
	gen radiag3th`v' = radiag`v'  if radiag`v'  == onsetage_g2_3th 
	}
		*bro ID wave onsetage_g2* radiag*


	
	** generate higher order onset (observed) **
	sum onsetd_*
	sum onsetage2d onsetage3d
	
		** conditional on being healthy at baseline, what is the age at which the 2nd, the 3rd disease is first observed (and which disease is it)** 
// 					loc 	radiaglist "" 
			foreach v of global diseasecodelist {
			gen second_onset_age_`v' = onsetd_`v' if onsetd_`v' > onsetage 
		}
			egen onsetage_2th = rowmin(second_onset_age_*)
			*bro ID wave onsetage onsetd_* second_onset_age*

// 			foreach v of global diseasecodelist {
// 			gen third_onset_age_`v' = onsetd_`v' if onsetd_`v' > onsetage2d 
// 		}
// 			egen onsetage_3th = rowmin(third_onset_age_*)		
			drop second_onset_age_* third_onset_age* 
				
	// now define if the disease first emerged at the same time as the 2nd (3rd) disease 
	foreach v of global diseasecodelist {
	gen onset2thd_`v' = onsetd_`v'  if onsetd_`v'  == onsetage_2th 
	gen onset3thd_`v' = onsetd_`v'  if onsetd_`v'  == onsetage_3th 
	}
	*bro ID wave onset*
	*++
	
	
	*** density (non sex-specific) ***
		loc i "2" // 2 3 
			loc sample 		"sfull5healthy"  // do only for healthy sample
	loc samplelabel: variable label `sample'
	foreach y of local templist {
// 	kdensity  radiag`i'th`y'  if `sample' == 1, gen(point`y' density`y') bw(2) nograph 
// 	loc kdenlist 	"`kdenlist' (line density`y' point`y')"	
	kdensity  onset`i'thd_`y' if `sample' == 1, gen(point`y'_obs density`y'_obs) bw(2) nograph 
	loc 	  kdenlist_obs 	"`kdenlist_obs' (line density`y'_obs point`y'_obs)"
	** change label of resulting densities **
// 	loc 	radiag`i'th`y'label: var label radiag`i'th`y'
// 	la var 	density`y' "`radiag`i'th`y'label'"
	loc 	onset`i'thd_`y'label: var label onsetd_`y'
	la var 	density`y'_obs "`onsetd_`y'label'"
	}
// 	di 			"`kdenlist'" /*for non-sex-specific*/
// 	twoway 		`kdenlist', xla(0(10)80) title("density: `i'-th onset by disease (self-reported)"  "`samplelabel'") name(k1,replace)
//  	gr export 	"$outpath/fig/main/g_kden_`sample'_radiagonset`i'thalld.pdf", replace 
	di 			"`kdenlist_obs'"
	twoway 		`kdenlist_obs', title("density: `i'-th onset by disease (observed)"  "`samplelabel'") name(k2, replace)
 	gr export 	"$outpath/fig/main/g_kden_`sample'_`i'thonsetalld.pdf", replace 
	STOP	
	*/
	
	


	
	/*** density (non sex-specific) ***
		loc i "3" // 2 3 
 	loc sample 		"sfull5"  
	loc samplelabel: variable label `sample'
	foreach y of local templist {
	kdensity  radiag`i'th`y'  if `sample' == 1, gen(point`y' density`y') bw(2) nograph 
	loc kdenlist 	"`kdenlist' (line density`y' point`y')"	
// 	kdensity  onsetd_`y'_uncens if `sample' == 1, gen(point`y'_obs density`y'_obs) bw(2) nograph 
// 	loc kdenlist_observed 	"`kdenlist_observed' (line density`y'_obs point`y'_obs)"
	** change label of resulting densities **
	loc 	radiag`i'th`y'label: var label radiag`i'th`y'
	la var 	density`y' "`radiag`i'th`y'label'"
// 	loc 	onsetd_`y'label: var label onsetd_`y'_uncens
// 	la var 	density`y'_obs`sex' "`onsetd_`y'label'"
	}
	di 			"`kdenlist'" /*for non-sex-specific*/
	twoway 		`kdenlist', xla(0(10)80) title("density: `i'-th onset by disease (self-reported)"  "`samplelabel'") name(k1,replace)
 	gr export 	"$outpath/fig/main/g_kden_`sample'_radiagonset`i'thalld.pdf", replace 
// 	di 			"`kdenlist_observed'"
// 	twoway 		`kdenlist_observed', title("density: first onset by disease (observed)"  "`samplelabel'") name(k2, replace)
// 	gr export 	"$outpath/fig/main/g_kden_`sample'_2ndonsetalld.pdf", replace 
	STOP
	
		
++
	
// 	// foreach sex in male female {
// 	foreach y of local templist {	
// 	// kdensity radiag`y' if sex == "`sex'", gen(point`y'`sex' density`y'`sex') bw(2) nograph 
// 	// loc kdenlist`sex' 		"`kdenlist`sex'' 	 (line density`y'`sex' point`y'`sex')"
// 	kdensity onsetd_`y' if sex == "`sex'", gen(point`y'_obs`sex' density`y'_obs`sex') bw(2) nograph 
// 	loc kdenlist_obs`sex' 	"`kdenlist_obs`sex'' (line density`y'_obs`sex' point`y'_obs`sex')"
// 	** change label of resulting densities **
// 	// loc 	radiag`y'label: var label radiag`y'
// 	// la var 	density`y'`sex' "`radiag`y'label'"
// 	loc 	onsetd_`y'label: var label onsetd_`y'
// 	la var 	density`y'_obs`sex' "`onsetd_`y'label'"
// 	}
// 	}
STOP
	*/


**# Bookmark #2 could add here a similar density plot now, but with (different) combinations of diseases for each age



*/

	/**bar chart with ever had condition **
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

/** ++ logistic prediction over age for each disease type ((?)plot smoothes out mortality) ++ **
loc 	sample 			"sfull5" 
loc 	samplelabel: variable label `sample'
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
	**generate predictions for each level of x's (same as -margins- above, but can combine predictions into one plot)**
	predict xb`y', pr
	loc 	xblist 			"`xblist' xb`y'"
	loc 	connectedlist 	"`connectedlist' (connected xb`y' age)"
qui margins male, at(age=(`agethreshold'(5)100)) 
marginsplot, title("Logistic Prediction" "(`ylabel')") name(g`y') xla(50(5)100) ytitle("") 
loc glist "`glist' g`y'"
}
gr combine `glist', ycommon name(logitby)
gr export 	"$outpath/fig/main/g_logit_byage-male-`sample'-alld.pdf", replace 
	** plot xbvalues above (genders combined) **
	preserve // plot mean predictions from above
	collapse (mean) `xblist', by(age)
	twoway `connectedlist', title("Logistic predictions of age") name(xb)
	gr export 	"$outpath/fig/main/g_logit_byage-`sample'-alld-xb.pdf", replace 
	restore 
STOP
*/





		



/*** +++ prevalence of count by cohort groups / age +++ ***
loc 	sample 			"$sample" 
loc 	samplelabel: variable label `sample'
recode d_count (2/3=3 "2 or 3") (4/20=5 "4 or more"), gen(d_count2)
la var d_count2 "d_count (grouped)"
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
marginsplot, title("Predicted `y' by `x'" "`samplelabel'") note("Sample: `samplelabel' | Controls: `ctrls' (none)" "Model: `reg'") legend(order(`labellist')) recast(line) recastci(rarea)  yla(0 0.8)
gr export 	"$outpath/fig/main/g_ologit_by`x'_`y'.jpg", replace quality(100)
STOP
*/
**# Bookmark #2 check if this below is irrelevant
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


/*******************************************
*** +++ Disease count over time +++ *** 
*******************************************
preserve
**# could choose to drop some sample cohorts
if dataset=="SHARE" {
keep 	if hacohort==1 | hacohort==2 
}
if dataset=="ELSA" {
keep 	if hacohort==1  
}
if dataset=="HRS" {
keep 	if hacohort<5 
}
qui log using 	"$outpath/logs/log-agegrpmin5b.txt", text replace name(log) 
/*this log is to show that the generation of agegrpmin5b is correct*/
clonevar 	agegrpmin5b = agegrpmin5
	replace 	agegrpmin5b = .m if agegrpmin5>65
replace 	agegrpmin5b = .m if agegrpmin5!=agegrp5 /*if age is larger than entry cohort age*/	
la de 		agegrpmin5bl 50 "ageatfirstobs & age: `agethreshold'-54" 55 "ageatfirstobs & age: 55-59" 60 "ageatfirstobs & age: 60-64" 65 "ageatfirstobs & age: 65-69" .m "current age larger than agegrpmin5"
la val 		agegrpmin5b agegrpmin5bl
bys agegrpmin5b: sum age /*agegrpmin5 only contains age<=agegrpmin5*/
qui log close log 
*tab age agegrpmin5 if agegrpmin5b>=. // shows that all missing observations are larger than cohort group

loc 	sample 		"sfullsample"
loc 	y 			"d_count"
loc 	ylabel: 	var label `y'
loc 	timevar 	"time" // age | time | timesincefirstobs_yr | time | timesincefirstobs
loc samplelabel:	var label `sample'
loc 	xla 		"" /*keep this empty for raw plot*/
loc 	cat 		"agegrpmin5b"
loc 	opt_marginsplot "ytitle("Predicted (`ylabel')")" // noci  
loc 	ctrls  		"`ctrl'"
loc 	reg  		reg `y' `timevar'##`cat' `ctrls' if `sample'==1  
qui `reg'
qui margins `timevar'#`cat' 
marginsplot, `opt_marginsplot'  name(g`cat'_`cohort', replace) `xla'   title("`ylabel' over calendar time")  note("Sample: `samplelabel' | Controls: `ctrls' (none)" "Model: `reg'")  xla(, ang(20))
gr export 	"$outpath/fig/main/g_reg_by`timevar'-`cat'_`sample'_`y'.jpg", replace 
restore	
pause 
*/	


/*******************************************
*** +++ Disease count over age +++ *** 
*******************************************

**recode age and timesincefirstobs if too few observations fall in this category and SEs large (for agemin<=70 sample**
levelsof agegrpmin5, local(levels)
foreach  cohort of   local levels {
qui 	sum time, meanonly 
loc 	timerange = r(max)-r(min)+5 /*maximum time an id is observed (5 added for agemingrp)*/
di 		"`timerange'"
replace age = `cohort'+`timerange' if age >`cohort'+`timerange' & age<. & agegrpmin5==`cohort' 
replace timesincefirstobs = `timerange'-5 if timesincefirstobs<. & timesincefirstobs>`timerange'-5
} 

*** +++ graph over age +++ ***
loc 	y 			"d_count"
loc 	ylabel: 	var label `y'
loc 	cat  	  	"agegrpmin5" // male, raeducl, countatfirstobs
loc 	timevar 	"age" /*use age dummies*/
loc 	xla 		"xla(50(5)90)" /*needed for separate sub-plots*/
// loc 	xlarotate	""	
loc 	opt_marginsplot "ytitle("Predicted (`ylabel')")" // noci  
loc 	ctrls  "`ctrl'"
	/** xtline (crude data: identical to predictions (profile plots) from margins, but without CI) **
	*preserve // cannot preserve data twice in stata
	collapse (mean) `y' = `y' 	(count) `y'_freq = `y' if `sample'==1 `sampleaddition' , by(`cat' `timevar') 
	xtset 	 `cat' `timevar'
	xtline 	 `y', overlay i(`cat') t(`timevar') ytitle("mean `ylabel'") `opt_global'  title("Collapsed Means `cohortlabel'") note("Notes: The plot shows trends of the collapsed means")  `xla' name(g0_`cohort', replace)
	*gr export 	"$outpath/fig/main/g_crude_by`timevar'-`cat'_`sample'_d_count_`cohort'.jpg", replace quality(100)
	*restore
	*/

*overall plot by cohort groups* 
loc 	reg  		reg `y' `timevar'##`cat' `ctrls' if `sample'==1 
qui `reg'
timer on 1
qui margins `timevar'#`cat' 
//qui margins `cat', at(age=(`agethreshold'(1)90)) // this is a lot slower but does the same in this case
marginsplot,  `opt_marginsplot'   `xla' title("Crude Data (`data')") note("Sample: `samplelabel' | Controls: `ctrls' (none)" "Model: `reg'") name(g`cat'_`cohort', replace) // by(agegrpmin5) 
// gr export 	"$outpath/fig/main/g_reg_by`timevar'-`cat'_`sample'_`y'.jpg", replace	quality(100)
timer off 1 
timer list 1
	*pause
	
	/*by covariate levels ((a) single combined plot of each cohort group)* 
	loc 	 catlist 	"male raeducl countatfirstobs"	
	foreach  cat of local catlist {	
	loc catlabel: var label `cat'
	loc reg  		reg `y' `timevar'##`cat'##agegrpmin5 `ctrls' if `sample'==1 & age<90 // set age limit
	qui `reg'
	qui margins `timevar'#`cat'#agegrpmin5
	marginsplot,  `opt_marginsplot'   `xla' `xlarotate' by(agegrpmin5) byopts(title("Crude Data, by (`catlabel')")) name(g`cat'_`cohort', replace) // ycommon?
	*gr export 	"$outpath/fig/main/g_reg_by`timevar'-`cat'_`sample'_d_count_bycohort.jpg", replace	quality(100)
	}
	*/

*by covariate levels ((b) separate sub-plots per cohort)*
loc 	 catlist 	"raeducl"
// loc 	 catlist 	"male raeducl countatfirstobs"	
foreach  cat of local catlist {	
foreach  cohort of   local levels {
loc cohortlabel : label (agegrpmin5) `cohort'
loc cohortlabel "(`cohortlabel')"  /*add parentheses if subplots*/
*loc sampleaddition "& agegrpmin5==`cohort'" /*needs to be located here*/
loc 	 opt_marginsplot "title("Crude Data `cohortlabel'") ytitle("Predicted (`ylabel')")" // noci   
loc 	 ctrls  "`ctrl'"
loc 	 reg  	reg `y' `timevar'##`cat' `ctrls' if `sample'==1 & agegrpmin5==`cohort'
 `reg'
 margins `timevar'#`cat'
marginsplot, `opt_marginsplot'  `xla' `xlarotate' title("Crude Data (`data') `cohortlabel'") note("Sample: `samplelabel' | Controls: `ctrls' (none)" "Model: `reg'") name(g`cat'_`cohort', replace)  // by(agegrpmin5)
*gr export 	"$outpath/fig/main/g_reg_by`timevar'-`cat'_`sample'_d_count_`cohort'.jpg", replace quality(100)
} 
}
*/

	/*by mortality*
	**# Bookmark #1 can do separately for all countatfirstobs levels (otherwise, include this to plot (b) above)
**# Bookmark #1 I think this does this by all groups, hence code stops for >65
**# Bookmark #1 in ELSA have no radage apparently, check this
	loc 	 cat 	"radagegrp"
	loc 	 cohort "50"
	foreach  cohort of local levels {
	loc cohortlabel :  label (agegrpmin5) `cohort'
	loc cohortlabel "(`cohortlabel')"  /*add parentheses if subplots*/
	loc 	 ctrls  "`ctrl'"			
	loc 	 reg  	xtreg `y' `timevar'##`cat' `ctrls' if `sample'==1 & countatfirstobs==0  & agegrpmin5==`cohort' 
	qui `reg'
	qui margins `timevar'#`cat' 					// , at(countatfirstobs=0)
	marginsplot		,   `opt_marginsplot'  name(g`cat'_`cohort', replace) `xla' title("Crude Data `cohortlabel'") note("Sample: `samplelabel' | Controls: `ctrls' (none)" "Model: `reg'")  // by(agegrpmin5) 
	gr export 	"$outpath/fig/main/g_reg_by`timevar'-`cat'_`sample'_d_count_`cohort'.jpg", replace quality(100)
	}
	pause
	STOP
	*/

	
	/** probability of survival by wave **
// 	gen 		alive=(1-dead) if !mi(dead)
// 	logit 		alive i.time if agegrpmin5==50
// 	margins 	time
// 	marginsplot, noci
	preserve 
	stset wave, failure(dead)
	stdes	
	rename countatfirstobs c
	levelsof agegrpmin5, local(levels)
	foreach  cohortgrp of   local levels {
	loc cohortlabel :  label (agegrpmin5) `cohortgrp'
	sts graph if agegrpmin5==`cohortgrp', survival by(c) legend(pos(6) rows(3)) name(g`cohortgrp') title("Crude Data `cohortlabel'")	
	gr export 	"$outpath/fig/main/g_surv_`sample'_`cohortgrp'.jpg", replace quality(100)
	}
	restore 
	pause
	*/

/** +++ graph over timesincefirstobs +++ ***
loc 	y 			"d_count"
loc 	ylabel: 	var label `y'
loc 	cat  	  	"agegrpmin5" 
loc 	timevar 	"timesincefirstobs" 
loc 	xla 		""
// loc 	xlarotate	""	
loc 	opt_marginsplot "ytitle("Predicted (`ylabel')")" // noci  
loc 	ctrls  		"`ctrl'"
loc 	reg  		xtreg `y' `timevar'##`cat' `ctrls' if `sample'==1 
qui `reg'
qui margins `timevar'#`cat'
marginsplot, `opt_marginsplot'   `xla' `xlarotate'  title("Crude Data (`data')")  note("Sample: `samplelabel' | Controls: `ctrls' (none)" "Model: `reg'") name(g`cat'_`cohort', replace)
gr export 	"$outpath/fig/main/g_reg_by`timevar'-`cat'_`sample'_d_count.jpg", replace
	**# Bookmark #6 if i want to show that time of entry does not matter, i can show that accumulation is parallel for different inw_first groups. However, do this in a separate graph; for this, use inw_first as a category. For this: use *replace inw_first=. if inw_first>8 (only in HRS)
pause
*/

/*** +++++++++++++++++++ graph over age by first onset age +++ *** (and maybe also do by timesincefirstobs), timesincefirstobs does not make sense until i group categories by time, not by agegrps anymore
**# Bookmark #1 plot same plot also by categories of firstage_mm  +++++++++++++++++++ ***
* do also with d_count_lead 
	*preserve // bc replace firstage
	egen 	firstagegrp5 = cut(onsetage),    at (`agethreshold',55,60,65,70,75,120) // ,80, 	
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
// 	loc 	xlarotate	""	
	loc 	opt_marginsplot "ytitle("Predicted (`ylabel')")" // noci  
	loc 	ctrls  		"`ctrl'"
loc cohortvar 	"agegrpmin5"
loc cohort 		"50"
foreach cohort in 50 55 60 65 {
loc cohortlabel: label (`cohortvar') `cohort'
	loc 	reg  		xtreg `y' `timevar'##`cat' `ctrls' if `sample'==1 & d_anyatfirstobs==0   & `cohortvar'==`cohort'
	qui `reg'
	qui margins `timevar'#`cat'
	marginsplot, `opt_marginsplot'  `xla' `xlarotate' title("Crude Data, by age of first onset (`cohortlabel')") legend(order(`labellist')) note("Sample: `samplelabel' | Controls: `ctrls' (none)" "Model: `reg'")  name(g`cat'_`cohort', replace)  // by(agegrpmin5) // 
	gr export 	"$outpath/fig/main/g_by`timevar'-`cat'_`sample'_`y'_`cohort'.jpg", replace quality(100)
}
	pause
		restore 
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
	rename countatfirstobs c
	sts graph if agegrpmin5==50, survival by(c) legend(pos(6) rows(3))

	
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


	/** histogram of duration in each health state **
		gen 	myvar = d_count if inrange(age,55,56)
		bys ID: egen countat55to56 = max(myvar)
		drop myvar
	hist duration_uncens if inrange(age,57,65), by(countat55to56)
	+
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

	

/*** +++++++++++++++++++ raw mean and se by age-group (by category t) +++++++++++++++++++ ***
loc y 		"d_count"
loc ylist	"pubpenr d_any d_count d_count_index" // 
loc t 		"male"
loc sample 		"sfullsample" // copy these lines if a specific subsample shall apply to specific plot
	loc slabel: variable label `sample'
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
 xla(`agethreshold'(5) 85) xsc(r(`agethreshold' 85)) ytitle("N observations", axis(2)) xline(70, lcolor(gray) lwidth(vthin)) note("`slabel'") ///  /*uncomment for age-group graph*/ ///
/// yscale(range(0 2000) axis(2)) /// /*adjust scale of 2nd axis*/ 
/*leave this line empty*/
gr export 	"$outpath/fig/main/g_crude_byagegrp-male_`y'.jpg", replace `jpghighquality'
restore	
}
pause
STOP 
*/	


		