proc import datafile = 'kc_house_data.csv' out=house replace;
delimiter=',';
getnames=yes;
run;

***
dependent variable = price 

quantitative: bedrooms bathrooms sqft_living sqft_lot sqft_above
qualitative: floors waterfront view condition grade yr_renovated sqft_basement lat long date

not used: id zipcode yr_built sqft_living15 sqft_lot15

*sqft_above = sqft_living - sqft_basement
*sqft_living15 and sqft_lot15 = the average house and lot size of the 15 closest neighbors
*1 bath => Tub, shower, toilet, sink
*.75 bath => Shower, toilet, sink
*.5 bath => Toilet, sink
***;

proc surveyselect data=house
   method=srs n=1500 out=house_new seed=228247000;
run;

*Change the date format;
data house_new;
set house_new;
length date_var $ 8;
date_var=date;
run;
data house_new;
set house_new;
date_new = input(date_var, yymmdd8.);
format date_new date9.;
run;
data house_new;
set house_new;
qtr_var = qtr(date_new);
run;


*Dummy variables;
data house_new;
set house_new;
ln_price=log(price);
ln_sqft_living=log(sqft_living);
ln_sqft_lot =log(sqft_lot); 
ln_sqft_above=log(sqft_above); 
floor_h=(floors>1.5);
view_good=0;if view=3 or view=4 then view_good=1;
condition_good=0; if condition=4 or condition=5 then condition_good=1;
grade_b=0; if grade=4 or grade=5 or grade=6 then grade_b=1;
grade_a=0; if grade=7  or grade=8 or grade=9 or grade=10 then grade_a=1;
grade_h=0; if grade=11 or grade=12 or grade=13 then grade_h=1;
renovated= (yr_renovated>0);
basement= (sqft_basement>0);
S = (lat<47.57815);
E = (long>-122.237);
NE=0; if S=0 and E=1 then NE=1;
SW=0; if S=1 and E=0 then SW=1;
SE=0; if S=1 and E=1 then SE=1;
Q2=(qtr_var=2);
Q3=(qtr_var=3);
Q4=(qtr_var=4);
above_NE = ln_sqft_above*NE;
above_SW = ln_sqft_above*SW;
above_SE = ln_sqft_above*SE;
ln_sqft_above_c = 7.4107474 - ln_sqft_above; 
above_NE_c = ln_sqft_above_c*NE;
above_SW_c = ln_sqft_above_c*SW;
above_SE_c = ln_sqft_above_c*SE;
run;

proc means mean median std stderr min p25 p50 p75 max clm;
var lat long qtr_var ln_sqft_living ln_sqft_above;
run;


*Check normality assumption / distribution for home saies by quarter;
proc univariate normal data=house_new;
var price;
histogram / normal (mu=est sigma=est);
run;
proc univariate normal data=house_new;
var ln_price;
histogram / normal (mu=est sigma=est);
run;

proc sgscatter data=house_new;
matrix ln_price sqft_living sqft_lot sqft_above ln_sqft_living ln_sqft_lot ln_sqft_above;
run;


*full model with log transformation on y;
proc reg data=house_new;
model ln_price =bathrooms bedrooms sqft_living sqft_lot sqft_above floor_h waterfront view_good condition_good grade_b grade_a grade_h renovated basement NE SW SE Q2 Q3 Q4/vif stb;
plot student.*(sqft_living sqft_lot sqft_above predicted. npp.);
run;

*reduced model_1 with log transformation on x;
proc reg corr data=house_new;
model ln_price =bathrooms bedrooms ln_sqft_living ln_sqft_lot ln_sqft_above floor_h waterfront view_good condition_good grade_b grade_a grade_h renovated basement NE SW SE Q2 Q3 Q4/vif stb;
plot student.*(ln_sqft_living ln_sqft_lot ln_sqft_above predicted. npp.);
run;




*reduced model_2: Remove a variable with multicollinearity problem;
* grade_a has the highest vif value (173.84572). Remove it and re-fit the model.;
proc reg corr data=house_new;
model ln_price =bathrooms bedrooms ln_sqft_living ln_sqft_lot ln_sqft_above floor_h waterfront view_good condition_good grade_b grade_h renovated basement NE SW SE Q2 Q3 Q4/vif stb;
run;

*ln_sqft_living has the next highest vif value (18.73723). Remove it and re-fit the model;
proc reg corr data=house_new;
model ln_price =bathrooms bedrooms ln_sqft_lot ln_sqft_above floor_h waterfront view_good condition_good grade_b grade_h renovated basement NE SW SE Q2 Q3 Q4/vif stb;
run;





