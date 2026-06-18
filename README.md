# SQL_Project-Fraud-detection-and-Risk-analysis
Audit Risk &amp; Compliance Analytics of 4 concrete companies with additional tables

## BUSINESS INSIGHT QUERIES

### Storytelling insight the Business lines

#### 1. Top Risk Industries
```sql
SELECT 
    Industry_Affected,
    SUM(High_Risk_Cases) AS total_risk,
    SUM(Fraud_Cases_Detected) AS total_fraud
FROM big4_financial_risk_compliance
GROUP BY Industry_Affected
ORDER BY total_risk DESC;```
