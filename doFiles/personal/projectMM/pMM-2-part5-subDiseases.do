*note: include this file into part5 of the data geneation file using -do- or -include- in Stata. -do- forgets the defined locals
*note: locals used in this file NEED to be defined inside this file if included using -do-. If included using -include-, this issue is not present.

**# Bookmark #1: important! Check that in your main do file the following operations occur in a previous step:
**#(note for ELSA: part5-subDiseases may be incorrect because other diseases are included in measure)

*rename 	hiper osteoer // hipe is used in replacement of osteoer


***********************
*** other variables ***
***********************
macro list 
di 	"`agethreshold' `h_data'"



************************
*** list of diseases ***
************************

**# Bookmark #2 (adding dementia reduces sample by about half due to missing responses to both tests)
	***dementia*** 
	sum 	tr20r orientr
	egen 	tr20rstd = std(tr20r)
	egen 	orientrstd = std(orientr)
	gen 	tr20r_wtd   = (tr20r +1) / 20 * 100
	gen  	orientr_wtd = (orientr +1) / 4 * 100
	egen 	cognition_total = rowtotal(tr20r_wtd orientr_wtd)
	egen 	cognitionstd1 = std(cognition_total)
	replace cognitionstd1 = . if mi(tr20r_wtd) | mi(tr20r_wtd)

	egen 	rowmiss = rowmiss(tr20r_wtd orientr_wtd)
	egen 	ts = rowtotal(tr20r_wtd orientr_wtd) // if rowmiss==0
	egen 	cognitionstd2 = std(ts) if rowmiss==0
	drop 	rowmiss 
	
	
		gen 	cognitionstd = tr20rstd
	*gen 	demener = (cognitionstd<0) if cognitionstd<. 
		qui sum cognitionstd, detail
		*local lower_quartile = r(p25)
		*sum `lower_quartile'
			_pctile cognitionstd, p(20)
			local 	qtile = r(r1)
			di "`qtile'"
		generate demener = cognitionstd < `qtile' if !mi(cognitionstd)
**# Bookmark #2 need to edit to onset being midpoint between 1st onset provided that at next OBSERVED period is still present (i do this below after generating d_demen I think this is better.). No, need to do here because onsetage will be based on this variable, not d_demener. Well, it no longer matters. The original definition of d_CODE came because it was a flexible generation of disease OR medication. This is no longer the case, so it no longer matters. However, for consistency, should recode demener and simply regenerate the same variable below as d_demen
	sort ID wave
	// bys ID (wave): replace demener = 0 if f.demener==0 & f.dead==0 // this is not complete, but should solve the problem except when there are gaps between time periods
		
	la var 	cognition_total "Cognition Total"
	*la var cognitionstd 	"std(total cognition)"
	la var  demener  		"has dementia"	

	gen 	rxdemenr = . 	// dementia medication missing
		gen 	radiagdemen = . // dementia self-report of onset missing

		
		
		
**# Bookmark #3 check once more, also think why even recode medication use as absorbing. this no longer makes sense, absorbing is done for osteoporosis because in SHARE we only have medication on it...
**# Bookmark #1 20241505: I have removed osteo from list due to SHARE missing osteoer
**# Bookmark #3 might have to double check that carry forward is working correctly when there are gaps

***to correct disease list (set as absorbing after onset, carry forward earlier report)**
local carryforwardlist "hibp diab heart lung  cancr strok arthr demen" // hiper psych (if disease is missing, block works nevertheless), osteo
foreach var of local carryforwardlist{
rename 		rx`var'r 	rx`var'r2 	
rename 		  `var'er  	  `var'er2  
clonevar	rx`var'r =  rx`var'r2
clonevar  	  `var'er  =  `var'er2
bys ID: 	replace rx`var'r = max(rx`var'r[_n-1], rx`var'r)  if inwt==1 // medication use !mi(rx`var'r): does not work well bc variable will be 0 if "ever had" is 0 and "medication" is missing
bys ID: 	replace `var'er  = max(  `var'er[_n-1],  `var'er) if inwt==1  // ever had: "onlyeverhad"	(should not replace in most surveys)
	**if someone does not have the disease, they should not report taking medications for it**
	recode rx`var'r (1=0) if !mi(rx`var'r) &  `var'er==0 /*only is recoded in ELSA and SHARE. This is due to
	correction of ever had reports that are not fed into medication use corrections in ELSA. In HRS, this 
	seems to be done already. In SHARE, question on medication is asked independently of ever had reports.*/ 
	replace rx`var'r = . if !mi(rx`var'r) &  `var'er==.  // should not change anything in HRS and ELSA
