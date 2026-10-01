/* Cleaning. */
version 18
args module
if "`module'" == "" {
    do "$CODE/01_cleaning_01_10_2026.do" wave2012
    do "$CODE/01_cleaning_01_10_2026.do" wave2014
    do "$CODE/01_cleaning_01_10_2026.do" wave2018
    do "$CODE/01_cleaning_01_10_2026.do" wave2020
    do "$CODE/01_cleaning_01_10_2026.do" wave2022
    do "$CODE/01_cleaning_01_10_2026.do" append
    do "$CODE/01_cleaning_01_10_2026.do" ready
    exit
}

if "`module'" == "wave2012" {
/* Wave2012. */
version 18

clear
set more off

global project "$ROOT"

global data "$HSSC_DATA/clean"
global cfps "$RAW"
global raw12 "$cfps/2012"

global adult12  "$raw12/cfps2012adult_202505.dta"
global famecon12 "$raw12/cfps2012famecon_201906.dta"

capture mkdir "$data"

capture confirm file "$adult12"
if _rc {
    display as error "Cannot find adult file:"
    display as error "$adult12"
    exit 601
}

capture confirm file "$famecon12"
if _rc {
    display as error "Cannot find family economic file:"
    display as error "$famecon12"
    exit 601
}

capture program drop neg2miss
program define neg2miss
    syntax varlist
    foreach v of varlist `varlist' {
        capture confirm numeric variable `v'
        if !_rc {
            quietly replace `v' = . if `v' < 0
        }
    }
end

use "$famecon12", clear

drop if missing(fid12)
duplicates drop fid12, force

capture confirm variable financial_product
if _rc gen double financial_product = .

capture confirm variable houseasset_net
if _rc {
    capture confirm variable houseasset_gross
    if !_rc {
        capture confirm variable house_debts
        if !_rc gen double houseasset_net = houseasset_gross - house_debts
        else gen double houseasset_net = .
    }
    else {
        gen double houseasset_net = .
    }
}

capture confirm variable fincome1_adj
if _rc {
    capture confirm variable fincome1
    if !_rc gen double fincome1_adj = fincome1
    else gen double fincome1_adj = .
}

capture confirm variable fincome1_per
if _rc {
    capture confirm variable fincome1
    if !_rc {
        capture confirm variable familysize
        if !_rc gen double fincome1_per = fincome1 / familysize
        else gen double fincome1_per = .
    }
    else {
        gen double fincome1_per = .
    }
}

capture confirm variable fincome1_per_adj
if _rc gen double fincome1_per_adj = fincome1_per

foreach v in fid10 provcd countyid cid urban12 ///
             familysize ///
             fincome1 fincome1_adj fincome1_per fincome1_per_adj fincper_p fincperadj_p ///
             fwage_1 foperate_1 fproperty_1 ftransfer_1 felse_1 ///
             expense pce food dress house daily med trco eec other ///
             company agrimachine durables_asset land_asset ///
             savings financial_product finance_asset fixed_asset ///
             debit_other nonhousing_debts house_debts ///
             resivalue_new resivalue otherhousevalue houseasset_gross houseasset_net total_asset ///
             fswt_natcs12 fswt_rescs12 fswt_natpn1012 fswt_respn1012 ///
             subsample subpopulation psu {
    capture confirm variable `v'
    if _rc gen double `v' = .
}

local famvars ///
    fid12 fid10 ///
    provcd countyid cid urban12 ///
    familysize ///
    fincome1 fincome1_adj fincome1_per fincome1_per_adj fincper_p fincperadj_p ///
    fwage_1 foperate_1 fproperty_1 ftransfer_1 felse_1 ///
    expense pce food dress house daily med trco eec other ///
    company agrimachine durables_asset land_asset ///
    savings financial_product finance_asset fixed_asset ///
    debit_other nonhousing_debts house_debts ///
    resivalue_new resivalue otherhousevalue houseasset_gross houseasset_net total_asset ///
    fswt_natcs12 fswt_rescs12 fswt_natpn1012 fswt_respn1012 ///
    subsample subpopulation psu

local keepfam
foreach v of local famvars {
    capture confirm variable `v'
    if !_rc local keepfam `keepfam' `v'
}

keep `keepfam'

capture confirm variable familysize
if !_rc rename familysize familysize12

gen hh_income_same = .
capture confirm variable fincome1
if !_rc replace hh_income_same = fincome1

capture confirm variable fincome1_adj
if !_rc replace hh_income_same = fincome1_adj if missing(hh_income_same)

gen hh_income_pc_same = .
capture confirm variable fincome1_per
if !_rc replace hh_income_pc_same = fincome1_per

capture confirm variable fincome1_per_adj
if !_rc replace hh_income_pc_same = fincome1_per_adj if missing(hh_income_pc_same)

gen hh_income_per_p_same = .
capture confirm variable fincper_p
if !_rc replace hh_income_per_p_same = fincper_p

capture confirm variable fincperadj_p
if !_rc replace hh_income_per_p_same = fincperadj_p if missing(hh_income_per_p_same)

gen total_asset_same = .
capture confirm variable total_asset
if !_rc replace total_asset_same = total_asset

gen houseasset_net_same = .
capture confirm variable houseasset_net
if !_rc replace houseasset_net_same = houseasset_net

gen houseasset_gross_same = .
capture confirm variable houseasset_gross
if !_rc replace houseasset_gross_same = houseasset_gross

gen finance_asset_same = .
capture confirm variable finance_asset
if !_rc replace finance_asset_same = finance_asset

gen fixed_asset_same = .
capture confirm variable fixed_asset
if !_rc replace fixed_asset_same = fixed_asset

gen land_asset_same = .
capture confirm variable land_asset
if !_rc replace land_asset_same = land_asset

gen durables_asset_same = .
capture confirm variable durables_asset
if !_rc replace durables_asset_same = durables_asset

gen savings_same = .
capture confirm variable savings
if !_rc replace savings_same = savings

gen financial_product_same = .
capture confirm variable financial_product
if !_rc replace financial_product_same = financial_product

gen company_asset_same = .
capture confirm variable company
if !_rc replace company_asset_same = company

gen agrimachine_asset_same = .
capture confirm variable agrimachine
if !_rc replace agrimachine_asset_same = agrimachine

gen resivalue_same = .
capture confirm variable resivalue_new
if !_rc replace resivalue_same = resivalue_new

capture confirm variable resivalue
if !_rc replace resivalue_same = resivalue if missing(resivalue_same)

gen otherhousevalue_same = .
capture confirm variable otherhousevalue
if !_rc replace otherhousevalue_same = otherhousevalue

gen debt_house_same = .
capture confirm variable house_debts
if !_rc replace debt_house_same = house_debts

gen debt_nonhouse_same = .
capture confirm variable nonhousing_debts
if !_rc replace debt_nonhouse_same = nonhousing_debts

gen debt_other_same = .
capture confirm variable debit_other
if !_rc replace debt_other_same = debit_other

gen debt_total_same = debt_house_same + debt_nonhouse_same
replace debt_total_same = debt_house_same if missing(debt_total_same) & !missing(debt_house_same)
replace debt_total_same = debt_nonhouse_same if missing(debt_total_same) & !missing(debt_nonhouse_same)

foreach v in hh_income_same hh_income_pc_same total_asset_same ///
         houseasset_net_same houseasset_gross_same finance_asset_same ///
         fixed_asset_same land_asset_same durables_asset_same ///
         savings_same financial_product_same company_asset_same ///
         agrimachine_asset_same debt_house_same debt_nonhouse_same debt_total_same {
    capture confirm variable `v'
    if !_rc {
        gen ihs_`v' = asinh(`v')
    }
}

xtile asset_q_same = total_asset_same if !missing(total_asset_same), nq(4)
xtile income_q_same = hh_income_pc_same if !missing(hh_income_pc_same), nq(4)

label define qlbl12 1 "Q1 lowest" 2 "Q2" 3 "Q3" 4 "Q4 highest", replace
label values asset_q_same qlbl12
label values income_q_same qlbl12

gen byte has_house = .
replace has_house = 1 if houseasset_gross_same > 0 & !missing(houseasset_gross_same)
replace has_house = 0 if houseasset_gross_same == 0

gen byte has_finance = .
replace has_finance = 1 if finance_asset_same > 0 & !missing(finance_asset_same)
replace has_finance = 0 if finance_asset_same == 0

gen byte has_business = .
replace has_business = 1 if fixed_asset_same > 0 & !missing(fixed_asset_same)
replace has_business = 0 if fixed_asset_same == 0

gen byte has_land = .
replace has_land = 1 if land_asset_same > 0 & !missing(land_asset_same)
replace has_land = 0 if land_asset_same == 0

gen byte has_debt = .
replace has_debt = 1 if debt_total_same > 0 & !missing(debt_total_same)
replace has_debt = 0 if debt_total_same == 0

gen byte asset_portfolio4 = .
replace asset_portfolio4 = 4 if has_business == 1
replace asset_portfolio4 = 2 if missing(asset_portfolio4) & has_house == 1 & has_finance == 0
replace asset_portfolio4 = 3 if missing(asset_portfolio4) & has_house == 1 & has_finance == 1
replace asset_portfolio4 = 1 if missing(asset_portfolio4) & !missing(has_house, has_finance, has_business)

label define port4lbl12 ///
    1 "Limited/non-housing assets" ///
    2 "Housing only" ///
    3 "Housing + financial assets" ///
    4 "Productive assets", replace
label values asset_portfolio4 port4lbl12

gen asset_wave_same = 2012
gen asset_wave_lag = 2010

compress
tempfile hhecon12
save `hhecon12', replace

use "$adult12", clear

drop if missing(pid)
duplicates drop pid, force

gen p_edu_raw = .

capture confirm variable cfps2012edu
if !_rc replace p_edu_raw = cfps2012edu if missing(p_edu_raw) & cfps2012edu >= 0

capture confirm variable cfps2011_latest_edu
if !_rc replace p_edu_raw = cfps2011_latest_edu if missing(p_edu_raw) & cfps2011_latest_edu >= 0

capture confirm variable cfps2011_latest_r1
if !_rc replace p_edu_raw = cfps2011_latest_r1 if missing(p_edu_raw) & cfps2011_latest_r1 >= 0

capture confirm variable kw1
if !_rc replace p_edu_raw = kw1 if missing(p_edu_raw) & kw1 >= 0

capture confirm variable te4
if !_rc replace p_edu_raw = te4 if missing(p_edu_raw) & te4 >= 0

gen byte p_edu_highschoolplus = .
replace p_edu_highschoolplus = 1 if inlist(p_edu_raw, 5, 6, 7, 8, 9)
replace p_edu_highschoolplus = 0 if inlist(p_edu_raw, 0, 1, 2, 3, 4, 10)

gen byte p_edu_collegeplus = .
replace p_edu_collegeplus = 1 if inlist(p_edu_raw, 6, 7, 8, 9)
replace p_edu_collegeplus = 0 if inlist(p_edu_raw, 0, 1, 2, 3, 4, 5, 10)

gen byte p_edu_bachelorplus = .
replace p_edu_bachelorplus = 1 if inlist(p_edu_raw, 7, 8, 9)
replace p_edu_bachelorplus = 0 if inlist(p_edu_raw, 0, 1, 2, 3, 4, 5, 6, 10)

gen p_age = .
capture confirm variable cfps2012_age
if !_rc replace p_age = cfps2012_age if cfps2012_age >= 0

gen byte p_party = .
capture confirm variable cfps_party
if !_rc {
    replace p_party = 1 if cfps_party == 1
    replace p_party = 0 if missing(p_party) & !missing(cfps_party)
}

gen p_occupation_code = .
foreach cand in qg303code qg303code_a_1 qg411code_a_1 job2012mn_occu {
    capture confirm variable `cand'
    if !_rc {
        replace p_occupation_code = `cand' if missing(p_occupation_code) & `cand' >= 0
    }
}

gen p_industry_code = .
foreach cand in qg302code qg302code_a_1 qg410code_a_1 {
    capture confirm variable `cand'
    if !_rc {
        replace p_industry_code = `cand' if missing(p_industry_code) & `cand' >= 0
    }
}

keep pid p_*
compress
tempfile parent_base
save `parent_base', replace

use `parent_base', clear
rename pid pid_f
foreach v of varlist p_* {
    local new = subinstr("`v'", "p_", "f_", 1)
    rename `v' `new'
}
tempfile father_bg
save `father_bg', replace

use `parent_base', clear
rename pid pid_m
foreach v of varlist p_* {
    local new = subinstr("`v'", "p_", "m_", 1)
    rename `v' `new'
}
tempfile mother_bg
save `mother_bg', replace

use "$adult12", clear

drop if missing(pid)
duplicates drop pid, force

local want ///
    pid fid12 fid10 ///
    cfps2012_age cfps2012_gender pid_f pid_m ///
    provcd countyid cid urban12 ///
    wc01 kra1 kr1 kr5m kr501 kr502 kr6m kra601 kra602 kra604 kra605 ///
    kr402ma kr402m kr403 kr420 kr420a kr425 kr426 kr430 kr431 kr432 ///
    kr405 kr405a kr405b kr406 kr406a kr406b ///
    kr410 kr413_s_1 kr413_s_2 kr413_s_3 kr413_s_4 kr413_s_5 kr413_s_6 ///
    kr413b_a_1 kr413b_a_2 kr413b_a_3 kr413b_a_4 kr413b_a_5 kr413b_a_6 ///
    ks1011 ks1012 ks1 ks102b ks2 ks201 ks202 ks3m ///
    ks4 ks501 ks502 ks503 ks504 ///
    ks601 ks602 ks603m ks604 ks605 ks606m ks701 ks702 ///
    ks8 ks801code ks901 ks902a ks906 ks905m ks907 ks908 ks904 ks903 ks977 ///
    ks9total ks9ckp ks9total_m ksa1total_m ks10 ///
    qint001 qext002 qint003 qext004 qint005 qext006 qint007 qext008 ///
    qint009 qint010 qint011 qext012 qext013 qint014 ///
    cfps2011_latest_edu cfps2011_latest_r1 cfps2011_latest_d3 ///
    cfps2010_gender cfps_minzu cfps_party qa301 qa701code ///
    longform shortform selfrpt proxyrpt rswt_natcs12 rswt_rescs12 rswt_natpn1012 rswt_respn1012

local keepvars
foreach v of local want {
    capture confirm variable `v'
    if !_rc local keepvars `keepvars' `v'
}
keep `keepvars'

foreach v in cfps2012_age cfps2012_gender provcd countyid cid urban12 ///
    wc01 kra1 kr1 kr5m kr501 kr502 kr6m kra601 kra602 kra604 kra605 ///
    kr402ma kr402m kr403 kr420 kr420a kr425 kr426 kr430 kr431 kr432 ///
    kr405 kr405a kr405b kr406 kr406a kr406b ///
    kr410 kr413_s_1 kr413_s_2 kr413_s_3 kr413_s_4 kr413_s_5 kr413_s_6 ///
    kr413b_a_1 kr413b_a_2 kr413b_a_3 kr413b_a_4 kr413b_a_5 kr413b_a_6 ///
    ks1011 ks1012 ks1 ks102b ks2 ks201 ks202 ks3m ///
    ks4 ks501 ks502 ks503 ks504 ///
    ks601 ks602 ks603m ks604 ks605 ks606m ks701 ks702 ///
    ks8 ks801code ks901 ks902a ks906 ks905m ks907 ks908 ks904 ks903 ks977 ///
    ks9total ks9ckp ks9total_m ksa1total_m ks10 ///
    qint001 qext002 qint003 qext004 qint005 qext006 qint007 qext008 ///
    qint009 qint010 qint011 qext012 qext013 qint014 ///
    cfps2011_latest_edu cfps2011_latest_r1 cfps2011_latest_d3 ///
    cfps2010_gender cfps_minzu cfps_party qa301 qa701code {
    capture confirm variable `v'
    if _rc gen `v' = .
}

neg2miss cfps2012_age cfps2012_gender provcd countyid cid urban12 ///
    wc01 kra1 kr1 kr5m kr501 kr502 kr6m kra601 kra602 kra604 kra605 ///
    kr402ma kr402m kr403 kr420 kr420a kr425 kr426 kr430 kr431 kr432 ///
    kr405 kr405a kr405b kr406 kr406a kr406b ///
    kr410 kr413_s_1 kr413_s_2 kr413_s_3 kr413_s_4 kr413_s_5 kr413_s_6 ///
    kr413b_a_1 kr413b_a_2 kr413b_a_3 kr413b_a_4 kr413b_a_5 kr413b_a_6 ///
    ks1011 ks1012 ks1 ks102b ks2 ks201 ks202 ks3m ///
    ks4 ks501 ks502 ks503 ks504 ///
    ks601 ks602 ks603m ks604 ks605 ks606m ks701 ks702 ///
    ks8 ks801code ks901 ks902a ks906 ks905m ks907 ks908 ks904 ks903 ks977 ///
    ks9total ks9ckp ks9total_m ksa1total_m ks10 ///
    qint001 qext002 qint003 qext004 qint005 qext006 qext008 ///
    qint009 qint010 qint011 qext012 qext013 qint014 ///
    cfps2011_latest_edu cfps2011_latest_r1 cfps2011_latest_d3 ///
    cfps2010_gender cfps_minzu cfps_party qa301 qa701code

gen byte female = .

quietly count if cfps2012_gender == 0
local has0 = r(N)

quietly count if cfps2012_gender == 5
local has5 = r(N)

if `has5' > 0 {
    replace female = cfps2012_gender == 5 if !missing(cfps2012_gender)
}
else if `has0' > 0 {
    replace female = cfps2012_gender == 0 if !missing(cfps2012_gender)
}
else {
    display as error "Please check cfps2012_gender coding manually."
    tab cfps2012_gender, nolabel m
}

label define femalelbl 0 "Male" 1 "Female", replace
label values female femalelbl

gen byte female12 = female
gen gender = cfps2012_gender

gen byte ps12 = inlist(kr1, 5, 6)

gen byte fulltime12 = .
replace fulltime12 = (kra1 == 1) if ps12 == 1

gen byte ordinary_ps12 = .
replace ordinary_ps12 = inlist(kr5m, 1, 2) if kr1 == 5
replace ordinary_ps12 = inlist(kr6m, 1, 2, 3) if kr1 == 6

gen ps_start12 = .
replace ps_start12 = kr502  if kr1 == 5
replace ps_start12 = kra602 if kr1 == 6
replace ps_start12 = . if ps_start12 < 1900

gen byte prev_ps = .
replace prev_ps = 1 if inrange(cfps2011_latest_r1, 5, 8) ///
                    | inrange(cfps2011_latest_edu, 6, 9)
replace prev_ps = 0 if (cfps2011_latest_r1 < 5 | missing(cfps2011_latest_r1)) ///
                  & (cfps2011_latest_edu < 6 | missing(cfps2011_latest_edu))
replace prev_ps = . if missing(cfps2011_latest_r1) & missing(cfps2011_latest_edu)

gen byte first_ps12 = ps12 == 1 ///
    & fulltime12 == 1 ///
    & ordinary_ps12 == 1 ///
    & inrange(ps_start12, 2011, 2012) ///
    & (prev_ps == 0 | missing(prev_ps))

gen wave = 2012

gen byte ps = ps12
gen byte level = .
replace level = 1 if kr1 == 5
replace level = 2 if kr1 == 6

label define levellbl 1 "Junior college" 2 "Bachelor", replace
label values level levellbl

gen byte fulltime = fulltime12
gen byte ordinary_ps = ordinary_ps12
gen ps_start = ps_start12
gen byte first_ps = first_ps12
gen byte strict_first_entrant = first_ps12
gen byte baseline_proxy = 0
gen byte sample_type = 1

replace kr501 = . if kr501 < 0
replace kra601 = . if kra601 < 0

gen disc = .
replace disc = kr501  if kr1 == 5
replace disc = kra601 if kr1 == 6
replace disc = . if disc < 0 | disc == 99

label define field5lbl ///
    1 "STEM" ///
    2 "Medicine" ///
    3 "Business-Law-Econ-Management" ///
    4 "Humanities-Social-Education" ///
    5 "Other", replace

gen byte field5 = .
replace field5 = 1 if inlist(disc, 7, 8)
replace field5 = 2 if disc == 10
replace field5 = 3 if inlist(disc, 2, 3, 12)
replace field5 = 4 if inlist(disc, 1, 4, 5, 6, 13)
replace field5 = 5 if inlist(disc, 9, 77)
replace field5 = 5 if missing(field5) & !missing(disc)

label values field5 field5lbl

gen byte stem = .
replace stem = 1 if field5 == 1
replace stem = 0 if inlist(field5, 2, 3, 4, 5)

label define stemlbl 0 "Non-STEM" 1 "STEM", replace
label values stem stemlbl

gen age12 = cfps2012_age

gen byte hukou_agri12 = .
replace hukou_agri12 = 1 if qa301 == 1
replace hukou_agri12 = 0 if inlist(qa301, 3, 5, 7, 79)

gen byte han12 = .
replace han12 = 1 if qa701code == 1
replace han12 = 0 if qa701code > 1 & qa701code < .

replace han12 = 1 if missing(han12) & cfps_minzu == 1
replace han12 = 0 if missing(han12) & cfps_minzu > 1 & cfps_minzu < .

gen urban12_ctrl = urban12
replace urban12_ctrl = . if urban12_ctrl < 0

gen edu_stage12 = kr1

gen byte school_public12 = .

gen byte school_key12 = .
replace school_key12 = 1 if kr402ma == 1
replace school_key12 = 0 if kr402ma == 5

gen byte key_class12 = .
replace key_class12 = 1 if kr403 == 1
replace key_class12 = 0 if kr403 == 5

gen class_rank12 = kr425
gen grade_rank12 = kr426
gen major_rank12 = kra605

gen byte rank_class_top25_12 = .
replace rank_class_top25_12 = 1 if inlist(class_rank12, 1, 2)
replace rank_class_top25_12 = 0 if inlist(class_rank12, 3, 4, 5)

gen byte rank_grade_top25_12 = .
replace rank_grade_top25_12 = 1 if inlist(grade_rank12, 1, 2)
replace rank_grade_top25_12 = 0 if inlist(grade_rank12, 3, 4, 5)

gen expected_edu12 = .
gen desired_occ_code12 = ks801code

gen study_hours_weekday12 = ks1011
gen study_hours_weekend12 = ks1012

gen byte student_cadre12 = .
replace student_cadre12 = 1 if ks1 == 1
replace student_cadre12 = 0 if ks1 == 5

gen byte club_participation12 = .
replace club_participation12 = 1 if ks2 == 1
replace club_participation12 = 0 if ks2 == 5

gen byte club_leader12 = .
replace club_leader12 = 1 if ks202 == 1
replace club_leader12 = 0 if ks202 == 5

gen talent_belief12 = ks4
gen self_academic12 = ks501
gen study_pressure12 = ks502
gen self_excellence12 = ks503
gen student_leader_fit12 = ks504

gen study_effort12 = ks601
gen concentration12 = ks602
gen homework_check12 = ks603m
gen rule_following12 = ks604
gen neatness12 = ks605
gen homework_before_play12 = ks606m

gen school_satisfaction12 = ks701
gen teacher_satisfaction12 = ks702

gen byte tutoring_any12 = .
replace tutoring_any12 = 1 if kr410 == 1
replace tutoring_any12 = 0 if kr410 == 5

gen edu_exp_school12 = ks9total_m
replace edu_exp_school12 = ks9total if missing(edu_exp_school12) & !missing(ks9total)
replace edu_exp_school12 = ks9ckp if missing(edu_exp_school12) & !missing(ks9ckp)

gen edu_exp_tutoring12 = ksa1total_m
gen edu_exp_total12 = ks9total_m
replace edu_exp_total12 = ks9total if missing(edu_exp_total12) & !missing(ks9total)
replace edu_exp_total12 = ks9ckp if missing(edu_exp_total12) & !missing(ks9ckp)

gen ihs_edu_exp_total12 = asinh(edu_exp_total12)
gen ihs_edu_exp_tutoring12 = asinh(edu_exp_tutoring12)

egen internalizing12 = rowmean(qint001 qint003 qint005 qint007 qint009 qint010 qint011 qint014)
egen externalizing12 = rowmean(qext002 qext004 qext006 qext008 qext012 qext013)

merge m:1 pid_f using `father_bg', gen(_merge_father12) keep(master match)
merge m:1 pid_m using `mother_bg', gen(_merge_mother12) keep(master match)

egen parent_edu_max12 = rowmax(f_edu_raw m_edu_raw)

gen byte parent_college_any12 = .
replace parent_college_any12 = 1 if f_edu_collegeplus == 1 | m_edu_collegeplus == 1
replace parent_college_any12 = 0 if f_edu_collegeplus == 0 & m_edu_collegeplus == 0

gen byte parent_bachelor_any12 = .
replace parent_bachelor_any12 = 1 if f_edu_bachelorplus == 1 | m_edu_bachelorplus == 1
replace parent_bachelor_any12 = 0 if f_edu_bachelorplus == 0 & m_edu_bachelorplus == 0

gen byte parent_highschool_any12 = .
replace parent_highschool_any12 = 1 if f_edu_highschoolplus == 1 | m_edu_highschoolplus == 1
replace parent_highschool_any12 = 0 if f_edu_highschoolplus == 0 & m_edu_highschoolplus == 0

gen byte parent_party_any12 = .
replace parent_party_any12 = 1 if f_party == 1 | m_party == 1
replace parent_party_any12 = 0 if f_party == 0 & m_party == 0

egen parent_age_mean12 = rowmean(f_age m_age)

gen byte father_linked12 = _merge_father12 == 3
gen byte mother_linked12 = _merge_mother12 == 3
gen byte both_parents_linked12 = father_linked12 == 1 & mother_linked12 == 1

merge m:1 fid12 using `hhecon12', gen(_merge_hhecon12) keep(master match)

