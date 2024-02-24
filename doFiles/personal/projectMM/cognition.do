pause on
pause off
log close _all 	/*closes all open log files*/
clear all		/*clears all data in memory*/



***choose data***
loc data "SHAREELSAHRS"

***define folder locations***
if "`c(username)'" == "P307344" { // UWP server
loc cv 		"X:/My Documents/XdrvData/`data'/"
loc outloc 	"\\Client\C$\Users\User\Documents\GitHub\2-projectMM-`data'\" 
}
else {
loc	cv 		"G:/My Drive/drvData/`data'/" // own PC
loc	outloc 	"C:/Users/User/Documents/GitHub/2-projectMM-`data'" 	
}
gl 	outpath 	"`outloc'/files" /*output folder location*/
loc saveloc 	"main" // main | supplement /*saving location*/
cd  			"`cv'"	
use 			"./`data'data/harmon/H_`data'_panel2-MM.dta", clear	


**define country-specific locals**
if "`data'"=="CHARLS" {
*loc t 				"ruralh" // /*categorical variable to split by*/ 	
}
if "`data'"=="SHARE" {
loc agethreshold 	"50" // select survey-specific lower age threshold
	drop if wave==3 // is not really a time period, there are no regular variables for this wave
	keep 	if hacohort==1 | hacohort==2 
	drop 	if countryID=="GR" /*relatively imprecise survey*/
}
if "`data'"=="ELSA" {
loc agethreshold 	"50" // select survey-specific lower age threshold
}
if "`data'"=="HRS" {
loc agethreshold 	"51" // select survey-specific lower age threshold
	keep 	if hacohort<=5 	
	keep if wave>=3 & wave<=13 // cognitive measures not consistently available
	drop if wave<=2    & dataset=="HRS"	
	drop if wave>=14   & dataset=="HRS"			
}	
if "`data'"=="SHAREELSA" {
loc agethreshold 	"50" // select survey-specific lower age threshold
	drop if agemin<50  & dataset=="SHARE"
	drop if agemin<50  & dataset=="ELSA"
	*drop if wave==3    & dataset=="SHARE" // already dropped
	drop if hacohort>2 & dataset=="SHARE"  
}	
if "`data'"=="SHAREELSAHRS" {
loc agethreshold 	"50" // select survey-specific lower age threshold
	drop if agemin<50  & dataset=="SHARE"
	drop if agemin<50  & dataset=="ELSA"
	*drop if wave==3    & dataset=="SHARE" // already dropped
	drop if hacohort>2 & dataset=="SHARE"  	
}	
loc t "male"
drop if agemin<`agethreshold'	
**********************
loc cognitionmeasures "tr20r orientr   cogimpr verbfr     bwc20r mstotr cogtotr"
bys dataset time: sum `cognitionmeasures'

