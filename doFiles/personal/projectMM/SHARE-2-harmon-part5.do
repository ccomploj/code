pause on
pause off
log close _all 	/*closes all open log files*/
clear all		/*clears all data in memory*/



***define folder locations***
loc data 		"SHARE" // SHARE | ELSA (note for ELSA part5-subDiseases may be incorrect because other diseases are present)
loc datalist 	"SHARE HRS ELSA"
*foreach data of local datalist{


**flexible to OS**
if "`c(username)'" == "P307344" { // UWP server
loc cv 		"X:/My Documents/XdrvData/`data'/"
loc outloc 	"\\Client\C$\Users\User\Documents\GitHub\2-projectMM-`data'\" 
	*gl  outpath "\\Client\C$\Users\User\Documents\GitHub\2-projectMM-`data'\files"
	*gl  outpath "`cv'files"
}
else {
loc	cv 		"G:/My Drive/drvData/`data'/"
loc	outloc 	"C:/Users/User/Documents/GitHub/2-projectMM-`data'" 	
	*gl 	outpath "C:/Users/User/Documents/GitHub/2-projectMM-`data'/files" 	
}

loc h_data 		"`cv'`data'data/harmon/" 		  // harmonized data folder location
loc out 		"`cv'`data'output/"				  // output folder location

cd 				"`cv'"
pwd

use 			"`h_data'/H_`data'_panel.dta", replace



	***log entire file***
	*log using 	"`h_data'logdoSHARE-2-harmonPart5.txt", text replace name(logDofile) // ends w/ -log close logDofile- || in folder location  
	log using 	"`out'/logdoSHARE-2-harmonPart5.txt", text replace name(logDofile) // ends w/ -log close logDofile- || in dataoutput location
	*log using 	"G:/My Drive/projects/projectMultimorbidity/outfiles/logs/logdoSHARE-2-harmonPart5.txt", text replace name(logDofile) // ends w/ -log close logDofile- || in specific location 
	
	**flexible to dataset**
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
**# Bookmark #2 dropping this is already for MM project. Ideally would move this below after saving intermediate dataset (can also move entire loop)
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
	}	
	
	
****************************************************************************************************
*Part 5*: Generate study-specific variables while in 'long' format 
**note: recode/relabel/rename variables from dataset and generate new variables**
****************************************************************************************************


***rename key variables ***
rename  ageyr age 

