pause on
pause off
log close _all 	/*closes all open log files*/
clear all		/*clears all data in memory*/



***choose data***
loc data "SHARE"

***define folder locations***
if "`c(username)'" == "P307344" { // UWP server
loc cv 		"X:/My Documents/XdrvData/`data'/"
loc outloc 	"\\Client\C$\Users\User\Documents\GitHub\2-projectMM-`data'\" 
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
}	
loc t "male"
drop if agemin<`agethreshold'	
**********************

***************************************************************************************************
**code common to all datasets***
***************************************************************************************************

***generate (stratification) samples (same for all surveys)***
gen 	sbalanced 	= (inw_miss==0 | everdead==1)	
la var 	sbalanced 			"balanced"
gen 	sneverdead  = (sfull & everdead==0)

loc 	shealthyatfirstobs "sfull & d_anyatfirstobs==0"
gen 	shealthyatfirstobs 	= `shealthyatfirstobs' if d_anyatfirstobs<. /*if d_anyatfirstobs missing, we do not know if the ID was healthy or not at baseline, hence this should be missing*/
la var 	shealthyatfirstobs  "`shealthyatfirstobs'"
la de 	shealthyatfirstobsl 0 "has disease at baseline" 1 "has no disease at baseline"
la val 	shealthyatfirstobs shealthyatfirstobsl

*** Additional Variables ***
** post indicator after first onset (observed) **
gen post = (iwym - firstdate_c1 > 0) if !mi(iwym - firstdate_c1) // first date observed with d_any==1 is also set to 0; is missing if dead 
*bro ID wave age firstage firstdate_c1 iwym post* d_any timesincefirstonset // if d_anyever==0
*tab timesincefirstonset post ,m

**duration since onset**
gen 	timesincefirstonset = iwym - firstdate_c1 if (iwym - firstdate_c1>=0)
la var 	timesincefirstonset "time (months) since first disease"	

**duration from *first* onset to death (in years)**
gen 	time_onsettodeath =  (radym - firstdate_c1)/12
*gen 	time_onsettodeathx = (raxym - firstdate_c1)/12 
la var 	time_onsettodeath "years first onset to death (observed)" 
*la var 	time_onsettodeathx "years first onset to death (observed) (eol module)" 

*bro ID wave radyear raxyear time_ons* firstyear_c1 firstdate_c1 d_any if time_onsettodeathx<0 /*using rad seems more correct than rax, bc no negative values*/
gen 	time_onsettodeath_age	 = radage-firstage 
gen 	time_onsettodeath_age_g2 = radage-firstage_g2
*sum 	radage radyear radmonth raxyear raxmonth time_onsetto*
li 		ID wave iwym dead d_count firstdate_c1 firstdate_c2 ra?ym time_onsettodeath* in 1/16, compress nola
*bro 	ID wave iwym dead d_count firstdate_c1 firstdate_c2 ra?ym time_onsettodeath*  if time_onsettodeath<0
*++
*/

pause 			// press q+enter to continue after pause or turn off pauses above

***************************************************************************************************
*Part 6*: Analysis (sample selection and sumstats and simple regressions)
***************************************************************************************************

cd  	"$outpath/tab"

count
codebook ID, compact
codebook ID if sfull, compact
codebook ID if sbalanced, compact

tab 	iwstatr wave  		// full sample 
	
	sum 	d_anyever d_anyever_g2
	
	
	
	tab sfull everdead 
	
	tab inw_tot d_anyever
	tab inw_tot d_anyever_g2
	sum agemin if d_anyever==0
	sum agemin if d_anyever_g2==0
	tab diff_d_count
	tab diff_miss_d_count

	** does the "treatment" also become smaller/turn off ? **
	tab d_any wave if post==1
	tab d_count wave if post==1

	** are the samples well defined?**
	tab 	everdead sfull	// all people who ever die are included
	tab 	sneverdead dead,m
	tab 	sfull d_anyatfirstobs, col // ideally, people dropped in sfull should not differ in having disease at baseline
	tab 	sfull shealthyatfirstobs, m 

	
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
	
	/***simple tabulations***
	tab d_any wave,m
	codebook radiag* d_*  , compact 
	sum firstage firstage_g2
	*/
	
	




	
	
	
