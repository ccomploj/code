capture log close
clear all
set more off
log close _all			// closes all log files
pause on				// turns pauses on (a pause does not interrupt local memory)
pause off
set maxvar 15000
timer on 1 				// counts the duration of file computation


***packages needed for file to run***
*	ssc install isvar

****************************************************************************************************
*Title: Harmonization file of HRS-type datasets harmonized by Gateway2Aging (www.g2aging.org)
*Summary: constructs main data from the HRS data g2aging version by selecting relevant variables and reshaping to a panel (ID-wave)
*Date: 16-07-2023
*Author: Castor Comploj
*Date Created: 13-07-2023
*Note: If you suggest a change, or the file is not suitable for your HRS-type survey, create a pull request for changes on Github directly or email me at castorcomploj@protonmail.com
****************************************************************************************************
***Special Notes***
**note: After running the file, most variable names end with r, s, h or hh. r refers to respondent and s refers to spouse. h (hh) refers to household.** 
**note: there are two types of variables in the g2aging data: time-varying and time-invariant.** 



****************************************************************************************************
*PART 1*: Adapt this section to the specific HRS-type harmonized dataset from the g2aging
*note: you do not have to change any other section except "Part 1", and the variables in "Part 3"
****************************************************************************************************
***define folder locations***
loc data 		"SHARE" // SHARE | ELSA (note for ELSA part5-subDiseases may be incorrect because other diseases are present)
		if "`c(username)'" == "P307344" { // UWP server
		loc cv 		"X:/My Documents/XdrvData/`data'/"
		*gl  outpath "\\Client\C$\Users\User\Documents\GitHub\2-projectMM-`data'\files"
		}
		else {
		loc	cv 		"G:/My Drive/drvData/`data'/"
		*gl 	outpath "C:/Users/User/Documents/GitHub/2-projectMM-`data'/files" 	
		}
loc h_data 		"`cv'`data'data/harmon/" 		  // harmonized data folder location
loc out 		"`cv'`data'output/"				  // output folder location

cd "`cv'"
pwd


***Bringing in Core Data***
**Harmonized data**
use 	"`h_data'H_SHARE_f.dta"  			// choose dataset

