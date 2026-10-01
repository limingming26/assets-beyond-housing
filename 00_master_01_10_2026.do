/* Run from the folder containing these seven do-files.
   Arguments are the CFPS raw-data directory and an output directory. */
version 18
clear all
set more off
set varabbrev off
set maxvar 32767
set linesize 180
set seed 20261001
args raw_dir output_dir
if `"`raw_dir'"'=="" | `"`output_dir'"'=="" {
    display as error "Provide the CFPS data directory and an output directory. See README.md."
    exit 198
}
global CODE "`c(pwd)'"
global ROOT "$CODE"
global RAW `"`raw_dir'"'
global OUT `"`output_dir'"'
if "$OUT"=="$CODE" | "$OUT"=="$RAW" {
    display as error "Choose an output directory separate from the code and raw data."
    exit 198
}
capture mkdir "$OUT"
global DATA "$OUT/data"
global MODELS "$OUT/models"
global TABLES "$OUT/tables"
global FIGURES "$OUT/figures"
global LOG "$OUT/log"
global LOGS "$LOG"
global WORK "$DATA"
global HSSC_DATA "$DATA"
global HSSC_RESULTS "$OUT"
global HSSC_LOG "$LOG"
global HSSC_DATE "01_10_2026"
global BOOT_REPS 1000
foreach dir in "$DATA" "$MODELS" "$TABLES" "$FIGURES" "$LOG" "$DATA/clean" "$OUT/intermediate" "$OUT/validation" {
    capture mkdir "`dir'"
}
capture log close _all
log using "$LOG/00_master_01_10_2026.log", text replace name(replication)
about
global C_BACKGROUND c.age_entry_imp i.level i.wave i.provcd_h ///
    i.hukou_agri_cat i.urban_cat i.parent_college_cat
global C_MAIN $C_BACKGROUND c.ihs_hh_income_pc_imp i.income_miss
global C_OUTCOME_WEALTH c.ihs_total_asset_same $C_MAIN
global C_DESTINATION_WEALTH c.ihs_total_asset_same c.age_entry_imp ///
    i.level i.wave i.hukou_agri_cat i.urban_cat i.parent_college_cat ///
    c.ihs_hh_income_pc_imp i.income_miss
global C_PARENT_WEALTH $C_OUTCOME_WEALTH ///
    i.parent_bachelor_cat i.parent_highschool_cat i.parent_party_cat
global C_ORIENT_WEALTH $C_OUTCOME_WEALTH ///
    c.self_academic_common_imp i.self_academic_common_miss ///
    c.talent_belief_common_imp i.talent_belief_common_miss ///
    c.study_pressure_common_imp i.study_pressure_common_miss ///
    c.study_effort_common_imp i.study_effort_common_miss ///
    c.concentration_common_imp i.concentration_common_miss ///
    c.expected_edu_common_imp i.expected_edu_common_miss


foreach stage in 01_cleaning 02_sample 03_descriptive 04_main_models 05_supplementary 06_figures {
    display as result "Running `stage'"
    capture noisily do "$CODE/`stage'_01_10_2026.do"
    local result=_rc
    if `result' {
        capture log close _all
        exit `result'
    }
}
display as result "REPLICATION COMPLETED"
log close replication