drop `var'er2 rx`var'r2
}

	
***either-or condition (ever had or medication use) ***
** r has disease: either "ever told by doctor" or "currently taking med for"**
local eitherorcodes "osteo" 
	loc eitherordlist ""
foreach var of local eitherorcodes { 
gen 	d_`var' = 	`var'er==1 | rx`var'r==1    if `var'er<. | rx`var'r<. 
	*gen 	d2_`var' = 	`var'er==1           	if `var'er<. /*to check that d_`var' gives the same result. if someone does not have the disease, they should not report taking medications for it*/
	*sum 	d_`var' d2_`var' // to check that d_`var' gives the same result. if someone does not have the disease, they should not report taking medications for it 
	// d_`var' and d2_`var' are not the same for "psych", bc CESD/test defines ever had condition, while medication use is only available if the respondent reports to have been diagnosed with a psychatric condition. 
	*loc   varlabel: var la `var'
	*local extracted_label = substr("`varlabel'", 11, .) // use this if full disease name
la var 	d_`var'	 	"'ever had'|using meds: `var'" // 
loc eitherordlist	"`eitherordlist' d_`var'" /*creates a local macro that appends new var at each iteration*/
}
*l ID wave d_osteo* osteo* rxosteo* if ID==958

	/**check to have used correct if-condition above: "if `var'er<. | rx`var'r<.": **
	**here we want to the variable to take value 1 if any of the two (ever had or taking meds) is 1 ///
	* , that is, ignoring the fact that there is a missing value in one of them (one could optionally ///
	* see if there is a nonrandom non-response of either category, or only take complete-cases (=hibp3)).
	gen d_hibp2 = (hibper==1 | rxhibpr==1) /*ignoring missing values (here treated as 0)*/
	gen d_hibp3 = (hibper==1 | rxhibpr==1) if hibper<. & rxhibpr<. /*set missing if both missing (>=.)*/
	gen d_hibp4 = (hibper==1 | rxhibpr==1) if hibper<. | rxhibpr<. /*set missing if either miss (= d_hibp above)*/
	tab d_hibp2 d_hibp3,m
	tab d_hibp3 d_hibp4,m
	sum hibper rxhibpr d_hibp if hibper<. & rxhibpr>=.			 /*check if either var missing*/
	sum hibper rxhibpr d_hibp if hibper>=. & rxhibpr<.		
	*bro ID wave hibper rxhibpr d_hibp* /*check whole sample*/
	*bro ID wave hibper rxhibpr d_hibp* if hibper>=. | rxhibpr>=. /*check which is correct: .m and
																   *other missings are "larger" than (.) */
	drop d_hibp2-d_hibp4 /*from this part, it is clear that d_hibp4 (=loop) is the correct of the variable*/
	*/
	
**# Bookmark #1 Dementia is not used as "doctor diagnosed" because definition difficult to make comparable across countries. Option B: could use different tests (but even then those are not consistent across time always)

**only ever had (these diseases have no medication)**
loc onlyeverhad 	"hibp diab heart lung 	depr   cancr strok arthr demen"	 // demen kidney psych
	loc onlyeverhadlist ""
foreach var of local onlyeverhad {
gen 	d_`var' = 	`var'er==1 	if `var'er<.	/*only one condition*/
la var 	d_`var' 	"'ever had' `var'"
loc onlyeverhadlist "`onlyeverhadlist' d_`var'" 
}

/**only medication (no "ever had")**
* note: severe osteoporitic disease can be defined as "self-reported hip-fracture OR taking meds for osteoporosis, hence renamed hibper to osteoer above"
* note: pay attention to if variable should be strictly increasing in time 
loc onlymed 	"osteo"
loc onlymedlist "rxosteor"
des `onlymedlist'
sum `onlymedlist'
foreach var of local onlymed {
gen d_`var' = rx`var'r==1       if rx`var'r<.  // `var'er==1 		// | 
}
*/

	**# Bookmark #1 ** reorder variables inside dataset 		
	order rx* d_*, after(age)	