*reduced model_3: Make interaction variables;
proc reg corr data=house_new;
model ln_price =bathrooms bedrooms ln_sqft_lot ln_sqft_above floor_h waterfront view_good condition_good grade_b grade_h renovated basement NE SW SE Q2 Q3 Q4 above_ne above_sw above_se /vif stb;
run;

*reduced model_4: Solve multicollinearity with interaction variable;
proc reg corr data=house_new;
model ln_price =bathrooms bedrooms ln_sqft_lot ln_sqft_above_c floor_h waterfront view_good condition_good grade_b grade_h renovated basement NE SW SE Q2 Q3 Q4 above_ne_c above_sw_c above_se_c /vif stb;
run;



*reduced model_5: remove outliers and influential points;
proc reg corr data=house_new;
model ln_price =bathrooms bedrooms ln_sqft_lot ln_sqft_above_c floor_h waterfront view_good condition_good grade_b grade_h renovated basement NE SW SE Q2 Q3 Q4 above_ne_c above_sw_c above_se_c /influence r;
run;

data house_new2;
set house_new;
if _n_ = 10 then delete;
if _n_ = 16 then delete;
if _n_ = 24 then delete;
if _n_ = 27 then delete;
if _n_ = 35 then delete;
if _n_ = 72 then delete;
if _n_ = 115 then delete;
if _n_ = 151 then delete;
if _n_ = 186 then delete;
if _n_ = 195 then delete;
if _n_ = 221 then delete;
if _n_ = 257 then delete;
if _n_ = 266 then delete;
if _n_ = 267 then delete;
if _n_ = 284 then delete;
if _n_ = 300 then delete;
if _n_ = 304 then delete;
if _n_ = 316 then delete;
if _n_ = 321 then delete;
if _n_ = 385 then delete;
if _n_ = 388 then delete;
if _n_ = 390 then delete;
if _n_ = 398 then delete;
if _n_ = 400 then delete;
if _n_ = 434 then delete;
if _n_ = 438 then delete;
if _n_ = 481 then delete;
if _n_ = 517 then delete;
if _n_ = 587 then delete;
if _n_ = 588 then delete;
if _n_ = 590 then delete;
if _n_ = 587 then delete;
if _n_ = 612 then delete;
if _n_ = 613 then delete;
if _n_ = 637 then delete;
if _n_ = 644 then delete;
if _n_ = 645 then delete;
if _n_ = 664 then delete;
if _n_ = 673 then delete;
if _n_ = 738 then delete;
if _n_ = 765 then delete;
if _n_ = 771 then delete;
if _n_ = 772 then delete;
if _n_ = 791 then delete;
if _n_ = 806 then delete;
if _n_ = 808 then delete;
if _n_ = 833 then delete;
if _n_ = 845 then delete;
if _n_ = 850 then delete;
if _n_ = 856 then delete;
if _n_ = 868 then delete;
if _n_ = 866 then delete;
if _n_ = 869 then delete;
if _n_ = 883 then delete;
if _n_ = 895 then delete;
if _n_ = 896 then delete;
if _n_ = 899 then delete;
if _n_ = 910 then delete;
if _n_ = 924 then delete;
if _n_ = 938 then delete;
if _n_ = 951 then delete;
if _n_ = 952 then delete;
if _n_ = 958 then delete;
if _n_ = 959 then delete;
if _n_ = 960 then delete;
if _n_ = 965 then delete;
if _n_ = 1013 then delete;
if _n_ = 1041 then delete;
if _n_ = 1044 then delete;
if _n_ = 1050 then delete;
if _n_ = 1074 then delete;
if _n_ = 1085 then delete;
if _n_ = 1098 then delete;
if _n_ = 1100 then delete;
if _n_ = 1103 then delete;
if _n_ = 1133 then delete;
if _n_ = 1147 then delete;
if _n_ = 1172 then delete;
if _n_ = 1182 then delete;
if _n_ = 1188 then delete;
if _n_ = 1189 then delete;
if _n_ = 1234 then delete;
if _n_ = 1278 then delete;
if _n_ = 1280 then delete;
if _n_ = 1282 then delete;
if _n_ = 1302 then delete;
if _n_ = 1303 then delete;
if _n_ = 1347 then delete;
if _n_ = 1348 then delete;
if _n_ = 1394 then delete;
if _n_ = 1414 then delete;
if _n_ = 1415 then delete;
if _n_ = 1452 then delete;
if _n_ = 1473 then delete;
if _n_ = 1484 then delete;
if _n_ = 1496 then delete;
run;

*Check for additional outliers and influential points;
proc reg corr data=house_new2;
model ln_price =bathrooms bedrooms ln_sqft_lot ln_sqft_above_c floor_h waterfront view_good condition_good grade_b grade_h renovated basement NE SW SE Q2 Q3 Q4 above_ne_c above_sw_c above_se_c /influence r;
run;

