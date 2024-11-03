/**#use only observations before a transition ** 
bys ID (duration): egen durationmax = max(duration)
replace duration = . if duration!= durationmax	// 
drop durationmax
*/

*******************************
** Out of sample predictions **
*******************************
**recode age and timesincefirstobs if too few observations fall in this category and SEs large (for agemin<=70 sample**
levelsof agegrpmin5, local(levels)
foreach  cohort of   local levels {
qui 	sum time, meanonly 
loc 	timerange = r(max)-r(min)+5 /*maximum time an id is observed (5 added for cohort)*/
replace age = `cohort'+`timerange' if age >`cohort'+`timerange' & age<. & agegrpmin5==`cohort' 
replace timesincefirstobs = `timerange'-5 if timesincefirstobs<. & timesincefirstobs>`timerange'-5
} 
di 		"`timerange'"

	*sample 20
loc 	y 			"d_count"
loc 	ylabel: 	var label `y'
loc 	cat  	  	"agegrpmin5" // male, raeducl, countatfirstobs
loc 	timevar 	"c.age" 
*loc 	xla 		"xla(50(5)90)" /*needed for separate sub-plots*/
loc 	opt_marginsplot "ytitle("Predicted (`ylabel')")" // noci  
// loc 	ctrls  "`ctrl'"
	loc ctrls "male i.raeducl"

*overall plot by cohort groups (continuous time)* 
	log using 	"$outpath/logs/log-reg_byage_d_count_outofsample.txt", text replace name(log) 
loc 	reg  		reg `y' `timevar'##`cat' `ctrls'  if `sample'==1 
 `reg'
	log close log
*qui margins `timevar'#`cat' 
qui margins `cat', at(age=(30(5)90)) 
marginsplot,  `opt_marginsplot'   `xla'  title("Prediction from linear fit using age") note("Sample: `samplelabel' | Controls: `ctrls' (none)" "Model: `reg'") name(g`cat'_`cohort', replace) yline(0) // by(agegrpmin5) 
gr export 	"$outpath/fig/main/g_reg_byage_d_count_outofsample.jpg", replace	quality(100)
	STOP
	


