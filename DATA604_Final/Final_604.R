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

#Observed
monthlyusage <- c(491,409,78,616,198,1321,1849,1265,512,312,310,491)
averageuse <- monthlyusage/monthdays

replication <-100
#panel.size <- 5
panel.seq <- seq(from=5, to=30, by=5)

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
      rnd.daily <- c(rnd.daily,(rnorm(monthdays[i],averageuse[i])))
    }
    
    run.gen <- t(as.data.frame(power.gen))
    run.gen <- cbind(panel.size,run.gen)
    pwr.gen <- rbind(pwr.gen, run.gen)

    run.consume <- t(as.data.frame(rnd.daily))
    pwr.con <- rbind(pwr.con, run.consume)
    
  }
  colnames(pwr.gen) <- c('Num Panels', 1:365)
  rownames(pwr.gen) <- c(1:nrow(pwr.gen))
  
  #colnames(pwr.con) <- c(1:365)
  #rownames(pwr.con) <- c(1:nrow(pwr.con))
  
  temp.gen <- t(as.data.frame(apply(pwr.gen,2,mean)))
  #temp.con <- t(as.data.frame(apply(pwr.con,2,mean)))
  
  summary.gen <- rbind(summary.gen, temp.gen)
  #summary.con <- rbind(summary.con, temp.con)
}

summary.con <- t(as.data.frame(apply(pwr.con,2,mean)))

colnames(summary.gen) <- c('Num Panels', 1:365)
rownames(summary.gen) <- c(1:nrow(summary.gen))

colnames(summary.con) <- c(1:365)
rownames(summary.con) <- c(1:nrow(summary.con))


View(summary.gen)
View(summary.con)

#The average cost per watt in the U.S. is $.22 per kWh.
#Average energy bill
#http://www.engineering.com/ElectronicsDesign/ElectronicsDesignArticles/ArticleID/7475/What-Is-the-Lifespan-of-a-Solar-Panel.aspx

avg.bill =.22
solarlifeexpectancy <- 20
totalbill <- summary.con*avg.bill
Total_utilityBill <-sum(totalbill)

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

