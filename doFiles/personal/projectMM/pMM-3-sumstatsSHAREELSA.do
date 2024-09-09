pause on
pause off
log close _all 	/*closes all open log files*/
clear all		/*clears all data in memory*/



***choose data***
*set everything into SHARE output, but dataset used only from SHAREELSA
loc data "SHARE"  


***define folder locations***
if "`c(username)'" == "P307344" { // UWP server
loc cv 		"X:/My Documents/XdrvData/`data'/"
loc outloc 	"`cv'" // to save locally 
}
else {
loc	cv 		"C:/Users/`c(username)'/Documents/RUG/`data'/"
loc	outloc 	"C:/Users/`c(username)'/Documents/GitHub/2-projectMM-`data'" // do not overwrite existing output in the compiled output	
}
gl 	outpath 	"`outloc'/files" /*output folder location*/
loc saveloc 	"main" // main | supplement /*saving location*/
loc altsaveloc  "allfiles" // saving location of all plots/subplots
cd  			"`cv'"	
use 			"./`data'data/harmon/H_SHAREELSA_panel2-MM.dta", clear	

count
cd  	"$outpath/tab"
	
	keep if hacohort<3 // only use the early sampling cohorts (included in sfull5)

** generate average followup time **
bys ID: egen followup = max(timesincefirstobs) // this is more correct bc based on iwyr rather than "time"/wave
la var followup "max. followup in years"
	gen myvar = time if inwt==1 // var takes value of time only if present in wave
	bys ID: egen timemin = min(myvar)
	bys ID: egen timemax = max(myvar)
	gen followup2 = timemax - timemin 
	sum followup2 if dataset=="SHARE" & sfull5==1
	*bro ID time followup followup2 iwyr myvar if followup!=followup2 // differs due to iwyr 

/** general table comparing SHARE and ELSA **
*qui log using 	"$outpath/logs/log-SHAREELSAstats.txt", text replace name(log) 
loc 	vars "male age inw_tot followup everdead d_anyatfirstobs"
dtable  `vars' if time==inw_first_yr, by(dataset) title(Summary Statistics of *full* sample) nformat(%9.2f mean sd)
collect style tex, nobegintable /*keeps only fragment without \begin{table}*/
collect export "$outpath/tab/main/sumstats/tsumstat_sfullsample_SHAREELSA", as(tex) tableonly replace  

dtable  `vars' if time==inw_first_yr & sfull5==1, by(dataset) title(Summary Statistics of *selected* sample) nformat(%9.2f mean sd)
collect style tex, nobegintable /*keeps only fragment without \begin{table}*/
collect export "$outpath/tab/main/sumstats/tsumstat_sfull5_SHAREELSA", as(tex) tableonly replace  
*qui log close log
*/

** prevalence of each disease --- at baseline
**# need to add here the number of observations to this table
* see here: https://www.statalist.org/forums/forum/general-stata-discussion/general/1762356-multiway-table-hide-certain-levels-of-variable
preserve 
la 	de templabel 1 "%" 	// relabel variable for more compact table
loc sample 	"sfull5"
loc app 	"" 			// tables will be appended	
foreach d of global alldiseasecodes { /*make sure global is present in -macro list-*/
la 	var d_`d' "`d'" 
la 	val d_`d' templabel	 
qui table (male agegrp5) (d_`d') if `sample' == 1, nototals statistic(percent, across(d_`d')) statistic(count d_`d')  name(t1) `app' 
loc app 		"append"
loc templist  	"`templist'   d_`d'"
loc templist1 	"`templist1' d_`d'[1]" // list with 1 indicator (to hide 0-levels)
}
		*LOOK AT DIMENSIONS OF TABLE
		collect dims
		*LOOK AT LEVELS OF DIMENSION RESULT
		collect levelsof result
		*FORMAT CELLS
collect style tex, nobegintable /*keeps only fragment without \begin{table}*/
collect style cell `templist', nformat(%3.2f)
// 		collect style cell result[percent], nformat(%3.2f)
// 		collect style cell result[count], nformat(%9.0f)
// 		collect layout (sex#agegrp) (result#(`templist1'))
collect layout (male#agegrp5) (`templist1')
*collect export "$outpath/tab/main/sumstats/tprevalenced_`sample'_SHAREELSA", as(tex) tableonly replace 
	restore
	
	
	
	
	
	
	