**End of Life Survey** /*(not required to use for file to run)*/ 
loc 	x_eol "raxyear raxmonth radage radmarr radmarrp" /*merge eol vars*/
merge 	1:1 mergeid using "`h_data'H_SHARE_EOL_c.dta", keepusing(`x_eol')


*pause // browse the data using -browse- ; to continue after a pause, type "q" and enter

**other data**
*[append other datasets (e.g. from individual waves of HRS-type study) using the available identifiers]

**generate specific identifiers**
gen 	countryID 	= substr(mergeid, 1,2) 
gen 	id  		= hhid + pn 				// note id is not unique
egen	panelid 	= group(countryID id)	

***define identifiers*** 	// find these using -browse- 
loc cntry  		"countryID" // insert country ID if multi-country dataset
loc cnty 	 	""			// insert county 	ID if available
loc communityID "" 		 	// insert community ID if available 
loc householdID "hhid" 	 	// insert household ID
loc pn 			"pn"		// insert person identifier
loc ID 			"mergeid"	// insert personal ID (household ID + personal ID)
loc ID 			"panelid"	// use panelid if ID does not uniquely identify individual (same ID in two count(r)ies)
loc idlist 		"`cntry' `cnty' `communityID' `householdID' `pn' `ID'" 
***define other survey-specific values*** 
loc wavelast 	"8"			// change this to the # of the last available wave (e.g. 8 if 8 waves, 4 if 4 waves)

pause // to continue after a pause, type "q" and enter; browse the data using -browse-


	***correction to (in)waves in SHARE***
	tab inw7 inw7c,m /*all who responed to w7 also responded to w7c (same questions), w7c also includes some who did not complete all of w7*/
	tab inw7 inw7sc,m  /*7sc includes people from w7*/
	tab inw7sc inw7c,m /*7c is condensed form*/
	sum inw7*
	tab inw7 inw7c if !mi(r7agey) /*so inw7c would be the correct version, as it includes 
	all those who were present in wave 7. This is not very important though. If we have variable r7agey, 
	it will show up in reshaped dataset. It is important for the definition of how many waves an ID has 
	participated in. So, for the purpose of this measure, I drop inw7, because the condensed questionnaire 
	should suffice for most purposes. disease are present in this dataset, but this should be checked for 
	all variables of interest*/
	drop inw7

	***log entire file***
	*log using 	"`h_data'logdoSHARE-1-harmon.txt", text replace name(logDofile) // ends w/ -log close logDofile-
	log using 	"`out'/logdoSHARE-1-harmon.txt", text replace name(logDofile) // ends w/ -log close logDofile-
	*log using 	"G:/My Drive/projects/projectMultimorbidity/outfiles/logs/logdoSHARE-1-harmon.txt", text replace name(logDofile) // ends w/ -log close logDofile-

****************************************************************************************************
*Part 2*: Overview of dataset
****************************************************************************************************
order `idlist', alphabetic

/***count the number of unique IDs***
count
preserve
contract `ID' 
count
restore
*/

/***destring ID variables when numeric (if needed) (note: does not work with non-numeric identifiers)***
foreach id of local idlist {
destring `id', replace		// create number format of identifiers, from string 
loc idlist2 "`idlist' `id'"
}
order `idlist2', alphabetic
*/

*pause 

****************************************************************************************************
*Part 3*: Choose variables and reshape from 'wide' to 'long'
****************************************************************************************************
***move r, h, hh indicators at the end of varname (for reshape operation)***
*describe r* h* hh*, simple
rename 	(r(##)*) (*[2]r#[1])		// respondent
rename 	(r(#)*) (*[2]r#[1])		// respondent
rename 	(h(##)*) (*[2]h#[1])		// household
rename 	(h(#)*) (*[2]h#[1])		// household
rename 	(hh(#)*) (*[2]hh#[1]) 	// household
rename 	(s(##)*) (*[2]s#[1])	 	// spouse
rename 	(s(#)*) (*[2]s#[1])	 	// spouse
*describe r* h* hh* s*  , simple	  



pause
	
***select variables of interest (by section in harmon manual)***
**note: select first (a) time-varying variables. Below at (b) you can select time-invariant variables.
**note: add -r-, -s-, or -h- at the end of each selected variable**
**note: make sure all variables are inserted correctly (e.g. higovr->higov will reshape in an empty column higov)**
**note: the order here is identical to the codebook in g2aging**
	
	
***(a) time-variant variables***
loc 	xtra	"hhresphh cplh iwyr iwmr iwstatr iwstats"	// general response info in demographics section
loc 	vra 	"mstatr nhmlivr ruralh ageyr     `xtra'"		// demographics, identifiers, weights
	loc 	d_everhad "hibper diaber cancrer lunger hearter stroker arthrer  hiper kidneyer   psycher osteoer" //  
	*loc 	d_sincelw "hrtattr strokr cancrr hipr" /*these are already incorporated in d_everhad*/
	loc 	d_agediag "radiaghibp radiagdiab radiagcancr radiaglung radiagheart radiagstrok radiagarthr  radiaghip radiagpsych radiagosteo  radiagkidney" // radiagpsych /*these are time-invariant*/
	loc 	d_medictn "rxhibpr rxdiabr rxheartr rxlungr rxpsychr rxosteor rxcancrr rxstrokr rxarthrr"
loc 	vrb 	"shltr hlthlmar hlthlmr iadlar drinklr smokenr `d_everhad' `d_sincelw' `d_medictn'"	// health
loc 	vrc 	"higovr     nrshom1yr hosp1yr doctor1yr doctim1yr homcar1yr drugs1wr"										// healthcare utilization and insurance
loc 	xtra2 	"cogimpr verbfr" 
loc 	vrd  	"tr20r orientr `xtra2'"									// cognition
loc 	vre		""												// financial and housing wealth
loc		vrf 	""												// income and consumption
loc 	vrg 	"hhreshh"										// family structure
loc	 	vrh 	"workr lbrf_sr"									// employment history
loc	 	vri 	"retempr"										// retirement (and expectations)
loc 	vrj 	"pubpenr pubpens"								// pension
loc 	vrk 	""												// physical measures
loc 	vrl 	""												// assistance and caregiving 
loc 	vrm 	""												// stress 
loc 	vro 	""												// (end of life planning)
loc 	vrp 	""												// (childhood) 
loc 	vrq		"satlifezr eurodr"								// psychosocial 
loc 	vrlist	`vra' `vrb' `vrc' `vrd' `vre' `vrf' `vrg' `vrh' `vri' `vrj' `vrl' `vrm' `vro' `vrp' `vrq'

***(b) time-invariant variables***
**# Bookmark #3
	unab inwlist: inw*
	*di "`inwlist'"
loc 	xa 		"hacohort `inwlist' rabyear rabmonth radyear radmonth ragender raeducl `x_eol' radage"		
loc 	xb 		"`d_agediag'"
loc 	xc 		""
loc 	xlist	`xa' `xb' `xc' `xd' `xe' `xf' `xg' `xh' `xi' `xj' `xk' `xl' `xm' `xo' `xp' `xq'

***only keep chosen variables above in dataset to speed up reshape operation***
foreach vr of local vrlist {
forvalues i=1/`wavelast'{ 
*di 		"`vr'`i'"
loc		keeplist "`keeplist' `vr'`i'" // append each variable with wave indicator to local keeplist
}
}
*di 		"`keeplist'"

**keep only locals that are existing variables (e.g. missing mstat3-var causes errors) (details at [a1])**
isvar 	`keeplist'  	// keeps only local macros that actually exist, stored as "r(varlist)"
*di		"`r(varlist)'"
loc 	vrlistset "`r(varlist)'"
	gl	vrlistset "`r(varlist)'"
*display "`vrlistset'"
loc 	keeplist2 "" 	// add survey-specific special variables (e.g. eligibility to a pension program)
keep 	`idlist' `vrlistset' `xlist' `keeplist2'

***store variable labels from -wide- format (I) to copy into -long- reshaped dataset later (II)***	
**(I) store labels**
display "`vrlistset'"
	loc varasstringlist ""
loc vlabellist ""
foreach v of local vrlistset { 	/*use only the variables that actually exist*/
local `v'label: variable label `v'	/*store the labels of these variables into "varnamer(/s/h)#"*/
local `v'label = substr("``v'label'", strpos("``v'label'", " ") + 1, .) /*use only substring of label*/
*display "``v'label'"
	local varasstringlist `" `varasstringlist'   "``v'label'" "'
label variable `v' "``v'label'" 	/*relabel the variable with the new substring (without wave number)*/
}
	*di `"`varasstringlist'"'
	*des

**assign a label of a variable across waves to a single local**
**note: in a loop, the labels of varnamer1 varnamer2, ., varnamerT are used to define a single local macro. This local macro will then be used to assign it as a label to the new variable varnamer(/s/h)
**note: this loop could be written differently. Currently the label of the last varname available (e.g. varnamer8) is used. If you suggest a more efficient coding, let me know.
foreach name of local vrlist { 
forval i=1/`wavelast' {		// wavelast, needs to be adjusted for last wave of varname available
capture confirm variable `name'`i', exact /*checks if variable exists*/
if !_rc{
local `name'label "``name'`i'label'" /*only use label of variable if that variable (wave) exists*/
*di "``name'label'"
}
}
loc namelabellist "`namelabellist' ``name'label'"	
}
*di "`namelabellist'"



**# Bookmark #3 add to github
**add to a local the list of time-constant variables that do *not* exist in particular survey (e.g.radiag) (to generate an empty placeholder in reshape)**
di "`xlist'"
foreach v of local xlist { 
capture confirm variable `v' // , exact /*checks if variable exists*/
if _rc{
local vnotexist "`v'" /*only use label of variable if that variable (wave) exists*/
di "`vnotexist'"
loc xlistnotexist "`xlistnotexist' `vnotexist'"	
}
}
di "`xlistnotexist'"

***reshape operation***
**reshape 'wide' to 'long' format**
reshape long `vrlist' `xlistnotexist', i(`ID') j(wave) 

**(II) apply variable labels from wide format before**
foreach name of local vrlist{
label variable `name' "``name'label'"
}


**relabel survey wave values**
forvalues i=1/`wavelast'{
loc wavelabellist `wavelabellist' `i' "Wave `i'"  
}
*di 			`"`wavelabellist'"'
la de 		wavel `wavelabellist'
la val 		wave wavel 
l  			`ID' wave `varlist' in 1		
la var 		wave "Survey Wave"
tab wave


**format interview time as single variable**
sum 	iwyr iwmr
gen 	iwym = ym(iwyr, iwmr)
format 	iwym %tm
sum 	iwym
*tab 	iwym iwyr  
la var	iwym "r interview date (ym)"
	
// **format death time as single variable (rax (EOL))**
sum 	raxyear raxmonth
gen 	raxym = ym(raxyear, raxmonth)
format 	raxym %tm
sum 	raxym
*tab 	raxym raxyear  
la var	raxym "r death date (ym)"	

	**format death time as single variable (rad)**
	sum 	radyear radmonth
	gen 	radym = ym(radyear, radmonth)
	format 	radym %tm
	sum 	radym
	*tab 	radym radyear  
	la var	radym "r death date (ym)"	
	
**format birth time as single variable**
sum 	rabyear rabmonth
gen 	rabym = ym(rabyear, rabmonth)
format 	rabym %tm
sum 	rabym
*tab 	rabym rabyear  
la var	rabym "r death date (ym)"	


***end timer, xtset and save data***
timer 		off  1
timer 		list 1

rename  	`ID' ID
xtset 		ID wave
**# Bookmark #1 could add this to github:
	***rename key variables (moved from part 5) ***
	rename 	inw7c inw7
	order 	inw7, before(inw8) // need to reorder for inw_tot
	rename 	lbrf_sr lbrfr /*lbrf question slightly differ in S compared to HRS*/
	***generate alternative for "wave", as survey year***
	**generate time**
	recode	wave (1 = 2004 "2004 wave") (2 = 2006 "2006/07 wave") (3 = 2008 "2008/09 wave") (4 = 2011 "2011/12 wave") (5 = 2013 "2013 wave") (6 = 2015 "2015 wave") (7 = 2017 "2017 wave") (8 = 2019 "2019/20 wave") , gen(time)
	la var 	time "Survey Year (Wave)"
	**relabel wave to survey-specific value-labels**
	la de 	wavel 1 "2004 wave" 2 "2006/07 wave" 3 "2008/09 wave" 4 "2011/12 wave" 5 "2013 wave" 6 "2015 wave" 7 "2017 wave" 8 "2019/20 wave" , replace
	la val 	wave wavel
	*/
		
	**# Bookmark #1 *rename 	hiper osteoer (no longer used hip fracture), only meds
	replace osteoer = . 
	
	
	
save		"`h_data'H_`data'_panel.dta", replace // check if appeared in correct folder!

pause


											
****************************************************************************************************
*Part 4*: Codebook: (run this to generate an overview of the harmonized variables)
****************************************************************************************************

/*
qui log using "`h_data'codebook", text replace name(log)
codebook, compact
codebook
qui log close log

qui log using "`h_data'codebook_tab", text replace name(log)
xtdes
des 
sum
display "`vrlist'"
foreach v of local vrlist { /*needs vrlist from first block which was used for reshape*/
tab `v' wave,m
}
qui log close log

pause	
*/


	
****************************************************************************************************
*Part 5*: Generate study-specific variables while in 'long' format 
**note: recode/relabel/rename variables from dataset and generate new variables**
****************************************************************************************************
*[see separate file]*
*++ END OF FILE ++*
log close logDofile /*logs file to specified folder if log active*/
+++ END OF FILE +++


****************************************************************************************************
*Appendix*
****************************************************************************************************
*[a1]  https://www.statalist.org/forums/forum/general-stata-discussion/general/1365048-keep-command-variable-not-found

	** notes
	*cognition: CHARLS: slfmem imrc dlrc tr20 (=sum of imrc dlrc) ser7 (draw)  | SHARE: slfmem imrc dlrc tr20 ser7 (from w4) + verbf numer_s cogimp cogothp
	*RAXYEAR is assigned special missing value .i if the proxy reported a year of death beyond the end of life interview date. 
	*RADYEAR and RADMONTH are based on questions asked as part of the exit interview each wave starting with Wave 2. When respondents don't know or refuse to answer, RADYEAR is assigned special missing values .d or .r, respectively. RADYEAR is assigned special missing value .i for impossible responses to death year. RADYEAR is assigned special missing .x if the respondent has not yet passed away.

**inw
*INWw indicates whether an individual responded to a particular wave. INWw is derived from the interview_wW variable in the SHARE tracker file. Respondents identified as having either a full or partial interview either in person or through a proxy are considered to have responded. 
*INWwSC indicates whether an individual responded to a particular wave's drop-off/self-completion questionnaire. A code of 0 indicates the respondent is not included in the SHARE drop-off/self-completion questionnaire file for that wave. A code of 1 indicates that the respondent at least partially completed the drop-off/self-completion questionnaire and is included in drop-off/self-completion questionnaire file. 
*INWwSC is assigned plain missing (.) if the respondent did not participate in the current wave. INWwLH indicates whether an individual responded to a particular wave's life history questionnaire. A code of 0 indicates the respondent is not included in the SHARELIFE life history questionnaire file. A code of 1 indicates that the respondent at least partially completed the life history questionnaire and is included in life history questionnaire file. The life history questionnaire was given in Wave 3 and Wave 7. Those respondents who did not respond to the Wave 3 SHARELIFE life history questionnaire were given the life history questionnaire in Wave 7 and those who participated in the SHARELIFE questionnaire in Wave 3 were given the full questionnaire in Wave 7.
*INW7C indicates whether an individual responded to the Wave 7 condensed questionnaire. A code of 0 indicates the respondent was not given or did not complete the SHARE Wave 7 condensed questionnaire file. A code of 1 indicates that the respondent was given and at least partially completed a condensed version of the Wave 7 questionnaire. At Wave 7, respondents who completed the SHARELIFE questionnaire were given a condensed version of the SHARE questionnaire, which covered a portion of the questions of the regular SHARE questionnaire.

		