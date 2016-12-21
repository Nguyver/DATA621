library(triangle)

#Monthly Avg Hours sunlight - NYC
#http://rredc.nrel.gov/solar/old_data/nsrdb/1961-1990/redbook/sum2/94728.txt
monthlyavg <- c(3.2, 4.0, 4.8, 5.2, 5.4, 5.5, 5.6, 5.5, 5.0, 4.4, 3.2, 2.8)
monthlymin <- c(2.5, 3.2, 3.9, 4.4, 4.5, 4.5, 4.8, 4.9, 4.3, 3.7, 2.4, 1.9)
monthlymax <- c(4.0, 5.2, 5.7, 6.0, 6.1, 6.2, 6.1, 6.1, 5.8, 5.6, 4.1, 3.4)
monthdays <- c(31,28,31,30,31,30,31,31,30,31,30,31)

#https://rocscience.com/help/roctopple/webhelp/roctopple/Triangular_Distribution.htm
monthlyMode <- 3*monthlyavg-monthlymin-monthlymax

#Appliance Consumption
#http://energy.gov/energysaver/estimating-appliance-and-home-electronic-energy-use

#Average NY Electricity Use
#http://www.eia.gov/electricity/sales_revenue_price/xls/table5_a.xlsx

#Average Family size: 2.54
#https://www.statista.com/statistics/183648/average-size-of-households-in-the-us/
#Census.gov :2.63

#Observed Data
monthlyusage <- c(491,409,78,616,198,1321,1849,1265,512,312,310,491)
averageuse <- monthlyusage/monthdays

replication <-1000
#panel.size <- 5
panel.seq <- seq(from=5, to=40, by=5)

#Simulation Starts here
pwr.con <- data.frame()
summary.gen <- data.frame()
summary.con <-data.frame()

for (panel in panel.seq)
{
  panel.size <- panel
  pwr.gen <- data.frame()

  for(run in 1:replication) 
  {
    #https://understandsolar.com/calculating-kilowatt-hours-solar-panels-produce/
    panel.kwh <- rtriangle(365,.2,.27,.25)
    
    dayssunlight <- vector()
    for (i in 1:length(monthdays))
    {
      dayssunlight <- c(dayssunlight,(rtriangle(monthdays[i],monthlymin[i],monthlymax[i],monthlyMode[i])))
    }
    
    #80% Derate Factor
    power.gen <-(dayssunlight*panel.size*panel.kwh)*.8
  
    rnd.daily <- vector()
    for (i in 1:length(monthdays))
    {
      rnd.daily <- c(rnd.daily,(rnorm(monthdays[i],averageuse[i], sd(averageuse))))
    }
    
    run.gen <- t(as.data.frame(power.gen))
    run.gen <- cbind(panel.size,run.gen)
    pwr.gen <- rbind(pwr.gen, run.gen)

    run.consume <- t(as.data.frame(rnd.daily))
    pwr.con <- rbind(pwr.con, run.consume)
    
  }
  colnames(pwr.gen) <- c('Num Panels', 1:365)
  rownames(pwr.gen) <- c(1:nrow(pwr.gen))
  
  temp.gen <- t(as.data.frame(apply(pwr.gen,2,mean)))
  
  summary.gen <- rbind(summary.gen, temp.gen)
}

summary.con <- t(as.data.frame(apply(pwr.con,2,mean)))

total.gen <- as.data.frame(apply(summary.gen[,-1], 1, sum))

colnames(summary.gen) <- c('Num Panels', 1:365)
rownames(summary.gen) <- c(1:nrow(summary.gen))

colnames(summary.con) <- c(1:365)
rownames(summary.con) <- c(1:nrow(summary.con))

View(summary.gen)
str(summary.gen)

View(summary.con)
str(summary.con)

test <- reshape(summary.gen, direction="long", varying=list(names(summary.gen)[2:366]), v.names="Value", idvar=c("NumPanels"))

View(test)

library(dplyr)


panel_5 <- test %>% filter(test$"Num Panels" == '5')
panel_10 <- test %>% filter(test$"Num Panels" == '10')
panel_15 <- test %>% filter(test$"Num Panels" == '15')
panel_20 <- test %>% filter(test$"Num Panels" == '20')
panel_25 <- test %>% filter(test$"Num Panels" == '25')
panel_30 <- test %>% filter(test$"Num Panels" == '30')
panel_35 <- test %>% filter(test$"Num Panels" == '35')
panel_40 <- test %>% filter(test$"Num Panels" == '40')