data house_new3;
set house_new2;
if _n_= 7 then delete;
if _n_= 17 then delete;
if _n_= 106 then delete;
if _n_= 123 then delete;
if _n_= 193 then delete;
if _n_= 200 then delete;
if _n_= 223 then delete;
if _n_= 225 then delete;
if _n_= 312 then delete;
if _n_= 322 then delete;
if _n_= 350 then delete;
if _n_= 370 then delete;
if _n_= 386 then delete;
if _n_= 486 then delete;
if _n_= 495 then delete;
if _n_= 510 then delete;
if _n_= 563 then delete;
if _n_= 581 then delete;
if _n_= 604 then delete;
if _n_= 611 then delete;
if _n_= 612 then delete;
if _n_= 613 then delete;
if _n_= 622 then delete;
if _n_= 627 then delete;
if _n_= 642 then delete;
if _n_= 660 then delete;
if _n_= 671 then delete;
if _n_= 675 then delete;
if _n_= 680 then delete;
if _n_= 689 then delete;
if _n_= 691 then delete;
if _n_= 731 then delete;
if _n_= 736 then delete;
if _n_= 756 then delete;
if _n_= 781 then delete;
if _n_= 809 then delete;
if _n_= 824 then delete;
if _n_= 868 then delete;
if _n_= 898 then delete;
if _n_= 946 then delete;
if _n_= 949 then delete;
if _n_= 1000 then delete;
if _n_= 1004 then delete;
if _n_= 1006 then delete;
if _n_= 1011 then delete;
if _n_= 1022 then delete;
if _n_= 1023 then delete;
if _n_= 1047 then delete;
if _n_= 1058 then delete;
if _n_= 1074 then delete;
if _n_= 1124 then delete;
if _n_= 1136 then delete;
if _n_= 1144 then delete;
if _n_= 1205 then delete;
if _n_= 1211 then delete;
if _n_= 1247 then delete;
if _n_= 1323 then delete;
if _n_= 1389 then delete;
run;

proc reg corr data=house_new3;
model ln_price =bathrooms bedrooms ln_sqft_lot ln_sqft_above_c floor_h waterfront view_good condition_good grade_b grade_h renovated basement NE SW SE Q2 Q3 Q4 above_ne_c above_sw_c above_se_c /influence r;
run;



*Split the original data;
PROC SURVEYSELECT DATA=house_new3
OUT = house_split seed=92595001
SAMPRATE = 0.75 OUTALL;
RUN;
data house_train (where = (Selected = 1));
set house_split;
run;
data house_test (where = (Selected = 0));
set house_split;
run;

proc reg data=house_train;
model  ln_price =bathrooms bedrooms ln_sqft_lot ln_sqft_above_c floor_h waterfront view_good condition_good grade_b grade_h renovated basement NE SW SE Q2 Q3 Q4 above_ne_c above_sw_c above_se_c/stb;
run;

proc reg data=house_test;
model  ln_price =bathrooms bedrooms ln_sqft_lot ln_sqft_above_c floor_h waterfront view_good condition_good grade_b grade_h renovated basement NE SW SE Q2 Q3 Q4 above_ne_c above_sw_c above_se_c/stb;
run;


*model selections;
proc reg data=house_train;
model ln_price =bathrooms bedrooms ln_sqft_lot ln_sqft_above_c floor_h waterfront view_good condition_good grade_b grade_h renovated basement NE SW SE Q2 Q3 Q4 above_ne_c above_sw_c above_se_c/selection=backward sle=0.05 sls=0.05;
run;

proc reg data=house_train;
model ln_price =bathrooms bedrooms ln_sqft_lot ln_sqft_above_c floor_h waterfront view_good condition_good grade_b grade_h renovated basement NE SW SE Q2 Q3 Q4 above_ne_c above_sw_c above_se_c/selection=stepwise sle=0.05 sls=0.05;
run;

proc reg data=house_train;
model ln_price =bathrooms bedrooms ln_sqft_lot ln_sqft_above_c floor_h waterfront view_good condition_good grade_b grade_h renovated basement NE SW SE Q2 Q3 Q4 above_ne_c above_sw_c above_se_c/selection=adjrsq sle=0.05 sls=0.05;
run;

proc reg data=house_train;
model ln_price =bathrooms bedrooms ln_sqft_lot ln_sqft_above_c floor_h waterfront view_good condition_good grade_b grade_h renovated basement NE SW SE Q2 Q3 Q4 above_ne_c above_sw_c above_se_c/selection=cp sle=0.05 sls=0.05;
run;

