# Assets beyond housing and gendered entry into science and engineering among homeowning families in China

This repository contains the Stata code for the analyses and figures reported in the article and its Supplementary Information.

## Data and software

The analyses use the China Family Panel Studies (CFPS). Registered users can obtain the microdata through the [CFPS data service](https://cfpsdata.pku.edu.cn/). Information about the survey is available on the [CFPS website](https://www.isss.pku.edu.cn/cfps/). The repository contains code only; users obtain the microdata directly from CFPS.

Stata 18 or later is required. The code uses built-in commands and an included Mata implementation of bias-reduced logistic regression. No additional Stata packages are required.

Keep the released filenames and organise the raw data in year folders as follows.

| Folder | Files |
| --- | --- |
| `2010` | `cfps2010adult_201906.dta`, `cfps2010famecon_201906.dta` |
| `2012` | `cfps2012adult_202505.dta`, `cfps2012famecon_201906.dta` |
| `2014` | `cfps2014adult_201906.dta`, `cfps2014famecon_201906.dta` |
| `2018` | `cfps2018person_202512.dta`, `cfps2018famecon_202512.dta` |
| `2020` | `cfps2020person_202306.dta`, `cfps2020famecon_202306.dta` |
| `2022` | `cfps2022person_202410.dta`, `cfps2022famecon_202410.dta` |

## Running the code

Download the eight files into one folder. In Stata, set that folder as the working directory and run the master file with the locations of the raw data and the desired output folder.

```stata
cd "/path/to/replication-folder"
do "00_master_01_10_2026.do" "/path/to/CFPS" "/path/to/Result/replication"
```

Replace the example paths with local paths. The parent of the output folder must already exist. Use an output folder separate from the code and raw data. The master file runs the six stages in order, including 1,000 person-level bootstrap replications. The original microdata remain unchanged.

## Files and outputs

| File | Purpose |
| --- | --- |
| `00_master_01_10_2026.do` | Sets paths and runs all stages. |
| `01_cleaning_01_10_2026.do` | Harmonises survey waves and constructs entrant and youth risk-set records. |
| `02_sample_01_10_2026.do` | Builds the analytical samples and asset-group measures. |
| `03_descriptive_01_10_2026.do` | Produces Table 1, sample and asset summaries for Appendix A, and household asset-holding rates. |
| `04_main_models_01_10_2026.do` | Estimates the main models, resource specifications and gender-specific resource associations. |
| `05_supplementary_01_10_2026.do` | Produces alternative model specifications, threshold estimates, early-wave extensions and selection-weighted estimates with bootstrap inference. |
| `06_figures_01_10_2026.do` | Produces Figures 1, B1, B2 and D1. |

The output folder contains numerical tables in `tables`, saved estimates in `models`, derived data in `data`, figures in `figures`, and a Stata log in `log`. Figures are exported as EPS, PDF and PNG. Numerical tables are exported as CSV; the manuscript's Word layout is applied separately.

The primary sample contains 872 first-time postsecondary entrants from homeowning households observed in 2014, 2018, 2020 and 2022. Science and engineering are combined in the outcome. The principal contrast is housing-plus minus housing-concentrated within each gender; the difference in contrasts is the women's contrast minus the men's contrast. CSV row labels specify the direction and units of each reported estimate.
