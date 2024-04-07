webuse estatus, clear
list id year estatus hhchild hhincome age in 1/15, sepby(id) noobs
xtset id
xtmlogit estatus i.hhchild age hhincome i.hhsigno i.bwinner, rrr
margins hhchild
marginsplot, plotopts(msize(*0.5)) ylabel(0(0.1)1)                      
               legend(order(4 "Out of l.f."                                
                            5 "Unemployed"                                 
                            6 "Employed") rows(1)) 
							
xtmlogit estatus i.hhchild age hhincome i.hhsigno i.bwinner, fe rrr