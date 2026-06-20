# SQL_Project-Fraud-detection-and-Risk-analysis
Audit Risk & Compliance Analytics of 4 concrete companies: PwC, Deloitte, KPMG, and Ernst & Young

Using the Artificial Intelligence / AI, we created 5 additional tables (in attachment) in order to get deeper in the Cross-Functional Business Analysis. We proceeded by arranging and cleaning every single data to adapt it to the main-table datase: big4_financial_risk_compliance [*See and dowload the file*](https://github.com/Pacifique26/SQL_Project-Fraud-detection-and-Risk-analysis/blob/main/big4_financial_risk_compliance.csv).

*The following queries combine audit, project, and workforce datasets to provide deeper insights into financial performance, fraud risk, employee productivity, and project management effectiveness.*

## BUSINESS INSIGHT QUERIES

### Storytelling insight the Business lines

#### Top Risk Industries
Identify which industries generate the highest volume of high-risk cases and fraud detections, helping leadership prioritize risk management efforts.
```sql
SELECT 
    Industry_Affected,
    SUM(High_Risk_Cases) AS total_risk,
    SUM(Fraud_Cases_Detected) AS total_fraud
FROM big4_financial_risk_compliance
GROUP BY Industry_Affected
ORDER BY total_risk DESC;
```

#### Revenue Impact vs Fraud
Compare total revenue impact against fraud cases detected across firms to assess the financial consequences of risk exposure.
```sql
SELECT 
    Firm_Name,
    round(SUM(Total_Revenue_Impact), 2) AS revenue_loss,
    round(SUM(Fraud_Cases_Detected), 2) AS fraud_cases
FROM big4_financial_risk_compliance
GROUP BY Firm_Name
ORDER BY revenue_loss DESC;
```
### Estimated project revenue by firm
Estimate total project-generated revenue for each firm to compare commercial performance across the Big Four.
```sql
SELECT 
    Firm_Name,
    SUM(quantityOrdered * priceEach) AS Estimated_Revenue
FROM Project_details
GROUP BY Firm_Name;
```

### AI vs Non-AI Performance during the audit
Evaluate whether AI-assisted audits achieve higher effectiveness and fraud detection outcomes than traditional auditing approaches.
```sql
SELECT 
    AI_Used_for_Auditing,
    round(AVG(Audit_Effectiveness_Score), 2) AS avg_effectiveness,
    round(AVG(Fraud_Cases_Detected), 2) AS avg_fraud_detected
FROM big4_financial_risk_compliance
GROUP BY AI_Used_for_Auditing;
```

Create a simplified AI usage indicator to support future analytics, reporting, and machine learning workflows.
```sql
WITH Cleaned_Risk_Data AS (
    SELECT 
        Firm_Name,
        Year,
        Industry_Affected,
        CASE 
            WHEN AI_Used_for_Auditing = 'Yes' THEN 1
            ELSE 0
        END AS AI_Flag
    FROM big4_financial_risk_compliance
)
SELECT * FROM Cleaned_Risk_Data;
```

### Impact: Client Satisfaction vs Audit Quality
Measure whether stronger audit effectiveness translates into higher client satisfaction and identify potential service gaps.
Examine the relationship between audit effectiveness, employee workload, and client satisfaction to assess service quality.
```sql
WITH Satisfaction_Impact AS (
    SELECT 
        firm,
        round(AVG(Client_Satisfaction_Score), 2) AS avg_satisfaction,
        round(AVG(Audit_Effectiveness_Score), 2) AS avg_audit_score,
        round(AVG(employee_workload), 2) AS avg_workload
    FROM (
        SELECT 
            e.employeeFirm_Name AS firm,
            b.Client_Satisfaction_Score,
            b.Audit_Effectiveness_Score,
            b.Employee_Workload
        FROM employees e
        JOIN big4_financial_risk_compliance b 
        ON e.employeeFirm_Name = b.Firm_Name
    ) t
    GROUP BY firm
)
SELECT *,
       round((avg_audit_score - avg_satisfaction), 2) AS audit_vs_satisfaction_gap
FROM Satisfaction_Impact;
```
### Examinating the Projects

#### Average Fraud_risk by ProjectField
Identify which project fields are associated with the highest average fraud risk and require increased oversight.
```sql
SELECT 
    pd.Firm_Name,
    pd.ProjectField,
    COUNT(pd.projectNumber) AS total_projects,
    round(AVG(p.PercentageProject_Fraud_Risk), 2) AS avg_risk
FROM Project_details pd
JOIN Project p ON pd.projectNumber = p.ProjectNumber
GROUP BY pd.Firm_Name, pd.ProjectField;
```
#### Average Fraud_risk by Firm_name
Compare the overall fraud risk exposure across firms based on their project portfolios.
```sql
SELECT 
    pd.Firm_Name,
    round(AVG(p.PercentageProject_Fraud_Risk),2) AS Avg_Fraud_Risk
FROM Project p
JOIN Project_details pd
ON p.ProjectNumber = pd.projectNumber
GROUP BY pd.Firm_Name;
```

### Fraud Risk Impact on Companies

#### Fraud detection: which firm converts risk into detected fraud most effectively?
Analyze how effectively each firm converts identified risks into detected fraud cases while measuring the associated financial impact.
```sql
WITH Fraud_Impact AS (
    SELECT 
        Firm_Name,
        SUM(Fraud_Cases_Detected) AS total_fraud,
        SUM(High_Risk_Cases) AS total_risk,
        round(SUM(Total_Revenue_Impact), 2) AS revenue_loss
    FROM big4_financial_risk_compliance
    GROUP BY Firm_Name
)
SELECT *,
       round((total_fraud * 1.0 / total_risk), 2) AS fraud_efficiency_ratio,
       round((revenue_loss / total_fraud), 2) AS cost_per_fraud_case
FROM Fraud_Impact
ORDER BY revenue_loss DESC;
```

#### By UNION ANALYSIS let find the sum of fraud by company
Provide a straightforward comparison of total fraud cases detected by each Big Four firm.
```sql
SELECT 'PwC' AS Firm, SUM(Fraud_Cases_Detected) AS fraud_cases
FROM big4_financial_risk_compliance
WHERE Firm_Name = 'PwC'

UNION ALL

SELECT 'Deloitte', SUM(Fraud_Cases_Detected)
FROM big4_financial_risk_compliance
WHERE Firm_Name = 'Deloitte'

UNION ALL

SELECT 'EY', SUM(Fraud_Cases_Detected)
FROM big4_financial_risk_compliance
WHERE Firm_Name = 'Ernst & Young'

UNION ALL

SELECT 'KPMG', SUM(Fraud_Cases_Detected)
FROM big4_financial_risk_compliance
WHERE Firm_Name = 'KPMG';
```

### Employee Performance vs Workload

#### Does higher workload reduce audit effectiveness?
Analyze whether employee workload and compensation levels influence audit effectiveness and operational performance.
```sql
WITH EmployeePerf AS (
    SELECT 
        employeeFirm_Name,
        AVG(employee_workload) AS avg_workload,
        round(AVG(salary), 2) AS avg_salary
    FROM employees
    GROUP BY employeeFirm_Name
)
SELECT 
    e.employeeFirm_Name,
    e.avg_workload,
    e.avg_salary,
    b.Audit_Effectiveness_Score
FROM EmployeePerf e
JOIN big4_financial_risk_compliance b 
ON e.employeeFirm_Name = b.Firm_Name;
```

### Project Risk Classification

#### Risk distribution across industries
Categorize projects into risk levels to support risk monitoring, prioritization, and resource allocation.
```sql
WITH ProjectRiskLevel AS (
    SELECT 
        ProjectNumber,
        ProjectField,
        PercentageProject_Fraud_Risk,
        CASE 
            WHEN PercentageProject_Fraud_Risk > 60 THEN 'HIGH'
            WHEN PercentageProject_Fraud_Risk BETWEEN 30 AND 60 THEN 'MEDIUM'
            ELSE 'LOW'
        END AS risk_level
    FROM Project
)
SELECT 
    ProjectField,
    risk_level,
    COUNT(*) AS total_projects
FROM ProjectRiskLevel
GROUP BY ProjectField, risk_level
ORDER BY ProjectField;
```

### Project duration: Time Analysis (2020-2025)

#### Average time by Field of project
Measure the average completion time of projects across different fields to identify operational efficiencies and bottlenecks.
```sql
SELECT 
ProjectField,
AVG(DATEDIFF(Project_End_Date, Project_Start_Date)) AS Avg_Project_Duration
FROM Project
GROUP BY ProjectField;
```
#### Project date-timing
Track project start and end dates to understand project lifecycles and scheduling patterns.
```sql
SELECT ProjectNumber,
		MIN(Project_Start_Date) AS Start_of_project, 
		MAX(Project_End_Date) AS End_of_project
 FROM project
 GROUP BY ProjectNumber;
```

### Risk Level: let find the 1st and 2nd high field risk cases by company 

#### Overall Risk Ranking
Rank audit engagements based on the number of high-risk cases and compare ranking methods using SQL window functions.
```sql
SELECT Firm_Name, Industry_Affected, Total_Audit_Engagements, High_Risk_Cases, 
	ROW_NUMBER() OVER(ORDER BY High_Risk_Cases DESC) AS Top_Firm_Risk,
	RANK() OVER(ORDER BY High_Risk_Cases DESC) AS Top_Firm_Risk_R,
	Dense_rank() OVER(ORDER BY High_Risk_Cases desc) AS Top_Firm_Risk_DR
	FROM big4_financial_risk_compliance;
```

#### Top 2 Highest-Risk Engagements per Firm
Identify the two highest-risk engagements for each firm to highlight key risk concentration areas.
```sql
SELECT * FROM
(SELECT Firm_Name, Industry_Affected, Total_Audit_Engagements, High_Risk_Cases, 
ROW_NUMBER() OVER(PARTITION BY Firm_Name ORDER BY High_Risk_Cases DESC) AS Top_Firm_Risk
FROM big4_financial_risk_compliance) AS Most_Hight
WHERE Top_Firm_Risk <=2;
```

### Looking for the Maximum price and budget in the project according to the field
Compare the highest project prices and budgets across fields to identify high-value business segments.
```sql
WITH MP AS
(SELECT ProjectField,
		MAX(priceEach) AS Max_Price
FROM project_details
GROUP BY ProjectField), 

MB AS
(SELECT ProjectField, 
		MAX(Project_budget) AS Max_Budget
FROM project
GROUP BY ProjectField)

SELECT MB.ProjectField, MP.Max_Price, MB.Max_Budget
FROM MB LEFT JOIN MP ON MB.ProjectField = MP.ProjectField;
```

## CONCLUSION

This SQL analysis provides a comprehensive view of risk, fraud detection, audit performance, and operational effectiveness across the Big 4 firms. By examining industry risk exposure, revenue impact, AI adoption, fraud detection efficiency, client satisfaction, workforce performance, and project-related metrics, the queries uncover key business drivers that influence audit quality and financial outcomes. Together, these insights support data-driven decision-making, strengthen risk management strategies, and highlight opportunities to improve both operational efficiency and client value.

