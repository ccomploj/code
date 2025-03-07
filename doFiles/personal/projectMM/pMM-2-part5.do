pause on
pause off
log close _all 	/*closes all open log files*/
clear all		/*clears all data in memory*/


***choose data***
loc data 		"HRS"
// loc datalist 	"SHARE ELSA" // HRS
// foreach data of local datalist{ 


***define folder locations***
**basic paths if no user specified**
loc cv ""
loc github_p5subdiseases "https://raw.githubusercontent.com/ccomploj/code/main/doFiles/personal/projectMM/pMM-2-part5-subDiseases.do" // on all devices use github link

**flexible to user**
if "`c(username)'" == "P307344" { // UWP server
loc cv 		"X:/My Documents/XdrvData/`data'/"
}
else {
loc	cv 		"C:/Users/`c(username)'/Documents/RUG/`data'/"
loc github_p5subdiseases "C:/Users/`c(username)'/Documents/GitHub/code/doFiles/personal/projectMM/pMM-2-part5-subDiseases.do" // on my device use offline file
}
loc h_data 		"`cv'`data'data/harmon/" 		  // harmonized data folder location
// loc out 		"`cv'`data'output/"				  // output location (if different)
cd 				"`cv'"
pwd

*** read data ***
use 			"`h_data'/H_`data'_panel.dta", replace

***define dataset-specific locals***
/*Notes: -agethreshold- is the age-eligibility threshold of the survey. -wavelast- refers to the last survey wave

** IMPORTANT: MUST DROP IRRELEVANT WAVES/TIME PERIODS AT THE *BEGINNING* OF THIS DO FILE (in this section) IF NOT USED, OTHERWISE ALL THE CODE USING inw_first (i.e. first year observed in the survey) etc. WILL BE INCORRECT (and subsequent code might also be incorrect if drop additional info from the sample later) **
** hence choose correct wavefirst and wavelast
inw_first is very important, will be used in all the timeing variables and censoring, so need to make sure early on that inw_first is generated after dropping the irrelevant time periods (otherwise, one may be classified as having inw_first=1 when the first data we have in w3)

*/
if "`data'"=="SHARE" {
loc agethreshold 	"50" // select survey-specific lower age threshold (needed for categorical variable generation)
loc wavefirst 		"1"
loc wavelast 		"8"  // select survey-specific last wave
loc ptestname 		"eurod" // psychological test
loc pthreshold		"4"
gen cohortselect = (hacohort==1|hacohort==2) // will be added to selected sample later below
drop if wave==3 // is not really a time period, there are no regular variables for this wave
drop if countryID=="GR" /* imprecise */
}
if "`data'"=="ELSA" {
loc agethreshold 	"50"    
loc wavefirst 		"1"
loc wavelast 		"9" 	
loc ptestname 		"cesdr" 
loc pthreshold		"3"
gen cohortselect = (hacohort==1) // hacohort=1 is different in ELSA compared to SHARE and HRS
}
if "`data'"=="HRS" {
loc agethreshold 	"51" 
loc wavefirst 		"3"
loc wavelast 		"13" // only 13 because cognition measures for 2018 and after are not yet imputed in v2
loc ptestname 		"cesdr" 
loc pthreshold		"3"
gen cohortselect = (hacohort<=5) // will be added to selected sample later below
	keep if wave>=`wavefirst' & wave<=`wavelast' // cognitive measures not always available 	
**# Bookmark #1 but should i not add cohortselection already in the full sample?
	keep if cohortselect==1
}	

**# IMPORTANT: Drop first all age-inelig. *observations* ***
drop if age<`agethreshold' // do not consider observations below the age-eligiblility threshold in any analysis or data construction (could alternatively also use interview weights instead for this, or recode age as missing in these periods to make them ineligible)
	* // drop if mi(age) // remove missing age points altogether (do not do this yet - the panel structure in the data is necessary to construct variables correctly, hence if someone is missing between waves or they did not respond to some variables, that is important information)
	* // drop if agemin<`agethreshold'	// remove *all* responses across time from younger spouses of age-elig individuals. No. I keep them, but only from the moment they become age-eligible 
	
	
