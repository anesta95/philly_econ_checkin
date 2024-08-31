# Philly Econ Check-In

This project is a collection of [R](https://www.r-project.org/) scripts that will fetch economic data on the Philadelphia, PA Metro Area from the [US Bureau of Labor Statistics](https://www.bls.gov/) and clean, analyze and visualize them.

## To-Dos to Execute the Code

To run these scripts you will need to download and install [R](https://cran.rstudio.com/). If you would like to run these scripts interactively in an IDE I would also recommend installing [RStudio](https://posit.co/download/rstudio-desktop/) though it is not strictly necessary.

I would also recommend setting an environment variable of `USER_EMAIL` to a valid email prior to running any of the scripts so that they can access BLS data. More info on that necessity [here](https://www.bls.gov/bls/pss.htm). However if no email is set you will be prompted to provide one in the command line.

## Execution

After downloading and installing R, run `Rscript employment.R` in the command line/terminal when you are in the project head directory. Alternatively, from the project directory start an R session and run `source("employment.R")`. This will output files with the most recent month and last 13 months of unemployment data for each county in the [Philadelphia MSA](https://censusreporter.org/profiles/31000US37980-philadelphia-camden-wilmington-pa-nj-de-md-metro-area/) as well as the entire Philadelpia MSA compared to nearby [MSAs](https://en.wikipedia.org/wiki/Metropolitan_statistical_area). Additionally, yearly changes in employment in the Philadelphia MSA by [NAICS](https://www.census.gov/naics/) two-digit supersector code are also produced.

The `employment.R` script can be run to produce new monthly data after [scheduled releases](https://www.bls.gov/schedule/news_release/metro.htm) for metro and county unemployment rates and payroll employment change.

All data will be output in the `data` folder in CSV files with the most recent month of data prepending each file name description in the `YYYY-MM-DD` format. Additional configurations of the same data will be written out to the `visualizations` folder that are CSV files of data that are sent to [Datawrapper](https://www.datawrapper.de/) visualizations that correspond to each file. For Datawrapper visualization updates to execute you will need to set a `DW_API` environment variable equal to a [Datawrapper API key](https://developer.datawrapper.de/docs/getting-started). Visualizations should be the same or as similar as possible to the below examples:

* [Unemployment Rate in the Philadelphia Metro Area](https://www.datawrapper.de/_/OtFCg/?v=3)
* [The Last Year of Unemployment in the Philadelphia Metro Area](https://www.datawrapper.de/_/KoeMM/)
* [Latest Unemployment Rate in Metro Areas Near Philadelphia](https://www.datawrapper.de/_/uKAnw/?v=2)
* [The Last Year of Unemployment in Metro Areas Near Philadelphia](https://www.datawrapper.de/_/nwJmd/)
* [Yearly Change in Employment for Philadelphia Metro](https://www.datawrapper.de/_/zoxrC/)

### Future Potential Expansions

Additional scripts with the same framework could be added to analyze average hourly wage data for workers in the Philadelphia MSA and nearby MSAs by NAICS supersector. Data could be combined with data from the [BLS Consumer Price Index](https://www.bls.gov/cpi/) to look at both real (inflation-adjusted) wages for Philadelphia Metro Area workers as well as price increases on various goods and services.

Data from the [BLS Quarterly Census of Employment and Wages](https://www.bls.gov/cew/) could also be incorporated every quarter to provide both a closer look at wage and employment trends by NAICS industry as well as changes in the number of businesses by NAICS industry.

Lastly this same framework could be applied to the [BLS/Census Current Population Survey](https://www.bls.gov/cps/) to programmatically retrieve and analyze [microdata from IPUMS](https://cps.ipums.org/cps/) that would provide deeper insights on unemployment rates, earnings, and even multiple jobholders and teleworking rates by industry, demographic and household composition aspects.
