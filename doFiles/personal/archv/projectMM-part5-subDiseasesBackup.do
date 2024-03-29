************************
*** list of diseases ***
************************

***either-or condition***
** r has disease: either "ever told by doctor" or "currently taking med for"**
local eitheror "hibp diab heart lung psych osteo" 
foreach var of local eitheror { 
	**# Bookmark #C recording variable as strictly increasing: 
	clonevar	rx`var'r2 = rx`var'r // generate strictly increasing (in time) medication use
	bys ID: 	replace rx`var'r2 = max(rx`var'r2[_n-1], rx`var'r2) if inwt==1 // medication use !mi(rx`var'r): does not work well bc variable will be 0 if "ever had" is 0 and "medication" is missing
gen 	d_`var' = 	`var'er==1 | rx`var'r2==1           if `var'er<. | rx`var'r2<. 
la var 	d_`var'	 	"ever had | taking meds for `var'"
loc eitherorlist	"`eitherorlist' d_`var'" /*creates a local macro that appends new var at each iteration*/
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

	

**# Bookmark #2 Note: left out kidney in first analysis in SHARE because this is available only from w6-w8, messing up d_miss
**only ever had (these diseases have no medication)**
loc onlyeverhad 	"cancr strok arthr"		  // kidney
foreach var of local onlyeverhad {
**# Bookmark #C2
	*bys ID: replace `var'er = max(`var'er[_n-1], `var'er) if inwt==1  // ever had: Change also in "onlyeverhad"
gen 	d_`var' = 	`var'er==1 	if `var'er<.	/*only one condition*/
la var 	d_`var' 	"(only) ever had `var'"
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
// 	* Step 1: Get a list of all variables that start with "rx"
// 	unab rxvars: rx*
// 	* Step 2: Get a list of all variables that start with "d_"
// 	unab dvars: d_*
// 	* Step 3: Order "rx*" variables before "d_*" variables
// 	foreach var of local rxvars {
// 		order `var', before(`dvars')
// 	}	
	order rx* d_*, after(age)
		
		
		

**"any disease", # of diseases missing, # of diseases present, multimorbidity***
loc 	alldiseases "`eitherorlist' `onlyeverhadlist' `onlymedlist'"
loc 	alldiseasecodes "`eitheror' `onlyeverhad' `onlymed'"
di 		"`alldiseases'" /*(!) check all diseases are shown: if one local is empty, this is simply ignored!*/
di 		"`alldiseasecodes'"
codebook `alldiseases', compact

egen 	d_any 	= rowmax(`alldiseases') // Observation (ID-wave) has any of the above diseases
la var 	d_any 		"any disease"

egen 	d_miss 	= rowmiss(`alldiseases') /*counts number of diseases "missing" for each observation (row)*/
replace d_miss 	= . if d_any>=. /*set count to (.) if no response to any disease (or dead) */
la var 	d_miss 		"# miss.diseases"
tab 	d_miss wave,m 
li 		ID wave age `alldiseases' d_any d_miss     in 1/3

su 		d_miss, meanonly
local 	d_missmin = r(min) // number of chosen diseases, max of variable
egen 	d_count = rowtotal(`alldiseases') if d_miss==`d_missmin', missing /*(row) sum of the variables in varlist
													:only for obs w/ no missing D (among those considered)*/
la var 	d_count 	"# diseases"					
tab 	d_count wave,m
tab 	d_count d_miss,m 
li 		ID wave age `alldiseases' d_any d_count     in 1/3


**multimorbidity**
gen 	d_count_geq2 = d_count>=2 if !mi(d_count)
la var 	d_count_geq2 ">=2 diseases"	
tab 	d_count d_count_geq2	
li 		ID d_any d_miss d_count d_count_geq2 in 1/5
table 	(var) wave, statistic(mean d_any d_miss d_count d_count_geq2) stat(max d_any d_miss d_count d_count_geq2)


**index of disease**
loc 	d_countmax = wordcount("`alldiseases'") // total number of chosen/considered diseases
gen 	d_count_index = d_count / `d_countmax'
sum 	d_count_index, de 
la var 	d_count_index 		"disease index (=count/total diseases)"

**First difference in d_count: if one has c diseases, does he keep the disease or does it disappear again? **	
bys ID: gen 	diff_d_count 	  = d_count - L.d_count
bys ID: gen 	diff_miss_d_count = d_count - L.d_count // accounts for gaps, e.g. if not responded in some wave
bys ID: replace	diff_miss_d_count = d_count - L2.d_count if L.d_count>=. & mi(diff_miss_d_count) /*L2 necessary if missing t (e.g. w3 in SHARE)*/  
bys ID: replace	diff_miss_d_count = d_count - L3.d_count if L2.d_count>=. & mi(diff_miss_d_count)
*note: could go further, but if gaps are longer than 4-6y I no longer consider them "first" differences 
*bro ID wave d_count diff_d_count diff_d_count_miss
la var 	diff_d_count 		"1st diff of # of diseases"
la var 	diff_miss_d_count	"1st diff of # of diseases: (L(t-2) used if L(t-1) missing)"
tab 	diff_d_count diff_miss_d_count,m
tab 	d_count 	 diff_miss_d_count,m
sum 	diff_d_count*

	**First difference in d_DISEASECODE: same as above**
	foreach code of local alldiseasecodes {	
	bys ID: gen diff_d_`code' 		= d_`code' - L.d_`code'
	tab diff_d_`code',m
	}

	**first difference in DISEASECODE (in some datasets the reports are not strictly increaing)**
	foreach code of local alldiseasecodes {	
	bys ID: gen diff_`code'er		  = `code'er - L.`code'er /*r because variable ends with r*/
	tab diff_`code',m
	}	
	
	**first difference in DISEASECODE, accounting for missing responses in some time-period**
	foreach code of local alldiseasecodes {
	bys ID: gen diff_miss_d_`code'  = d_`code' - L.d_`code'
	bys ID: replace	diff_miss_d_`code'  = d_`code' - L2.d_`code' if L.d_`code'>=. & mi(diff_miss_d_`code')   
	bys ID: replace	diff_miss_d_`code'  = d_`code' - L3.d_`code' if L2.d_`code'>=. & mi(diff_miss_d_`code')
	la var 	diff_miss_d_`code' "1st diff of `code' (raw data)"	
	bys ID: gen diff_miss_`code'er  = `code'er - L.`code'er
	bys ID: replace	diff_miss_`code'er  = `code'er - L2.`code'er if L.`code'er>=. & mi(diff_miss_`code'er) 
	bys ID: replace	diff_miss_`code'er  = `code'er - L3.`code'er if L2.`code'er>=. & mi(diff_miss_`code'er)	
	la var 	diff_miss_`code'er	"1st diff of d_`code' (ever had | medication)"
	}
	
	
	
	
