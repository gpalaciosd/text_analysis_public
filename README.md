# Using news data to forecast economic activity

## Summary
In this project, I use text analysis tools to crete news-based indicators of economic activity for Peru. Then I combine these variables with other economic indicators (firms expectations, electricity, and Google Trends searches) to predict monthly economic growth.

## Outcome variables

I predict monthly rates of economic growth for GDP and its components (value added approach). Outputs include GDP, GDP of non-primary sectors, manufacturing, and services. The period of analysis is November 2012 - September 2020. 

## Contribution

The monthly rate of GDP growth is published with a lag of a month and a half -- for instance, we get the April GDP growth rate by mid June, and the May rate by mid July. In this project, we use real-time indicators to do nowcasting. For example, by collecting news up to the last day of May, we are able to forecast the growth rates of April and May by May 31.

## Scripts

The script __1_cleaning__ transforms the body of news articles into a bag of words. I create monthly variables using sentiment analysis and topic modeling. For information about topic modeling, please refer to [this website](https://www.tidytextmining.com/topicmodeling.html) on text mining in R.

The script __2_forecast__ runs Lasso models to forecast monthly growth in economic activity based on news variables and other economic indicators, such as electricity and firms expectations. To evaluate the performance of the model, I obtain rolling window forecasts and compute two main metrics:
1. RMSE: The square root of the mean square error obtained from comparing the actual growth rate with the rolling window (RW) prediction.
2. Match: The proportion of times that the model predicts the right direction of change in economic growth. For example, if the growth rate in May is higher than in April, the prediction for May should be higher than the RW prediction that the model would have given for April based on all the information available up until April 30.

In the script __3_forecast2__ (forthcoming), I run additional prediction models and compare them with the Lasso model based on the performance metrics.

## Output 

The __data__ folder contains a Spanish sentiment dictionary that builds on [Kaggle's dictionary](https://www.kaggle.com/datasets/rtatman/sentiment-lexicons-for-81-languages).

The __output__ folder includes:
1. _plots_: Plots that show the GDP series and predictions. Also summarizes the performance metrics.
2. _var_imp_: Plots of variable importance that show the variables that the model selects and their relative importance.
3. _results_: Summarizes the model performance metrics and the new predictions.

## Results

1. The model does a good job at predicting GDP and non-primary GDP. 
2. It takes the model two months to really incorporate the dimension of the COVID shock. However, it does a better job at suggesting the recovery.
3. Among the most important GDP predictors, we have: 
- News sentiment variables: number of positive news, previous month (_l_pos_dum_)
- Electricity variables: growth rate of electricity and electricity without manufacturing (_var_elec_, _var_elecsm_)
- Expectations: sale prices, inventories, purchases, and demand.
- COVID/topic variables: COVID dummy and rate of change in COVID-related topics.
- Google Trends: search of words such as "good" and "government".

## Next steps

1. Update predictors up to 2022.
2. Run more prediction models, including random forest.
3. Check the 2019 predictions.

For questions or comments, please reach out to me at __guillermopalaciosdiaz@gmail.com__.

## References

1. [Text as data](https://web.stanford.edu/~gentzkow/research/text-as-data.pdf)
2. [Text mining in R](https://www.tidytextmining.com/topicmodeling.html)