**"any disease", # of diseases missing, # of diseases present, multimorbidity***
	*loc 	alldiseasesd 	""
	*loc 	alldiseasecodes ""
loc 	alldiseasesd "`eitherordlist' `onlyeverhadlist' `onlymedlist'"
	gl 	alldiseasesd "`alldiseasesd'" /*copy local into global for later use (outside of this do file)*/
loc 	alldiseasecodes "`eitherorcodes' `onlyeverhad' `onlymed'"
	gl 	alldiseasecodes "`alldiseasecodes'"
di 		"`alldiseasesd'" /*(!) check all diseases are shown: if one local is empty, this is simply ignored!*/
di 		"`alldiseasecodes'"
codebook `alldiseasesd', compact

egen 	d_miss 	= rowmiss(`alldiseasesd') /*counts number of diseases "missing" for each observation (row)*/
// replace d_miss 	= . if mi(d_count) // if mi(d_any) /*set count to (.) if no response to any disease (or dead) */
la var 	d_miss 		"# missing diseases"
tab 	d_miss wave,m 
*bro ID wave d_*
li 		ID wave age `alldiseasesd' d_miss     in 1/3
**# Bookmark #1 could add a variable for which disease is actually missing, maybe some diseases are based on age-threshold, hence they are always missing. need to check this.

su 		d_miss, meanonly 
local 	d_missmin = r(min) // for some dataset, one disease might always be missing bc not available 
egen 	d_count = rowtotal(`alldiseasesd') if d_miss==`d_missmin', missing /*(row) sum of the variables in varlist: only for obs w/ no missing D 
		(count should be missing only if all diseases *considered* are missing)*/
la var 	d_count 	"# diseases"					
tab 	d_count wave,m
tab 	d_count d_miss,m 

gen 	d_any = (d_count>0) if !mi(d_count)
// egen 	d_any 	= rowmax(`alldiseasesd')  // Observation (ID-wave) has any of the above diseases (this is wrong.: having 0 on d_any should only be defined if there is a nonmissing disease count)
// recode d_any=. if mi(d_count) // at most, could recode d_any to missing in such a case.
la var 	d_any 		"any disease"
li 		ID wave age `alldiseasesd' d_any d_count     in 1/3




**multimorbidity**
gen 	d_count_geq2 = d_count>=2 if !mi(d_count)
la var 	d_count_geq2 ">=2 diseases"	
tab 	d_count d_count_geq2	
li 		ID d_any d_miss d_count d_count_geq2 in 1/5
table 	(var) wave, statistic(mean d_any d_miss d_count d_count_geq2) stat(max d_any d_miss d_count d_count_geq2)

**index of disease**
loc 	d_countmax = wordcount("`alldiseasesd'") // total number of chosen/considered diseases
gen 	d_count_index = d_count / `d_countmax'
sum 	d_count_index, de 
replace d_count_index = 1 if dead==1 // this is similar to Borella Bullano, De Nardi (2024) Clustering.
la var 	d_count_index 		"disease index (=count/total diseases)"

**First difference in d_count: if one has c diseases, does he keep the disease or does it disappear again? **	
	**# Bookmark #1
	*bys ID: gen diff_d_count_forward = d_count[_n+1] - d_count 
	*la var 	diff_d_count_forward 	"1st diff (forward) of # of diseases"
bys ID: gen 	diff_d_count 	  = d_count - L.d_count
	*bys ID: gen 	diff_miss_d_count = d_count - L.d_count // accounts for gaps, e.g. if not responded in some wave
	*bys ID: replace	diff_miss_d_count = d_count - L2.d_count if L.d_count>=. & mi(diff_miss_d_count) /*L2 necessary if missing t (e.g. w3 in SHARE)*/  
	*bys ID: replace	diff_miss_d_count = d_count - L3.d_count if L2.d_count>=. & mi(diff_miss_d_count)
	*note: could go further, but if gaps are longer than 4-6y I no longer consider them "first" differences 
	*bro ID wave d_count diff_d_count diff_d_count_miss
la var 	diff_d_count 		"1st diff of # of diseases"
	*la var 	diff_miss_d_count	"1st diff of # of diseases: (L(t-2) used if L(t-1) missing) (=adj. for gaps)"
	*tab 	diff_d_count diff_miss_d_count,m
	*tab 	d_count 	 diff_miss_d_count,m
sum 	diff_d_count*

	**First difference in d_DISEASECODE: same as above**
	foreach code of local alldiseasecodes {	
	bys ID: gen diff_d_`code' 	= d_`code' - L.d_`code'
	la var 		diff_d_`code' 	"1st diff ('ever had' | medication) of d_`code'"	
	*tab diff_d_`code',m
	}

	**first difference in DISEASECODE (in some datasets the reports are not strictly increaing)**
	foreach code of local alldiseasecodes {	
	bys ID: gen diff_`code'er	= `code'er - L.`code'er /*r because variable ends with r*/
	la var 		diff_`code'er 	"1st diff ('ever had' - raw data) of `code'er"	
	*tab diff_`code',m
	}	
	
	/**first difference in DISEASECODE, accounting for missing responses in some time-period**
	foreach code of local alldiseasecodes {
	bys ID: gen 	diff_miss_d_`code'  = d_`code' - L.d_`code'
	bys ID: replace	diff_miss_d_`code'  = d_`code' - L2.d_`code' if L.d_`code'>=. & mi(diff_miss_d_`code')   
	bys ID: replace	diff_miss_d_`code'  = d_`code' - L3.d_`code' if L2.d_`code'>=. & mi(diff_miss_d_`code')
	la var 			diff_miss_d_`code' "1st diff ('ever had' | medication) (adj. for gaps) of d_`code'"	
	bys ID: gen 	diff_miss_`code'er  = `code'er - L.`code'er
	bys ID: replace	diff_miss_`code'er  = `code'er - L2.`code'er if L.`code'er>=. & mi(diff_miss_`code'er) 
	bys ID: replace	diff_miss_`code'er  = `code'er - L3.`code'er if L2.`code'er>=. & mi(diff_miss_`code'er)	
	la var 			diff_miss_`code'er	"1st diff (ever had - raw data) (adj. for gaps) of `code'"
	}	
	*/
	
	
