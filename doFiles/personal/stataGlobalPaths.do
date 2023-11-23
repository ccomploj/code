// Full CHARLS datasets on G-Drive (Same directory for all users). Or copy files to own dir.
gl myGoogle "G:/Shared drives/sharedStefan/---CHARLS"  
// Datasets will only be saved locally. Main folder (dropbox or local).
if "`c(username)'" == "StefanPichler" {
gl myFolder "C:/Users/StefanPichler/Dropbox/Projekte_Castor_und_Stefan/---CHARLS"
} 
if "`c(username)'" == "P306685" {
gl myFolder "C:/Users/P306685/Dropbox/Projekte_Castor_und_Stefan/---CHARLS"    
}
if "`c(username)'" == "User" {
gl myFolder C:/Users/User/Documents/RUG/---CHARLS
}
if "`c(username)'" == "P307344" {
gl myFolder X:/My Documents/CHARLS 
*	gl	myGoogle "X:\My Documents\XdrvData\CHARLS"
	gl outpath  "//Client/G$/Shared drives/sharedStefan/---CHARLS/1-NRPS/outFiles" // get G on UWP on my PC
}
gl 		outpath  "$myGoogle/1-NRPS/outFiles"
cd 		"$myFolder" // Datasets are saved on local $myFolder. Output is on G-Drive $myGoogle


clear 	all			
set 	more off
set 	trace off
capture log close
log 	close _all // closes all open log files regardless of names


/*// Packages needed:
ssc install outreg2
search st0085_2  // esttab

** for interpolation/imputation **
ssc install mipolate

** for (iv)reghdfe**
*ssc install reghdfe
*ssc install ivreghdfe
* ssc install ftools
* ssc install reghdfe 
* ssc install ivreg2
/* if ivreg does not work:
ssc install itsa, replace
ssc install avar, replace
ssc install ranktest 
*/

/*
ssc install csdid, replace
ssc install drdid, replace	
ssc install coefplot
*/

