/*how to plot margins, see here:
https://www.stata.com/manuals/rmarginsplot.pdf*/

use https://www.stata-press.com/data/r18/nhanes2, clear
// logit highbp sex##c.age // estimates a single line for age, only at() works, could also use -reg-
// levelsof age
// margins sex, at(age=(`r(levels)')) // should use this if -at- variable is continuous if want to estimate predictions (the line) for the different groups. However, if I want to plot crude data, should use age as dummies in the predicion. This takes more computation time, but I can group ages to speedd up the process. 
// marginsplot, name(g1, replace)

timer clear 
timer on 1
logit highbp sex##age // estimates dummies, at() and margins with interactions is equivalent
margins age#sex // does not work with continuous age (after specifying -c.-) (but -at() also works in this case)
marginsplot, name(g2, replace)
timer off 1 
gr combine g1 g2 
timer list 1

	**can also compute age#sex using at(), but this is much slower, see comparison below**
	timer on 2 
	logit highbp sex##age // estimates dummies, at() and margins with interactions is equivalent	
	levelsof age
	margins sex, at(age=(`r(levels)')) 
	marginsplot, name(g3, replace)
	timer off 2 
	timer list 2
*	timer list 
	gr combine g2 g3


/*notes: use logit also, not just reg, and plot by percentiles
for instance 
margins agegrp, at((p25 ) bmi) at((p75 bmi)*/