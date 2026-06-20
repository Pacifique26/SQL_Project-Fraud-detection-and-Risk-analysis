use portfolioproject;

# BUSINESS INSIGHT QUERIES

## Storytelling insight the Business lines

### 1. Top Risk Industries

SELECT 
    Industry_Affected,
    SUM(High_Risk_Cases) AS total_risk,
    SUM(Fraud_Cases_Detected) AS total_fraud
FROM big4_financial_risk_compliance
GROUP BY Industry_Affected
ORDER BY total_risk DESC;

### 2. Revenue Impact vs Fraud

SELECT 
    Firm_Name,
    round(SUM(Total_Revenue_Impact), 2) AS revenue_loss,
    round(SUM(Fraud_Cases_Detected), 2) AS fraud_cases
FROM big4_financial_risk_compliance
GROUP BY Firm_Name
ORDER BY revenue_loss DESC;

# Estimated project revenue by firm

SELECT 
    Firm_Name,
    SUM(quantityOrdered * priceEach) AS Estimated_Revenue
FROM Project_details
GROUP BY Firm_Name;

# AI vs Non-AI Performance during the audit

SELECT 
    AI_Used_for_Auditing,
    round(AVG(Audit_Effectiveness_Score), 2) AS avg_effectiveness,
    round(AVG(Fraud_Cases_Detected), 2) AS avg_fraud_detected
FROM big4_financial_risk_compliance
GROUP BY AI_Used_for_Auditing;


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

# IMPACT: CLIENT SATISFACTION vs AUDIT QUALITY

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

# Let check Projects

## Average Fraud_risk by ProjectField

SELECT 
    pd.Firm_Name,
    pd.ProjectField,
    COUNT(pd.projectNumber) AS total_projects,
    round(AVG(p.PercentageProject_Fraud_Risk), 2) AS avg_risk
FROM Project_details pd
JOIN Project p ON pd.projectNumber = p.ProjectNumber
GROUP BY pd.Firm_Name, pd.ProjectField;

## Average Fraud_risk by Firm_name

SELECT 
    pd.Firm_Name,
    round(AVG(p.PercentageProject_Fraud_Risk),2) AS Avg_Fraud_Risk
FROM Project p
JOIN Project_details pd
ON p.ProjectNumber = pd.projectNumber
GROUP BY pd.Firm_Name;

# FRAUD RISK IMPACT ON COMPANIES
## Fraud detection: which firm converts risk into detected fraud most effectively?

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

# By UNION ANALYSIS let find the sum of fraud by company

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

# Employee Performance vs Workload
## Does higher workload reduce audit effectiveness?

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

# Project Risk Classification
## Risk distribution across industries

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

# Project duration: Time Analysis (2020-2025)

## Average time by Field of project
SELECT 
ProjectField,
AVG(DATEDIFF(Project_End_Date, Project_Start_Date)) AS Avg_Project_Duration
FROM Project
GROUP BY ProjectField;

## Project date-timing

SELECT ProjectNumber,
		MIN(Project_Start_Date) AS Start_of_project, 
		MAX(Project_End_Date) AS End_of_project
 FROM project
 GROUP BY ProjectNumber;

# RISK LEVEL: let find the 1st and 2nd high field risk cases by company 

SELECT Firm_Name, Industry_Affected, Total_Audit_Engagements, High_Risk_Cases, 
	ROW_NUMBER() OVER(ORDER BY High_Risk_Cases DESC) AS Top_Firm_Risk,
	RANK() OVER(ORDER BY High_Risk_Cases DESC) AS Top_Firm_Risk_R,
	Dense_rank() OVER(ORDER BY High_Risk_Cases desc) AS Top_Firm_Risk_DR
	FROM big4_financial_risk_compliance; 

SELECT * FROM
(SELECT Firm_Name, Industry_Affected, Total_Audit_Engagements, High_Risk_Cases, 
ROW_NUMBER() OVER(PARTITION BY Firm_Name ORDER BY High_Risk_Cases DESC) AS Top_Firm_Risk
FROM big4_financial_risk_compliance) AS Most_Hight
WHERE Top_Firm_Risk <=2;

# Looking for the Maximum price and budget in the project according to the field

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

 
 

 





