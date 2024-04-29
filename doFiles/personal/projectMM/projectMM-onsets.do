

sum 	onsetd_diab radiagdiab

tab onsetd_diab radiagdiab  if mi(radiagdiab) & !mi(onsetd_diab), m
tab radiagdiab  onsetd_diab if mi(onsetd_diab) & !mi(radiagdiab), m
// in HRS, only have 
*319 are .m


codebook onsetd_diab if , compact // ELSA, 35 individuals with .m, HRS 20
codebook radiagdiab if onsetd_diab==.m , compact 

	bys ID: egen diabatfirstobs = min(d_diab)

bro ID wave age radiagdiab diaber onsetd_diab if !mi(onsetd_diab) | mi(radiagdiab)
bro ID wave age radiagdiab diaber onsetd_diab if diabatfirstobs==1


bro ID wave age radiagdiab diaber onsetd_diab if !mi(onsetd_diab) & mi(radiagdiab)

bro ID wave age radiagdiab diaber onsetd_diab if mi(onsetd_diab) & !mi(radiagdiab)