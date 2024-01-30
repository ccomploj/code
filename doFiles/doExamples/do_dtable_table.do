
** problem: dtable does not work with multiple column variables until Stata 18 ** 
** solution: this file ** 

set seed 18
sysuse auto, clear
generate u1 = runiform()
sort u1
gen somecategory = (_n<30)
dtable mpg i.rep78, by(foreign, tests) /*only works with one column var*/

* use -table- to compute statistics and arrange the basic layout;
* use -style(dtable)- to get its styles: numeric formats,
* parentheses, and percent signs
table (var) (foreign somecategory result) , ///
    style(dtable) ///
    stat(mean mpg) ///
    stat(sd mpg) ///
    stat(fvfrequency rep78) ///
    stat(fvpercent rep78) ///
    nototals

* use composite results to assign statistics to columns
collect composite define col1 = mean fvfrequency
collect composite define col2 = sd fvpercent
collect style autolevels result col1 col2, clear

* hide the result labels
collect style header result, title(hide) level(hide) 
* show labels for the column variables
collect style header foreign somecategory, title(label)

* replay the current layout so you can see the specification with the
* final table
collect layout




 