***overview of data***
**final sample**
qui log using 	"$outpath/logs/log-samplefinal.txt", text replace name(log) // exported onto github project directly
tab hacohort wave 	if sfull,m
tab iwstatr wave 	if sfull,m
sum agemin 			if sfull, 
qui log close log

tabstat d_*, statistics(count mean sd min max) columns(statistics) varwidth(20)	

**included diseases**
*note: cannot export to .tex with little code. This option is available: https://www.statalist.org/forums/forum/general-stata-discussion/general/1642470-expxport-codebook-descriptives-to-latex
qui log using 	"$outpath/logs/log-t_diseaselist.txt", text replace name(log) 
codebook d_* timetonextdisease2, compact 
codebook diff_*,compact // assuming the first disease starts with hibp in the dataset
sum d_anyatfirstobs if sfull & wave==inw_first & agemin==50  // ppl w/ >1 conditions at baseline
sum d_anyatfirstobs if sfull & wave==inw_first & inrange(agemin,50,65) // ppl w/ >1 conditions at baseline
qui log close log
*STOP
*/

**************************
*** Summary Statistics ***
**************************	

/*** general table (not summary statistics) ***
table iwstatr male, statistic (mean male) statistic(sd male) statistic(freq)	
tabulate iwstatr, summarize(male)
*/	

preserve /*temporarily remove observations from panel if missing response and not dead, for correct N in summary statistics in dtable*/
keep if inwt==1 | dead==1 /*-listwise- drops obs if any of the variables is missing. This is not desired if these variables are nonmissing only for selected ids (e.g. for those who have a disease). Hence, I drop the observations that are "missing" from the panel // export(text.tex, tableonly)*/
	
loc frmt				"tex"
loc continuous_meanonly	"iwyr rabyear radyear dead d_anyatfirstobs    male d_any" // /*mean only*/
loc continuous 			"age `continuous_meanonly' d_count firstage firstage_g2 time_onsettodeath time_c* timetonextdisease2"  
loc continuous2_alld	"firstage_d* radiag*" //   
loc categorical			"i.raeducl i.cohort" //  i.raeducl i.cohort  married | i.mstatr
loc columns 			"wave"
*loc columnsmany		"s50to65 wave" // shealthy 
*loc stratification 	"shealthy" // male

loc 	opt_dtable 		"nformat(%9.2f mean sd) sample(, place(seplabels)) by(`columns', nototals missing) column(by(hide)) halign(center) warn sformat("%s |" count fvfrequency) " //  
loc 	opt_table 		"nototals stat(frequency) stat(percent) sformat("%s%%" percent) nformat(%9.2f mean sd) " // nototals stat(fvpercent `categorical') " totals(wave)

	**add information from cohorts**
	*info about cohorts*
	loc x 		"hacohort"
	levelsof 	`x', local(levels)
	foreach level of local levels{
	loc levellabel: label (hacohort) `level'
	loc hacohortl "`hacohortl'; `levellabel'"
	}
	di "`hacohortl'"