** participation frequency/timing **
* note: all inw* columns should be next to each other in dataset (i.e. not an irrelevant inw3lh in between that should not be used) *
ds 		inw* // make sure inw1-inw2-...-inw8 (in this order) only includes the "real" waves (e.g. not inw3lh)
egen 	in_wtot  = rowtotal(inw`wavefirst'-inw`wavelast')				// counts # of periods ID present
egen 	in_wmiss = anycount(inw`wavefirst'-inw`wavelast'), values(0) 	// counts # of periods ID *not* present
tab 	in_wtot in_wmiss 
la var 	in_wtot 	"# of waves participated"
la var  in_wmiss 	"# of waves missing"
*bro ID wave inwt inw* // check correct generation
	sum inw* if in_wtot == 0 // selected waves should all be 0 here, because inw_tot
	tab in_wtot in_wt
**# IMPORTANT: Drop individuals only present in excluded waves
	drop if in_wtot == 0 // if e.g. only waves 3-13 are used, then individuals with inw_tot=0 were present only in 14-15 or in 1-2 which were excluded from the participation count	(make 100% sure that that in_wtot was generated correctly first for each country's dataset) (note: their age will be missing in all other time periods, so these individuals will be dropped later when dropping all observations with missing age) 
drop 	inw*


***log entire file***
log using 	"`h_data'/logdo`data'-2-harmonPart5.txt", text replace name(logDofile) // ends w/ -log close logDofile- || in dataoutput location	



	
***************************************************************************************************
*Part 5*: Generate study-specific variables while in 'long' format 
**note: recode/relabel/rename variables from dataset and generate new variables**
***************************************************************************************************

*** birth and death year ***
la var 		rabyear "year of birth"
la var 		radyear "year of death"

** ever dead **
gen 	dead = (iwstatr==5|iwstatr==6) if iwstatr<. 
bys ID: egen everdead = max(dead) // =1 if ID ever dies | note: if not all waves are used in the dataset, make sure they are removed *before*, otherwise this variable will be wrongly constructed
la var 	everdead "ever dies during followup"
** death year **
	// clonevar radyear2 = radyear 
	// replace  radyear2=0 if mi(radyear2) // not dead people will have missing radyear
egen 	radagegrp = cut(radage),    at (50,70,80,120)
replace radagegrp = 0 if everdead==0
la de 	radagegrpl 	0 "never dead" 50  "died at 50-69" 70 "died at 70-80" 80 "died at 80+"    
la val 	radagegrp radagegrpl
la var 	radagegrp "age at death group"
tab 	radage radagegrp

** birth-cohort (birthyear) groups **
egen 	rabyeargrp10 = cut(rabyear), at(1850,1900, 1910, 1920, 1930, 1940, 1950, 1960, 1970, 1980, 2000)
la var  rabyeargrp10 "cohort group (10-year)"
tab  	rabyear rabyeargrp10, m

*** age and age-groups (choice of definition depends on survey sampling eligibility) ***
bys ID: egen agemin=min(age) 			/*age at first response across years*/ 
bys ID: egen agemax=max(age) 			/*age at last  response across years*/ 
la var 		 agemin "age when first observed"
// clonevar 	 ageatfirstobs = agemin 	// same var, only two names for it
egen 		agegrp10 	= cut(age),    at (`agethreshold',60,70,80,120) 	
egen 		agegrp5 	= cut(age),    at (`agethreshold',55,60,65,70,75,80,120)
egen 		agegrpmin10	= cut(agemin), at (`agethreshold',60,70,80,120)
egen 		agegrpmin5 	= cut(agemin), at (`agethreshold',55,60,65,70,120) 
la de 		agegrp10l 	50  "ages `agethreshold'-59" 60 "ages 60-69" 70 "ages 70-79" 80 "ages 80+"
la de 	  agegrp5l 	50  "ages `agethreshold'-54" 55 "ages 55-59" 60 "ages 60-64" 65 "ages 65-69" 70 "ages 70-74" 75 "ages 75-79" 80 "ages 80+"        
la de 		agegrpminl  50  "ageatfirstobs: `agethreshold'-59" 60 "ageatfirstobs: 60-69" 70 "ageatfirstobs: 70-79" 80 "ageatfirstobs: 80+"       
la de 		agegrpmin5l 50 "ageatfirstobs: `agethreshold'-54" 55 "ageatfirstobs: 55-59" 60 "ageatfirstobs: 60-64" 65 "ageatfirstobs: 65-69" 70 "ageatfirstobs: 70+"         
la val 		agegrp10 	agegrp10l   // labels value labels
la val 		agegrp5 	agegrp5l	// labels value labels
la val 		agegrpmin10 agegrpminl  // labels value labels
la val 		agegrpmin5 	agegrpmin5l // labels value labels
la var 		agegrp10	"current-age-group (10-year)"
la var 		agegrp5 	"current-age-group (5-year)"
la var 		agegrpmin10	"ageatfirstobs group (10-year)"
la var 		agegrpmin5 	"ageatfirstobs group (5-year)"
tab			age		agegrp10, m
tab			agemin 	agegrp5, m
* recode agethreshold (diff. across datasets) to same number (e.g. 51 to 50) (for files to have same name) *
// recode 		agegrp10 		(`agethreshold' = 50) 
// recode 		agegrp5 	  	(`agethreshold' = 50) 
// recode 		agegrpmin10  	(`agethreshold' = 50)  
// recode 		agegrpmin5 		(`agethreshold' = 50) 



/** check if anyone currently or ever not age-eligible for the survey **
agenotelig (who is never age-eligible to reach the survey age-threshold? - only relevant if do not drop the observations from the younger spouses of the main respondent (at the beginning of this script))
gen age_never`agethreshold' = agemax<`agethreshold'
tab age_never`agethreshold', m	
gen age_not`agethreshold' = age<`agethreshold'
tab iwstatr age_not`agethreshold' // check what iw status is assigned to these age-inelig. observations
di "`agethreshold'"
sum age*
*/



**# Bookmark #1 could add to github (and other files) (i think better not, but think again)
** use nonmissing age as indicator of being present in current wave **
gen 	in_wt = (age<.) // treat sb w/ miss. age as not in wave; missing age often matches with inw
la var 	in_wt 	"in curr. wave"
*bro ID wave inwt inw* // (note: make sure that age is indeed missing in data when nonresponse)

**inw_first (first time entry into survey - in calendar time)**
gen 		 myvar 			= time if in_wt==1 
bys ID: egen in_wfirst_yr	= min(myvar) 	// inw_first in years, not waves
bys ID: egen in_wlast_yr	= max(myvar)  	// inw_first in years, not waves (for health sequences)
drop myvar
la var 	 	 in_wfirst_yr "time first observed"
la var 	 	 in_wlast_yr  "time last observed"
tab in_wfirst_yr
li ID wave in_wfirst* time in_wt age in 1/5
*/

/**inw_first (first time entry into survey): note: if some time periods are excluded from dataset, make sure they are removed *BEFORE* generating this variable since it takes the first nonmissing time period for each individual **
gen 		 myvar 		= wave if inwt==1 
bys ID: egen inw_first	= min(myvar) 
drop 		 myvar
li ID 		 wave inw* in 1/3
sum		 	 inw_first // not all participants are ever present in survey (they always have missing age)
la var 	 	 inw_first "wave first observed"
tab 	 	 inw_first wave,m 
*/

/**time since first observed (/since survey entry)**
gen 	timesincefirstobs 	= time - inw_first_yr if time >= inw_first_yr & inwt==1 // need if-condition bc time never missing
gen 	followup_iwyr 		= age  - ageatfirstobs // make sure is never negative (i.e. first obs. after min.age) 
gen 	followupmax   		= inw_last_yr - inw_first_yr // based on ind.level inw, so correct (but not on iwyr)	
la var 	timesincefirstobs 	"years since first observed" 
la var 	followup_iwyr		"years since first observed (using iwyr)"
la var  followupmax   		"max. followup in years"
*bys ID: egen followupmax2 = max(followup) // should be same as followupmax
*la var  followupmax2   	"max. followup in years"
li ID wave age inw_first_yr inw_last_yr followup* timesincefirstobs in 1/20
*bro ID wave age inw_first_yr inw_last_yr followup* timesincefirstobs
*/


// A: demographics, identifiers, weights
recode 	ragender 		(1 = 1 "1.male") (2 = 0 "0.female"), gen(male)
recode 	ragender 		(1 = 1 "1.male") (2 = 0 "0.female"), gen(sex)
tab 	ragender male 	// check if generation above was correct	
la var 	male 			"male"

recode  mstatr 			(1/3 = 1 "1.married/partnered") (4/8 = 0 "0.not married"), gen(marriedr)
recode  mstatr 			(7 = 1 "1.widowed") (1/5 = 0 "0.not widowed") (8 = .), gen(widowedr) 
gen 	nevmarriedr = 	(mstatr==8) if mstatr<.
bys ID: egen nevmarried_c = max(nevmarriedr)
la var  married 		"married or partnered"	
la var 	widowedr 		"widowed"
la var 	nevmarried_c	"never married (ever)"
tab 	mstatr marriedr, m
tab 	mstatr widowed,m /*(!) note: never married is set to missing for widowed*/
tab 	mstatr nevmarriedr,m
tab 	nevmarriedr nevmarried_c /*some could have married later, but likely inaccurate responses*/

**label variables from A (if different label desired)**
la var 	raeducl 	"education"
la de 	raeducll 	1 "1.low educ" 2 "2.secondary" 3 "3.university"
la val 	raeducl raeducll
	
// B: health 
la var smokenr "curr.smoking"
// C: healthcare use and insurance
// D: cognition
// E: financial and housing Wealth
// F: income and consumption

// G: family structure
egen 	hhreshcat = cut(hhresh), at (1,2,4,20) 
la de 	hhreshcatl 1 "single HH" 2 "2-3 ppl in HH" 4 "4+ ppl in HH"
la val  hhreshcat hhreshcatl
la var  hhreshcat "# of people in HH"
tab  	hhresh hhreshcat

// H: employment history
// gen 	disabled = (lbrfr==6) if lbrfr<.
// tab 	lbrfr disabled,m
// I: retirement (and expectations)
la var retempr "retired"
// J: pension 
// 	gen 	pubpenhh 	= 	(pubpenr==1|pubpens==1)	if pubpenr<. | pubpens<. /*should use "|" due to unmarried people*/
// 		la var 	pubpenr  "receive public pension"
// 		la var 	pubpenhh "anyone in HH receives public pension"
// K: physical measures
// L: assistance and caregiving
// M: stress
// O: (end of life planning)
// P: (childhood)
// Q: Psychosocial
// 	rename 		psycher depr_selfrep /*self reported/doctor diagnosis depression*/
**validated test as indicator for depression, using cutoff score**
*gen psycher = (`ptestname'>=`pthreshold') if `ptestname'<.  /*validated test as indicator for depression*/
gen 	deprer 	= (`ptestname'>=`pthreshold') if `ptestname'<. /*named -er- even if not absorbing*/
la var 	deprer "(currently has depression)"

	*tab	depress_selfrep psycher // depress_selfrep may be strictly increasing in time
	*corr 	depress_selfrep psycher /*see if there is self-reported depression correlates well*/

// Y: Other relevant variables (e.g. from other datasets)
*gen	ageatdeath // construct ageatdeath from end-of-life version of harmonized dataset (see here https://g2aging.org/downloads) (if this is available and informative);  


sort 	ID wave
save	"`h_data'H_`data'_panel2.dta", replace 
pause


**********************************************************************************************
*Part 5.1*: Sample Selection and variables (some other Paper)
**********************************************************************************************
*sort ID wave 
*drop if mi(age) // after generating all variables, drop all missing observations
*save "`h_data'H_panel2-SOMENAME.dta", replace 

**********************************************************************************************
*Part 5.2*: Sample Selection and variables (Multimorbidity Paper)
**********************************************************************************************
use 	"`h_data'H_`data'_panel2.dta", clear // load earlier dataset 


*** disease list and durations (include external file to keep good overview here) ***
display  "`github_p5subdiseases'"
include  "`github_p5subdiseases'" // include github file

**# Bookmark #1 maybe already here i want to remove observations if dead or not repesent in survey? (just that then i cannot study attrition), othrwise can study attrition using intermediate dataset
*** drop irrelevant observations *** 
drop if mi(age) // after generating all variables, drop all missing observations

***select samples***
// full sample
count if !mi(age) // saves N into r(N)
gen		sfullsample = (!mi(age))	
la var 	sfullsample "sample: full (N=`r(N)')"

/* balanced sample 
loc 	temp 		"(inw_miss==0 | everdead==1)"	
gen 	sbalanced 	= `temp'
la var 	sbalanced 	"balanced sample `temp'"
*/

/* selected sample
loc 	temp 	"(everdead==1|inw_tot>=5) & agemin<70"
gen 	sfull5 = `temp' & !mi(age)
*la var sfull5 "`temp'"
la var 	sfull5 	"sample: selected (in5w or everdead, <70)"
// exclude the sampling cohorts that are decided to be excluded
replace sfull5 = 0 if cohortselect == 0
bys everdead: tab sfull5 inw_tot, m
tab 	sfull5 inw_tot if everdead==0 // check if generated correctly 
*/

/* selected sample 2
loc 	temp 			"sfull5 & d_anyatfirstobs==0"
gen 	sfull5healthy = `temp' if d_anyatfirstobs<. /*if d_anyatfirstobs missing, we do not know if the ID was healthy or not at baseline, hence this should be missing*/
la var 	sfull5healthy  "sample: selected + healthy-at-baseline"
la de 	sfull5healthyl 0 "has disease at baseline" 1 "has no disease at baseline"
la val 	sfull5healthy sfull5healthyl
*/
	
	*** Sample Selection (MM paper) ***
	log using 	"`h_data'/log-sampleSelection.txt", text replace name(logSampleselection)
	count 					// total
	codebook ID, compact 	// 79,420 IDs
	// tab sfullsample sfull5 // full sample vs. selected sample
	tab iwstatr wave,m		
	tab radyear in_wtot, m
	log close logSampleselection	

loc 	droplist 	"ragender" 			// drop variables no longer needed 
drop 	`droplist'	

gen 	dataset = "`data'" // add variable referring to dataset
sort 	ID wave
save	"`h_data'H_`data'_panel2-MM.dta", replace // check if appeared in correct folder!

// keep 	ID wave time male raeducl age d_count* sfullsample rabyeargrp10 ageatfirstobs countatfirstobs duration
save	"`h_data'H_`data'_panel2-MMcompact.dta", replace // check if appeared in correct folder!
	** export to CSV for R **
	*export delimited using "G:\My Drive\projects\projectMM\dataInCsv\H_`data'_g3.csv", replace // save in csv format (works only on my machine)
	



**********************************************************************************************
*++ END OF FILE ++*
log close logDofile /*logs file to specified folder if log active*/
} /*end of loop for multiple datasets*/
+++ END OF FILE +++
**********************************************************************************************



**********************************************************************************************
*Part 6*: Analysis (use separate .do file)
**********************************************************************************************
*[see separate file]*







**********************************************************************************************
***Addendum***
**********************************************************************************************
***some useful Stata shortcuts on Windows:
* CTRL + L 			: select line 
* CTRL + D 			: run selected block 
* CTRL + R 			: run entire file
* CTRL + S + Shift	: save (as)

***Stata suggestions***
* - run entire do-file at once, program using local (and if necessary global) macros 
* - use "tab" to make code easier to read.  
* - use "pauses" in your code when necessary
* - use many comments of the type /*sometext*/ after a line of code or ***sometext*** for headings
* - use forward slash "/" only for directories - this is then the same on Mac and Windows


***common errors***
* - "log file already open": use -log close log- or -log close _all-

**********************************************************************************************
*Full variable descriptions*
**********************************************************************************************

***Archive Code***
/* using if condition in d_count: 
computes the count *only* for 
	observations that have no missing diseases:
	("if d_missing<=1" allows for 1 missing value, because in SHARE kidney is not available in waves 1-5)
		|if kidney is never  available, "if d_missing==0" should be used - since kidney variable is not available
		|if kidney is always available, "if d_missing==0" should be used
		|if another key variable is only available for few periods, the same coding applies.| 
	(",missing" tells sets d_count to . instead of 0 when all variables are .) */
	
	/*check why inap**
	tab iwstatr wave
	gen inap = iwstatr==0
	gen time = wave if age<. /*age missing if not responded to wave*/
	bys ID: egen firstsurvey=min(time)
	li time firstsurvey wave age in 24/40
	replace inap=0 if 
	bys ID: egen everinap=max(inap)
	sum everinap
	+	
	*/
	
	
	/**# Bookmark #2 *** generate own self-reported first onset if first onset variable is missing *** (can move to common code using if conditions conditional on dataset)
		egen totalN = total(1) // total count of dataset 
		loc 	list "radiagheart radiagstrok radiagcancr"
		foreach var of local list {
		egen missing`var'  = total(missing(`var')) 	// Count the number of missing observations for the variable
		}		
		
		// radiag: heart
		loc var "radiagheart"		
		if 	 missing`var' == totalN {
		*sum 	radiagheart // this variable is an empty variable (always missing) if recoding as below: 
		egen 	radiagheart2 = rowmin(radiagchf radiaghrtr rafrhrtatt)  // rechrtattr not used (most recent heart attack) /* -bys ID- not helpful here*/
		bys ID: egen myvar   = min(radiagheart2) // replace with minimum value 
		replace radiagheart2 = myvar // make sure the first ever reported onset is used (relevant if rechrtattr ('most recent diagnosis') is not missing)
		drop 	myvar
		order `var'2, after(`var')
		rename `var' `var'3 // rename to a copy  
			drop 	`var'3 // or drop it instead
		}
		
		
		// radiag: stroke
		loc var "radiagstrok"	
		if 	 missing`var' == totalN {
		bys ID: egen 	radiagstrok2 = min(recstrokr) 
		order `var'2, after(`var')
		rename `var' `var'3 // rename to a copy  
			drop 	`var'3 // or drop it instead
		}		
		
		// radiag: cancr
		loc var "radiagcancr"	
		if 	 missing`var' == totalN {
		bys ID: egen 	radiagcancr2 = min(reccancr)
		order `var'2, after(`var')
		rename `var' `var'3 // rename to a copy  
			drop 	`var'3 // or drop it instead
		}		
		/*

		* this was now generated for HRS, should also work for ELSA, but other vars may be added there *  
	* there is radiagangin in HRS, how about other surveys and why was it excluded? * 	
	