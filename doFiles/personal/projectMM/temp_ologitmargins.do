/** basic plot has issues, too many groups (2) and too many levels (1-5), so 10 lines **
clear all
webuse fullauto
ologit rep77 mpg i.foreign
margins, at(mpg=(10(5)45) foreign=(0/1)) 
marginsplot
++
*/


/** to combine different outcomes in single prediction line **
clear all
webuse fullauto
ologit rep77 mpg // i.foreign
margins, at(mpg=(10(5)45)) predict(outcome(1)) predict(outcome(2))
set scheme s1mono
marginsplot, recast(line) saving(gr1, replace)
margins, at(mpg=(10(5)45)) expression(predict(outcome(1)) + predict(outcome(2)))
marginsplot, recast(line) saving(gr2, replace) leg(on order(2 "Outcome 1 or Outcome 2"))
gr combine gr1.gph gr2.gph, ycommon
++
*/


** plot marginal effects **
clear all
webuse fullauto
ologit rep77 mpg  i.foreign
margins, dydx(foreign) at(mpg=(10(5)45)) predict(outcome(1)) predict(outcome(2)) 
marginsplot, recast(scatter)

mchange black female age, stats(change start end) dec(5) delta(10)