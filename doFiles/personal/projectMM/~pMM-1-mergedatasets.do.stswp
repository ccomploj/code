pause on
pause off
log close _all 	/*closes all open log files*/
clear all		/*clears all data in memory*/





***define folder locations***
if "`c(username)'" == "P307344" { // UWP server
loc cv 		"X:/My Documents/XdrvData/"
}
else {
loc	cv 		"C:/Users/`c(username)'/Documents/RUG/"
}
cd  		"`cv'"	

// set up ELSA data
loc data 	"ELSA"
use 		"./`data'/`data'data/harmon/H_`data'_panel2-MM.dta", clear	
gen 		countryID = "EN"
rename 		ID IDold 
tempfile 	elsadata
save 		"`elsadata'", replace

// set up SHARE data
loc data 	"SHARE"
use 		"./`data'/`data'data/harmon/H_`data'_panel2-MM.dta", clear	
rename 		ID IDold
append 		using "`elsadata'", force // option -force- is used bc of mismatch in vartype of pn; 

// reorganize merged data (SHARE+ELSA)
**# Bookmark #1 should I use iwyr instead?
label drop time // time label does not match accurately across countries
gen time2 = iwyr // using interview year may be more appropriate for "time"
drop wave // wave is no longer relevant now, bc wave 1 is different for each
egen ID 	= group(dataset IDold)	// assign a new ID to avoid repetitions of the same ID
xtset ID time
loc data 	"SHAREELSA"
*save  		"./`data'/`data'data/harmon/H_`data'_panel2-MM.dta", replace
save  		"./SHARE/SHAREdata/harmon/H_`data'_panel2-MM.dta", replace // save in same location as SHARE
tempfile 	shareelsa 
save 		"`shareelsa'", replace // save again in local memory

*** now merge also HRS data, and save to a new dataset ***
loc data 	"HRS"
use 		"./`data'/`data'data/harmon/H_`data'_panel2-MM.dta", clear	
rename 		ID IDold
append 		using "`shareelsa'", // force

// reorganize merged data (HRS+above)
**# Bookmark #2 should I use iwyr instead?
label drop time // time label does not match accurately across countries
drop wave
drop ID // need to drop (was created above in merged data) and regenerate below
egen ID 	= group(dataset IDold)	
xtset 		ID time
loc data 	"SHAREELSAHRS"
*save  		"./`data'/`data'data/harmon/H_`data'_panel2-MM.dta", replace
save  		"./SHARE/SHAREdata/harmon/H_`data'_panel2-MM.dta", replace  // save in same location as SHARE


*** some basic overview statistics ***
bys dataset: tab agegrp10 d_any if age>50, col nofreq
bys dataset: tab agegrp10 demen if age>50, col nofreq
bys dataset: tab agemin demener, col nofreq m
tab tr20r agegrpmin5, m // check if any cohort more likely to not be in the sample