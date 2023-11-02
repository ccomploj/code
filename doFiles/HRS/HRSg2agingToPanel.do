capture log close
clear all
set more off
log close _all				// closes all log files
pause on				// turns pauses on (a pause does not interrupt local memory)
*pause off				// deactivates -pause- (press q to continue after a pause)
set maxvar 15000
timer on 1 				// counts the duration of file computation


***packages needed for file to run***
*	ssc install isvar

****************************************************************************************************
*Title: Harmonization file of HRS-type datasets harmonized by Gateway2Aging (www.g2aging.org)
*Summary: constructs main data from HRS data (g2aging version) by reshaping selected vars to a panel 
*Date: 16-07-2023
*Author: Castor Comploj
*Date Created: 13-07-2023
*Note: If you suggest a change, or the file is not suitable for your HRS-type survey, please commit 
*      changes on Github directly or email me at castorcomploj@protonmail.com
****************************************************************************************************
***Special Notes***
*note: After running the file, most variable names end with r, s, h or hh. r refers to respondent 
*		and s refers to spouse. h (hh) refers to household. 
*note: there are two types of variables in the g2aging data: time-varying and time-invariant. 



****************************************************************************************************
*PART 1*: Adapt this section to the specific HRS-type harmonized dataset from the g2aging
*note: you do not have to change any other section except "Part 1", and the variables in "Part 3"
****************************************************************************************************
***define folder locations***
loc cv 		"X:/My Documents/XdrvData/SHARE/" 	// main folder location
loc h_data 	"`cv'SHAREdata/harmon/"				// harmonized data folder location
loc out 	"`cv'SHAREoutput/"					// output folder location

***Bringing in Core Data***
**Harmonized data**
use "`h_data'H_SHARE_f.dta"					  // choose dataset

