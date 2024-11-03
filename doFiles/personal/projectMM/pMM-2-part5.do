pause on
pause off
log close _all 	/*closes all open log files*/
clear all		/*clears all data in memory*/

**# Bookmark #1 should recode onsetage to only be nonmissing if full disease count is not missing (otherwise may not capture true onset)
//  tab d_any d_miss,m // use this to check


***choose data***
loc data 		"HRS"
loc datalist 	"SHARE ELSA" // HRS
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
loc out 		"`cv'`data'output/"				  // output folder location
cd 				"`cv'"
pwd

*** read data ***
use 			"`h_data'/H_`data'_panel.dta", replace

***define dataset-specific locals***
** IMPORTANT: MUST DROP IRRELEVANT WAVES AT THE *BEGINNING* OF THIS DO FILE IF NOT USED, OTHERWISE ALL THE CODE USING inw_first etc. WILL BE INCORRECT (and subsequent code might also be incorrect if drop additional info from the sample later) **

if "`data'"=="SHARE" {
loc agethreshold 	"50" // select survey-specific lower age threshold
loc upperthreshold	"85" // select survey-specific upper age threshold	
loc wavelast 		"8"  // select survey-specific last wave
loc ptestname 		"eurod" // psychological test
loc pthreshold		"4"
gen cohortselection = (hacohort==1|hacohort==2) // will be added to selected sample later below
drop if wave==3 // is not really a time period, there are no regular variables for this wave
drop if countryID=="GR" /*relatively imprecise survey*/
}
if "`data'"=="ELSA" {
loc agethreshold 	"50" // select survey-specific lower age threshold
loc upperthreshold	"85" // select survey-specific upper age threshold	
loc wavelast 		"9" 	// select survey-specific last wave
loc ptestname 		"cesdr" // psychological test
loc pthreshold		"3"
gen cohortselection = (hacohort==1) // hacohort=1 is different in ELSA compared to SHARE and HRS
}
if "`data'"=="HRS" {
loc agethreshold 	"51" // select survey-specific lower age threshold
loc upperthreshold	"85" // select survey-specific upper age threshold	
**# Bookmark #1 note: I added the last waves 14 and 15 again, why did i remove them previously?
loc wavelast 		"15" // select survey-specific last wave
loc ptestname 		"cesdr" // psychological test
loc pthreshold		"3"
**# Bookmark #1 but should i not add cohortselection already in the full sample?
gen cohortselection = (hacohort<=5) // will be added to selected sample later below
	keep if wave>=3 & wave<=`wavelast' // cognitive measures not always available 	
	** should select the cohorts here already **
}	


	*** first of all drop age-inelig. *observations ***
	drop if age<`agethreshold' // think carefully, is this the correct time to drop these observations? Or just recode them to missing instead (could also use interview weights instead for this.)
	*drop if mi(age) // remove missing age points altogether (do not want to have a first onset age for these) (this i moved later, since when creating the variables I want a "full" panel to have a better overview)
// 	drop if agemin<`agethreshold'	// remove younger spouses of age-elig individuals. But how to drop them? Drop just the observations or also all the younger people across all waves? For now, I drop the observations and keep them in if they then become age-eligible. Ideally, I should recode them

***log entire file***
log using 	"`out'/logdo`data'-2-harmonPart5.txt", text replace name(logDofile) // ends w/ -log close logDofile- || in dataoutput location	
	
***************************************************************************************************
*Part 5*: Generate study-specific variables while in 'long' format 
**note: recode/relabel/rename variables from dataset and generate new variables**
***************************************************************************************************
*** relabel main variables *** 
la var rabyear "year of birth"
la var radyear "year of death"


***rename key variables ***
rename  ageyr 	age 
la var  age 	"age"
gen 	inwt = (age<.) // treat sb w/ miss. age as not in wave; missing age often matches with inw
la var 	inwt "in curr. wave"
*tab 	inwt inw1 if wave==1

* note: if not all waves are used in the dataset, make sure they are removed *before* generating the below*
gen 	dead = (iwstatr==5|iwstatr==6) if iwstatr<. 
bys ID: egen everdead = max(dead) // =1 if ID ever dies 
la var 	everdead "ever dies during followup"

*** vars related to survey participation ***
** participation frequency/timing **
**# Bookmark #1 check this version in github, or should i add it there even?
* note: all inw* columns should be next to each other in dataset (i.e. not inw3lh in between that should not be used) *
ds 		inw* // make sure inw1-inw2-...-inw8 (in this order) only includes the "real" waves (e.g. not inw3lh)
egen 	inw_tot  = rowtotal(inw1-inw`wavelast')				// counts # of periods ID present
egen 	inw_miss = anycount(inw1-inw`wavelast'), values(0) 	// counts # of periods ID *not* present
tab 	inw_tot inw_miss 
la var 	inw_tot 	"# of waves participated"
la var  inw_miss 	"# of waves missing"

**ages, agegroups (choice of definition depends on survey sampling eligibility)**
// age first/last observed
bys ID: egen agemin=min(age) 			/*age at first response across years*/ 
bys ID: egen agemax=max(age) 			/*age at last  response across years*/ 
la var 		 agemin "age when first observed"
clonevar 	 ageatfirstobs = agemin // same var, only two names for it

**define agegroups (choice of definition depends on survey sampling eligibility)**
egen 		agegrp10 	= cut(age),    at (`agethreshold',60,70,80,120) 	
egen 		agegrp5 	= cut(age),    at (`agethreshold',55,60,65,70,75,80,120)
egen 		agegrpmin10	= cut(agemin), at (`agethreshold',60,70,80,120)
egen 		agegrpmin5 	= cut(agemin), at (`agethreshold',55,60,65,70,120) 
// recode agethreshold (diff. across datasets) to same number (for file saving) 
recode 		agegrp10 		(`agethreshold' = 50) 
recode 		agegrp5 	  	(`agethreshold' = 50) 
recode 		agegrpmin10  	(`agethreshold' = 50)  
recode 		agegrpmin5 		(`agethreshold' = 50) 
la de 		agegrp10l 	50  "ages `agethreshold'-59" 60 "ages 60-69" 70 "ages 70-79" 80 "ages 80+"      
la de 		agegrp5l 	50  "ages `agethreshold'-54" 55 "ages 55-59" 60 "ages 60-64" 65 "ages 65-69" 70 "ages 70-74" 75 "ages 75-79" 80 "ages 80+"        
la de 		agegrpminl  50  "ageatfirstobs: `agethreshold'-59" 60 "ageatfirstobs: 60-69" 70 "ageatfirstobs: 70-79" 80 "ageatfirstobs: 80+"       
la de 		agegrpmin5l 50 "ageatfirstobs: `agethreshold'-54" 55 "ageatfirstobs: 55-59" 60 "ageatfirstobs: 60-64" 65 "ageatfirstobs: 65-69" 70 "ageatfirstobs: 70+" // 75 "ageatfirstobs: 75-79" 80 "ageatfirstobs: 80+"       
la val 		agegrp10 	agegrp10l   // labels value labels
la val 		agegrp5 	agegrp5l	// labels value labels
la val 		agegrpmin10 agegrpminl  // labels value labels
la val 		agegrpmin5 	agegrpmin5l // labels value labels
la var 		agegrp10	"current-age group (10-year)"
la var 		agegrp5 	"current-age group (5-year)"
la var 		agegrpmin10	"ageatfirstobs group (10-year)"
la var 		agegrpmin5 	"ageatfirstobs group (5-year)"
tab			age		agegrp10, m
tab			agemin 	agegrp5, m

** define cohort (birthyear) groups **
egen rabyeargrp10 = cut(rabyear), at(1850,1910,1920,1930, 1940, 1950, 1960, 1970, 1980, 2000)
tab  rabyear rabyeargrp10	

*** death year ***
	// clonevar radyear2 = radyear 
	// replace  radyear2=0 if mi(radyear2) // not dead people will have 
egen 	radagegrp = cut(radage),    at (50,65,80,120)
replace radagegrp = 0 if everdead==0
la de 	radagegrpl 	0 "never dead" 50  "died at 50-64" 65 "died at 65-80" 80 "died at 80+"    
la val 	radagegrp radagegrpl
*tab radage radcohort

// agenotelig (who is never age-eligible to reach the survey age-threshold? - only relevant if do not drop the observations from the younger spouses of the main respondent (at the beginning of this script))
gen age_never`agethreshold' = agemax<`agethreshold'
tab age_never`agethreshold', m	
gen age_not`agethreshold' = age<`agethreshold'
tab iwstatr age_not`agethreshold' // check what iw status is assigned to these age-inelig. observations


**inw_first (entry time into survey)**
* note: if not all waves are used in the dataset, make sure they are removed *before* generating the below*
gen 		 myvar 		= wave if inwt==1 
bys ID: egen inw_first	= min(myvar) 
drop 		 myvar
li ID 		 wave inw* in 1/3
count
sum		 	inw_first // not all participants are ever present in survey (they always have missing age)
la var 	 	inw_first "wave first observed"
tab 	 	inw_first wave,m 

**inw_first (entry into survey - in calendar time)**
gen 		 myvar 			= time if inwt==1 
bys ID: egen inw_first_yr	= min(myvar) 	// inw_first in years, not waves
bys ID: egen inw_last_yr	= max(myvar)  	// inw_first in years, not waves (for health sequences)
drop myvar
li ID wave inw_first* time inwt age in 1/5
tab inw_first_yr

**time since first observed (/since survey entry)**
gen 	followup 	  = time - inw_first_yr if time >= inw_first_yr & inwt==1 // need if-condition bc time never missing
gen 	followup_iwyr = age  - ageatfirstobs // make sure is never negative (i.e. first obs. after min.age) 
gen 	followupmax   = inw_last_yr - inw_first_yr // based on ind.level inw, so correct (but not on iwyr)	
la var 	followup 		"years since first observed" 
la var 	followup_iwyr	"years since first observed (using iwyr)"
la var  followupmax   	"max. followup in years"
*bys ID: egen followupmax2 = max(followup) // should be same as followupmax
*la var  followupmax2   	"max. followup in years"

**timesincefirstobs: in years (using interview year as time)** 
gen 	timesincefirstobs = followup // obsolete, use followup from now on
la var 	timesincefirstobs 	"time since first observed"
li ID wave age inw_first_yr inw_last_yr followup* timesincefirstobs in 1/20
*bro ID wave age inw_first_yr inw_last_yr followup* timesincefirstobs

// su 		iwyr, meanonly
// loc 	timemin= r(min)	// take first survey year as starting time for 'time' 
// di 		`timemin' 
// gen 			time_sincefirstwave = iwyr - `timemin' // interview time w.r.t. first survey time
// gen 		 	myvar 			= time_sincefirstwave if inwt==1 
// gen 			timesincefirstobs = time_sincefirstwave - inw_first_yr if wave>=inw_first // time from first obs to iwyr
//				
li 		ID wave time inwt inw_first* timesincefirstobs  in 300/310
*tab 	inw_first inw_first_time,m // sometimes, first iwyr is different from first wave
sum 	timesincefirstobs
tab 	iwyr timesincefirstobs
tab 	time timesincefirstobs 
tab 	inw_first timesincefirstobs


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
tab 	nevmarriedr nevmarried_c /*few people could have married, most likely though inaccurate responses*/




**label variables from A (if different label desired)**
la var 	raeducl 	"education"
la de 	raeducll 	1 "1.low educ" 2 "2.secondary" 3 "3.university"
la val 	raeducl raeducll
	
loc 	droplist 	"ragender" 			// drop variables not needed
drop 	`droplist'
// B: health 
// C: healthcare use and insurance
// D: cognition
// E: financial and housing Wealth
// F: income and consumption

// G: family structure
egen 	hhreshhcat = cut(hhreshh), at (1,2,4,20) 
tab  	hhreshh hhreshhcat
la de 	hhreshhcatl 1 "single HH" 2 "2-3 ppl in HH" 4 "4+ ppl in HH"
la val  hhreshhcat hhreshhcatl

la var  hhreshhcat "# of people in HH"
// H: employment history
// gen 	disabled = (lbrfr==6) if lbrfr<.
// tab 	lbrfr disabled,m

la var 	retempr "retired"
// I: retirement (and expectations)
// J: pension 
	gen 	pubpenhh 	= 	(pubpenr==1|pubpens==1)	if pubpenr<. | pubpens<. /*should use "|" due to unmarried people*/
		la var 	pubpenr  "receive public pension"
		la var 	pubpenhh "anyone in HH receives public pension"
// K: physical measures
// L: assistance and caregiving
// M: stress
// O: (end of life planning)
// P: (childhood)
// Q: Psychosocial
	rename 		psycher depr_selfrep /*self reported/doctor diagnosis depression*/
**# Bookmark #1
	**validated test as indicator for depression**
	*gen psycher = (`ptestname'>=`pthreshold') if `ptestname'<.  /*validated test as indicator for depression*/
	gen deprer 	= (`ptestname'>=`pthreshold') if `ptestname'<. /*named -er- even if not absorbing*/
	la var deprer "(currently has depression)"

*tab	depress_selfrep psycher if wave==2 // depress_selfrep may be strictly increasing in time
*corr 	depress_selfrep psycher if wave==2 /*about 0.25 in SHARE in the second wave*/

// Y: Other relevant variables (e.g. from other datasets)
*gen	ageatdeath // construct ageatdeath from end-of-life version of harmonized dataset (see here https://g2aging.org/downloads) (if this is available and informative);  

*** other labels *** 
la var smokenr "curr.smoking"

	*****************
	*** Attrition *** 
	*****************
	tab 	iwstatr
// 	gen 	iwstatr0 = (iwstatr==0) if iwstatr<.
// 	gen 	iwstatr4 = (iwstatr==4) if iwstatr<.
// 	gen 	iwstatr9 = (iwstatr==9) if iwstatr<.
// 	bys ID: egen everiwstatr0 = max(iwstatr0) 
// 	bys ID: egen everiwstatr4 = max(iwstatr4) 
// 	bys ID: egen everiwstatr9 = max(iwstatr9) 
// 	la var 	everiwstatr0 "ever inap."
// 	la var 	everiwstatr4 "ever nr \& alive"
// 	la var 	everiwstatr4 "ever nr, dk if alive"
// 	tab everdead if wave==1
// 	tab everdead iwstatr,m col
// 	sum iwstatr0 iwstatr4 iwstatr9 dead
// 	sum everiwstatr0 everiwstatr4 everiwstatr9 everdead	
// 	tab iwstatr wave,m	
// 	tab inw_tot everdead,m
	/*loc ctrls "male i.raeducl age"
	eststo attr0: qui reg everiwstatr0 `ctrls'
	eststo attr4: qui reg everiwstatr4 `ctrls'
	eststo attr9: qui reg everiwstatr9 `ctrls'
	esttab attr*, label
	eststo clear
	*/

sort 	ID wave
save	"`h_data'H_`data'_panel2.dta", replace 
pause


**********************************************************************************************
*Part 5.1*: Sample Selection and variables (some Paper)
**********************************************************************************************
*sort ID wave 
*save "`h_data'H_panel2-SOMENAME.dta", replace 

**********************************************************************************************
*Part 5.2*: Sample Selection and variables (Multimorbidity Paper)
**********************************************************************************************
use 	"`h_data'H_`data'_panel2.dta", clear // load earlier dataset 


***********************************
*** diseases list and durations ***
***********************************
include  "`github_p5subdiseases'" // include github file

	
***select samples***
**# ageinelig individuals ( already dropped at beginning of file)
	// drop if mi(age) // these observations are not used anyway, do not want to report any information about these individuals !! do NOT drop! sb might just be dead // i drop these observations later
	drop if inw_tot == 0 // if e.g. only waves 3-13 are used, then inw_tot=0 if sb was present in 14-15 only (check that inw_was generated correctly first for each country's dataset) ( i should dro these anyway (their age will be missing in all these time periods, so maybe I should not drop these))

	
	

**# Bookmark #1 maybe already here i want to remove observations if dead or not repesent in survey? (just that then i cannot study attrition)
// full sample
count if !mi(age) // saves N into r(N)
gen		sfullsample = ( !mi(age) )	
la var 	sfullsample "sample: full (N=`r(N)')"

/* balanced sample 
loc 	temp 		"(inw_miss==0 | everdead==1)"	
gen 	sbalanced 	= `temp'
la var 	sbalanced 	"balanced sample `temp'"
*/

// selected sample
loc 	temp 	"(everdead==1|inw_tot>=5) & agemin<70"
gen 	sfull5 = `temp' & !mi(age)
*la var sfull5 "`temp'"
la var 	sfull5 	"sample: selected (in5w or everdead, <70)"
tab 	sfull5 inw_tot if everdead==0 // check if generated correctly 
**# Bookmark #1
	// exclude the sampling cohorts that are decided to be excluded
	replace sfull5 = 0 if cohortselection == 0
	bys everdead: tab sfull5 inw_tot, m

loc 	temp 			"sfull5 & d_anyatfirstobs==0"
// gen 	sfull5healthy = `temp' if d_anyatfirstobs<. /*if d_anyatfirstobs missing, we do not know if the ID was healthy or not at baseline, hence this should be missing*/
// la var 	sfull5healthy  "sample: selected + healthy-at-baseline"
// la de 	sfull5healthyl 0 "has disease at baseline" 1 "has no disease at baseline"
// la val 	sfull5healthy sfull5healthyl

	**# Bookmark #2 *** generate own self-reported first onset if first onset variable is missing *** (can move to common code using if conditions conditional on dataset)
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
		
		*++
		* this was now generated for HRS, should also work for ELSA, but other vars may be added there *  
		* there is radiagangin in HRS, how about other surveys and why was it excluded? * 	

*****************************
*** Sample Selection (MM) ***
*****************************
log using 	"`out'logs/log-sampleSelection.txt", text replace name(logSampleselection)
count 					// total
count 	if wave == inw_first // how many in first wave?
codebook ID, compact 	// 79,420 IDs
tab sfullsample sfull5 // full sample vs. selected sample
tab iwstatr wave,m		
tab radyear inw_tot, m
log close logSampleselection
	

gen 	dataset = "`data'" // add variable referring to dataset
sort 	ID wave
save	"`h_data'H_`data'_panel2-MM.dta", replace // check if appeared in correct folder!
*pause 

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
	

	
	