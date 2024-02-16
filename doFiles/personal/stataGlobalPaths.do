/* INFORMATION ON NRPS PROJECT 

There are 3 Main Directories:
i) G-Drive: 	 See below $myGoogle. Contains .do Files and Full CHARLS data (only original data is saved here) 
ii)local Folder: See below $myFolder. Saves locally .dta files and output (prepared dataset is saved here)
iii)github folder: results are directly exported onto document

There are several do files: 
-	do_CHARLS_Cleaning		: Use all CHARLS datasets, individual variables (H_CHARLS_D_Data -> H_CHARLS_D_DataM)
- 	do_CHARLS_Harmon 		: Use Harmonized data, and merging with above, set to long format (H_CHARLS_D_DataM -> H_CHARLS_D_DataPanel -> used for all regressions and vizualization)
- 	do_CHARLS_HarmonsubNRPS	: Prepares variables needed for NRPS project
-	do_CHARLS_Viz		: Graphs 
- 	do_CHARLS-DDR 		: DDR 
- 	do_CHARLS-TWFE 		: TWFE
-	do_CHARLS-csdid		: csdid (when not incorporated in twfe)
*/



/*// Packages needed:
ssc install outreg2
search st0085_2  // esttab

** for interpolation/imputation **
ssc install mipolate


** for (iv)reghdfe**
ssc install reghdfe
ssc install erepost
ssc install ivreghdfe
ssc install ftools
ssc install ivreg2
/* if ivreg does not work:
ssc install itsa, replace
ssc install avar, replace
ssc install ranktest 
*/

/*
ssc install csdid, replace
ssc install drdid, replace	
ssc install coefplot, replace
*/


*/



***file paths moved to Github***
// myGoogle: Full CHARLS datasets are on G-Drive (Same directory for all users). 
// myFolder: data location: After data preparation data will appear in myFolder
gl 	myGoogle 		"G:/Shared drives/sharedStefan/---CHARLS" 	// path to all data files 
	*gl 	outpath  		"$myGoogle/1-NRPS/outFiles" 				// old output path (no longer used)			
gl 	outgithubNRPS 	"C:/Users/User/Documents/GitHub/1-projectNRPS-github/files" // new output path (saves files directly on document after cloning repo)

// Datasets will only be saved locally. Main folder (dropbox or local).
if "`c(username)'" == "StefanPichler" {
gl myFolder "C:/Users/StefanPichler/Dropbox/Projekte_Castor_und_Stefan/---CHARLS" 
} 
if "`c(username)'" == "P306685" {
gl myFolder  "C:/Users/P306685/Dropbox/Projekte_Castor_und_Stefan/---CHARLS"    
}
if "`c(username)'" == "User" {
*gl myFolder C:/Users/User/Documents/RUG/---CHARLS
gl myFolder "G:/My Drive/drvData/CHARLS"	

}
if "`c(username)'" == "P307344" {
gl myFolder X:\My Documents\XdrvData\CHARLS
gl 	outgithubNRPS 	"X:\My Documents\XdrvData\CHARLS\files\1-NRPS" // new output path (saves files directly on document after cloning repo)
*gl	myGoogle "X:\My Documents\XdrvData\CHARLS"
*gl outpath  "//Client/G$/Shared drives/sharedStefan/---CHARLS/1-NRPS/outFiles" // get G on UWP on my PC

}

clear 	all			
set 	more off
set 	trace off
capture log close
log 	close _all // closes all open log files regardless of names
*/