gen byte valid_field = !missing(field5)
gen byte has_asset_same = !missing(total_asset_same)
gen byte has_income_same = !missing(hh_income_same)

gen byte analytic_2012 = first_ps12 == 1 & valid_field == 1 & has_asset_same == 1

gen fid_current = fid12
gen fid_pre = fid10

gen provcd_h = provcd
gen countyid_h = countyid
gen urban_h = urban12

gen byte has_basic_controls12 = !missing(age12, urban12_ctrl)
gen byte has_parent_edu12 = !missing(parent_college_any12)
gen byte has_academic_controls12 = !missing(rank_class_top25_12) | !missing(rank_grade_top25_12) | !missing(major_rank12)
gen byte has_mechanism_controls12 = !missing(study_effort12) | !missing(study_pressure12) | !missing(tutoring_any12) | !missing(edu_exp_total12)

label var female "Female indicator"
label var ps12 "Currently enrolled in junior college or bachelor program"
label var fulltime12 "Full-time student"
label var ordinary_ps12 "Ordinary junior college or bachelor program"
label var ps_start12 "Year started current postsecondary stage"
label var prev_ps "Already in postsecondary education in previous wave"
label var first_ps12 "First ordinary full-time postsecondary entrant in 2012"
label var disc "Unified discipline code for junior college and bachelor"
label var field5 "Field of study, junior college + bachelor"
label var stem "STEM field"

label var wave "Survey wave"
label var ps "Currently enrolled in junior college or bachelor"
label var level "Postsecondary level"
label var fulltime "Full-time student"
label var ordinary_ps "Ordinary junior college or bachelor program"
label var ps_start "Start year of current postsecondary stage"
label var first_ps "First ordinary full-time postsecondary entrant"
label var strict_first_entrant "Strict first entrant indicator"
label var baseline_proxy "Baseline proxy indicator"
label var sample_type "Sample type"

label var age12 "Age in 2012"
label var female12 "Female, 2012 adult file"
label var hukou_agri12 "Agricultural hukou, 2012"
label var han12 "Han ethnicity, 2012"
label var urban12_ctrl "Urban/rural indicator, 2012"

label var parent_college_any12 "At least one parent junior-college educated or above"
label var parent_bachelor_any12 "At least one parent bachelor educated or above"
label var parent_highschool_any12 "At least one parent high-school educated or above"
label var parent_party_any12 "At least one parent CCP member"
label var parent_age_mean12 "Mean parental age"
label var father_linked12 "Father linked in 2012 adult file"
label var mother_linked12 "Mother linked in 2012 adult file"
label var both_parents_linked12 "Both parents linked in 2012 adult file"

label var hh_income_same "Household income, 2012"
label var hh_income_pc_same "Per-capita household income, 2012"
label var hh_income_per_p_same "Per-capita household income percentile/rank, 2012"
label var total_asset_same "Household net assets, 2012"
label var houseasset_net_same "Net housing asset, 2012"
label var houseasset_gross_same "Gross housing asset, 2012"
label var finance_asset_same "Financial asset, 2012"
label var fixed_asset_same "Productive fixed asset, 2012"
label var land_asset_same "Land asset, 2012"
label var durables_asset_same "Durable asset, 2012"
label var savings_same "Savings, 2012"
label var financial_product_same "Financial products, 2012"
label var company_asset_same "Company/business asset, 2012"
label var agrimachine_asset_same "Agricultural machinery asset, 2012"
label var debt_house_same "Housing debt, 2012"
label var debt_nonhouse_same "Non-housing debt, 2012"
label var debt_total_same "Total household debt, 2012"
label var asset_q_same "Within-2012 household net asset quartile"
label var income_q_same "Within-2012 per-capita household income quartile"
label var has_house "Has housing asset, 2012"
label var has_finance "Has financial asset, 2012"
label var has_business "Has productive asset, 2012"
label var has_land "Has land asset, 2012"
label var has_debt "Has household debt, 2012"
label var asset_portfolio4 "Household asset portfolio, 2012"

label var analytic_2012 "2012 analytic sample: first entrant with valid field and assets"

foreach v of varlist _all {
    local lab : variable label `v'
    if "`lab'" == "" {
        label var `v' "`v'"
    }
}

preserve
    keep if inrange(age12,16,30) & (prev_ps==0 | missing(prev_ps)) & !missing(female,asset_portfolio4)
    save "$DATA/clean/cfps2012_selection_risk_01_10_2026.dta", replace
restore
keep if first_ps12 == 1

compress
save "$data/cfps2012_clean_all_01_10_2026.dta", replace

display "=================================================="
display "DONE. Saved:"
display "$data/cfps2012_clean_all_01_10_2026.dta"
display "=================================================="

display "Expected check: saved file should contain only 2012 strict first entrants, around 272."
count

display "STEM distribution in saved entrant cohort:"
tab stem, m

display "Level by female in saved entrant cohort:"
tab kr1 female, m

display "Female by field in saved entrant cohort:"
tab female field5, m

display "Field by level in saved entrant cohort:"
tab kr1 field5, m

display "Female STEM cell:"
count if female == 1 & field5 == 1

display "Male STEM cell:"
count if female == 0 & field5 == 1

display "Missing field in saved entrant cohort:"
count if missing(field5)

display "Analytic sample:"
tab analytic_2012, m

display "Asset portfolio among analytic sample:"
tab asset_portfolio4 if analytic_2012 == 1, m

display "Parent education availability among analytic sample:"
tab parent_college_any12 if analytic_2012 == 1, m

display "Check empty labels:"
foreach v of varlist _all {
    local lab : variable label `v'
    if "`lab'" == "" {
        display as error "`v' has no label"
    }
}

display "=================================================="
display "2012 cleaning complete."
display "=================================================="

exit
}

if "`module'" == "wave2014" {
/* Wave2014. */
version 18

clear
set more off

global project "$ROOT"

global data "$HSSC_DATA/clean"
global cfps "$RAW"
global raw14 "$cfps/2014"

global adult14  "$raw14/cfps2014adult_201906.dta"
global famecon14 "$raw14/cfps2014famecon_201906.dta"

capture mkdir "$data"

capture confirm file "$adult14"
if _rc {
    display as error "Cannot find adult file:"
    display as error "$adult14"
    exit 601
}

capture confirm file "$famecon14"
if _rc {
    display as error "Cannot find family economic file:"
    display as error "$famecon14"
    exit 601
}

capture program drop neg2miss
program define neg2miss
    syntax varlist
    foreach v of varlist `varlist' {
        capture confirm numeric variable `v'
        if !_rc {
            quietly replace `v' = . if `v' < 0
        }
    }
end

use "$famecon14", clear

drop if missing(fid14)
duplicates drop fid14, force

local famvars ///
    fid14 fid12 fid10 ///
    provcd14 countyid14 cid14 urban14 ///
    fml2014num familysize fresp1pid ///
    finc finc_est finc_max finc_min ///
    fincome1 fincome1_per fincome1_per_p ///
    fexp fexp_est fexp_max fexp_min expense pce ///
    food dress house daily med trco eec other ///
    agrimachine company durables_asset land_asset ///
    savings financial_product finance_asset fixed_asset ///
    debit_other nonhousing_debts house_debts ///
    resivalue otherhousevalue houseasset_gross houseasset_net ///
    total_asset ///
    fwage_1 foperate_1 fproperty_1 ftransfer_1 felse_1 ///
    fswt_natcs14 fswt_rescs14 fswt_natpn1014 fswt_respn1014 ///
    subsample14 subsample10 subpopulation10 psu

local keepfam
foreach v of local famvars {
    capture confirm variable `v'
    if !_rc local keepfam `keepfam' `v'
}

keep `keepfam'

capture confirm variable fml2014num
if !_rc rename fml2014num fml_count

capture confirm variable familysize
if !_rc rename familysize familysize14

capture confirm variable fresp1pid
if !_rc rename fresp1pid resp1pid14

gen hh_income_same = .
capture confirm variable fincome1
if !_rc replace hh_income_same = fincome1

capture confirm variable finc
if !_rc replace hh_income_same = finc if missing(hh_income_same)

gen hh_income_pc_same = .
capture confirm variable fincome1_per
if !_rc replace hh_income_pc_same = fincome1_per

gen hh_income_per_p_same = .
capture confirm variable fincome1_per_p
if !_rc replace hh_income_per_p_same = fincome1_per_p

gen total_asset_same = .
capture confirm variable total_asset
if !_rc replace total_asset_same = total_asset

gen houseasset_net_same = .
capture confirm variable houseasset_net
if !_rc replace houseasset_net_same = houseasset_net

gen houseasset_gross_same = .
capture confirm variable houseasset_gross
if !_rc replace houseasset_gross_same = houseasset_gross

gen finance_asset_same = .
capture confirm variable finance_asset
if !_rc replace finance_asset_same = finance_asset

gen fixed_asset_same = .
capture confirm variable fixed_asset
if !_rc replace fixed_asset_same = fixed_asset

gen land_asset_same = .
capture confirm variable land_asset
if !_rc replace land_asset_same = land_asset

gen durables_asset_same = .
capture confirm variable durables_asset
if !_rc replace durables_asset_same = durables_asset

gen savings_same = .
capture confirm variable savings
if !_rc replace savings_same = savings

gen financial_product_same = .
capture confirm variable financial_product
if !_rc replace financial_product_same = financial_product

gen company_asset_same = .
capture confirm variable company
if !_rc replace company_asset_same = company

gen agrimachine_asset_same = .
capture confirm variable agrimachine
if !_rc replace agrimachine_asset_same = agrimachine

gen resivalue_same = .
capture confirm variable resivalue
if !_rc replace resivalue_same = resivalue

gen otherhousevalue_same = .
capture confirm variable otherhousevalue
if !_rc replace otherhousevalue_same = otherhousevalue

gen debt_house_same = .
capture confirm variable house_debts
if !_rc replace debt_house_same = house_debts

gen debt_nonhouse_same = .
capture confirm variable nonhousing_debts
if !_rc replace debt_nonhouse_same = nonhousing_debts

gen debt_other_same = .
capture confirm variable debit_other
if !_rc replace debt_other_same = debit_other

gen debt_total_same = debt_house_same + debt_nonhouse_same
replace debt_total_same = debt_house_same if missing(debt_total_same) & !missing(debt_house_same)
replace debt_total_same = debt_nonhouse_same if missing(debt_total_same) & !missing(debt_nonhouse_same)

foreach v in hh_income_same hh_income_pc_same total_asset_same ///
         houseasset_net_same houseasset_gross_same finance_asset_same ///
         fixed_asset_same land_asset_same durables_asset_same ///
         savings_same financial_product_same company_asset_same ///
         agrimachine_asset_same debt_house_same debt_nonhouse_same debt_total_same {
    capture confirm variable `v'
    if !_rc {
        gen ihs_`v' = asinh(`v')
    }
}

xtile asset_q_same = total_asset_same if !missing(total_asset_same), nq(4)
xtile income_q_same = hh_income_pc_same if !missing(hh_income_pc_same), nq(4)

label define qlbl14 1 "Q1 lowest" 2 "Q2" 3 "Q3" 4 "Q4 highest", replace
label values asset_q_same qlbl14
label values income_q_same qlbl14

gen byte has_house = .
replace has_house = 1 if houseasset_gross_same > 0 & !missing(houseasset_gross_same)
replace has_house = 0 if houseasset_gross_same == 0

gen byte has_finance = .
replace has_finance = 1 if finance_asset_same > 0 & !missing(finance_asset_same)
replace has_finance = 0 if finance_asset_same == 0

gen byte has_business = .
replace has_business = 1 if fixed_asset_same > 0 & !missing(fixed_asset_same)
replace has_business = 0 if fixed_asset_same == 0

gen byte has_land = .
replace has_land = 1 if land_asset_same > 0 & !missing(land_asset_same)
replace has_land = 0 if land_asset_same == 0

gen byte has_debt = .
replace has_debt = 1 if debt_total_same > 0 & !missing(debt_total_same)
replace has_debt = 0 if debt_total_same == 0

gen byte asset_portfolio4 = .
replace asset_portfolio4 = 4 if has_business == 1
replace asset_portfolio4 = 2 if missing(asset_portfolio4) & has_house == 1 & has_finance == 0
replace asset_portfolio4 = 3 if missing(asset_portfolio4) & has_house == 1 & has_finance == 1
replace asset_portfolio4 = 1 if missing(asset_portfolio4) & !missing(has_house, has_finance, has_business)

label define port4lbl14 ///
    1 "Limited/non-housing assets" ///
    2 "Housing only" ///
    3 "Housing + financial assets" ///
    4 "Productive assets", replace
label values asset_portfolio4 port4lbl14

gen asset_wave_same = 2014
gen asset_wave_lag = 2012

compress
tempfile hhecon14
save `hhecon14', replace

use "$adult14", clear

drop if missing(pid)
duplicates drop pid, force

gen p_edu_raw = .

capture confirm variable cfps2014edu
if !_rc replace p_edu_raw = cfps2014edu if missing(p_edu_raw) & cfps2014edu >= 0

capture confirm variable te4
if !_rc replace p_edu_raw = te4 if missing(p_edu_raw) & te4 >= 0

capture confirm variable cfps2012_latest_edu
if !_rc replace p_edu_raw = cfps2012_latest_edu if missing(p_edu_raw) & cfps2012_latest_edu >= 0

capture confirm variable cfps2012_latest_r1
if !_rc replace p_edu_raw = cfps2012_latest_r1 if missing(p_edu_raw) & cfps2012_latest_r1 >= 0

gen byte p_edu_highschoolplus = .
replace p_edu_highschoolplus = 1 if inlist(p_edu_raw, 5, 6, 7, 8, 9)
replace p_edu_highschoolplus = 0 if inlist(p_edu_raw, 0, 1, 2, 3, 4, 10)

gen byte p_edu_collegeplus = .
replace p_edu_collegeplus = 1 if inlist(p_edu_raw, 6, 7, 8, 9)
replace p_edu_collegeplus = 0 if inlist(p_edu_raw, 0, 1, 2, 3, 4, 5, 10)

gen byte p_edu_bachelorplus = .
replace p_edu_bachelorplus = 1 if inlist(p_edu_raw, 7, 8, 9)
replace p_edu_bachelorplus = 0 if inlist(p_edu_raw, 0, 1, 2, 3, 4, 5, 6, 10)

gen p_age = .
capture confirm variable cfps2014_age
if !_rc replace p_age = cfps2014_age if cfps2014_age >= 0

gen byte p_party = .
capture confirm variable cfps_party
if !_rc {
    replace p_party = 1 if cfps_party == 1
    replace p_party = 0 if missing(p_party) & !missing(cfps_party)
}

gen p_occupation_code = .
foreach cand in qg303code qg303code_a_1 qg411code_a_1 job2012mn_occu {
    capture confirm variable `cand'
    if !_rc {
        replace p_occupation_code = `cand' if missing(p_occupation_code) & `cand' >= 0
    }
}

gen p_industry_code = .
foreach cand in qg302code qg302code_a_1 qg410code_a_1 {
    capture confirm variable `cand'
    if !_rc {
        replace p_industry_code = `cand' if missing(p_industry_code) & `cand' >= 0
    }
}

