/**#use only observations before a transition ** 
bys ID (duration): egen durationmax = max(duration)
replace duration = . if duration!= durationmax	// 
drop durationmax
*/