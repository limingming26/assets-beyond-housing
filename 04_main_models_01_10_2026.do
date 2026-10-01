/* Main models. */
version 18
args module
if "`module'" == "" {
    do "$CODE/04_main_models_01_10_2026.do" main_estimators
    do "$CODE/04_main_models_01_10_2026.do" control_coefficients
    do "$CODE/04_main_models_01_10_2026.do" resource_sequence
    do "$CODE/04_main_models_01_10_2026.do" resource_interactions
    exit
}

if "`module'" == "main_estimators" {
/* Main estimators. */
version 18
clear
set more off
set linesize 180

if "$ROOT" == "" {
    display as error "Run 00_master_01_10_2026.do from the package folder."
    exit 198
}

use "$DATA/core_entrants_01_10_2026.dta", clear

tempname results cells clusters
tempfile results_data cells_data clusters_data
postfile `results' str28 specification str52 contrast ///
    double estimate se p ci_lb ci_ub long model_N using `results_data', replace
postfile `cells' str28 specification byte female portfolio ///
    double probability se ci_lb ci_ub long model_N using `cells_data', replace
postfile `clusters' str32 specification str24 cluster_unit double clusters ///
    using `clusters_data', replace
global CORE_RESULTS "`results'"
global CORE_CELLS "`cells'"

capture program drop post_core_results
program define post_core_results
    syntax, SPEC(string) MODELN(integer)

    quietly margins female#housing_portfolio, post noestimcheck

    foreach g in 0 1 {
        foreach p in 0 1 {
            local gterm "0bn"
            if `g' == 1 local gterm "1"
            quietly lincom _b[`gterm'.female#`p'.housing_portfolio]
            post $CORE_CELLS ("`spec'") (`g') (`p') ///
                (r(estimate)) (r(se)) (r(lb)) (r(ub)) (`modeln')
        }
    }

    quietly lincom _b[1.female#0.housing_portfolio] - ///
        _b[0bn.female#0.housing_portfolio]
    post $CORE_RESULTS ("`spec'") ("Women - men, housing-concentrated") ///
        (r(estimate)) (r(se)) (r(p)) (r(lb)) (r(ub)) (`modeln')

    quietly lincom _b[1.female#1.housing_portfolio] - ///
        _b[0bn.female#1.housing_portfolio]
    post $CORE_RESULTS ("`spec'") ("Women - men, housing-plus") ///
        (r(estimate)) (r(se)) (r(p)) (r(lb)) (r(ub)) (`modeln')

    quietly lincom _b[0bn.female#0.housing_portfolio] - ///
        _b[0bn.female#1.housing_portfolio]
    post $CORE_RESULTS ("`spec'") ("Men, concentrated - plus") ///
        (r(estimate)) (r(se)) (r(p)) (r(lb)) (r(ub)) (`modeln')

    quietly lincom _b[1.female#0.housing_portfolio] - ///
        _b[1.female#1.housing_portfolio]
    post $CORE_RESULTS ("`spec'") ("Women, concentrated - plus") ///
        (r(estimate)) (r(se)) (r(p)) (r(lb)) (r(ub)) (`modeln')

    quietly lincom ///
        (_b[1.female#0.housing_portfolio] - ///
         _b[0bn.female#0.housing_portfolio]) - ///
        (_b[1.female#1.housing_portfolio] - ///
         _b[0bn.female#1.housing_portfolio])
    post $CORE_RESULTS ("`spec'") ("Gender-gap contrast: concentrated - plus") ///
        (r(estimate)) (r(se)) (r(p)) (r(lb)) (r(ub)) (`modeln')
end

quietly logit stem i.female##i.housing_portfolio i.wave, vce(robust)
local model_N = e(N)
post_core_results, spec("M0_wave_only") modeln(`model_N')

quietly logit stem i.female##i.housing_portfolio $C_MAIN, vce(robust)
local model_N = e(N)
post_core_results, spec("M1_main_controls") modeln(`model_N')

quietly logit stem i.female##i.housing_portfolio $C_OUTCOME_WEALTH, vce(robust)
local model_N = e(N)
post_core_results, spec("M2_plus_wealth_preferred") modeln(`model_N')

quietly logit stem i.female##i.housing_portfolio $C_OUTCOME_WEALTH, ///
    vce(cluster provcd_h)
local model_N = e(N)
post `clusters' ("M3_wealth_province_cluster") ("Province") (e(N_clust))
local province_df = e(N_clust) - 1
post_core_results, spec("M3_wealth_province_cluster") modeln(`model_N')

quietly regress stem i.female##i.housing_portfolio $C_OUTCOME_WEALTH, ///
    vce(robust)
local model_N = e(N)
post_core_results, spec("M4_wealth_linear_probability") modeln(`model_N')

quietly logit stem i.female##i.housing_portfolio $C_OUTCOME_WEALTH, ///
    vce(cluster fid_current)
local model_N = e(N)
post `clusters' ("M5_wealth_household_cluster") ("Current household") (e(N_clust))
post_core_results, spec("M5_wealth_household_cluster") modeln(`model_N')

tempvar focal_interaction firth_constant
generate double `focal_interaction' = female * housing_portfolio

quietly _rmcoll $C_OUTCOME_WEALTH, expand
local firth_expanded `r(varlist)'
quietly fvrevar `firth_expanded'
local firth_generated `r(varlist)'
quietly _rmcoll `firth_generated'
local firth_reduced `r(varlist)'
local firth_controls
foreach firth_var of local firth_reduced {
    if substr("`firth_var'", 1, 2) == "o." continue
    local firth_controls `firth_controls' `firth_var'
}

generate double `firth_constant' = 1
mkmat female housing_portfolio `focal_interaction' ///
    `firth_controls' `firth_constant', matrix(REPL_FIRTH_X)
mkmat stem, matrix(REPL_FIRTH_Y)

capture mata: mata drop repl_firth_pll()
capture mata: mata drop repl_firth_compute()
mata:
real scalar repl_firth_pll(
    real colvector y,
    real matrix X,
    real colvector b)
{
    real colvector eta, pr, wt
    real matrix info
    real scalar determinant

    eta = X * b
    pr = invlogit(eta)
    wt = pr :* (1 :- pr)
    info = quadcross(X, wt, X)
    determinant = det(info)
    if (determinant <= 0) return(-1e300)

    return(
        sum(y :* eta :- ln(1 :+ exp(eta))) +
        0.5 * ln(determinant)
    )
}

void repl_firth_compute(
    string scalar y_name,
    string scalar x_name,
    string scalar result_name,
    string scalar cell_name)
{
    real colvector y, b, pr, wt, leverage, score, step, b_new
    real matrix X, info, inv_info, X_cf, gradients, cell_results
    real matrix contrast_weights, contrast_gradients, contrast_results
    real scalar old_pll, new_pll, scale, max_step, iteration
    real scalar gender, portfolio, index, estimate, se

    y = st_matrix(y_name)
    X = st_matrix(x_name)
    b = J(cols(X), 1, 0)
    old_pll = repl_firth_pll(y, X, b)

    for (iteration = 1; iteration <= 300; iteration++) {
        pr = invlogit(X * b)
        wt = pr :* (1 :- pr)
        info = quadcross(X, wt, X)
        inv_info = invsym(info)
        leverage = wt :* rowsum((X * inv_info) :* X)
        score = quadcross(X, y :- pr :+ leverage :* (0.5 :- pr))
        step = inv_info * score
        max_step = max(abs(step))
        if (max_step > 3) step = step * (3 / max_step)

        scale = 1
        while (scale > 1e-8) {
            b_new = b + scale * step
            new_pll = repl_firth_pll(y, X, b_new)
            if (new_pll >= old_pll) break
            scale = scale / 2
        }

        if (max(abs(b_new - b)) < 1e-9) {
            b = b_new
            old_pll = new_pll
            break
        }
        b = b_new
        old_pll = new_pll
    }

    if (iteration > 300) _error(430)

    pr = invlogit(X * b)
    wt = pr :* (1 :- pr)
    inv_info = invsym(quadcross(X, wt, X))

    cell_results = J(4, 4, .)
    gradients = J(4, cols(X), .)
    index = 0
    for (gender = 0; gender <= 1; gender++) {
        for (portfolio = 0; portfolio <= 1; portfolio++) {
            index = index + 1
            X_cf = X
            X_cf[, 1] = J(rows(X), 1, gender)
            X_cf[, 2] = J(rows(X), 1, portfolio)
            X_cf[, 3] = J(rows(X), 1, gender * portfolio)
            pr = invlogit(X_cf * b)
            gradients[index, ] =
                colsum(X_cf :* (pr :* (1 :- pr))) / rows(X_cf)
            estimate = mean(pr)
            se = sqrt(gradients[index, ] * inv_info * gradients[index, ]')
            cell_results[index, ] = (
                estimate,
                se,
                estimate - invnormal(0.975) * se,
                estimate + invnormal(0.975) * se
            )
        }
    }

    contrast_weights = (
        -1,  0,  1,  0 \  
         0, -1,  0,  1 \  
         1, -1,  0,  0 \  
         0,  0,  1, -1 \  
        -1,  1,  1, -1    
    )
    contrast_gradients = contrast_weights * gradients
    contrast_results = J(5, 5, .)

    for (index = 1; index <= 5; index++) {
        estimate = contrast_weights[index, ] * cell_results[, 1]
        se = sqrt(
            contrast_gradients[index, ] *
            inv_info *
            contrast_gradients[index, ]'
        )
        contrast_results[index, ] = (
            estimate,
            se,
            2 * normal(-abs(estimate / se)),
            estimate - invnormal(0.975) * se,
            estimate + invnormal(0.975) * se
        )
    }

    st_matrix(result_name, contrast_results)
    st_matrix(cell_name, cell_results)
    st_numscalar("REPL_FIRTH_ITERATIONS", iteration)
}

repl_firth_compute(
    "REPL_FIRTH_Y",
    "REPL_FIRTH_X",
    "REPL_FIRTH_RESULTS",
    "REPL_FIRTH_CELLS"
)
end

local firth_N = rowsof(REPL_FIRTH_Y)
local firth_contrast_1 "Women - men, housing-concentrated"
local firth_contrast_2 "Women - men, housing-plus"
local firth_contrast_3 "Men, concentrated - plus"
local firth_contrast_4 "Women, concentrated - plus"
local firth_contrast_5 "Gender-gap contrast: concentrated - plus"

forvalues firth_row = 1/5 {
    post `results' ("M6_bias_reduced_firth") ///
        ("`firth_contrast_`firth_row''") ///
        (REPL_FIRTH_RESULTS[`firth_row', 1]) ///
        (REPL_FIRTH_RESULTS[`firth_row', 2]) ///
        (REPL_FIRTH_RESULTS[`firth_row', 3]) ///
        (REPL_FIRTH_RESULTS[`firth_row', 4]) ///
        (REPL_FIRTH_RESULTS[`firth_row', 5]) ///
        (`firth_N')
}

forvalues firth_row = 1/4 {
    local firth_gender = floor((`firth_row' - 1) / 2)
    local firth_portfolio = mod(`firth_row' - 1, 2)
    post `cells' ("M6_bias_reduced_firth") ///
        (`firth_gender') (`firth_portfolio') ///
        (REPL_FIRTH_CELLS[`firth_row', 1]) ///
        (REPL_FIRTH_CELLS[`firth_row', 2]) ///
        (REPL_FIRTH_CELLS[`firth_row', 3]) ///
        (REPL_FIRTH_CELLS[`firth_row', 4]) ///
        (`firth_N')
}

display as text "Firth bias-reduced logit converged in " ///
    REPL_FIRTH_ITERATIONS " adjusted-score iterations."

postclose `results'
postclose `cells'
postclose `clusters'

use `results_data', clear
replace p = 2 * ttail(`province_df', abs(estimate / se)) ///
    if specification == "M3_wealth_province_cluster"
replace ci_lb = estimate - invttail(`province_df', .025) * se ///
    if specification == "M3_wealth_province_cluster"
replace ci_ub = estimate + invttail(`province_df', .025) * se ///
    if specification == "M3_wealth_province_cluster"
generate estimate_pp = 100 * estimate
generate se_pp = 100 * se
generate ci_lb_pp = 100 * ci_lb
generate ci_ub_pp = 100 * ci_ub
save "$MODELS/core_model_sequence_01_10_2026.dta", replace
export delimited using "$TABLES/core_model_sequence_01_10_2026.csv", replace

use `cells_data', clear
generate probability_pct = 100 * probability
generate se_pct = 100 * se
generate ci_lb_pct = 100 * ci_lb
generate ci_ub_pct = 100 * ci_ub
save "$MODELS/core_adjusted_probabilities_01_10_2026.dta", replace
export delimited using "$TABLES/core_adjusted_probabilities_01_10_2026.csv", replace

use `clusters_data', clear
save "$MODELS/inference_cluster_counts_01_10_2026.dta", replace
export delimited using "$TABLES/inference_cluster_counts_01_10_2026.csv", replace

exit
}

if "`module'" == "control_coefficients" {
/* Control coefficients. */
version 18

version 18
clear
set more off
set varabbrev off

if "$ROOT" == "" {
    display as error "Run 00_master_01_10_2026.do from the package folder."
    exit 198
}

use "$DATA/core_entrants_01_10_2026.dta", clear

local C_BACKGROUND ///
    c.age_entry_imp ///
    i.level i.wave i.provcd_h ///
    i.hukou_agri_cat i.urban_cat ///
    i.parent_college_cat
local C_INCOME c.ihs_hh_income_pc_imp i.income_miss
local C_WEALTH c.ihs_total_asset_same

quietly logit stem i.female##i.housing_portfolio ///
    `C_BACKGROUND' `C_INCOME' `C_WEALTH', vce(robust)
generate byte common_sample = e(sample)
quietly count if common_sample
assert r(N) == 870

local H0_controls "`C_BACKGROUND'"
local H1_controls "`C_BACKGROUND' `C_INCOME'"
local H2_controls "`C_BACKGROUND' `C_WEALTH'"
local H3_controls "`C_BACKGROUND' `C_INCOME' `C_WEALTH'"
local H0_name "H0_background"
local H1_name "H1_plus_income"
local H2_name "H2_plus_wealth"
local H3_name "H3_income_and_wealth"

tempname handle
tempfile results
postfile `handle' str36 specification str100 term ///
    double estimate se p long model_N using `results', replace

forvalues model = 0/3 {
    quietly logit stem i.female##i.housing_portfolio ///
        `H`model'_controls' if common_sample, vce(robust)
    assert e(N) == 870
    matrix B = e(b)
    matrix V = e(V)
    local names : colfullnames B
    local K = colsof(B)
    forvalues j = 1/`K' {
        local term : word `j' of `names'
        scalar beta = B[1, `j']
        scalar sigma = sqrt(V[`j', `j'])
        scalar pvalue = cond(sigma > 0, 2 * normal(-abs(beta / sigma)), .)
        post `handle' ("`H`model'_name'") ("`term'") ///
            (beta) (sigma) (pvalue) (e(N))
    }
}

postclose `handle'
use `results', clear
order specification term estimate se p model_N
sort specification term
export delimited using "$TABLES/table2_control_coefficients_01_10_2026.csv", replace

exit
}

if "`module'" == "resource_sequence" {
/* Resource sequence. */
version 18
capture program drop hssc_fit
program define hssc_fit
    syntax varname, EXPOSURE(name) SPEC(string) SAMPLE(string) CONTROLS(string)
    quietly logit `varlist' i.female##i.`exposure' `controls' if `sample', vce(robust)
    assert e(converged) == 1
    local n = e(N)
    estimates save "$HSSC_RESULTS/models/`spec'_$HSSC_DATE.ster", replace
    quietly margins female#`exposure', post noestimcheck
    matrix hssc_b = e(b)
    matrix hssc_V = e(V)
    assert colsof(hssc_b) == 4
    forvalues g=0/1 {
        forvalues p=0/1 {
            local j = 1+2*`g'+`p'
            scalar hssc_e = 100*hssc_b[1,`j']
            scalar hssc_s = 100*sqrt(hssc_V[`j',`j'])
            post $HSSC_PRED ("`spec'") ("`varlist'") (`g') (`p') (`n') ///
                (hssc_e) (hssc_s) (hssc_e-invnormal(.975)*hssc_s) (hssc_e+invnormal(.975)*hssc_s)
        }
    }
    forvalues j=1/3 {
        if `j'==1 {
            matrix hssc_L=(-1,1,0,0)
            local contrast "Men: group 1 minus group 0"
        }
        if `j'==2 {
            matrix hssc_L=(0,0,-1,1)
            local contrast "Women: group 1 minus group 0"
        }
        if `j'==3 {
            matrix hssc_L=(1,-1,-1,1)
            local contrast "Women minus men difference in contrasts"
        }
        matrix hssc_E=hssc_L*hssc_b'
        matrix hssc_S=hssc_L*hssc_V*hssc_L'
        scalar hssc_e=100*hssc_E[1,1]
        scalar hssc_s=100*sqrt(hssc_S[1,1])
        scalar hssc_p=2*normal(-abs(hssc_e/hssc_s))
        post $HSSC_CONTRAST ("`spec'") ("`varlist'") ("`contrast'") (`n') ///
            (hssc_e) (hssc_s) (hssc_p) ///
            (hssc_e-invnormal(.975)*hssc_s) (hssc_e+invnormal(.975)*hssc_s)
    }
end

version 18
use "$HSSC_DATA/core_entrants_$HSSC_DATE.dta", clear
quietly logit stem i.female##i.housing_portfolio $C_OUTCOME_WEALTH, vce(robust)
generate byte common_sample=e(sample)
assert e(N)==870
tempname contrasts predictions
tempfile condata preddata
postfile `contrasts' str48 specification str24 outcome str72 contrast long model_N ///
    double estimate_pp se_pp p ci_lb_pp ci_ub_pp using `condata', replace
postfile `predictions' str48 specification str24 outcome byte female portfolio long model_N ///
    double probability_pct se_pct ci_lb_pct ci_ub_pct using `preddata', replace
global HSSC_CONTRAST "`contrasts'"
global HSSC_PRED "`predictions'"
local H0 "$C_BACKGROUND"
local H1 "$C_MAIN"
local H2 "$C_BACKGROUND c.ihs_total_asset_same"
local H3 "$C_OUTCOME_WEALTH"
forvalues m=0/3 {
    hssc_fit stem, exposure(housing_portfolio) spec("H`m'_resource_sequence") ///
        sample("common_sample") controls("`H`m''")
}
postclose `contrasts'
postclose `predictions'
use `condata', clear
export delimited using "$TABLES/main_resource_contrasts_$HSSC_DATE.csv", replace
save "$MODELS/main_resource_contrasts_$HSSC_DATE.dta", replace
use `preddata', clear
export delimited using "$TABLES/main_resource_probabilities_$HSSC_DATE.csv", replace
save "$MODELS/main_resource_probabilities_$HSSC_DATE.dta", replace

exit
}

if "`module'" == "resource_interactions" {
/* Resource interactions. */
version 18
clear
set more off
set linesize 180

use "$DATA/core_entrants_01_10_2026.dta", clear

tempname contrasts cells slopes
tempfile contrasts_data cells_data slopes_data
postfile `contrasts' str42 specification str52 contrast ///
    double estimate se p ci_lb ci_ub long model_N using `contrasts_data', replace
postfile `cells' str42 specification byte female portfolio ///
    double probability se ci_lb ci_ub long model_N using `cells_data', replace
postfile `slopes' str42 specification str32 resource byte female ///
    double estimate se p ci_lb ci_ub long model_N using `slopes_data', replace
global DIAG_CONTRASTS "`contrasts'"
global DIAG_CELLS "`cells'"
global DIAG_SLOPES "`slopes'"

capture program drop post_probability_contrasts
program define post_probability_contrasts
    syntax, SPEC(string) MODELN(integer)

    quietly margins female#housing_portfolio, post noestimcheck

    foreach g in 0 1 {
        foreach p in 0 1 {
            local gterm "0bn"
            if `g' == 1 local gterm "1"
            quietly lincom _b[`gterm'.female#`p'.housing_portfolio]
            post $DIAG_CELLS ("`spec'") (`g') (`p') ///
                (r(estimate)) (r(se)) (r(lb)) (r(ub)) (`modeln')
        }
    }

    quietly lincom _b[1.female#0.housing_portfolio] - ///
        _b[0bn.female#0.housing_portfolio]
    post $DIAG_CONTRASTS ("`spec'") ("Women - men, housing-concentrated") ///
        (r(estimate)) (r(se)) (r(p)) (r(lb)) (r(ub)) (`modeln')

    quietly lincom _b[1.female#1.housing_portfolio] - ///
        _b[0bn.female#1.housing_portfolio]
    post $DIAG_CONTRASTS ("`spec'") ("Women - men, housing-plus") ///
        (r(estimate)) (r(se)) (r(p)) (r(lb)) (r(ub)) (`modeln')

    quietly lincom _b[0bn.female#0.housing_portfolio] - ///
        _b[0bn.female#1.housing_portfolio]
    post $DIAG_CONTRASTS ("`spec'") ("Men, concentrated - plus") ///
        (r(estimate)) (r(se)) (r(p)) (r(lb)) (r(ub)) (`modeln')

    quietly lincom _b[1.female#0.housing_portfolio] - ///
        _b[1.female#1.housing_portfolio]
    post $DIAG_CONTRASTS ("`spec'") ("Women, concentrated - plus") ///
        (r(estimate)) (r(se)) (r(p)) (r(lb)) (r(ub)) (`modeln')

    quietly lincom ///
        (_b[1.female#0.housing_portfolio] - ///
         _b[0bn.female#0.housing_portfolio]) - ///
        (_b[1.female#1.housing_portfolio] - ///
         _b[0bn.female#1.housing_portfolio])
    post $DIAG_CONTRASTS ("`spec'") ("Gender-gap contrast: concentrated - plus") ///
        (r(estimate)) (r(se)) (r(p)) (r(lb)) (r(ub)) (`modeln')
end

capture program drop post_resource_slopes
program define post_resource_slopes
    syntax varname, SPEC(string) MODELN(integer) [DF(real 0)]

    quietly margins female, dydx(`varlist')
    matrix B = r(b)
    matrix V = r(V)

    forvalues j = 1/2 {
        local g = `j' - 1
        scalar b_g = B[1, `j']
        scalar se_g = sqrt(V[`j', `j'])
        scalar test_g = b_g / se_g
        if `df' > 0 {
            scalar crit_g = invttail(`df', .025)
            scalar p_g = 2 * ttail(`df', abs(test_g))
        }
        else {
            scalar crit_g = invnormal(.975)
            scalar p_g = 2 * normal(-abs(test_g))
        }
        scalar lb_g = b_g - crit_g * se_g
        scalar ub_g = b_g + crit_g * se_g
        post $DIAG_SLOPES ("`spec'") ("`varlist'") (`g') ///
            (b_g) (se_g) (p_g) (lb_g) (ub_g) (`modeln')
    }

    scalar b_d = B[1, 2] - B[1, 1]
    scalar se_d = sqrt(V[2, 2] + V[1, 1] - 2 * V[2, 1])
    scalar test_d = b_d / se_d
    if `df' > 0 {
        scalar crit_d = invttail(`df', .025)
        scalar p_d = 2 * ttail(`df', abs(test_d))
    }
    else {
        scalar crit_d = invnormal(.975)
        scalar p_d = 2 * normal(-abs(test_d))
    }
    scalar lb_d = b_d - crit_d * se_d
    scalar ub_d = b_d + crit_d * se_d
    post $DIAG_SLOPES ("`spec'") ("`varlist'") (-1) ///
        (b_d) (se_d) (p_d) (lb_d) (ub_d) (`modeln')
end
quietly logit stem i.female##i.housing_portfolio ///
    $C_OUTCOME_WEALTH, vce(robust)
local model_N = e(N)
post_probability_contrasts, spec("D0_preferred") modeln(`model_N')
quietly logit stem i.female##i.housing_portfolio ///
    i.female#c.ihs_hh_income_pc_imp ///
    $C_OUTCOME_WEALTH, vce(robust)
local model_N = e(N)
post_resource_slopes ihs_hh_income_pc_imp, ///
    spec("D1_income_by_gender") modeln(`model_N')
post_probability_contrasts, spec("D1_income_by_gender") modeln(`model_N')
quietly logit stem i.female##i.housing_portfolio ///
    i.female#c.ihs_total_asset_same ///
    $C_OUTCOME_WEALTH, vce(robust)
local model_N = e(N)
post_resource_slopes ihs_total_asset_same, ///
    spec("D2_wealth_by_gender") modeln(`model_N')
post_probability_contrasts, spec("D2_wealth_by_gender") modeln(`model_N')
quietly logit stem i.female##i.housing_portfolio ///
    i.female#c.ihs_hh_income_pc_imp ///
    i.female#c.ihs_total_asset_same ///
    $C_OUTCOME_WEALTH, vce(robust)
local model_N = e(N)
post_resource_slopes ihs_hh_income_pc_imp, ///
    spec("D3_income_wealth_by_gender") modeln(`model_N')
post_resource_slopes ihs_total_asset_same, ///
    spec("D3_income_wealth_by_gender") modeln(`model_N')
post_probability_contrasts, spec("D3_income_wealth_by_gender") modeln(`model_N')

postclose `contrasts'
postclose `cells'
postclose `slopes'

use `contrasts_data', clear
generate estimate_pp = 100 * estimate
generate se_pp = 100 * se
generate ci_lb_pp = 100 * ci_lb
generate ci_ub_pp = 100 * ci_ub
save "$MODELS/resource_gender_contrasts_01_10_2026.dta", replace
export delimited using "$TABLES/resource_gender_contrasts_01_10_2026.csv", replace

use `cells_data', clear
generate probability_pct = 100 * probability
generate se_pct = 100 * se
generate ci_lb_pct = 100 * ci_lb
generate ci_ub_pct = 100 * ci_ub
save "$MODELS/resource_gender_cells_01_10_2026.dta", replace
export delimited using "$TABLES/resource_gender_cells_01_10_2026.csv", replace

use `slopes_data', clear
label define gender_slope -1 "Women - men" 0 "Men" 1 "Women"
label values female gender_slope
generate estimate_pp = 100 * estimate
generate se_pp = 100 * se
generate ci_lb_pp = 100 * ci_lb
generate ci_ub_pp = 100 * ci_ub
save "$MODELS/resource_gender_slopes_01_10_2026.dta", replace
export delimited using "$TABLES/resource_gender_slopes_01_10_2026.csv", replace

exit
}

display as error "Unknown module."
exit 198