*** check if any condition is perfectly predicted by age (based on age-eligiblity to the question) ***
log using 	"`out'logs/log-diseasebycohort.txt", text replace name(log)
foreach d of local alldiseasesd  {
tab agegrp5 `d'	,m /*if nothing is odd, would seem okay. If we have more people entering later 
(e.g. inw1==0 & inw2==1, or based on hacohort), this could lead to a jump in the graphs */
} 
log close log
*/


**any disease at baseline (= when first observed)**
gen 	myvar = (d_any==1 & wave==inw_first) if d_any<. /*if any D and time is equal to first observed time*/
bys ID: egen d_anyatfirstobs = max(myvar)
drop 	myvar
la var 	d_anyatfirstobs "has disease at baseline"
tab 	d_anyatfirstobs  d_any if wave==1 	/*checked correct generation*/
sum 	d_anyatfirstobs 

**>=2 diseases at baseline (= when first observed)**
gen 	myvar = (d_count>=2 & wave==inw_first) if d_count<. /*if has MM and time is equal to first observed time*/
bys ID: egen d_count_geq2atfirstobs = max(myvar)
la var 	d_count_geq2atfirstobs ">=2 diseases at baseline"
drop 	myvar


**age of first onset (g2aging version - self-reported age at first diagnosis) (if available)**
di 	"`alldiseasecodes'"
	loc 	radiaglist "" 
foreach v of local alldiseasecodes {		
loc 	radiaglist "`radiaglist' radiag`v'" 
}
di 		"`radiaglist'" /*same list as `d_agediag' in harmon file*/
sum 	`radiaglist'
egen 	onsetage_g2 = rowmin(`radiaglist') 	/*earliest reported age for any of the diseases*/
la var 	onsetage_g2 "age of first onset (g2aging)"
li 		ID wave d_any age onsetage onsetage_g2 in 10/20

**# Bookmark #2 age of second onset (g2aging version)
// I have this code. This finds the earliest age of the variables radiaglist. 
// Now I want to do something similar, but to compute a cumulative number of diseases at each age. 
// For example, if at age 30 there are 2 possible diseases, then 




**any disease ever (observed)**
bys ID: egen d_anyever = max(d_any) // ever reported having a disease
la var 	d_anyever 		"ever experiences any disease"

**any disease ever (g2aging)**
gen 	d_anyever_g2 = (onsetage_g2<.) /*note: firstage_g2 is time-constant*/
la var 	d_anyever_g2	"ever experiences any disease (g2aging)"
sum 	d_anyever d_anyever_g2



**first onset year** 
gen 	myvar = time if d_any==1 
bys ID: egen onsetyear = min(myvar)
la var 	onsetyear 	"year of first onset (observed) (censored)"
drop	myvar 
sort 	ID wave
li 		ID wave age d_any onsetyear in 1/16 /*check correct generation*/
// clonevar onsetyear_uncens = onsetyear // (NOT OKAY maybe IN HRS SINCE WAVES DROPPED)
// replace  onsetyear_uncens = . if d_anyatfirstobs>0 & !mi(d_anyatfirstobs)
la var 	 onsetyear "year of first onset (observed) (uncensored)"



**first onset age (any chronic disease observed)**
**# Bookmark #1 replace firstage varname with onset_age
gen 	myvar 		= age if d_any==1 /*age, if any disease is present*/
bys ID: egen onsetage = min(myvar)
la var 	onsetage 		"age of first onset (obs.) (censored)"
drop 	myvar
sort 	ID wave
li 		ID wave age d_any onsetage in 1/16 /*check correct generation*/
// clonevar onsetage_uncens = onsetage
// replace  onsetage_uncens = . if d_anyatfirstobs>0 & !mi(d_anyatfirstobs)
// la var 	 onsetage_uncens 	"age of first onset (obs.) (uncens. part)"
	* bro ID wave time tsinceonset timesinceonset onsetyear
	
	egen 	onsetagegrp5 = cut(onsetage),    at (`agethreshold',55,60,65,70,120) // ,80, 	
	recode  onsetagegrp5 (`agethreshold' = 50)
	replace onsetagegrp5 = . if d_anyatfirstobs==1 
	loc 	labelname "onsetage:"
	la de 	onsetagegrp5l 	50  "`labelname' `agethreshold'-54" 55 "`labelname' 55-59" 60 "`labelname' 60-64" 65 "`labelname' 65-69" 70 "`labelname' 70+" // 75 "`labelname' 75+" 
	la val 	onsetagegrp5 onsetagegrp5l
	*tab onsetagegrp5,m
	
**# Bookmark #1 first onset age (of higher order count) (should do with radiag)
	** first onset age (of higher order count) **
	gen 	myvar 			= age if d_count==2 
	bys ID: egen onsetage2d = min(myvar)
	la var 	onsetage2d 		"age of first onset (of 2D) (observed)" //  (censored)	
	drop 	myvar
	gen 	myvar 			= age if d_count==3
	bys ID: egen onsetage3d = min(myvar)
	la var 	onsetage3d 		"age of first onset (of 2D) (observed)" // (observed) (censored)	
	drop 	myvar


**age at first onset, for each disease separately:**
di 		"`alldiseasesd'"
loc 	onsetlist "" 	
foreach d of local alldiseasesd {
gen 	myvar 			= age if `d'==1
bys ID: egen onset`d' 	= min(myvar)
drop 	myvar
	bys ID: egen `d'ever = max(`d') // ever reported having a disease
	la var 		 `d'ever "ever has (between t and T) D: `d'"
	sum onset`d' if `d'ever == 0 		 // if never had disease, onsetage should be missing (zero here)  
	replace onset`d' = .m if `d'ever == 0 // and replace these cases to special missing value .m
	drop  `d'ever 
la var 	onset`d' "age at 1st onset (obs.) - `d'"
loc 	onsetlist 	"`onsetlist' onset`d'" 
/*/ make generate uncensored part for each variable 
gen 	onset`d'_uncens = onset`d' 
replace onset`d'_uncens = . if onset`d' == ageatfirstobs
la var 	onset`d'_uncens "age at 1st onset (obs.) - `d' (uncens)"
*/
}
li 		ID wave age onsetage onsetage_* in 1/2 
codebook onset*, compact /*this is the first onset for each disease separately, but a different 
								age could also be the result of the one disease "missing", while others 
								were present in a given year. To remedy this issue, should delete
								observations who had one or more missing diseases.*/
*/								


/**first onset DATE for each disease "count"**
di 		   "`d_countmax'" /*max. count of diseases defined above*/
forval 	j=1/`d_countmax' { /*use maximum count of disease list*/
gen 		 myvar	= iwym if d_count>=`j' & !mi(d_count) /*iw date if C disease(s) present: only uses obs with no missing count*/
bys ID: egen onsetdate_c`j' 	= min(myvar)
format 		 onsetdate_c`j' %tm
drop 		 myvar
la var 		 onsetdate_c`j' "first date of iw with (>=`j') diseases"
}
li 			ID wave dead d_count iwym onsetdate_c* in 100/116, compress nola /*check*/
*/


*****************
*** Durations ***
*****************
**# Bookmark #2 tsinceonset and timesinceonset have different nobs, check why
**duration since onset (TIME)** 
gen 	tsinceonset = time - onsetyear if inwt==1
la var 	tsinceonset "time (periods) since first disease"	

// gen 	timesinceonset = iwym - onsetdate_c1 if (iwym - onsetdate_c1>=0)
// la var 	timesinceonset "time (months) since first disease"	

**duration since onset (AGE)** 
gen 	yearssinceonset = age - onsetage 
la var 	yearssinceonset "years since onset"

sum  tsinceonset yearssinceonset
*bro ID wave time tsinceonset timesinceonset onsetyear

/**duration from c to c+1[+ / or more]** 
*note: [there may be gaps of nonresponse, i.e. diseases could jump from 1 to 4 or 2 to 7, because either nonresponse or jump from c to c+2]: if panel not balanced in disease count or there is a real jump, this could cause additional imprecision*
*note: some people have x count at t, then x-1 count at t+1*
forval 	j=2/`d_countmax'{
loc 		i=`j'-1
gen 		time_c`i'toc`j' = onsetdate_c`j'-onsetdate_c`i'
la var 		time_c`i'toc`j' "months (observed) `i' to `j'+ diseases"
}
li 			ID wave iwym d_count onsetdate_c? time_c?toc? in 85/100 , compress
li 			ID wave iwym d_count onsetdate_c? time_c?toc? in 50/100 if (inw_miss==0 | everdead==1), compress
*/

/**duration from c to c+1 [+ / or more] (time-varying single variable)**	
**note: with and without adjusting for firstdate>=iwym**
gen timetonextdisease  = .
gen timetonextdisease2 = .
forval 	j=1/`d_countmax'{
loc 	i=`j'-1
replace timetonextdisease  = -iwym + onsetdate_c`j' if d_count==`i'	
replace timetonextdisease2 = -iwym + onsetdate_c`j' if d_count==`i' & onsetdate_c`j'>= iwym /*set timetonextdisease2 to missing if firstdate with some count is smaller than the current date / e.g. if had 2 diseases, then after that went back to 1*/
}	
la var timetonextdisease2 "time (months) from C to C+1 (or more) diseases"
sum timetonextdisease*, de
	li ID wave d_count iwym onsetdate_c? timetonextdisease* time_c1toc2 time_c2toc3 if ID==785 // when the disease count decreases, timetonextdisease2 is missing
	sum timetonextdisease* time_c1toc2 if d_count==1
	*bro ID wave d_count iwym timetonextdisease* time_c1toc2
	*bro ID wave d_count iwym firstdate_c? timetonextdisease*  	
	*bro ID wave d_count iwym firstdate_c? timetonextdisease* if sbalanced 	
	*bro ID wave d_count iwym firstdate_c? timetonextdisease* if sbalanced & timetonextdisease<0	
	// timetonextdisease can be negative if count decreases from t to t+1
	// currently, timetonextdisease2 still ignores the dose: it treats time from 1 to 2 the same as 1 to 4 (2nd accumulates faster) || if sb jumps from 2 to 4, firstdate_c3 is equal to firstdate_c4 anyway || hence, this measure is simple "to next '1 or more' diseases"
