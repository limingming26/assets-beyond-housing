/* Descriptive. */
version 18
args module
if "`module'" == "" {
    do "$CODE/03_descriptive_01_10_2026.do" sample_statistics
    do "$CODE/03_descriptive_01_10_2026.do" table1
    do "$CODE/03_descriptive_01_10_2026.do" asset_composition
    do "$CODE/03_descriptive_01_10_2026.do" household_prevalence
    exit
}

if "`module'" == "sample_statistics" {
/* Sample statistics. */
version 18
clear
set more off
set linesize 180

use "$DATA/core_entrants_01_10_2026.dta", clear

generate byte bachelor = level == 2 if !missing(level)
generate byte agricultural_hukou = hukou_agri_cat == 1 if !missing(hukou_agri_cat)
generate byte urban_residence = urban_cat == 1 if !missing(urban_cat)
generate byte parent_college = parent_college_cat == 1 if !missing(parent_college_cat)
generate byte parent_college_missing = parent_college_cat == 9 if !missing(parent_college_cat)
generate double liquid_amount = savings_same + financial_product_rebuilt
generate double observed_gross_assets = houseasset_gross_same + liquid_amount + ///
    fixed_asset_same + land_asset_same + durables_asset_same
generate double housing_share_observed = houseasset_gross_same / observed_gross_assets ///
    if observed_gross_assets > 0
generate double debt_asset_ratio = debt_total_same / observed_gross_assets ///
    if observed_gross_assets > 0

tempname chars portfolios waveassets missingpost rawcells balancepost validationpost
tempfile chars_data portfolios_data waveassets_data missing_data rawcells_data ///
    balance_data validation_data
postfile `chars' str64 measure str12 statistic double pooled men women women_minus_men ///
    using `chars_data', replace
postfile `portfolios' byte portfolio str28 portfolio_label str88 rule long N ///
    double sample_pct women_pct median_wealth_wan liquid_pct business_pct ///
    using `portfolios_data', replace
postfile `waveassets' int wave long N double concentrated_pct liquid_pct business_pct ///
    median_income_wan median_wealth_wan using `waveassets_data', replace
postfile `missingpost' str52 variable double N_missing pct_missing using `missing_data', replace
postfile `rawcells' byte portfolio female long N double raw_stem_pct ///
    using `rawcells_data', replace
postfile `balancepost' str64 measure str12 statistic double concentrated plus smd ///
    using `balance_data', replace
postfile `validationpost' str64 measure str12 statistic double concentrated plus ///
    using `validation_data', replace

quietly count
local n_all = r(N)
quietly count if female == 0
local n_men = r(N)
quietly count if female == 1
local n_women = r(N)
post `chars' ("Observations") ("N") (`n_all') (`n_men') (`n_women') (`n_women' - `n_men')

