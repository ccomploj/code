clear all
set maxvar 30000

use "C:\Users\bertr\Dropbox (Personal)\HRS_files_new\randhrs1992_2018v2_STATA\randhrs1992_2018v2.dta" 

merge 1:1 hhidpn using ///
"C:\Users\bertr\Dropbox (Personal)\HRS_files_new\randhrsfam1992_2014v1_STATA\randhrsfamr1992_2014v1.dta" 

keep if _merge == 3
tab _merge

forvalues j=13(1)14{
	drop r`j'* s`j'* h`j'*
}

* rename variables to fit stata panel formulation
forvalues i=1(1)12{
	local j = 13-`i'
	rename r`j'* *r`j'
	rename s`j'* *s`j'
	rename h`j'* *h`j'	
}

* education converted to fit Skira
gen education = .
replace education = 0 if raeduc==1 | raeduc==2
replace education = 1 if raeduc==3 
replace education = 2 if raeduc==4 | raeduc==5
label define label_temp 0 "0.no HS" 1 "1.HS" 2 "2.college"
label values education label_temp

* create local variables for time varying and non time varying variables
/*
- age, # living sisters, years of job experience, marital status
- work status, 
- mother lives 10 miles, father lives 10 miles
- hours of care to parents
*/
local tvars "agey_br livsisr jyearsr mstatr lbrfr inw"
local tvars `tvars' "mlv10mir"
local tvars `tvars' "flv10mir"
local tvars `tvars' "prpcrhr"
local tvars `tvars' "momlivr"
local tvars `tvars' "dadlivr"
local tvars `tvars' "livbror"
local tvars `tvars' "mpchelpr"
local tvars `tvars' "fpchelpr"
local tvars `tvars'  "shltr"



* create a new local to get variable at each wave
local tvars2 ""
foreach var of local tvars {
	forvalues i=1(1)12{
		local tvars2 `tvars2' `var'`i'		
	}
}
* to display: 
display "`tvars2'"

* local for time invariant variables
local xvars "hhidpn ragender education"

* combine in single list
local keep_all `tvars2'
foreach var of local xvars {
	local keep_all `keep_all' `var'
}

display "`keep_all'"

* keep only variables in keep_all
keep  `keep_all'

reshape long `tvars', i(hhidpn) j(wave)
xtset hhidpn wave