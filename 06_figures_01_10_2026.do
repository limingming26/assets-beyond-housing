/* Figures. */
version 18
args module
if "`module'" == "" {
    do "$CODE/06_figures_01_10_2026.do" plot_data
    do "$CODE/06_figures_01_10_2026.do" figures
    exit
}

if "`module'" == "plot_data" {
/* Plot data. */
use "$DATA/core_entrants_01_10_2026.dta", clear
keep housing_portfolio total_asset_wan
sort total_asset_wan
local position=1+(_N-1)*.99
local lo=floor(`position')
local hi=ceil(`position')
scalar cap99=total_asset_wan[`lo']+(`position'-`lo')*(total_asset_wan[`hi']-total_asset_wan[`lo'])
gen double wealth_plot=asinh(min(total_asset_wan,cap99))
bysort housing_portfolio (wealth_plot): gen double cumulative=_n/_N
rename housing_portfolio portfolio
keep portfolio wealth_plot cumulative
export delimited using "$TABLES/Wealth_Plot_Data_01_10_2026.csv", replace nolabel
use "$DATA/core_riskset_weights_01_10_2026.dta", clear
keep if sel_alt==1
tempname p
tempfile densitydata
postfile `p' byte entry int order double x density using `densitydata', replace
forvalues g=0/1 {
    quietly count if postsecondary_entry==`g' & !missing(ps_alt)
    local n=r(N)
    forvalues b=0/29 {
        local left=`b'/30
        local right=(`b'+1)/30
        quietly count if postsecondary_entry==`g' & ps_alt>=`left' & (ps_alt<`right' | (`b'==29 & ps_alt==1))
        local d=r(N)/(`n'/30)
        post `p' (`g') (2*`b') (`left') (`d')
        post `p' (`g') (2*`b'+1) (`right') (`d')
    }
}
postclose `p'
use `densitydata', clear
export delimited using "$TABLES/Entry_Plot_Data_01_10_2026.csv", replace nolabel

exit
}

if "`module'" == "figures" {
/* Figures. */
set scheme s2mono
graph set window fontface "Arial"
graph set eps fontface "Arial"
import delimited using "$TABLES/main_resource_probabilities_01_10_2026.csv",clear
keep if specification=="H3_resource_sequence"
gen double x=portfolio+cond(female==1,-.05,.05)
twoway (rcap ci_lb_pct ci_ub_pct x if female==1,lcolor(black)) ///
 (scatter probability_pct x if female==1,msymbol(Dh) mcolor(black) msize(medium)) ///
 (rcap ci_lb_pct ci_ub_pct x if female==0,lcolor(black)) ///
 (scatter probability_pct x if female==0,msymbol(O) mcolor(black) msize(medium)), ///
 xlabel(0 `""Housing-" "concentrated""' 1 "Housing-plus",labsize(small)) ///
 ylabel(0(20)80,angle(0) labsize(small) nogrid) yscale(range(0 80)) xscale(range(-.22 1.22)) ///
 xtitle("") ytitle("Adjusted probability of S&E entry (%)",size(small)) ///
 title("A. Adjusted probabilities",size(medsmall) color(black) pos(11)) ///
 legend(order(2 "Women" 4 "Men") rows(1) pos(12) ring(0) size(small) region(lcolor(none))) ///
 graphregion(color(white)) plotregion(lcolor(none)) name(prob,replace)
import delimited using "$TABLES/main_resource_contrasts_01_10_2026.csv",clear
keep if specification=="H3_resource_sequence"
gen y=cond(strpos(contrast,"Women minus men"),1,cond(substr(contrast,1,5)=="Women",3,2))
twoway (rcap ci_lb_pp ci_ub_pp y,horizontal lcolor(black)) ///
 (scatter y estimate_pp if y==3,msymbol(Dh) mcolor(black) msize(medium)) ///
 (scatter y estimate_pp if y==2,msymbol(O) mcolor(black) msize(medium)) ///
 (scatter y estimate_pp if y==1,msymbol(S) mcolor(black) msize(medium)), ///
 ylabel(3 "Women" 2 "Men" 1 `""Difference in contrasts" "(women − men)""',angle(0) labsize(small) nogrid) ///
 xlabel(-20 "−20" -10 "−10" 0 10 20 30,labsize(small)) xscale(range(-20 30)) yscale(range(.5 3.5)) ///
 xline(0,lcolor(gs10) lwidth(thin)) ytitle("") ///
 xtitle("Housing-plus minus housing-concentrated" "(percentage points)",size(small)) ///
 title("B. Housing-plus contrasts",size(medsmall) color(black) pos(11)) legend(off) ///
 graphregion(color(white)) plotregion(lcolor(none)) name(con,replace)
graph combine prob con, cols(2) xsize(9.3) ysize(4.1) graphregion(color(white)) imargin(small)
graph export "$FIGURES/Figure_1_01_10_2026.png",width(4200) replace
graph export "$FIGURES/Figure_1_01_10_2026.pdf",replace
graph export "$FIGURES/Figure_1_01_10_2026.eps",replace

import delimited using "$TABLES/field_destination_probabilities_01_10_2026.csv",clear
keep female outcome_code portfolio probability_pct ci_lb_pct ci_ub_pct
isid female outcome_code portfolio
assert _N==20
reshape wide probability_pct ci_lb_pct ci_ub_pct, i(female outcome_code) j(portfolio)
gen double x0=outcome_code-.14
gen double x1=outcome_code+.14
gen byte panel=cond(female==1,1,2)
label define panel 1 "A. Women" 2 "B. Men"
label values panel panel
twoway (pcspike probability_pct0 x0 probability_pct1 x1,lcolor(gs12) lwidth(medthin)) ///
 (rcap ci_lb_pct0 ci_ub_pct0 x0,lcolor(gs7) lwidth(thin)) ///
 (scatter probability_pct0 x0,msymbol(T) mcolor(gs7) msize(medium)) ///
 (rcap ci_lb_pct1 ci_ub_pct1 x1,lcolor(black) lwidth(thin)) ///
 (scatter probability_pct1 x1,msymbol(T) mcolor(black) msize(medium)), ///
 xlabel(1 `""Science and" "engineering""' 2 "Medicine" ///
 3 `""Business, law," "economics and" "management""' ///
 4 `""Humanities," "social science" "and education""' 5 "Other",labsize(2.5)) ///
 ylabel(0(20)80,angle(0) labsize(small) glcolor(gs14) glwidth(vthin)) ///
 yscale(range(0 80)) xscale(range(.55 5.45)) ///
 xtitle("") ytitle("Adjusted probability (%)",size(small)) ///
 legend(order(3 "Housing-concentrated" 5 "Housing-plus") rows(1) size(small) region(lcolor(none))) ///
 by(panel,cols(1) note("") legend(pos(6)) graphregion(color(white)) imargin(medsmall)) ///
 subtitle(,pos(11) color(black) bcolor(white) justification(left) nobexpand) ///
 xsize(6.2) ysize(7.2) graphregion(color(white)) plotregion(color(white) lcolor(none))
graph export "$FIGURES/Figure_B2_01_10_2026.png",width(3000) replace
graph export "$FIGURES/Figure_B2_01_10_2026.pdf",replace
graph export "$FIGURES/Figure_B2_01_10_2026.eps",replace

import delimited using "$TABLES/Wealth_Plot_Data_01_10_2026.csv",clear
rename portfolio housing_portfolio
local ticks
foreach t in -5 0 10 50 100 300 600 {
 local at=asinh(`t')
 local ticklabel "`t'"
 if `t'<0 local ticklabel "−5"
 local ticks `"`ticks' `at' "`ticklabel'""'
}
twoway (line cumulative wealth_plot if housing_portfolio==0,sort connect(J) lcolor(black) lpattern(solid)) ///
 (line cumulative wealth_plot if housing_portfolio==1,sort connect(J) lcolor(black) lpattern(dash)), ///
 xlabel(`ticks',labsize(small)) ylabel(0(.2)1,format(%3.1f) angle(0) labsize(small) nogrid) ///
 xtitle("Total net wealth (RMB 10,000; IHS-scaled axis)",size(small)) ytitle("Cumulative share",size(small)) ///
 legend(order(1 "Housing-concentrated" 2 "Housing-plus") rows(2) pos(5) ring(0) size(small) region(lcolor(none))) ///
 xsize(6.2) ysize(3.7) graphregion(color(white)) plotregion(color(white) lcolor(none))
graph export "$FIGURES/Figure_B1_01_10_2026.png",width(3000) replace
graph export "$FIGURES/Figure_B1_01_10_2026.pdf",replace
graph export "$FIGURES/Figure_B1_01_10_2026.eps",replace

import delimited using "$TABLES/Entry_Plot_Data_01_10_2026.csv",clear
rename entry postsecondary_entry
sort postsecondary_entry order
twoway (line density x if postsecondary_entry==0,lpattern(dash) lcolor(black)) ///
 (line density x if postsecondary_entry==1,lpattern(solid) lcolor(black)), ///
 xlabel(0(.2)1,format(%3.1f) labsize(small)) ylabel(,format(%9.0f) angle(0) nogrid labsize(small)) ///
 xtitle("Estimated probability of postsecondary entry",size(small)) ytitle("Density",size(small)) ///
 legend(order(2 "Entrants" 1 "Non-entrants") rows(2) pos(2) ring(0) size(small) region(lcolor(none))) ///
 xsize(6.2) ysize(3.7) graphregion(color(white)) plotregion(color(white) lcolor(none))
graph export "$FIGURES/Figure_D1_01_10_2026.png",width(3000) replace
graph export "$FIGURES/Figure_D1_01_10_2026.pdf",replace
graph export "$FIGURES/Figure_D1_01_10_2026.eps",replace

exit
}

display as error "Unknown module."
exit 198