keep pid p_*
compress
tempfile parent_base
save `parent_base', replace

use `parent_base', clear
rename pid pid_f
foreach v of varlist p_* {
    local new = subinstr("`v'", "p_", "f_", 1)
    rename `v' `new'
}
tempfile father_bg
save `father_bg', replace

use `parent_base', clear
rename pid pid_m
foreach v of varlist p_* {
    local new = subinstr("`v'", "p_", "m_", 1)
    rename `v' `new'
}
tempfile mother_bg
save `mother_bg', replace

use "$adult14", clear

drop if missing(pid)
duplicates drop pid, force

local want ///
    pid fid14 fid12 fid10 fid_base ///
    cfps2014_age cfps_gender pid_f pid_m ///
    provcd14 countyid14 cid14 urban14 ///
    wc01 wc02 kra1 kr1 kr5m kr501 kr502 kr6m kra601 kra602 kra604 kra605 ///
    kr402ma kr402m kr403 kr420 kr420a kr425 kr426 kr430 kr431 kr432 ///
    kr405 kr405a kr405b kr406 kr406a kr406b ///
    ks1011 ks1012 ks1 ks102b ks2 ks201 ks202 ks3m ///
    ks4 ks501 ks502 ks503 ks504 ///
    ks601 ks602 ks603m ks604 ks605 ks606m ks701 ks702 ///
    ks8 ks801code ks901 ks902a ks906 ks905m ks907 ks908 ks904 ks903 ks977 ///
    ks9total ks9ckp ks9total_m ks10 ///
    qint001 qext002 qint003 qext004 qint005 qext006 qint007 qext008 ///
    qint009 qint010 qint011 qext012 qext013 qint014 ///
    cfps2012_latest_edu cfps2012_latest_r1 cfps2012latest_school ///
    cfps2014sch cfps2014edu cfps2014eduy cfps2014eduy_im ///
    cfps_birthy cfps_minzu cfps_party qa301 qa701code ///
    selfrpt proxyrpt rswt_natcs14 rswt_rescs14 rswt_natpn1014 rswt_respn1014

local keepvars
foreach v of local want {
    capture confirm variable `v'
    if !_rc local keepvars `keepvars' `v'
}
keep `keepvars'

foreach v in cfps2014_age cfps_gender provcd14 countyid14 cid14 urban14 ///
    wc01 wc02 kra1 kr1 kr5m kr501 kr502 kr6m kra601 kra602 kra604 kra605 ///
    kr402ma kr402m kr403 kr420 kr420a kr425 kr426 kr430 kr431 kr432 ///
    kr405 kr405a kr405b kr406 kr406a kr406b ///
    ks1011 ks1012 ks1 ks102b ks2 ks201 ks202 ks3m ///
    ks4 ks501 ks502 ks503 ks504 ///
    ks601 ks602 ks603m ks604 ks605 ks606m ks701 ks702 ///
    ks8 ks801code ks901 ks902a ks906 ks905m ks907 ks908 ks904 ks903 ks977 ///
    ks9total ks9ckp ks9total_m ks10 ///
    qint001 qext002 qint003 qext004 qint005 qext006 qint007 qext008 ///
    qint009 qint010 qint011 qext012 qext013 qint014 ///
    cfps2012_latest_edu cfps2012_latest_r1 cfps2012latest_school ///
    cfps2014sch cfps2014edu cfps2014eduy cfps2014eduy_im ///
    cfps_birthy cfps_minzu cfps_party qa301 qa701code {
    capture confirm variable `v'
    if _rc gen `v' = .
}

neg2miss cfps2014_age cfps_gender provcd14 countyid14 cid14 urban14 ///
    wc01 wc02 kra1 kr1 kr5m kr501 kr502 kr6m kra601 kra602 kra604 kra605 ///
    kr402ma kr402m kr403 kr420 kr420a kr425 kr426 kr430 kr431 kr432 ///
    kr405 kr405a kr405b kr406 kr406a kr406b ///
    ks1011 ks1012 ks1 ks102b ks2 ks201 ks202 ks3m ///
    ks4 ks501 ks502 ks503 ks504 ///
    ks601 ks602 ks603m ks604 ks605 ks606m ks701 ks702 ///
    ks8 ks801code ks901 ks902a ks906 ks905m ks907 ks908 ks904 ks903 ks977 ///
    ks9total ks9ckp ks9total_m ks10 ///
    qint001 qext002 qint003 qext004 qint005 qext006 qint007 qext008 ///
    qint009 qint010 qint011 qext012 qext013 qint014 ///
    cfps2012_latest_edu cfps2012_latest_r1 cfps2012latest_school ///
    cfps2014sch cfps2014edu cfps2014eduy cfps2014eduy_im ///
    cfps_birthy cfps_minzu cfps_party qa301 qa701code

gen byte female = .

quietly count if cfps_gender == 0
local has0 = r(N)

quietly count if cfps_gender == 5
local has5 = r(N)

if `has5' > 0 {
    replace female = cfps_gender == 5 if !missing(cfps_gender)
}
else if `has0' > 0 {
    replace female = cfps_gender == 0 if !missing(cfps_gender)
}
else {
    display as error "Please check cfps_gender coding manually."
    tab cfps_gender, nolabel m
}

label define femalelbl 0 "Male" 1 "Female", replace
label values female femalelbl

gen byte female14 = female
gen gender = cfps_gender

gen byte ps14 = inlist(kr1, 5, 6)

gen byte fulltime14 = .
replace fulltime14 = (kra1 == 1) if ps14 == 1

gen byte ordinary_ps14 = .
replace ordinary_ps14 = inlist(kr5m, 1, 2) if kr1 == 5
replace ordinary_ps14 = inlist(kr6m, 1, 2, 3) if kr1 == 6

gen ps_start14 = .
replace ps_start14 = kr502  if kr1 == 5
replace ps_start14 = kra602 if kr1 == 6
replace ps_start14 = . if ps_start14 < 1900

gen byte prev_ps = .
replace prev_ps = 1 if inrange(cfps2012_latest_r1, 5, 8) ///
                    | inrange(cfps2012_latest_edu, 6, 9)
replace prev_ps = 0 if (cfps2012_latest_r1 < 5 | missing(cfps2012_latest_r1)) ///
                  & (cfps2012_latest_edu < 6 | missing(cfps2012_latest_edu))
replace prev_ps = . if missing(cfps2012_latest_r1) & missing(cfps2012_latest_edu)

gen byte first_ps14 = ps14 == 1 ///
    & fulltime14 == 1 ///
    & ordinary_ps14 == 1 ///
    & inrange(ps_start14, 2013, 2014) ///
    & (prev_ps == 0 | missing(prev_ps))

gen wave = 2014

gen byte ps = ps14
gen byte level = .
replace level = 1 if kr1 == 5
replace level = 2 if kr1 == 6

label define levellbl 1 "Junior college" 2 "Bachelor", replace
label values level levellbl

gen byte fulltime = fulltime14
gen byte ordinary_ps = ordinary_ps14
gen ps_start = ps_start14
gen byte first_ps = first_ps14
gen byte strict_first_entrant = first_ps14
gen byte baseline_proxy = 0
gen byte sample_type = 1

replace kr501 = . if kr501 < 0
replace kra601 = . if kra601 < 0

gen disc = .
replace disc = kr501  if kr1 == 5
replace disc = kra601 if kr1 == 6
replace disc = . if disc < 0 | disc == 99

label define field5lbl ///
    1 "STEM" ///
    2 "Medicine" ///
    3 "Business-Law-Econ-Management" ///
    4 "Humanities-Social-Education" ///
    5 "Other", replace

gen byte field5 = .
replace field5 = 1 if inlist(disc, 7, 8)
replace field5 = 2 if disc == 10
replace field5 = 3 if inlist(disc, 2, 3, 12)
replace field5 = 4 if inlist(disc, 1, 4, 5, 6, 13)
replace field5 = 5 if inlist(disc, 9, 77)
replace field5 = 5 if missing(field5) & !missing(disc)

label values field5 field5lbl

gen byte stem = .
replace stem = 1 if field5 == 1
replace stem = 0 if inlist(field5, 2, 3, 4, 5)

label define stemlbl 0 "Non-STEM" 1 "STEM", replace
label values stem stemlbl

gen age14 = cfps2014_age

gen byte hukou_agri14 = .
replace hukou_agri14 = 1 if qa301 == 1
replace hukou_agri14 = 0 if inlist(qa301, 3, 5, 7, 79)

gen byte han14 = .
replace han14 = 1 if qa701code == 1
replace han14 = 0 if qa701code > 1 & qa701code < .

gen urban14_ctrl = urban14
replace urban14_ctrl = . if urban14_ctrl < 0

gen edu_stage14 = kr1

gen byte school_public14 = .
gen byte school_key14 = .
replace school_key14 = 1 if kr402ma == 1
replace school_key14 = 0 if kr402ma == 5

gen byte key_class14 = .
replace key_class14 = 1 if kr403 == 1
replace key_class14 = 0 if kr403 == 5

gen class_rank14 = kr425
gen grade_rank14 = kr426
gen major_rank14 = kra605

gen byte rank_class_top25_14 = .
replace rank_class_top25_14 = 1 if inlist(class_rank14, 1, 2)
replace rank_class_top25_14 = 0 if inlist(class_rank14, 3, 4, 5)

gen byte rank_grade_top25_14 = .
replace rank_grade_top25_14 = 1 if inlist(grade_rank14, 1, 2)
replace rank_grade_top25_14 = 0 if inlist(grade_rank14, 3, 4, 5)

gen expected_edu14 = .
gen desired_occ_code14 = ks801code

gen study_hours_weekday14 = ks1011
gen study_hours_weekend14 = ks1012

gen byte student_cadre14 = .
replace student_cadre14 = 1 if ks1 == 1
replace student_cadre14 = 0 if ks1 == 5

gen byte club_participation14 = .
replace club_participation14 = 1 if ks2 == 1
replace club_participation14 = 0 if ks2 == 5

gen byte club_leader14 = .
replace club_leader14 = 1 if ks202 == 1
replace club_leader14 = 0 if ks202 == 5

gen talent_belief14 = ks4
gen self_academic14 = ks501
gen study_pressure14 = ks502
gen self_excellence14 = ks503
gen student_leader_fit14 = ks504

gen study_effort14 = ks601
gen concentration14 = ks602
gen homework_check14 = ks603m
gen rule_following14 = ks604
gen neatness14 = ks605
gen homework_before_play14 = ks606m

gen school_satisfaction14 = ks701
gen teacher_satisfaction14 = ks702

gen byte tutoring_any14 = .
capture confirm variable ks8
if !_rc {
    replace tutoring_any14 = 1 if ks8 == 1
    replace tutoring_any14 = 0 if ks8 == 5
}

gen edu_exp_school14 = ks901 + ks902a + ks906 + ks905m + ks907 + ks908 + ks904 + ks977
replace edu_exp_school14 = . if missing(ks901, ks902a, ks906, ks905m, ks907, ks908, ks904, ks977)

gen edu_exp_tutoring14 = ks903
gen edu_exp_total14 = ks9total_m
replace edu_exp_total14 = ks9total if missing(edu_exp_total14) & !missing(ks9total)
replace edu_exp_total14 = ks9ckp if missing(edu_exp_total14) & !missing(ks9ckp)

gen ihs_edu_exp_total14 = asinh(edu_exp_total14)
gen ihs_edu_exp_tutoring14 = asinh(edu_exp_tutoring14)

egen internalizing14 = rowmean(qint001 qint003 qint005 qint007 qint009 qint010 qint011 qint014)
egen externalizing14 = rowmean(qext002 qext004 qext006 qext008 qext012 qext013)

merge m:1 pid_f using `father_bg', gen(_merge_father14) keep(master match)
merge m:1 pid_m using `mother_bg', gen(_merge_mother14) keep(master match)

egen parent_edu_max14 = rowmax(f_edu_raw m_edu_raw)

gen byte parent_college_any14 = .
replace parent_college_any14 = 1 if f_edu_collegeplus == 1 | m_edu_collegeplus == 1
replace parent_college_any14 = 0 if f_edu_collegeplus == 0 & m_edu_collegeplus == 0

gen byte parent_bachelor_any14 = .
replace parent_bachelor_any14 = 1 if f_edu_bachelorplus == 1 | m_edu_bachelorplus == 1
replace parent_bachelor_any14 = 0 if f_edu_bachelorplus == 0 & m_edu_bachelorplus == 0

gen byte parent_highschool_any14 = .
replace parent_highschool_any14 = 1 if f_edu_highschoolplus == 1 | m_edu_highschoolplus == 1
replace parent_highschool_any14 = 0 if f_edu_highschoolplus == 0 & m_edu_highschoolplus == 0

gen byte parent_party_any14 = .
replace parent_party_any14 = 1 if f_party == 1 | m_party == 1
replace parent_party_any14 = 0 if f_party == 0 & m_party == 0

egen parent_age_mean14 = rowmean(f_age m_age)

gen byte father_linked14 = _merge_father14 == 3
gen byte mother_linked14 = _merge_mother14 == 3
gen byte both_parents_linked14 = father_linked14 == 1 & mother_linked14 == 1

merge m:1 fid14 using `hhecon14', gen(_merge_hhecon14) keep(master match)

gen byte valid_field = !missing(field5)
gen byte has_asset_same = !missing(total_asset_same)
gen byte has_income_same = !missing(hh_income_same)

gen byte analytic_2014 = first_ps14 == 1 & valid_field == 1 & has_asset_same == 1

gen fid_current = fid14
gen fid_pre = fid12

gen provcd_h = provcd14
gen countyid_h = countyid14
gen urban_h = urban14

gen byte has_basic_controls14 = !missing(age14, urban14_ctrl)
gen byte has_parent_edu14 = !missing(parent_college_any14)
gen byte has_academic_controls14 = !missing(rank_class_top25_14) | !missing(rank_grade_top25_14) | !missing(major_rank14)
gen byte has_mechanism_controls14 = !missing(study_effort14) | !missing(study_pressure14) | !missing(tutoring_any14) | !missing(edu_exp_total14)

label var female "Female indicator"
label var ps14 "Currently enrolled in junior college or bachelor program"
label var fulltime14 "Full-time student"
label var ordinary_ps14 "Ordinary junior college or bachelor program"
label var ps_start14 "Year started current postsecondary stage"
label var prev_ps "Already in postsecondary education in previous wave"
label var first_ps14 "First ordinary full-time postsecondary entrant in 2014"
label var disc "Unified discipline code for junior college and bachelor"
label var field5 "Field of study, junior college + bachelor"
label var stem "STEM field"

label var wave "Survey wave"
label var ps "Currently enrolled in junior college or bachelor"
label var level "Postsecondary level"
label var fulltime "Full-time student"
label var ordinary_ps "Ordinary junior college or bachelor program"
label var ps_start "Start year of current postsecondary stage"
label var first_ps "First ordinary full-time postsecondary entrant"
label var strict_first_entrant "Strict first entrant indicator"
label var baseline_proxy "Baseline proxy indicator"
label var sample_type "Sample type"

label var age14 "Age in 2014"
label var female14 "Female, 2014 adult file"
label var hukou_agri14 "Agricultural hukou, 2014"
label var han14 "Han ethnicity, 2014"
label var urban14_ctrl "Urban/rural indicator, 2014"

label var parent_college_any14 "At least one parent junior-college educated or above"
label var parent_bachelor_any14 "At least one parent bachelor educated or above"
label var parent_highschool_any14 "At least one parent high-school educated or above"
label var parent_party_any14 "At least one parent CCP member"
label var parent_age_mean14 "Mean parental age"
label var father_linked14 "Father linked in 2014 adult file"
label var mother_linked14 "Mother linked in 2014 adult file"
label var both_parents_linked14 "Both parents linked in 2014 adult file"

label var hh_income_same "Household income, 2014"
label var hh_income_pc_same "Per-capita household income, 2014"
label var hh_income_per_p_same "Per-capita household income percentile/rank, 2014"
label var total_asset_same "Household net assets, 2014"
label var houseasset_net_same "Net housing asset, 2014"
label var houseasset_gross_same "Gross housing asset, 2014"
label var finance_asset_same "Financial asset, 2014"
label var fixed_asset_same "Productive fixed asset, 2014"
label var land_asset_same "Land asset, 2014"
label var durables_asset_same "Durable asset, 2014"
label var savings_same "Savings, 2014"
label var financial_product_same "Financial products, 2014"
label var company_asset_same "Company/business asset, 2014"
label var agrimachine_asset_same "Agricultural machinery asset, 2014"
label var debt_house_same "Housing debt, 2014"
label var debt_nonhouse_same "Non-housing debt, 2014"
label var debt_total_same "Total household debt, 2014"
label var asset_q_same "Within-2014 household net asset quartile"
label var income_q_same "Within-2014 per-capita household income quartile"
label var has_house "Has housing asset, 2014"
label var has_finance "Has financial asset, 2014"
label var has_business "Has productive asset, 2014"
label var has_land "Has land asset, 2014"
label var has_debt "Has household debt, 2014"
label var asset_portfolio4 "Household asset portfolio, 2014"

label var analytic_2014 "2014 analytic sample: first entrant with valid field and assets"

foreach v of varlist _all {
    local lab : variable label `v'
    if "`lab'" == "" {
        label var `v' "`v'"
    }
}

preserve
    keep if inrange(age14,16,30) & (prev_ps==0 | missing(prev_ps)) & !missing(female,asset_portfolio4)
    save "$DATA/clean/cfps2014_selection_risk_01_10_2026.dta", replace
restore
keep if first_ps14 == 1

compress
save "$data/cfps2014_clean_all_01_10_2026.dta", replace

display "=================================================="
display "DONE. Saved:"
display "$data/cfps2014_clean_all_01_10_2026.dta"
display "=================================================="

display "Expected check: saved file should contain only 2014 strict first entrants, around 256."
count

display "STEM distribution in saved entrant cohort:"
tab stem, m

display "Level by female in saved entrant cohort:"
tab kr1 female, m

display "Female by field in saved entrant cohort:"
tab female field5, m

display "Field by level in saved entrant cohort:"
tab kr1 field5, m

display "Female STEM cell:"
count if female == 1 & field5 == 1

display "Male STEM cell:"
count if female == 0 & field5 == 1

display "Missing field in saved entrant cohort:"
count if missing(field5)

display "Analytic sample:"
tab analytic_2014, m

display "Asset portfolio among analytic sample:"
tab asset_portfolio4 if analytic_2014 == 1, m

display "Parent education availability among analytic sample:"
tab parent_college_any14 if analytic_2014 == 1, m

display "Check empty labels:"
foreach v of varlist _all {
    local lab : variable label `v'
    if "`lab'" == "" {
        display as error "`v' has no label"
    }
}

display "=================================================="
display "2014 cleaning complete."
display "=================================================="

exit
}

if "`module'" == "wave2018" {
/* Wave2018. */
version 18

clear
set more off

global project "$ROOT"

global data "$HSSC_DATA/clean"
global cfps "$RAW"
global raw18 "$cfps/2018"

global person18  "$raw18/cfps2018person_202512.dta"
global famecon18 "$raw18/cfps2018famecon_202512.dta"

capture mkdir "$data"

capture confirm file "$person18"
if _rc {
    display as error "Cannot find person file:"
    display as error "$person18"
    exit 601
}

capture confirm file "$famecon18"
if _rc {
    display as error "Cannot find family economic file:"
    display as error "$famecon18"
    exit 601
}

capture program drop neg2miss
program define neg2miss
    syntax varlist
    foreach v of varlist `varlist' {
        capture confirm numeric variable `v'
        if !_rc {
            quietly replace `v' = . if `v' < 0
        }
    }
end

use "$famecon18", clear

drop if missing(fid18)
duplicates drop fid18, force

local famvars ///
    fid18 fid16 fid14 fid12 fid10 ///
    provcd18 countyid18 cid18 urban18 ///
    fml_count familysize18 headpid resp1pid ///
    finc finc_est finc1 fincome1 fincome1_per fincome1_per_p ///
    fexp fexp_est fexp1 ///
    food dress house daily med trco eec other pce eptran epwelf mortage expense ///
    agrimachine company durables_asset land_asset savings financial_product ///
    debit_other nonhousing_debts house_debts ///
    resivalue otherhousevalue houseasset_gross houseasset_net ///
    finance_asset fixed_asset total_asset ///
    fwage_1 foperate_1 fproperty_1 ftransfer_1 felse_1 ///
    fswt_natcs18n fswtps_natcs18n subsample subpopulation psu

local keepfam
foreach v of local famvars {
    capture confirm variable `v'
    if !_rc local keepfam `keepfam' `v'
}

keep `keepfam'

gen hh_income_same = .
capture confirm variable fincome1
if !_rc replace hh_income_same = fincome1

capture confirm variable finc
if !_rc replace hh_income_same = finc if missing(hh_income_same)

capture confirm variable finc1
if !_rc replace hh_income_same = finc1 if missing(hh_income_same)

gen hh_income_pc_same = .
capture confirm variable fincome1_per
if !_rc replace hh_income_pc_same = fincome1_per

gen hh_income_per_p_same = .
capture confirm variable fincome1_per_p
if !_rc replace hh_income_per_p_same = fincome1_per_p

gen total_asset_same = .
capture confirm variable total_asset
if !_rc replace total_asset_same = total_asset

gen houseasset_net_same = .
capture confirm variable houseasset_net
if !_rc replace houseasset_net_same = houseasset_net

gen houseasset_gross_same = .
capture confirm variable houseasset_gross
if !_rc replace houseasset_gross_same = houseasset_gross

gen finance_asset_same = .
capture confirm variable finance_asset
if !_rc replace finance_asset_same = finance_asset

gen fixed_asset_same = .
capture confirm variable fixed_asset
if !_rc replace fixed_asset_same = fixed_asset

gen land_asset_same = .
capture confirm variable land_asset
if !_rc replace land_asset_same = land_asset

gen durables_asset_same = .
capture confirm variable durables_asset
if !_rc replace durables_asset_same = durables_asset

gen savings_same = .
capture confirm variable savings
if !_rc replace savings_same = savings

gen financial_product_same = .
capture confirm variable financial_product
if !_rc replace financial_product_same = financial_product

gen company_asset_same = .
capture confirm variable company
if !_rc replace company_asset_same = company

gen agrimachine_asset_same = .
capture confirm variable agrimachine
if !_rc replace agrimachine_asset_same = agrimachine

gen resivalue_same = .
capture confirm variable resivalue
if !_rc replace resivalue_same = resivalue

gen otherhousevalue_same = .
capture confirm variable otherhousevalue
if !_rc replace otherhousevalue_same = otherhousevalue

gen debt_house_same = .
capture confirm variable house_debts
if !_rc replace debt_house_same = house_debts

gen debt_nonhouse_same = .
capture confirm variable nonhousing_debts
if !_rc replace debt_nonhouse_same = nonhousing_debts

gen debt_other_same = .
capture confirm variable debit_other
if !_rc replace debt_other_same = debit_other

gen debt_total_same = debt_house_same + debt_nonhouse_same
replace debt_total_same = debt_house_same if missing(debt_total_same) & !missing(debt_house_same)
replace debt_total_same = debt_nonhouse_same if missing(debt_total_same) & !missing(debt_nonhouse_same)

foreach v in hh_income_same hh_income_pc_same total_asset_same ///
         houseasset_net_same houseasset_gross_same finance_asset_same ///
         fixed_asset_same land_asset_same durables_asset_same ///
         savings_same financial_product_same company_asset_same ///
         agrimachine_asset_same debt_house_same debt_nonhouse_same debt_total_same {
    capture confirm variable `v'
    if !_rc {
        gen ihs_`v' = asinh(`v')
    }
}

xtile asset_q_same = total_asset_same if !missing(total_asset_same), nq(4)
xtile income_q_same = hh_income_pc_same if !missing(hh_income_pc_same), nq(4)

label define qlbl18 1 "Q1 lowest" 2 "Q2" 3 "Q3" 4 "Q4 highest", replace
label values asset_q_same qlbl18
label values income_q_same qlbl18

gen byte has_house = .
replace has_house = 1 if houseasset_gross_same > 0 & !missing(houseasset_gross_same)
replace has_house = 0 if houseasset_gross_same == 0

gen byte has_finance = .
replace has_finance = 1 if finance_asset_same > 0 & !missing(finance_asset_same)
replace has_finance = 0 if finance_asset_same == 0

gen byte has_business = .
replace has_business = 1 if fixed_asset_same > 0 & !missing(fixed_asset_same)
replace has_business = 0 if fixed_asset_same == 0

gen byte has_land = .
replace has_land = 1 if land_asset_same > 0 & !missing(land_asset_same)
replace has_land = 0 if land_asset_same == 0

gen byte has_debt = .
replace has_debt = 1 if debt_total_same > 0 & !missing(debt_total_same)
replace has_debt = 0 if debt_total_same == 0

gen byte asset_portfolio4 = .
replace asset_portfolio4 = 4 if has_business == 1
replace asset_portfolio4 = 2 if missing(asset_portfolio4) & has_house == 1 & has_finance == 0
replace asset_portfolio4 = 3 if missing(asset_portfolio4) & has_house == 1 & has_finance == 1
replace asset_portfolio4 = 1 if missing(asset_portfolio4) & !missing(has_house, has_finance, has_business)

label define port4lbl18 ///
    1 "Limited/non-housing assets" ///
    2 "Housing only" ///
    3 "Housing + financial assets" ///
    4 "Productive assets", replace
label values asset_portfolio4 port4lbl18

gen asset_wave_same = 2018
gen asset_wave_lag = 2016

compress
tempfile hhecon18
save `hhecon18', replace

use "$person18", clear

drop if missing(pid)
duplicates drop pid, force

gen p_edu_raw = .

capture confirm variable edu_update
if !_rc replace p_edu_raw = edu_update if missing(p_edu_raw) & edu_update >= 0

capture confirm variable edu_updated
if !_rc replace p_edu_raw = edu_updated if missing(p_edu_raw) & edu_updated >= 0

capture confirm variable kw01
if !_rc replace p_edu_raw = kw01 if missing(p_edu_raw) & kw01 >= 0

capture confirm variable w01
if !_rc replace p_edu_raw = w01 if missing(p_edu_raw) & w01 >= 0

capture confirm variable cfps2018edu
if !_rc replace p_edu_raw = cfps2018edu if missing(p_edu_raw) & cfps2018edu >= 0

capture confirm variable edu_last
if !_rc replace p_edu_raw = edu_last if missing(p_edu_raw) & edu_last >= 0

capture confirm variable r1_last
if !_rc replace p_edu_raw = r1_last if missing(p_edu_raw) & r1_last >= 0

gen byte p_edu_highschoolplus = .
replace p_edu_highschoolplus = 1 if inlist(p_edu_raw, 5, 6, 7, 8, 9)
replace p_edu_highschoolplus = 0 if inlist(p_edu_raw, 0, 3, 4, 10)

gen byte p_edu_collegeplus = .
replace p_edu_collegeplus = 1 if inlist(p_edu_raw, 6, 7, 8, 9)
replace p_edu_collegeplus = 0 if inlist(p_edu_raw, 0, 3, 4, 5, 10)

gen byte p_edu_bachelorplus = .
replace p_edu_bachelorplus = 1 if inlist(p_edu_raw, 7, 8, 9)
replace p_edu_bachelorplus = 0 if inlist(p_edu_raw, 0, 3, 4, 5, 6, 10)

gen p_age = .
capture confirm variable age
if !_rc replace p_age = age if age >= 0

gen byte p_party = .
capture confirm variable party
if !_rc {
    replace p_party = 1 if party == 1
    replace p_party = 0 if missing(p_party) & !missing(party)
}

gen p_occupation_code = .
foreach cand in qg411code_a_1 qg510code_a_1 qg609code_a_1 sg411code_best job2012mn_occu {
    capture confirm variable `cand'
    if !_rc {
        replace p_occupation_code = `cand' if missing(p_occupation_code) & `cand' >= 0
    }
}

gen p_industry_code = .
foreach cand in qg410code_a_1 qg509code_a_1 qg608code_a_1 sg410code {
    capture confirm variable `cand'
    if !_rc {
        replace p_industry_code = `cand' if missing(p_industry_code) & `cand' >= 0
    }
}

