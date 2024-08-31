library(dplyr)
library(readr)
library(httr)
library(purrr)
library(stringr)
library(rlang)
library(lubridate)
library(tidyr)

source("functions.R")

## Analysis ##
# Grabbing BLS LAUS area reference file from here:
# https://download.bls.gov/pub/time.series/la/la.area

message("Grabbing BLS LAUS data...")
la_area <- get_bls_data(url = "https://download.bls.gov/pub/time.series/la/la.area",
                        email = user_email)

# Grabbing all the BLS Local Area Unemployment data for states that have a
# county in the Philly MSA or have a close by MSAs to Philly to combine into one data 
# frame. Data from: https://www.bls.gov/lau/data.htm flat files.

laus_pa_nj_de_md_dc_ny <- list_rbind(
  map(
    laus_pa_nj_de_md_dc_ny_urls, ~get_bls_data(.x, email = user_email)
  )
)

laus_pa_nj_de_md_dc_ny_parsed <- laus_pa_nj_de_md_dc_ny %>%
  mutate(seas_adj = str_sub(series_id, 3, 3),
         area_code = str_sub(series_id, 4, 18),
         fips_code = str_sub(series_id, 6, 10),
         measure_code = str_sub(series_id, 19, 20),
         date = base::as.Date(paste0(year, "-", str_sub(period, 2, 3), "-01")),
         value = as.numeric(value)) %>% 
  filter(!is.na(date)) %>%  # removing M13 period rows that are cannot be parsed because they are annual averages
  inner_join(la_area, by = "area_code")

philly_msa_laus_parsed <- laus_pa_nj_de_md_dc_ny_parsed %>%
  filter(area_code %in% philly_msa_counties_laus) %>%  
  mutate(area_text = str_remove(area_text, "/city")) %>%
  select(series_id, date, seas_adj, area_code, fips_code, area_text, measure_code, value)

max_philly_msa_laus_date <- max(philly_msa_laus_parsed$date)

# 1.  Latest unemployment rate for every county in Philly MSA
latest_philly_msa_unemp_long <- philly_msa_laus_parsed %>%
  filter(date == max_philly_msa_laus_date,
         measure_code == "03") %>%
  select(series_id, date, fips_code, area_text, value) %>%
  arrange(value)

econ_csv_write_out(latest_philly_msa_unemp_long, max_philly_msa_laus_date,
                   "data")

latest_philly_msa_unemp_dw <- latest_philly_msa_unemp_long %>%
  select(-c(series_id))

econ_csv_write_out(latest_philly_msa_unemp_dw, max_philly_msa_laus_date,
                   "visualizations")

# 2. Trendline of last twelve months of unemployment for every county in Philly MSA
last_year_philly_msa_unemp_long <- philly_msa_laus_parsed %>% 
  filter(between(date, max_philly_msa_laus_date %m-% months(12), max_philly_msa_laus_date),
         measure_code == "03") %>% 
  select(series_id, date, fips_code, area_text, value) %>%
  arrange(desc(date), desc(value))

econ_csv_write_out(last_year_philly_msa_unemp_long, max_philly_msa_laus_date,
                   "data")

last_year_philly_msa_unemp_dw <- last_year_philly_msa_unemp_long %>%
  select(date, area_text, value) %>% 
  pivot_wider(id_cols = date, names_from = area_text, values_from = value)

econ_csv_write_out(last_year_philly_msa_unemp_dw, max_philly_msa_laus_date,
                   "visualizations")
# 3. Latest Philly MSA unemployment vs. nearby MSAs (DC, Baltimore, Pittsburgh, NYC)
laus_msa_comp_parsed <- laus_pa_nj_de_md_dc_ny_parsed %>% 
  filter(area_code %in% msa_comparisons_laus) %>% 
  mutate(area_text = str_remove(area_text, "\\s+Metropolitan Statistical Area")) %>% 
  select(series_id, date, seas_adj, area_code, fips_code, area_text, measure_code, value)

max_msa_laus_date <- max(laus_msa_comp_parsed$date, na.rm = T)

latest_msa_comp_unemp_long <- laus_msa_comp_parsed %>%
  filter(date == max_msa_laus_date,
         measure_code == "03") %>%
  select(series_id, date, fips_code, area_text, value) %>%
  arrange(desc(value))

econ_csv_write_out(latest_msa_comp_unemp_long, max_msa_laus_date,
                   "data")

latest_msa_comp_unemp_dw <- latest_msa_comp_unemp_long %>%
  select(-c(series_id, fips_code))

econ_csv_write_out(latest_msa_comp_unemp_dw, max_msa_laus_date,
                   "visualizations")

# 4. Trendline of last twelve months of unemployment for Philly & four nearby MSAs (DC, Baltimore, Pittsburgh, NYC)
last_year_msa_comp_unemp_long <- laus_msa_comp_parsed %>% 
  filter(between(date, max_msa_laus_date %m-% months(12), max_msa_laus_date),
         measure_code == "03") %>% 
  select(series_id, date, fips_code, area_text, value) %>%
  arrange(desc(date), desc(value))

econ_csv_write_out(last_year_msa_comp_unemp_long, max_msa_laus_date,
                   "data")

last_year_msa_comp_unemp_dw <- last_year_msa_comp_unemp_long %>%
  select(date, area_text, value) %>%
  mutate(area_text = str_remove(str_remove(area_text, "-.*$"), ",.*$")) %>%
  pivot_wider(id_cols = date, names_from = area_text, values_from = value)

econ_csv_write_out(last_year_msa_comp_unemp_dw, max_msa_laus_date,
                   "visualizations")