foreach c of local cognitionmeasures {
	loc clabel: var label `c'
	di "`clabel'"		
// 	tab `c' dataset, row nofreq
	tab `c' time if dataset=="SHARE"
	tab `c' time if dataset=="ELSA"	
	tab `c' time if dataset=="SHARE"	
}
+
foreach c of local cognitionmeasures {
	loc clabel: var label `c'
	di "`clabel'"	
	bys dataset: tab  `c' cohortmin5 , row nofreq
}

+++
cognition

**orient
SHARE
In Waves 4 and 5, these questions are only asked of new interviewees, so if the questions were skipped because of re-interviewing, special missing
value .q was assigned. In Wave 7, only respondents who were in Wave 3 (SHARELIFE Interview), and so were
given the regular questionnaire in Wave 7, were asked these questions.

In Waves 1, 2, 6, and 8, the questions were asked for all respondents. In Waves 4 and 5, these questions
are only asked of new interviewees. In Wave 7, only respondents who were in Wave 3 (SHARELIFE Interview)
were asked these questions.

R1ORIENT 30222 3.74 0.71 0.00 4.00
R2ORIENT 36927 3.75 0.73 0.00 4.00
R4ORIENT 37005 3.77 0.71 0.00 4.00
R5ORIENT 23015 3.77 0.69 0.00 4.00
R6ORIENT 64976 3.84 0.51 0.00 4.00
R7ORIENT 13921 3.70 0.84 0.00 4.00
R8ORIENT 46579 3.75 0.76 0.00 4.00

ELSA

R1ORIENT 11769 3.73 0.58 0.00 4.00
R2ORIENT 9253 3.75 0.57 0.00 4.00
R3ORIENT 9482 3.75 0.58 0.00 4.00
R4ORIENT 10552 3.76 0.56 0.00 4.00
R5ORIENT 9670 3.77 0.56 0.00 4.00
R6ORIENT 9909 3.78 0.56 0.00 4.00
R7ORIENT 8915 3.78 0.55 0.00 4.00
R8ORIENT 7858 3.77 0.58 0.00 4.00
R9ORIENT 8077 3.79 0.54 0.00 4.00

HRS
R2ORIENT 7382 3.66 0.72 0.00 4.00
R3ORIENT 16351 3.76 0.57 0.00 4.00
R4ORIENT 12330 3.73 0.62 0.00 4.00
R5ORIENT 9503 3.74 0.62 0.00 4.00
R6ORIENT 9611 3.71 0.67 0.00 4.00
R7ORIENT 13083 3.72 0.65 0.00 4.00
R8ORIENT 10517 3.67 0.71 0.00 4.00
R9ORIENT 10518 3.68 0.71 0.00 4.00
R10ORIENT 16031 3.71 0.64 0.00 4.00
R11ORIENT 10250 3.63 0.74 0.00 4.00
R12ORIENT 9692 3.62 0.77 0.00 4.00
R13ORIENT 13700 3.68 0.68 0.00 4.00
Questions about date naming begin in AHEAD Wave 1, and so RwORIENT is available starting in AHEAD Wave 1.
From Wave 4 forward, the questions are only asked of interviewees and re-interviewees **who are 65 or
older**. If the questions were skipped because the respondent is younger than 65, then special missing
value .a is assigned.
RwORIENT is not currently available for Waves 14 and 15, but will be incorporated with the next data
release.





**tr20
SHARE
R1TR20 29779 8.14 3.59 0.00 20.00
R2TR20 36367 8.49 3.62 0.00 20.00
R4TR20 56331 8.94 3.77 0.00 20.00
R5TR20 63750 9.23 3.79 0.00 20.00
R6TR20 64509 9.25 3.74 0.00 20.00
R7TR20 74299 8.84 3.78 0.00 20.00
R8TR20 45386 9.08 3.70 0.00 20.00

ELSA
R1TR20 11701 9.47 3.59 0.00 20.00
R2TR20 9234 9.95 3.62 0.00 20.00
R3TR20 9478 10.32 3.70 0.00 20.00
R4TR20 10544 10.41 3.66 0.00 20.00
R5TR20 9688 10.44 3.73 0.00 20.00
R6TR20 9971 10.69 3.72 0.00 20.00
R7TR20 9040 10.54 3.78 0.00 20.00
R8TR20 7921 10.65 3.79 0.00 20.00
R9TR20 8135 10.72 3.65 0.00 20.00


HRS
R3TR20 16351 9.94 3.92 0.0 20.0
R4TR20 19341 10.21 3.88 0.0 20.0
R5TR20 17516 9.88 3.77 0.0 20.0
R6TR20 16129 9.98 3.65 0.0 20.0
R7TR20 18327 9.78 3.48 0.0 20.0
R8TR20 17209 9.72 3.61 0.0 20.0
R9TR20 16077 9.68 3.56 0.0 20.0
R10TR20 20652 9.67 3.40 0.0 20.0
R11TR20 19407 9.59 3.46 0.0 20.0
R12TR20 17698 9.65 3.54 0.0 20.0
R13TR20 19971 9.67 3.43 0.0 20.0
	??these variables include questions **only asked of Respondents over 65 or new Respondents**. Additionally, proxy
respondents are not asked the questions. Users should use the special missing values described above and review the documentation
sections for the input variables for more details on the RwCOGTOT sample