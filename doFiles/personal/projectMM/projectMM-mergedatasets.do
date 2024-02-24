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
gen 		dataset   = "ELSA"
tempfile 	tempdata
save 		"`tempdata'", replace


loc data 	"SHARE"
use 		"./`data'/`data'data/harmon/H_`data'_panel2-MM.dta", clear	
gen 		dataset = "SHARE"
append 		using "`tempdata'", force

**# Bookmark #1
	label drop time
	drop if wave==3    & dataset=="SHARE"
	replace wave = wave-1 if dataset=="SHARE"
	drop wave // wave is no longer relevant now
loc data 	"SHAREELSA"
save  		"./`data'/`data'data/harmon/H_`data'_panel2-MM.dta", replace

tempfile 	tempdata2
save 		"`tempdata2'", replace

loc data 	"HRS"
use 		"./`data'/`data'data/harmon/H_`data'_panel2-MM.dta", clear	
gen 		dataset = "HRS"
append 		using "`tempdata2'", force
drop wave
loc data 	"SHAREELSAHRS"
save  		"./`data'/`data'data/harmon/H_`data'_panel2-MM.dta", replace
