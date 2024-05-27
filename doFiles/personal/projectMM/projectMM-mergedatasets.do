pause on
pause off
log close _all 	/*closes all open log files*/
clear all		/*clears all data in memory*/





***define folder locations***
if "`c(username)'" == "P307344" { // UWP server
loc cv 		"X:/My Documents/XdrvData/"
}
else {
loc	cv 		"G:/My Drive/drvData/" // own PC
}
cd  		"`cv'"	


loc data 	"ELSA"
use 		"./`data'/`data'data/harmon/H_`data'_panel2-MM.dta", clear	
gen 		countryID = "EN"
rename 		ID IDold // 

tempfile 	tempdata
save 		"`tempdata'", replace


loc data 	"SHARE"
use 		"./`data'/`data'data/harmon/H_`data'_panel2-MM.dta", clear	
*gen 		dataset = "SHARE"
rename 		ID IDold

append 		using "`tempdata'", force

**# Bookmark #1: this only applies to first merged dataset
	label drop time // time label does not match accurately across countries
	drop if wave==3    & dataset=="SHARE"
	replace wave = wave-1 if dataset=="SHARE"
	drop wave // wave is no longer relevant now

	
egen ID 	= group(dataset IDold)	
xtset ID time
loc data 	"SHAREELSA"
save  		"./`data'/`data'data/harmon/H_`data'_panel2-MM.dta", replace

tempfile 	tempdata2
save 		"`tempdata2'", replace

loc data 	"HRS"
use 		"./`data'/`data'data/harmon/H_`data'_panel2-MM.dta", clear	
*gen 		dataset = "HRS"
rename 		ID IDold

append 		using "`tempdata2'", force
		**# Bookmark #2 this applies to previous data (where similar was already applied) and the newly merged data
		label drop time
		drop wave
drop ID
egen ID 	= group(dataset IDold)	
xtset 		ID time
loc data 	"SHAREELSAHRS"
save  		"./`data'/`data'data/harmon/H_`data'_panel2-MM.dta", replace

		bys dataset: tab agegrp10 d_any if age>50, col nofreq
		bys dataset: tab agegrp10 demen if age>50, col nofreq
bys dataset: tab agemin demener, col nofreq m
tab tr20r agegrpmin5, m // check if any cohort more likely to not be in the sample