**End of Life Survey** /*(not required to use for file to run)*/ 
loc x_eol "raxmonth raxyear radage" /*merge eol vars*/
merge 1:1 mergeid using "`h_data'H_SHARE_EOL_c.dta", keepusing(`x_eol')

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
loc ID 			"panelid"	// use panelid if ID does not uniquely identify indiv. (same ID in two count(r)ies)
loc idlist 		"`cntry' `cnty' `communityID' `householdID' `pn' `ID'" 
***define other survey-specific values*** 
loc wavelast 	"8"			// change this to the # of the last available wave (e.g. 8 if 8 waves, 4 if 4 waves)



*pause // to continue after a pause, type "q" and enter; browse the data using -browse-

****************************************************************************************************
*Part 2*: Overview of dataset
****************************************************************************************************
order `idlist', alphabetic
**start log**
log using 	"`h_data'log_harmon.txt", text replace name(log_harmon) // ends w/ -log close log_harmon-

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

pause 


****************************************************************************************************
*Part 3*: Choose variables and reshape from 'wide' to 'long'
****************************************************************************************************
***move r, h, hh indicators at the end of varname (for reshape operation)***
*describe r* h* hh*, simple
rename 	(r(#)*) (*[2]r#[1])		// respondent
rename 	(h(#)*) (*[2]h#[1])		// household
rename 	(hh(#)*) (*[2]hh#[1]) 	// household
rename 	(s(#)*) (*[2]s#[1])	 	// spouse
*describe r* h* hh* s*  , simple	  

*pause

***select variables of interest (by section in harmon manual)***
**note: select first (a) time-varying variables. Below at (b) you can select time-invariant variables.
**note: add -r-, -s-, or -h- at the end of each selected variable**
**note: make sure all variables are inserted correctly (e.g. higovr->higov becomes empty column higov)**
**note: make sure no variable appears twice**
***(a) time-variant variables***
loc 	xtra	"hhresphh cplh iwyr iwmr iwstatr iwstats"		// general response info in vra
loc 	vra 	"mstatr nhmlivr ruralh ageyr     `xtra'"		// demographics, identifiers, weights
loc 	disease ""
loc 	vrb 	"shltr iadlar `disease'"						// health
loc 	vrc 	"higovr"										// healthcare utilization and insurance
loc 	vrd  	""												// cognition
loc 	vre		""												// financial and housing wealth
loc		vrf 	""												// income and consumption
loc 	vrg 	""												// family structure
loc	 	vrh 	"workr"											// employment history
loc	 	vri 	"retempr"										// retirement (and expectations)
loc 	vrj 	"pubpenr"										// pension
loc 	vrk 	""												// physical measures
loc 	vrl 	""												// assistance and caregiving 
loc 	vrm 	""												// stress 
loc 	vro 	""												// (end of life planning)
loc 	vrp 	""												// (childhood) 
loc 	vrq		"satlifezr"										// psychosocial 
loc 	vrlist	`vra' `vrb' `vrc' `vrd' `vre' `vrf' `vrg' `vrh' `vri' `vrj' `vrl' `vrm' `vro' `vrp' `vrq'
***(b) time-invariant variables***
loc 	xa 		"inw? rabyear rabmonth radyear radmonth ragender raeducl `x_eol'"		
loc 	xb 		""
loc 	xc 		""
loc 	xlist	`xa' `xb' `xc' 

***only keep chosen variables above in dataset to speed up reshape operation***
foreach vr of local vrlist {
forvalues i=1/`wavelast'{ 
di 		"`vr'`i'"
loc		keeplist "`keeplist' `vr'`i'" // append each variable with wave indicator to local keeplist
}
}
di 		"`keeplist'"
**keep only locals that are existing variables (e.g. missing mstat3-var causes errors) (details at [a1])**
isvar 	`keeplist'  	// keeps only local macros that actually exist, stored as "r(varlist)"
display "`r(varlist)'"
loc 	vrlistset "`r(varlist)'"
loc 	keeplist2 "" 	// other survey-specific variables (e.g. eligibility to pension program)
keep 	`idlist' `vrlistset' `xlist' `keeplist2'

***store variable labels from -wide- format (I) to copy into -long- reshaped dataset later (II)***	
***(I) store labels***
display "`vrlistset'"
loc vlabellist ""
foreach v of local vrlistset { 	/*use only the variables that actually exist*/
local `v'label: variable label `v'	/*store the labels of these variables into "varnamer(/s/h)#"*/
local `v'label = substr("``v'label'", strpos("``v'label'", " ") + 1, .) /*use only substring of label*/
display "``v'label'"
label variable `v' "``v'label'" 	/*relabel the variable with the new substring (without wave number)*/
}
des
**assign a label of a variable across waves to a single local**
**note: in a loop, the labels of varnamer1 varnamer2, ., varnamerT are here used to define a single local 
*		macro. This local macro will then be used to assign it as a label to the new variable varnamer(/s/h)
**note: this loop could be written differently. Currently the label of the last varname available (e.g. 
*		varnamer8) is used. If you would like to suggest a more efficient coding, let me know.
**note: the result of this block is a variable label assigned to the local "varname"label 
foreach name of local vrlist { 
forval i=1/`wavelast' {		
capture confirm variable `name'`i', exact /*checks if variable exists*/
if !_rc{ /*only use label of variable if that variable (wave) exists and has therefore not an empty label*/
local `name'label "``name'`i'label'" /*assign this variable label to the local "varname"label*/
di "``name'label'"
}
}
loc namelabellist "`namelabellist' ``name'label'"	
}
di "`namelabellist'" /*list of unique var labels (which are at (II) assigned to the new variable varname*/


***reshape operation***
**reshape 'wide' to 'long' format**
reshape long `vrlist', i(`ID') j(wave) 

**(II) apply variable labels from wide format before**
foreach name of local vrlist{
label variable `name' "``name'label'"
}

**relabel survey wave values**
forvalues i=1/`wavelast'{
loc wavelabellist `wavelabellist' `i' "Wave `i'"  
}
di 			`"`wavelabellist'"'
la de 		wavel `wavelabellist'
la val 		wave wavel 
l  			`ID' wave `varlist' in 1		
tab wave
la var 		wave "Survey Wave"

***end timer, xtset and save data***
timer 		off  1
timer 		list 1
xtset 		`ID' wave
save		"`h_data'H_panel.dta", replace // check if appeared in correct folder!

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
*note: recode/relabel variables from dataset*
****************************************************************************************************
// I: A: demographics, identifiers, weights
rename  ageyr age 
recode 	ragender 	(1 = 1 "1.male") (2 = 0 "0.female"), gen(male)
la var 	male		"male"

tab 	raeducl, gen(educ_) 				// create dummies from categorical variable


loc 	droplist "ragender" 				// drop variables that are not needed
drop 	`droplist'

// B: health 
// C: healthcare use and insurance
// D: cognition
// E: financial and housing Wealth
// F: income and consumption
// G: family structure
// H: employment history
// I: retirement (and expectations)
// J: pension 
// K: physical measures
// L: assistance and caregiving
// M: stress
// O: (end of life planning)
// P: (childhood)
// Q: Psychosocial
// Y: Other relevant variables (e.g. from other datasets)


***generate and label new variables***
gen		agein2011 = 2011-ageyr
la var		agein2011 "age in 2011"


macro list 
sort 	`ID' wave 
save	"`h_data'H_panel2.dta", replace // check if appeared in correct folder!


****************************************************************************************************
log close log_harmon
++END OF FILE++
****************************************************************************************************

****************************************************************************************************
*Appendix*
****************************************************************************************************
*[a1]  https://www.statalist.org/forums/forum/general-stata-discussion/general/1365048-keep-command-variable-not-found
