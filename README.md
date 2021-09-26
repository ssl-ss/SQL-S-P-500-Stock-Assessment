# SQL-S-P-500-Stock-Assessment
#### Author: Senling Shu
##### Updated: 9/21/2021


## Background

I am recently interested in stock investment. With 0 experience and a tight budget, I need to rely on some tools that can help me make safer investment decisions. So, I decided to build a SQL database that contains the up-to-date financial information and stock prices of the S&P 500 companies. I used the 9 established financial indicators as filters to query the stock data of the companies with above-average financial health.    


I chose the S&P 500 companies because they are considered the most healthy corporations in the nation. I assume it is relatively safer for me to start with them. Additionally, the S&P index gives us a larger sample size than Dow Jones Industrial Average or Nasdaq index, which includes 30 companies and 100 companies respectively.



### The 9 Financial Indicators <sup>[1-3]<sup>

***1. EPS (Earnings Per Share)***

   - EPS = company’s total profit / number of shares 
   - Great stocks should have a consistent and steady growth of earnings on a yearly basis 
   
   - Desirable: 
      * Y3_EPS > Y2_EPS > Y1_EPS**

***2. P/E Ratio (Price-to-Earnings)***

   - P/E = price per share / earning per share 
   - It tells us whether the stock price is set fair
   - A high P/E can mean the stock is overpriced while a low P/E means the stock is underpriced and is normally considered as value stocks 
   - Desirable: 
      * “The market average P/E ratio currently ranges from 20-25, so a higher PE above that could be considered bad, while a lower PE ratio could be considered better” <sup>[4]<sup>   
      * “Generally speaking, a P/E ratio of 15 or less is a good value, especially if the other numbers work out positively” <sup>[3]<sup>

***3. P/B Ratio (Price-to-Book)***

   - P/B = price per share / book value per share 
   - Book values are what companies put on their annual financial report. It compares how the market values the company vs. the company values itself 
   - Desirable: 
      * A lower P/B will be better because there is less discrepancy between the market’s perspective and the company’s perspective 
      * Not so useful when using it by itself. Better to compare it with other companies in the same sector

***4. P/S Ratio (Price-to-Sale)***

   - P/S (price to sales ratio) = price per share/sales per share
   - It tells how much the market values the company’s sales
   - Desirable: 
      * A lower P/S will be better because there is less discrepancy between the market’s perspective and the company’s perspective 
      * Not so useful when using it by itself. Better to compare it with other companies in the same sector 

***5. Dividend Yield***

   - Dividend yield = annual dividend per share/price per share 
   - It tells how much payments the company makes to shareholders. In other words,  it means how much return on the investment 
   - Desirable:
      * A higher dividend yield means higher return
      * “The current average S&P 500 dividend yield is 1.80%. The average between 2008 and 2018 has hovered around 2%. This suggests that a dividend yield of 2% or more would be considered good or at least above average. And the best-yielding do better than that, often around 4%-5%” <sup>[5]<sup>
      
***6. Gross Profit Margin***
   - Gross Profit Margin = (Revenue - Cost) / Revenue
   - It measures a company’s profitability 
   - Desirable:
      * Higher than other companies in the same sector

***7. Dividends***

   - How much of one company’s earnings is paid out to the shareholders 
   - Desirable:
      * Y3_Dividends > Y2_Dividends > Y1_Dividends**

***8. FCF (Free Cash Flow)***

   - It shows whether one company still has enough money to reward the shareholders 
   - Desirable: 
      * Higher than other companies in the same sector 
      
***9. D/E (Debt-to-Equity)***

   - It indicates how many company’s operations are funded by borrowed money 
   - A greater D/E means greater risk 
   - Desirable: 
      * Lower than other companies in the same sector 

** Y3 > Y2 > Y1 AND Y3 = Y2 + 1 AND Y2 = Y1 + 1 \(if Y1 = Year of 2019, then Y2 = Year of 2020 and Y3 = Year of 2021\)  

**References:**

\[1\] https://investoracademy.org/top-10-fundamental-analysis-indicators-for-all-investors/

\[2\] https://www.getsmarteraboutmoney.ca/invest/investment-products/stocks/6-indicators-used-to-assess-stocks/

\[3\] https://www.dummies.com/personal-finance/investing/stocks-trading/10-indicators-great-stock/

\[4\] https://corporatefinanceinstitute.com/resources/knowledge/valuation/price-earnings-ratio/

\[5\] https://www.businessinsider.com/what-is-dividend-yield


## Data 

#### Scraped Data: 

- S&P500_company_financials.csv:
  * Contains symbols, profits, dividend yields, P/S ratios, P/E ratios, P/B ratios, D/E ratios, and Free cash flows of the companies
  * From Ycharts 

- company_info.csv: 
  * Contains the symbols and headquarters of the companies, first date being added to the S&P list, and year of founding 
  * From Wikipedia
  
- company_employees.csv:
  * Contains symbols and number of employees per company
  * From CSIMarket

- stock_price.csv:
  * Contains symbols and stock prices of the companies 
  * From Ycharts as of 9/22/2021

- company_weights.csv: 
  * Contains the names and weights (i.e. how much impact one company has in the S&P 500) of the companies 
  * From Finasko (https://finasko.com/sp-500-companies-weightage/)

- company_dividends.csv:
  * Contains the symbols and company dividends from 2019 to 2021   
  * From Nasdaq

- company_eps.csv:
  * Contains the symbols and company eps from 2019 to 2021   
  * From Nasdaq




  
#### Downloads:

- S&P500_index.csv: 
  * Contains names, tickers/symbols, and sectors of the companies 
  * From https://topforeignstocks.com/indices/components-of-the-sp-500-index/

## Files
   
   **Main.sql**
      - The MySQL script contains commands to 
   
         * create, join, and union tables
         * select data based on simple (e.g. "WHERE") and complex (e.g. "CASE WHEN") conditions 
         * apply aggregate functions to columns 
         * generate nested subqueries and common table expression
   
   **Web Scraping.ipynb**
   
      - The Python script contains code to scrape data from multiple web sources 
      - It involves the usage of beautifulsoup, pandas, requests, selenium, and re packages
   
   **stock vis.twb**
   
      - The Tableau visualizations (e.g. bar chart, pie chart, map, etc.) 
   
   **assessment results.pdf**
   
      - The pdf report includes assessment results and visualizations 
   