keep pid p_*
compress
tempfile parent_base
save `parent_base', replace

use `parent_base', clear
rename pid pid_f
foreach v of varlist p_* {
    local new = subinstr("`v'", "p_", "f_", 1)
    rename `v' `new'
}
tempfile father_bg
save `father_bg', replace

use `parent_base', clear
rename pid pid_m
foreach v of varlist p_* {
    local new = subinstr("`v'", "p_", "m_", 1)
    rename `v' `new'
}
tempfile mother_bg
save `mother_bg', replace

use "$person18", clear

drop if missing(pid)
duplicates drop pid, force

local want ///
    pid fid18 fid16 fid14 fid12 fid10 fid_base ///
    age gender gender_pre qa002 pid_f pid_m ///
    provcd18 countyid18 cid18 urban18 ///
    school qc1 qc2 qc3 qc4 qc5 qr0 ///
    qs7 qs8 qs701_b_1code qs9code qs801_b_1 ///
    qs601 qs602 qs603 qs604 qs605 qs606 ///
    qs10 qs1001 qs1003 qs11 qs1102 qs1103 ///
    kr425 kr426 kra605 ///
    qs1011 qs1012 qs1_b_2 qs102b qs2 qs201 qs202 ///
    qs3m qs4_b_2 qs501_b_2 qs502 qs503 qs504 ///
    qs601n qs602n qs603mn qs604n qs605n qs606mn qs701_b_2 qs702 ///
    pt1 pt2 pt201 pt3 pt301 pt4 pt401 pt5 pt501 pt7 pt701 pt8 ///
    pd503r pd501a pd502a pd503a pd504a pd501b pd577r pd5total pd5total_m pd6 pd7r ///
    qint001 qext002 qint003 qext004 qint005 qext006 qint007 qext008 ///
    qint009 qint010 qint011 qext012 qext013 qint014 ///
    edu_last r1_last edu_update edu_updated w01 cfps2018sch cfps2018edu party fml_count ///
    qa001b qa301 qa701code qc201 qs801_b_2code ///
    selfrpt proxyrpt rswt_natcs18n rswt_natpn1018n

local keepvars
foreach v of local want {
    capture confirm variable `v'
    if !_rc local keepvars `keepvars' `v'
}
keep `keepvars'

foreach v in age gender gender_pre qa002 provcd18 countyid18 cid18 urban18 ///
    school qc1 qc2 qc3 qc4 qc5 qr0 qs7 qs8 qs701_b_1code qs9code qs801_b_1 ///
    qs601 qs602 qs603 qs604 qs605 qs606 qs10 qs1001 qs1003 qs11 qs1102 qs1103 ///
    kr425 kr426 kra605 qs1011 qs1012 qs1_b_2 qs102b qs2 qs201 qs202 qs3m ///
    qs4_b_2 qs501_b_2 qs502 qs503 qs504 qs601n qs602n qs603mn qs604n qs605n qs606mn qs701_b_2 qs702 ///
    pt1 pt2 pt201 pt3 pt301 pt4 pt401 pt5 pt501 pt7 pt701 pt8 ///
    pd503r pd501a pd502a pd503a pd504a pd501b pd577r pd5total pd5total_m pd6 pd7r ///
    qint001 qext002 qint003 qext004 qint005 qext006 qint007 qext008 ///
    qint009 qint010 qint011 qext012 qext013 qint014 ///
    edu_last r1_last edu_update edu_updated w01 cfps2018sch cfps2018edu party fml_count qa001b qa301 qa701code qc201 qs801_b_2code {
    capture confirm variable `v'
    if _rc gen `v' = .
}

neg2miss age gender gender_pre qa002 provcd18 countyid18 cid18 urban18 ///
    school qc1 qc2 qc3 qc4 qc5 qr0 qs7 qs8 qs701_b_1code qs9code qs801_b_1 ///
    qs601 qs602 qs603 qs604 qs605 qs606 qs10 qs1001 qs1003 qs11 qs1102 qs1103 ///
    kr425 kr426 kra605 qs1011 qs1012 qs1_b_2 qs102b qs2 qs201 qs202 qs3m ///
    qs4_b_2 qs501_b_2 qs502 qs503 qs504 qs601n qs602n qs603mn qs604n qs605n qs606mn qs701_b_2 qs702 ///
    pt1 pt2 pt201 pt3 pt301 pt4 pt401 pt5 pt501 pt7 pt701 pt8 ///
    pd503r pd501a pd502a pd503a pd504a pd501b pd577r pd5total pd5total_m pd6 pd7r ///
    qint001 qext002 qint003 qext004 qint005 qext006 qint007 qext008 ///
    qint009 qint010 qint011 qext012 qext013 qint014 ///
    edu_last r1_last edu_update edu_updated w01 cfps2018sch cfps2018edu party fml_count qa001b qa301 qa701code qc201 qs801_b_2code

gen byte female = .

quietly count if gender == 0
local has0 = r(N)

quietly count if gender == 5
local has5 = r(N)

if `has5' > 0 {
    replace female = gender == 5 if !missing(gender)
}
else if `has0' > 0 {
    replace female = gender == 0 if !missing(gender)
}
else {
    display as error "Please check gender coding manually."
    tab gender, nolabel m
}

label define femalelbl 0 "Male" 1 "Female", replace
label values female femalelbl

gen byte female18 = female

gen byte ps18 = inlist(qc3, 6, 7)

gen byte fulltime18 = .
replace fulltime18 = (qc4 == 1) if ps18 == 1

gen byte ordinary_ps18 = .
replace ordinary_ps18 = inlist(qs7, 1, 2) if qc3 == 6
replace ordinary_ps18 = inlist(qs8, 1, 2, 3) if qc3 == 7

gen ps_start18 = qr0 if ps18 == 1
replace ps_start18 = . if ps_start18 < 1900

gen byte prev_ps = .
replace prev_ps = 1 if inrange(r1_last, 6, 9) | inrange(edu_last, 6, 9)
replace prev_ps = 0 if (r1_last < 6 | missing(r1_last)) ///
                  & (edu_last < 6 | missing(edu_last))
replace prev_ps = . if missing(r1_last) & missing(edu_last)

gen byte first_ps18 = ps18 == 1 ///
    & fulltime18 == 1 ///
    & ordinary_ps18 == 1 ///
    & inrange(ps_start18, 2017, 2018) ///
    & (prev_ps == 0 | missing(prev_ps))

gen wave = 2018

gen byte ps = ps18
gen byte level = .
replace level = 1 if qc3 == 6
replace level = 2 if qc3 == 7

label define levellbl 1 "Junior college" 2 "Bachelor", replace
label values level levellbl

gen byte fulltime = fulltime18
gen byte ordinary_ps = ordinary_ps18
gen ps_start = ps_start18
gen byte first_ps = first_ps18
gen byte strict_first_entrant = first_ps18
gen byte baseline_proxy = 0
gen byte sample_type = 1

replace qs701_b_1code = . if qs701_b_1code < 0
replace qs9code = . if qs9code < 0

gen disc = .
replace disc = qs701_b_1code if qc3 == 6
replace disc = qs9code        if qc3 == 7
replace disc = . if disc < 0 | disc == 99

label define field5lbl ///
    1 "STEM" ///
    2 "Medicine" ///
    3 "Business-Law-Econ-Management" ///
    4 "Humanities-Social-Education" ///
    5 "Other", replace

gen byte field5 = .
replace field5 = 1 if inlist(disc, 7, 8)
replace field5 = 2 if disc == 10
replace field5 = 3 if inlist(disc, 2, 3, 12)
replace field5 = 4 if inlist(disc, 1, 4, 5, 6, 13)
replace field5 = 5 if inlist(disc, 9, 77)
replace field5 = 5 if missing(field5) & !missing(disc)

label values field5 field5lbl

gen byte stem = .
replace stem = 1 if field5 == 1
replace stem = 0 if inlist(field5, 2, 3, 4, 5)

label define stemlbl 0 "Non-STEM" 1 "STEM", replace
label values stem stemlbl

gen age18 = age
replace age18 = qa001b if missing(age18) & !missing(qa001b)

gen byte hukou_agri18 = .
replace hukou_agri18 = 1 if qa301 == 1
replace hukou_agri18 = 0 if inlist(qa301, 3, 5, 7, 79)

gen byte han18 = .
replace han18 = 1 if qa701code == 1
replace han18 = 0 if qa701code > 1 & qa701code < .

gen urban18_ctrl = urban18
replace urban18_ctrl = . if urban18_ctrl < 0

gen edu_stage18 = qc3
gen grade_current18 = qc5

gen byte school_public18 = .
replace school_public18 = 1 if qs601 == 1
replace school_public18 = 0 if qs601 == 5

gen byte school_key18 = .
replace school_key18 = 1 if qs602 == 1
replace school_key18 = 0 if qs602 == 5

gen byte key_class18 = .
replace key_class18 = 1 if qs604 == 1
replace key_class18 = 0 if qs604 == 5

gen class_rank18 = kr425
gen grade_rank18 = kr426
gen major_rank18 = kra605

gen byte rank_class_top25_18 = .
replace rank_class_top25_18 = 1 if inlist(class_rank18, 1, 2)
replace rank_class_top25_18 = 0 if inlist(class_rank18, 3, 4, 5)

gen byte rank_grade_top25_18 = .
replace rank_grade_top25_18 = 1 if inlist(grade_rank18, 1, 2)
replace rank_grade_top25_18 = 0 if inlist(grade_rank18, 3, 4, 5)

gen expected_edu18 = qc201
gen desired_occ_code18 = qs801_b_2code

gen study_hours_weekday18 = qs1011
gen study_hours_weekend18 = qs1012

gen byte student_cadre18 = .
replace student_cadre18 = 1 if qs1_b_2 == 1
replace student_cadre18 = 0 if qs1_b_2 == 5

gen byte club_participation18 = .
replace club_participation18 = 1 if qs2 == 1
replace club_participation18 = 0 if qs2 == 5

gen byte club_leader18 = .
replace club_leader18 = 1 if qs202 == 1
replace club_leader18 = 0 if qs202 == 5

gen talent_belief18 = qs4_b_2
gen self_academic18 = qs501_b_2
gen study_pressure18 = qs502
gen self_excellence18 = qs503
gen student_leader_fit18 = qs504

gen study_effort18 = qs601n
gen concentration18 = qs602n
gen homework_check18 = qs603mn
gen rule_following18 = qs604n
gen neatness18 = qs605n
gen homework_before_play18 = qs606mn

gen school_satisfaction18 = qs701_b_2
gen teacher_satisfaction18 = qs702

gen byte tutoring_any18 = .
replace tutoring_any18 = 1 if pt1 == 1 | pt2 == 1 | pt3 == 1 | pt4 == 1 | pt5 == 1 | pt7 == 1 | pt8 == 1
replace tutoring_any18 = 0 if missing(tutoring_any18) & ///
    inlist(pt1,5,.) & inlist(pt2,5,.) & inlist(pt3,5,.) & inlist(pt4,5,.) & ///
    inlist(pt5,5,.) & inlist(pt7,5,.) & inlist(pt8,5,.)

gen edu_exp_school18 = pd501b
gen edu_exp_tutoring18 = pd503r
gen edu_exp_total18 = pd5total_m
replace edu_exp_total18 = pd5total if missing(edu_exp_total18) & !missing(pd5total)

gen ihs_edu_exp_total18 = asinh(edu_exp_total18)
gen ihs_edu_exp_tutoring18 = asinh(edu_exp_tutoring18)

egen internalizing18 = rowmean(qint001 qint003 qint005 qint007 qint009 qint010 qint011 qint014)
egen externalizing18 = rowmean(qext002 qext004 qext006 qext008 qext012 qext013)

merge m:1 pid_f using `father_bg', gen(_merge_father18) keep(master match)
merge m:1 pid_m using `mother_bg', gen(_merge_mother18) keep(master match)

egen parent_edu_max18 = rowmax(f_edu_raw m_edu_raw)

gen byte parent_college_any18 = .
replace parent_college_any18 = 1 if f_edu_collegeplus == 1 | m_edu_collegeplus == 1
replace parent_college_any18 = 0 if f_edu_collegeplus == 0 & m_edu_collegeplus == 0

gen byte parent_bachelor_any18 = .
replace parent_bachelor_any18 = 1 if f_edu_bachelorplus == 1 | m_edu_bachelorplus == 1
replace parent_bachelor_any18 = 0 if f_edu_bachelorplus == 0 & m_edu_bachelorplus == 0

gen byte parent_highschool_any18 = .
replace parent_highschool_any18 = 1 if f_edu_highschoolplus == 1 | m_edu_highschoolplus == 1
replace parent_highschool_any18 = 0 if f_edu_highschoolplus == 0 & m_edu_highschoolplus == 0

gen byte parent_party_any18 = .
replace parent_party_any18 = 1 if f_party == 1 | m_party == 1
replace parent_party_any18 = 0 if f_party == 0 & m_party == 0

egen parent_age_mean18 = rowmean(f_age m_age)

gen byte father_linked18 = _merge_father18 == 3
gen byte mother_linked18 = _merge_mother18 == 3
gen byte both_parents_linked18 = father_linked18 == 1 & mother_linked18 == 1

merge m:1 fid18 using `hhecon18', gen(_merge_hhecon18) keep(master match)

gen byte valid_field = !missing(field5)
gen byte has_asset_same = !missing(total_asset_same)
gen byte has_income_same = !missing(hh_income_same)

gen byte analytic_2018 = first_ps18 == 1 & valid_field == 1 & has_asset_same == 1

gen fid_current = fid18
gen fid_pre = fid16

gen provcd_h = provcd18
gen countyid_h = countyid18
gen urban_h = urban18

gen byte has_basic_controls18 = !missing(age18, urban18_ctrl)
gen byte has_parent_edu18 = !missing(parent_college_any18)
gen byte has_academic_controls18 = !missing(rank_class_top25_18) | !missing(rank_grade_top25_18) | !missing(major_rank18)
gen byte has_mechanism_controls18 = !missing(study_effort18) | !missing(study_pressure18) | !missing(tutoring_any18) | !missing(edu_exp_total18)

label var female "Female indicator"
label var ps18 "Currently enrolled in junior college or bachelor program"
label var fulltime18 "Full-time student"
label var ordinary_ps18 "Ordinary junior college or bachelor program"
label var ps_start18 "Year started current postsecondary stage"
label var prev_ps "Already in postsecondary education in previous wave"
label var first_ps18 "First ordinary full-time postsecondary entrant in 2018"
label var disc "Unified discipline code for junior college and bachelor"
label var field5 "Field of study, junior college + bachelor"
label var stem "STEM field"

label var wave "Survey wave"
label var ps "Currently enrolled in junior college or bachelor"
label var level "Postsecondary level"
label var fulltime "Full-time student"
label var ordinary_ps "Ordinary junior college or bachelor program"
label var ps_start "Start year of current postsecondary stage"
label var first_ps "First ordinary full-time postsecondary entrant"
label var strict_first_entrant "Strict first entrant indicator"
label var baseline_proxy "Baseline proxy indicator"
label var sample_type "Sample type"

label var age18 "Age in 2018"
label var female18 "Female, 2018 person file"
label var hukou_agri18 "Agricultural hukou, 2018"
label var han18 "Han ethnicity, 2018"
label var urban18_ctrl "Urban/rural indicator, 2018"

label var parent_college_any18 "At least one parent junior-college educated or above"
label var parent_bachelor_any18 "At least one parent bachelor educated or above"
label var parent_highschool_any18 "At least one parent high-school educated or above"
label var parent_party_any18 "At least one parent CCP member"
label var parent_age_mean18 "Mean parental age"
label var father_linked18 "Father linked in 2018 person file"
label var mother_linked18 "Mother linked in 2018 person file"
label var both_parents_linked18 "Both parents linked in 2018 person file"

label var hh_income_same "Household income, 2018"
label var hh_income_pc_same "Per-capita household income, 2018"
label var hh_income_per_p_same "Per-capita household income percentile/rank, 2018"
label var total_asset_same "Household net assets, 2018"
label var houseasset_net_same "Net housing asset, 2018"
label var houseasset_gross_same "Gross housing asset, 2018"
label var finance_asset_same "Financial asset, 2018"
label var fixed_asset_same "Productive fixed asset, 2018"
label var land_asset_same "Land asset, 2018"
label var durables_asset_same "Durable asset, 2018"
label var savings_same "Savings, 2018"
label var financial_product_same "Financial products, 2018"
label var company_asset_same "Company/business asset, 2018"
label var agrimachine_asset_same "Agricultural machinery asset, 2018"
label var debt_house_same "Housing debt, 2018"
label var debt_nonhouse_same "Non-housing debt, 2018"
label var debt_total_same "Total household debt, 2018"
label var asset_q_same "Within-2018 household net asset quartile"
label var income_q_same "Within-2018 per-capita household income quartile"
label var has_house "Has housing asset, 2018"
label var has_finance "Has financial asset, 2018"
label var has_business "Has productive asset, 2018"
label var has_land "Has land asset, 2018"
label var has_debt "Has household debt, 2018"
label var asset_portfolio4 "Household asset portfolio, 2018"

label var analytic_2018 "2018 analytic sample: first entrant with valid field and assets"

foreach v of varlist _all {
    local lab : variable label `v'
    if "`lab'" == "" {
        label var `v' "`v'"
    }
}

preserve
    keep if inrange(age18,16,30) & (prev_ps==0 | missing(prev_ps)) & !missing(female,asset_portfolio4)
    save "$DATA/clean/cfps2018_selection_risk_01_10_2026.dta", replace
restore
keep if first_ps18 == 1

compress
save "$data/cfps2018_clean_all_01_10_2026.dta", replace

display "=================================================="
display "DONE. Saved:"
display "$data/cfps2018_clean_all_01_10_2026.dta"
display "=================================================="

display "Expected check: saved file should contain only 2018 strict first entrants, around 280."
count

display "STEM distribution in saved entrant cohort:"
tab stem, m

display "Level by female in saved entrant cohort:"
tab qc3 female, m

display "Female by field in saved entrant cohort:"
tab female field5, m

display "Field by level in saved entrant cohort:"
tab qc3 field5, m

display "Female STEM cell:"
count if female == 1 & field5 == 1

display "Male STEM cell:"
count if female == 0 & field5 == 1

display "Missing field in saved entrant cohort:"
count if missing(field5)

display "Analytic sample:"
tab analytic_2018, m

display "Asset portfolio among analytic sample:"
tab asset_portfolio4 if analytic_2018 == 1, m

display "Parent education availability among analytic sample:"
tab parent_college_any18 if analytic_2018 == 1, m

display "Check empty labels:"
foreach v of varlist _all {
    local lab : variable label `v'
    if "`lab'" == "" {
        display as error "`v' has no label"
    }
}

display "=================================================="
display "2018 cleaning complete."
display "=================================================="

exit
}

if "`module'" == "wave2020" {
/* Wave2020. */
version 18

clear
set more off

global project "$ROOT"

global data "$HSSC_DATA/clean"
global cfps "$RAW"
global raw20 "$cfps/2020"

global person20  "$raw20/cfps2020person_202306.dta"
global famecon20 "$raw20/cfps2020famecon_202306.dta"

capture mkdir "$data"

capture confirm file "$person20"
if _rc {
    display as error "Cannot find person file:"
    display as error "$person20"
    exit 601
}

capture confirm file "$famecon20"
if _rc {
    display as error "Cannot find family economic file:"
    display as error "$famecon20"
    exit 601
}

capture program drop neg2miss
program define neg2miss
    syntax varlist
    foreach v of varlist `varlist' {
        capture confirm numeric variable `v'
        if !_rc {
            quietly replace `v' = . if `v' < 0
        }
    }
end

use "$famecon20", clear

drop if missing(fid20)
duplicates drop fid20, force

local famvars ///
    fid20 fid18 fid16 fid14 fid12 fid10 ///
    provcd20 countyid20 cid20 urban20 ///
    fml_count familysize20 headpid resp1pid ///
    finc finc_est finc1 fincome1 fincome1_per fincome1_per_p ///
    fexp fexp_est fexp1 ///
    food dress house daily med trco eec other pce eptran epwelf mortage expense ///
    agrimachine company durables_asset land_asset savings financial_product ///
    debit_other nonhousing_debts house_debts ///
    resivalue otherhousevalue houseasset_gross houseasset_net ///
    finance_asset fixed_asset total_asset ///
    fwage_1 foperate_1 fproperty_1 ftransfer_1 felse_1 ///
    fswt_natcs20n fswtps_natcs20n subsample subpopulation psu

local keepfam
foreach v of local famvars {
    capture confirm variable `v'
    if !_rc local keepfam `keepfam' `v'
}

keep `keepfam'

gen hh_income_same = .
capture confirm variable fincome1
if !_rc replace hh_income_same = fincome1

capture confirm variable finc
if !_rc replace hh_income_same = finc if missing(hh_income_same)

capture confirm variable finc1
if !_rc replace hh_income_same = finc1 if missing(hh_income_same)

gen hh_income_pc_same = .
capture confirm variable fincome1_per
if !_rc replace hh_income_pc_same = fincome1_per

gen hh_income_per_p_same = .
capture confirm variable fincome1_per_p
if !_rc replace hh_income_per_p_same = fincome1_per_p

gen total_asset_same = .
capture confirm variable total_asset
if !_rc replace total_asset_same = total_asset

gen houseasset_net_same = .
capture confirm variable houseasset_net
if !_rc replace houseasset_net_same = houseasset_net

gen houseasset_gross_same = .
capture confirm variable houseasset_gross
if !_rc replace houseasset_gross_same = houseasset_gross

gen finance_asset_same = .
capture confirm variable finance_asset
if !_rc replace finance_asset_same = finance_asset

gen fixed_asset_same = .
capture confirm variable fixed_asset
if !_rc replace fixed_asset_same = fixed_asset

gen land_asset_same = .
capture confirm variable land_asset
if !_rc replace land_asset_same = land_asset

gen durables_asset_same = .
capture confirm variable durables_asset
if !_rc replace durables_asset_same = durables_asset

gen savings_same = .
capture confirm variable savings
if !_rc replace savings_same = savings

gen financial_product_same = .
capture confirm variable financial_product
if !_rc replace financial_product_same = financial_product

gen company_asset_same = .
capture confirm variable company
if !_rc replace company_asset_same = company

gen agrimachine_asset_same = .
capture confirm variable agrimachine
if !_rc replace agrimachine_asset_same = agrimachine

gen resivalue_same = .
capture confirm variable resivalue
if !_rc replace resivalue_same = resivalue

gen otherhousevalue_same = .
capture confirm variable otherhousevalue
if !_rc replace otherhousevalue_same = otherhousevalue

gen debt_house_same = .
capture confirm variable house_debts
if !_rc replace debt_house_same = house_debts

gen debt_nonhouse_same = .
capture confirm variable nonhousing_debts
if !_rc replace debt_nonhouse_same = nonhousing_debts

gen debt_other_same = .
capture confirm variable debit_other
if !_rc replace debt_other_same = debit_other

gen debt_total_same = debt_house_same + debt_nonhouse_same
replace debt_total_same = debt_house_same if missing(debt_total_same) & !missing(debt_house_same)
replace debt_total_same = debt_nonhouse_same if missing(debt_total_same) & !missing(debt_nonhouse_same)

foreach v in hh_income_same hh_income_pc_same total_asset_same ///
         houseasset_net_same houseasset_gross_same finance_asset_same ///
         fixed_asset_same land_asset_same durables_asset_same ///
         savings_same financial_product_same company_asset_same ///
         agrimachine_asset_same debt_house_same debt_nonhouse_same debt_total_same {
    capture confirm variable `v'
    if !_rc {
        gen ihs_`v' = asinh(`v')
    }
}

xtile asset_q_same = total_asset_same if !missing(total_asset_same), nq(4)
xtile income_q_same = hh_income_pc_same if !missing(hh_income_pc_same), nq(4)

label define qlbl20 1 "Q1 lowest" 2 "Q2" 3 "Q3" 4 "Q4 highest", replace
label values asset_q_same qlbl20
label values income_q_same qlbl20

gen byte has_house = .
replace has_house = 1 if houseasset_gross_same > 0 & !missing(houseasset_gross_same)
replace has_house = 0 if houseasset_gross_same == 0

gen byte has_finance = .
replace has_finance = 1 if finance_asset_same > 0 & !missing(finance_asset_same)
replace has_finance = 0 if finance_asset_same == 0

gen byte has_business = .
replace has_business = 1 if fixed_asset_same > 0 & !missing(fixed_asset_same)
replace has_business = 0 if fixed_asset_same == 0

