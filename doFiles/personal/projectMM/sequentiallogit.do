*https://grodri.github.io/glms/stata/c6s4*
use https://grodri.github.io/datasets/elsalvador1985, clear
gen age = 12.5 + 5*ageg
gen agesq = age^2
	tab cuse
	tab cuse,nola
gen use  = cuse < 3 /*sterilization or other method == using contraception*/
logit use age agesq [fw=cases] /*older people are more likely to use sterilization*/
di -0.5*_b[age]/_b[agesq]
	/*calculate extreme point after 
	df(age)/d(age)=d/d(age) beta_0 age + beta1 agesq 
				  =beta_0 + beta_1 * 2 * age == 0 
				   -beta_0 / beta1 * 2 = age*	
	maximum reached at 34.7 of age and then declines*/
scalar ll_u = e(ll) 	/*log-likelihood*/
predict fit_u, xb /*fitted values from logit predicting contraceptive use*/

/*choice of sterilization among users (cuse==1)*/
gen ster = cuse == 1
logit ster age agesq [fw=cases] if use  /*here outcome is -ster-, -use- is group*/ 
di -0.5*_b[age]/_b[agesq]
scalar ll_s = e(ll)
predict fit_s, xb


/*comparing log likelihoods*/ 
scalar ll_seq = ll_s + ll_u
quietly mlogit cuse i.ageg [fw=cases], base(3) /*using multinomial logit*/
scalar dev = 2*(e(ll) - ll_seq)
di "deviance =",%6.2f dev,"df =", 14 - 6, "p-value =", ///
  %5.3f chi2tail(8, dev)
