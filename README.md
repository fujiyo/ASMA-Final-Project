# ASMA-Final-Project
應數碩一610611002鄧汶 

應數碩一610611101高淑婷 

應數碩一610611108劉雅涵

應數碩一610611104潘星丞

Date:2018/6/21

# 1 簡介
資料來源:[Kaggle](https://www.kaggle.com/c/sf-crime)

From 1934 to 1963, San Francisco was infamous for housing some of the world’s most notorious criminals on the inescapable island of Alcatraz.

Today, the city is known more for its tech scene than its criminal past. But, with rising wealth inequality, housing shortages, and a proliferation of expensive digital toys riding BART to work, there is no scarcity of crime in the city by the bay.

From Sunset to SOMA, and Marina to Excelsior, this competition’s dataset provides nearly 12 years of crime reports from across all of San Francisco’s neighborhoods. Given time and location, you must predict the category of crime that occurred.

We’re also encouraging you to explore the dataset visually. What can we learn about the city through visualizations like this Top Crimes Map? The top most up-voted scripts from this competition will receive official Kaggle swag as prizes.

## 1.1 目標
+  建構好的predict model來預測犯罪類型
+  透過圖表及地圖看出犯罪的規律

# 2 讀取packages
## 2.1 讀取資料
![image](https://github.com/fujiyo/ASMA-Final-Project/blob/master/figure-html/load%20data.JPG?raw=true)

# 3 整理資料
![image](https://github.com/fujiyo/ASMA-Final-Project/blob/master/figure-html/%E6%95%B4%E7%90%86%E8%B3%87%E6%96%99.JPG?raw=true)
![image](https://github.com/fujiyo/ASMA-Final-Project/blob/master/figure-html/unnamed-chunk-3-1.png?raw=true)

## 3.1 find outlier
![image](https://github.com/fujiyo/ASMA-Final-Project/blob/master/figure-html/unnamed-chunk-4-1.png?raw=true)

## 3.2 切割時間跟dummy variable
![image](https://github.com/fujiyo/ASMA-Final-Project/blob/master/figure-html/dummy.JPG?raw=true)

# 4 分析資料
## 4.1 method-PCA
![image](https://github.com/fujiyo/ASMA-Final-Project/blob/master/figure-html/unnamed-chunk-6-1.png?raw=true)
![image](https://github.com/fujiyo/ASMA-Final-Project/blob/master/figure-html/unnamed-chunk-6-2.png?raw=true)

## 4.2 method2-histogram of variable
![image](https://github.com/fujiyo/ASMA-Final-Project/blob/master/figure-html/unnamed-chunk-7-1.png?raw=true)

## 4.3 line chart
![image](https://github.com/fujiyo/ASMA-Final-Project/blob/master/figure-html/legend.JPG?raw=true)
![image](https://github.com/fujiyo/ASMA-Final-Project/blob/master/figure-html/unnamed-chunk-8-2.png?raw=true)
![image](https://github.com/fujiyo/ASMA-Final-Project/blob/master/figure-html/unnamed-chunk-8-3.png?raw=true)
![image](https://github.com/fujiyo/ASMA-Final-Project/blob/master/figure-html/unnamed-chunk-8-4.png?raw=true)
![image](https://github.com/fujiyo/ASMA-Final-Project/blob/master/figure-html/unnamed-chunk-8-5.png?raw=true)

## 4.4 每年轄區對應的犯罪類型
![image](https://github.com/fujiyo/ASMA-Final-Project/blob/master/figure-html/unnamed-chunk-9-1.png?raw=true)
![image](https://github.com/fujiyo/ASMA-Final-Project/blob/master/figure-html/unnamed-chunk-9-2.png?raw=true)
![image](https://github.com/fujiyo/ASMA-Final-Project/blob/master/figure-html/unnamed-chunk-9-3.png?raw=true)
![image](https://github.com/fujiyo/ASMA-Final-Project/blob/master/figure-html/unnamed-chunk-9-4.png?raw=true)

## 4.5 每月轄區對應的犯罪類型
![image](https://github.com/fujiyo/ASMA-Final-Project/blob/master/figure-html/unnamed-chunk-10-1.png?raw=true)
![image](https://github.com/fujiyo/ASMA-Final-Project/blob/master/figure-html/unnamed-chunk-10-2.png?raw=true)
![image](https://github.com/fujiyo/ASMA-Final-Project/blob/master/figure-html/unnamed-chunk-10-3.png?raw=true)
![image](https://github.com/fujiyo/ASMA-Final-Project/blob/master/figure-html/unnamed-chunk-10-4.png?raw=true)

## 4.6 星期幾轄區對應的犯罪類型
![image](https://github.com/fujiyo/ASMA-Final-Project/blob/master/figure-html/unnamed-chunk-11-1.png?raw=true)
![image](https://github.com/fujiyo/ASMA-Final-Project/blob/master/figure-html/unnamed-chunk-11-2.png?raw=true)
![image](https://github.com/fujiyo/ASMA-Final-Project/blob/master/figure-html/unnamed-chunk-11-3.png?raw=true)
![image](https://github.com/fujiyo/ASMA-Final-Project/blob/master/figure-html/unnamed-chunk-11-4.png?raw=true)

## 4.7 每小時轄區對應的犯罪類型
![image](https://github.com/fujiyo/ASMA-Final-Project/blob/master/figure-html/unnamed-chunk-12-1.png?raw=true)
![image](https://github.com/fujiyo/ASMA-Final-Project/blob/master/figure-html/unnamed-chunk-12-2.png?raw=true)
![image](https://github.com/fujiyo/ASMA-Final-Project/blob/master/figure-html/unnamed-chunk-12-3.png?raw=true)
![image](https://github.com/fujiyo/ASMA-Final-Project/blob/master/figure-html/unnamed-chunk-12-4.png?raw=true)

# 5 XGBOOST
## 5.1 設定data及參數
---------
xgb_params=list(    
  objective="multi:softmax",
  booster="gbtree",
  eta= 0.1, 
  max_depth= 6, 
  colsample_bytree= 0.7,
  subsample = 0.7,
  num_class = 20,
  seed =221)
best.nround = 1010
--------
## 5.2 building model
![image](https://github.com/fujiyo/ASMA-Final-Project/blob/master/figure-html/model%20logloss.JPG?raw=true)
![image](https://github.com/fujiyo/ASMA-Final-Project/blob/master/figure-html/feature.JPG?raw=true)

## 5.3 training error


## 5.4 testing error

# 6 地圖

# 7 結論&反思
+  從圖表看出年月星期幾對於犯罪總數沒有很明顯的變化，但是小時對於犯罪總數有很明顯的在凌晨兩點到六點犯罪總數比其他時間點減少，中午十一點到十二點以及晚餐時間六點到八點犯罪總數提高，所以，藉由這些圖表，可以讓警方作為參考，在犯罪總數較高的時間，加強巡邏。

+  在xgboost的時候其實在挑選training data跟testing data其實它的資料會不balanced ，所以之後要深入探討建構model的時候要考慮data的balanced。

+  希望可以在深入探討藉由地圖看出犯罪類型在地理上的分布及變化。(也可以根據時間在地圖上看到變化)

# 8 Q&A

