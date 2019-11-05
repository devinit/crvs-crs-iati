list.of.packages <- c("data.table")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages, repos="http://cran.us.r-project.org")
lapply(list.of.packages, require, character.only=T)

script.dir = "/home/alex/git/crvs-crs-iati"
setwd(script.dir)

load("raw_data/crs.RData")


# Output required
# Activity Id
# Donor
# Implementer
# Recipient Country
# Transaction Year
# Commitment
# Expenditure
# Title
# Description
keep = c(
  "project_number",
  "donor_name",
  "agency_name",
  "recipient_name",
  "year",
  "purpose_code",
  "usd_commitment",
  "usd_disbursement",
  "project_title",
  "short_description",
  "long_description"
)

crs$text_search = paste(
  crs$project_title,
  crs$short_description,
  crs$long_description
)
# 
# 1. CRVS
# 
# Sector
# CRS Purpose Code = 13010
crvs = subset(
  crs,
  purpose_code == 13010
)
# IATI only: UNICEF PDB Code (Reporting-Org = XM-DAC- 41122 Sector Vocabulary=99 Code=23-03-04)
# Title or description
# CRVS
# civil registration
# vital statistics
# vital event
# birth AND registration
# birth AND registry
# birth AND notification
# death AND registration
# death AND registry
# population register
crvs = subset(
  crvs,
  grepl(pattern="crvs",x=text_search,ignore.case=T,useBytes=T) |
  grepl(pattern="civil registration",x=text_search,ignore.case=T,useBytes=T) |
  grepl(pattern="vital statistics",x=text_search,ignore.case=T,useBytes=T) |
  grepl(pattern="vital event",x=text_search,ignore.case=T,useBytes=T) |
  (grepl(pattern="birth",x=text_search,ignore.case=T,useBytes=T) & grepl(pattern="registration",x=text_search,ignore.case=T,useBytes=T)) |
  (grepl(pattern="birth",x=text_search,ignore.case=T,useBytes=T) & grepl(pattern="registry",x=text_search,ignore.case=T,useBytes=T)) |
  (grepl(pattern="birth",x=text_search,ignore.case=T,useBytes=T) & grepl(pattern="notification",x=text_search,ignore.case=T,useBytes=T)) |
  (grepl(pattern="death",x=text_search,ignore.case=T,useBytes=T) & grepl(pattern="registration",x=text_search,ignore.case=T,useBytes=T)) |
  (grepl(pattern="death",x=text_search,ignore.case=T,useBytes=T) & grepl(pattern="registry",x=text_search,ignore.case=T,useBytes=T)) |
  grepl(pattern="population register",x=text_search,ignore.case=T,useBytes=T)
)
# 
# 2. Identity
# 
# Sector
# CRS Purpose Code = 13010 (same as CRVS)
# identity = subset(
#   crs,
#   purpose_code == 13010
# )
identity = copy(crs)
# IATI Only: World Bank Theme (Reporting-org=44000 Sector Vocabulary=98 Code=000434)
# Title or description
# national identity
# national identification
# national ID
# legal identity
# legal ID
# digital identity
# digital ID
# ID4D
identity = subset(
  identity,
  grepl(pattern="national identity",x=text_search,ignore.case=T,useBytes=T) |
    grepl(pattern="national identification",x=text_search,ignore.case=T,useBytes=T) |
    grepl(pattern="national ID",x=text_search,ignore.case=T,useBytes=T) |
    grepl(pattern="legal identity",x=text_search,ignore.case=T,useBytes=T) |
    grepl(pattern="legal ID",x=text_search,ignore.case=T,useBytes=T) |
    grepl(pattern="digital identity",x=text_search,ignore.case=T,useBytes=T) |
    grepl(pattern="digital ID",x=text_search,ignore.case=T,useBytes=T) |
    grepl(pattern="ID4D",x=text_search,ignore.case=T,useBytes=T)
)
# 
# 3. Electoral Register
# 
# Sector
# CRS Purpose Code = 15151
electoral = subset(
  crs,
  purpose_code == 15151
)
# Title or description
# electoral AND register
# election AND management
# electoral AND management
# voter registration
electoral = subset(
  electoral,
    (grepl(pattern="electoral",x=text_search,ignore.case=T,useBytes=T) & grepl(pattern="register",x=text_search,ignore.case=T,useBytes=T)) |
    (grepl(pattern="election",x=text_search,ignore.case=T,useBytes=T) & grepl(pattern="management",x=text_search,ignore.case=T,useBytes=T)) |
    (grepl(pattern="electoral",x=text_search,ignore.case=T,useBytes=T) & grepl(pattern="management",x=text_search,ignore.case=T,useBytes=T)) |
    grepl(pattern="voter registration",x=text_search,ignore.case=T,useBytes=T)
)


crvs = crvs[,keep,with=F]
identity = identity[,keep,with=F]
electoral = electoral[,keep,with=F]

fwrite(crvs,"formatted_data/crs_crvs.csv")
fwrite(identity, "formatted_data/crs_identity.csv")
fwrite(electoral, "formatted_data/crs_electoral.csv")
