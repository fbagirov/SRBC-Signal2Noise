# title: "Metrics Combined"
# author: "Emily Wefelmeyer, Ziyaun Huang, Pranita Patil, Sridhar Ravula"
# date: "November 20, 2018"

# Community Metrics calculations

Metrics_fish <- function(fishCounts, fishCounts2) {
  
  
  #Pielou metric
  
  if (!require('vegan')) install.packages('vegan', quiet=TRUE, repos = "http://cran.us.r-project.org")
  library(vegan)
  
  if (!require('gdata')) install.packages('gdata', quiet=TRUE, repos = "http://cran.us.r-project.org")
  library(gdata)
  
  temp <- fishCounts2[,-(1:4)]
  
  H <- diversity(temp)
  S <- specnumber(temp)
  fishCounts2$pielou <- H/log(S)
  
  #Species Count
  
  fishCounts2$speciesCount <- rowSums(temp > 0)
  
  
  
  #Hill's N1
  
  fishCounts2$Hills_N1 <- exp(H)
  rm(H, S)
  
  
  
  #Hill's N2
  
  if (!require('analogue')) install.packages('analogue', quiet=TRUE, repos = "http://cran.us.r-project.org")
  library(analogue)
  
  fishCounts2$Hills_N2 <- n2(temp, "sites")
  
  
  #Margalef 
  #Calculate Margalef
  
  if (!require('benthos')) install.packages('benthos', quiet=TRUE, repos = "http://cran.us.r-project.org")
  library(benthos)
  
  if (!require('lubridate')) install.packages('lubridate', quiet=TRUE)
  library(lubridate)
  
  if (!require('dplyr')) install.packages('dplyr', quiet=TRUE)
  library(dplyr)
  
  fishCounts$Fish <- as.character(fishCounts$Fish)
  
  fishCounts_new1 <- fishCounts %>%
    group_by(Station_ID) %>%
    summarise(n = n())
  
  N <- nrow(fishCounts2)
  Metrics <- data.frame(
    Station_ID=numeric(N),
    DateTime=rep(as.Date(NA),N),
    margalef=numeric(N)
  )
  
  Metrics$Station_ID <- fishCounts2$Station_ID
  
  
  k=1
  for (i in unique(fishCounts$Station_ID))
  {
    fishCounts_new2 <- fishCounts %>% 
      filter(Station_ID == i ) %>%
      select(Fish, County, DateTime) %>%
      arrange(Fish)
    
    fishCounts_new2$DateTime <- substr(fishCounts_new2$DateTime[], 
                                       1, 
                                       nchar(fishCounts_new2$DateTime[]))
    
    for (j in unique(fishCounts_new2$DateTime))
    {
      fishCounts_new3 <- fishCounts_new2 %>% 
        filter(DateTime == j ) %>%
        select(Fish, County, DateTime) %>%
        arrange(Fish)
      
      Metrics$margalef[k] <- fishCounts_new3 %>% margalef(taxon = Fish, 
                                                          count = County)
      Metrics$Station_ID[k] <- i
      Metrics$DateTime[k] <- j
      
      
      k<-k+1
    }
  }
  
  
  #Add margalef to **fishCounts2**
  
  StationID <- unique(Metrics$Station_ID)
  nStations <- as.numeric(length(StationID))
  
  #Create initial data frame from varous pieces
  fish <- subset(fishCounts2, Station_ID == StationID[1])
  metric <- subset(Metrics, Station_ID == StationID[1])
  
  #Combine fish & macro counts
  temp <- merge(fish,
                metric,
                by.x = "Date",
                by.y = "DateTime",
                all = TRUE)
  
  #Clean to have unified station ID
  temp$StationID <- rep(StationID[1], times = nrow(temp))
  temp$Station_ID.x <- NULL
  temp$Station_ID.y <- NULL
  
  
  #Create initial data frame
  data <- temp
  rm(temp)
  
  #Combine rest of the data frames
  for(station in StationID[2:nStations]) {
    fish <- subset(fishCounts2, Station_ID == station)
    metric <- subset(Metrics, Station_ID == station)
    
    #Combine fish & macro counts
    temp <- merge(fish,
                  metric,
                  by.x = "Date",
                  by.y = "DateTime",
                  all = TRUE)
    
    #Clean to have unified station ID
    temp$StationID <- rep(station, times = nrow(temp))
    temp$Station_ID.x <- NULL
    temp$Station_ID.y <- NULL
    
    #Add station's data to the full data set
    ifelse(nrow(temp) > 0, 
           (data[(nrow(data)+1):(nrow(data) + nrow(temp)),] <-
              temp[1:nrow(temp),]),
           data <- data)
  }
  
  #Remove Date
  data$Date <- NULL
  
  #rename data frame
  fishCounts2 <- data
  
  #Remove data not needed
  rm(fish, 
     metric, 
     data,
     nStations, 
     StationID, 
     fishCounts_new1, 
     fishCounts_new2, 
     fishCounts_new3, 
     k, 
     Metrics,
     station, 
     j,
     i,
     N,
     temp)
  
  #Remove unneed dataframes from import
  rm(fishCounts)
  
  return(fishCounts2)
  
}