proc reg data=house_train;
model ln_price =bedrooms ln_sqft_above_c waterfront view_good condition_good grade_b grade_h renovated basement NE SW SE Q4 above_NE_c above_SW_c above_SE_c/stb;
run;

*We found two insignificant variables from testing set after model selection;
proc reg data=house_test;
model ln_price =bedrooms ln_sqft_above_c waterfront view_good condition_good grade_b grade_h renovated basement NE SW SE Q4 above_NE_c above_SW_c above_SE_c/stb;
run;
*Since standardized estimates for insignificant variables are significantly, there would be limited or almost no influence on the final model. Thus, we decided to take them out;
*Renovated and NE;

proc reg data=house_train;
model ln_price =bedrooms ln_sqft_above_c waterfront view_good condition_good grade_b grade_h basement SW SE Q4 above_NE_c above_SW_c above_SE_c/stb;
run;

proc reg data=house_test;
model ln_price =bedrooms ln_sqft_above_c waterfront view_good condition_good grade_b grade_h basement SW SE Q4 above_NE_c above_SW_c above_SE_c/stb;
run;
 



*Take the first two observations from training set ;
proc print data=house_train;
run;

data pred;
input bedrooms	waterfront	view_good	condition_good	grade_b	grade_h	basement	SW	SE	Q4	ln_sqft_above_c	above_NE_c	above_SW_c	above_SE_c;
datalines;
2	0	0	1	0	0	0	0	1	1	0.32067	0	0	0.32067
3	0	0	1	0	0	0	0	1	1	-0.3931	0	0	-0.3931
;

*Compute two predictions including the prediction intervals using the regression model.;
data prediction;
set pred house_test;
run;

proc reg data=prediction;;
model ln_price =bedrooms ln_sqft_above_c waterfront view_good condition_good grade_b grade_h basement SW SE Q4 above_NE_c above_SW_c above_SE_c / p clm cli alpha=0.05;
run;



*Validation test;
* create new variable new_y = ln_price for training set, and = NA * for testing set; 
data house_validation; 
set house_split; 
if selected then new_y=ln_price; 
run; 

/* get predicted values for the missing new_y in test set for the fitted model*/ 
title "Validation - Test Set"; 
proc reg data=house_validation; 
model new_y = bedrooms ln_sqft_above_c waterfront view_good condition_good grade_b grade_h basement SW SE Q4 above_NE_c above_SW_c above_SE_c; 
output out=outm1(where=(new_y=.)) p=yhat; 
run; 


/* summarize the results of the cross-validations for model-1*/ 
title "Difference between Observed and Predicted in Test Set"; 
data outm1_sum; 
set outm1; 
d=ln_price-yhat; 
*d is the difference between observed and predicted values in test set; 
absd=abs(d); 
run; 

/* computes predictive statistics: root mean square error (rmse) and mean absolute error (mae)*/ 
proc summary data=outm1_sum; 
var d absd; 
output out=outm1_stats std(d)=rmse mean(absd)=mae ; 
run; 

proc print data=outm1_stats; 
title 'Validation  statistics for Model'; 
run; 

*computes correlation of observed and predicted values in test set; 
proc corr data=outm1; 
var ln_price yhat; 
run; 









*---------------------------------------;
*boxplot for bedrooms;
proc sort;
by bedrooms;
run;
proc boxplot;
plot ln_price*bedrooms;
run;

*boxplot for bathrooms;
proc sort;
by bathrooms;
run;
proc boxplot;
plot ln_price*bathrooms;
run;

*boxplot for floors;
proc sort;
by floors;
run;
proc boxplot;
plot ln_price*floors;
run;

*boxplot for waterfront;
proc sort;
by waterfront;
run;
proc boxplot;
plot ln_price*waterfront;
run;

*boxplot for view;
proc sort;
by view;
run;
proc boxplot;
plot ln_price*view;
run;

*boxplot for condition;
proc sort;
by condition;
run;
proc boxplot;
plot ln_price*condition;
run;

*boxplot for grade;
proc sort;
by grade;
run;
proc boxplot;
plot ln_price*grade;
run;

*boxplot for yr_built;
proc sort;
by yr_built;
run;
proc boxplot;
plot ln_price*yr_built;
run;

*boxplot for renovated;
proc sort;
by renovated;
run;
proc boxplot;
plot ln_price*renovated;
run;

*boxplot for basementt;
proc sort;
by basement;
run;
proc boxplot;
plot ln_price*basement;
run;

*boxplot for qtr_var;
proc sort;
by qtr_var;
run;
proc boxplot;
plot ln_price*qtr_var;
run;