**age at first onset (any chronic disease observed)**
gen 	myvar 		= age if d_any==1 /*age, if any disease is present*/
bys ID: egen d_firstage = min(myvar)
drop 	myvar
sort 	ID wave
li 		ID wave age d_any d_firstage in 1/16 /*check correct generation*/
la var 	d_firstage 	"age of first onset (observed)"


	**age at first onset, for each disease separately:**
	foreach d of local alldiseases {
	gen 	first_age 		= age if `d'==1
	bys ID: egen d_firstage_`d' = min(first_age)
	drop 	first_age
	la var 	d_firstage_`d' "age of first onset (observed) for `d'"
	loc 	d_firstagelist "`d_firstagelist' d_firstage_`d'" 
	}
	li 		ID wave age d_firstage d_firstage_* in 1/2 
	codebook d_firstage_*, compact /*this is the first onset for each disease separately, but a different 
									age could also be the result of the one disease "missing", while others 
									were present in a given year. To remedy this issue, should delete
									observations who had one or more missing diseases.*/
	
**age of first onset (g2aging version - self-reported age at first diagnosis)**
**# Bookmark #1
	*loc 	locallist "`alldiseasecodes'" 
	*di 	"`locallist'"
	*foreach v of local locallist {
di 	"`alldiseasecodes'"
foreach v of local alldiseasecodes {		
loc 	radiaglist "`radiaglist' radiag`v'" 
}
di 		"`radiaglist'" /*same list as `d_agediag' in harmon file*/
sum 	`radiaglist'
egen 	d_firstage_g2 = rowmin(`radiaglist') 	/*earliest reported age for any of the diseases*/
la var 	d_firstage_g2 "age of first onset (g2aging)"
li 		ID wave d_any age d_firstage d_firstage_g2 in 10/20

**any disease at baseline (= when first observed)**
gen 	myvar = (d_any==1 & wave==inw_first) if d_any<. /*if any D and time is equal to first observed time*/
bys ID: egen d_anyatfirstobs = max(myvar)
drop 	myvar
la var 	d_anyatfirstobs "already has disease at baseline"
tab 	d_anyatfirstobs  d_any if wave==1 	/*checked correct generation*/
sum 	d_anyatfirstobs 

**any disease ever (observed)**
bys ID: egen d_anyever = max(d_any) // ever reported having a disease
la var 	d_anyever 		"ever reports any disease"

**any disease ever (g2aging)**
gen 	d_anyever_g2 = (d_firstage_g2<.) /*note: d_firstage_g2 is time-constant*/
la var 	d_anyever_g2	"ever reports having had any disease (g2aging)"
sum 	d_anyever d_anyever_g2


	
*****************
*** Durations ***
*****************
**first onset DATE for each disease "count"**
di 		   "`d_countmax'" /*max. count of diseases defined above*/
forval 	j=1/`d_countmax' { /*use maximum count of disease list*/
gen 		 myvar	= iwym if d_count>=`j' & !mi(d_count) /*iw date if C disease(s) present: only uses obs with no missing count*/
bys ID: egen d_firstdate_c`j' 	= min(myvar)
format 		 d_firstdate_c`j' %tm
drop 		 myvar
la var 		 d_firstdate_c`j' "first date of iw with (>=`j') diseases"
}
li 			ID wave dead d_count iwym d_firstdate_c* in 100/116, compress nola /*check*/