*/



/**duration from *first* onset to death (in years)**
gen 	time_onsettodeath =  (radym - onsetdate_c1)/12
*gen 	time_onsettodeathx = (raxym - firstdate_c1)/12 
la var 	time_onsettodeath "years first onset to death (observed)" 
*la var time_onsettodeathx "years first onset to death (observed) (eol module)" 

*bro ID wave radyear raxyear time_ons* firstyear_c1 firstdate_c1 d_any if time_onsettodeathx<0 /*using rad seems more correct than rax, bc no negative values*/
gen 	time_onsettodeath_age	 = radage-onsetage 
gen 	time_onsettodeath_age_g2 = radage-onsetage_g2
*sum 	radage radyear radmonth raxyear raxmonth time_onsetto*
li 		ID wave iwym dead d_count onsetdate_c1 onsetdate_c2 ra?ym time_onsettodeath* in 1/16, compress nola
*bro 	ID wave iwym dead d_count firstdate_c1 firstdate_c2 ra?ym time_onsettodeath*  if time_onsettodeath<0
*++	
*/

/**duration from *first* onset to death**
gen 	time_onsettodeath =  radym-firstdate_c1
gen 	time_onsettodeathx = raxym-firstdate_c1 // using rax variable
replace time_onsettodeath =  time_onsettodeath/12 // convert to years
replace time_onsettodeathx = time_onsettodeathx/12
la var 	time_onsettodeath "years first onset to death (observed)" 
*bro ID wave radyear raxyear time_ons* d_firstyear_c1 firstdate_c1 d_any if time_onsettodeathx<0 /*using rad seems more correct than rax, bc no negative values*/
gen 	time_onsettodeath_age		= radage-firstage 
gen 	time_onsettodeath_age_g2 	= radage-firstage_g2
sum 	radage radyear radmonth raxyear raxmonth time_*
li 		ID wave iwym dead d_count firstdate_c1 firstdate_c2 ra?ym time_onsettodeath* in 1/16, compress nola
*bro 	ID wave iwym dead d_count firstdate_c1 firstdate_c2 ra?ym time_onsettodeath*  if time_onsettodeath<0
*++
*/	

