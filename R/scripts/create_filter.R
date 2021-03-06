library(magrittr)
library(dplyr)
library(readr)
library(tidyr)
library(purrr)

option_list = list(
  optparse::make_option(c("-c", "--config"), action="store", default=Sys.getenv("CONFIG_PATH"), type='character', help="path to the config file")
)

opts = optparse::parse_args(optparse::OptionParser(option_list=option_list))

config <- covidcommon::load_config(opts$c)
if (is.na(config)) {
  stop("no configuration found -- please set CONFIG_PATH environment variable or use the -c command flag")
}


incid_data_list <- covidImportation::get_incidence_data(
  first_date = ISOdate(2019,12,1),
  last_date = as.POSIXct(lubridate::ymd(config$end_date)),
  update_case_data = TRUE,
  case_data_dir = file.path('importation',config$spatial_setup$setup_name,"case_data"),
  check_saved_data=TRUE,
  save_data=TRUE
)
jhucsse <- incid_data_list$jhucsse_case_data

all_times <- lubridate::ymd(config$start_date) +
  seq_len(lubridate::ymd(config$end_date) - lubridate::ymd(config$start_date))

geodata <- report.generation:::load_geodata_file(file.path(config$spatial_setup$base_path,config$spatial_setup$geodata),5,'0',TRUE)

all_geoids <- geodata[[config$spatial_setup$nodenames]]

all_loc_df <- dplyr::tibble(
  Update = all_times[1],
  FIPS = all_geoids,
  Confirmed = 0
)

all_time_df <- dplyr::tibble(
  Update = all_times,
  FIPS = all_geoids[1],
  Confirmed = 0
)

cumulative_cases <- jhucsse %>%
  dplyr::filter(FIPS %in% all_geoids) %>%
  dplyr::select(Update, FIPS, Confirmed)

cumulative_cases$Update <- as.Date(cumulative_cases$Update)

all_data <- dplyr::bind_rows(
  all_loc_df,
  all_time_df,
  cumulative_cases
)

all_data <- all_data %>% arrange(FIPS,Update) %>% pivot_wider(Update,names_from=FIPS,values_from=Confirmed,values_fn=list(Confirmed=function(x){max(x,na.rm=T)}),values_fill=c(Confirmed=0)) %>% arrange(Update)

for(name in names(all_data)[-1]){
  all_data[[name]] <- cummax(all_data[[name]])
}

all_data <- all_data %>% dplyr::filter(
  Update %in% all_times
)

write.table(all_data[,-1],file=file.path(config$dynfilter_path),row.names=FALSE,col.names=FALSE)

