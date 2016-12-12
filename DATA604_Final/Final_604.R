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

replication <-20
panel.size <- 25

#Simulation Starts here
power <- data.frame()
for(run in 1:replication) 
{
  #https://understandsolar.com/calculating-kilowatt-hours-solar-panels-produce/
  
  panel.kwh <- rtriangle(365,.25,.27,.26)
  
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
  run.data <- cbind(run,'Generate',run.gen)
 
  run.consume <- t(as.data.frame(rnd.daily))
  run.data2 <- cbind(run,'Consume',run.consume)
  
  power <- rbind(power, run.data)
  power <- rbind(power, run.data2)
}

colnames(power) <- c('Run','Type', 1:365)
rownames(power) <- c(1:nrow(power))

View(power)

#The average cost per watt in the U.S. is $.22 per watt.
#Average energy bill

avg.bill =.22
solarlifeexpectancy <- 20
totalbill <- rnd.daily*avg.bill
Total_utilityBill <-sum(totalbill)

#totalbill for 15 years
(sum(totalbill)*solarlifeexpectancy)

diff_inenergy <- abs(sum(rnd.daily)-sum(run.gen))
toutility <- diff_inenergy *avg.bill

#Cost of solar panel
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

