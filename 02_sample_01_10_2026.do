/* Sample. */
version 18
args module
if "`module'" == "" {
    do "$CODE/02_sample_01_10_2026.do" entrants
    do "$CODE/02_sample_01_10_2026.do" financial_products
    do "$CODE/02_sample_01_10_2026.do" risk_set
    do "$CODE/02_sample_01_10_2026.do" selection_sample
    exit
}

if "`module'" == "entrants" {
/* Entrants. */
version 18
use "$HSSC_DATA/clean/cfps_entrant_main_2012_2022_analysis_ready_$HSSC_DATE.dta", clear
isid pid wave
generate byte science_only = disc == 7 if !missing(disc)
generate byte engineering_only = disc == 8 if !missing(disc)
assert stem == inlist(disc,7,8) if !missing(stem,disc)
generate double financial_product_rebuilt = financial_product_same
generate byte finance_liquid = (savings_same > 0 | financial_product_same > 0) ///
    if !missing(savings_same,financial_product_same)
generate byte housing_portfolio = .
replace housing_portfolio = 0 if has_house == 1 & finance_liquid == 0 & has_business == 0
replace housing_portfolio = 1 if has_house == 1 & (finance_liquid == 1 | has_business == 1)
label define ref_female 0 "Men" 1 "Women", replace
label define ref_portfolio 0 "Housing-concentrated" 1 "Housing-plus", replace
label values female ref_female
label values housing_portfolio ref_portfolio
generate byte hssc_core = analytic_main == 1 & inlist(wave,2014,2018,2020,2022) ///
    & !missing(housing_portfolio,female,stem)
label variable stem "Science or engineering entry (07 or 08)"
label variable science_only "Science entry; descriptive field breakdown"
label variable engineering_only "Engineering entry; descriptive field breakdown"
compress
save "$HSSC_DATA/entrants_all_$HSSC_DATE.dta", replace
keep if hssc_core
assert _N == 872
quietly count if total_asset_same < 0
assert r(N) == 23
assert abs(ihs_total_asset_same-asinh(total_asset_same)) < 1e-5 if !missing(total_asset_same)
save "$HSSC_DATA/core_entrants_$HSSC_DATE.dta", replace
preserve
    collapse (count) N=stem (sum) se_events=stem science_events=science_only ///
        engineering_events=engineering_only, by(female housing_portfolio)
    generate se_percent = 100*se_events/N
    export delimited using "$TABLES/current_exact_cells_$HSSC_DATE.csv", replace
restore
preserve
    contract wave level disc, freq(N)
    export delimited using "$TABLES/field_codes_by_wave_and_level_$HSSC_DATE.csv", replace
restore

exit
}

if "`module'" == "financial_products" {
/* Financial products. */
tempfile products2012
use "$famecon12", clear
keep fid12 govbond stock funds otherfinance
drop if missing(fid12)
foreach variable in govbond stock funds otherfinance {
    replace `variable' = . if `variable' < 0
}
egen double financial_product_rebuilt_2012 = ///
    rowtotal(govbond stock funds otherfinance), missing
keep fid12 financial_product_rebuilt_2012
isid fid12
save `products2012', replace

use "$DATA/clean/cfps_entrant_main_2012_2022_analysis_ready_01_10_2026.dta", clear
keep if analytic_main == 1
merge m:1 fid12 using `products2012', keep(master match) nogen
generate double financial_product_rebuilt = financial_product_same
replace financial_product_rebuilt = financial_product_rebuilt_2012 if wave == 2012
drop financial_product_rebuilt_2012
generate byte finance_liquid = ///
    (savings_same > 0 | financial_product_rebuilt > 0) ///
    if !missing(savings_same, financial_product_rebuilt)
compress
save "$DATA/cfps_entrants_finance_reconstructed.dta", replace

exit
}

