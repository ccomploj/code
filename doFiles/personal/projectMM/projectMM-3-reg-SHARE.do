pause on
*pause off
log close _all 	/*closes all open log files*/
clear all		/*clears all data in memory*/


***choose data***
loc data 		"SHARE"
loc datalist 	"SHARE ELSA HRS"
*foreach data of local datalist {

***define folder locations***
if "`c(username)'" == "P307344" { // UWP server
loc cv 		"X:/My Documents/XdrvData/`data'/"
loc outloc 	"`cv'" // to save locally 
*loc outloc "\\Client\C$\Users\User\Documents\GitHub\2-projectMM-`data'\" // from UWP save directly to PC (only works with full version of Citrix)
}
else {
*loc cv 		"G:/My Drive/drvData/`data'/" // own PC
loc	cv 		"C:/Users/User/Documents/RUG/`data'/"
loc	outloc 	"C:/Users/User/Documents/GitHub/2-projectMM-`data'" // do not overwrite existing output in the compiled output	
}
gl 	outpath 	"`outloc'/files" /*output folder location*/
loc saveloc 	"main" // main | supplement /*saving location*/
cd  			"`cv'"	
use 			"./`data'data/harmon/H_`data'_panel2-MM.dta", clear	
	*pause

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
// loc ptestname 	"cesdr"
// loc pthreshold	"4"
	keep 	if hacohort<=5 	
	keep if wave>=3 & wave<=13 // cognitive measures not consistently available 		
}	
if "`data'"=="SHAREELSA" {
loc agethreshold 	"50" // select survey-specific lower age threshold
loc upperthreshold	"85" // select survey-specific upper age threshold	
loc wavelast 		"9" 	// select survey-specific last wave
// loc ptestname 	"cesdr"
// need to do correct this accordingly
// loc pthreshold	"3"
	drop if agemin<50  & dataset=="SHARE"
	drop if agemin<50  & dataset=="ELSA"
	*drop if wave==3    & dataset=="SHARE" // already dropped
	drop if hacohort>2 & dataset=="SHARE"  
}	
drop if agemin<`agethreshold'	
**********************
cd  	"$outpath/tab"


****************************************************************************************************
*Part 7a*: Regression (define .do file)
****************************************************************************************************	
*** define global vars ***
loc sample "sfull"
loc samplelabel: variable label `sample'
set scheme s1color	


/*** packages needed for regression ***
ssc install gologit2 // search and install gologit2
rnethelp "http://fmwww.bc.edu/RePEc/bocode/o/oparallel.sthlp" // for brant test
findit spost13 // needed for -mtable-, but also brant test	
*brant test (only for ologit): https://www.statalist.org/forums/forum/general-stata-discussion/general/1335252-ologit-and-brant-test
ssc install regoprob2
ssc install seqlogit
search st0359 // DH model (xtdhreg)
findit mdraws // DH model required package
*/


*** additional variables *** 
tab raeducl, gen(raeduclcat) // separate variables needed for regoprob2
drop 	raeduclcat1
rename 	raeduclcat2 educ_vocational
rename  raeduclcat3 educ_university

	// 	*** split by regions ***
	// 	if dataset == "ELSA" {
	// 	gen countryID = "EN"
	// 	}
	// 	gen 	region = "NA"
	// 	replace	region = "North"  		 if (countryID=="AT"|countryID=="Bf"|countryID=="Bn"|countryID=="Cf"|countryID=="Cg"|countryID=="Ci" | countryID=="DE"|countryID=="DK"|countryID=="EE"|countryID=="FI"|countryID=="FR"|countryID=="IE"        |countryID=="Ia" |countryID=="Ih" |countryID=="Ir"     |countryID=="LT"|countryID=="LU"|countryID=="LV" |countryID=="NL" |countryID=="SE"       ///
	// 	| countryID=="EN") // add EN
	// 	replace region = "Center-East"   if (countryID=="BG"|countryID=="CZ"|countryID=="HR"|countryID=="HU"|countryID=="Cf" |countryID=="PL" |countryID=="RO" |countryID=="SI" |countryID=="SK" )
	//  	replace region = "South" 		 if (countryID=="CY"|countryID=="ES"|countryID=="IT"|countryID=="MT"|countryID=="PT")	
	// 	qui log using 	"$outpath/logs/log-regionclassification.txt", text replace name(log) 
	// 	tab countryID region,m
	// 	log close log
	// // 	label 	define regionl 1 "North-East" 2 "East" 3 "Center" 4 "West"
	// // 	*label   define regionl 1 "NE" 2 "E" 3 "C" 4 "W"
	// // 	label	value  region regionl


****************************************************************************************************
*Part 7b*: Regression (general)
****************************************************************************************************	

**recode age and timesincefirstobs if too few observations fall in this category and SEs large (for agemin<=70 sample**
levelsof agegrpmin5, local(levels)
foreach  cohort of   local levels {
qui 	sum time, meanonly 
loc 	timerange = r(max)-r(min)+5 /*maximum time an id is observed (5 added for cohort)*/
replace age = `cohort'+`timerange' if age >`cohort'+`timerange' & age<. & agegrpmin5==`cohort' 
replace timesincefirstobs = `timerange'-5 if timesincefirstobs<. & timesincefirstobs>`timerange'-5
} 
di 		"`timerange'"

	*sample 20
loc 	y 			"d_count"
loc 	ylabel: 	var label `y'
loc 	cat  	  	"agegrpmin5" // male, raeducl, countatfirstobs
loc 	timevar 	"c.age" 
*loc 	xla 		"xla(50(5)90)" /*needed for separate sub-plots*/
loc 	opt_marginsplot "ytitle("Predicted (`ylabel')")" // noci  
// loc 	ctrls  "`ctrl'"
	loc ctrls "male i.raeducl"

*overall plot by cohort groups (continuous time)* 
	log using 	"$outpath/logs/log-reg_byage_d_count_outofsample.txt", text replace name(log) 
loc 	reg  		reg `y' `timevar'##`cat' `ctrls'  if `sample'==1 
 `reg'
	log close log
*qui margins `timevar'#`cat' 
qui margins `cat', at(age=(30(5)90)) 
marginsplot,  `opt_marginsplot'   `xla' `xlarotate' title("Prediction from linear fit using age") note("Sample: `samplelabel' | Controls: `ctrls' (none)" "Model: `reg'") name(g`cat'_`cohort', replace) yline(0) // by(agegrpmin5) 
gr export 	"$outpath/fig/main/g_reg_byage_d_count_outofsample.jpg", replace	quality(100)
	STOP
	
	
	
	*** mixed model ***
	xtreg, mle = xtmixed...