loc 	sample 		"sfull" // 
foreach sample in 	"sfull" "shealthyatfirstobs" { //"shealthy"  /*comment out line if single sample*/
loc 	samplelabel: variable label `sample' /*adds var label to local*/
loc 	notes 		""
loc 	notes 		"Notes: The Table shows (number of nonmissing observations) | (mean) | (sd) | The sample used is: `samplelabel'. The sample cohorts that are included are: `hacohortl'" // where cohorts 1 and 2 are included
di "`sample'"
sum `continuous' `cont_onlymean' `categorical' if `sample' 

*** summary statistics method 1: using -dtable- (Stata 18+) ***
*https://www.statalist.org/forums/forum/general-stata-discussion/general/1660553-exporting-fragment-latex-tables-via-collect-export
/*only works with a single column variable: if want to use multiple column variables, need to use -table- until Stata 18. See an example here: https://github.com/ccomploj/code/blob/313b50e33f5ae0df6c99a73fcf224dfb59e070e8/doFiles/sumstats/do_dtable_table.do*/
dtable  `continuous' `categorical' if `sample', `opt_dtable' notes(`notes') continuous(, stat(count mean sd)) continuous(`continuous_meanonly', stat(count mean))  // title(sometitle) export(myfile.docx, replace)
collect style tex, nobegintable /*keeps only fragment without \begin{table}*/
collect export "$outpath/tab/`saveloc'/sumstats/o_sumstat_bywave`sample'", as(`frmt') tableonly replace  
**same table, just with all diseases**
dtable  if `sample', `opt_dtable' notes(`notes') continuous(`continuous2_alld', stat(count mean sd)) 
collect style tex , nobegintable /*keeps only fragment without \begin{table}*/
*collect export "$outpath/tab/sumstats/o_sumstat_bywave`sample'", as(`frmt') tableonly append /*append table*/
collect export "$outpath/tab/`saveloc'/sumstats/o_sumstat_bywave`sample'_alld", as(`frmt') tableonly replace /*replace table*/
} /*closes sample loop*/
restore
STOP
*/

/** summary statistics method 2: using -table- (Stata 17+) **
table (var) (`columnsmany') (`stratification')  if `sample' ,  `opt_table' stat(mean `continuous_meanonly' `continuous' )  stat(sd `continuous') 
*collect export "$outpath/sumstats/o_sumstat`sample'", as(`frmt') replace tableonly
	// 	putdocx clear /*to save onto a dynamic document*/
	// 	putdocx begin
	// 	putdocx collect
	//	putdocx save "$outpath/sumstats/o_sumstat_`sample'.docx", replace
table (var) (`columnsmany') (`stratification') if `sample',  `opt_table' stat(mean `continuous2_alld' )  stat(sd `continuous2_alld') 
*collect export "$outpath/sumstats/o_sumstat`sample'_alld", as(`frmt') tableonly replace	/*separate table*/
	// 	putdocx collect
	// 	putdocx save "$outpath/sumstats/o_sumstat.docx", replace
} /*closes sample loop*/
restore
STOP
*/ 

/*** summary statistics method 3: using -esttab- *** 
*note: here we test for significant differences in vars between samples*
loc 	mainvars  	"`continuous_meanonly' raeducl    " /*cannot use factor variables (`categorical' (=i.raeduc)) here, and other restrictions*/
loc 	t 			"male" /*Need to addjust code if want multiple columns*/
	loc 	sample 	"sfull"	/*was defined above*/
loc 	mtitle 	  	"mtitle("`t'=1" "`t'=0")" /*can replace this if value labels are defined*/
*loc 	samerow 	" " " /*moves sd to same row*/
loc 	opt_sumstat "replace label `mtitle' cells(`samerow' mean(pattern(1 1 0) fmt(2)) sd(pattern(1 1 0)) t(pattern(0 0 1)) `samerow' )"
eststo est1: 	 	qui estpost sum 	`mainvars'  if `sample' & `t'==1
eststo est2: 	 	qui estpost sum 	`mainvars' 	if `sample' & `t'==0
eststo estdiff: 	qui estpost ttest 	`mainvars'  if `sample' , by(`t') unequal
esttab est1 est2 estdiff ,	`opt_sumstat' modelwidth(10)  
*esttab est* using 	"$outpath/sumstats/o_sumstat_esttab" , tex `opt_sumstat' fragment 
restore	
STOP
*/

/*** test for differences in vars between samples (can also use -tests- in dtable) ***
tab sfull sbalanced
loc testvars "iwyr age  d_any d_count d_count_geq2 firstage firstage_g2 dead male raeducl married"
eststo estdiff1: qui estpost ttest `testvars' if sfull, by(sbalanced) unequal
eststo estdiff2: qui estpost ttest `testvars' if sfull, by(shealthyatfirstobs) unequal	
esttab estdiff1 estdiff2
restore
++
*/
*/

	