library(ggplot2)
g1 <- ggplot(panel_5, aes(time, Value)) + geom_line() + labs(x = "Day", y = "kWh", title="5 Panels") 
g2 <- ggplot(panel_10, aes(time, Value)) + geom_line()
g3 <- ggplot(panel_15, aes(time, Value)) + geom_line() 
g4 <- ggplot(panel_20, aes(time, Value)) + geom_line() 


mean(panel_5$Value)
mean(panel_10$Value)
mean(panel_15$Value)
mean(panel_20$Value)
panel25_avg_kw <- mean(panel_25$Value)


install.packages("scales")
library(scales)

avg.kwh.year <- 9500
panels.energy <- c(0, sum(panel_5$Value),sum(panel_10$Value),sum(panel_15$Value),sum(panel_20$Value),sum(panel_25$Value),sum(panel_30$Value),sum(panel_35$Value))
panel.count <- seq(from=0, to=35, by=5)
(trad.elec.kwh.needed <- c(ifelse(round(avg.kwh.year - panels.energy) <= 0, 0, round(avg.kwh.year - panels.energy, 2))))
#(yearly.saving <- paste0('$', (avg.kwh.year - trad.elec.kwh.needed) * 0.17))
(yearly.saving <- (avg.kwh.year - trad.elec.kwh.needed) * 0.17)

(validation.table <- data.frame(panel.count, 
                               format(round(panels.energy,2), big.mark = ","),  
                               format(trad.elec.kwh.needed, big.mark = ","),
                               dollar_format()(yearly.saving)))
colnames(validation.table) <- c("Panels", "Solar Energy (kWh)", "Grid Elec Need (kWh)", "Yearly Solar Savings")

knitr::kable(validation.table)




sum(panel_40$Value)

test.con <- as.data.frame(summary.con)
View(test.con)
rownames(test.con) <- c('power.con.kw')
test.con1 <- reshape(test.con, direction="long", varying=list(names(test.con)[2:365]), v.names="Value")
View(test.con1)

ggplot(test.con1, aes(time, Value)) + geom_line() + xlab("Days in a Year") + ylab("KWt")

ggplot(data = test , aes(x=test$'Num Panels', y=test$Value)) +  geom_line() + geom_point()

mean(test.con1$Value)




#The average cost per watt in the U.S. is $.22 per kWh.
#https://www.bls.gov/regions/new-york-new-jersey/news-release/averageenergyprices_newyorkarea.htm

#Average energy bill
avg.watt <- c(0.186,0.182,0.187,0.188,0.177,0.190,0.191,0.191,0.191,0.179,0.178,0.182)

#http://www.engineering.com/ElectronicsDesign/ElectronicsDesignArticles/ArticleID/7475/What-Is-the-Lifespan-of-a-Solar-Panel.aspx

#Simulate daily cost of electricity based on montly average of 2016
kWh.daily <- vector()
save.gen <- vector()

for (panel in 1:length(panel.seq))
{
  kWh.daily <- vector()
  for (i in 1:length(monthdays))
  {
    kWh.daily <- c(kWh.daily,(rnorm(monthdays[i],avg.watt[i], sd=sd(avg.watt))))
  }
    temp.gen <- cbind(panel.seq[panel],(summary.gen[panel,2:ncol(summary.gen)]*kWh.daily))
    save.gen <- rbind(save.gen, temp.gen)
}
#MAYBE: simulate life expectancy of system

money <- as.data.frame(apply(save.gen[,-1], 1, sum))
rownames(money) <- panel.seq
colnames(money) <- c("Savings")

bill.year <- summary.con*watt.daily
total.year <-sum(bill.year)

View(money)

##-----------------------------------------------------


 
#totalbill for 15 years
(sum(totalbill)*solarlifeexpectancy)

diff_inenergy <- abs(sum(rnd.daily)-sum(run.gen))
toutility <- diff_inenergy *avg.bill

#Estimated Cost of solar panel
  #6kW solar energy system cost: $15,000
  #8kW solar energy system cost: $20,000
  #10kW solar energy system cost: $25,000
  #15kW solar energy system cost: $34,000


df.solarcost <- data.frame(c(6,8,10,15),c(8,10,15),c(15000,20000,25000,34000))
colnames(df.solarcost) <- c("Start_kwatts","End_kwatts", "cost")

for (i in 1: length(df.solarcost))
{
  if (df.solarcost[i,1]<=sum(run.gen)/1000 && df.solarcost[i,2] >=sum(run.gen)/1000 ) 
  {
    initialcost <- df.solarcost[i+1,3]
  }
}

print(initialcost)
Total_panelcost = initialcost + toutility*solarlifeexpectancy

data.frame(Total_panelcost,Total_utilityBill)

## I would like to recommend if we add more panels and sell the extra energy to the grid, 
#Solar panel implimentation will be more attractive to the public. That will help the environment too






