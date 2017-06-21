# Cribs: Predictive Model for house price
Coursework Project for CSC423 (Data Analysis and Regression)

# Introduction
This is a coursework project that we have completed in Winter 2017. Using SAS software, we built a multivariate regression model for predicting home sale price in King County. 

# Team members
Jun Tae Son, Omer Saif Cheema, Yusheng Zhu 

# Data Description and Abstract of the analysis
We obtained the data from the following link: https://www.kaggle.com/harlfoxem/housesalesprediction. 

The data set in the analysis has historical data on house sales in King County, Washington from May 2014 to May 2015. The data set is composed of 21 attributes and 21,613 rows of observations. The data was imported by using the Proc Import function in SAS and then, 1500 rows were randomly taken out of the original data set using different seed values by all three members. We included the following features in the analysis; date of house sales, location of the property, the number of bedrooms and bathrooms, the size of the property, floors, waterfront, view index, conditions of house, levels of construction and design, renovation history and basement. 

We analyzed how influential these features are on house price and conducted prediction test using our final model. We assumed that the prices of the houses are only affected by the variables used in the data set and factors like interest rates, property taxes other political and economic factors stay constant. Our final model indicates that house prices in King County are most influenced by interior area of a house, the location of a house and whether a house has a basement or not. Finally, we are excited to declare that the predictors in our final model can explain over 75 percent of variation in house prices in King County. 

•	Analyzed uncleaned multi-dimension data through SAS software.

•	Developed predictive models based on methods in Applied Statistics. 

•	Improved the model performance up to 75% accuracy by testing model assumptions, significance of coefficient estimates, multicollinearity problem, and influence diagnostics.