gen byte has_land = .
replace has_land = 1 if land_asset_same > 0 & !missing(land_asset_same)
replace has_land = 0 if land_asset_same == 0

gen byte has_debt = .
replace has_debt = 1 if debt_total_same > 0 & !missing(debt_total_same)
replace has_debt = 0 if debt_total_same == 0

gen byte asset_portfolio4 = .
replace asset_portfolio4 = 4 if has_business == 1
replace asset_portfolio4 = 2 if missing(asset_portfolio4) & has_house == 1 & has_finance == 0
replace asset_portfolio4 = 3 if missing(asset_portfolio4) & has_house == 1 & has_finance == 1
replace asset_portfolio4 = 1 if missing(asset_portfolio4) & !missing(has_house, has_finance, has_business)

label define port4lbl20 ///
    1 "Limited/non-housing assets" ///
    2 "Housing only" ///
    3 "Housing + financial assets" ///
    4 "Productive assets", replace
label values asset_portfolio4 port4lbl20

gen asset_wave_same = 2020
gen asset_wave_lag = 2018

compress
tempfile hhecon20
save `hhecon20', replace

use "$person20", clear

drop if missing(pid)
duplicates drop pid, force

gen p_edu_raw = .

capture confirm variable edu_update
if !_rc replace p_edu_raw = edu_update if missing(p_edu_raw) & edu_update >= 0

capture confirm variable kw01
if !_rc replace p_edu_raw = kw01 if missing(p_edu_raw) & kw01 >= 0

capture confirm variable w01
if !_rc replace p_edu_raw = w01 if missing(p_edu_raw) & w01 >= 0

capture confirm variable edu_last
if !_rc replace p_edu_raw = edu_last if missing(p_edu_raw) & edu_last >= 0

capture confirm variable r1_last
if !_rc replace p_edu_raw = r1_last if missing(p_edu_raw) & r1_last >= 0

gen byte p_edu_highschoolplus = .
replace p_edu_highschoolplus = 1 if inlist(p_edu_raw, 5, 6, 7, 8, 9)
replace p_edu_highschoolplus = 0 if inlist(p_edu_raw, 0, 3, 4, 10)

gen byte p_edu_collegeplus = .
replace p_edu_collegeplus = 1 if inlist(p_edu_raw, 6, 7, 8, 9)
replace p_edu_collegeplus = 0 if inlist(p_edu_raw, 0, 3, 4, 5, 10)

gen byte p_edu_bachelorplus = .
replace p_edu_bachelorplus = 1 if inlist(p_edu_raw, 7, 8, 9)
replace p_edu_bachelorplus = 0 if inlist(p_edu_raw, 0, 3, 4, 5, 6, 10)

gen p_age = .
capture confirm variable age
if !_rc replace p_age = age if age >= 0

gen byte p_party = .
capture confirm variable party
if !_rc {
    replace p_party = 1 if party == 1
    replace p_party = 0 if missing(p_party) & !missing(party)
}

gen p_occupation_code = .
foreach cand in qg411code_a_1 qg510code_a_1 qg609code_a_1 sg411code_best job2012mn_occu {
    capture confirm variable `cand'
    if !_rc {
        replace p_occupation_code = `cand' if missing(p_occupation_code) & `cand' >= 0
    }
}

gen p_industry_code = .
foreach cand in qg410code_a_1 qg509code_a_1 qg608code_a_1 sg410code {
    capture confirm variable `cand'
    if !_rc {
        replace p_industry_code = `cand' if missing(p_industry_code) & `cand' >= 0
    }
}

keep pid p_*
compress
tempfile parent_base
save `parent_base', replace

use `parent_base', clear
rename pid pid_a_f
foreach v of varlist p_* {
    local new = subinstr("`v'", "p_", "f_", 1)
    rename `v' `new'
}
tempfile father_bg
save `father_bg', replace

use `parent_base', clear
rename pid pid_a_m
foreach v of varlist p_* {
    local new = subinstr("`v'", "p_", "m_", 1)
    rename `v' `new'
}
tempfile mother_bg
save `mother_bg', replace

use "$person20", clear

drop if missing(pid)
duplicates drop pid, force

local want ///
    pid fid20 fid18 fid16 fid14 fid12 fid10 fid_base ///
    age gender gender_pre qa002 pid_a_f pid_a_m ///
    provcd20 countyid20 cid20 urban20 ///
    school qc1 qc2 qc3 qc4 qc5 qr0 ///
    qs7 qs8 qs701_b_1code qs9code qs801_b_1 ///
    qs601 qs602 qs603 qs604 qs605 qs606 ///
    qs10 qs1001 qs1003 qs11 qs1102 qs1103 ///
    kr425 kr426 kra605 ///
    qs1011 qs1012 qs1_b_2 qs102b qs2 qs201 qs202 ///
    qs3m qs4_b_2 qs501_b_2 qs502 qs503 qs504 ///
    qs601n qs602n qs603mn qs604n qs605n qs606mn qs701_b_2 qs702 ///
    pt1 pt2 pt201 pt3 pt301 pt4 pt401 pt5 pt501 pt7 pt701 pt8 ///
    pd503r pd501a pd502a pd503a pd504a pd501b pd577rn pd5total pd5total_mn pd6 wd7rn ///
    qint001 qext002 qint003 qext004 qint005 qext006 qint007 qext008 ///
    qint009 qint010 qint011 qext012 qext013 qint014 ///
    edu_last r1_last edu_update kw01 w01 wedu party child16n_2 fml_count ///
    qa001b qa301 qa701code qc201 qs801_b_2code ///
    selfrpt proxyrpt rswt_natcs20n rswt_natpn1020n rswtps_natcs20n rswtps_natpn1020n

local keepvars
foreach v of local want {
    capture confirm variable `v'
    if !_rc local keepvars `keepvars' `v'
}
keep `keepvars'

foreach v in age gender gender_pre qa002 provcd20 countyid20 cid20 urban20 ///
    school qc1 qc2 qc3 qc4 qc5 qr0 qs7 qs8 qs701_b_1code qs9code qs801_b_1 ///
    qs601 qs602 qs603 qs604 qs605 qs606 qs10 qs1001 qs1003 qs11 qs1102 qs1103 ///
    kr425 kr426 kra605 qs1011 qs1012 qs1_b_2 qs102b qs2 qs201 qs202 qs3m ///
    qs4_b_2 qs501_b_2 qs502 qs503 qs504 qs601n qs602n qs603mn qs604n qs605n qs606mn qs701_b_2 qs702 ///
    pt1 pt2 pt201 pt3 pt301 pt4 pt401 pt5 pt501 pt7 pt701 pt8 ///
    pd503r pd501a pd502a pd503a pd504a pd501b pd577rn pd5total pd5total_mn pd6 wd7rn ///
    qint001 qext002 qint003 qext004 qint005 qext006 qint007 qext008 ///
    qint009 qint010 qint011 qext012 qext013 qint014 ///
    edu_last r1_last edu_update kw01 w01 wedu party child16n_2 fml_count qa001b qa301 qa701code qc201 qs801_b_2code {
    capture confirm variable `v'
    if _rc gen `v' = .
}

neg2miss age gender gender_pre qa002 provcd20 countyid20 cid20 urban20 ///
    school qc1 qc2 qc3 qc4 qc5 qr0 qs7 qs8 qs701_b_1code qs9code qs801_b_1 ///
    qs601 qs602 qs603 qs604 qs605 qs606 qs10 qs1001 qs1003 qs11 qs1102 qs1103 ///
    kr425 kr426 kra605 qs1011 qs1012 qs1_b_2 qs102b qs2 qs201 qs202 qs3m ///
    qs4_b_2 qs501_b_2 qs502 qs503 qs504 qs601n qs602n qs603mn qs604n qs605n qs606mn qs701_b_2 qs702 ///
    pt1 pt2 pt201 pt3 pt301 pt4 pt401 pt5 pt501 pt7 pt701 pt8 ///
    pd503r pd501a pd502a pd503a pd504a pd501b pd577rn pd5total pd5total_mn pd6 wd7rn ///
    qint001 qext002 qint003 qext004 qint005 qext006 qint007 qext008 ///
    qint009 qint010 qint011 qext012 qext013 qint014 ///
    edu_last r1_last edu_update kw01 w01 wedu party child16n_2 fml_count qa001b qa301 qa701code qc201 qs801_b_2code

gen byte female = .

quietly count if gender == 0
local has0 = r(N)

quietly count if gender == 5
local has5 = r(N)

if `has5' > 0 {
    replace female = gender == 5 if !missing(gender)
}
else if `has0' > 0 {
    replace female = gender == 0 if !missing(gender)
}
else {
    display as error "Please check gender coding manually."
    tab gender, nolabel m
}

label define femalelbl 0 "Male" 1 "Female", replace
label values female femalelbl

gen byte female20 = female

gen byte ps20 = inlist(qc3, 6, 7)

gen byte fulltime20 = .
replace fulltime20 = (qc4 == 1) if ps20 == 1

gen byte ordinary_ps20 = .
replace ordinary_ps20 = inlist(qs7, 1, 2) if qc3 == 6
replace ordinary_ps20 = inlist(qs8, 1, 2, 3) if qc3 == 7

gen ps_start20 = qr0 if ps20 == 1
replace ps_start20 = . if ps_start20 < 1900

gen byte prev_ps = .
replace prev_ps = 1 if inrange(r1_last, 6, 9) | inrange(edu_last, 6, 9)
replace prev_ps = 0 if (r1_last < 6 | missing(r1_last)) ///
                  & (edu_last < 6 | missing(edu_last))
replace prev_ps = . if missing(r1_last) & missing(edu_last)

gen byte first_ps20 = ps20 == 1 ///
    & fulltime20 == 1 ///
    & ordinary_ps20 == 1 ///
    & inrange(ps_start20, 2019, 2020) ///
    & (prev_ps == 0 | missing(prev_ps))

gen wave = 2020

gen byte ps = ps20
gen byte level = .
replace level = 1 if qc3 == 6
replace level = 2 if qc3 == 7

label define levellbl 1 "Junior college" 2 "Bachelor", replace
label values level levellbl

gen byte fulltime = fulltime20
gen byte ordinary_ps = ordinary_ps20
gen ps_start = ps_start20
gen byte first_ps = first_ps20
gen byte strict_first_entrant = first_ps20
gen byte baseline_proxy = 0
gen byte sample_type = 1

replace qs701_b_1code = . if qs701_b_1code < 0
replace qs9code = . if qs9code < 0

gen disc = .
replace disc = qs701_b_1code if qc3 == 6
replace disc = qs9code        if qc3 == 7
replace disc = . if disc < 0 | disc == 99

label define field5lbl ///
    1 "STEM" ///
    2 "Medicine" ///
    3 "Business-Law-Econ-Management" ///
    4 "Humanities-Social-Education" ///
    5 "Other", replace

gen byte field5 = .
replace field5 = 1 if inlist(disc, 7, 8)
replace field5 = 2 if disc == 10
replace field5 = 3 if inlist(disc, 2, 3, 12)
replace field5 = 4 if inlist(disc, 1, 4, 5, 6, 13)
replace field5 = 5 if inlist(disc, 9, 77)
replace field5 = 5 if missing(field5) & !missing(disc)

label values field5 field5lbl

gen byte stem = .
replace stem = 1 if field5 == 1
replace stem = 0 if inlist(field5, 2, 3, 4, 5)

label define stemlbl 0 "Non-STEM" 1 "STEM", replace
label values stem stemlbl

gen age20 = age
replace age20 = qa001b if missing(age20) & !missing(qa001b)

gen byte hukou_agri20 = .
replace hukou_agri20 = 1 if qa301 == 1
replace hukou_agri20 = 0 if inlist(qa301, 3, 5, 7, 79)

gen byte han20 = .
replace han20 = 1 if qa701code == 1
replace han20 = 0 if qa701code > 1 & qa701code < .

gen urban20_ctrl = urban20
replace urban20_ctrl = . if urban20_ctrl < 0

gen edu_stage20 = qc3
gen grade_current20 = qc5

gen byte school_public20 = .
replace school_public20 = 1 if qs601 == 1
replace school_public20 = 0 if qs601 == 5

gen byte school_key20 = .
replace school_key20 = 1 if qs602 == 1
replace school_key20 = 0 if qs602 == 5

gen byte key_class20 = .
replace key_class20 = 1 if qs604 == 1
replace key_class20 = 0 if qs604 == 5

gen class_rank20 = kr425
gen grade_rank20 = kr426
gen major_rank20 = kra605

gen byte rank_class_top25_20 = .
replace rank_class_top25_20 = 1 if inlist(class_rank20, 1, 2)
replace rank_class_top25_20 = 0 if inlist(class_rank20, 3, 4, 5)

gen byte rank_grade_top25_20 = .
replace rank_grade_top25_20 = 1 if inlist(grade_rank20, 1, 2)
replace rank_grade_top25_20 = 0 if inlist(grade_rank20, 3, 4, 5)

gen expected_edu20 = qc201
gen desired_occ_code20 = qs801_b_2code

gen study_hours_weekday20 = qs1011
gen study_hours_weekend20 = qs1012

gen byte student_cadre20 = .
replace student_cadre20 = 1 if qs1_b_2 == 1
replace student_cadre20 = 0 if qs1_b_2 == 5

gen byte club_participation20 = .
replace club_participation20 = 1 if qs2 == 1
replace club_participation20 = 0 if qs2 == 5

gen byte club_leader20 = .
replace club_leader20 = 1 if qs202 == 1
replace club_leader20 = 0 if qs202 == 5

gen talent_belief20 = qs4_b_2
gen self_academic20 = qs501_b_2
gen study_pressure20 = qs502
gen self_excellence20 = qs503
gen student_leader_fit20 = qs504

gen study_effort20 = qs601n
gen concentration20 = qs602n
gen homework_check20 = qs603mn
gen rule_following20 = qs604n
gen neatness20 = qs605n
gen homework_before_play20 = qs606mn

gen school_satisfaction20 = qs701_b_2
gen teacher_satisfaction20 = qs702

gen byte tutoring_any20 = .
replace tutoring_any20 = 1 if pt1 == 1 | pt2 == 1 | pt3 == 1 | pt4 == 1 | pt5 == 1 | pt7 == 1 | pt8 == 1
replace tutoring_any20 = 0 if missing(tutoring_any20) & ///
    inlist(pt1,5,.) & inlist(pt2,5,.) & inlist(pt3,5,.) & inlist(pt4,5,.) & ///
    inlist(pt5,5,.) & inlist(pt7,5,.) & inlist(pt8,5,.)

gen edu_exp_school20 = pd501b
gen edu_exp_tutoring20 = pd503r
gen edu_exp_total20 = pd5total_mn

gen ihs_edu_exp_total20 = asinh(edu_exp_total20)
gen ihs_edu_exp_tutoring20 = asinh(edu_exp_tutoring20)

egen internalizing20 = rowmean(qint001 qint003 qint005 qint007 qint009 qint010 qint011 qint014)
egen externalizing20 = rowmean(qext002 qext004 qext006 qext008 qext012 qext013)

merge m:1 pid_a_f using `father_bg', gen(_merge_father20) keep(master match)
merge m:1 pid_a_m using `mother_bg', gen(_merge_mother20) keep(master match)

egen parent_edu_max20 = rowmax(f_edu_raw m_edu_raw)

gen byte parent_college_any20 = .
replace parent_college_any20 = 1 if f_edu_collegeplus == 1 | m_edu_collegeplus == 1
replace parent_college_any20 = 0 if f_edu_collegeplus == 0 & m_edu_collegeplus == 0

gen byte parent_bachelor_any20 = .
replace parent_bachelor_any20 = 1 if f_edu_bachelorplus == 1 | m_edu_bachelorplus == 1
replace parent_bachelor_any20 = 0 if f_edu_bachelorplus == 0 & m_edu_bachelorplus == 0

gen byte parent_highschool_any20 = .
replace parent_highschool_any20 = 1 if f_edu_highschoolplus == 1 | m_edu_highschoolplus == 1
replace parent_highschool_any20 = 0 if f_edu_highschoolplus == 0 & m_edu_highschoolplus == 0

gen byte parent_party_any20 = .
replace parent_party_any20 = 1 if f_party == 1 | m_party == 1
replace parent_party_any20 = 0 if f_party == 0 & m_party == 0

egen parent_age_mean20 = rowmean(f_age m_age)

gen byte father_linked20 = _merge_father20 == 3
gen byte mother_linked20 = _merge_mother20 == 3
gen byte both_parents_linked20 = father_linked20 == 1 & mother_linked20 == 1

merge m:1 fid20 using `hhecon20', gen(_merge_hhecon20) keep(master match)

gen byte valid_field = !missing(field5)
gen byte has_asset_same = !missing(total_asset_same)
gen byte has_income_same = !missing(hh_income_same)

gen byte analytic_2020 = first_ps20 == 1 & valid_field == 1 & has_asset_same == 1

gen fid_current = fid20
gen fid_pre = fid18

gen provcd_h = provcd20
gen countyid_h = countyid20
gen urban_h = urban20

gen byte has_basic_controls20 = !missing(age20, urban20_ctrl)
gen byte has_parent_edu20 = !missing(parent_college_any20)
gen byte has_academic_controls20 = !missing(rank_class_top25_20) | !missing(rank_grade_top25_20) | !missing(major_rank20)
gen byte has_mechanism_controls20 = !missing(study_effort20) | !missing(study_pressure20) | !missing(tutoring_any20) | !missing(edu_exp_total20)

label var female "Female indicator"
label var ps20 "Currently enrolled in junior college or bachelor program"
label var fulltime20 "Full-time student"
label var ordinary_ps20 "Ordinary junior college or bachelor program"
label var ps_start20 "Year started current postsecondary stage"
label var prev_ps "Already in postsecondary education in previous wave"
label var first_ps20 "First ordinary full-time postsecondary entrant in 2020"
label var disc "Unified discipline code for junior college and bachelor"
label var field5 "Field of study, junior college + bachelor"
label var stem "STEM field"

label var wave "Survey wave"
label var ps "Currently enrolled in junior college or bachelor"
label var level "Postsecondary level"
label var fulltime "Full-time student"
label var ordinary_ps "Ordinary junior college or bachelor program"
label var ps_start "Start year of current postsecondary stage"
label var first_ps "First ordinary full-time postsecondary entrant"
label var strict_first_entrant "Strict first entrant indicator"
label var baseline_proxy "Baseline proxy indicator"
label var sample_type "Sample type"

label var age20 "Age in 2020"
label var female20 "Female, 2020 person file"
label var hukou_agri20 "Agricultural hukou, 2020"
label var han20 "Han ethnicity, 2020"
label var urban20_ctrl "Urban/rural indicator, 2020"

label var parent_college_any20 "At least one parent junior-college educated or above"
label var parent_bachelor_any20 "At least one parent bachelor educated or above"
label var parent_highschool_any20 "At least one parent high-school educated or above"
label var parent_party_any20 "At least one parent CCP member"
label var parent_age_mean20 "Mean parental age"
label var father_linked20 "Father linked in 2020 person file"
label var mother_linked20 "Mother linked in 2020 person file"
label var both_parents_linked20 "Both parents linked in 2020 person file"

label var hh_income_same "Household income, 2020"
label var hh_income_pc_same "Per-capita household income, 2020"
label var hh_income_per_p_same "Per-capita household income percentile/rank, 2020"
label var total_asset_same "Household net assets, 2020"
label var houseasset_net_same "Net housing asset, 2020"
label var houseasset_gross_same "Gross housing asset, 2020"
label var finance_asset_same "Financial asset, 2020"
label var fixed_asset_same "Productive fixed asset, 2020"
label var land_asset_same "Land asset, 2020"
label var durables_asset_same "Durable asset, 2020"
label var savings_same "Savings, 2020"
label var financial_product_same "Financial products, 2020"
label var company_asset_same "Company/business asset, 2020"
label var agrimachine_asset_same "Agricultural machinery asset, 2020"
label var debt_house_same "Housing debt, 2020"
label var debt_nonhouse_same "Non-housing debt, 2020"
label var debt_total_same "Total household debt, 2020"
label var asset_q_same "Within-2020 household net asset quartile"
label var income_q_same "Within-2020 per-capita household income quartile"
label var has_house "Has housing asset, 2020"
label var has_finance "Has financial asset, 2020"
label var has_business "Has productive asset, 2020"
label var has_land "Has land asset, 2020"
label var has_debt "Has household debt, 2020"
label var asset_portfolio4 "Household asset portfolio, 2020"

label var analytic_2020 "2020 analytic sample: first entrant with valid field and assets"

foreach v of varlist _all {
    local lab : variable label `v'
    if "`lab'" == "" {
        label var `v' "`v'"
    }
}

preserve
    keep if inrange(age20,16,30) & (prev_ps==0 | missing(prev_ps)) & !missing(female,asset_portfolio4)
    save "$DATA/clean/cfps2020_selection_risk_01_10_2026.dta", replace
restore
keep if first_ps20 == 1

compress
save "$data/cfps2020_clean_all_01_10_2026.dta", replace

display "=================================================="
display "DONE. Saved:"
display "$data/cfps2020_clean_all_01_10_2026.dta"
display "=================================================="

display "Expected check: saved file should contain only 2020 strict first entrants, around 229."
count

display "STEM distribution in saved entrant cohort:"
tab stem, m

display "Level by female in saved entrant cohort:"
tab qc3 female, m

display "Female by field in saved entrant cohort:"
tab female field5, m

display "Field by level in saved entrant cohort:"
tab qc3 field5, m

display "Female STEM cell:"
count if female == 1 & field5 == 1

display "Male STEM cell:"
count if female == 0 & field5 == 1

display "Missing field in saved entrant cohort:"
count if missing(field5)

display "Analytic sample:"
tab analytic_2020, m

display "Asset portfolio among analytic sample:"
tab asset_portfolio4 if analytic_2020 == 1, m

display "Parent education availability among analytic sample:"
tab parent_college_any20 if analytic_2020 == 1, m

display "Check empty labels:"
foreach v of varlist _all {
    local lab : variable label `v'
    if "`lab'" == "" {
        display as error "`v' has no label"
    }
}

display "=================================================="
display "2020 cleaning complete."
display "=================================================="

exit
}

if "`module'" == "wave2022" {
/* Wave2022. */
version 18

clear
set more off

global project "$ROOT"

global data "$HSSC_DATA/clean"
global cfps "$RAW"
global raw22 "$cfps/2022"

global person22  "$raw22/cfps2022person_202410.dta"
global famecon22 "$raw22/cfps2022famecon_202410.dta"

capture mkdir "$data"

capture confirm file "$person22"
if _rc {
    display as error "Cannot find person file:"
    display as error "$person22"
    exit 601
}

capture confirm file "$famecon22"
if _rc {
    display as error "Cannot find family economic file:"
    display as error "$famecon22"
    exit 601
}

capture program drop neg2miss
program define neg2miss
    syntax varlist
    foreach v of varlist `varlist' {
        capture confirm numeric variable `v'
        if !_rc {
            quietly replace `v' = . if `v' < 0
        }
    }
end

use "$famecon22", clear

drop if missing(fid22)
duplicates drop fid22, force

