/*
meologit and gllamm are both Stata commands that can be used to estimate ordered logit models with unobserved heterogeneity, but they differ in their underlying estimation approach and capabilities.

meologit uses maximum likelihood estimation and is part of Stata's built-in capabilities. It is generally faster and more efficient for simpler models.
gllamm (generalized linear latent and mixed models) is a user-written program that uses quasi-likelihood methods. It is more flexible and can handle more complex model specifications, such as correlated random effects, non-normal mixtures, and heteroskedastic errors. However, it can be slower and less stable for simpler models.
In summary, meologit is the simpler and more efficient choice for basic mixed-effects ordered logit models, while gllamm offers more advanced capabilities but at the cost of increased complexity and potentially longer estimation times.
*/

/*
Syntax: The syntax for meologit is simpler and more straightforward, while gllamm has a more complex syntax that allows for greater flexibility in specifying models.
Model specification: meologit is specifically designed for estimating random effects ordered logit or probit models, while gllamm can handle a wider range of models, including non-linear mixed effects models, multilevel models, and panel data models.
Estimation methods: meologit uses a maximum likelihood estimation method, while gllamm uses a generalized linear latent and mixed models (GLLAMM) estimation method, which can handle more complex models with multiple random effects and cross-classified data structures.
Convergence: meologit may have convergence issues for complex models or large datasets, while gllamm is more robust and can handle larger and more complex models.
Post-estimation analysis: gllamm provides more options for post-estimation analysis, including the ability to estimate marginal effects, predict probabilities, and perform hypothesis testing.
In summary, meologit is a simpler and more specialized command for estimating random effects ordered logit or probit models, while gllamm is a more flexible and powerful command that can handle a wider range of models and provide more options for post-estimation analysis.
*/

/*
If you want to allow for latent classes, meaning individuals can belong to different unobserved groups or "types," you should consider using a latent class model or a finite mixture model, not necessarily a mixed-effects model. In Stata, you can use the fmm command to fit finite mixture models, which identify latent classes within your data. This allows for different subpopulations within the overall population, each with its own parameters.
https://www.stata.com/features/overview/finite-mixture-models/
*/

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
*loc cv 		"G:/My Drive/drvData/`data'/" // own PC
loc	cv 		"C:/Users/`c(username)'/Documents/RUG/`data'/"
loc	outloc 	"C:/Users/`c(username)'/Documents/GitHub/2-projectMM-`data'" // do not overwrite existing output in the compiled output	
}
gl 	outpath 	"`outloc'/files" /*output folder location*/
loc saveloc 	"main" // main | supplement /*saving location*/
loc altsaveloc  "allfiles" // saving location of all plots/subplots
cd  			"`cv'"	
use 			"./`data'data/harmon/H_`data'_panel2-MM.dta", clear	


****************************************************************************************************
*Part 7a*: Regression (define .do file)
****************************************************************************************************	
tab raeducl, gen(educ)

bsample 20, cl(ID)

