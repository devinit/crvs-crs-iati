list.of.packages <- c("data.table","httr","jsonlite","curl")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages, repos="http://cran.us.r-project.org")
lapply(list.of.packages, require, character.only=T)

script.dir = "/home/alex/git/crvs-crs-iati"
setwd(script.dir)

httr::set_config(httr::config(http_version = 0))

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

# 
# 1. CRVS
# 
# Sector
# CRS Purpose Code = 13010
# IATI only: UNICEF PDB Code (Reporting-Org = XM-DAC- 41122 Sector Vocabulary=99 Code=23-03-04)
crvs_list = list()
crvs_index = 1
next_uri = paste0(
  "https://datastore.iati.cloud/api/activities/",
  "?reporting_organisation_identifier=XM-DAC-41122",
  # "&sector_vocabulary=99",
  "&sector=23-03-04",
  "&format=json",
  "&page_size=20",
  "&has_recipient_country=True",
  "&fields=",
  paste0(
    "iati_identifier,",
    "participating_organisations,",
    "transactions,",
    "title,",
    "descriptions,",
    "recipient_countries,",
    "reporting_organisation"
  )
)
while(!is.null(next_uri)){
  activities_raw = content(GET(
    next_uri
  ))
  
  results = activities_raw["results"][[1]]
  for(result in results){
    if(length(result$reporting_organisation$narratives)>0){
      reporting_organisation = result$reporting_organisation$narratives[[1]]$text
    }else{
      reporting_organisation = ""
    }
    if(length(result$title$narratives)>0){
      title = result$title$narratives[[1]]$text
    }else{
      title = ""
    }
    descriptions = result$descriptions
    description = ""
    for(desc in descriptions){
      if(length(desc$narratives)>0){
        description = paste(description,desc$narratives[[1]]$text)  
      }
    }
    text_search = paste(title, description)
    
    crvs_match = TRUE
    if(crvs_match){
      iati_identifier = result$iati_identifier
      part_orgs = result$participating_organisations
      donor_names = c()
      implementing_names = c()
      for(part_org in part_orgs){
        if(part_org$role$name == "Funding"){
          if(length(part_org$narratives)>0){
            donor_names = c(donor_names,part_org$narratives[[1]]$text)
          }
        }
        if(part_org$role$name == "Implementing"){
          if(length(part_org$narratives)>0){
            implementing_names = c(implementing_names,part_org$narratives[[1]]$text)
          }
        }
      }
      donor_name = paste(donor_names,collapse=";")
      implementing_name = paste(implementing_names,collapse=";")
      
      recipient_countries = result$recipient_countries
      activity_recipient = ""
      for(recipient_country in recipient_countries){
        if(!is.null(recipient_country$percentage)){
          if(recipient_country$percentage == 100){
            activity_recipient = recipient_country$country$name
          } 
        }
      }
      
      transactions_uri = result$transactions
      while(!is.null(transactions_uri)){
        transactions_raw = content(GET(
          transactions_uri
        ))
        
        transactions = transactions_raw["results"][[1]]
        for(transaction in transactions){
          transaction_recipient = ""
          if(!is.null(transaction$recipient_country)){
            transaction_recipient = transaction$recipient_country$country$name
          }
          trans_df = data.frame(
            reporting_organisation,
            iati_identifier,
            donor_name,
            implementing_name,
            title,
            description,
            activity_recipient,
            transaction_recipient,
            year = substr(transaction$transaction_date, 1, 4),
            value = transaction$value,
            currency = transaction$currency$name,
            transaction_type = transaction$transaction_type$name
          )
          crvs_list[[crvs_index]] = trans_df
          crvs_index = crvs_index + 1
        }
        transactions_uri = transactions_raw["next"][[1]]
      }
    }
  }
  
  next_uri = activities_raw["next"][[1]]
  message(next_uri)
}
next_uri = paste0(
  "https://datastore.iati.cloud/api/activities/",
  "?sector_vocabulary=1",
  "&sector=13010",
  "&format=json",
  "&page_size=20",
  "&has_recipient_country=True",
  "&fields=",
  paste0(
    "iati_identifier,",
    "participating_organisations,",
    "transactions,",
    "title,",
    "descriptions,",
    "recipient_countries,",
    "reporting_organisation"
  )
)
while(!is.null(next_uri)){
  activities_raw = content(GET(
    next_uri
  ))
  
  results = activities_raw["results"][[1]]
  for(result in results){
    if(length(result$reporting_organisation$narratives)>0){
      reporting_organisation = result$reporting_organisation$narratives[[1]]$text
    }else{
      reporting_organisation = ""
    }
    if(length(result$title$narratives)>0){
      title = result$title$narratives[[1]]$text
    }else{
      title = ""
    }
    descriptions = result$descriptions
    description = ""
    for(desc in descriptions){
      if(length(desc$narratives)>0){
        description = paste(description,desc$narratives[[1]]$text)  
      }
    }
    text_search = paste(title, description)
    
    crvs_match = grepl(pattern="crvs",x=text_search,ignore.case=T,useBytes=T) |
      grepl(pattern="civil registration",x=text_search,ignore.case=T,useBytes=T) |
      grepl(pattern="vital statistics",x=text_search,ignore.case=T,useBytes=T) |
      grepl(pattern="vital event",x=text_search,ignore.case=T,useBytes=T) |
      (grepl(pattern="birth",x=text_search,ignore.case=T,useBytes=T) & grepl(pattern="registration",x=text_search,ignore.case=T,useBytes=T)) |
      (grepl(pattern="birth",x=text_search,ignore.case=T,useBytes=T) & grepl(pattern="registry",x=text_search,ignore.case=T,useBytes=T)) |
      (grepl(pattern="birth",x=text_search,ignore.case=T,useBytes=T) & grepl(pattern="notification",x=text_search,ignore.case=T,useBytes=T)) |
      (grepl(pattern="death",x=text_search,ignore.case=T,useBytes=T) & grepl(pattern="registration",x=text_search,ignore.case=T,useBytes=T)) |
      (grepl(pattern="death",x=text_search,ignore.case=T,useBytes=T) & grepl(pattern="registry",x=text_search,ignore.case=T,useBytes=T)) |
      grepl(pattern="population register",x=text_search,ignore.case=T,useBytes=T)
    if(crvs_match){
      iati_identifier = result$iati_identifier
      part_orgs = result$participating_organisations
      donor_names = c()
      implementing_names = c()
      for(part_org in part_orgs){
        if(part_org$role$name == "Funding"){
          if(length(part_org$narratives)>0){
            donor_names = c(donor_names,part_org$narratives[[1]]$text)
          }
        }
        if(part_org$role$name == "Implementing"){
          if(length(part_org$narratives)>0){
            implementing_names = c(implementing_names,part_org$narratives[[1]]$text)
          }
        }
      }
      donor_name = paste(donor_names,collapse=";")
      implementing_name = paste(implementing_names,collapse=";")
      
      recipient_countries = result$recipient_countries
      activity_recipient = ""
      for(recipient_country in recipient_countries){
        if(!is.null(recipient_country$percentage)){
          if(recipient_country$percentage == 100){
            activity_recipient = recipient_country$country$name
          } 
        }
      }
      
      transactions_uri = result$transactions
      while(!is.null(transactions_uri)){
        transactions_raw = content(GET(
          transactions_uri
        ))
        
        transactions = transactions_raw["results"][[1]]
        for(transaction in transactions){
          transaction_recipient = ""
          if(!is.null(transaction$recipient_country)){
            transaction_recipient = transaction$recipient_country$country$name
          }
          trans_df = data.frame(
            reporting_organisation,
            iati_identifier,
            donor_name,
            implementing_name,
            title,
            description,
            activity_recipient,
            transaction_recipient,
            year = substr(transaction$transaction_date, 1, 4),
            value = transaction$value,
            currency = transaction$currency$name,
            transaction_type = transaction$transaction_type$name
          )
          crvs_list[[crvs_index]] = trans_df
          crvs_index = crvs_index + 1
        }
        transactions_uri = transactions_raw["next"][[1]]
      }
    }
  }
  
  next_uri = activities_raw["next"][[1]]
  message(next_uri)
}
crvs = rbindlist(crvs_list)
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
# 
# 2. Identity
# 
# Sector
# CRS Purpose Code = 13010 (same as CRVS)
# IATI Only: World Bank Theme (Reporting-org=44000 Sector Vocabulary=98 Code=000434)
identity_list = list()
identity_index = 1
next_uri = paste0(
  "https://datastore.iati.cloud/api/activities/",
  "?reporting_organisation_identifier=44000",
  "&sector_vocabulary=98",
  "&sector=000434",
  "&format=json",
  "&page_size=20",
  "&has_recipient_country=True",
  "&fields=",
  paste0(
    "iati_identifier,",
    "participating_organisations,",
    "transactions,",
    "title,",
    "descriptions,",
    "recipient_countries,",
    "reporting_organisation"
  )
)
while(!is.null(next_uri)){
  activities_raw = content(GET(
    next_uri
  ))
  
  results = activities_raw["results"][[1]]
  for(result in results){
    if(length(result$reporting_organisation$narratives)>0){
      reporting_organisation = result$reporting_organisation$narratives[[1]]$text
    }else{
      reporting_organisation = ""
    }
    if(length(result$title$narratives)>0){
      title = result$title$narratives[[1]]$text
    }else{
      title = ""
    }
    descriptions = result$descriptions
    description = ""
    for(desc in descriptions){
      if(length(desc$narratives)>0){
        description = paste(description,desc$narratives[[1]]$text)  
      }
    }
    text_search = paste(title, description)
    
    identity_match = TRUE
    if(identity_match){
      iati_identifier = result$iati_identifier
      part_orgs = result$participating_organisations
      donor_names = c()
      implementing_names = c()
      for(part_org in part_orgs){
        if(part_org$role$name == "Funding"){
          if(length(part_org$narratives)>0){
            donor_names = c(donor_names,part_org$narratives[[1]]$text)
          }
        }
        if(part_org$role$name == "Implementing"){
          if(length(part_org$narratives)>0){
            implementing_names = c(implementing_names,part_org$narratives[[1]]$text)
          }
        }
      }
      donor_name = paste(donor_names,collapse=";")
      implementing_name = paste(implementing_names,collapse=";")
      
      recipient_countries = result$recipient_countries
      activity_recipient = ""
      for(recipient_country in recipient_countries){
        if(!is.null(recipient_country$percentage)){
          if(recipient_country$percentage == 100){
            activity_recipient = recipient_country$country$name
          } 
        }
      }
      
      transactions_uri = result$transactions
      while(!is.null(transactions_uri)){
        transactions_raw = content(GET(
          transactions_uri
        ))
        
        transactions = transactions_raw["results"][[1]]
        for(transaction in transactions){
          transaction_recipient = ""
          if(!is.null(transaction$recipient_country)){
            transaction_recipient = transaction$recipient_country$country$name
          }
          trans_df = data.frame(
            reporting_organisation,
            iati_identifier,
            donor_name,
            implementing_name,
            title,
            description,
            activity_recipient,
            transaction_recipient,
            year = substr(transaction$transaction_date, 1, 4),
            value = transaction$value,
            currency = transaction$currency$name,
            transaction_type = transaction$transaction_type$name
          )
          identity_list[[identity_index]] = trans_df
          identity_index = identity_index + 1
        }
        transactions_uri = transactions_raw["next"][[1]]
      }
    }
  }
  
  next_uri = activities_raw["next"][[1]]
  message(next_uri)
}
next_uri = paste0(
  "https://datastore.iati.cloud/api/activities/",
  "?sector_vocabulary=1",
  "&sector=13010",
  "&format=json",
  "&page_size=20",
  "&has_recipient_country=True",
  "&fields=",
  paste0(
    "iati_identifier,",
    "participating_organisations,",
    "transactions,",
    "title,",
    "descriptions,",
    "recipient_countries,",
    "reporting_organisation"
  )
)
while(!is.null(next_uri)){
  activities_raw = content(GET(
    next_uri
  ))
  
  results = activities_raw["results"][[1]]
  for(result in results){
    if(length(result$reporting_organisation$narratives)>0){
      reporting_organisation = result$reporting_organisation$narratives[[1]]$text
    }else{
      reporting_organisation = ""
    }
    if(length(result$title$narratives)>0){
      title = result$title$narratives[[1]]$text
    }else{
      title = ""
    }
    descriptions = result$descriptions
    description = ""
    for(desc in descriptions){
      if(length(desc$narratives)>0){
        description = paste(description,desc$narratives[[1]]$text)  
      }
    }
    text_search = paste(title, description)
    
    identity_match = grepl(pattern="national identity",x=text_search,ignore.case=T,useBytes=T) |
      grepl(pattern="national identification",x=text_search,ignore.case=T,useBytes=T) |
      grepl(pattern="national ID",x=text_search,ignore.case=T,useBytes=T) |
      grepl(pattern="legal identity",x=text_search,ignore.case=T,useBytes=T) |
      grepl(pattern="legal ID",x=text_search,ignore.case=T,useBytes=T) |
      grepl(pattern="digital identity",x=text_search,ignore.case=T,useBytes=T) |
      grepl(pattern="digital ID",x=text_search,ignore.case=T,useBytes=T) |
      grepl(pattern="ID4D",x=text_search,ignore.case=T,useBytes=T)
    if(identity_match){
      iati_identifier = result$iati_identifier
      part_orgs = result$participating_organisations
      donor_names = c()
      implementing_names = c()
      for(part_org in part_orgs){
        if(part_org$role$name == "Funding"){
          if(length(part_org$narratives)>0){
            donor_names = c(donor_names,part_org$narratives[[1]]$text)
          }
        }
        if(part_org$role$name == "Implementing"){
          if(length(part_org$narratives)>0){
            implementing_names = c(implementing_names,part_org$narratives[[1]]$text)
          }
        }
      }
      donor_name = paste(donor_names,collapse=";")
      implementing_name = paste(implementing_names,collapse=";")
      
      recipient_countries = result$recipient_countries
      activity_recipient = ""
      for(recipient_country in recipient_countries){
        if(!is.null(recipient_country$percentage)){
          if(recipient_country$percentage == 100){
            activity_recipient = recipient_country$country$name
          } 
        }
      }
      
      transactions_uri = result$transactions
      while(!is.null(transactions_uri)){
        transactions_raw = content(GET(
          transactions_uri
        ))
        
        transactions = transactions_raw["results"][[1]]
        for(transaction in transactions){
          transaction_recipient = ""
          if(!is.null(transaction$recipient_country)){
            transaction_recipient = transaction$recipient_country$country$name
          }
          trans_df = data.frame(
            reporting_organisation,
            iati_identifier,
            donor_name,
            implementing_name,
            title,
            description,
            activity_recipient,
            transaction_recipient,
            year = substr(transaction$transaction_date, 1, 4),
            value = transaction$value,
            currency = transaction$currency$name,
            transaction_type = transaction$transaction_type$name
          )
          identity_list[[identity_index]] = trans_df
          identity_index = identity_index + 1
        }
        transactions_uri = transactions_raw["next"][[1]]
      }
    }
  }
  
  next_uri = activities_raw["next"][[1]]
  message(next_uri)
}
identity = rbindlist(identity_list)
# Title or description
# national identity
# national identification
# national ID
# legal identity
# legal ID
# digital identity
# digital ID
# ID4D
# 
# 3. Electoral Register
# 
# Sector
# CRS Purpose Code = 15151
electoral_list = list()
electoral_index = 1
next_uri = paste0(
  "https://datastore.iati.cloud/api/activities/",
  "?sector_vocabulary=1",
  "&sector=15151",
  "&format=json",
  "&page_size=20",
  "&has_recipient_country=True",
  "&fields=",
  paste0(
    "iati_identifier,",
    "participating_organisations,",
    "transactions,",
    "title,",
    "descriptions,",
    "recipient_countries,",
    "reporting_organisation"
  )
)
while(!is.null(next_uri)){
  activities_raw = content(GET(
    next_uri
  ))
  
  results = activities_raw["results"][[1]]
  for(result in results){
    if(length(result$reporting_organisation$narratives)>0){
      reporting_organisation = result$reporting_organisation$narratives[[1]]$text
    }else{
      reporting_organisation = ""
    }
    if(length(result$title$narratives)>0){
      title = result$title$narratives[[1]]$text
    }else{
      title = ""
    }
    descriptions = result$descriptions
    description = ""
    for(desc in descriptions){
      if(length(desc$narratives)>0){
        description = paste(description,desc$narratives[[1]]$text)  
      }
    }
    text_search = paste(title, description)
    
    electoral_match = (grepl(pattern="electoral",x=text_search,ignore.case=T,useBytes=T) & grepl(pattern="register",x=text_search,ignore.case=T,useBytes=T)) |
      (grepl(pattern="election",x=text_search,ignore.case=T,useBytes=T) & grepl(pattern="management",x=text_search,ignore.case=T,useBytes=T)) |
      (grepl(pattern="electoral",x=text_search,ignore.case=T,useBytes=T) & grepl(pattern="management",x=text_search,ignore.case=T,useBytes=T)) |
      grepl(pattern="voter registration",x=text_search,ignore.case=T,useBytes=T)
    if(electoral_match){
      iati_identifier = result$iati_identifier
      part_orgs = result$participating_organisations
      donor_names = c()
      implementing_names = c()
      for(part_org in part_orgs){
        if(part_org$role$name == "Funding"){
          if(length(part_org$narratives)>0){
            donor_names = c(donor_names,part_org$narratives[[1]]$text)
          }
        }
        if(part_org$role$name == "Implementing"){
          if(length(part_org$narratives)>0){
            implementing_names = c(implementing_names,part_org$narratives[[1]]$text)
          }
        }
      }
      donor_name = paste(donor_names,collapse=";")
      implementing_name = paste(implementing_names,collapse=";")
      
      recipient_countries = result$recipient_countries
      activity_recipient = ""
      for(recipient_country in recipient_countries){
        if(!is.null(recipient_country$percentage)){
          if(recipient_country$percentage == 100){
            activity_recipient = recipient_country$country$name
          } 
        }
      }
      
      transactions_uri = result$transactions
      while(!is.null(transactions_uri)){
        transactions_raw = content(GET(
          transactions_uri
        ))
        
        transactions = transactions_raw["results"][[1]]
        for(transaction in transactions){
          transaction_recipient = ""
          if(!is.null(transaction$recipient_country)){
            transaction_recipient = transaction$recipient_country$country$name
          }
          trans_df = data.frame(
            reporting_organisation,
            iati_identifier,
            donor_name,
            implementing_name,
            title,
            description,
            activity_recipient,
            transaction_recipient,
            year = substr(transaction$transaction_date, 1, 4),
            value = transaction$value,
            currency = transaction$currency$name,
            transaction_type = transaction$transaction_type$name
          )
          electoral_list[[electoral_index]] = trans_df
          electoral_index = electoral_index + 1
        }
        transactions_uri = transactions_raw["next"][[1]]
      }
    }
  }
  
  next_uri = activities_raw["next"][[1]]
  message(next_uri)
}
electoral = rbindlist(electoral_list)
# Title or description
# electoral AND register
# election AND management
# electoral AND management
# voter registration

fwrite(crvs,"formatted_data/iati_crvs.csv")
fwrite(identity, "formatted_data/iati_identity.csv")
fwrite(electoral, "formatted_data/iati_electoral.csv")
