*estimates use "$outpath/logs/t-regd_count-age-SHAREestimates", number(1)


clear all
*ssc install estout, replace 
sysuse auto

qui eststo a: reg price weight
qui eststo b: reg price weight length
qui eststo c: reg price weight length mpg 

estimates dir
foreach e in `r(names)' {
    estimates restore `e'
    estimates title: `e'
    estimates save "$outpath/logs/test" , append
}

clear all 
estimates describe using "$outpath/logs/test"
forvalues j=1/`r(nestresults)' {
    estimates describe using "$outpath/logs/test", number(`j')
    local title `r(title)'
    estimates use "$outpath/logs/test", number(`j')
    est store `title'
}
est dir