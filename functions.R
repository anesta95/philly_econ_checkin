### FUNCTIONS ###
get_bls_data <- function(url, email) {
  bls_res <- GET(url = url, user_agent(email))
  stop_for_status(bls_res)
  
  bls_content <- content(bls_res, 
                         as = "parsed",
                         type = "text/tab-separated-values",
                         encoding = "UTF-8",
                         col_names = T,
                         col_types = cols(.default = col_character()),
                         trim_ws = T
  )
  return(bls_content)
  
}

econ_csv_write_out <- function(dataframe, date, folder) {
  filename <- paste0(folder, "/", date, "_", as_name(enquo(dataframe)), ".csv")
  
  write_csv(x = dataframe, file = filename)
  
  on.exit(expr = message(paste("Writing out", filename)), add = T)
}

republish_chart <- function(API_KEY, chartID, data, subtitle = NULL, 
                            title = NULL, colors = NULL, 
                            tooltip = NULL, legend = NULL, 
                            axes = NULL, notes) {
  
  # PUT request to refresh data as per: https://developer.datawrapper.de/reference/putchartsiddata
  dataRefresh <- PUT(url = paste0("https://api.datawrapper.de/v3/charts/", 
                                  chartID, "/data"),
                     add_headers(authorization = paste("Bearer", 
                                                       API_KEY, 
                                                       sep = " ")),
                     body = format_csv(data))
  
  call_back <- list(metadata = list())
  
  # This section adds chart title, subtitle, colors, tooltip, legend, and axes, if needed
  if (!is.null(title)) {
    call_back$title <- title
  }
  
  if (!is.null(subtitle)) {
    call_back$metadata$describe$intro <- subtitle   
  }
  
  if (!is.null(colors)) {
    call_back$metadata$visualize$`custom-colors` <- colors
  }
  
  if (!is.null(tooltip)) {
    call_back$metadata$visualize$tooltip <- tooltip
  }
  
  if (!is.null(legend)) {
    call_back$metadata$visualize$legend <- legend
  }
  
  if (!is.null(axes)) {
    call_back$metadata$axes <- axes
  }
  
  # Typically I always need to update the caption, but this can be 
  # moved to a conditional
  call_back$metadata$annotate$notes <- notes
  
  # PATCH request to update chart properties as per
  # https://developer.datawrapper.de/reference/patchchartsid
  notesRes <- PATCH(url = paste0("https://api.datawrapper.de/v3/charts/", 
                                 chartID),
                    add_headers(authorization = paste("Bearer", API_KEY, 
                                                      sep = " ")),
                    body = call_back,
                    encode = "json")
  
  # POST request to republish chart
  # https://developer.datawrapper.de/reference/postchartsidpublish
  publishRes <- POST(
    url = paste0("https://api.datawrapper.de/v3/charts/", 
                 chartID, "/publish"),
    add_headers(authorization = paste("Bearer", 
                                      API_KEY, 
                                      sep = " "))
  )
  
  list(dataRefresh, notesRes, publishRes) -> resList
  
  # Check for errors
  if (any(map_lgl(resList, http_error))) {
    which(map_lgl(resList, http_error))[1] -> errorIdx
    
    stop_for_status(resList[[errorIdx]], task = paste0("update step ",
                                                       errorIdx, 
                                                       " of chart ", 
                                                       chartID))
    
  } else {
    message(paste0("Chart ", chartID, " updated successfully"))
  }
  
}

### OBJECTS ###
philly_msa_counties_laus <- c(
  "CN3400500000000",
  "CN3400700000000",
  "CN3401500000000",
  "CN3403300000000",
  "CN4201700000000",
  "CN4202900000000",
  "CN4204500000000",
  "CN4209100000000",
  "CN4210100000000",
  "CN1000300000000",
  "CN2401500000000"
)

msa_comparisons_laus <- c(
  "MT4237980000000",
  "MT1147900000000",
  "MT2412580000000",
  "MT3635620000000",
  "MT4238300000000"
)

laus_pa_nj_de_md_dc_ny_urls <- c(
  "https://download.bls.gov/pub/time.series/la/la.data.15.DC",
  "https://download.bls.gov/pub/time.series/la/la.data.14.Delaware",
  "https://download.bls.gov/pub/time.series/la/la.data.27.Maryland",
  "https://download.bls.gov/pub/time.series/la/la.data.37.NewJersey",
  "https://download.bls.gov/pub/time.series/la/la.data.45.Pennsylvania",
  "https://download.bls.gov/pub/time.series/la/la.data.39.NewYork"
)

sae_pa_urls <- c(
  "https://download.bls.gov/pub/time.series/sm/sm.data.39a.Pennsylvania",
  "https://download.bls.gov/pub/time.series/sm/sm.data.39b.Pennsylvania"
)

user_email <- Sys.getenv("USER_EMAIL")

### You will need to set an environment variable named USER_EMAIL with ###
### your valid email in order for httr calls to BLS data to succeed. ###
### Or enter an email in the while loop below. ###

while(!(grepl(pattern = "^[[:alnum:].-_]+@[[:alnum:].-]+$", x = user_email))) {
  
  message("Enter a valid email so BLS data can be programmatically accessed.\nSee more info at https://www.bls.gov/bls/pss.htm.\nAlternatively stop this script and set a USER_EMAIL environment variable with a valid email: ")
  input_email <- readLines(con = "stdin", n = 1)
  
  user_email <- input_email
  
}

dw_api_key <- Sys.getenv("DW_API_KEY")
### You will need to set an environment variable named DW_API_KEY with ###
### your valid Datawrapper API key in order for httr calls to Datawrapper API to succeed. ###
### Create one here: https://app.datawrapper.de/account/api-tokens ###