/**comparison ageatdeath with g2aging variable radage: not identical. why?**
gen 	ageatdeath = radym - rabym
replace ageatdeath = ageatdeath/12
gen 	ageatdeathx = raxym - rabym /*generally rax is correct*/
replace ageatdeathx = ageatdeathx/12
sum 	ageatdeath ageatdeathx radage
drop 	ageatdeath ageatdeathx
*++
*/

*******************
*** Transitions ***
*******************
** disease count in next period: d_count_lead (add mortality as outcome) **
gen 	d_count2 = d_count 
replace d_count2 = 99 if dead==1 
bys ID: gen d_count_lead = f.d_count2       if inwt==1 // only use the lead if present in wave
*bys ID: replace d_count_lead = f2.d_count2 if d_count_lead ==. // it jumps basically here bc 1 gap is allowed
la var d_count_lead "# diseases in next period" // (gaps are ignored)
la de  d_count_leadl 99 "dead" // add dead label to 99
la val d_count_lead d_count_leadl
drop   d_count2 
*bro ID wave d_count d_count_lead dead
**# Bookmark #1 temporarily recode dead to missing
	recode d_count_lead (99=.)


**************
*** Groups ***
**************
** countatfirstobs and countatonset ** 
gen 	tempvar = d_count if inw_first==wave 		// count at baseline
bys ID: egen countatfirstobs = max(tempvar) 
recode 	countatfirstobs (0 = 0 "0 diseases at baseline") (1 = 1 "1 disease at baseline") (2/3 = 2 "2/3 diseases at baseline") (4/10 = 4 "4+ diseases at baseline"), gen(countatfirstobs2)
drop 	tempvar countatfirstobs
rename 	countatfirstobs2 countatfirstobs 
la var countatfirstobs "# diseases when first observed"

// gen 	tempvar = d_count if timesinceonset==0 // count at onset
// bys ID: egen countatonset = max(tempvar) 
// replace countatonset =. if age<onsetage 		// if first onset not experienced yet, should not include
// recode 	countatonset (1/2 = 1 "1 or 2 diseases at onset") (3/4 = 2 "3 or 4 diseases at onset") (5/15 = 3 "5 or more at onset"), gen(countatonset2)
// drop 	tempvar countatonset
// rename 	countatonset2 countatonset 



