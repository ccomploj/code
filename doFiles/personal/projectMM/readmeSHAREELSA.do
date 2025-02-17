* The following order is used:

* 1) First download the specific datasets SHARE and ELSA and prepare a "harmonized" g2aging version
* 2) Construct the main datasets as a panel format and choosing relevant variables (ELSA and SHARE should be treated differently initially, they also have different variable names sometimes)
* - for this, use pMM-1-SHARE and pMM-1-ELSA. 
* - I have created txt logs of this part
* 3) Generate general variables: 
* - for this, run pMM-2-part5. Do this twice (run it once using ELSA and once using SHARE)
* - Note: pMM-2-part5 includes the file pMM-2-part5-subDiseases (which contains all specific variables for this project). This file is set to take the file from this online repository. 
* - then, merge the datasets into a single dataset using pMM-2-mergedatasets
* - I have created txt logs of this part.
* 4) Plot (for figures, I have used the datasets separately to make errors impossible, but this can be done also with a single combined dataset) and run regressions using the separate files.