**duration from c to c+1[+ / or more]** 
*note: [there may be gaps of nonresponse, i.e. diseases could jump from 1 to 4 or 2 to 7, because either nonresponse or jump from c to c+2]: if panel not balanced in disease count or there is a real jump, this could cause additional imprecision*
*note: some people have x count at t, then x-1 count at t+1*
forval 	j=2/`d_countmax'{
loc 		i=`j'-1
gen 		time_c`i'toc`j' = d_firstdate_c`j'-d_firstdate_c`i'
la var 		time_c`i'toc`j' "months (observed) `i' to `j'+ diseases"
}
li 			ID wave iwym d_count d_firstdate_c? time_c?toc? in 85/100 , compress
li 			ID wave iwym d_count d_firstdate_c? time_c?toc? in 50/100 if (inw_miss==0 | everdead==1), compress

**duration from c to c+1 [+ / or more] (time-varying single variable)**	
**note: with and without adjusting for firstdate>=iwym**
gen timetonextdisease  = .
gen timetonextdisease2 = .
forval 	j=1/`d_countmax'{
loc 	i=`j'-1
replace timetonextdisease  = -iwym + d_firstdate_c`j' if d_count==`i'	
replace timetonextdisease2 = -iwym + d_firstdate_c`j' if d_count==`i' & d_firstdate_c`j'>= iwym /*set timetonextdisease2 to missing if firstdate with some count is smaller than the current date / e.g. if had 2 diseases, then after that went back to 1*/
}	
la var timetonextdisease2 "time (months) from C to C+1 (or more) diseases"
sum timetonextdisease*, de
	li ID wave d_count iwym d_firstdate_c? timetonextdisease* time_c1toc2 time_c2toc3 if ID==785 // when the disease count decreases, timetonextdisease2 is missing
	sum timetonextdisease* time_c1toc2 if d_count==1
	*bro ID wave d_count iwym timetonextdisease* time_c1toc2
	*bro ID wave d_count iwym d_firstdate_c? timetonextdisease*  	
	*bro ID wave d_count iwym d_firstdate_c? timetonextdisease* if sbalanced 	
	*bro ID wave d_count iwym d_firstdate_c? timetonextdisease* if sbalanced & timetonextdisease<0	
	// timetonextdisease can be negative if count decreases from t to t+1
	// currently, timetonextdisease2 still ignores the dose: it treats time from 1 to 2 the same as 1 to 4 (2nd accumulates faster) || if sb jumps from 2 to 4, d_firstdate_c3 is equal to d_firstdate_c4 anyway || hence, this measure is simple "to next '1 or more' diseases"

	

/**duration from *first* onset to death**
gen 	time_onsettodeath =  radym-d_firstdate_c1
gen 	time_onsettodeathx = raxym-d_firstdate_c1 // using rax variable
replace time_onsettodeath =  time_onsettodeath/12 // convert to years
replace time_onsettodeathx = time_onsettodeathx/12
la var 	time_onsettodeath "years first onset to death (observed)" 
*bro ID wave radyear raxyear time_ons* d_firstyear_c1 d_firstdate_c1 d_any if time_onsettodeathx<0 /*using rad seems more correct than rax, bc no negative values*/
gen 	time_onsettodeath_age		= radage-d_firstage 
gen 	time_onsettodeath_age_g2 	= radage-d_firstage_g2
sum 	radage radyear radmonth raxyear raxmonth time_*
li 		ID wave iwym dead d_count d_firstdate_c1 d_firstdate_c2 ra?ym time_onsettodeath* in 1/16, compress nola
*bro 	ID wave iwym dead d_count d_firstdate_c1 d_firstdate_c2 ra?ym time_onsettodeath*  if time_onsettodeath<0
*++
*/	

/**comparison ageatdeath with g2aging variable radage: not identical. why?**
gen 	ageatdeath = radym - rabym
replace ageatdeath = ageatdeath/12
gen 	ageatdeathx = raxym - rabym /*generally rax is correct*/
replace ageatdeathx = ageatdeathx/12
sum 	ageatdeath ageatdeathx radage
drop 	ageatdeath ageatdeathx
++
*/
