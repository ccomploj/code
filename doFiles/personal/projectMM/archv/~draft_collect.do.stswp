use https://www.stata-press.com/data/r18/nhanes2l, clear
label define yesno 0 "No" 1 "Yes"
label values highbp diabetes heartatk yesno
label variable diabetes "Diabetes"
collect clear
 table (sex agegrp) (diabetes),  statistic(percent, across(diabetes)) statistic(count diabetes) name(table1) 
quietly: table (sex agegrp) (highbp),  statistic(percent, across(highbp)) statistic(count highbp) name(table1) append
quietly: table (sex agegrp) (heartatk),  statistic(percent, across(heartatk)) statistic(count heartatk) name(table1) append

//
// // Add a row to count the number of non-missing observations for each sex-agegrp combination
table (sex agegrp), nototals  statistic(count agegrp) name(table1) append // statistic(count d_count) 



*LOOK AT DIMENSIONS OF TABLE
collect dims

*LOOK AT LEVELS OF DIMENSION RESULT
collect levelsof result


*FORMAT CELLS
collect style cell result[percent], nformat(%3.2f)
collect style cell result[count], nformat(%9.0f)

// collect layout (sex#agegrp) (result#(diabetes[1] highbp[1] heartatk[1]))
collect layout (sex[1]#agegrp) (diabetes[1] highbp[1] result[count]) 