local famvars ///
    fid22 fid20 fid18 fid16 fid14 fid12 fid10 ///
    provcd22 countyid22 cid22 urban22 ///
    fml_count familysize22 ///
    finc finc_est finc_max finc_min ///
    fincome1 fincome1_per fincome1_per_p ///
    fexp fexp_est fexp_max fexp_min ///
    food dress house daily med trco eec other pce eptran epwelf mortage expense ///
    agrimachine company durables_asset land_asset savings financial_product ///
    debit_other nonhousing_debts house_debts ///
    resivalue otherhousevalue houseasset_gross houseasset_net ///
    finance_asset fixed_asset total_asset ///
    fwage_1 foperate_1 fproperty_1 ftransfer_1 felse_1 ///
    fswt_natcs22n subsample subpopulation psu

local keepfam
foreach v of local famvars {
    capture confirm variable `v'
    if !_rc local keepfam `keepfam' `v'
}

keep `keepfam'

gen hh_income_same = .
capture confirm variable fincome1
if !_rc replace hh_income_same = fincome1

capture confirm variable finc
if !_rc replace hh_income_same = finc if missing(hh_income_same)

gen hh_income_pc_same = .
capture confirm variable fincome1_per
if !_rc replace hh_income_pc_same = fincome1_per

gen hh_income_per_p_same = .
capture confirm variable fincome1_per_p
if !_rc replace hh_income_per_p_same = fincome1_per_p

gen total_asset_same = .
capture confirm variable total_asset
if !_rc replace total_asset_same = total_asset

gen houseasset_net_same = .
capture confirm variable houseasset_net
if !_rc replace houseasset_net_same = houseasset_net

gen houseasset_gross_same = .
capture confirm variable houseasset_gross
if !_rc replace houseasset_gross_same = houseasset_gross

gen finance_asset_same = .
capture confirm variable finance_asset
if !_rc replace finance_asset_same = finance_asset

gen fixed_asset_same = .
capture confirm variable fixed_asset
if !_rc replace fixed_asset_same = fixed_asset

gen land_asset_same = .
capture confirm variable land_asset
if !_rc replace land_asset_same = land_asset

gen durables_asset_same = .
capture confirm variable durables_asset
if !_rc replace durables_asset_same = durables_asset

gen savings_same = .
capture confirm variable savings
if !_rc replace savings_same = savings

gen financial_product_same = .
capture confirm variable financial_product
if !_rc replace financial_product_same = financial_product

gen company_asset_same = .
capture confirm variable company
if !_rc replace company_asset_same = company

gen agrimachine_asset_same = .
capture confirm variable agrimachine
if !_rc replace agrimachine_asset_same = agrimachine

gen resivalue_same = .
capture confirm variable resivalue
if !_rc replace resivalue_same = resivalue

gen otherhousevalue_same = .
capture confirm variable otherhousevalue
if !_rc replace otherhousevalue_same = otherhousevalue

gen debt_house_same = .
capture confirm variable house_debts
if !_rc replace debt_house_same = house_debts

gen debt_nonhouse_same = .
capture confirm variable nonhousing_debts
if !_rc replace debt_nonhouse_same = nonhousing_debts

gen debt_other_same = .
capture confirm variable debit_other
if !_rc replace debt_other_same = debit_other

gen debt_total_same = debt_house_same + debt_nonhouse_same
replace debt_total_same = debt_house_same if missing(debt_total_same) & !missing(debt_house_same)
replace debt_total_same = debt_nonhouse_same if missing(debt_total_same) & !missing(debt_nonhouse_same)

foreach v in hh_income_same hh_income_pc_same total_asset_same ///
         houseasset_net_same houseasset_gross_same finance_asset_same ///
         fixed_asset_same land_asset_same durables_asset_same ///
         savings_same financial_product_same company_asset_same ///
         agrimachine_asset_same debt_house_same debt_nonhouse_same debt_total_same {
    capture confirm variable `v'
    if !_rc {
        gen ihs_`v' = asinh(`v')
    }
}

xtile asset_q_same = total_asset_same if !missing(total_asset_same), nq(4)
xtile income_q_same = hh_income_pc_same if !missing(hh_income_pc_same), nq(4)

label define qlbl22 1 "Q1 lowest" 2 "Q2" 3 "Q3" 4 "Q4 highest", replace
label values asset_q_same qlbl22
label values income_q_same qlbl22

gen byte has_house = .
replace has_house = 1 if houseasset_gross_same > 0 & !missing(houseasset_gross_same)
replace has_house = 0 if houseasset_gross_same == 0

gen byte has_finance = .
replace has_finance = 1 if finance_asset_same > 0 & !missing(finance_asset_same)
replace has_finance = 0 if finance_asset_same == 0

gen byte has_business = .
replace has_business = 1 if fixed_asset_same > 0 & !missing(fixed_asset_same)
replace has_business = 0 if fixed_asset_same == 0

gen byte has_land = .
replace has_land = 1 if land_asset_same > 0 & !missing(land_asset_same)
replace has_land = 0 if land_asset_same == 0

gen byte has_debt = .
replace has_debt = 1 if debt_total_same > 0 & !missing(debt_total_same)
replace has_debt = 0 if debt_total_same == 0

gen byte asset_portfolio4 = .
replace asset_portfolio4 = 4 if has_business == 1
replace asset_portfolio4 = 2 if missing(asset_portfolio4) & has_house == 1 & has_finance == 0
replace asset_portfolio4 = 3 if missing(asset_portfolio4) & has_house == 1 & has_finance == 1
replace asset_portfolio4 = 1 if missing(asset_portfolio4) & !missing(has_house, has_finance, has_business)

label define port4lbl22 ///
    1 "Limited/non-housing assets" ///
    2 "Housing only" ///
    3 "Housing + financial assets" ///
    4 "Productive assets", replace
label values asset_portfolio4 port4lbl22

gen asset_wave_same = 2022
gen asset_wave_lag = 2020

compress
tempfile hhecon22
save `hhecon22', replace

use "$person22", clear

drop if missing(pid)
duplicates drop pid, force

gen p_edu_raw = .

capture confirm variable edu_update
if !_rc replace p_edu_raw = edu_update if missing(p_edu_raw) & edu_update >= 0

capture confirm variable kw01
if !_rc replace p_edu_raw = kw01 if missing(p_edu_raw) & kw01 >= 0

capture confirm variable edu_last
if !_rc replace p_edu_raw = edu_last if missing(p_edu_raw) & edu_last >= 0

gen byte p_edu_highschoolplus = .
replace p_edu_highschoolplus = 1 if inlist(p_edu_raw, 5, 6, 7, 8, 9)
replace p_edu_highschoolplus = 0 if inlist(p_edu_raw, 0, 3, 4, 10)

gen byte p_edu_collegeplus = .
replace p_edu_collegeplus = 1 if inlist(p_edu_raw, 6, 7, 8, 9)
replace p_edu_collegeplus = 0 if inlist(p_edu_raw, 0, 3, 4, 5, 10)

gen byte p_edu_bachelorplus = .
replace p_edu_bachelorplus = 1 if inlist(p_edu_raw, 7, 8, 9)
replace p_edu_bachelorplus = 0 if inlist(p_edu_raw, 0, 3, 4, 5, 6, 10)

gen p_age = .
capture confirm variable age
if !_rc replace p_age = age if age >= 0

gen byte p_party = .
capture confirm variable party
if !_rc {
    replace p_party = 1 if party == 1
    replace p_party = 0 if missing(p_party) & !missing(party)
}

gen p_occupation_code = .
foreach cand in qg411code_a_1 qg510code_a_1 qg609code_a_1 sg411code_best job2012mn_occu {
    capture confirm variable `cand'
    if !_rc {
        replace p_occupation_code = `cand' if missing(p_occupation_code) & `cand' >= 0
    }
}

gen p_industry_code = .
foreach cand in qg410code_a_1 qg509code_a_1 qg608code_a_1 sg410code {
    capture confirm variable `cand'
    if !_rc {
        replace p_industry_code = `cand' if missing(p_industry_code) & `cand' >= 0
    }
}

keep pid p_*
compress
tempfile parent_base
save `parent_base', replace

use `parent_base', clear
rename pid pid_a_f
foreach v of varlist p_* {
    local new = subinstr("`v'", "p_", "f_", 1)
    rename `v' `new'
}
tempfile father_bg
save `father_bg', replace

use `parent_base', clear
rename pid pid_a_m
foreach v of varlist p_* {
    local new = subinstr("`v'", "p_", "m_", 1)
    rename `v' `new'
}
tempfile mother_bg
save `mother_bg', replace

use "$person22", clear

drop if missing(pid)
duplicates drop pid, force

local want ///
    pid fid22 fid20 fid18 fid16 fid14 fid12 fid10 ///
    age gender gender_pre qa002 pid_a_f pid_a_m ///
    provcd22 countyid22 cid22 urban22 ///
    school qc1 qc2 qc3 qc4 qc5 qr0 ///
    qs7 qs8 qs701ncode qs9ncode qs801_b_1 ///
    qs601 qs602 qs603 qs604 qs605 qs606 ///
    qs10 qs1001 qs1003 qs11 qs1102 qs1103 ///
    kr425 kr426 kra605 ///
    qs1011 qs1012 qs1_b_2 qs102b qs2 qs201 qs202 ///
    qs4_b_2 qs501_b_2 qs502 qs503 qs504 ///
    qs601n qs602n qs603mn qs604n qs605n qs606mn qs701 qs702 ///
    pt1 pt2 pt201 pt3 pt301 pt4 pt401 pt5 pt501 pt7 pt701 pt8 ///
    pd503r pd501a pd502a pd503a pd504a pd501b pd577rn pd5total pd5total_mn pd6 wd7rn ///
    qint001 qext002 qint003 qext004 qint005 qext006 qint007 qext008 ///
    qint009 qint010 qint011 qext012 qext013 qint014 ///
    edu_last r1_last edu_update kw01 wedu party child16n fml_count ///
    qa001b qa301 qa701code qc201 qs801_b_2code

local keepvars
foreach v of local want {
    capture confirm variable `v'
    if !_rc local keepvars `keepvars' `v'
}
keep `keepvars'

foreach v in age gender gender_pre qa002 provcd22 countyid22 cid22 urban22 ///
    school qc1 qc2 qc3 qc4 qc5 qr0 qs7 qs8 qs701ncode qs9ncode qs801_b_1 ///
    qs601 qs602 qs603 qs604 qs605 qs606 qs10 qs1001 qs1003 qs11 qs1102 qs1103 ///
    kr425 kr426 kra605 qs1011 qs1012 qs1_b_2 qs102b qs2 qs201 qs202 ///
    qs4_b_2 qs501_b_2 qs502 qs503 qs504 qs601n qs602n qs603mn qs604n qs605n qs606mn qs701 qs702 ///
    pt1 pt2 pt201 pt3 pt301 pt4 pt401 pt5 pt501 pt7 pt701 pt8 ///
    pd503r pd501a pd502a pd503a pd504a pd501b pd577rn pd5total pd5total_mn pd6 wd7rn ///
    qint001 qext002 qint003 qext004 qint005 qext006 qint007 qext008 ///
    qint009 qint010 qint011 qext012 qext013 qint014 ///
    edu_last r1_last edu_update kw01 wedu party child16n fml_count qa001b qa301 qa701code qc201 qs801_b_2code {
    capture confirm variable `v'
    if _rc gen `v' = .
}

neg2miss age gender gender_pre qa002 provcd22 countyid22 cid22 urban22 ///
    school qc1 qc2 qc3 qc4 qc5 qr0 qs7 qs8 qs701ncode qs9ncode qs801_b_1 ///
    qs601 qs602 qs603 qs604 qs605 qs606 qs10 qs1001 qs1003 qs11 qs1102 qs1103 ///
    kr425 kr426 kra605 qs1011 qs1012 qs1_b_2 qs102b qs2 qs201 qs202 ///
    qs4_b_2 qs501_b_2 qs502 qs503 qs504 qs601n qs602n qs603mn qs604n qs605n qs606mn qs701 qs702 ///
    pt1 pt2 pt201 pt3 pt301 pt4 pt401 pt5 pt501 pt7 pt701 pt8 ///
    pd503r pd501a pd502a pd503a pd504a pd501b pd577rn pd5total pd5total_mn pd6 wd7rn ///
    qint001 qext002 qint003 qext004 qint005 qext006 qint007 qext008 ///
    qint009 qint010 qint011 qext012 qext013 qint014 ///
    edu_last r1_last edu_update kw01 wedu party child16n fml_count qa001b qa301 qa701code qc201 qs801_b_2code

gen byte female = .

quietly count if gender == 0
local has0 = r(N)

quietly count if gender == 5
local has5 = r(N)

if `has5' > 0 {
    replace female = gender == 5 if !missing(gender)
}
else if `has0' > 0 {
    replace female = gender == 0 if !missing(gender)
}
else {
    display as error "Please check gender coding manually."
    tab gender, nolabel m
}

label define femalelbl 0 "Male" 1 "Female", replace
label values female femalelbl

gen byte female22 = female

gen byte ps22 = inlist(qc3, 6, 7)

gen byte fulltime22 = .
replace fulltime22 = (qc4 == 1) if ps22 == 1

gen byte ordinary_ps22 = .
replace ordinary_ps22 = inlist(qs7, 1, 2) if qc3 == 6
replace ordinary_ps22 = inlist(qs8, 1, 2, 3) if qc3 == 7

gen ps_start22 = qr0 if ps22 == 1
replace ps_start22 = . if ps_start22 < 1900

gen byte prev_ps = .
replace prev_ps = 1 if inrange(r1_last, 6, 9) | inrange(edu_last, 6, 9)
replace prev_ps = 0 if (r1_last < 6 | missing(r1_last)) ///
                  & (edu_last < 6 | missing(edu_last))
replace prev_ps = . if missing(r1_last) & missing(edu_last)

gen byte first_ps22 = ps22 == 1 ///
    & fulltime22 == 1 ///
    & ordinary_ps22 == 1 ///
    & inrange(ps_start22, 2021, 2022) ///
    & (prev_ps == 0 | missing(prev_ps))

gen wave = 2022

gen byte ps = ps22
gen byte level = .
replace level = 1 if qc3 == 6
replace level = 2 if qc3 == 7

label define levellbl 1 "Junior college" 2 "Bachelor", replace
label values level levellbl

gen byte fulltime = fulltime22
gen byte ordinary_ps = ordinary_ps22
gen ps_start = ps_start22
gen byte first_ps = first_ps22
gen byte strict_first_entrant = first_ps22
gen byte baseline_proxy = 0
gen byte sample_type = 1

replace qs701ncode = . if qs701ncode < 0
replace qs9ncode = . if qs9ncode < 0

gen disc = .
replace disc = qs701ncode if qc3 == 6
replace disc = qs9ncode if qc3 == 7

label define field5lbl ///
    1 "STEM" ///
    2 "Medicine" ///
    3 "Business-Law-Econ-Management" ///
    4 "Humanities-Social-Education" ///
    5 "Other", replace

gen byte field5 = .
replace field5 = 1 if inlist(disc, 7, 8)
replace field5 = 2 if disc == 10
replace field5 = 3 if inlist(disc, 2, 3, 12)
replace field5 = 4 if inlist(disc, 1, 4, 5, 6, 13)
replace field5 = 5 if missing(field5) & !missing(disc)

label values field5 field5lbl

gen byte stem = .
replace stem = 1 if field5 == 1
replace stem = 0 if inlist(field5, 2, 3, 4, 5)

label define stemlbl 0 "Non-STEM" 1 "STEM", replace
label values stem stemlbl

gen age22 = age
replace age22 = qa001b if missing(age22) & !missing(qa001b)

gen byte hukou_agri22 = .
replace hukou_agri22 = 1 if qa301 == 1
replace hukou_agri22 = 0 if inlist(qa301, 3, 5, 7, 79)

gen byte han22 = .
replace han22 = 1 if qa701code == 1
replace han22 = 0 if qa701code > 1 & qa701code < .

gen urban22_ctrl = urban22
replace urban22_ctrl = . if urban22_ctrl < 0

gen edu_stage22 = qc3
gen grade_current22 = qc5

gen byte school_public22 = .
replace school_public22 = 1 if qs601 == 1
replace school_public22 = 0 if qs601 == 5

gen byte school_key22 = .
replace school_key22 = 1 if qs602 == 1
replace school_key22 = 0 if qs602 == 5

gen byte key_class22 = .
replace key_class22 = 1 if qs604 == 1
replace key_class22 = 0 if qs604 == 5

gen class_rank22 = kr425
gen grade_rank22 = kr426
gen major_rank22 = kra605

gen byte rank_class_top25_22 = .
replace rank_class_top25_22 = 1 if inlist(class_rank22, 1, 2)
replace rank_class_top25_22 = 0 if inlist(class_rank22, 3, 4, 5)

gen byte rank_grade_top25_22 = .
replace rank_grade_top25_22 = 1 if inlist(grade_rank22, 1, 2)
replace rank_grade_top25_22 = 0 if inlist(grade_rank22, 3, 4, 5)

gen expected_edu22 = qc201
gen desired_occ_code22 = qs801_b_2code

gen study_hours_weekday22 = qs1011
gen study_hours_weekend22 = qs1012

gen byte student_cadre22 = .
replace student_cadre22 = 1 if qs1_b_2 == 1
replace student_cadre22 = 0 if qs1_b_2 == 5

gen byte club_participation22 = .
replace club_participation22 = 1 if qs2 == 1
replace club_participation22 = 0 if qs2 == 5

gen byte club_leader22 = .
replace club_leader22 = 1 if qs202 == 1
replace club_leader22 = 0 if qs202 == 5

gen talent_belief22 = qs4_b_2
gen self_academic22 = qs501_b_2
gen study_pressure22 = qs502
gen self_excellence22 = qs503
gen student_leader_fit22 = qs504

gen study_effort22 = qs601n
gen concentration22 = qs602n
gen homework_check22 = qs603mn
gen rule_following22 = qs604n
gen neatness22 = qs605n
gen homework_before_play22 = qs606mn

gen school_satisfaction22 = qs701
gen teacher_satisfaction22 = qs702

gen byte tutoring_any22 = .
replace tutoring_any22 = 1 if pt1 == 1 | pt2 == 1 | pt3 == 1 | pt4 == 1 | pt5 == 1 | pt7 == 1 | pt8 == 1
replace tutoring_any22 = 0 if missing(tutoring_any22) & ///
    inlist(pt1,5,.) & inlist(pt2,5,.) & inlist(pt3,5,.) & inlist(pt4,5,.) & ///
    inlist(pt5,5,.) & inlist(pt7,5,.) & inlist(pt8,5,.)

gen edu_exp_school22 = pd501b
gen edu_exp_tutoring22 = pd503r
gen edu_exp_total22 = pd5total_mn

gen ihs_edu_exp_total22 = asinh(edu_exp_total22)
gen ihs_edu_exp_tutoring22 = asinh(edu_exp_tutoring22)

egen internalizing22 = rowmean(qint001 qint003 qint005 qint007 qint009 qint010 qint011 qint014)
egen externalizing22 = rowmean(qext002 qext004 qext006 qext008 qext012 qext013)

merge m:1 pid_a_f using `father_bg', gen(_merge_father22) keep(master match)
merge m:1 pid_a_m using `mother_bg', gen(_merge_mother22) keep(master match)

egen parent_edu_max22 = rowmax(f_edu_raw m_edu_raw)

gen byte parent_college_any22 = .
replace parent_college_any22 = 1 if f_edu_collegeplus == 1 | m_edu_collegeplus == 1
replace parent_college_any22 = 0 if f_edu_collegeplus == 0 & m_edu_collegeplus == 0

gen byte parent_bachelor_any22 = .
replace parent_bachelor_any22 = 1 if f_edu_bachelorplus == 1 | m_edu_bachelorplus == 1
replace parent_bachelor_any22 = 0 if f_edu_bachelorplus == 0 & m_edu_bachelorplus == 0

gen byte parent_highschool_any22 = .
replace parent_highschool_any22 = 1 if f_edu_highschoolplus == 1 | m_edu_highschoolplus == 1
replace parent_highschool_any22 = 0 if f_edu_highschoolplus == 0 & m_edu_highschoolplus == 0

gen byte parent_party_any22 = .
replace parent_party_any22 = 1 if f_party == 1 | m_party == 1
replace parent_party_any22 = 0 if f_party == 0 & m_party == 0

egen parent_age_mean22 = rowmean(f_age m_age)

gen byte father_linked22 = _merge_father22 == 3
gen byte mother_linked22 = _merge_mother22 == 3
gen byte both_parents_linked22 = father_linked22 == 1 & mother_linked22 == 1

merge m:1 fid22 using `hhecon22', gen(_merge_hhecon22) keep(master match)

gen byte valid_field = !missing(field5)
gen byte has_asset_same = !missing(total_asset_same)
gen byte has_income_same = !missing(hh_income_same)

gen byte analytic_2022 = first_ps22 == 1 & valid_field == 1 & has_asset_same == 1

gen fid_current = fid22
gen fid_pre = fid20

gen provcd_h = provcd22
gen countyid_h = countyid22
gen urban_h = urban22

gen byte has_basic_controls22 = !missing(age22, urban22_ctrl)
gen byte has_parent_edu22 = !missing(parent_college_any22)
gen byte has_academic_controls22 = !missing(rank_class_top25_22) | !missing(rank_grade_top25_22) | !missing(major_rank22)
gen byte has_mechanism_controls22 = !missing(study_effort22) | !missing(study_pressure22) | !missing(tutoring_any22) | !missing(edu_exp_total22)

label var female "Female indicator"
label var ps22 "Currently enrolled in junior college or bachelor program"
label var fulltime22 "Full-time student"
label var ordinary_ps22 "Ordinary junior college or bachelor program"
label var ps_start22 "Year started current postsecondary stage"
label var prev_ps "Already in postsecondary education in previous wave"
label var first_ps22 "First ordinary full-time postsecondary entrant in 2022"
label var disc "Unified discipline code for junior college and bachelor"
label var field5 "Field of study, junior college + bachelor"
label var stem "STEM field"

label var wave "Survey wave"
label var ps "Currently enrolled in junior college or bachelor"
label var level "Postsecondary level"
label var fulltime "Full-time student"
label var ordinary_ps "Ordinary junior college or bachelor program"
label var ps_start "Start year of current postsecondary stage"
label var first_ps "First ordinary full-time postsecondary entrant"
label var strict_first_entrant "Strict first entrant indicator"
label var baseline_proxy "Baseline proxy indicator"
label var sample_type "Sample type"

label var age22 "Age in 2022"
label var female22 "Female, 2022 person file"
label var hukou_agri22 "Agricultural hukou, 2022"
label var han22 "Han ethnicity, 2022"
label var urban22_ctrl "Urban/rural indicator, 2022"

label var parent_college_any22 "At least one parent junior-college educated or above"
label var parent_bachelor_any22 "At least one parent bachelor educated or above"
label var parent_highschool_any22 "At least one parent high-school educated or above"
label var parent_party_any22 "At least one parent CCP member"
label var parent_age_mean22 "Mean parental age"
label var father_linked22 "Father linked in 2022 person file"
label var mother_linked22 "Mother linked in 2022 person file"
label var both_parents_linked22 "Both parents linked in 2022 person file"

label var hh_income_same "Household income, 2022"
label var hh_income_pc_same "Per-capita household income, 2022"
label var total_asset_same "Household net assets, 2022"
label var asset_q_same "Within-2022 household net asset quartile"
label var income_q_same "Within-2022 per-capita household income quartile"
label var asset_portfolio4 "Household asset portfolio, 2022"

label var analytic_2022 "2022 analytic sample: first entrant with valid field and assets"

