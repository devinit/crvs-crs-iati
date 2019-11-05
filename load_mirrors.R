list.of.packages <- c("data.table")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages, repos="http://cran.us.r-project.org")
lapply(list.of.packages, require, character.only=T)

script.dir = "/home/alex/git/crvs-crs-iati"
setwd(script.dir)

crs_path = "raw_data/Crs_latest"

file_vec <- list.files(path = crs_path,pattern = "*.txt",full.names = TRUE,recursive = FALSE);
crs_field_types = c(
  "integer",
  "integer",
  "text",
  "integer",
  "text",
  "text",
  "text",
  "integer",
  "integer",
  "text",
  "integer",
  "text",
  "integer",
  "text",
  "integer",
  "text",
  "integer",
  "integer",
  "integer",
  "text",
  "float8",
  "float8",
  "float8",
  "float8",
  "float8",
  "float8",
  "float8",
  "float8",
  "float8",
  "float8",
  "float8",
  "float8",
  "float8",
  "float8",
  "float8",
  "float8",
  "float8",
  "float8",
  "integer",
  "float8",
  "float8",
  "float8",
  "float8",
  "text",
  "text",
  "integer",
  "text",
  "integer",
  "text",
  "integer",
  "text",
  "text",
  "integer",
  "text",
  "text",
  "text",
  "text",
  "integer",
  "integer",
  "integer",
  "integer",
  "integer",
  "integer",
  "integer",
  "integer",
  "integer",
  "integer",
  "integer",
  "integer",
  "text",
  "integer",
  "integer",
  "text",
  "float8",
  "text",
  "text",
  "float8",
  "float8",
  "float8",
  "float8",
  "float8",
  "bool",
  "bool",
  "integer",
  "integer",
  "float8"
)
names(crs_field_types) = c(
  "year"
  ,"donor_code"
  ,"donor_name"
  ,"agency_code"
  ,"agency_name"
  ,"crs_id"
  ,"project_number"
  ,"initial_report"
  ,"recipient_code"
  ,"recipient_name"
  ,"region_code"
  ,"region_name"
  ,"income_group_code"
  ,"income_group_name"
  ,"flow_code"
  ,"flow_name"
  ,"bilateral_multilateral"
  ,"category"
  ,"finance_type"
  ,"aid_type"
  ,"usd_commitment"
  ,"usd_disbursement"
  ,"usd_received"
  ,"usd_commitment_deflated"
  ,"usd_disbursement_deflated"
  ,"usd_received_deflated"
  ,"usd_adjustment"
  ,"usd_adjustment_deflated"
  ,"usd_amount_untied"
  ,"usd_amount_partial_tied"
  ,"usd_amount_tied"
  ,"usd_amount_untied_deflated"
  ,"usd_amount_partial_tied_deflated"
  ,"usd_amount_tied_deflated"
  ,"usd_irtc"
  ,"usd_expert_commitment"
  ,"usd_expert_extended"
  ,"usd_export_credit"
  ,"currency_code"
  ,"commitment_national"
  ,"disbursement_national"
  ,"grant_equivalent" # Guessed column name
  ,"usd_grant_equivalent"
  ,"short_description"
  ,"project_title"
  ,"purpose_code"
  ,"purpose_name"
  ,"sector_code"
  ,"sector_name"
  ,"channel_code"
  ,"channel_name"
  ,"channel_reported_name"
  ,"channel_parent_category" # Guessed column name
  ,"geography"
  ,"expected_start_date"
  ,"completion_date"
  ,"long_description"
  ,"gender"
  ,"environment"
  ,"trade"
  ,"pdgg"
  ,"ftc"
  ,"pba"
  ,"investment_project"
  ,"associated_finance"
  ,"biodiversity"
  ,"climate_mitigation"
  ,"climate_adaptation"
  ,"desertification"
  ,"commitment_date"
  ,"type_repayment"
  ,"number_repayment"
  ,"interest_1"
  ,"interest_2"
  ,"repay_date_1"
  ,"repay_date_2"
  ,"grant_element"
  ,"usd_interest"
  ,"usd_outstanding"
  ,"usd_arrears_principal"
  ,"usd_arrears_interest"
  ,"usd_future_debt_service_principal"
  ,"usd_future_debt_service_interest"
  ,"rmnch"
  ,"budget_identifier"
  ,"capital_expenditure"
)

crs_list = list()
crs_index = 1

for(txt in file_vec){
  message(txt)
  dataChunk = read.delim(txt, header=T, sep="|", as.is=T, na.strings=c("\032",""),quote="")
  names(dataChunk) = names(crs_field_types)
  crs_list[[crs_index]] = dataChunk
  crs_index = crs_index + 1
}

crs  = rbindlist(crs_list)
save(crs,file="raw_data/crs.RData")

  