# 5. Five six-digit NAICS industries with most job growth and loss in Philly MSA MoM annualized and YoY
# Grabbing all the BLS State and Metro Area Employment, Hours, and Earnings data for Pennsylvania
# to get Philly MSA YoY and MoM changes
# Data from: https://download.bls.gov/pub/time.series/sm/ flat files.

message("Grabbing BLS SAE data...")
sae_area <- get_bls_data("https://download.bls.gov/pub/time.series/sm/sm.area",
                         email = user_email)

sae_industry <- get_bls_data("https://download.bls.gov/pub/time.series/sm/sm.industry",
                             email = user_email)

sae_pa <- list_rbind(
  map(
    sae_pa_urls, ~get_bls_data(.x, email = user_email)
  )
)

sae_pa_parsed <- sae_pa %>%
  mutate(seas_adj = str_sub(series_id, 3, 3),
         state_code = str_sub(series_id, 4, 5),
         area_code = str_sub(series_id, 6, 10),
         supersector_code = str_sub(series_id, 11, 12),
         naics_code = str_sub(series_id, 13, 18),
         industry_code = str_sub(series_id, 11, 18),
         measure_code = str_sub(series_id, 19, 20),
         date = base::as.Date(paste0(year, "-", str_sub(period, 2, 3), "-01")),
         value = as.numeric(value)) %>% 
  filter(!is.na(date)) %>%  # removing M13 period rows that are cannot be parsed because they are annual averages
  inner_join(sae_area, by = "area_code") %>% 
  inner_join(sae_industry, by = "industry_code")

philly_msa_sae_parsed <- sae_pa_parsed %>%
  filter(area_code == "37980") %>%  
  select(series_id, date, seas_adj, area_code, supersector_code, 
         naics_code, area_name, industry_name, measure_code, value)

max_philly_msa_sae_date <- max(philly_msa_sae_parsed$date)

philly_msa_emp_yoy_chg_long <- philly_msa_sae_parsed %>% 
  filter(measure_code == "01", naics_code == "000000", seas_adj == "U",
         date %in% c(max_philly_msa_sae_date, max_philly_msa_sae_date %m-% months(12))) %>% 
  arrange(series_id, desc(date)) %>% 
  group_by(series_id) %>% 
  mutate(yoy_chg = ((value / lead(value)) - 1) * 100,
         value = value * 1000) %>% 
  ungroup() %>% 
  filter(date != min(date)) %>% 
  rename(employment = value) %>% 
  select(series_id, date, area_code, area_name, industry_name, employment, yoy_chg) %>% 
  arrange(desc(yoy_chg))

econ_csv_write_out(philly_msa_emp_yoy_chg_long, max_philly_msa_sae_date,
                   "data")

philly_msa_emp_yoy_chg_dw <- philly_msa_emp_yoy_chg_long %>%
  select(date, industry_name, yoy_chg) %>% 
  mutate(change_direction = if_else(yoy_chg > 0, "Increase", "Decrease"))

econ_csv_write_out(philly_msa_emp_yoy_chg_dw, max_philly_msa_sae_date,
                   "visualizations")

### Datawrapper Updates ###
if (!(nzchar(dw_api_key))) {
  message("No Datawrapper API key specified. Set environment variable DW_API_KEY to valid Datawrapper API key and run again to update visualizations")
} else {
  # Reformatting latest data dates
  max_philly_msa_laus_date_dw <- format(max_philly_msa_laus_date, "%b. '%y")
  max_msa_laus_date_dw <- format(max_msa_laus_date, "%b. '%y")
  max_philly_msa_sae_date_dw <- format(max_philly_msa_sae_date, "%b. '%y")
  
  # Updating chart titled Unemployment Rate in the Philadelphia Metro Area
  republish_chart(API_KEY = dw_api_key,
                  chartID = "OtFCg",
                  data = latest_philly_msa_unemp_dw,
                  subtitle = paste0("By county in ", max_philly_msa_laus_date_dw),
                  notes = "Data is preliminary and not seasonally adjusted."
                  )
  
  # Updating chart titled The Last Year of Unemployment in the Philadelphia Metro Area
  republish_chart(API_KEY = dw_api_key,
                  chartID = "KoeMM",
                  data = last_year_philly_msa_unemp_dw,
                  subtitle = paste0("By county as of ", max_philly_msa_laus_date_dw),
                  notes = "Data from latest month is preliminary and all data are not seasonally adjusted."
  )
  
  # Updating chart titled Latest Unemployment Rate in Metro Areas Near Philadelphia
  republish_chart(API_KEY = dw_api_key,
                  chartID = "uKAnw",
                  data = latest_msa_comp_unemp_dw,
                  subtitle = paste0("As of ", max_msa_laus_date_dw),
                  notes = "Data is preliminary and not seasonally adjusted."
  )
  
  # Updating chart titled The Last Year of Unemployment in Metro Areas Near Philadelphia
  republish_chart(API_KEY = dw_api_key,
                  chartID = "nwJmd",
                  data = last_year_msa_comp_unemp_dw,
                  notes = "Data is for respective Metropolitan Statistical Area (MSA) as defined by OMB. Data from latest month is preliminary and all data are not seasonally adjusted."
  )
  
  # Updating chart titled Yearly Change in Employment for Philadelphia Metro
  republish_chart(API_KEY = dw_api_key,
                  chartID = "zoxrC",
                  data = philly_msa_emp_yoy_chg_dw,
                  subtitle = paste0("By sector as of ", max_philly_msa_sae_date_dw),
                  notes = "Data is preliminary and not seasonally adjusted for the Philadelphia-Camden-Wilmington, PA-NJ-DE-MD MSA by NAICS sector."
  )
}



