pause on
*pause off
log close _all 	/*closes all open log files*/
clear all		/*clears all data in memory*/


***choose data***
loc data 		"HRS"
loc datalist 	"SHARE ELSA HRS"
*foreach data of local datalist {

***define folder locations***
if "`c(username)'" == "P307344" { // UWP server
loc cv 		"X:/My Documents/XdrvData/`data'/"
loc outloc 	"`cv'" // to save locally 
*loc outloc "\\Client\C$\Users\User\Documents\GitHub\2-projectMM-`data'\" // from UWP save directly to PC (only works with full version of Citrix)
}
else {
loc	cv 		"G:/My Drive/drvData/`data'/" // own PC
	*loc cv 	"C:\Users\User\Documents\RUG/`data'"
loc	outloc 	"C:/Users/User/Documents/GitHub/2-projectMM-`data'" // do not overwrite existing output in the compiled output	
}
gl 	outpath 	"`outloc'/files" /*output folder location*/
loc saveloc 	"main" // main | supplement /*saving location*/
cd  			"`cv'"	
use 			"./`data'data/harmon/H_`data'_panel2-MM.dta", clear	



****************************************************************************************************
*Part 7a*: Regression (define .do file)
****************************************************************************************************	

** [survey-specific loop excluded here] **
	*sample 20 // this could cause issues if different time periods are dropped for different IDs
	keep if wave==3 // not sure yet how to deal with it in panel data
	
	egen rabyeargrp = cut(rabyear), at(1925, 1940, 1950, 1960, 1970, 1980, 2000)
	tab  rabyear rabyeargrp	
	
recode 	d_count_lead (0 = 0 "0 disease") (1 = 1 "1 disease") (2/3 = 2 "2 or 3 diseases") (4/10 = 4 "4+ diseases"), gen(d_count_lead2)

gl  diseaselist 	"d_hibp d_diab d_heart d_lung d_depr d_osteo d_cancr d_strok d_arthr d_demen"
sum $diseaselist

****************************************************************************************************
*Part 7b*: Regression (with unobserved heterogeneity)
****************************************************************************************************
	
		gl depvars "c.ageatfirstobs i.rabyeargrp" //  i.countatfirstobs: how should baseline health status s sort of captured in the outcome
		gl depvars "i.ageatfirstobs i.rabyeargrp" //  i.countatfirstobs: how should baseline health status s sort of captured in the outcome
		
	
	
*** latent class model using disease combinations ***
loc N "2"
*qui log using 	"$outpath/logs/log-reg-gsem-dcombinations-`N'-class.txt", text replace name(log) 			
qui log using 	"$outpath/logs/log-reg-gsem-dcombinations-`N'-class-ctrl.txt", text replace name(log) 		
gsem ( d_hibp d_diab d_heart d_lung d_depr  d_cancr d_strok d_arthr d_demen <- $depvars), family(bernoulli) link(logit) lclass(C `N'),	// d_osteo	// works with 2 classes and 3 also (dependent on seed I think)
	// lcensored(d_count_lead|0) : not allowed with family bernoulli, only for -gaussian-, 
// 	qui log using 	"$outpath/logs/log-reg-gsem-dcombinations-`N'-class-nocons.txt", text replace name(log) 		
// gsem ( d_hibp d_diab d_heart d_lung d_depr  d_cancr d_strok d_arthr d_demen <- _cons), family(bernoulli) link(logit) lclass(C `N')	// d_osteo	// works with 2 classes and 3 also	
estat lcprob 
estat lcmean 

** predict margins ** 
margins, 	predict(classpr class(1)) ///
			predict(classpr class(2))
marginsplot, xtitle("") ytitle("") xlabel(1 "Class 1" 2 "Class 2") title("Predicted Latent Class Probabilities with 95% CI") recast(bar) name(classpr)

loc class "1"
margins, predict(outcome(d_hibp)   class(`class')) /// 
		 predict(outcome(d_diab)   class(`class')) ///
		 predict(outcome(d_heart)  class(`class')) ///
		 predict(outcome(d_lung)   class(`class')) ///
		 predict(outcome(d_depr)   class(`class')) ///
		 predict(outcome(d_cancr)  class(`class')) ///
		 predict(outcome(d_strok)  class(`class')) ///
		 predict(outcome(d_demen)  class(`class')) 
marginsplot,  xtitle("") ytitle("") xlabel(1 "hibp" 2 "diab" 3 "heart" 4 "lung" 5 "depr" 6 "osteo" 7 "cancr" 8 "strok" 9 "arthr" 10 "demen") title("Predicted Probability of 'Behaviors' For Class (`class') with 95% CI")      name(c`class')  recast(bar)
*pause
qui log close log
STOP

gsem ( d_count <- _cons), family(ordinal) link(logit) lclass(C 2)	
*gsem ( d_count d_count_lead <- _cons), family(ordinal) link(logit) lclass(C 2)	// d_osteo	// works with 2 classes and 3 also

	** other potentially useful code **
// 	gsem (d_count_lead2 <-, ologit),  lclass(C 3) 	
// 	gsem (d_count <-, ologit) (C <- male), lclass(C 3) 


























