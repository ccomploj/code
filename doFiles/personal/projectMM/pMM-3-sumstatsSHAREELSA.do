pause on
pause off
log close _all 	/*closes all open log files*/
clear all		/*clears all data in memory*/



***choose data***
*set everything into SHARE output, but dataset used only from SHAREELSA
loc data "SHAREELSA"   // use SHAREELSA data

	* actually this path was the same since this had SHAREELSA dataset
	// ***define folder locations***
	// if "`c(username)'" == "P307344" { // UWP server
	// loc cv 		"X:/My Documents/XdrvData/`data'/"
	// loc outloc 	"`cv'" // to save locally 
	// }
	// else {
	// loc	cv 		"C:/Users/`c(username)'/Documents/RUG/`data'/"
	// loc	outloc 	"C:/Users/`c(username)'/Documents/GitHub/2-projectMM-`data'" // do not overwrite existing output in the compiled output	
	// }
	// gl 	outpath 	"`outloc'/files" /*output folder location*/
	// loc saveloc 	"main" // main | supplement /*saving location*/
	// loc altsaveloc  "allfiles" // saving location of all plots/subplots
	// cd  			"`cv'"	
	// use 			"./`data'data/harmon/H_SHAREELSA_panel2-MM.dta", clear	


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






***********
cd  	"$outpath/tab"
gl  diseasecodelist "hibp diab heart lung depr osteo cancr strok arthr demen" // psych
gl  diseaselist 	"d_hibp d_diab d_heart d_lung d_depr d_osteo d_cancr d_strok d_arthr d_demen"
		bys dataset: tab hacohort cohortselection 
**# Bookmark #1 I drop the cohortselection in all files except vizualization
	drop if cohortselection==0 
	drop if mi(age) // these are missing observations/time periods
	tab hacohort
	

*** generate new variables of SHARE and ELSA ***	
*** generate new variables ***	

** d_anyatfirstobs among young age cohort**
gen  d_any50to55 	= d_anyatfirstobs if inrange(age,50,54) 
la var d_any50to55 "has disease (aged 50-54)"

** d_count_geq2 among young age cohort**
gen d_count_geq2_50to55 = d_count_geq2 if inrange(age,50,54) 
sum d_count_geq2_50to55
la var d_count_geq2_50to55 ">=2 diseases (aged 50-54)"


qui log using 	"$outpath/logs/log-tdmissbycountry.txt", text replace name(log) 
tab countryID sfull5,m row nofreq 
tab countryID inw_tot if sfull5 // selected sample
tab countryID inw_first if sfullsample // fullsample
tab countryID d_miss if time==2017 // it seems that 2017 has many countries that are missing 1 disease (wave 7). Should double check this wave
log close log

* simple summary statistics to compare N *
qui log using 	"$outpath/logs/log-tsumstat.txt", text replace name(log) 
bys dataset: sum `vars'
log close log

preserve // bc recode variable into percentages
loc continuous_meanonly "male everdead d_any d_count_geq2 d_any50to55 d_count_geq2_50to55"
loc 	vars "age inw_tot followupmax d_count `continuous_meanonly' "
	** transform into percentages **
	foreach v of local continuous_meanonly {
		replace `v'=`v'*100
		loc vla: variable label `v'
		di "`vla'"
		la var `v' "`vla' (%)" 
	}

loc opt_dtable "by(dataset) nformat(%9.2f mean sd) continuous(`continuous_meanonly', stat(mean))"
loc sample "sfullsample"
dtable  `vars' if time==inw_first_yr & `sample'==1, `opt_dtable' title(Summary Statistics of *full* sample, at baseline)    // continuous(`continuous2_alld', stat(count mean sd))  halign(center) sformat("%s |" fvfrequency count)
collect style tex, nobegintable /*keeps only fragment without \begin{table}*/
collect export "$outpath/tab/main/sumstats/tsumstat_sfullsample_SHAREELSA", as(tex) tableonly replace  
loc sample "sfull5"
dtable  `vars' if time==inw_first_yr & `sample'==1, `opt_dtable' title(Summary Statistics of *selected* sample, at baseline) 
collect style tex, nobegintable /*keeps only fragment without \begin{table}*/
collect export "$outpath/tab/main/sumstats/tsumstat_sfull5_SHAREELSA", as(tex) tableonly replace  
restore
*/




** prevalence of each disease --- at baseline **
**# need to add here the number of observations to this table
* see here: https://www.statalist.org/forums/forum/general-stata-discussion/general/1762356-multiway-table-hide-certain-levels-of-variable
// preserve 
collect clear
loc 	sample 	"sfull5"
loc 	app 	"" 			// tables will be appended	
la de templabel 1 "%" 	// relabel variable for more compact table
loc list "$diseasecodelist"
foreach d of local list { /*make sure global is present in -macro list-*/
la 	var d_`d' "`d'" 
la 	val d_`d' templabel	 
** for every disease, a table of male and agegrp5, and then append each new table to earlier table
qui table (male agegrp5) (d_`d') if `sample' == 1, nototals statistic(percent, across(d_`d'))  name(t1) `app' // statistic(count d_`d') 
loc app 		"append"
loc templist  	"`templist' d_`d'"
loc templist1 	"`templist1' d_`d'[1]" // list with 1 indicator (to hide 0-levels)
	loc connectedlistmale 	"`connectedlistmale' 	(connected d_`d' agegrp5 if male==1)" // for connectedplot below
	loc connectedlistfemale "`connectedlistfemale' 	(connected d_`d' agegrp5 if male==0)" 
}
	** add N for each age group ** 
	qui table (male agegrp5) if `sample' == 1, nototals statistic(count agegrp5)  name(t1) append

di "`templist'"
di "`templist1'"
di "`connectedlistmale'"
di "`connectedlistfemale'"

// help collect levelsof
collect dims // look at dimensions of table
collect levelsof result // these were saved above in table
collect style cell `templist', nformat(%3.2f) // change fmt of numbers
collect style cell result[percent], nformat(%3.2f)
collect style cell result[count], nformat(%9.0f) // count was also saved above already
// 	collect label list result // result is "dim" 
// 	collect label list count
	collect label drop result

// 	collect layout (male#agegrp5) (result#(d_hibp[1] d_diab[1]))
// collect layout (male#agegrp5) (result#(`templist1')) // include also count
collect layout (male#agegrp5) (`templist1' result[count])
collect style tex, nobegintable /*keeps only fragment without \begin{table}*/
collect export "$outpath/tab/main/sumstats/tprevalenced_`sample'_SHAREELSA", as(tex) tableonly replace 
*/
**# Bookmark #1 here i have % bc it is saved as % in table, could check now still how many nonmissings are in each disease, and nonmissing obs for each disease
	

** profile plot, prevalence of D by age ** 
preserve
collapse (mean) `templist', by(agegrp5 male)
foreach v of varlist `templist' {
di "`v'"
label var `v' "`v'" // remove "mean" from label
}
di "`connectedlistmale'"
*search grc1leg2 // single legend in combined graph
twoway 	`connectedlistmale' , 	xlabel(,grid) ylabel(,grid) title("Mean by Age-group, male") name(gr1, replace)  legend(position(6) row(4)) // suppress legend on first graph only
twoway 	`connectedlistfemale' , xlabel(,grid) ylabel(,grid) title("Mean by Age-group, female") name(gr2, replace) legend(off)
grc1leg2 gr1 gr2, scheme(s1color) legendfrom(gr1) ycommon  // allows for single legend in combined graph
// gr combine gr1 gr2, ycommon 
gr export 	"$outpath/fig/main/g_prevalencedbyage_bysex.pdf", replace	
restore

	