foreach v of varlist _all {
    local lab : variable label `v'
    if "`lab'" == "" {
        label var `v' "`v'"
    }
}

preserve
    keep if inrange(age22,16,30) & (prev_ps==0 | missing(prev_ps)) & !missing(female,asset_portfolio4)
    save "$DATA/clean/cfps2022_selection_risk_01_10_2026.dta", replace
restore
keep if first_ps22 == 1

compress
save "$data/cfps2022_clean_all_01_10_2026.dta", replace

display "=================================================="
display "DONE. Saved:"
display "$data/cfps2022_clean_all_01_10_2026.dta"
display "=================================================="

display "Expected check: saved file should contain only 2022 strict first entrants, around 261."
count

display "STEM distribution in saved entrant cohort:"
tab stem, m

display "Level by female in saved entrant cohort:"
tab qc3 female, m

display "Female by field in saved entrant cohort:"
tab female field5, m

display "Field by level in saved entrant cohort:"
tab qc3 field5, m

display "Female STEM cell:"
count if female == 1 & field5 == 1

display "Male STEM cell:"
count if female == 0 & field5 == 1

display "Missing field in saved entrant cohort:"
count if missing(field5)

display "Analytic sample:"
tab analytic_2022, m

display "Asset portfolio among analytic sample:"
tab asset_portfolio4 if analytic_2022 == 1, m

display "Parent education availability among analytic sample:"
tab parent_college_any22 if analytic_2022 == 1, m

display "Check empty labels:"
foreach v of varlist _all {
    local lab : variable label `v'
    if "`lab'" == "" {
        display as error "`v' has no label"
    }
}

display "=================================================="
display "2022 cleaning complete."
display "=================================================="

exit
}

if "`module'" == "append" {
/* Append. */
version 18

clear
set more off

global project "$ROOT"

global data "$HSSC_DATA/clean"
global out  "$HSSC_DATA/clean"

local d2012 "$data/cfps2012_clean_all_01_10_2026.dta"
local d2014 "$data/cfps2014_clean_all_01_10_2026.dta"
local d2018 "$data/cfps2018_clean_all_01_10_2026.dta"
local d2020 "$data/cfps2020_clean_all_01_10_2026.dta"
local d2022 "$data/cfps2022_clean_all_01_10_2026.dta"

foreach f in "`d2012'" "`d2014'" "`d2018'" "`d2020'" "`d2022'" {
    capture confirm file "`f'"
    if _rc {
        display as error "Cannot find file:"
        display as error "`f'"
        exit 601
    }
}

use "`d2012'", clear
append using "`d2014'"
append using "`d2018'"
append using "`d2020'"
append using "`d2022'"

compress
save "$out/cfps_entrant_appended_raw_2010_2022_01_10_2026.dta", replace

local needed_vars ///
    fid_current fid_pre ///
    fid10 fid12 fid14 fid18 fid20 fid22 ///
    age10 age12 age14 age18 age20 age22 ///
    hukou_agri10 hukou_agri12 hukou_agri14 hukou_agri18 hukou_agri20 hukou_agri22 ///
    han10 han12 han14 han18 han20 han22 ///
    urban10_ctrl urban12_ctrl urban14_ctrl urban18_ctrl urban20_ctrl urban22_ctrl ///
    parent_college_any10 parent_college_any12 parent_college_any14 parent_college_any18 parent_college_any20 parent_college_any22 ///
    parent_bachelor_any10 parent_bachelor_any12 parent_bachelor_any14 parent_bachelor_any18 parent_bachelor_any20 parent_bachelor_any22 ///
    parent_highschool_any10 parent_highschool_any12 parent_highschool_any14 parent_highschool_any18 parent_highschool_any20 parent_highschool_any22 ///
    parent_party_any10 parent_party_any12 parent_party_any14 parent_party_any18 parent_party_any20 parent_party_any22 ///
    parent_age_mean10 parent_age_mean12 parent_age_mean14 parent_age_mean18 parent_age_mean20 parent_age_mean22 ///
    father_linked10 father_linked12 father_linked14 father_linked18 father_linked20 father_linked22 ///
    mother_linked10 mother_linked12 mother_linked14 mother_linked18 mother_linked20 mother_linked22 ///
    school_public10 school_public12 school_public14 school_public18 school_public20 school_public22 ///
    school_key10 school_key12 school_key14 school_key18 school_key20 school_key22 ///
    key_class10 key_class12 key_class14 key_class18 key_class20 key_class22 ///
    class_rank10 class_rank12 class_rank14 class_rank18 class_rank20 class_rank22 ///
    grade_rank10 grade_rank12 grade_rank14 grade_rank18 grade_rank20 grade_rank22 ///
    major_rank10 major_rank12 major_rank14 major_rank18 major_rank20 major_rank22 ///
    rank_class_top25_10 rank_class_top25_12 rank_class_top25_14 rank_class_top25_18 rank_class_top25_20 rank_class_top25_22 ///
    rank_grade_top25_10 rank_grade_top25_12 rank_grade_top25_14 rank_grade_top25_18 rank_grade_top25_20 rank_grade_top25_22 ///
    study_effort10 study_effort12 study_effort14 study_effort18 study_effort20 study_effort22 ///
    concentration10 concentration12 concentration14 concentration18 concentration20 concentration22 ///
    study_pressure10 study_pressure12 study_pressure14 study_pressure18 study_pressure20 study_pressure22 ///
    tutoring_any10 tutoring_any12 tutoring_any14 tutoring_any18 tutoring_any20 tutoring_any22 ///
    edu_exp_total10 edu_exp_total12 edu_exp_total14 edu_exp_total18 edu_exp_total20 edu_exp_total22 ///
    edu_exp_tutoring10 edu_exp_tutoring12 edu_exp_tutoring14 edu_exp_tutoring18 edu_exp_tutoring20 edu_exp_tutoring22

foreach v of local needed_vars {
    capture confirm variable `v'
    if _rc {
        gen double `v' = .
    }
}

capture drop cohort_wave
gen cohort_wave = wave
label var cohort_wave "Cohort/survey wave"

capture drop id_pid
gen double id_pid = pid
label var id_pid "Personal ID"

capture drop id_fid
gen double id_fid = fid_current
replace id_fid = fid10 if missing(id_fid) & wave == 2010
replace id_fid = fid12 if missing(id_fid) & wave == 2012
replace id_fid = fid14 if missing(id_fid) & wave == 2014
replace id_fid = fid18 if missing(id_fid) & wave == 2018
replace id_fid = fid20 if missing(id_fid) & wave == 2020
replace id_fid = fid22 if missing(id_fid) & wave == 2022
label var id_fid "Current household ID"

capture drop id_fid_pre
gen double id_fid_pre = fid_pre
label var id_fid_pre "Previous-wave household ID"

capture drop cohort_type
gen byte cohort_type = .
replace cohort_type = 2 if wave == 2010 & baseline_proxy == 1
replace cohort_type = 1 if inlist(wave, 2012, 2014, 2018, 2020, 2022) & strict_first_entrant == 1

capture drop main_2012_2022
gen byte main_2012_2022 = cohort_type == 1 & inlist(wave, 2012, 2014, 2018, 2020, 2022)

capture drop expanded_2010_2022
gen byte expanded_2010_2022 = inlist(cohort_type, 1, 2)

capture drop age_entry
gen age_entry = .
replace age_entry = age10 if wave == 2010
replace age_entry = age12 if wave == 2012
replace age_entry = age14 if wave == 2014
replace age_entry = age18 if wave == 2018
replace age_entry = age20 if wave == 2020
replace age_entry = age22 if wave == 2022

capture drop hukou_agri
gen byte hukou_agri = .
replace hukou_agri = hukou_agri10 if wave == 2010
replace hukou_agri = hukou_agri12 if wave == 2012
replace hukou_agri = hukou_agri14 if wave == 2014
replace hukou_agri = hukou_agri18 if wave == 2018
replace hukou_agri = hukou_agri20 if wave == 2020
replace hukou_agri = hukou_agri22 if wave == 2022

capture drop han
gen byte han = .
replace han = han10 if wave == 2010
replace han = han12 if wave == 2012
replace han = han14 if wave == 2014
replace han = han18 if wave == 2018
replace han = han20 if wave == 2020
replace han = han22 if wave == 2022

capture drop urban_ctrl
gen urban_ctrl = .
replace urban_ctrl = urban10_ctrl if wave == 2010
replace urban_ctrl = urban12_ctrl if wave == 2012
replace urban_ctrl = urban14_ctrl if wave == 2014
replace urban_ctrl = urban18_ctrl if wave == 2018
replace urban_ctrl = urban20_ctrl if wave == 2020
replace urban_ctrl = urban22_ctrl if wave == 2022

capture drop parent_college_any
gen byte parent_college_any = .
replace parent_college_any = parent_college_any10 if wave == 2010
replace parent_college_any = parent_college_any12 if wave == 2012
replace parent_college_any = parent_college_any14 if wave == 2014
replace parent_college_any = parent_college_any18 if wave == 2018
replace parent_college_any = parent_college_any20 if wave == 2020
replace parent_college_any = parent_college_any22 if wave == 2022

capture drop parent_bachelor_any
gen byte parent_bachelor_any = .
replace parent_bachelor_any = parent_bachelor_any10 if wave == 2010
replace parent_bachelor_any = parent_bachelor_any12 if wave == 2012
replace parent_bachelor_any = parent_bachelor_any14 if wave == 2014
replace parent_bachelor_any = parent_bachelor_any18 if wave == 2018
replace parent_bachelor_any = parent_bachelor_any20 if wave == 2020
replace parent_bachelor_any = parent_bachelor_any22 if wave == 2022

capture drop parent_highschool_any
gen byte parent_highschool_any = .
replace parent_highschool_any = parent_highschool_any10 if wave == 2010
replace parent_highschool_any = parent_highschool_any12 if wave == 2012
replace parent_highschool_any = parent_highschool_any14 if wave == 2014
replace parent_highschool_any = parent_highschool_any18 if wave == 2018
replace parent_highschool_any = parent_highschool_any20 if wave == 2020
replace parent_highschool_any = parent_highschool_any22 if wave == 2022

capture drop parent_party_any
gen byte parent_party_any = .
replace parent_party_any = parent_party_any10 if wave == 2010
replace parent_party_any = parent_party_any12 if wave == 2012
replace parent_party_any = parent_party_any14 if wave == 2014
replace parent_party_any = parent_party_any18 if wave == 2018
replace parent_party_any = parent_party_any20 if wave == 2020
replace parent_party_any = parent_party_any22 if wave == 2022

capture drop parent_age_mean
gen parent_age_mean = .
replace parent_age_mean = parent_age_mean10 if wave == 2010
replace parent_age_mean = parent_age_mean12 if wave == 2012
replace parent_age_mean = parent_age_mean14 if wave == 2014
replace parent_age_mean = parent_age_mean18 if wave == 2018
replace parent_age_mean = parent_age_mean20 if wave == 2020
replace parent_age_mean = parent_age_mean22 if wave == 2022

capture drop father_linked
gen byte father_linked = .
replace father_linked = father_linked10 if wave == 2010
replace father_linked = father_linked12 if wave == 2012
replace father_linked = father_linked14 if wave == 2014
replace father_linked = father_linked18 if wave == 2018
replace father_linked = father_linked20 if wave == 2020
replace father_linked = father_linked22 if wave == 2022

capture drop mother_linked
gen byte mother_linked = .
replace mother_linked = mother_linked10 if wave == 2010
replace mother_linked = mother_linked12 if wave == 2012
replace mother_linked = mother_linked14 if wave == 2014
replace mother_linked = mother_linked18 if wave == 2018
replace mother_linked = mother_linked20 if wave == 2020
replace mother_linked = mother_linked22 if wave == 2022

capture drop school_public
gen byte school_public = .
replace school_public = school_public10 if wave == 2010
replace school_public = school_public12 if wave == 2012
replace school_public = school_public14 if wave == 2014
replace school_public = school_public18 if wave == 2018
replace school_public = school_public20 if wave == 2020
replace school_public = school_public22 if wave == 2022

capture drop school_key
gen byte school_key = .
replace school_key = school_key10 if wave == 2010
replace school_key = school_key12 if wave == 2012
replace school_key = school_key14 if wave == 2014
replace school_key = school_key18 if wave == 2018
replace school_key = school_key20 if wave == 2020
replace school_key = school_key22 if wave == 2022

capture drop key_class
gen byte key_class = .
replace key_class = key_class10 if wave == 2010
replace key_class = key_class12 if wave == 2012
replace key_class = key_class14 if wave == 2014
replace key_class = key_class18 if wave == 2018
replace key_class = key_class20 if wave == 2020
replace key_class = key_class22 if wave == 2022

capture drop class_rank
gen class_rank = .
replace class_rank = class_rank10 if wave == 2010
replace class_rank = class_rank12 if wave == 2012
replace class_rank = class_rank14 if wave == 2014
replace class_rank = class_rank18 if wave == 2018
replace class_rank = class_rank20 if wave == 2020
replace class_rank = class_rank22 if wave == 2022

capture drop grade_rank
gen grade_rank = .
replace grade_rank = grade_rank10 if wave == 2010
replace grade_rank = grade_rank12 if wave == 2012
replace grade_rank = grade_rank14 if wave == 2014
replace grade_rank = grade_rank18 if wave == 2018
replace grade_rank = grade_rank20 if wave == 2020
replace grade_rank = grade_rank22 if wave == 2022

capture drop major_rank
gen major_rank = .
replace major_rank = major_rank10 if wave == 2010
replace major_rank = major_rank12 if wave == 2012
replace major_rank = major_rank14 if wave == 2014
replace major_rank = major_rank18 if wave == 2018
replace major_rank = major_rank20 if wave == 2020
replace major_rank = major_rank22 if wave == 2022

capture drop rank_class_top25
gen byte rank_class_top25 = .
replace rank_class_top25 = rank_class_top25_10 if wave == 2010
replace rank_class_top25 = rank_class_top25_12 if wave == 2012
replace rank_class_top25 = rank_class_top25_14 if wave == 2014
replace rank_class_top25 = rank_class_top25_18 if wave == 2018
replace rank_class_top25 = rank_class_top25_20 if wave == 2020
replace rank_class_top25 = rank_class_top25_22 if wave == 2022

capture drop rank_grade_top25
gen byte rank_grade_top25 = .
replace rank_grade_top25 = rank_grade_top25_10 if wave == 2010
replace rank_grade_top25 = rank_grade_top25_12 if wave == 2012
replace rank_grade_top25 = rank_grade_top25_14 if wave == 2014
replace rank_grade_top25 = rank_grade_top25_18 if wave == 2018
replace rank_grade_top25 = rank_grade_top25_20 if wave == 2020
replace rank_grade_top25 = rank_grade_top25_22 if wave == 2022

capture drop study_effort
gen study_effort = .
replace study_effort = study_effort10 if wave == 2010
replace study_effort = study_effort12 if wave == 2012
replace study_effort = study_effort14 if wave == 2014
replace study_effort = study_effort18 if wave == 2018
replace study_effort = study_effort20 if wave == 2020
replace study_effort = study_effort22 if wave == 2022

capture drop concentration
gen concentration = .
replace concentration = concentration10 if wave == 2010
replace concentration = concentration12 if wave == 2012
replace concentration = concentration14 if wave == 2014
replace concentration = concentration18 if wave == 2018
replace concentration = concentration20 if wave == 2020
replace concentration = concentration22 if wave == 2022

capture drop study_pressure
gen study_pressure = .
replace study_pressure = study_pressure10 if wave == 2010
replace study_pressure = study_pressure12 if wave == 2012
replace study_pressure = study_pressure14 if wave == 2014
replace study_pressure = study_pressure18 if wave == 2018
replace study_pressure = study_pressure20 if wave == 2020
replace study_pressure = study_pressure22 if wave == 2022

capture drop tutoring_any
gen byte tutoring_any = .
replace tutoring_any = tutoring_any10 if wave == 2010
replace tutoring_any = tutoring_any12 if wave == 2012
replace tutoring_any = tutoring_any14 if wave == 2014
replace tutoring_any = tutoring_any18 if wave == 2018
replace tutoring_any = tutoring_any20 if wave == 2020
replace tutoring_any = tutoring_any22 if wave == 2022

capture drop edu_exp_total
gen edu_exp_total = .
replace edu_exp_total = edu_exp_total10 if wave == 2010
replace edu_exp_total = edu_exp_total12 if wave == 2012
replace edu_exp_total = edu_exp_total14 if wave == 2014
replace edu_exp_total = edu_exp_total18 if wave == 2018
replace edu_exp_total = edu_exp_total20 if wave == 2020
replace edu_exp_total = edu_exp_total22 if wave == 2022

capture drop edu_exp_tutoring
gen edu_exp_tutoring = .
replace edu_exp_tutoring = edu_exp_tutoring10 if wave == 2010
replace edu_exp_tutoring = edu_exp_tutoring12 if wave == 2012
replace edu_exp_tutoring = edu_exp_tutoring14 if wave == 2014
replace edu_exp_tutoring = edu_exp_tutoring18 if wave == 2018
replace edu_exp_tutoring = edu_exp_tutoring20 if wave == 2020
replace edu_exp_tutoring = edu_exp_tutoring22 if wave == 2022

capture drop ihs_edu_exp_total
gen ihs_edu_exp_total = asinh(edu_exp_total)

capture drop ihs_edu_exp_tutoring
gen ihs_edu_exp_tutoring = asinh(edu_exp_tutoring)

capture drop valid_field
gen byte valid_field = !missing(field5)

capture drop has_asset_same
gen byte has_asset_same = !missing(total_asset_same)

capture drop has_income_same
gen byte has_income_same = !missing(hh_income_same)

capture drop analytic_main
gen byte analytic_main = main_2012_2022 == 1 ///
    & valid_field == 1 ///
    & has_asset_same == 1

capture drop analytic_main_income
gen byte analytic_main_income = analytic_main == 1 & has_income_same == 1

capture drop analytic_main_parent
gen byte analytic_main_parent = analytic_main == 1 & !missing(parent_college_any)

capture drop analytic_expanded
gen byte analytic_expanded = expanded_2010_2022 == 1 ///
    & valid_field == 1 ///
    & has_asset_same == 1

capture drop analytic_expanded_parent
gen byte analytic_expanded_parent = analytic_expanded == 1 & !missing(parent_college_any)
foreach v of varlist _all {
    capture label values `v'
}
label define yesnolbl 0 "No" 1 "Yes", replace
label define femalelbl 0 "Male" 1 "Female", replace
label define levellbl 1 "Junior college" 2 "Bachelor", replace
label define stemlbl 0 "Non-STEM" 1 "STEM", replace

label define field5lbl ///
    1 "STEM" ///
    2 "Medicine" ///
    3 "Business-Law-Econ-Management" ///
    4 "Humanities-Social-Education" ///
    5 "Other", replace

label define cohorttypelbl ///
    1 "Strict first entrant" ///
    2 "2010 baseline proxy", replace

label define sampletypelbl ///
    1 "Strict first entrant" ///
    2 "2010 baseline proxy", replace

label define qlbl_common ///
    1 "Q1 lowest" ///
    2 "Q2" ///
    3 "Q3" ///
    4 "Q4 highest", replace

label define port4lbl_common ///
    1 "Limited/non-housing assets" ///
    2 "Housing only" ///
    3 "Housing + financial assets" ///
    4 "Productive assets", replace

capture label values female femalelbl
capture label values level levellbl
capture label values stem stemlbl
capture label values field5 field5lbl
capture label values cohort_type cohorttypelbl
capture label values sample_type sampletypelbl
capture label values asset_q_same qlbl_common
capture label values income_q_same qlbl_common
capture label values asset_portfolio4 port4lbl_common

foreach v in main_2012_2022 expanded_2010_2022 ///
    baseline_proxy strict_first_entrant first_ps ps fulltime ordinary_ps ///
    valid_field has_asset_same has_income_same ///
    analytic_main analytic_main_income analytic_main_parent ///
    analytic_expanded analytic_expanded_parent ///
    hukou_agri han school_public school_key key_class ///
    rank_class_top25 rank_grade_top25 tutoring_any ///
    parent_college_any parent_bachelor_any parent_highschool_any parent_party_any ///
    father_linked mother_linked {
    capture label values `v' yesnolbl
}

label var pid "Personal ID"
label var id_pid "Personal ID"
capture label var fid "Household ID, original wave-specific variable"
label var id_fid "Current household ID"
label var id_fid_pre "Previous-wave household ID"
label var cid "Community ID"
label var provcd "Province code"
label var countyid "County code"
label var psu "Primary sampling unit"
label var subsample "Subsample indicator"
label var subpopulation "Sampling subpopulation"

label var wave "Survey wave"
label var cohort_wave "Cohort wave"
label var cohort_type "Cohort type"
label var main_2012_2022 "Main sample: strict entrants, 2012-2022"
label var expanded_2010_2022 "Expanded sample: 2010 proxy plus 2012-2022 strict entrants"

label var female "Female indicator"
label var age_entry "Age at survey or cohort entry"
label var hukou_agri "Agricultural hukou"
label var han "Han ethnicity"
label var urban_ctrl "Urban/rural indicator"

label var ps "Currently enrolled in junior college or bachelor program"
label var level "Postsecondary level"
label var fulltime "Full-time student"
label var ordinary_ps "Ordinary postsecondary program"
label var ps_start "Start year of current postsecondary stage"
label var first_ps "First-entrant or baseline-proxy indicator"
label var strict_first_entrant "Strict first-entrant indicator"
label var baseline_proxy "2010 baseline-proxy indicator"
label var sample_type "Sample type"

label var disc "Unified discipline code"
label var field5 "Field of study, five-category classification"
label var stem "STEM field"

label var parent_college_any "At least one parent junior-college educated or above"
label var parent_bachelor_any "At least one parent bachelor educated or above"
label var parent_highschool_any "At least one parent high-school educated or above"
label var parent_party_any "At least one parent CCP member"
label var parent_age_mean "Mean parental age"
label var father_linked "Father linked in person file"
label var mother_linked "Mother linked in person file"

label var hh_income_same "Same-wave household income"
label var hh_income_pc_same "Same-wave per-capita household income"
label var hh_income_per_p_same "Same-wave per-capita household income percentile/rank"

label var total_asset_same "Same-wave household net assets"
label var houseasset_net_same "Same-wave net housing assets"
label var houseasset_gross_same "Same-wave gross housing assets"
label var finance_asset_same "Same-wave financial assets"
label var fixed_asset_same "Same-wave productive fixed assets"
label var land_asset_same "Same-wave land assets"
label var durables_asset_same "Same-wave durable assets"
label var savings_same "Same-wave savings"
label var financial_product_same "Same-wave financial products"
label var company_asset_same "Same-wave business/company assets"
label var agrimachine_asset_same "Same-wave agricultural machinery assets"
label var resivalue_same "Same-wave primary residence value"
label var otherhousevalue_same "Same-wave other housing value"

label var debt_house_same "Same-wave housing debt"
label var debt_nonhouse_same "Same-wave non-housing debt"
label var debt_other_same "Same-wave other receivables/debt variable"
label var debt_total_same "Same-wave total household debt"

