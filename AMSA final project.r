---
title: $$ Applied Multivariate Statistical Analysis Final Project$$
author: $$應數碩一 610611002 鄧汶\\   
          應數碩一 610611101 高淑婷\\   
          應數碩一 610611108 劉雅涵\\
          應數碩一 610611104 潘星丞\\$$
date: $$2018/6/21$$
output:
  html_document:
    number_sections: true
    fig_caption: true
    toc: true
    toc_float: true
    fig_width: 7
    fig_height: 4.5
    theme: cosmo
    highlight: tango
    code_folding: hide
---
# 簡介  
資料來源:[Kaggle](https://www.kaggle.com/c/sf-crime) 

From 1934 to 1963, San Francisco was infamous for housing some of the world's most notorious criminals on the inescapable island of Alcatraz.

Today, the city is known more for its tech scene than its criminal past. But, with rising wealth inequality, housing shortages, and a proliferation of expensive digital toys riding BART to work, there is no scarcity of crime in the city by the bay.

From Sunset to SOMA, and Marina to Excelsior, this competition's dataset provides nearly 12 years of crime reports from across all of San Francisco's neighborhoods. Given time and location, you must predict the category of crime that occurred.

We're also encouraging you to explore the dataset visually. What can we learn about the city through visualizations like this Top Crimes Map? The top most up-voted scripts from this competition will receive official Kaggle swag as prizes. 

## 目標
+  透過Xgboost建構好的predict model來預測犯罪類型
+  透過圖表及地圖看出犯罪的規律

# 讀取packages
```{r,warning=FALSE,message=FALSE}
library(RColorBrewer)
library(leaflet)
library(dplyr)
library(plyr)
library(scales)
library(reshape2)
library(ggplot2)
library(xgboost)
library(Matrix)
library(dummies)
library(scatterplot3d)
library(Rmisc)
```

## 讀取資料
```{r}
data<-read.csv("San Francisco Crime data.csv")
raw.data<-data
raw.color<-c("red","hotpink","chocolate4","palevioletred4","darkorange",
             "yellow","yellow4","green","green4","seagreen1",
             "turquoise","steelblue1","cyan","blue","navy",
             "blueviolet","darkmagenta","magenta","slategray4","gray52")
head(data[1:20,])
data<-data[,-c(3,6)]
```

# 整理資料
```{r}
crime.category = data %>%
  dplyr::group_by(Category) %>%
  dplyr::summarise(count = n()) %>%
  transform(Category = reorder(Category,-count))

P1<-ggplot(crime.category) +
  geom_bar(aes(x=Category, y=count, color = Category, fill = Category),stat="identity")+
  coord_flip()+
  theme(legend.position="None")+
  ggtitle("Crime Incident")+
  xlab("Crime Category")+
  ylab("Times of Crime")

a<-as.character(data[,2])
a[which(a=="BURGLARY")]<-"LARCENY/THEFT"
a[which(a=="BAD CHECKS")]<-"FRAUD"
a[which(a=="RECOVERED VEHICLE")]<-"VEHICLE THEFT"
a[which(a=="SEX OFFENSES NON FORCIBLE")]<-"SEX OFFENSES FORCIBLE"
a<-as.factor(a)
data[,2]<-a
rm(a)
data[,2]<-as.character(data[,2])
data<-data[-which(data[,2]=="ARSON"),]
data<-data[-which(data[,2]=="BRIBERY"),]
data<-data[-which(data[,2]=="DRIVING UNDER THE INFLUENCE"),]
data<-data[-which(data[,2]=="EMBEZZLEMENT"),]
data<-data[-which(data[,2]=="EXTORTION"),]
data<-data[-which(data[,2]=="FAMILY OFFENSES"),]
data<-data[-which(data[,2]=="GAMBLING"),]
data<-data[-which(data[,2]=="KIDNAPPING"),]
data<-data[-which(data[,2]=="LIQUOR LAWS"),]
data<-data[-which(data[,2]=="LOITERING"),]
data<-data[-which(data[,2]=="PORNOGRAPHY/OBSCENE MAT"),]
data<-data[-which(data[,2]=="RUNAWAY"),]
data<-data[-which(data[,2]=="SUICIDE"),]
data<-data[-which(data[,2]=="TREA"),]
data<-data[-which(data[,2]=="OTHER OFFENSES"),]
data[,2]<-factor(data[,2])

levels(data$Category)

crime.category = data %>%
  dplyr::group_by(Category) %>%
  dplyr::summarise(count = n()) %>%
  transform(Category = reorder(Category,-count))

P2<-ggplot(crime.category) +
  geom_bar(aes(x=Category, y=count, color = Category, fill = Category),stat="identity")+
  coord_flip()+
  theme(legend.position="None")+
  ggtitle("Crime Incident")+
  xlab("Crime Category")+
  ylab("Times of Crime")

layout<-matrix(c(1,2),ncol = 2,nrow=1)
multiplot(P1,P2,layout=layout)
```

## find outlier
```{r}
opar <- par(mfrow = c(1,2), oma = c(0, 0, 2.7, 0));
plot(data$X,data$Y,main="the coordinate of longitude and latitude",xlab = "longitude",ylab = "latitude")
# we will found it has outlier
outlier<-data[which(data$Y==90),]
data<-data[-which(data$Y==90),]
plot(data$X,data$Y,main="the coordinate of longitude and latitude without outlier",xlab = "longitude",ylab = "latitude")
``` 

## 切割時間跟dummy variable
```{r}
t<-data[,1]
t<-as.character(t)
t<-strsplit(t,split = " " )
tim1<-c()
numtim1<-c()
day1<-c()
numday1<-c()
year<-numeric(dim(data)[1])
month<-numeric(dim(data)[1])
day<-numeric(dim(data)[1])
hour<-numeric(dim(data)[1])

for(i in 1:dim(data)[1]){
  day1<-strsplit(t[[i]][1],split = "-")
  numday1<-as.numeric(day1[[1]])
  year[i]<-numday1[1]
  month[i]<-numday1[2]
  day[i]<-numday1[3]
  
  tim1<-strsplit(t[[i]][2],split = ":")
  numtim1<-as.numeric(tim1[[1]])
  hour[i]<-numtim1[1]
}
Dates<-data[,1]
data1<-data.frame(Dates,year,month,day,hour,data[,2:7])
#dummy variable
DayOfWeek<-dummy(data1$DayOfWeek, sep = "_")
PdDistrict<- dummy(data1$PdDistrict, sep = "_")
data2<-data1[,-c(1,6:9)]
data2<-data.frame(data2,DayOfWeek,PdDistrict)
head(data2[1:10,1:10])
```

# 分析資料
## method-PCA
```{r}
opar <- par(mfrow = c(1,2), oma = c(0, 0, 2.7, 0));
x<-as.matrix(data2)
e<-eigen(cov(x))
xx<-x%*%e$vectors
plot(e$values, xlab = "Index", ylab = "Lambda",
     main = "Eigenvalues of X", 
     cex.lab = 1.2, cex.axis = 1.2, cex.main = 1.8)
cueigen<-numeric(length(e$values))
a<-0
for(i in 1:length(e$values)){
a<-a+e$values[i]
cueigen[i]<-a/sum(e$values)
}
rm(a)

plot(cueigen, xlab = "Index", ylab = "variance explained",
     main = "", 
     cex.lab = 1.2, cex.axis = 1.2, cex.main = 1.8)
text(4,0.93,"90%",col="red")
pca.col<-as.numeric(data$Category)
for(i in 1:20){
  pca.col[which(pca.col==i)]<-raw.color[i]
}
pca.pch<-as.numeric(data$Category)
opar <- par(mfrow = c(1,2), oma = c(0, 0, 2.7, 0));
plot(x=xx[,1],y=xx[,2],main = "plot of PC1 and PC2" ,xlab = "PC1" ,ylab = "PC2",col=pca.col)
scatterplot3d(x=xx[,1],y=xx[,2],z=xx[,3],color=pca.col,pch=16,xlab ="PC1",ylab="PC2",zlab="PC3",main="the Principle plot")

```

## method2-histogram of variable
```{r}
#年的犯罪類型次數########################
year = data1 %>%
  dplyr::group_by(year) %>%
  dplyr::summarise(count = n()) %>%
  transform(year = order(year,-count))

p.y=ggplot(year) + 
  geom_bar(aes(x=2002+year, y=count, color = "pink", fill = "pink"),stat="identity",width = 0.5)+
  theme(legend.position="None")+
  ggtitle("Year of Crime")+
  xlab("Year")+
  ylab("Times of Crime")

p.y<-p.y+ scale_x_continuous(breaks=seq(2003,2015,1))


#月的犯罪類型次數########################
month = data1 %>%
  dplyr::group_by(month) %>%
  dplyr::summarise(count = n()) %>%
  transform(month = order(month,-count))

p.m=ggplot(month) + 
  geom_bar(aes(x=month, y=count, color = "pink", fill = "pink"),stat="identity",width = 0.5)+
  theme(legend.position="None")+
  ggtitle("Month of Crime")+
  xlab("Month")+
  ylab("Times of Crime")

p.m<-p.m+ scale_x_continuous(breaks=seq(1, 12, 1))   


#周的犯罪總次數########################
dayofweek = data %>%
  dplyr::group_by(DayOfWeek) %>%
  dplyr::summarise(count = n()) %>%
  transform(DayOfWeek = order(DayOfWeek,-count))
p.w=ggplot(dayofweek) +
  geom_bar(aes(x=DayOfWeek, y=count, color = "pink", fill = "pink"),stat="identity",width = 0.5)+
  theme(legend.position="None")+
  ggtitle("Day of Week of Crime")+
  xlab("Day")+
  ylab("Times of Crime")

p.w<-p.w+ scale_x_continuous(breaks=seq(1, 7, 1)) 

#小時的犯罪類型次數########################
hour = data1 %>%
  dplyr::group_by(hour) %>%
  dplyr::summarise(count = n()) %>%
  transform(hour = order(hour,-count))
p.h=ggplot(hour) + 
  geom_bar(aes(x=hour, y=count, color = "pink", fill = "pink"),stat="identity",width = 0.5)+
  theme(legend.position="None")+
  ggtitle("Hour of Crime Category")+
  xlab("Hour")+
  ylab("Times of Crime")

p.h<-p.h+ scale_x_continuous(breaks=seq(1, 24, 1)) 

layout<-matrix(c(1,2,3,4),nrow = 2,ncol = 2)
multiplot(p.y,p.m,p.w,p.h , layout = layout)
```

## line chart

```{r}
plot(x=c(1:10),type = "n",axes= FALSE,main="legend of crime category color",xlab = "",ylab = "")
legend("center",legend=c("ASSAULT","DISORDERLY CONDUCT","VEHICLE THEFT","DRUG/NARCOTIC","FORGERY/COUNTERFEITING","FRAUD","LARCENY/THEFT","MISSING PERSON","NON-CRIMINAL","PROSTITUTION","ROBBERY","SECONDARY CODES","SEX OFFENSES","STOLEN PROPERTY","SUSPICIOUS OCC","TRESPASS","VANDALISM","VEHICLE THEFT","WEAPON LAWS","DRUNKENNESS"),col=c("red","hotpink","chocolate4","palevioletred4","darkorange","yellow","yellow4","green","green4","seagreen1","turquoise","steelblue1","cyan","blue","navy","blueviolet","darkmagenta","magenta","slategray4","gray52"),ncol=3,lwd=2,text.width=3,cex=0.5,xjust=0.3,yjust=-0.5,xpd=TRUE)

par(mai=c(2.5,1,0.5,0.5))
YEAR=seq(2003,2015,1)
year.ASSAULT=table(data1$year[which(data1$Category=="ASSAULT")])
plot(x=YEAR,year.ASSAULT,type = "l",lwd=2, xlim = c(min(YEAR), max(YEAR)),ylim = c(50,23000),xaxt="n",yaxt="n",col="red",xlab="YEAR",ylab="Category")
# par(bg='lavender')
axis(side=1,at=seq(2003,2015,1))
axis(side=2,at=seq(0,23000,5000))    
xy1=par("usr")
title("Line Plot of San Francisco Crime")
color=c("red","hotpink","chocolate4","palevioletred4","darkorange","yellow","yellow4","green","green4","seagreen1","turquoise","steelblue1","cyan","blue","navy","blueviolet","darkmagenta","magenta","slategray4","gray52")
for(i in 2:20){
  a<-data1$year[which(as.numeric(data1$Category)==i)]
  a<-c(a,2003:2015)
  year.Category=table(a)-1
  lines(x=YEAR,year.Category,type = "l", col = color[i],lwd=2)
}

####每月各種犯罪類別次數變化分布圖################
par(mai=c(2.5,1,0.5,0.5))
MONTH=seq(1,12,1)
month.ASSAULT=table(data1$month[which(data1$Category=="ASSAULT")])
plot(x=MONTH,month.ASSAULT,type = "l",lwd=2, xlim = c(min(MONTH), max(MONTH)),ylim = c(50,19000),xaxt="n",yaxt="n",col="red",xlab="MONTH",ylab="Category")
title("Line Plot of San Francisco Crime")
axis(side=1,at=seq(1,12,1))
axis(side=2,at=seq(50,19000,3000))
color=c("red","hotpink","chocolate4","palevioletred4","darkorange","yellow","yellow4","green","green4","seagreen1","turquoise","steelblue1","cyan","blue","navy","blueviolet","darkmagenta","magenta","slategray4","gray52")
for(i in 2:20){
  a<-data1$month[which(as.numeric(data1$Category)==i)]
  a<-c(a,1:12)
  month.Category=table(a)-1
  lines(x=MONTH,month.Category,type = "l", col = color[i],lwd=2)
}

####每周各種犯罪類別次數變化分布圖################
par(mai=c(2.5,1,0.5,0.5))
DayOfWeek.ASSAULT=table(data1$DayOfWeek[which(data1$Category=="ASSAULT")])
DayOfWeek.ASSAULT.=c(DayOfWeek.ASSAULT[[2]],DayOfWeek.ASSAULT[[6]],DayOfWeek.ASSAULT[[7]],DayOfWeek.ASSAULT[[5]],DayOfWeek.ASSAULT[[1]],DayOfWeek.ASSAULT[[3]],DayOfWeek.ASSAULT[[4]])
plot(DayOfWeek.ASSAULT.,type = "l",lwd=2,ylim = c(500,35000),xaxt="n",yaxt="n",col="red",xlab="DayOfWeek",ylab="Category")
weekname=c("Monday","Tuesday","Wednesday","Thursday","Friday","Saturday","Sunday")
axis(side=1,at=seq(1,7,1),label=weekname)
axis(side=2,at=seq(500,35000,5000))
title("Line Plot of San Francisco Crime")
xy3=par("usr")
color=c("red","hotpink","chocolate4","palevioletred4","darkorange","yellow","yellow4","green","green4","seagreen1","turquoise","steelblue1","cyan","blue","navy","blueviolet","darkmagenta","magenta","slategray4","gray52")
for(i in 2:20){
  a<-data1$DayOfWeek[which(as.numeric(data1$Category)==i)]
  a=as.numeric(a)
  a<-c(a,1:7)
  DayOfWeek.Category=table(a)-1
  DayOfWeek.Category.=c(DayOfWeek.Category[[2]],DayOfWeek.Category[[6]],DayOfWeek.Category[[7]],DayOfWeek.Category[[5]],DayOfWeek.Category[[1]],DayOfWeek.Category[[3]],DayOfWeek.Category[[4]])
  lines(DayOfWeek.Category.,type = "l", col = color[i],lwd=2)
}

####每小時各種犯罪類別次數變化分布圖################
par(mai=c(2.5,1,0.5,0.5))
hour=seq(0,23,1)
hour.ASSAULT=table(data1$hour[which(data1$Category=="ASSAULT")])
plot(x=hour,hour.ASSAULT,type = "l",lwd=2, xlim = c(min(hour), max(hour)),ylim = c(0,17000),xaxt="n",col="red",xlab="HOUR",ylab="Category")
title("Line Plot of San Francisco Crime")
axis(side=1,at=seq(0,23,1))
axis(side=2,at=seq(0,15000,2500))
xy4=par("usr")
color=c("red","hotpink","chocolate4","palevioletred4","darkorange","yellow","yellow4","green","green4","seagreen1","turquoise","steelblue1","cyan","blue","navy","blueviolet","darkmagenta","magenta","slategray4","gray52")
for(i in 2:20){
  a<-data1$hour[which(as.numeric(data1$Category)==i)]
  a<-c(a,0:23)
  hour.Category=table(a)-1
  lines(x=hour,hour.Category,type = "l", col = color[i],lwd=2)
}
```

## 每年轄區對應的犯罪類型
```{r}
###每年轄區對應的犯罪類型
par(mfrow=c(1,3))
#par(mai=c(0.5,0.5,1,0.5))
YEAR=seq(2003,2015,1)
color=c("red","hotpink","chocolate4","palevioletred4","darkorange","yellow","yellow4","green","green4","seagreen1","turquoise","steelblue1","cyan","blue","navy","blueviolet","darkmagenta","magenta","slategray4","gray52")
b<-c("BAYVIEW","CENTRAL","INGLESIDE","MISSION","NORTHERN","PARK","RICHMOND","SOUTHERN","TARAVAL","TENDERLOIN")
for(j in 1:10){
  year.Category.PD=table(data1$year[intersect(which(as.numeric(data1$PdDistrict)==j),which(as.numeric(data1$Category)==1))])
  plot(x=YEAR,year.Category.PD,type = "l",lwd=2, xlim = c(min(YEAR), max(YEAR)),ylim = c(50,5400),xaxt="n",yaxt="n",col="red",xlab="YEAR",ylab="Category")
  axis(side=1,at=seq(2003,2015,1))
  axis(side=2,at=seq(50,5400,500))
  for(i in 2:20){
    a<-data1$year[intersect(which(as.numeric(data1$PdDistrict)==j),which(as.numeric(data1$Category)==i))]
    a<-c(a,2003:2015)
    year.Category.PD=table(a)-1
    lines(x=YEAR,year.Category.PD,type = "l", col = color[i],lwd=2)
    title(paste(b[j]))
  }
}
```

## 每月轄區對應的犯罪類型
```{r}
###每月轄區對應的犯罪類型
par(mfrow=c(1,3),oma = c(0, 0, 2.7, 0))
#par(mai=c(0.5,0.5,1,1.02))
MONTH=seq(1,12,1)
color=c("red","hotpink","chocolate4","palevioletred4","darkorange",
        "yellow","yellow4","green","green4","seagreen1",
        "turquoise","steelblue1","cyan","blue","navy",
        "blueviolet","darkmagenta","magenta","slategray4","gray52")
b<-c("BAYVIEW","CENTRAL","INGLESIDE","MISSION","NORTHERN",
     "PARK","RICHMOND","SOUTHERN","TARAVAL","TENDERLOIN")

for(j in 1:10){
  month.Category.PD=table(data1$month[intersect(which(as.numeric(data1$PdDistrict)==j),
                                                which(as.numeric(data1$Category)==1))])
  plot(x=MONTH,month.Category.PD,type = "l",lwd=2, xlim = c(min(MONTH), max(MONTH)),
       ylim = c(50,5400),xaxt="n",yaxt="n",col="red",xlab="MONTH",ylab="Category")
  axis(side=1,at=seq(1,12,1))
  axis(side=2,at=seq(50,5400,500))
  for(i in 2:20){
    a<-data1$month[intersect(which(as.numeric(data1$PdDistrict)==j),which(as.numeric(data1$Category)==i))]
    a<-c(a,1:12)
    month.Category.PD=table(a)-1
    lines(x=MONTH,month.Category.PD,type = "l", col = color[i],lwd=2)
    title(paste(b[j]))
  }
}
```

## 星期幾轄區對應的犯罪類型
```{r}
#@@有改過##星期幾轄區對應的犯罪類型
par(mfrow=c(1,3),oma = c(0, 0, 2.7, 0))
WEEKEND=seq(1,7,1)
color=c("red","hotpink","chocolate4","palevioletred4","darkorange",
        "yellow","yellow4","green","green4","seagreen1",
        "turquoise","steelblue1","cyan","blue","navy",
        "blueviolet","darkmagenta","magenta","slategray4","gray52")
b<-c("BAYVIEW","CENTRAL","INGLESIDE","MISSION","NORTHERN",
     "PARK","RICHMOND","SOUTHERN","TARAVAL","TENDERLOIN")


xy1=par("usr")

for(j in 1:10){
  DayOfWeek.Category.PD=table(data1$DayOfWeek[intersect(which(as.numeric(data1$PdDistrict)==j),
                                                        which(as.numeric(data1$Category)==1))])
  plot(DayOfWeek.Category.PD,type = "l",lwd=2, xlim = c(min(WEEKEND), max(WEEKEND)),
       ylim = c(50,10000),xaxt="n",yaxt="n",col="red",xlab="WEEKEND",ylab="Category")
  weekname=c("Monday","Tuesday","Wednesday","Thursday","Friday","Saturday","Sunday")
  axis(side=1,at=seq(1,7,1),label=weekname)
  axis(side=2,at=seq(50,10000,500))

  for(i in 2:20){
    a<-data1$DayOfWeek[intersect(which(as.numeric(data1$PdDistrict)==j),which(as.numeric(data1$Category)==i))]
    a<-c(a,1:7)
    DayOfWeek.Category.PD=table(a)-1
    DayOfWeek.Category.PD.=c(DayOfWeek.Category.PD[[2]],DayOfWeek.Category.PD[[6]],DayOfWeek.Category.PD[[7]],
                             DayOfWeek.Category.PD[[5]],DayOfWeek.Category.PD[[1]],DayOfWeek.Category.PD[[3]],
                             DayOfWeek.Category.PD[[4]])
    lines(DayOfWeek.Category.PD.,type = "l", col = color[i],lwd=2)
    title(paste(b[j]))
  }
}
```

## 每小時轄區對應的犯罪類型
```{r}
###每小時轄區對應的犯罪類型
par(mfrow=c(1,3),oma = c(0, 0, 2.7, 0))
#par(mai=c(0.5,0.5,1,0.5))
HOUR=seq(0,23,1)
color=c("red","hotpink","chocolate4","palevioletred4","darkorange","yellow","yellow4","green","green4","seagreen1","turquoise","steelblue1","cyan","blue","navy","blueviolet","darkmagenta","magenta","slategray4","gray52")
b<-c("BAYVIEW","CENTRAL","INGLESIDE","MISSION","NORTHERN","PARK","RICHMOND","SOUTHERN","TARAVAL","TENDERLOIN")
for(j in 1:10){
  hour.Category.PD=table(data1$hour[intersect(which(as.numeric(data1$PdDistrict)==j),which(as.numeric(data1$Category)==1))])
  plot(x=HOUR,hour.Category.PD,type = "l",lwd=2, xlim = c(min(HOUR), max(HOUR)),ylim = c(50,4100),xaxt="n",yaxt="n",col="red",xlab="HOUR",ylab="Category")
  axis(side=1,at=seq(0,23,1))
  axis(side=2,at=seq(50,4100,500))
  for(i in 2:20){
    a<-data1$hour[intersect(which(as.numeric(data1$PdDistrict)==j),which(as.numeric(data1$Category)==i))]
    a<-c(a,0:23)
    hour.Category.PD=table(a)-1
    lines(x=HOUR,hour.Category.PD,type = "l", col = color[i],lwd=2)
    title(paste(b[j]))
  }
}
```

# XGBOOST
## 設定data及參數
```{r}
#xgboost
#case1
set.seed(100)
xgtrain.x = data2
y_train <- as.numeric(as.factor(data$Category))-1
n1<-sample(dim(data)[1],500000)
n2<-c(1:dim(data)[1])[-n1]
trainy<-y_train[n1]
testy<-y_train[n2]
trainXG = as.matrix(xgtrain.x[n1,])
testXG  = as.matrix(xgtrain.x[n2,])
dall.train = xgb.DMatrix(data=as.matrix(trainXG), label=trainy) 

#####
xgb_params=list( 	
  objective="multi:softmax",
  booster="gbtree",
  eta= 0.1, 
  max_depth= 6, 
  colsample_bytree= 0.7,
  subsample = 0.7,
  num_class = 20,
  seed =221)

# xgb_cv <- xgb.cv(data = dall.train,
#                  params = xgb_params,
#                  nrounds = 3000,
#                  maximize = FALSE,
#                  prediction = TRUE,
#                  nfold = 5,
#                  print_every_n = 10,
#                  early_stopping_rounds = 10
#                  ,nthread=8,
#                  eval_metric='mlogloss'
# )
# (best.nround = xgb_cv$best_iteration) 

best.nround = 1010
cat("the best runs times is:",best.nround,"\n")
```
## building model
```{r}
# build model
dtrain <- xgb.DMatrix(data=trainXG, label=trainy)
dtest <- xgb.DMatrix(data=testXG, label=testy)
xgb_model <- xgb.train(	data = dtrain,
                        params = xgb_params,
                        list(train = dtrain, test = dtest),
                        nrounds =best.nround,
                        verbose = 1,
                        print_every_n = 10,
                        eval_metric='mlogloss'
)

feature = xgb.importance(feature_names = colnames(xgtrain.x), 
                         model = xgb_model)

feature[1:23,]
xgb.plot.importance(feature)
```

## training error
```{r}
#train error
xgb.pred.train = predict(xgb_model,dtrain)

confusionmatrix.xgb.train<-table(trainy,xgb.pred.train)
colnames(confusionmatrix.xgb.train)<-levels(data$Category)
row.names(confusionmatrix.xgb.train)<-levels(data$Category)
cat("The confusion Matrix of training data.")

confusionmatrix.xgb.train

cat("the correct rate of train data is:",sum(diag(confusionmatrix.xgb.train))/length(n1),"\n")
cat("each column correct rate is:","\n")
cat(diag(confusionmatrix.xgb.train)/colSums(confusionmatrix.xgb.train),"\n")
```
## testing error
```{r}
#test error
xgb.pred.test = predict(xgb_model,dtest)

confusionmatrix.xgb.test<-table(testy,xgb.pred.test)
colnames(confusionmatrix.xgb.test)<-levels(data$Category)
row.names(confusionmatrix.xgb.test)<-levels(data$Category)
cat("The confusion Matrix of training data.")

confusionmatrix.xgb.test

cat("the correct rate of test data is:",sum(diag(confusionmatrix.xgb.test))/length(n2),"\n")
cat("each column correct rate is:","\n")
cat(diag(confusionmatrix.xgb.test)/colSums(confusionmatrix.xgb.test),"\n")

```

# 地圖
## ASSAULT
```{r}
cate.level<-levels(data$Category)

crime.map <- function(categories) {
  new.crimes <- filter(data, Category %in% categories) %>% droplevels()
  
  pal <- colorFactor(brewer.pal(length(unique(new.crimes$PdDistrict)), "Set3"),
                     domain = new.crimes$PdDistrict)
  
  leaflet(new.crimes) %>%
    addProviderTiles(providers$Stamen.TonerLite,
        options = providerTileOptions(noWrap = TRUE)
        )  %>%
    addCircleMarkers (lng =  ~X, lat =  ~Y,
                      color = ~pal(PdDistrict),
                      opacity = .7, radius  = 1) %>%
    addLegend(pal = pal, values = new.crimes$PdDistrict)
}
crime.map("ASSAULT")
```


#  結論&反思
+  從圖表看出年月星期幾對於犯罪總數沒有很明顯的變化，但是小時對於犯罪總數有很明顯的在凌晨兩點到六點犯罪總數比其他時間點減少，中午十一點到十二點以及晚餐時間六點到八點犯罪總數提高，所以，藉由這些圖表，可以讓警方作為參考，在犯罪總數較高的時間，加強巡邏。

+ 在xgboost的時候其實在挑選training data跟testing data其實它的資料會不balanced
，所以之後要深入探討建構model的時候要考慮data的balanced。


# Q&A




![alt text](C:\Users\pan\Desktop\01.jpg)
![alt text](C:\Users\pan\Desktop\02.jpg)