foreach item in ///
    "stem|STEM entry (%)|100" ///
    "bachelor|Bachelor's program (%)|100" ///
    "age_entry_imp|Age at entry (years)|1" ///
    "agricultural_hukou|Agricultural hukou (%)|100" ///
    "urban_residence|Urban residence (%)|100" ///
    "parent_college|At least one parent college educated (%)|100" ///
    "parent_college_missing|Parental education missing (%)|100" {
    gettoken v rest : item, parse("|")
    gettoken pipe rest : rest, parse("|")
    gettoken label rest : rest, parse("|")
    gettoken pipe scale : rest, parse("|")
    local scale = real("`scale'")
    quietly summarize `v', meanonly
    local pooled = r(mean) * `scale'
    quietly summarize `v' if female == 0, meanonly
    local men = r(mean) * `scale'
    quietly summarize `v' if female == 1, meanonly
    local women = r(mean) * `scale'
    post `chars' ("`label'") ("Mean") (`pooled') (`men') (`women') (`women' - `men')
}

forvalues p = 0/1 {
    forvalues g = 0/1 {
        quietly count if housing_portfolio == `p' & female == `g'
        local N = r(N)
        quietly summarize stem if housing_portfolio == `p' & female == `g', meanonly
        post `rawcells' (`p') (`g') (`N') (100 * r(mean))
    }
}

foreach item in ///
    "female|Female share (%)|100" ///
    "stem|STEM entry (%)|100" ///
    "bachelor|Bachelor's program (%)|100" ///
    "age_entry_imp|Age at entry (years)|1" ///
    "agricultural_hukou|Agricultural hukou (%)|100" ///
    "urban_residence|Urban residence (%)|100" ///
    "parent_college|At least one parent college educated (%)|100" ///
    "parent_college_missing|Parental education missing (%)|100" {
    gettoken v rest : item, parse("|")
    gettoken pipe rest : rest, parse("|")
    gettoken label rest : rest, parse("|")
    gettoken pipe scale : rest, parse("|")
    local scale = real("`scale'")
    quietly summarize `v' if housing_portfolio == 0
    local m0 = r(mean)
    local v0 = r(Var)
    quietly summarize `v' if housing_portfolio == 1
    local m1 = r(mean)
    local v1 = r(Var)
    local denom = sqrt((`v0' + `v1') / 2)
    local smd = cond(`denom' > 0, (`m0' - `m1') / `denom', .)
    post `balancepost' ("`label'") ("Mean") ///
        (`m0' * `scale') (`m1' * `scale') (`smd')
}

foreach item in ///
    "hh_income_pc_wan|ihs_hh_income_pc_imp|Per-capita household income (RMB 10,000)" ///
    "total_asset_wan|ihs_total_asset_same|Total net wealth (RMB 10,000)" {
    gettoken displayvar rest : item, parse("|")
    gettoken pipe rest : rest, parse("|")
    gettoken smdvar rest : rest, parse("|")
    gettoken pipe label : rest, parse("|")
    quietly summarize `displayvar' if housing_portfolio == 0, detail
    local d0 = r(p50)
    quietly summarize `displayvar' if housing_portfolio == 1, detail
    local d1 = r(p50)
    quietly summarize `smdvar' if housing_portfolio == 0
    local m0 = r(mean)
    local v0 = r(Var)
    quietly summarize `smdvar' if housing_portfolio == 1
    local m1 = r(mean)
    local v1 = r(Var)
    local denom = sqrt((`v0' + `v1') / 2)
    local smd = cond(`denom' > 0, (`m0' - `m1') / `denom', .)
    post `balancepost' ("`label'") ("Median") (`d0') (`d1') (`smd')
}

quietly count if housing_portfolio == 0
local n0 = r(N)
quietly count if housing_portfolio == 1
local n1 = r(N)
post `validationpost' ("Observations") ("N") (`n0') (`n1')

foreach item in ///
    "houseasset_gross_same|Median gross housing assets (RMB 10,000)|10000" ///
    "land_asset_same|Median land assets (RMB 10,000)|10000" ///
    "durables_asset_same|Median durable assets (RMB 10,000)|10000" ///
    "debt_total_same|Median total debt (RMB 10,000)|10000" {
    gettoken v rest : item, parse("|")
    gettoken pipe rest : rest, parse("|")
    gettoken label rest : rest, parse("|")
    gettoken pipe divisor : rest, parse("|")
    local divisor = real("`divisor'")
    quietly summarize `v' if housing_portfolio == 0, detail
    local d0 = r(p50) / `divisor'
    quietly summarize `v' if housing_portfolio == 1, detail
    local d1 = r(p50) / `divisor'
    post `validationpost' ("`label'") ("Median") (`d0') (`d1')
}

foreach item in ///
    "housing_share_observed|Housing share of observed gross assets (%)|100" ///
    "has_land|Land ownership (%)|100" ///
    "has_debt|Any household debt (%)|100" ///
    "debt_asset_ratio|Debt-to-observed-gross-assets ratio (%)|100" {
    gettoken v rest : item, parse("|")
    gettoken pipe rest : rest, parse("|")
    gettoken label rest : rest, parse("|")
    gettoken pipe scale : rest, parse("|")
    local scale = real("`scale'")
    quietly summarize `v' if housing_portfolio == 0, detail
    local d0 = r(p50) * `scale'
    if inlist("`v'", "has_land", "has_debt") local d0 = r(mean) * `scale'
    quietly summarize `v' if housing_portfolio == 1, detail
    local d1 = r(p50) * `scale'
    if inlist("`v'", "has_land", "has_debt") local d1 = r(mean) * `scale'
    local stat "Median"
    if inlist("`v'", "has_land", "has_debt") local stat "Mean"
    post `validationpost' ("`label'") ("`stat'") (`d0') (`d1')
}

foreach item in ///
    "hh_income_pc_wan|Per-capita household income (RMB 10,000)" ///
    "total_asset_wan|Total net wealth (RMB 10,000)" {
    gettoken v rest : item, parse("|")
    gettoken pipe label : rest, parse("|")
    quietly summarize `v', detail
    local pooled = r(p50)
    quietly summarize `v' if female == 0, detail
    local men = r(p50)
    quietly summarize `v' if female == 1, detail
    local women = r(p50)
    post `chars' ("`label'") ("Median") (`pooled') (`men') (`women') (`women' - `men')
}

quietly count
local total = r(N)
forvalues p = 0/1 {
    quietly count if housing_portfolio == `p'
    local N = r(N)
    local pct = 100 * `N' / `total'
    quietly summarize female if housing_portfolio == `p', meanonly
    local wpct = 100 * r(mean)
    quietly summarize total_asset_wan if housing_portfolio == `p', detail
    local wealth = r(p50)
    quietly summarize finance_liquid if housing_portfolio == `p', meanonly
    local liquid = 100 * r(mean)
    quietly summarize has_business if housing_portfolio == `p', meanonly
    local business = 100 * r(mean)
    local label "Housing-concentrated"
    local rule "Housing; no positive liquid assets; no productive/business assets"
    if `p' == 1 {
        local label "Housing-plus"
        local rule "Housing plus positive liquid and/or productive/business assets"
    }
    post `portfolios' (`p') ("`label'") ("`rule'") (`N') (`pct') (`wpct') ///
        (`wealth') (`liquid') (`business')
}

foreach w in 2014 2018 2020 2022 {
    quietly count if wave == `w'
    local N = r(N)
    quietly summarize housing_portfolio if wave == `w', meanonly
    local concentrated = 100 * (1 - r(mean))
    quietly summarize finance_liquid if wave == `w', meanonly
    local liquid = 100 * r(mean)
    quietly summarize has_business if wave == `w', meanonly
    local business = 100 * r(mean)
    quietly summarize hh_income_pc_wan if wave == `w', detail
    local income = r(p50)
    quietly summarize total_asset_wan if wave == `w', detail
    local wealth = r(p50)
    post `waveassets' (`w') (`N') (`concentrated') (`liquid') (`business') ///
        (`income') (`wealth')
}

foreach item in ///
    "age_entry_miss|Age at entry" ///
    "income_miss|Per-capita household income" ///
    "parent_college_cat|Parental college education" ///
    "ihs_total_asset_same|Total net wealth" {
    gettoken v rest : item, parse("|")
    gettoken pipe label : rest, parse("|")
    if "`v'" == "age_entry_miss" quietly count if age_entry_miss == 1
    else if "`v'" == "income_miss" quietly count if income_miss == 1
    else if "`v'" == "parent_college_cat" quietly count if parent_college_cat == 9
    else quietly count if missing(`v')
    local miss = r(N)
    post `missingpost' ("`label'") (`miss') (100 * `miss' / `n_all')
}

quietly count if missing(houseasset_gross_same, savings_same, ///
    financial_product_rebuilt, fixed_asset_same)
local miss = r(N)
post `missingpost' ("Portfolio components") (`miss') (100 * `miss' / `n_all')

postclose `chars'
postclose `portfolios'
postclose `waveassets'
postclose `missingpost'
postclose `rawcells'
postclose `balancepost'
postclose `validationpost'

use `chars_data', clear
save "$MODELS/sample_characteristics_01_10_2026.dta", replace
export delimited using "$TABLES/sample_characteristics_01_10_2026.csv", replace

use `portfolios_data', clear
save "$MODELS/portfolio_composition_01_10_2026.dta", replace
export delimited using "$TABLES/portfolio_composition_01_10_2026.csv", replace

use `waveassets_data', clear
save "$MODELS/wave_asset_summaries_01_10_2026.dta", replace
export delimited using "$TABLES/wave_asset_summaries_01_10_2026.csv", replace

use `missing_data', clear
save "$MODELS/core_missingness_01_10_2026.dta", replace
export delimited using "$TABLES/core_missingness_01_10_2026.csv", replace

use `rawcells_data', clear
sort portfolio female
save "$MODELS/core_raw_cells_01_10_2026.dta", replace
export delimited using "$TABLES/core_raw_cells_01_10_2026.csv", replace

use `balance_data', clear
save "$MODELS/portfolio_covariate_balance_01_10_2026.dta", replace
export delimited using "$TABLES/portfolio_covariate_balance_01_10_2026.csv", replace

use `validation_data', clear
save "$MODELS/portfolio_validation_01_10_2026.dta", replace
export delimited using "$TABLES/portfolio_validation_01_10_2026.csv", replace

use "$DATA/core_entrants_01_10_2026.dta", clear
contract wave female housing_portfolio, freq(N)
sort wave female housing_portfolio
save "$MODELS/wave_gender_portfolio_cells_01_10_2026.dta", replace
export delimited using "$TABLES/wave_gender_portfolio_cells_01_10_2026.csv", replace

use "$DATA/core_entrants_01_10_2026.dta", clear
contract wave disc field5, freq(N)
sort wave disc
save "$MODELS/field_code_crosswalk_counts_01_10_2026.dta", replace
export delimited using "$TABLES/field_code_crosswalk_counts_01_10_2026.csv", replace

exit
}

if "`module'" == "table1" {
/* Table1. */
use "$DATA/core_entrants_01_10_2026.dta", clear
assert _N==872
gen byte bachelor=level==2 if !missing(level)
gen byte agricultural_hukou=hukou_agri_cat==1 if !missing(hukou_agri_cat)
gen byte urban_residence=urban_cat==1 if !missing(urban_cat)
gen byte parent_college=parent_college_cat==1 if !missing(parent_college_cat)
gen byte parent_college_missing=parent_college_cat==9 if !missing(parent_college_cat)
gen byte hukou_missing=hukou_agri_cat==9
gen byte residence_missing=urban_cat==9
tempname res
tempfile vals
postfile `res' str1 panel str60 measure str10 statistic double full_value full_sd women_value women_sd men_value men_sd p_value long full_n women_n men_n using `vals', replace
foreach panel in A B C {
 local cond "1"
 if "`panel'"=="B" local cond "housing_portfolio==0"
 if "`panel'"=="C" local cond "housing_portfolio==1"
 foreach v in stem bachelor age_entry_imp agricultural_hukou hukou_missing urban_residence residence_missing parent_college parent_college_missing hh_income_pc_wan total_asset_wan finance_liquid has_business {
  local statistic "binary"
  local scale=100
  if inlist("`v'","age_entry_imp","hh_income_pc_wan","total_asset_wan") {
   local statistic "continuous"
   local scale=1
  }
  quietly summarize `v' if `cond'
  local fm=r(mean)*`scale'
  local fs=r(sd)*`scale'
  local fn=r(N)
  quietly summarize `v' if `cond' & female==1
  local wm=r(mean)*`scale'
  local ws=r(sd)*`scale'
  local wn=r(N)
  quietly summarize `v' if `cond' & female==0
  local mm=r(mean)*`scale'
  local ms=r(sd)*`scale'
  local mn=r(N)
  local pv=.
  if `fs'>0 & !missing(`fs') {
   quietly ttest `v' if `cond', by(female) unequal
   local pv=r(p)
  }
  post `res' ("`panel'") ("`v'") ("`statistic'") (`fm') (`fs') (`wm') (`ws') (`mm') (`ms') (`pv') (`fn') (`wn') (`mn')
 }
}
postclose `res'
use `vals',clear
export delimited using "$TABLES/Table1_Recomputed_01_10_2026.csv",replace

exit
}

if "`module'" == "asset_composition" {
/* Asset composition. */
version 18
use "$HSSC_DATA/core_entrants_$HSSC_DATE.dta", clear
assert !missing(fixed_asset_same,agrimachine_asset_same,company_asset_same)
assert fixed_asset_same>=0 & agrimachine_asset_same>=0 & company_asset_same>=0

generate double company_component_reconciled = fixed_asset_same-agrimachine_asset_same
label variable company_component_reconciled "Business component reconciled to published productive total, RMB"
generate double component_factor = cond(wave==2014,10000,1)
assert abs(company_component_reconciled-component_factor*company_asset_same)<1
assert (company_component_reconciled>0)==(company_asset_same>0)
generate byte component_amount_gap = abs(fixed_asset_same-agrimachine_asset_same-company_asset_same)>1
preserve
    collapse (count) entrants=pid (sum) differing_amounts=component_amount_gap ///
        (first) reconciliation_factor=component_factor, by(wave)
    generate str100 status="Numerical reconciliation only; original release label requires unit review"
    export delimited using "$HSSC_RESULTS/validation/component_amount_reconciliation_$HSSC_DATE.csv", replace
restore

generate byte machinery_only = agrimachine_asset_same>0 & company_asset_same==0
generate byte asset_group5=.
replace asset_group5=1 if housing_portfolio==0
replace asset_group5=2 if finance_liquid==1 & has_business==0
replace asset_group5=3 if finance_liquid==0 & has_business==1 & machinery_only
replace asset_group5=4 if finance_liquid==0 & has_business==1 & !machinery_only
replace asset_group5=5 if finance_liquid==1 & has_business==1
assert !missing(asset_group5)
label define ag5 1 "Housing-concentrated" 2 "Liquid only" ///
    3 "No liquid; machinery only within productive assets" ///
    4 "No liquid; productive assets include business" 5 "Liquid and productive", replace
label values asset_group5 ag5
save "$HSSC_DATA/asset_composition_$HSSC_DATE.dta", replace

tempname summary counts moved
tempfile summarydata countdata moveddata
postfile `summary' byte asset_group str80 asset_label long N women women_se income_N ///
    double income_median wealth_median debt_pct long hukou_N hukou_agri_N ///
    using `summarydata', replace
forvalues g=1/5 {
    local label : label ag5 `g'
    quietly count if asset_group5==`g'
    local n=r(N)
    quietly count if asset_group5==`g' & female==1
    local nw=r(N)
    quietly count if asset_group5==`g' & female==1 & stem==1
    local ne=r(N)
    quietly summarize hh_income_pc_same if asset_group5==`g', detail
    local ni=r(N)
    local mi=r(p50)
    quietly summarize total_asset_same if asset_group5==`g', detail
    local mw=r(p50)
    quietly summarize has_debt if asset_group5==`g', meanonly
    local debt=100*r(mean)
    quietly count if asset_group5==`g' & !missing(hukou_agri)
    local nh=r(N)
    quietly count if asset_group5==`g' & hukou_agri==1
    post `summary' (`g') ("`label'") (`n') (`nw') (`ne') (`ni') ///
        (`mi') (`mw') (`debt') (`nh') (r(N))
}
postclose `summary'
preserve
    use `summarydata', clear
    generate women_se_pct=100*women_se/women
    generate hukou_agri_pct=100*hukou_agri_N/hukou_N
    generate str100 money_basis="Nominal RMB, pooled waves; income excludes missing observations"
    export delimited using "$TABLES/asset_composition_A7_$HSSC_DATE.csv", replace
restore

postfile `counts' str70 group long N women women_se using `countdata', replace
forvalues k=1/4 {
    local label "All productive-asset holders"
    local condition "has_business==1"
    if `k'==2 {
        local label "Machinery only within productive assets"
        local condition "has_business==1 & machinery_only"
    }
    if `k'==3 {
        local label "Business only within productive assets"
        local condition "has_business==1 & agrimachine_asset_same==0 & company_asset_same>0"
    }
    if `k'==4 {
        local label "Machinery and business"
        local condition "has_business==1 & agrimachine_asset_same>0 & company_asset_same>0"
    }
    quietly count if `condition'
    local n=r(N)
    quietly count if `condition' & female==1
    local nw=r(N)
    quietly count if `condition' & female==1 & stem==1
    post `counts' ("`label'") (`n') (`nw') (r(N))
}
postclose `counts'
preserve
    use `countdata', clear
    export delimited using "$TABLES/productive_components_A7_$HSSC_DATE.csv", replace
restore

postfile `moved' int threshold byte female long moved_N moved_se machinery_only_N ///
    long concentrated_N concentrated_se plus_N plus_se using `moveddata', replace
foreach cutoff in 0 1000 5000 {
    generate byte portfolio_cut = (finance_liquid==1 | fixed_asset_same>`cutoff')
    generate byte reclassified = housing_portfolio==1 & portfolio_cut==0
    forvalues g=0/1 {
        quietly count if female==`g' & reclassified
        local n=r(N)
        quietly count if female==`g' & reclassified & stem==1
        local ne=r(N)
        quietly count if female==`g' & reclassified & machinery_only
        local nm=r(N)
        quietly count if female==`g' & portfolio_cut==0
        local nc=r(N)
        quietly count if female==`g' & portfolio_cut==0 & stem==1
        local nce=r(N)
        quietly count if female==`g' & portfolio_cut==1
        local np=r(N)
        quietly count if female==`g' & portfolio_cut==1 & stem==1
        post `moved' (`cutoff') (`g') (`n') (`ne') (`nm') (`nc') (`nce') (`np') (r(N))
    }
    drop portfolio_cut reclassified
}
postclose `moved'
use `moveddata', clear
export delimited using "$TABLES/productive_threshold_reclassification_A7_$HSSC_DATE.csv", replace

exit
}

if "`module'" == "household_prevalence" {
/* Household prevalence. */
tempname p
tempfile prevalence
postfile `p' int wave long households concentrated_N plus_N double concentrated_pct plus_pct using `prevalence', replace
foreach wave in 2014 2018 2020 2022 {
    local release "201906"
    local weight "fswt_natcs14"
    if `wave'==2018 {
        local release "202512"
        local weight "fswt_natcs18n"
    }
    if `wave'==2020 {
        local release "202306"
        local weight "fswtps_natcs20n"
    }
    if `wave'==2022 {
        local release "202410"
        local weight "fswt_natcs22n"
    }
    use "$RAW/`wave'/cfps`wave'famecon_`release'.dta", clear
    local yy=substr("`wave'",3,2)
    drop if missing(fid`yy')
    isid fid`yy'
    gen byte liquid=(savings>0 | financial_product>0) if !missing(savings,financial_product)
    gen byte productive=fixed_asset>0 if !missing(fixed_asset)
    gen byte portfolio=.
    replace portfolio=0 if houseasset_gross>0 & !missing(houseasset_gross) & liquid==0 & productive==0
    replace portfolio=1 if houseasset_gross>0 & !missing(houseasset_gross) & (liquid==1 | productive==1)
    keep if !missing(portfolio,`weight') & `weight'>0
    quietly count
    local n=r(N)
    quietly count if portfolio==0
    local n0=r(N)
    quietly count if portfolio==1
    local n1=r(N)
    quietly summarize portfolio [aw=`weight']
    post `p' (`wave') (`n') (`n0') (`n1') (100*(1-r(mean))) (100*r(mean))
}
postclose `p'
use `prevalence', clear
export delimited using "$TABLES/household_asset_prevalence_01_10_2026.csv", replace

exit
}

display as error "Unknown module."
exit 198
