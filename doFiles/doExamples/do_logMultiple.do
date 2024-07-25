clear all
cap log close
log close _all
log using "$outpath\logs\test.txt" , text replace

gen x =1 
gen y =2
gen z =3
sum x 

log using "$outpath\logs\sub1.txt" , text replace name(sub1)

sum y

log close sub1

log using "$outpath\logs\sub2.txt" , text replace name(sub2)

sum z

log close sub2


sum x 

log close
log close _all