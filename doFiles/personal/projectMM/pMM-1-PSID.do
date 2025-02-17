clear all
set maxvar 30000

** wide format **
use "C:\Users\casto\Documents\RUG\PSID\194322-V1\PSIDSHELF_1968_2019_WIDE_1.82_GB_UNZIPPED\Users\DD\Dropbox (University of Michigan)\Data\PSID\PSID_SHELF\PSIDSHELF_1968_2019_WIDE.dta" 

** long format ** 
// use "C:\Users\casto\Documents\RUG\PSID\194322-V1\PSIDSHELF_1968_2019_LONG_5.54_GB_UNZIPPED\Users\DD\Dropbox (University of Michigan)\Data\PSID\PSID_SHELF\PSIDSHELF_1968_2019_LONG.dta"

unab allvars: * 
display "`allvars'"


count
codebook ID YEAR, compact

ds


keep ID YEAR LINEAGE


** to do: 
* - check if have disease info
* - if not, have to go to long format of data, merge disease by creating a new variable for every time period, then reshape to the long format