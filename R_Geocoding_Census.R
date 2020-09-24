library(dplyr)

turns <- read.csv('http://web.mta.info/developers/data/nyct/turnstile/turnstile_200919.txt')

google_key <- "AIzaSyBT2ORkaNi7AoNkLDAHvS9yorsfgiJL8fo"
base <- "https://maps.googleapis.com/maps/api/geocode/json?address="
cen_key <- '97d55623ee041618526d685d56a340986817ea2c'

turns_filt <- turns %>%
  group_by(STATION,DIVISION) %>%
  summarize(all = sum(ENTRIES))

turns_filt$LAT <- NA
turns_filt$LON <- NA

for (i in 1:nrow(turns_filt)){
  tryCatch({ 
    geo <- fromJSON(URLencode(paste(base,paste(turns_filt$STATION[i],"Station",turns_filt$DIVISION[i],'Line New York'),"&key=",key)))
    # you need to basically make it so the paste puts out whatever address
    turns_filt$LON[i] <- geo$results$geometry$location$lng[1] 
    turns_filt$LAT[i]  <-  geo$results$geometry$location$lat[1]
    turns_filt$geo_type[i] <- geo$results$types[[1]]
    message(i)
  }, error=function(e){}) 
}

turns_filt$State_FIPS <- NA
turns_filt$County_FIPS <- NA
turns_filt$Tract_FIPS <- NA

for (k in which(is.na(turns_filt$State_FIPS))){
  geo <- fromJSON(paste0('https://geocoding.geo.census.gov/geocoder/geographies/coordinates?x=',turns_filt$LON[k],'&y=',turns_filt$LAT[k],'&benchmark=4&vintage=4'))
  turns_filt$State_FIPS[k] <- geo$result$geographies$`Census Tracts`$STATE
  turns_filt$County_FIPS[k] <- geo$result$geographies$`Census Tracts`$COUNTY
  turns_filt$Tract_FIPS[k] <- geo$result$geographies$`Census Tracts`$TRACT
  message(k)
}


#Reference Table of Data

cen_dat <- fromJSON(paste0('https://api.census.gov/data/2018/acs/acs5/subject?get=NAME,S0101_C05_001E,S0101_C01_001E,S2001_C02_011E,S2001_C02_012E,S2001_C01_002E,S2403_C01_001E,S2403_C01_012E,S2403_C01_017E&for=tract:*&in=state:36&in=county:*&key=',cen_key))
colnames(cen_dat) <- cen_dat[1,]
cen_dat <- cen_dat[-1,]
colnames(cen_dat)[2:9] <- c('Female_Population','Total_Population','P_75_100k','P_over_100k','median_income','tot_emp','emp_info','emp_prof')

##notes
# populations above the age of 16
# Estimate!!Total!!Civilian employed population 16 years and over!!Professional, scientific, and management, and administrative and waste management services!!Professional, scientific, and technical services
#

cen_dat <- as.data.frame(cen_dat)
cen_dat[,2:9] <- sapply(cen_dat[,2:9],as.numeric)

cen_dat$p_f_pop <- cen_dat$Female_Population/cen_dat$Total_Population
cen_dat$p_emp_info <- cen_dat$emp_info/cen_dat$tot_emp
cen_dat$p_emp_prof <- cen_dat$emp_prof/cen_dat$tot_emp

turns_filt$p_f_pop <- cen_dat$p_f_pop[match(paste0(turns_filt$State_FIPS,turns_filt$County_FIPS,turns_filt$Tract_FIPS),paste0(cen_dat$state,cen_dat$county,cen_dat$tract))]
turns_filt$p_emp_info <- cen_dat$p_emp_info[match(paste0(turns_filt$State_FIPS,turns_filt$County_FIPS,turns_filt$Tract_FIPS),paste0(cen_dat$state,cen_dat$county,cen_dat$tract))]
turns_filt$p_emp_prof <- cen_dat$p_emp_prof[match(paste0(turns_filt$State_FIPS,turns_filt$County_FIPS,turns_filt$Tract_FIPS),paste0(cen_dat$state,cen_dat$county,cen_dat$tract))]
turns_filt$p_75_100k <- cen_dat$P_75_100k[match(paste0(turns_filt$State_FIPS,turns_filt$County_FIPS,turns_filt$Tract_FIPS),paste0(cen_dat$state,cen_dat$county,cen_dat$tract))]/100
turns_filt$p_over_100k <- cen_dat$P_over_100k[match(paste0(turns_filt$State_FIPS,turns_filt$County_FIPS,turns_filt$Tract_FIPS),paste0(cen_dat$state,cen_dat$county,cen_dat$tract))]/100


write.csv(turns_filt, 'geocoded_cen_dat.csv', row.names = F)
