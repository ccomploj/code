pause on
pause off
log close _all 	/*closes all open log files*/
clear all		/*clears all data in memory*/



***choose data***
loc data 		"HRS" // HRS, SHARE, SHAREELSA
loc datalist 	"SHARE HRS ELSA"
*foreach data of local datalist{

	**define country-specific locals**
	loc data2 "`data'" // use same path unless otherwise specified
	if "`data'"=="SHARE" {
	}
	if "`data'"=="ELSA" {
	}
	if "`data'"=="HRS" {
	}
	if "`data'"=="SHAREELSA" {
		loc data2 "SHARE" // use output location and path of SHARE if combined dataset is used. (should not do if separate datasets, if that is the case should move to other do file)
	}	

***define folder locations***
if "`c(username)'" == "P307344" { // UWP server
loc cv 		"X:/My Documents/XdrvData/`data'/"
loc outloc 	"`cv'" // to save locally 
*loc outloc "\\Client\C$\Users\User\Documents\GitHub\2-projectMM-`data'\" // from UWP save directly to PC (only works with full version of Citrix)
}
else {
loc	cv 		"C:/Users/`c(username)'/Documents/RUG/`data2'/"
loc	outloc 	"C:/Users/`c(username)'/Documents/GitHub/2-projectMM-`data2'" // do not overwrite existing output in the compiled output	
}
gl 	outpath 	"`outloc'/files" /*output folder location*/
loc saveloc 	"main" // main | supplement /*saving location*/
loc altsaveloc  "allfiles" // saving location of all plots/subplots
cd  			"`cv'"	
use 			"./`data2'data/harmon/H_`data'_panel2-MM.dta", clear	


pause // press q+enter to continue after pause or turn off pauses above

***********
cd  	"$outpath/tab"
gl  diseasecodelist "hibp diab heart lung depr osteo cancr strok arthr demen" // psych
gl  diseaselist 	"d_hibp d_diab d_heart d_lung d_depr d_osteo d_cancr d_strok d_arthr d_demen"
**# Bookmark #1 I drop the cohortselection in all files except vizualization
	drop if cohortselection==0 
	drop if mi(age) // these are missing observations/time periods
	tab hacohort

**# Bookmark #2 to sumstat notes, should add included cohorts (this causes bad formatting in latex)


***************************************************************************************************
*Part 6*: Analysis (sample selection and sumstats and simple regressions)
***************************************************************************************************


************************
*** overview of data ***
************************
codebook ID, compact
codebook ID if sfullsample, compact
codebook ID if sfull5, compact
tab 	iwstatr time  		


**disease list (ideally would make only description without sumstats here)**
**+censoring of onset**
qui log using "tablogs/codebook-diseaselist.txt", text replace name(log)
count
count if !mi(age)
codebook $diseaselist , compact
// left-censoring: the following for how many already have a disease when first observed
sum onsetage d_anyatfirstobs if inw_first_yr==time
sum onsetage d_anyatfirstobs if inw_first_yr==time & cohortselection==1 // cohortselection are the selected hacohorts
// right-censoring: the following for how many never develop any disease 
sum d_anyever d_anyever_g2 if inw_first_yr==time /* d_anyever_g2 (selfrep) should be be similar to d_anyever
													for right-censoring*/
*sum age
sum agemax everdead if inw_first_yr==time & d_anyever==0, /* characteristics of people who never report 
															having any disease  (these are younger)*/
*hist agemax if d_anyever == 0 
*bro ID wave age d_any d_count d_anyever if d_anyever==0
qui log close log


**final sample**
qui log using 	"$outpath/logs/log-samplefinal.txt", text replace name(log) 
tab time d_miss 	if !mi(age),m // to double-check if there is some diseases missing in later waves
tab time hacohort 	if !mi(age),m
tab time iwstatr 	if mi(age),m // if not present in survey, what is the interview status
sum agemin agemax, 
tab diff_d_count
qui log close log


	/***simple tabulations***
	tab d_any wave,m
	tab d_count wave,m

	codebook radiag* d_*  , compact 
	sum firstage firstage_g2
	*/
	
		/** does the "treatment" also become smaller/turn off ? **
	tab d_any  	time if post==1
	tab d_count time if post==1
	*/
	

	
	/*
	tab inw_tot d_anyever
	tab inw_tot d_anyever_g2
	sum agemin if d_anyever==0
	sum agemin if d_anyever_g2==0
	tab diff_d_count
	*	tab diff_miss_d_count
	*/	
	

	** are the samples well defined?**
	tab 	everdead sfull5	// all people who ever die are included
	*tab 	sneverdead dead,m
	tab 	sfull5 d_anyatfirstobs, col // ideally, people dropped in sfull should not differ in having disease at baseline
	*tab 	sfull5 shealthyatfirstobs, m 

	
	/* summarize each key variable separately
	*log using 	"./log-diseaseSumstats.txt", text replace name(log)
	**check distribution across ages**
	sum firstage, 	detail 
	sum firstage_g2, 	detail
	sum d_count, 		detail 
	sum d_count_geq2, 	detail

	**check distribution of first onset for each disease separately**
	foreach d of local d_firstagelist {
		sum `d', detail
	}
	foreach d of local radiaglist {
		sum `d', detail
	}
	log close log
	*/	
	


tabstat d_*, statistics(count mean sd min max) columns(statistics) varwidth(20)	

**included diseases**
*note: cannot export to .tex with little code. This option is available: https://www.statalist.org/forums/forum/general-stata-discussion/general/1642470-expxport-codebook-descriptives-to-latex
qui log using 	"$outpath/logs/log-t_diseaselist.txt", text replace name(log) 
*codebook d_* timetonextdisease2, compact 
// codebook diff_*,compact // assuming the first disease starts with hibp in the dataset
sum d_anyatfirstobs if sfull5 & time==inw_first_yr & agemin==50  // ppl w/ >1 conditions at baseline
sum d_anyatfirstobs if sfull5 & time==inw_first_yr & inrange(agemin,50,65) // ppl w/ >1 conditions at baseline
qui log close log
*STOP


		*check if availability of any of the diseases is based on age*
*/




/**************************
*** Summary Statistics ***
**************************	

/*** general table (these are not summary statistics) ***
table iwstatr male, statistic (mean male) statistic(sd male) statistic(freq)	
tabulate iwstatr, summarize(male)
*/	

preserve /*temp. remove observations from panel if missing response and not dead, for correct N in dtable*/
keep if inwt==1 | dead==1 /*-listwise- drops obs if any of the variables is missing. This is not desired if these variables are nonmissing only for selected ids (e.g. for those who have a disease). Hence, I drop the observations that are "missing" from the panel // export(text.tex, tableonly)*/
	
loc frmt				"tex"
loc continuous_meanonly	"male rabyear radyear iwyr everdead  d_anyatfirstobs d_any" // /*mean only*/
loc continuous 			"age `continuous_meanonly' d_count d_miss onsetage onsetage_g2" //  
loc continuous2_alld	"onsetd_* radiag*" //   
loc categorical			"i.raeducl i.agegrpmin10" //  i.raeducl i.agegrpmin10  married | i.mstatr
loc columns 			"time"
*loc columnsmany		"s50to65 wave" // shealthy 
*loc stratification 	"shealthy" // male

loc 	opt_dtable 		"nformat(%9.2f mean sd) sample(, place(seplabels)) by(`columns', nototals missing) column(by(hide)) halign(center) warn sformat("%s |" count fvfrequency) " //  

loc 	sample 		"sfullsample" // this sample should have age-missing observations dropped
loc 	samplelabel: variable label `sample' /*adds sample label to local macro*/
di "`sample'"
sum `continuous' `categorical' if `sample' 

*** summary statistics method 1: using -dtable- (Stata 18+) ***
*https://www.statalist.org/forums/forum/general-stata-discussion/general/1660553-exporting-fragment-latex-tables-via-collect-export
*only works with a single column variable: if want to use multiple column variables, need to use -table- until Stata 18. See an example here: https://github.com/ccomploj/code/blob/313b50e33f5ae0df6c99a73fcf224dfb59e070e8/doFiles/sumstats/do_dtable_table.do
dtable  `continuous' `categorical' if `sample', `opt_dtable' continuous(, stat(count mean sd)) continuous(`continuous_meanonly', stat(count mean))  // title(sometitle) export(myfile.docx, replace)
collect style tex, nobegintable /*keeps only fragment without \begin{table}*/
collect export "$outpath/tab/`saveloc'/sumstats/o_sumstat_bywave`sample'", as(`frmt') tableonly replace  
**same table, but now for all disease onsets**
dtable  if `sample', `opt_dtable' continuous(`continuous2_alld', stat(count mean sd)) 
collect style tex , nobegintable /*keeps only fragment without \begin{table}*/
collect export "$outpath/tab/`saveloc'/sumstats/o_sumstat_bywave`sample'_alld", as(`frmt') tableonly replace /*save this new table separately rather than appending (-append-)*/
} /*closes sample loop*/
restore
STOP
*/




**************************
*** Other tables ***
**************************	


*** number of missing counts within sequence ***
**# Bookmark #1 doing it with age here, but actually should do with d_count as d_count may be missing even though he participated
*** how many are missing at least once in a sequence from earliest interview until latest interview (without being dead of course) *** 
use 			"`cv'/`data2'data/harmon/H_`data'_panel2-MM.dta", clear	// need to use full dataset with missing ages
tab 	sfullsample
tab 	followupmax 
**moved generation to part5-subdiseases.do**
// gen myvar = (d_count==. & inw_first_yr < time & inw_last_yr > time) //  // & followup==. 
// //* 	gen myvar2 = (d_count==. & followup==. & inw_first_yr < time & inw_last_yr > time) //  // & followup==. 	
// // gen myvar2 = (followup==. & inrange(time, inw_first_yr, inw_last_yr))/*
// bys ID: egen missingatleastonce = max(myvar)
// bys ID: egen missingcountbtwwaves = total(myvar == 1)
bro ID wave time followup age myvar* inw_first_yr inw_last_yr missingatleastonce missingcountbtwwaves

drop if mi(age)
// drop if time<inw_first_yr | time>inw_last_yr // keeps only the missings in between
qui log using "tablogs/t-sequencemissings.txt", text replace name(log)
// within a health sequence, how many times between first and last interview is the count missing
di "dataset: `data'"
tab missingatleastonce,m 
tab inw_tot missingcountbtwwaves, row nofreq 
qui log close log
STOP
*/







/****************** ARCHIVE *********************
loc 	opt_table 		"nototals stat(frequency) stat(percent) sformat("%s%%" percent) nformat(%9.2f mean sd) " // nototals stat(fvpercent `categorical') " totals(wave)

	**add information from cohorts**
**# Bookmark #1 maybe add if sample condition to cohort and levels?
	*info about cohorts*
	loc x 		"hacohort"
	levelsof 	`x', local(levels)
	foreach level of local levels{
	loc levellabel: label (hacohort) `level'
	loc hacohortl "`hacohortl'; `levellabel'"
	}
	di "`hacohortl'"

loc 	notes 		"Notes: The Table shows (number of nonmissing observations) | (mean) | (sd) | The sample used is: `samplelabel'. The sample cohorts that are included are: `hacohortl'" // where cohorts 1 and 2 are included
di "`sample'"

*/