if "`module'" == "risk_set" {
/* Risk set. */
use "$DATA/clean/cfps2012_selection_risk_01_10_2026.dta", clear
append using "$DATA/clean/cfps2014_selection_risk_01_10_2026.dta"
append using "$DATA/clean/cfps2018_selection_risk_01_10_2026.dta"
append using "$DATA/clean/cfps2020_selection_risk_01_10_2026.dta"
append using "$DATA/clean/cfps2022_selection_risk_01_10_2026.dta"

capture drop postsecondary_entry
gen byte postsecondary_entry = strict_first_entrant == 1
label var postsecondary_entry "First-time ordinary full-time postsecondary entrant"

capture drop valid_field
gen byte valid_field = !missing(field5)

capture drop has_asset_same
gen byte has_asset_same = !missing(total_asset_same)

capture drop age_entry
gen double age_entry = .
foreach y in 2012 2014 2018 2020 2022 {
    local yy = substr("`y'", 3, 2)
    capture confirm variable age`yy'
    if !_rc replace age_entry = age`yy' if wave == `y' & missing(age_entry)
}

capture drop parent_college_any
gen byte parent_college_any = .
foreach y in 2012 2014 2018 2020 2022 {
    local yy = substr("`y'", 3, 2)
    capture confirm variable parent_college_any`yy'
    if !_rc replace parent_college_any = parent_college_any`yy' ///
        if wave == `y' & missing(parent_college_any)
}

capture drop hukou_agri
gen byte hukou_agri = .
foreach y in 2012 2014 2018 2020 2022 {
    local yy = substr("`y'", 3, 2)
    capture confirm variable hukou_agri`yy'
    if !_rc replace hukou_agri = hukou_agri`yy' ///
        if wave == `y' & missing(hukou_agri)
}

capture drop urban_ctrl
gen byte urban_ctrl = .
foreach y in 2012 2014 2018 2020 2022 {
    local yy = substr("`y'", 3, 2)
    capture confirm variable urban`yy'_ctrl
    if !_rc replace urban_ctrl = urban`yy'_ctrl ///
        if wave == `y' & missing(urban_ctrl)
}

capture drop age_entry_miss age_entry_imp
gen byte age_entry_miss = missing(age_entry)
quietly summarize age_entry if !missing(age_entry), meanonly
gen double age_entry_imp = age_entry
replace age_entry_imp = r(mean) if missing(age_entry_imp)

capture drop income_miss ihs_hh_income_pc_imp
gen byte income_miss = missing(ihs_hh_income_pc_same)
gen double ihs_hh_income_pc_imp = ihs_hh_income_pc_same
quietly summarize ihs_hh_income_pc_same if !missing(ihs_hh_income_pc_same), meanonly
replace ihs_hh_income_pc_imp = r(mean) if missing(ihs_hh_income_pc_imp)

capture drop hukou_agri_cat urban_cat parent_college_cat
gen byte hukou_agri_cat = hukou_agri
replace hukou_agri_cat = 9 if missing(hukou_agri_cat)
gen byte urban_cat = urban_ctrl
replace urban_cat = 9 if missing(urban_cat)
gen byte parent_college_cat = parent_college_any
replace parent_college_cat = 9 if missing(parent_college_cat)

label define yesnomiss_pub 0 "No" 1 "Yes" 9 "Missing", replace
label values hukou_agri_cat yesnomiss_pub
label values urban_cat yesnomiss_pub
label values parent_college_cat yesnomiss_pub

capture drop analytic_entry_ipw
gen byte analytic_entry_ipw = postsecondary_entry == 1 ///
    & valid_field == 1 ///
    & !missing(stem) ///
    & !missing(asset_portfolio4)
label var analytic_entry_ipw "Entrants with valid STEM and portfolio in reconstructed risk set"

save "$DATA/cfps_selection_riskset.dta", replace

exit
}

if "`module'" == "selection_sample" {
/* Selection sample. */
global ORIGINAL_ENTRANT_SOURCE "$DATA/clean/cfps_entrant_main_2012_2022_analysis_ready_01_10_2026.dta"
global ENTRANT_SOURCE "$DATA/cfps_entrants_finance_reconstructed.dta"
global RISKSET_SOURCE "$DATA/cfps_selection_riskset.dta"
version 18
clear
set more off
set linesize 180

tempname audit counts
tempfile audit_data counts_data entrant_match
postfile `audit' str64 metric double value using `audit_data', replace
postfile `counts' str12 dataset int wave byte entry female portfolio long N ///
    using `counts_data', replace

use "$ORIGINAL_ENTRANT_SOURCE", clear
quietly count
post `audit' ("Initial identified first entrants") (r(N))
quietly count if valid_field == 0
post `audit' ("Excluded: invalid or missing field outcome") (r(N))
quietly count if valid_field == 1 & has_asset_same == 0
post `audit' ("Excluded: incomplete same-wave asset record") (r(N))
quietly count if analytic_main == 1
post `audit' ("Analysis-ready first entrants") (r(N))

use "$ENTRANT_SOURCE", clear
quietly count
assert r(N) == 1205
quietly count if analytic_main == 1 & inlist(wave, 2014, 2018, 2020, 2022)
post `audit' ("Entrants in comparable 2014-2022 waves") (r(N))
quietly count if analytic_main == 1 & wave == 2012
post `audit' ("Excluded: 2012 noncomparable liquid-asset wave") (r(N))
keep if analytic_main == 1 & inlist(wave, 2014, 2018, 2020, 2022)

generate byte housing_portfolio = .
replace housing_portfolio = 0 if has_house == 1 & ///
    finance_liquid == 0 & has_business == 0
replace housing_portfolio = 1 if has_house == 1 & ///
    (finance_liquid == 1 | has_business == 1)
label values female ref_female
label values housing_portfolio ref_portfolio

quietly count if has_house == 0
post `audit' ("Excluded: no housing assets") (r(N))
keep if !missing(housing_portfolio, female, stem)
isid pid wave

quietly count
post `audit' ("Primary analytic housing-owner sample") (r(N))
quietly count if housing_portfolio == 0
post `audit' ("Housing-concentrated entrants") (r(N))
quietly count if housing_portfolio == 1
post `audit' ("Housing-plus entrants") (r(N))

foreach w in 2014 2018 2020 2022 {
    forvalues g = 0/1 {
        forvalues p = 0/1 {
            quietly count if wave == `w' & female == `g' & housing_portfolio == `p'
            post `counts' ("entrants") (`w') (1) (`g') (`p') (r(N))
        }
    }
}

compress
save "$DATA/entrant_selection_interface_01_10_2026.dta", replace
preserve
    keep pid wave housing_portfolio stem
    rename housing_portfolio entrant_portfolio
    rename stem entrant_stem
    save `entrant_match', replace
restore

use "$RISKSET_SOURCE", clear
keep if inlist(wave, 2014, 2018, 2020, 2022)
keep if inrange(age_entry_imp, 16, 24)

quietly count if missing(financial_product_same)
post `audit' ("Risk-set missing financial products, 2014+") (r(N))

generate byte finance_liquid = ///
    (savings_same > 0 | financial_product_same > 0) ///
    if !missing(savings_same, financial_product_same)

generate byte housing_portfolio = .
replace housing_portfolio = 0 if has_house == 1 & ///
    finance_liquid == 0 & has_business == 0
replace housing_portfolio = 1 if has_house == 1 & ///
    (finance_liquid == 1 | has_business == 1)
label values female ref_female
label values housing_portfolio ref_portfolio

keep if !missing(housing_portfolio, female, postsecondary_entry)

generate byte wealth_missing = missing(ihs_total_asset_same)
bysort wave: egen double wave_wealth_median = median(ihs_total_asset_same)
generate double ihs_total_asset_imp = ihs_total_asset_same
replace ihs_total_asset_imp = wave_wealth_median if wealth_missing == 1

generate byte outcome_analytic = postsecondary_entry == 1 & ///
    valid_field == 1 & !missing(stem, level)
generate byte female_plus = female == 1 & housing_portfolio == 1

quietly count
post `audit' ("Housing-owner risk-set person-waves") (r(N))
bysort pid: generate int risk_waves_per_person = _N
egen byte risk_person_tag = tag(pid)
quietly count if risk_person_tag == 1
post `audit' ("Unique persons in housing-owner risk set") (r(N))
quietly summarize risk_waves_per_person if risk_person_tag == 1, meanonly
post `audit' ("Mean person-waves per risk-set person") (r(mean))
post `audit' ("Maximum person-waves per risk-set person") (r(max))
quietly count if postsecondary_entry == 1
post `audit' ("Postsecondary entrants in risk set") (r(N))
quietly count if outcome_analytic == 1
post `audit' ("Entrants with observed STEM outcome") (r(N))

foreach w in 2014 2018 2020 2022 {
    forvalues e = 0/1 {
        forvalues g = 0/1 {
            forvalues p = 0/1 {
                quietly count if wave == `w' & postsecondary_entry == `e' & ///
                    female == `g' & housing_portfolio == `p'
                post `counts' ("riskset") (`w') (`e') (`g') (`p') (r(N))
            }
        }
    }
}

compress
save "$DATA/core_riskset_01_10_2026.dta", replace

preserve
    keep if outcome_analytic == 1
    keep pid wave housing_portfolio stem
    rename housing_portfolio riskset_portfolio
    rename stem riskset_stem
    merge 1:1 pid wave using `entrant_match'

    quietly count if _merge == 3
    post `audit' ("Matched analytic entrants") (r(N))
    quietly count if _merge == 1
    post `audit' ("Risk-set analytic entrants unmatched") (r(N))
    quietly count if _merge == 2
    post `audit' ("Entrant-file records unmatched") (r(N))
    quietly count if _merge == 3 & riskset_portfolio != entrant_portfolio
    post `audit' ("Portfolio disagreements among matches") (r(N))
    quietly count if _merge == 3 & riskset_stem != entrant_stem
    post `audit' ("STEM disagreements among matches") (r(N))
restore

merge 1:1 pid wave using `entrant_match', keep(master match) generate(core_merge)
generate byte core_outcome_analytic = core_merge == 3
quietly count if outcome_analytic == 1 & core_outcome_analytic == 0
post `audit' ("Risk-set entrants lacking primary wealth record") (r(N))
quietly count if core_outcome_analytic == 1
post `audit' ("Core entrants retained in age 16-24 IPW sample") (r(N))
drop entrant_portfolio entrant_stem core_merge
compress
save "$DATA/core_riskset_01_10_2026.dta", replace

postclose `audit'
postclose `counts'

use `audit_data', clear
save "$MODELS/preparation_audit_01_10_2026.dta", replace
export delimited using "$TABLES/preparation_audit_01_10_2026.csv", replace

use `counts_data', clear
sort dataset wave entry female portfolio
save "$MODELS/frozen_sample_counts_01_10_2026.dta", replace
export delimited using "$TABLES/frozen_sample_counts_01_10_2026.csv", replace

exit
}

display as error "Unknown module."
exit 198
