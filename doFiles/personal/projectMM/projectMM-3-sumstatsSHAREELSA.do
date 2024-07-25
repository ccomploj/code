pause on
pause off
log close _all 	/*closes all open log files*/
clear all		/*clears all data in memory*/



***choose data***
**# Bookmark #1 set everything into SHARE output, but dataset used only from SHAREELSA
loc data "SHARE"  


***define folder locations***
if "`c(username)'" == "P307344" { // UWP server
loc cv 		"X:/My Documents/XdrvData/`data'/"
loc outloc 	"`cv'" // to save locally 
*loc outloc "\\Client\C$\Users\User\Documents\GitHub\2-projectMM-`data'\" // from UWP save directly to PC (only works with full version of Citrix)
}
else {
loc	cv 		"C:/Users/User/Documents/RUG/`data'/"
loc	outloc 	"C:/Users/User/Documents/GitHub/2-projectMM-`data'" // do not overwrite existing output in the compiled output	
}
gl 	outpath 	"`outloc'/files" /*output folder location*/
loc saveloc 	"main" // main | supplement /*saving location*/
loc altsaveloc  "allfiles" // saving location of all plots/subplots
cd  			"`cv'"	
use 			"./`data'data/harmon/H_SHAREELSA_panel2-MM.dta", clear	


count
cd  	"$outpath/tab"
	
	
	keep if hacohort<3 // only use the early sampling cohorts


** generate average followup time **
bys ID: egen followup = max(timesincefirstobs) // this is more correct bc based on iwyr rather than "time"/wave
la var followup "max. followup in years"
	gen myvar = time if inwt==1 // var takes value of time only if present in wave
	bys ID: egen timemin = min(myvar)
	bys ID: egen timemax = max(myvar)
	gen followup2 = timemax - timemin 
	sum followup2 if dataset=="SHARE" & sfull5==1
	*bro ID time followup followup2 iwyr myvar if followup!=followup2 // differs due to iwyr 

** general table comparing SHARE and ELSA **
qui log using 	"$outpath/logs/log-SHAREELSAstats.txt", text replace name(log) 
loc 	vars "male age inw_tot followup everdead d_anyatfirstobs"
dtable  `vars' if time==inw_first_yr, by(dataset) title(Summary Statistics of *full* sample) nformat(%9.2f mean sd)
collect style tex, nobegintable /*keeps only fragment without \begin{table}*/
// collect export "$outpath/tab/main/sumstats/tsumstat_sfullsample_SHAREELSA", as(tex) tableonly replace  

dtable  `vars' if time==inw_first_yr & sfull5==1, by(dataset) title(Summary Statistics of *selected* sample) nformat(%9.2f mean sd)
collect style tex, nobegintable /*keeps only fragment without \begin{table}*/
// collect export "$outpath/tab/main/sumstats/tsumstat_sfull5_SHAREELSA", as(tex) tableonly replace  
qui log close log