fmm 2: ologit d_count_lead male educ* d_count
fmm, lcprob(agegrpmin10 ageatfirstobs male): (ologit d_count_lead male educ* d_count d_count)
]]



		*sample 20 // this could cause issues if different time periods are dropped for different IDs
	*** generate duration with c conditions ***
	gen duration = 0 if d_count>0 & !mi(d_count) // only when count is 1 and not missing 
	sum d_count, meanonly
	loc d_count_max = r(max) // maximum disease count across i
	forval i=1/`d_count_max'{
	bys ID (time): replace duration = cond(d_count==`i',   cond(diff_d_count==0, duration[_n-1]+1,1),duration)
		}
	replace duration = . if mi(d_count) // if count missing, duration should be missing
	la var duration 		"consecutive time periods spent with c conditions"
	**show duration correctly generated**
	sum duration*
	tab duration time
	sum time, meanonly 
	loc timediff = (r(max)-r(min))/2
	di "`timediff'" // should equal to the maximum of duration above
		*	bro ID wave d_count* diff_d_count* duration if ID==10013010
		*	bro ID wave d_count* diff_d_count* duration if ID==10063010
	*li ID time d_count duration in 1/50 if !mi(d_count)
		**set durations to missing if left-censored (do not know the 'true' duration)**
		bys ID: egen d_count_min = min(d_count)
			*replace duration = . if d_count_min==d_count // do not know if entered survey already with condition
		gen		 duration_uncens = duration if d_count_min!=d_count
		la var 	 duration_uncens	"consecutive time periods spent with c conditions (uncensored)"
		sum duration*
	**# Bookmark #3 check this for SHARE. Sth with duration is generated incorrectly when there is a gap
		*bro ID wave d_count_min d_count duration duration_uncens	
		*++
		*/		

	recode 	d_count_lead (0 = 0 "0 disease") (1 = 1 "1 disease") (2/3 = 2 "2 or 3 diseases") (4/10 = 4 "4+ diseases"), gen(d_count_lead2)
	recode d_count_lead2 (99=.)
	recode d_count_lead (99=.)
	gl  diseaselist 	"d_hibp d_diab d_heart d_lung d_depr d_osteo d_cancr d_strok d_arthr d_demen"
	sum $diseaselist

	

****************************************************************************************************
*Part 7b*: Regression (with unobserved heterogeneity)
****************************************************************************************************
	replace duration = 5 if duration>=5 &!mi(duration)

	gl y 	"d_count_lead2"
	*loc xit2 "c.d_count#c.age c.d_count#c.age#c.age" // how to include linear interactions of types with d_count?
	gl xit 	"c.age c.age#c.age i.duration `xit2'" //     , i.countatfirstobs: how should baseline health status s sort of captured in the outcome
	gl zit_0 "i.rabyeargrp c.ageatfirstobs" //  d_count  
	
	** w/o unobserved heterogeneity
	loc data "HRS"
// log using 		"$outpath/logs/log-t-regd_count-age-ologit`data'.txt", text replace name(ologit) 
// di "$y $xit"
// ologit $y $xit 
// log close ologit 

log using 		"$outpath/logs/log-t-regd_count-age-fmmologit`data'8.txt", text replace name(log) 
di "$y $xit $zit_0"
fmm 2, lcprob($zit_0) : ologit $y $xit, //  cl(ID)
log close log
// fmm 3, ordered: ologit y x1 x2
	
	
STOP 	

	
	

	
	
		*** suggestion of bertrand *** 
	loc ctrls "age male raeducl"
	gen presentintplus1 = !mi(d_count) & !mi(F.d_count) // should work for all pairs
	**
		sum d_count, meanonly
		loc d_countmax = r(max) // not correct diseasemax, but max observed so still correct here
		di "`d_countmax'"
	logit time_c1toc2 `ctrls' if d_count==1 & presentintplus1

	forval c=1/`d_countmax' {
*	logit timetonextdisease2 if d_count==1 
	**time, so should use -reg-**
	**raw margins** 
	reg time_c1toc2  if d_count==`c' & presentintplus1,  
	predict fit_`c', xb
	
	reg time_c1toc2 `ctrls' if d_count==`c' & presentintplus1,  // time_c#toc# considers iwym; ignores missing response, should ideally condition also on being present in both time periods (and having a count in those time periods)	; curr only uses definition of    ; compare this to ordered logit; is this sequential logit?; n
	predict fit_`c', xb
	}
*	logit time_c2toc3 if d_count==2	& presentintplus1
*	logit time_c3toc4 if d_count==3 & presentintplus1
	
	

	
****************************************************************************************************
*Part X* ARCHIVE
****************************************************************************************************
	
	
	
/*** (lclass) latent class model using disease combinations ***
		keep if wave==3 // not sure yet how to deal with it in panel data

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
*/




