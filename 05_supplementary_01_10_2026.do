/* Supplementary. */
version 18
args module
if "`module'" == "" {
    do "$CODE/05_supplementary_01_10_2026.do" alternative_models
    do "$CODE/05_supplementary_01_10_2026.do" early_waves
    do "$CODE/05_supplementary_01_10_2026.do" selection_weights
    do "$CODE/05_supplementary_01_10_2026.do" bootstrap
    exit
}

if "`module'" == "alternative_models" {
/* Alternative models. */
version 18
clear
set more off
set linesize 180

if "$ROOT" == "" {
    display as error "Run 00_master_01_10_2026.do from the package folder."
    exit 198
}

use "$DATA/core_entrants_01_10_2026.dta", clear

egen double liquid_amount = rowtotal(savings_same financial_product_rebuilt), missing
replace liquid_amount = . if missing(savings_same, financial_product_rebuilt)
generate double cpi_to_2022 = 1
replace cpi_to_2022 = 1.164304 if wave == 2014
replace cpi_to_2022 = 1.085195 if wave == 2018
replace cpi_to_2022 = 1.029693 if wave == 2020
generate double liquid_amount_2022 = liquid_amount * cpi_to_2022
generate double business_amount_2022 = fixed_asset_same * cpi_to_2022
generate double total_asset_2022 = total_asset_same * cpi_to_2022
generate double ihs_total_asset_2022 = asinh(total_asset_2022)

generate byte housing_detail = .
replace housing_detail = 1 if has_house == 1 & finance_liquid == 0 & has_business == 0
replace housing_detail = 2 if has_house == 1 & finance_liquid == 1 & has_business == 0
replace housing_detail = 3 if has_house == 1 & finance_liquid == 0 & has_business == 1
replace housing_detail = 4 if has_house == 1 & finance_liquid == 1 & has_business == 1
label define housing_detail_lbl ///
    1 "Housing-concentrated" ///
    2 "Housing + liquid" ///
    3 "Housing + productive" ///
    4 "Housing + liquid + productive", replace
label values housing_detail housing_detail_lbl

tempname results counts destinations
tempfile results_data counts_data destinations_data
postfile `results' str40 specification str120 contrast double estimate se p ///
    ci_lb ci_ub long model_N using `results_data', replace
postfile `counts' str18 definition int wave byte category female long N ///
    using `counts_data', replace
postfile `destinations' str36 outcome byte outcome_code female portfolio ///
    double probability se ci_lb ci_ub long model_N using `destinations_data', replace
global APP_RESULTS "`results'"

capture program drop post_appendix_contrasts
program define post_appendix_contrasts
    syntax, SPEC(string) MODELN(integer) [EXPOSURE(name)]
    if "`exposure'"=="" local exposure housing_portfolio
    quietly margins female#`exposure', post noestimcheck

    quietly lincom _b[0bn.female#0.`exposure'] - ///
        _b[0bn.female#1.`exposure']
    post $APP_RESULTS ("`spec'") ("Men, concentrated - plus") ///
        (r(estimate)) (r(se)) (r(p)) (r(lb)) (r(ub)) (`modeln')

    quietly lincom _b[1.female#0.`exposure'] - ///
        _b[1.female#1.`exposure']
    post $APP_RESULTS ("`spec'") ("Women, concentrated - plus") ///
        (r(estimate)) (r(se)) (r(p)) (r(lb)) (r(ub)) (`modeln')

    quietly lincom ///
        (_b[1.female#0.`exposure'] - _b[0bn.female#0.`exposure']) - ///
        (_b[1.female#1.`exposure'] - _b[0bn.female#1.`exposure'])
    post $APP_RESULTS ("`spec'") ("Gender-gap contrast: concentrated - plus") ///
        (r(estimate)) (r(se)) (r(p)) (r(lb)) (r(ub)) (`modeln')
end

quietly logit stem i.female##i.housing_detail $C_OUTCOME_WEALTH, vce(robust)
local model_N = e(N)
quietly margins female#housing_detail, post noestimcheck

foreach ref in 2 3 4 {
    local refname "Housing + liquid"
    if `ref' == 3 local refname "Housing + productive"
    if `ref' == 4 local refname "Housing + liquid + productive"

    quietly lincom _b[0bn.female#1.housing_detail] - ///
        _b[0bn.female#`ref'.housing_detail]
    post `results' ("detailed_plus_wealth") ("Men: concentrated - `refname'") ///
        (r(estimate)) (r(se)) (r(p)) (r(lb)) (r(ub)) (`model_N')

    quietly lincom _b[1.female#1.housing_detail] - ///
        _b[1.female#`ref'.housing_detail]
    post `results' ("detailed_plus_wealth") ("Women: concentrated - `refname'") ///
        (r(estimate)) (r(se)) (r(p)) (r(lb)) (r(ub)) (`model_N')

    quietly lincom ///
        (_b[1.female#1.housing_detail] - _b[0bn.female#1.housing_detail]) - ///
        (_b[1.female#`ref'.housing_detail] - _b[0bn.female#`ref'.housing_detail])
    post `results' ("detailed_plus_wealth") ("Gender-gap contrast: concentrated - `refname'") ///
        (r(estimate)) (r(se)) (r(p)) (r(lb)) (r(ub)) (`model_N')
}

quietly test ///
    (_b[1.female#2.housing_detail] - _b[0bn.female#2.housing_detail] = ///
     _b[1.female#3.housing_detail] - _b[0bn.female#3.housing_detail]) ///
    (_b[1.female#2.housing_detail] - _b[0bn.female#2.housing_detail] = ///
     _b[1.female#4.housing_detail] - _b[0bn.female#4.housing_detail])
post `results' ("detailed_pooling_tests") ("Joint: plus-group gender gaps equal") ///
    (.) (.) (r(p)) (.) (.) (`model_N')

quietly test ///
    (_b[1.female#1.housing_detail] - _b[0bn.female#1.housing_detail] = ///
     _b[1.female#2.housing_detail] - _b[0bn.female#2.housing_detail]) ///
    (_b[1.female#1.housing_detail] - _b[0bn.female#1.housing_detail] = ///
     _b[1.female#3.housing_detail] - _b[0bn.female#3.housing_detail]) ///
    (_b[1.female#1.housing_detail] - _b[0bn.female#1.housing_detail] = ///
     _b[1.female#4.housing_detail] - _b[0bn.female#4.housing_detail])
post `results' ("detailed_pooling_tests") ///
    ("Joint: concentrated contrasts equal zero") ///
    (.) (.) (r(p)) (.) (.) (`model_N')

foreach w in 0 2014 2018 2020 2022 {
    local waveif "1"
    if `w' > 0 local waveif "wave == `w'"
    forvalues p = 1/4 {
        forvalues g = 0/1 {
            quietly count if `waveif' & housing_detail == `p' & female == `g'
            post `counts' ("detailed") (`w') (`p') (`g') (r(N))
        }
    }
}

foreach threshold in 0 100 1000 5000 10000 {
    capture drop finance_t portfolio_t
    generate byte finance_t = liquid_amount > `threshold' if !missing(liquid_amount)
    generate byte portfolio_t = .
    replace portfolio_t = 0 if has_house == 1 & finance_t == 0 & has_business == 0
    replace portfolio_t = 1 if has_house == 1 & (finance_t == 1 | has_business == 1)

    quietly logit stem i.female##i.portfolio_t $C_OUTCOME_WEALTH ///
        if !missing(portfolio_t), vce(robust)
    local model_N = e(N)
    post_appendix_contrasts, spec("liquid_threshold_`threshold'") modeln(`model_N') exposure(portfolio_t)

    forvalues p = 0/1 {
        forvalues g = 0/1 {
            quietly count if portfolio_t == `p' & female == `g'
            post `counts' ("liquid_`threshold'") (0) (`p') (`g') (r(N))
        }
    }
}

foreach threshold in 0 1000 5000 {
    capture drop business_t portfolio_bt
    generate byte business_t = fixed_asset_same > `threshold' if !missing(fixed_asset_same)
    generate byte portfolio_bt = .
    replace portfolio_bt = 0 if has_house == 1 & finance_liquid == 0 & business_t == 0
    replace portfolio_bt = 1 if has_house == 1 & (finance_liquid == 1 | business_t == 1)

    quietly logit stem i.female##i.portfolio_bt $C_OUTCOME_WEALTH ///
        if !missing(portfolio_bt), vce(robust)
    local model_N = e(N)
    post_appendix_contrasts, spec("business_threshold_`threshold'") modeln(`model_N') exposure(portfolio_bt)

    forvalues p = 0/1 {
        forvalues g = 0/1 {
            quietly count if portfolio_bt == `p' & female == `g'
            post `counts' ("business_`threshold'") (0) (`p') (`g') (r(N))
        }
    }
}

foreach threshold in 1000 5000 {
    capture drop finance_real_t portfolio_real_t
    generate byte finance_real_t = liquid_amount_2022 > `threshold' ///
        if !missing(liquid_amount_2022)
    generate byte portfolio_real_t = .
    replace portfolio_real_t = 0 if has_house == 1 & finance_real_t == 0 & has_business == 0
    replace portfolio_real_t = 1 if has_house == 1 & (finance_real_t == 1 | has_business == 1)

    quietly logit stem i.female##i.portfolio_real_t $C_OUTCOME_WEALTH ///
        if !missing(portfolio_real_t), vce(robust)
    local model_N = e(N)
    post_appendix_contrasts, spec("liquid_real_threshold_`threshold'") modeln(`model_N') exposure(portfolio_real_t)

    forvalues p = 0/1 {
        forvalues g = 0/1 {
            quietly count if portfolio_real_t == `p' & female == `g'
            post `counts' ("liquid_real_`threshold'") (0) (`p') (`g') (r(N))
        }
    }
}

foreach dropwave in 2014 2018 2020 2022 {
    quietly logit stem i.female##i.housing_portfolio $C_OUTCOME_WEALTH ///
        if wave != `dropwave', vce(robust)
    local model_N = e(N)
    quietly margins female#housing_portfolio, post noestimcheck
    quietly lincom ///
        (_b[1.female#0.housing_portfolio] - ///
         _b[0bn.female#0.housing_portfolio]) - ///
        (_b[1.female#1.housing_portfolio] - ///
         _b[0bn.female#1.housing_portfolio])
    post `results' ("drop_`dropwave'_plus_wealth") ///
        ("Gender-gap contrast: concentrated - plus") ///
        (r(estimate)) (r(se)) (r(p)) (r(lb)) (r(ub)) (`model_N')
}

global C_NOWAVE_WEALTH ///
    c.ihs_total_asset_same ///
    c.age_entry_imp ///
    i.level i.provcd_h ///
    i.hukou_agri_cat i.urban_cat ///
    i.parent_college_cat ///
    c.ihs_hh_income_pc_imp i.income_miss

quietly regress stem i.female##i.housing_portfolio##ib2014.wave ///
    $C_NOWAVE_WEALTH, vce(robust)
local model_N = e(N)
quietly testparm 1.female#1.housing_portfolio#i.wave
post `results' ("wave_heterogeneity_lpm") ///
    ("Joint gender x portfolio x wave test") ///
    (.) (.) (r(p)) (.) (.) (`model_N')

quietly logit stem i.female##i.housing_portfolio $C_PARENT_WEALTH, vce(robust)
local model_N = e(N)
post_appendix_contrasts, spec("additional_parent_controls") modeln(`model_N')

quietly logit stem i.female##i.housing_portfolio $C_ORIENT_WEALTH, vce(robust)
local model_N = e(N)
post_appendix_contrasts, spec("additional_orientation_controls") modeln(`model_N')

quietly logit stem i.female##i.housing_portfolio ///
    i.has_debt c.ihs_debt_total_same $C_OUTCOME_WEALTH, vce(robust)
local model_N = e(N)
post_appendix_contrasts, spec("additional_debt_controls") modeln(`model_N')

quietly logit stem i.female##i.housing_portfolio i.asset_q_same $C_MAIN, vce(robust)
local model_N = e(N)
post_appendix_contrasts, spec("wealth_quartiles") modeln(`model_N')

quietly logit stem i.female##i.housing_portfolio ///
    c.ihs_total_asset_2022 $C_MAIN, vce(robust)
local model_N = e(N)
post_appendix_contrasts, spec("wealth_cpi_2022") modeln(`model_N')

quietly summarize ihs_total_asset_same if housing_portfolio == 0, detail
local low0 = r(p1)
local high0 = r(p99)
quietly summarize ihs_total_asset_same if housing_portfolio == 1, detail
local low1 = r(p1)
local high1 = r(p99)
local common_low = max(`low0', `low1')
local common_high = min(`high0', `high1')
local support_tolerance = 1e-6
quietly logit stem i.female##i.housing_portfolio $C_OUTCOME_WEALTH ///
    if inrange(ihs_total_asset_same, ///
    `common_low' - `support_tolerance', ///
    `common_high' + `support_tolerance'), vce(robust)
local model_N = e(N)
post_appendix_contrasts, spec("wealth_common_support_p1_p99") modeln(`model_N')

forvalues outcome = 1/5 {
    local outname "S&E"
    if `outcome' == 2 local outname "Medicine"
    if `outcome' == 3 local outname "Business/law/economics/management"
    if `outcome' == 4 local outname "Humanities/social science/education"
    if `outcome' == 5 local outname "Other"

    quietly mlogit field5 i.female##i.housing_portfolio ///
        $C_DESTINATION_WEALTH, baseoutcome(5) vce(robust)
    local model_N = e(N)
    quietly margins female#housing_portfolio, predict(outcome(`outcome'))
    matrix destination_b = r(b)
    matrix destination_table = r(table)
    foreach g in 0 1 {
        foreach p in 0 1 {
            local col = 1 + 2 * `g' + `p'
            local probability = destination_b[1,`col']
            local se = destination_table[2,`col']
            local lb = max(0, destination_table[5,`col'])
            local ub = min(1, destination_table[6,`col'])
            post `destinations' ("`outname'") (`outcome') (`g') (`p') ///
                (`probability') (`se') (`lb') (`ub') (`model_N')
        }
    }
}

postclose `results'
postclose `counts'
postclose `destinations'

use `results_data', clear
generate str120 original_contrast = contrast
generate double original_estimate = estimate
replace estimate=-estimate
rename ci_lb old_lb
generate double ci_lb=-ci_ub
replace ci_ub=-old_lb
drop old_lb
replace contrast="Men: housing-plus - concentrated" if original_contrast=="Men, concentrated - plus"
replace contrast="Women: housing-plus - concentrated" if original_contrast=="Women, concentrated - plus"
replace contrast="Women minus men difference in contrasts" if original_contrast=="Gender-gap contrast: concentrated - plus"
replace contrast=subinstr(original_contrast,"Men: concentrated - ","Men: ",.)+" - concentrated" if strpos(original_contrast,"Men: concentrated - ")==1
replace contrast=subinstr(original_contrast,"Women: concentrated - ","Women: ",.)+" - concentrated" if strpos(original_contrast,"Women: concentrated - ")==1
replace contrast=subinstr(original_contrast,"Gender-gap contrast: concentrated - ","Women minus men: ",.) if strpos(original_contrast,"Gender-gap contrast: concentrated - Housing")==1
generate estimate_pp = 100 * estimate
generate se_pp = 100 * se
generate ci_lb_pp = 100 * ci_lb
generate ci_ub_pp = 100 * ci_ub
save "$MODELS/core_appendix_results_01_10_2026.dta", replace
export delimited using "$TABLES/core_appendix_results_01_10_2026.csv", replace

use `counts_data', clear
save "$MODELS/detailed_portfolio_counts_01_10_2026.dta", replace
export delimited using "$TABLES/detailed_portfolio_counts_01_10_2026.csv", replace

use `destinations_data', clear
generate probability_pct = 100 * probability
generate se_pct = 100 * se
generate ci_lb_pct = 100 * ci_lb
generate ci_ub_pct = 100 * ci_ub
save "$MODELS/field_destination_probabilities_01_10_2026.dta", replace
export delimited using "$TABLES/field_destination_probabilities_01_10_2026.csv", replace

exit
}

if "`module'" == "early_waves" {
/* Early waves. */
version 18
clear
set more off
set linesize 180

tempname resultpost countpost
tempfile resultdata countdata current14 raw2010family raw2010students
postfile `resultpost' str38 specification str48 contrast double estimate se p ///
    ci_lb ci_ub long model_N using `resultdata', replace
postfile `countpost' str32 sample int wave byte group female long N ///
    using `countdata', replace
global RESULTPOST "`resultpost'"

capture program drop post_gap_contrast
program define post_gap_contrast
    syntax, Spec(string) Groupvar(name)
    local modeln = e(N)
    quietly margins female#`groupvar', post

    quietly lincom _b[1.female#0.`groupvar'] - _b[0bn.female#0.`groupvar']
    post $RESULTPOST ("`spec'") ("Women - men, housing concentrated") ///
        (r(estimate)) (r(se)) (r(p)) (r(lb)) (r(ub)) (`modeln')

    quietly lincom _b[1.female#1.`groupvar'] - _b[0bn.female#1.`groupvar']
    post $RESULTPOST ("`spec'") ("Women - men, housing plus") ///
        (r(estimate)) (r(se)) (r(p)) (r(lb)) (r(ub)) (`modeln')

    quietly lincom _b[0bn.female#0.`groupvar'] - _b[0bn.female#1.`groupvar']
    post $RESULTPOST ("`spec'") ("Men, concentrated - plus") ///
        (r(estimate)) (r(se)) (r(p)) (r(lb)) (r(ub)) (`modeln')

    quietly lincom _b[1.female#0.`groupvar'] - _b[1.female#1.`groupvar']
    post $RESULTPOST ("`spec'") ("Women, concentrated - plus") ///
        (r(estimate)) (r(se)) (r(p)) (r(lb)) (r(ub)) (`modeln')

    quietly lincom ///
        (_b[1.female#0.`groupvar'] - _b[0bn.female#0.`groupvar']) - ///
        (_b[1.female#1.`groupvar'] - _b[0bn.female#1.`groupvar'])
    post $RESULTPOST ("`spec'") ("Gender-gap contrast: concentrated - plus") ///
        (r(estimate)) (r(se)) (r(p)) (r(lb)) (r(ub)) (`modeln')
end

use "$ENTRANT_SOURCE", clear
generate byte housing_concentration_all = .
replace housing_concentration_all = 0 if has_house == 1 & ///
    finance_liquid == 0 & has_business == 0
replace housing_concentration_all = 1 if has_house == 1 & ///
    (finance_liquid == 1 | has_business == 1)

foreach w in 0 2012 2014 2018 2020 2022 {
    local waveif "1"
    if `w' > 0 local waveif "wave == `w'"
    forvalues category = 0/1 {
        forvalues g = 0/1 {
            quietly count if `waveif' & housing_concentration_all == `category' & female == `g'
            post `countpost' ("2012_floor_corrected") (`w') (`category') (`g') (r(N))
        }
    }
}

quietly logit stem i.female##i.housing_concentration_all $C_MAIN ///
    if !missing(housing_concentration_all), vce(robust)
post_gap_contrast, spec("2012_2022_floor_corrected") groupvar(housing_concentration_all)

quietly logit stem i.female##i.housing_concentration_all ///
    c.ihs_total_asset_same $C_MAIN ///
    if !missing(housing_concentration_all), vce(robust)
post_gap_contrast, spec("2012_2022_floor_plus_wealth") groupvar(housing_concentration_all)

use "$RAW/2010/cfps2010famecon_201906.dta", clear
keep fid provcd urban faminc familysize total_asset resivalue_new otherhousevalue ///
    savings stock funds company
drop if missing(fid)
isid fid

foreach v in faminc familysize total_asset resivalue_new otherhousevalue ///
    savings stock funds company {
    replace `v' = . if `v' < 0
}

egen double house_gross_2010 = rowtotal(resivalue_new otherhousevalue), missing
replace house_gross_2010 = . if missing(resivalue_new) & missing(otherhousevalue)
egen double liquid_2010 = rowtotal(savings stock funds), missing
replace liquid_2010 = . if missing(savings) & missing(stock) & missing(funds)
generate double business_2010 = company

generate byte has_house_2010 = house_gross_2010 > 0 if !missing(house_gross_2010)
generate byte has_liquid_2010 = liquid_2010 > 0 if !missing(liquid_2010)
generate byte has_business_2010 = business_2010 > 0 if !missing(business_2010)
generate byte housing_concentration = .
replace housing_concentration = 0 if has_house_2010 == 1 & ///
    has_liquid_2010 == 0 & has_business_2010 == 0
replace housing_concentration = 1 if has_house_2010 == 1 & ///
    (has_liquid_2010 == 1 | has_business_2010 == 1)

generate double income_pc_2010 = faminc / familysize ///
    if !missing(faminc, familysize) & familysize > 0
generate double ihs_income = asinh(income_pc_2010)
generate byte income_missing = missing(ihs_income)
generate double ihs_wealth = asinh(total_asset)
keep fid provcd urban housing_concentration ihs_income income_missing ihs_wealth
save `raw2010family', replace

use "$RAW/2010/cfps2010adult_201906.dta", clear
keep pid fid gender qa1age qa1y_best qa2 tb4_a_f tb4_a_m ///
    kr1 kr5 kr6 kr601 qc502
drop if missing(pid)
isid pid

generate double age = qa1age
replace age = 2010 - qa1y_best if missing(age) & !missing(qa1y_best)
generate byte ordinary_student = ///
    (kr1 == 5 & kr5 == 1) | (kr1 == 6 & kr6 == 1)
generate byte recent_hs_proxy = inlist(qc502, 2009, 2010)
keep if ordinary_student == 1 & age <= 25 & !missing(age)

generate byte female = gender == 0 if inlist(gender, 0, 1)
generate byte level = .
replace level = 1 if kr1 == 5
replace level = 2 if kr1 == 6
generate byte stem = inlist(kr601, 7, 8) ///
    if kr601 >= 0 & !missing(kr601)
generate byte hukou = .
replace hukou = 1 if qa2 == 1
replace hukou = 0 if qa2 >= 0 & qa2 != 1 & !missing(qa2)
replace hukou = 9 if missing(hukou)
generate byte parent_college = .
replace parent_college = 1 if inrange(tb4_a_f, 6, 9) | inrange(tb4_a_m, 6, 9)
replace parent_college = 0 if inrange(tb4_a_f, 0, 5) & inrange(tb4_a_m, 0, 5)
replace parent_college = 9 if missing(parent_college)
generate int wave = 2010

merge m:1 fid using `raw2010family', keep(master match) generate(merge_family2010)
replace urban = . if urban < 0
generate byte urban_group = urban
replace urban_group = 9 if missing(urban_group)
save `raw2010students', replace

use "$ENTRANT_SOURCE", clear
keep if wave >= 2014
generate byte housing_concentration = .
replace housing_concentration = 0 if has_house == 1 & ///
    finance_liquid == 0 & has_business == 0
replace housing_concentration = 1 if has_house == 1 & ///
    (finance_liquid == 1 | has_business == 1)
capture drop age
rename age_entry_imp age
capture drop hukou
rename hukou_agri_cat hukou
capture drop parent_college
rename parent_college_cat parent_college
capture drop urban_group
rename urban_cat urban_group
capture drop provcd
rename provcd_h provcd
capture drop ihs_income
generate double ihs_income = ihs_hh_income_pc_imp
capture drop income_missing
generate byte income_missing = income_miss
capture drop ihs_wealth
generate double ihs_wealth = ihs_total_asset_same
capture drop recent_hs_proxy
generate byte recent_hs_proxy = 1
keep pid female stem level wave age provcd hukou parent_college urban_group ///
    housing_concentration ihs_income income_missing ihs_wealth recent_hs_proxy
save `current14', replace

foreach sample in recent_hs student_stock {
    use `raw2010students', clear
    if "`sample'" == "recent_hs" keep if recent_hs_proxy == 1
    keep pid female stem level wave age provcd hukou parent_college urban_group ///
        housing_concentration ihs_income income_missing ihs_wealth recent_hs_proxy
    append using `current14'

    quietly summarize ihs_income if !missing(ihs_income), meanonly
    replace ihs_income = r(mean) if missing(ihs_income)
    replace income_missing = 1 if missing(income_missing)

    foreach w in 0 2010 2014 2018 2020 2022 {
        local waveif "1"
        if `w' > 0 local waveif "wave == `w'"
        forvalues category = 0/1 {
            forvalues g = 0/1 {
                quietly count if `waveif' & housing_concentration == `category' & female == `g'
                post `countpost' ("2010_`sample'") (`w') (`category') (`g') (r(N))
            }
        }
    }

    quietly logit stem i.female##i.housing_concentration ///
        c.age i.level i.wave i.provcd i.hukou i.urban_group i.parent_college ///
        c.ihs_income i.income_missing ///
        if !missing(housing_concentration), vce(robust)
    post_gap_contrast, spec("2010_`sample'_plus_2014_2022") ///
        groupvar(housing_concentration)

    quietly logit stem i.female##i.housing_concentration ///
        c.age i.level i.wave i.provcd i.hukou i.urban_group i.parent_college ///
        c.ihs_income i.income_missing c.ihs_wealth ///
        if !missing(housing_concentration), vce(robust)
    post_gap_contrast, spec("2010_`sample'_plus_wealth") ///
        groupvar(housing_concentration)
}

postclose `resultpost'
postclose `countpost'

use `resultdata', clear
generate estimate_pp = 100 * estimate
generate se_pp = 100 * se
generate ci_lb_pp = 100 * ci_lb
generate ci_ub_pp = 100 * ci_ub
save "$MODELS/raw_wave_extensions_01_10_2026.dta", replace
export delimited using "$TABLES/raw_wave_extensions_01_10_2026.csv", replace

use `countdata', clear
save "$MODELS/raw_wave_extension_counts_01_10_2026.dta", replace
export delimited using "$TABLES/raw_wave_extension_counts_01_10_2026.csv", replace

exit
}

if "`module'" == "selection_weights" {
/* Selection weights. */
version 18
clear
set more off
set linesize 180

use "$DATA/core_riskset_01_10_2026.dta", clear
capture drop sel_alt ps_alt sw_alt ipw_alt ow_entry ow_full mw_entry mw_full

quietly logit postsecondary_entry ///
    i.female##i.housing_portfolio ///
    i.age_entry_imp ///
    i.wave i.provcd_h ///
    i.hukou_agri_cat i.urban_cat ///
    i.parent_college_cat ///
    c.ihs_hh_income_pc_imp i.income_miss ///
    c.ihs_total_asset_same if wealth_missing == 0, vce(cluster pid)

generate byte sel_alt = e(sample)
predict double ps_alt if sel_alt == 1, pr
quietly summarize postsecondary_entry if sel_alt == 1, meanonly
local p_entry = r(mean)

generate double sw_alt = `p_entry' / ps_alt ///
    if sel_alt == 1 & core_outcome_analytic == 1 & ps_alt > 0
quietly _pctile sw_alt if !missing(sw_alt), p(1 99)
local p1 = r(r1)
local p99 = r(r2)
generate double ipw_alt = sw_alt
replace ipw_alt = `p1' if ipw_alt < `p1' & !missing(ipw_alt)
replace ipw_alt = `p99' if ipw_alt > `p99' & !missing(ipw_alt)
generate double ow_entry = 1 - ps_alt ///
    if sel_alt == 1 & core_outcome_analytic == 1
generate double ow_full = cond(postsecondary_entry == 1, 1 - ps_alt, ps_alt) ///
    if sel_alt == 1
generate double mw_entry = min(ps_alt, 1 - ps_alt) / ps_alt ///
    if sel_alt == 1 & core_outcome_analytic == 1 & ps_alt > 0
generate double mw_full = cond(postsecondary_entry == 1, ///
    min(ps_alt, 1 - ps_alt) / ps_alt, ///
    min(ps_alt, 1 - ps_alt) / (1 - ps_alt)) if sel_alt == 1

compress
save "$DATA/core_riskset_weights_01_10_2026.dta", replace

tempname results summaries balance
tempfile results_data summaries_data balance_data
postfile `results' str30 specification str48 contrast double estimate se p ///
    ci_lb ci_ub long model_N using `results_data', replace
postfile `summaries' str24 method double N mean_w min_w max_w ess ///
    using `summaries_data', replace
postfile `balance' str24 method str28 covariate double smd ///
    using `balance_data', replace
global ALT_RESULTS "`results'"

capture program drop post_alt_results
program define post_alt_results
    syntax, SPEC(string) MODELN(integer)
    quietly margins female#housing_portfolio, post noestimcheck

    quietly lincom _b[0bn.female#0.housing_portfolio] - ///
        _b[0bn.female#1.housing_portfolio]
    post $ALT_RESULTS ("`spec'") ("Men, concentrated - plus") ///
        (r(estimate)) (r(se)) (r(p)) (r(lb)) (r(ub)) (`modeln')

    quietly lincom _b[1.female#0.housing_portfolio] - ///
        _b[1.female#1.housing_portfolio]
    post $ALT_RESULTS ("`spec'") ("Women, concentrated - plus") ///
        (r(estimate)) (r(se)) (r(p)) (r(lb)) (r(ub)) (`modeln')

    quietly lincom ///
        (_b[1.female#0.housing_portfolio] - _b[0bn.female#0.housing_portfolio]) - ///
        (_b[1.female#1.housing_portfolio] - _b[0bn.female#1.housing_portfolio])
    post $ALT_RESULTS ("`spec'") ("Gender-gap contrast: concentrated - plus") ///
        (r(estimate)) (r(se)) (r(p)) (r(lb)) (r(ub)) (`modeln')
end

foreach item in "riskset_ipw ipw_alt" "overlap ow_entry" "matching mw_entry" {
    tokenize "`item'"
    local method "`1'"
    local wvar "`2'"

    quietly summarize `wvar' if core_outcome_analytic == 1, meanonly
    local N = r(N)
    local mean_w = r(mean)
    local min_w = r(min)
    local max_w = r(max)
    local sum_w = r(sum)
    tempvar w2
    generate double `w2' = `wvar'^2 if core_outcome_analytic == 1
    quietly summarize `w2', meanonly
    local ess = (`sum_w'^2) / r(sum)
    drop `w2'
    post `summaries' ("`method'") (`N') (`mean_w') (`min_w') (`max_w') (`ess')

    quietly logit stem i.female##i.housing_portfolio $C_OUTCOME_WEALTH ///
        [pw = `wvar'] if core_outcome_analytic == 1 & !missing(`wvar'), vce(robust)
    local model_N = e(N)
    post_alt_results, spec("`method'_adjusted") modeln(`model_N')

    quietly logit stem i.female##i.housing_portfolio ///
        [pw = `wvar'] if core_outcome_analytic == 1 & !missing(`wvar'), vce(robust)
    local model_N = e(N)
    post_alt_results, spec("`method'_cell_means") modeln(`model_N')
}

generate double age_c = age_entry_imp - 20
generate double age_sq = age_c^2
quietly tabulate age_entry_imp if sel_alt == 1, generate(bal_agecat_)
quietly tabulate wave if sel_alt == 1, generate(bal_wave_)
quietly tabulate provcd_h if sel_alt == 1, generate(bal_province_)
quietly tabulate hukou_agri_cat if sel_alt == 1, generate(bal_hukou_)
quietly tabulate urban_cat if sel_alt == 1, generate(bal_urban_)
quietly tabulate parent_college_cat if sel_alt == 1, generate(bal_parent_)
ds bal_agecat_* bal_wave_* bal_province_* bal_hukou_* bal_urban_* bal_parent_*
local factor_balance `r(varlist)'

local balance_vars female housing_portfolio female_plus age_entry_imp age_sq ///
    `factor_balance' ihs_hh_income_pc_imp income_miss ihs_total_asset_same
foreach v of local balance_vars {
    quietly summarize `v' if sel_alt == 1
    local mt = r(mean)
    local vt = r(Var)
    quietly summarize `v' if core_outcome_analytic == 1
    local me = r(mean)
    local ve = r(Var)
    local smd = (`me' - `mt') / sqrt((`ve' + `vt') / 2)
    post `balance' ("unweighted_riskset") ("`v'") (`smd')
}
foreach v of local balance_vars {
    quietly summarize `v' if sel_alt == 1 & postsecondary_entry == 1
    local m1 = r(mean)
    local v1 = r(Var)
    quietly summarize `v' if sel_alt == 1 & postsecondary_entry == 0
    local m0 = r(mean)
    local v0 = r(Var)
    local smd = (`m1' - `m0') / sqrt((`v1' + `v0') / 2)
    post `balance' ("unweighted_entry_groups") ("`v'") (`smd')
}
foreach v of local balance_vars {
    quietly summarize `v' if sel_alt == 1
    local mt = r(mean)
    local vt = r(Var)
    quietly summarize `v' [aw = ipw_alt] ///
        if core_outcome_analytic == 1 & !missing(ipw_alt)
    local me = r(mean)
    local ve = r(Var)
    local smd = (`me' - `mt') / sqrt((`ve' + `vt') / 2)
    post `balance' ("riskset_ipw") ("`v'") (`smd')
}

foreach item in "overlap ow_full" "matching mw_full" {
    tokenize "`item'"
    local method "`1'"
    local wfull "`2'"
    foreach v of local balance_vars {
        quietly summarize `v' [aw = `wfull'] ///
            if sel_alt == 1 & postsecondary_entry == 1
        local m1 = r(mean)
        local v1 = r(Var)
        quietly summarize `v' [aw = `wfull'] ///
            if sel_alt == 1 & postsecondary_entry == 0
        local m0 = r(mean)
        local v0 = r(Var)
        local smd = (`m1' - `m0') / sqrt((`v1' + `v0') / 2)
        post `balance' ("`method'") ("`v'") (`smd')
    }
}

postclose `results'
postclose `summaries'
postclose `balance'

use `results_data', clear
generate estimate_pp = 100 * estimate
generate se_pp = 100 * se
generate ci_lb_pp = 100 * ci_lb
generate ci_ub_pp = 100 * ci_ub
save "$MODELS/selection_alternative_results_01_10_2026.dta", replace
export delimited using "$TABLES/selection_alternative_results_01_10_2026.csv", replace

use `summaries_data', clear
save "$MODELS/selection_alternative_summaries_01_10_2026.dta", replace
export delimited using "$TABLES/selection_alternative_summaries_01_10_2026.csv", replace

use `balance_data', clear
generate abs_smd = abs(smd)
gsort method -abs_smd
save "$MODELS/selection_alternative_balance_01_10_2026.dta", replace
export delimited using "$TABLES/selection_alternative_balance_01_10_2026.csv", replace

exit
}

if "`module'" == "bootstrap" {
/* Bootstrap. */
version 18
clear
set more off
set linesize 180

local reps = $BOOT_REPS

set seed 260721
tempname draws
tempfile draws_data
postfile `draws' int replicate byte success_ipw success_ow success_mw ///
    int error_ipw error_ow error_mw double did_ipw did_ow did_mw ///
    using `draws_data', replace

forvalues b = 1/`reps' {
    quietly use "$DATA/core_riskset_01_10_2026.dta", clear
    capture drop boot_pid sel_b ps_b sw_b ipw_b ow_b mw_b

    capture quietly bsample, cluster(pid) idcluster(boot_pid)
    if _rc {
        post `draws' (`b') (0) (0) (0) (_rc) (_rc) (_rc) (.) (.) (.)
        continue
    }

    capture quietly logit postsecondary_entry ///
        i.female##i.housing_portfolio i.age_entry_imp ///
        i.wave i.provcd_h i.hukou_agri_cat i.urban_cat ///
        i.parent_college_cat c.ihs_hh_income_pc_imp i.income_miss ///
        c.ihs_total_asset_same if wealth_missing == 0, vce(cluster boot_pid)
    if _rc {
        post `draws' (`b') (0) (0) (0) (_rc) (_rc) (_rc) (.) (.) (.)
        continue
    }

    generate byte sel_b = e(sample)
    capture predict double ps_b if sel_b == 1, pr
    if _rc {
        post `draws' (`b') (0) (0) (0) (_rc) (_rc) (_rc) (.) (.) (.)
        continue
    }

    quietly summarize postsecondary_entry if sel_b == 1, meanonly
    local p_entry = r(mean)
    generate double sw_b = `p_entry' / ps_b ///
        if sel_b == 1 & core_outcome_analytic == 1 & ps_b > 0
    quietly _pctile sw_b if !missing(sw_b), p(1 99)
    local p1 = r(r1)
    local p99 = r(r2)
    generate double ipw_b = sw_b
    replace ipw_b = `p1' if ipw_b < `p1' & !missing(ipw_b)
    replace ipw_b = `p99' if ipw_b > `p99' & !missing(ipw_b)
    generate double ow_b = 1 - ps_b if sel_b == 1 & core_outcome_analytic == 1
    generate double mw_b = min(ps_b, 1 - ps_b) / ps_b ///
        if sel_b == 1 & core_outcome_analytic == 1 & ps_b > 0

    local success_ipw = 0
    local success_ow = 0
    local success_mw = 0
    local error_ipw = 0
    local error_ow = 0
    local error_mw = 0
    local did_ipw = .
    local did_ow = .
    local did_mw = .

    foreach method in ipw ow mw {
        local wvar `method'_b
        capture quietly logit stem i.female##i.housing_portfolio ///
            $C_OUTCOME_WEALTH [pw = `wvar'] ///
            if core_outcome_analytic == 1 & !missing(`wvar'), vce(robust)
        local error_`method' = _rc
        if `error_`method'' == 0 {
            capture quietly margins female#housing_portfolio, post noestimcheck
            local error_`method' = _rc
        }
        if `error_`method'' == 0 {
            capture quietly lincom ///
                (_b[1.female#0.housing_portfolio] - _b[0bn.female#0.housing_portfolio]) - ///
                (_b[1.female#1.housing_portfolio] - _b[0bn.female#1.housing_portfolio])
            local error_`method' = _rc
        }
        if `error_`method'' == 0 {
            local success_`method' = 1
            local did_`method' = r(estimate)
        }
    }

    post `draws' (`b') (`success_ipw') (`success_ow') (`success_mw') ///
        (`error_ipw') (`error_ow') (`error_mw') (`did_ipw') (`did_ow') (`did_mw')
    if mod(`b', 100) == 0 display "Completed bootstrap `b' of `reps'"
}
postclose `draws'

use `draws_data', clear
foreach method in ipw ow mw {
    generate did_`method'_pp = 100 * did_`method'
}
save "$MODELS/selection_bootstrap_draws_01_10_2026.dta", replace
export delimited using "$TABLES/selection_bootstrap_draws_01_10_2026.csv", replace

tempname summary
tempfile summary_data
postfile `summary' str24 method long requested successful failed ///
    double bootstrap_mean bootstrap_se median percentile_lb percentile_ub sign_p ///
    using `summary_data', replace

foreach method in ipw ow mw {
    quietly count
    local requested = r(N)
    quietly count if success_`method' == 1 & !missing(did_`method')
    local successful = r(N)
    quietly summarize did_`method' if success_`method' == 1, detail
    local mean = r(mean)
    local se = r(sd)
    local median = r(p50)
    quietly _pctile did_`method' if success_`method' == 1, p(2.5 97.5)
    local lb = r(r1)
    local ub = r(r2)
    quietly count if success_`method' == 1 & did_`method' <= 0
    local nonpositive = r(N)
    quietly count if success_`method' == 1 & did_`method' >= 0
    local nonnegative = r(N)
    local p_sign = 2 * min(`nonpositive' / `successful', `nonnegative' / `successful')
    if `p_sign' > 1 local p_sign = 1
    local label "Full risk-set IPW"
    if "`method'" == "ow" local label "Overlap weights"
    if "`method'" == "mw" local label "Matching weights"
    post `summary' ("`label'") (`requested') (`successful') ///
        (`requested' - `successful') (`mean') (`se') (`median') (`lb') (`ub') (`p_sign')
}
postclose `summary'

use `summary_data', clear
generate bootstrap_mean_pp = 100 * bootstrap_mean
generate bootstrap_se_pp = 100 * bootstrap_se
generate percentile_lb_pp = 100 * percentile_lb
generate percentile_ub_pp = 100 * percentile_ub
save "$MODELS/selection_bootstrap_summary_01_10_2026.dta", replace
export delimited using "$TABLES/selection_bootstrap_summary_01_10_2026.csv", replace

exit
}

display as error "Unknown module."
exit 198