***vars related to survey participation***
**participation frequency/timing**
*!caution!: all vars/columns inw should be next to each other in dataset 
egen 	inw_tot  = rowtotal(inw1-inw`wavelast')				// counts # of periods ID present
egen 	inw_miss = anycount(inw1-inw`wavelast'), values(0) 	// counts # of periods ID *not* present
tab 	inw_tot inw_miss 

**in current wave**
gen 	inwt = (age<.) // treat sb w/ miss. age as not in wave; missing age often matches with inw
la var 	inwt "in curr. wave"
*tab 	inwt inw1 if wave==1

**inw_first (entry into survey)**
gen 		 myvar 		= wave if inwt==1 
bys ID: egen inw_first	= min(myvar) 
drop 		 myvar

li ID 		 wave inw* in 1/3
*sum		 inw_first // not all participants are ever present in survey
la var 		 inw_first "wave first observed"
tab 		 inw_first wave,m 

**time since first observed (entry into survey)**
*note: MUST generate BEFORE gap appears (e.g. before deleting wave 3 (Life-history) from the panel)*
	/*timesincefirstobs: in waves*
	bys ID: gen timesincefirstobs = _n -1  				 if wave>=inw_first	
	replace timesincefirstobs 	= timesincefirstobs - inw_first + 1 /*subtract time first observed*/	
	*/
	/*timesincefirstobs: in years*
	su 		time, meanonly
	local 	timemin= r(min)
	gen 	time_sincebaseline = time - `timemin' // use first survey wave	
		gen 		 myvar 			= time_sincebaseline if inwt==1 
		bys ID: egen inw_firstyr	= min(myvar) 
		drop 		 myvar
		tab inw_first inw_firstyr,m	
	gen timesincefirstobs = time_sincebaseline - inw_firstyr  if wave>=inw_first
	*/
**timesincefirstobs: in years (using interview year as time)** 
su 		iwyr, meanonly
loc 	timemin= r(min)	// take first survey year as starting time for 'time' 
di 		`timemin' 
gen 			time_sincefirstwave = iwyr - `timemin' // interview time w.r.t. first survey time
gen 		 	myvar 			= time_sincefirstwave if inwt==1 
bys ID: egen 	inw_first_yr	= min(myvar) 	// inw_first in years, not waves
gen 			timesincefirstobs = time_sincefirstwave - inw_first_yr if wave>=inw_first // time from first obs to iwyr
li 		ID wave time inwt inw_first* time_sincefirstwave timesincefirstobs  in 300/310
drop 	myvar // time_sincefirstwave 
*tab 	inw_first inw_first_yr,m // sometimes, first iwyr is different from first wave
sum 	timesincefirstobs
la var 	timesincefirstobs 	"time since first observed"
tab 	iwyr timesincefirstobs
tab 	time timesincefirstobs 
tab 	inw_first timesincefirstobs



// A: demographics, identifiers, weights
recode 	ragender 		(1 = 1 "1.male") (2 = 0 "0.female"), gen(male)
la var 	male 			"male"
tab 	ragender male 	// check if generation above was correct	

recode  mstatr 			(1/3 = 1 "1.married/partnered") (4/8 = 0 "0.not married"), gen(marriedr)
recode  mstatr 			(7 = 1 "1.widowed") (1/5 = 0 "0.not widowed") (8 = .), gen(widowedr) 
gen 	nevmarriedr = 	(mstatr==8) if mstatr<.
bys ID: egen nevmarried_c = max(nevmarriedr)
la var  married 		"married or partnered"	
la var 	nevmarried_c	"never married (ever)"
tab 	mstatr marriedr, m
tab 	mstatr widowed,m /*(!) note: never married is set to missing for widowed*/
tab 	mstatr nevmarriedr,m
tab 	nevmarriedr nevmarried_c /*few people could have married, most likely though inaccurate responses*/

**ages, cohorts (choice of definition depends on survey sampling eligibility)**
// age first/last observed
bys ID: egen agemin=min(age) 			/*age at first response across years*/ 
bys ID: egen agemax=max(age) 			/*age at last  response across years*/ 
la var 		 agemin "age when first observed"
gen 		 ageatfirstobs = agemin

**define cohorts (choice of definition depends on survey sampling eligibility)**
egen 		cohort 		= cut(age)	 , at (`agethreshold',60,70,80,120) 	
egen 		cohortmin 	= cut(agemin), at (`agethreshold',60,70,80,120)
egen 		cohortmin5 	= cut(agemin), at (`agethreshold',55,60,65,70,75,80,120)
tab 		cohort
la de 		cohortl `agethreshold' "`agethreshold'-59" 60 "60-69" 70 "70-79" 80 "80+"       
la de 		cohortl5 `agethreshold' "`agethreshold'-54" 55 "55-59" 60 "60-64" 65 "65-69" 70 "70-74" 75 "75-79" 80 "80+"       
la val 		cohort 		cohortl // labels value labels
la val 		cohortmin 	cohortl // labels value labels
la val 		cohortmin5 	cohortl // labels value labels
tab			age		cohort, m
tab			agemin 	cohort, m


// agenotelig 
gen age_never`agethreshold'=agemax<`agethreshold'
tab age_never`agethreshold' ,m	

gen age_not`agethreshold'=age<`agethreshold'
tab iwstatr age_not`agethreshold'


**label variables from A (if different label desired)**
la var  age 		"age at interview"
la var 	raeducl 	"r educ"
la de 	raeducll 	1 "1.less than upper secondary" 2 "2.upper secondary or vocational" 3 "3.tertiary education"
la val 	raeducl raeducll
	
loc 	droplist 	"ragender" 			// drop variables not needed
drop 	`droplist'
// B: health 
rename 	hiper osteoer
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
rename 	psycher depress_selfrep /*self reported/doctor diagnosis depression*/

gen 	psycher = (`ptestname'>=`pthreshold') if `ptestname'<.  /*validated test as indicator for depression*/

tab	 	depress_selfrep psycher if wave==2 // depress_selfrep may be strictly increasing in time
corr 	depress_selfrep psycher if wave==2 /*about 0.25 in SHARE in the second wave*/

// Y: Other relevant variables (e.g. from other datasets)
*gen	ageatdeath // construct ageatdeath from end-of-life version of harmonized dataset (see here https://g2aging.org/downloads) (if this is available and informative);  



*****************
*** Attrition *** 
*****************
*use	"./SHAREdata/harmon/H_panel2.dta", replace 
tab 	iwstatr
gen 	iwstatr0 = (iwstatr==0) if iwstatr<.
gen 	iwstatr4 = (iwstatr==4) if iwstatr<.
gen 	iwstatr9 = (iwstatr==9) if iwstatr<.
gen 	dead = (iwstatr==5|iwstatr==6) if iwstatr<. 
bys ID: egen everdead = max(dead) // =1 if ID ever dies 
bys ID: egen everiwstatr0 = max(iwstatr0) 
bys ID: egen everiwstatr4 = max(iwstatr4) 
bys ID: egen everiwstatr9 = max(iwstatr9) 
la var 	everiwstatr0 "ever inap."
la var 	everiwstatr4 "ever nr \& alive"
la var 	everiwstatr4 "ever nr, dk if alive"
tab everdead if wave==1
tab everdead iwstatr,m col
sum iwstatr0 iwstatr4 iwstatr9 dead
sum everiwstatr0 everiwstatr4 everiwstatr9 everdead	
tab iwstatr wave,m	
tab inw_tot everdead,m
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


****************************************************************************************************
*Part 5.1*: Sample Selection and variables (some Paper)
****************************************************************************************************
*sort ID wave 
*save "`h_data'H_panel2-SOMENAME.dta", replace 

****************************************************************************************************username
*Part 5.2*: Sample Selection and variables (Multimorbidity Paper)
****************************************************************************************************
use 	"`h_data'H_`data'_panel2.dta", clear // load earlier dataset 

***********************************
*** diseases list and durations ***
***********************************

*do 	"C:/Users/User/Documents/GitHub/code/doFiles/personal/projectMM-part5-subDiseases.do" // do does not include locals inside subfile
*include "C:/Users/User/Documents/GitHub/code/doFiles/personal/projectMM-part5-subDiseases.do" // "include" includes current locals into subfile
include "https://raw.githubusercontent.com/ccomploj/code/main/doFiles/personal/projectMM-part5-subDiseases.do"




*****************************
*** Sample Selection (MM) ***
*****************************
log using 	"`out'logs/log-sampleSelection.txt", text replace name(logSampleselection)
	tab hacohort inw1, 
	*tab countryID hacohort,m   		
	tab inw1 wave,m		// 30,419 IDs present in wave 1			
	tab inw_tot wave 	// 139,620 total IDs
	tab inw_tot wave if hacohort==1 & inw1==1 // 30,419 IDs also present in wave 1
	tab iwstatr inw2 if wave==2,m // check consistency: everyone with iwstat 1 is inw in that wave
	tab iwstatr wave, m 							
	tab iwstatr wave if hacohort==1 & inw1==1, m 	
	tab iwstatr inw_tot if hacohort==1,m 			
	tab iwstatr inw_tot if hacohort==1 & wave==1,m 	
	tab inw_tot radyear
	*tab inw_tot raxyear
	tab iwstatr wave,m

*** drop IDs *** 	/*choose IDs from first cohort that responded to wave 1, and [...]*/
count 					// total
count 	if wave		==1 // 
count 	if hacohort	==1 // 
count 	if inw1		==1	// 
codebook ID, compact 	// 83,310 IDs
codebook ID, compact 	// 79,420 IDs
keep 	if agemin<=70 /*exclude all observations from people who are very old when first observed*/
codebook ID, compact
log close logSampleselection
	
	
**generate subsamples**
loc 	sfull5 	"(everdead==1|inw_tot>=5)"
gen 	sfull5 = `sfull5'
gen 	sfull = sfull5	
la var 	sfull "`sfull5'"
	**check generation is correct**
	tab sfull5 inw_tot if everdead==0
sum d_anyatfirstobs 
sum d_anyatfirstobs if sfull
count if sfull
*++
*/



sort 	ID wave
save	"`h_data'H_`data'_panel2-MM.dta", replace // check if appeared in correct folder!
*pause 



****************************************************************************************************
*++ END OF FILE ++*
log close logDofile /*logs file to specified folder if log active*/
}
+++ END OF FILE +++
****************************************************************************************************




****************************************************************************************************
*Part 6*: Analysis (use separate .do file)
****************************************************************************************************
*[see separate file]*







****************************************************************************************************
***Addendum***
****************************************************************************************************
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

****************************************************************************************************
*Full variable descriptions*
****************************************************************************************************
*RADIAGPSYCH indicates the age at which the respondent was first diagnosed with emotional, nervous, or psychiatric problems. Respondents who have never been diagnosed with emotional, nervous, or psychiatric problems are not asked this question and are assigned a special missing code .x. If the age first diagnosed with emotional, nervous, or psychiatric problems is provided in multiple waves, the first provided age is used. Don't know, refused, or other missing responses of RADIAGPSYCH are assigned special missing codes .d, .r, and .m, respectively. RADIAGPSYCH is set to special missing .q in Waves 1, 2, and 4, when this question is not asked.
*RADIAGXXXX: For all variables, if the respondent reports a new diagnosis after their first interview, they are not asked the age at which they were diagnosed, and the variable is assigned special missing .s. All variables are assigned special missing .c in Wave 7 if the respondent has been diagnosed with the condition but is not asked the age at which they were diagnosed because they were given the condensed core interview and the life history interview in this wave. For all variables, if the given age is greater than the respondent's age in the current interview year, then the variable is assigned special missing value .i. Please note that there may be extreme values for some of these variables, which have been left to the discretion of the user.


***Archive Code***
/* using if condition in d_count: 
computes the count *only* for 
	observations that have no missing diseases:
	("if d_missing<=1" allows for 1 missing value, because in SHARE kidney is not available in waves 1-5)
		|if kidney is never  available, "if d_missing==0" should be used - since kidney variable is not available
		|if kidney is always available, "if d_missing==0" should be used
		|if another key variable is only available for few periods, the same coding applies.| 
	(",missing" tells sets d_count to . instead of 0 when all variables are .) */
	
/**age at first onset (of Multimorbidity)**
gen 	first_age 		= age if d_count>=2 /*age, if any disease is present*/
bys ID: egen d_firstage_mm = min(first_age)
drop 	first_age
sort 	ID wave
li 		ID wave age d_any d_count d_count_geq2 d_firstage_mm in 1/16 /*check correct generation*/
la var 	d_firstage_mm 	"age of first onset (of multimorbidity)"	
*/
	
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