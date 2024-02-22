capture log close
clear all
set more off
log close _all			// closes all log files
pause on				// turns pauses on (a pause does not interrupt local memory)
pause off
set maxvar 20000
timer on 1 				// counts the duration of file computation


***packages needed for file to run***
*	ssc install isvar


/*
**SHARE**
loc data 		"SHARE" // SHARE | ELSA (note for ELSA part5-subDiseases may be incorrect because other diseases are present)
loc	cv 			"G:/My Drive/drvData/`data'/"
loc h_data 		"`cv'`data'data/harmon/" 		  // harmonized data folder location
use 	"`h_data'H_SHARE_f.dta"  			// choose dataset
export delimited using "`h_data'H_SHARE_f.csv", replace // save in csv format
use 	"`h_data'H_SHARE_panel2-MM"
export delimited using "`h_data'H_SHARE_panel2-MM.csv", replace


**ELSA**
loc data 		"ELSA" // SHARE | ELSA (note for ELSA part5-subDiseases may be incorrect because other diseases are present)
loc	cv 			"G:/My Drive/drvData/`data'/"
loc h_data 		"`cv'`data'data/harmon/" 		  // harmonized data folder location
use 	"`h_data'H_ELSA_g3.dta"  			// choose dataset
export delimited using "`h_data'H_ELSA_g3.csv", replace // save in csv format
// use 	"`h_data'H_ELSA_panel2-MM"
// export delimited using "`h_data'H_ELSA_panel2-MM.csv", replace
*/


**HRS**
loc data 		"HRS" // SHARE | ELSA (note for ELSA part5-subDiseases may be incorrect because other diseases are present)
loc	cv 			"G:/My Drive/drvData/`data'/"
loc h_data 		"`cv'`data'data/harmon/" 		  // harmonized data folder location
use 	"`h_data'H_HRS_d.dta"  			// choose dataset
export delimited using "`h_data'H_HRS_d.csv", replace // save in csv format
// use 	"`h_data'H_HRS_panel2-MM"
// export delimited using "`h_data'H_HRS_panel2-MM.csv", replace

use 	"`h_data'randhrs1992_2020v1.dta"  			// choose dataset
export delimited using "`h_data'randhrs1992_2020v1.csv", replace // save in csv format
// use 	"`h_data'H_HRS_panel2-MM"
// export delimited using "`h_data'H_HRS_panel2-MM.csv", replace