label var ihs_hh_income_same "IHS same-wave household income"
label var ihs_hh_income_pc_same "IHS same-wave per-capita household income"
label var ihs_total_asset_same "IHS same-wave household net assets"
label var ihs_houseasset_net_same "IHS same-wave net housing assets"
label var ihs_houseasset_gross_same "IHS same-wave gross housing assets"
label var ihs_finance_asset_same "IHS same-wave financial assets"
label var ihs_fixed_asset_same "IHS same-wave productive fixed assets"
label var ihs_land_asset_same "IHS same-wave land assets"
label var ihs_durables_asset_same "IHS same-wave durable assets"
label var ihs_savings_same "IHS same-wave savings"
label var ihs_financial_product_same "IHS same-wave financial products"
label var ihs_company_asset_same "IHS same-wave business/company assets"
label var ihs_agrimachine_asset_same "IHS same-wave agricultural machinery assets"
label var ihs_debt_house_same "IHS same-wave housing debt"
label var ihs_debt_nonhouse_same "IHS same-wave non-housing debt"
label var ihs_debt_total_same "IHS same-wave total household debt"

label var asset_q_same "Within-wave household net asset quartile"
label var income_q_same "Within-wave per-capita household income quartile"

label var has_house "Has housing assets"
label var has_finance "Has financial assets"
label var has_business "Has productive assets"
label var has_land "Has land assets"
label var has_debt "Has household debt"
label var asset_portfolio4 "Household asset portfolio"

label var school_public "Public school"
label var school_key "Key or demonstration school"
label var key_class "Key class"

label var class_rank "Class rank"
label var grade_rank "Grade rank"
label var major_rank "Major rank"
label var rank_class_top25 "Class rank in top 25 percent"
label var rank_grade_top25 "Grade rank in top 25 percent"

label var study_effort "Study effort"
label var concentration "Concentration"
label var study_pressure "Study pressure"
label var tutoring_any "Any tutoring or extracurricular training"

label var edu_exp_total "Total education expenditure"
label var edu_exp_tutoring "Tutoring expenditure"
label var ihs_edu_exp_total "IHS total education expenditure"
label var ihs_edu_exp_tutoring "IHS tutoring expenditure"

label var valid_field "Has valid field-of-study information"
label var has_asset_same "Has same-wave household asset information"
label var has_income_same "Has same-wave household income information"

label var analytic_main "Main analytic sample: 2012-2022 strict entrants with valid field and assets"
label var analytic_main_income "Main analytic sample with household income"
label var analytic_main_parent "Main analytic sample with parent education"

label var analytic_expanded "Expanded analytic sample including 2010 proxy"
label var analytic_expanded_parent "Expanded analytic sample with parent education"

foreach v of varlist _all {
    local lab : variable label `v'
    if "`lab'" == "" {
        label var `v' "`v'"
    }
    else if ustrregexm("`lab'", "\p{Han}") {
        label var `v' "`v'"
    }
}

compress
save "$out/cfps_entrant_expanded_2010_2022_controls_01_10_2026.dta", replace

preserve
keep if main_2012_2022 == 1
compress
save "$out/cfps_entrant_main_2012_2022_controls_01_10_2026.dta", replace
restore

display "=================================================="
display "APPEND COMPLETE"
display "=================================================="

display "All appended rows by wave:"
tab wave, m

display "Cohort type by wave:"
tab wave cohort_type, m

display "Main sample count by wave:"
tab wave if analytic_main == 1, m

display "Expanded sample count by wave:"
tab wave if analytic_expanded == 1, m

display "Field distribution, main sample:"
tab wave field5 if analytic_main == 1, m

display "STEM by female, main sample:"
tab female stem if analytic_main == 1, m

display "Field by female, main sample:"
tab female field5 if analytic_main == 1, m

display "Asset quartile by field, main sample:"
tab asset_q_same field5 if analytic_main == 1, m

display "Asset portfolio by field, main sample:"
tab asset_portfolio4 field5 if analytic_main == 1, m

display "Missingness summary, main sample:"
misstable summarize ///
    female age_entry level field5 stem ///
    total_asset_same ihs_total_asset_same asset_q_same asset_portfolio4 ///
    hh_income_pc_same ihs_hh_income_pc_same income_q_same ///
    parent_college_any hukou_agri han urban_ctrl ///
    school_key key_class rank_class_top25 rank_grade_top25 ///
    study_effort study_pressure tutoring_any edu_exp_total ///
    if analytic_main == 1

display "Main sample with parent education:"
tab analytic_main_parent if analytic_main == 1, m

display "Expanded sample with parent education:"
tab analytic_expanded_parent if analytic_expanded == 1, m

display "=================================================="
display "CHECK CHINESE VARIABLE LABELS"
display "=================================================="

local chinese_label_count = 0

foreach v of varlist _all {
    local lab : variable label `v'
    if ustrregexm("`lab'", "\p{Han}") {
        local chinese_label_count = `chinese_label_count' + 1
        display as error "`v' has Chinese label: `lab'"
    }
}

display "Number of variables with Chinese labels: `chinese_label_count'"

display "=================================================="
display "CHECK VALUE LABEL ATTACHMENTS"
display "=================================================="

foreach v of varlist _all {
    local vl : value label `v'
    if "`vl'" != "" {
        display "`v' uses value label: `vl'"
    }
}

display "=================================================="
display "Saved:"
display "$out/cfps_entrant_main_2012_2022_controls_01_10_2026.dta"
display "$out/cfps_entrant_expanded_2010_2022_controls_01_10_2026.dta"
display "=================================================="

exit
}

if "`module'" == "ready" {
/* Ready. */
version 18

clear
set more off
set maxvar 32767

global project "$ROOT"
global data    "$HSSC_DATA/clean"
global res     "$HSSC_RESULTS/intermediate"

global main_raw "$data/cfps_entrant_main_2012_2022_controls_01_10_2026.dta"
global exp_raw  "$data/cfps_entrant_expanded_2010_2022_controls_01_10_2026.dta"

global main_ready "$data/cfps_entrant_main_2012_2022_analysis_ready_01_10_2026.dta"
global exp_ready  "$data/cfps_entrant_expanded_2010_2022_analysis_ready_01_10_2026.dta"

capture mkdir "$res"
capture mkdir "$res/data_cleaning"

capture program drop apply_value_labels_clean
program define apply_value_labels_clean

    capture label define yesnolbl 0 "No" 1 "Yes", replace
    capture label define yesnomisslbl 0 "No" 1 "Yes" 9 "Missing", replace
    capture label define femalelbl 0 "Men" 1 "Women", replace
    capture label define levellbl 1 "Junior college" 2 "Bachelor", replace
    capture label define stemlbl 0 "Non-STEM" 1 "STEM", replace

    capture label define field5lbl ///
        1 "STEM" ///
        2 "Medicine" ///
        3 "Business-Law-Econ-Management" ///
        4 "Humanities-Social-Education" ///
        5 "Other", replace

    capture label define field3lbl ///
        1 "STEM" ///
        2 "Medicine and LEM non-STEM" ///
        3 "Other non-STEM", replace

    capture label define port4lbl ///
        1 "Limited/non-housing assets" ///
        2 "Housing only" ///
        3 "Housing + financial assets" ///
        4 "Productive assets", replace

    capture label define port4shortlbl ///
        1 "Limited/non-housing" ///
        2 "Housing only" ///
        3 "Housing + financial" ///
        4 "Productive", replace

    capture label define qlbl ///
        1 "Q1 lowest" ///
        2 "Q2" ///
        3 "Q3" ///
        4 "Q4 highest", replace

    capture label values female femalelbl
    capture label values stem stemlbl
    capture label values level levellbl
    capture label values field5 field5lbl
    capture label values field3_dest field3lbl
    capture label values asset_portfolio4 port4lbl
    capture label values asset_q_same qlbl
    capture label values income_q_same qlbl

    foreach v in analytic_main analytic_main_income analytic_main_parent ///
        analytic_expanded analytic_expanded_parent main_2012_2022 expanded_2010_2022 ///
        hukou_agri han urban_ctrl parent_college_any parent_bachelor_any ///
        parent_highschool_any parent_party_any school_public school_key key_class ///
        rank_class_top25 rank_grade_top25 tutoring_any ///
        has_house has_finance has_business has_land has_debt ///
        age_entry_miss income_miss ///
        med_field bus_field humsoc_field other_field ///
        highstatus_nonstem_field other_nonstem_field ///
        self_academic_common_miss talent_belief_common_miss ///
        study_pressure_common_miss study_effort_common_miss ///
        concentration_common_miss expected_edu_common_miss ///
        desired_occ_miss {
        capture label values `v' yesnolbl
    }

    foreach v in hukou_agri_cat han_cat urban_cat ///
        parent_college_cat parent_bachelor_cat parent_highschool_cat parent_party_cat ///
        has_house_cat has_finance_cat has_business_cat has_land_cat has_debt_cat ///
        rank_class_top25_cat rank_grade_top25_cat school_key_cat key_class_cat {
        capture label values `v' yesnomisslbl
    }

end

capture program drop harmonize_student_controls_clean
program define harmonize_student_controls_clean

    capture drop self_academic_common talent_belief_common ///
        study_pressure_common study_effort_common concentration_common ///
        expected_edu_common desired_occ_code_common

    foreach x in self_academic talent_belief study_pressure study_effort ///
        concentration expected_edu desired_occ_code {

        gen double `x'_common = .

        foreach w in 12 14 18 20 22 {
            local yr = 2000 + `w'
            capture confirm numeric variable `x'`w'
            if !_rc {
                replace `x'_common = `x'`w' ///
                    if wave == `yr' & missing(`x'_common) & !missing(`x'`w')
            }
        }
    }

    label var self_academic_common "Academic self-evaluation, harmonised"
    label var talent_belief_common "Belief in talent importance, harmonised"
    label var study_pressure_common "Study pressure, harmonised"
    label var study_effort_common "Study effort, harmonised"
    label var concentration_common "Classroom concentration, harmonised"
    label var expected_edu_common "Educational expectation, harmonised"
    label var desired_occ_code_common "Desired occupation code, harmonised"

end

capture program drop prepare_analysis_variables_clean
program define prepare_analysis_variables_clean, rclass
    syntax [, SAMPLEVAR(name)]
    if "`samplevar'" == "" {
        local samplevar "analytic_main"
        capture confirm variable analytic_main
        if _rc {
            capture confirm variable analytic_expanded
            if !_rc local samplevar "analytic_expanded"
        }
    }

    capture drop age_entry_miss age_entry_imp
    gen byte age_entry_miss = missing(age_entry)

    quietly count if `samplevar' == 1 & !missing(age_entry)
    if r(N) > 0 {
        quietly summarize age_entry if `samplevar' == 1, meanonly
        gen double age_entry_imp = age_entry
        replace age_entry_imp = r(mean) if missing(age_entry_imp)
    }
    else {
        gen double age_entry_imp = 0
        replace age_entry_miss = 1
    }

    label var age_entry_imp "Age at survey or cohort entry, mean-imputed"
    label var age_entry_miss "Age missing indicator"

    capture drop hukou_agri_cat han_cat urban_cat ///
        parent_college_cat parent_bachelor_cat parent_highschool_cat parent_party_cat

    foreach v in hukou_agri han urban_ctrl parent_college_any ///
        parent_bachelor_any parent_highschool_any parent_party_any {
        capture confirm numeric variable `v'
        if _rc gen byte `v' = .
    }

    gen byte hukou_agri_cat = hukou_agri
    replace hukou_agri_cat = 9 if missing(hukou_agri_cat)

    gen byte han_cat = han
    replace han_cat = 9 if missing(han_cat)

    gen byte urban_cat = urban_ctrl
    replace urban_cat = 9 if missing(urban_cat)

    gen byte parent_college_cat = parent_college_any
    replace parent_college_cat = 9 if missing(parent_college_cat)

    gen byte parent_bachelor_cat = parent_bachelor_any
    replace parent_bachelor_cat = 9 if missing(parent_bachelor_cat)

    gen byte parent_highschool_cat = parent_highschool_any
    replace parent_highschool_cat = 9 if missing(parent_highschool_cat)

    gen byte parent_party_cat = parent_party_any
    replace parent_party_cat = 9 if missing(parent_party_cat)

    label var hukou_agri_cat "Agricultural hukou, missing category"
    label var han_cat "Han ethnicity, missing category"
    label var urban_cat "Urban residence, missing category"
    label var parent_college_cat "At least one parent college educated, missing category"
    label var parent_bachelor_cat "At least one parent bachelor educated, missing category"
    label var parent_highschool_cat "At least one parent high-school educated, missing category"
    label var parent_party_cat "At least one parent CCP member, missing category"

    capture drop income_miss ihs_hh_income_pc_imp hh_income_pc_wan

    capture confirm numeric variable ihs_hh_income_pc_same
    if !_rc {
        gen byte income_miss = missing(ihs_hh_income_pc_same)
        gen double ihs_hh_income_pc_imp = ihs_hh_income_pc_same
        quietly count if `samplevar' == 1 & !missing(ihs_hh_income_pc_same)
        if r(N) > 0 {
            quietly summarize ihs_hh_income_pc_same if `samplevar' == 1, meanonly
            replace ihs_hh_income_pc_imp = r(mean) if missing(ihs_hh_income_pc_imp)
        }
        else {
            replace ihs_hh_income_pc_imp = 0 if missing(ihs_hh_income_pc_imp)
            replace income_miss = 1
        }
    }
    else {
        gen byte income_miss = 1
        gen double ihs_hh_income_pc_imp = 0
    }

    capture confirm numeric variable hh_income_pc_same
    if !_rc gen double hh_income_pc_wan = hh_income_pc_same / 10000
    else gen double hh_income_pc_wan = .

    label var income_miss "Per-capita household income missing"
    label var ihs_hh_income_pc_imp "IHS per-capita household income, mean-imputed"
    label var hh_income_pc_wan "Per-capita household income (10,000 RMB)"

    capture drop total_asset_wan
    capture confirm numeric variable total_asset_same
    if !_rc gen double total_asset_wan = total_asset_same / 10000
    else gen double total_asset_wan = .
    label var total_asset_wan "Household net assets (10,000 RMB)"

    capture drop has_house_cat has_finance_cat has_business_cat has_land_cat has_debt_cat
    foreach a in house finance business land debt {
        capture confirm numeric variable has_`a'
        if !_rc {
            gen byte has_`a'_cat = has_`a'
            replace has_`a'_cat = 9 if missing(has_`a'_cat)
        }
        else {
            gen byte has_`a'_cat = 9
        }
    }

    label var has_house_cat "Has housing assets, missing category"
    label var has_finance_cat "Has financial assets, missing category"
    label var has_business_cat "Has productive assets, missing category"
    label var has_land_cat "Has land assets, missing category"
    label var has_debt_cat "Has household debt, missing category"
    capture drop portfolio_wealth_position
    gen byte portfolio_wealth_position = .
    replace portfolio_wealth_position = 1 if asset_portfolio4 == 1
    replace portfolio_wealth_position = 2 if asset_portfolio4 == 2
    replace portfolio_wealth_position = 3 if inlist(asset_portfolio4, 3, 4)
    label define portposlbl 1 "Lowest net wealth / no housing security" ///
                          2 "Intermediate net wealth / housing only" ///
                          3 "Higher or more complex asset structure", replace
    label values portfolio_wealth_position portposlbl
    label var portfolio_wealth_position "Descriptive wealth position of portfolio"

    capture drop med_field bus_field humsoc_field other_field ///
        highstatus_nonstem_field other_nonstem_field field3_dest

    gen byte med_field = field5 == 2 if !missing(field5)
    gen byte bus_field = field5 == 3 if !missing(field5)
    gen byte humsoc_field = field5 == 4 if !missing(field5)
    gen byte other_field = field5 == 5 if !missing(field5)

    gen byte highstatus_nonstem_field = inlist(field5, 2, 3) if !missing(field5)
    gen byte other_nonstem_field = inlist(field5, 4, 5) if !missing(field5)

    gen byte field3_dest = .
    replace field3_dest = 1 if field5 == 1
    replace field3_dest = 2 if inlist(field5, 2, 3)
    replace field3_dest = 3 if inlist(field5, 4, 5)

    label var med_field "Medicine field indicator"
    label var bus_field "Business-Law-Econ-Management field indicator"
    label var humsoc_field "Humanities-Social-Education field indicator"
    label var other_field "Other field indicator"
    label var highstatus_nonstem_field "Medicine or business/law/econ/management"
    label var other_nonstem_field "Humanities/social/education or other"
    label var field3_dest "Three-category field destination"

    capture drop rank_class_top25_cat rank_grade_top25_cat school_key_cat key_class_cat

    foreach x in rank_class_top25 rank_grade_top25 school_key key_class {
        capture confirm numeric variable `x'
        if !_rc {
            gen byte `x'_cat = `x'
            replace `x'_cat = 9 if missing(`x'_cat)
        }
        else {
            gen byte `x'_cat = 9
        }
    }

    label var rank_class_top25_cat "Class rank in top 25 percent, missing category"
    label var rank_grade_top25_cat "Grade rank in top 25 percent, missing category"
    label var school_key_cat "Key school, missing category"
    label var key_class_cat "Key class, missing category"

    foreach x in self_academic_common talent_belief_common study_pressure_common ///
        study_effort_common concentration_common expected_edu_common {

        capture drop `x'_miss `x'_imp
        capture confirm numeric variable `x'
        if !_rc {
            gen byte `x'_miss = missing(`x')
            gen double `x'_imp = `x'
            quietly count if `samplevar' == 1 & !missing(`x')
            if r(N) > 0 {
                quietly summarize `x' if `samplevar' == 1, meanonly
                replace `x'_imp = r(mean) if missing(`x'_imp)
            }
            else {
                replace `x'_imp = 0 if missing(`x'_imp)
                replace `x'_miss = 1
            }
        }
        else {
            gen byte `x'_miss = 1
            gen double `x'_imp = 0
        }
    }

    label var self_academic_common_imp "Academic self-evaluation, mean-imputed"
    label var self_academic_common_miss "Academic self-evaluation missing"
    label var talent_belief_common_imp "Belief in talent importance, mean-imputed"
    label var talent_belief_common_miss "Talent-belief missing"
    label var study_pressure_common_imp "Study pressure, mean-imputed"
    label var study_pressure_common_miss "Study-pressure missing"
    label var study_effort_common_imp "Study effort, mean-imputed"
    label var study_effort_common_miss "Study-effort missing"
    label var concentration_common_imp "Classroom concentration, mean-imputed"
    label var concentration_common_miss "Concentration missing"
    label var expected_edu_common_imp "Educational expectation, mean-imputed"
    label var expected_edu_common_miss "Educational expectation missing"

    capture drop desired_occ_miss desired_occ_cat
    capture confirm numeric variable desired_occ_code_common
    if !_rc {
        gen byte desired_occ_miss = missing(desired_occ_code_common)
        gen double desired_occ_cat = desired_occ_code_common
        replace desired_occ_cat = 999 if missing(desired_occ_cat)
    }
    else {
        gen byte desired_occ_miss = 1
        gen double desired_occ_cat = 999
    }
    label var desired_occ_miss "Desired occupation missing"
    label var desired_occ_cat "Desired occupation category"

    apply_value_labels_clean

end

capture program drop apply_variable_labels_clean
program define apply_variable_labels_clean

    apply_value_labels_clean

    capture label var pid "Personal ID"
    capture label var id_pid "Personal ID"
    capture label var id_fid "Current household ID"
    capture label var id_fid_pre "Previous-wave household ID"
    capture label var wave "Survey wave"
    capture label var cohort_wave "Cohort wave"
    capture label var provcd_h "Province code"

    capture label var main_2012_2022 "Main sample: strict entrants, 2012-2022"
    capture label var analytic_main "Main analytic sample: 2012-2022 strict entrants with valid field and assets"
    capture label var analytic_main_income "Main analytic sample with household income"
    capture label var analytic_main_parent "Main analytic sample with parental education"
    capture label var analytic_expanded "Expanded analytic sample"
    capture label var analytic_expanded_parent "Expanded analytic sample with parental education"

    capture label var stem "STEM field"
    capture label var field5 "Field of study, five-category classification"
    capture label var field3_dest "Three-category field destination"
    capture label var female "Gender"
    capture label var age_entry "Age at survey or cohort entry"
    capture label var level "Postsecondary level"

    capture label var hukou_agri "Agricultural hukou"
    capture label var han "Han ethnicity"
    capture label var urban_ctrl "Urban/rural indicator"
    capture label var parent_college_any "At least one parent junior-college educated or above"
    capture label var parent_bachelor_any "At least one parent bachelor educated or above"
    capture label var parent_highschool_any "At least one parent high-school educated or above"
    capture label var parent_party_any "At least one parent CCP member"

    capture label var hh_income_same "Same-wave household income"
    capture label var hh_income_pc_same "Same-wave per-capita household income"
    capture label var ihs_hh_income_same "IHS same-wave household income"
    capture label var ihs_hh_income_pc_same "IHS same-wave per-capita household income"

    capture label var total_asset_same "Same-wave household net assets"
    capture label var total_asset_wan "Household net assets (10,000 RMB)"
    capture label var ihs_total_asset_same "IHS same-wave household net assets"

    capture label var houseasset_net_same "Same-wave net housing assets"
    capture label var houseasset_gross_same "Same-wave gross housing assets"
    capture label var finance_asset_same "Same-wave financial assets"
    capture label var fixed_asset_same "Same-wave productive fixed assets"
    capture label var land_asset_same "Same-wave land assets"
    capture label var durables_asset_same "Same-wave durable assets"
    capture label var savings_same "Same-wave savings"
    capture label var financial_product_same "Same-wave financial products"
    capture label var company_asset_same "Same-wave company/business assets"
    capture label var agrimachine_asset_same "Same-wave agricultural machinery assets"

    capture label var debt_house_same "Same-wave housing debt"
    capture label var debt_nonhouse_same "Same-wave non-housing debt"
    capture label var debt_other_same "Same-wave other debt"
    capture label var debt_total_same "Same-wave total household debt"

    capture label var asset_portfolio4 "Household asset portfolio"
    capture label var has_house "Has housing assets"
    capture label var has_finance "Has financial assets"
    capture label var has_business "Has productive assets"
    capture label var has_land "Has land assets"
    capture label var has_debt "Has household debt"

    foreach v of varlist _all {
        local lab : variable label `v'
        if "`lab'" == "" {
            label var `v' "`v'"
        }
    }

end

capture confirm file "$main_raw"
if _rc {
    display as error "Cannot find main raw file: $main_raw"
    exit 601
}

use "$main_raw", clear
harmonize_student_controls_clean
prepare_analysis_variables_clean, samplevar(analytic_main)
apply_variable_labels_clean

compress
save "$main_ready", replace

capture confirm file "$exp_raw"
if !_rc {
    use "$exp_raw", clear
    harmonize_student_controls_clean
    prepare_analysis_variables_clean, samplevar(analytic_expanded)
    apply_variable_labels_clean
    compress
    save "$exp_ready", replace
}

use "$main_ready", clear

display "=================================================="
display "ANALYSIS-READY MAIN DATA CREATED"
display "=================================================="

tab wave if analytic_main == 1, m
tab female stem if analytic_main == 1, row col m
tab asset_portfolio4 if analytic_main == 1, m

display "Household net assets by asset portfolio, in 10,000 RMB"
tabstat total_asset_wan if analytic_main == 1, by(asset_portfolio4) ///
    statistics(n mean p50 sd p25 p75 min max) columns(statistics) format(%12.2f)

display "=================================================="
display "DATA CLEANING COMPLETE"
display "Saved: $main_ready"
display "Saved: $exp_ready if expanded file existed"
display "=================================================="

exit
}

display as error "Unknown module."
exit 198
