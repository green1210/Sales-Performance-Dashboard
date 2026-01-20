# Sales Performance Dashboard - Excel Automation Guide

## 📊 Overview

**Objective:** Create an automated Excel reporting system that reduces manual reporting time by 60%

**Key Features:**
- Automated data refresh via Power Query
- Dynamic pivot tables and charts
- KPI dashboard with conditional formatting
- One-click report generation

---

## 🎯 Excel Workbook Structure

### Workbook Name: `Sales_Performance_Report.xlsx`

**Worksheets:**
1. **Dashboard** - Executive KPI summary
2. **Revenue Analysis** - Detailed revenue breakdowns
3. **Customer Insights** - Customer segmentation and metrics
4. **Product Performance** - Product and category analysis
5. **Regional Analysis** - Geographic performance
6. **Raw Data** - Imported clean dataset
7. **Pivot Cache** - Hidden pivot table data source

---

## 📥 Power Query Setup (Automated Data Import)

### Step 1: Connect to Data Source

**Power Query Configuration:**
```
Source = Csv.Document(
    File.Contents("C:\Users\manik\OneDrive\Documents\My Projects\Sales Performance Dashboard\data\sales_data_clean.csv"),
    [Delimiter=",", Columns=24, Encoding=65001, QuoteStyle=QuoteStyle.None]
)

#"Promoted Headers" = Table.PromoteHeaders(Source, [PromoteAllScalars=true])

#"Changed Type" = Table.TransformColumnTypes(
    #"Promoted Headers",
    {
        {"transaction_id", Int64.Type},
        {"order_date", type date},
        {"customer_id", Int64.Type},
        {"product_id", Int64.Type},
        {"product_category", type text},
        {"quantity", Int64.Type},
        {"unit_price", type number},
        {"discount", type number},
        {"revenue", type number},
        {"region", type text},
        {"sales_channel", type text},
        {"customer_type", type text}
    }
)
```

### Step 2: Data Transformation Steps

**In Power Query Editor:**

1. **Remove Duplicates**
   - Select `transaction_id` column
   - Right-click → Remove Duplicates

2. **Add Custom Columns**
   ```powerquery
   // Year
   = Table.AddColumn(#"Changed Type", "Year", each Date.Year([order_date]))
   
   // Month
   = Table.AddColumn(#"Previous Step", "Month", each Date.Month([order_date]))
   
   // Quarter
   = Table.AddColumn(#"Previous Step", "Quarter", each "Q" & Text.From(Date.QuarterOfYear([order_date])))
   
   // Month Name
   = Table.AddColumn(#"Previous Step", "Month_Name", each Date.MonthName([order_date]))
   
   // Gross Revenue
   = Table.AddColumn(#"Previous Step", "Gross_Revenue", each [quantity] * [unit_price])
   
   // Discount Amount
   = Table.AddColumn(#"Previous Step", "Discount_Amount", each [Gross_Revenue] * [discount])
   ```

3. **Filter Invalid Data**
   - Filter out negative revenue values
   - Filter out null customer IDs

4. **Sort Data**
   - Sort by `order_date` (oldest to newest)

### Step 3: Load to Excel
- **Load To:** Table in worksheet "Raw Data"
- **Enable:** "Add to Data Model"
- **Refresh Settings:** 
  - ☑ Refresh data when opening the file
  - ☑ Enable background refresh

---

## 📊 Dashboard Sheet Design

### Layout Structure

**Dimensions:** A1:P30

**Section 1: KPI Cards (Row 1-5)**

| Cell Range | KPI | Formula |
|------------|-----|---------|
| B2:D4 | Total Revenue | `=SUM('Raw Data'[revenue])` |
| E2:G4 | Revenue Growth % | `=(Current_Month_Revenue - Previous_Month_Revenue) / Previous_Month_Revenue` |
| H2:J4 | Total Transactions | `=COUNTA('Raw Data'[transaction_id])` |
| K2:M4 | Unique Customers | `=SUMPRODUCT(1/COUNTIF('Raw Data'[customer_id],'Raw Data'[customer_id]))` |
| B6:D8 | Avg Order Value | `=AVERAGE('Raw Data'[revenue])` |
| E6:G8 | Conversion Rate | `=Total_Transactions / (Unique_Customers * 1.5)` |
| H6:J8 | Repeat Purchase Rate | Custom formula (see below) |
| K6:M8 | Top Category | `=INDEX(Categories, MATCH(MAX(Category_Revenue), Category_Revenue, 0))` |

**Conditional Formatting for KPIs:**
- Revenue Growth > 0: Green fill
- Revenue Growth < 0: Red fill
- Revenue Growth = 0: Yellow fill

### Section 2: Charts (Row 10-25)

**Chart 1: Monthly Revenue Trend (B10:G25)**
- **Type:** Line chart with markers
- **Data Source:** PivotTable1 (Monthly revenue)
- **X-Axis:** Month
- **Y-Axis:** Total Revenue
- **Features:**
  - Trendline (linear)
  - Data labels on last 3 months

**Chart 2: Category Performance (H10:M25)**
- **Type:** Horizontal bar chart
- **Data Source:** PivotTable2 (Category summary)
- **Categories:** Product categories
- **Values:** Total revenue
- **Sorting:** Descending by revenue

**Chart 3: Regional Distribution (B27:G42)**
- **Type:** Pie chart
- **Data Source:** PivotTable3 (Regional summary)
- **Values:** Total revenue
- **Labels:** Region names with percentages

**Chart 4: Channel Comparison (H27:M42)**
- **Type:** Clustered column chart
- **Data Source:** PivotTable4 (Channel analysis)
- **Categories:** Online vs Offline
- **Values:** Revenue, Transactions, AOV

---

## 🔄 Pivot Table Configurations

### PivotTable 1: Monthly Revenue Analysis

**Location:** Revenue Analysis sheet, Cell A1

**Configuration:**
```
Rows: Year, Month_Name (grouped by month)
Values: 
  - Sum of Revenue
  - Count of Transaction_ID
  - Distinct Count of Customer_ID
  - Average of Revenue (AOV)

Calculated Fields:
  - MoM Growth % = (Current_Revenue - Previous_Revenue) / Previous_Revenue
  - Revenue Per Customer = Sum_Revenue / Distinct_Customers
```

**Formula for Calculated Field (MoM Growth):**
```excel
=IFERROR(
    (SUM(Revenue) - OFFSET(SUM(Revenue), -1, 0)) / 
    OFFSET(SUM(Revenue), -1, 0),
    0
)
```

### PivotTable 2: Category Performance

**Location:** Product Performance sheet, Cell A1

**Configuration:**
```
Rows: Product_Category
Values:
  - Sum of Revenue
  - Count of Transaction_ID
  - Distinct Count of Product_ID
  - Average of Unit_Price

Sort: Sum of Revenue (Descending)
```

**Show Values As:**
- % of Grand Total (for revenue contribution)

### PivotTable 3: Regional Analysis

**Location:** Regional Analysis sheet, Cell A1

**Configuration:**
```
Rows: Region
Values:
  - Sum of Revenue
  - Distinct Count of Customer_ID
  - Count of Transaction_ID
  - Average of Revenue

Calculated Field:
  - Market Share % = (Region_Revenue / Total_Revenue) * 100
  - Revenue_Per_Customer = Sum_Revenue / Distinct_Customers
```

### PivotTable 4: Customer Segmentation

**Location:** Customer Insights sheet, Cell A1

**Configuration:**
```
Rows: Customer_Type
Values:
  - Distinct Count of Customer_ID
  - Sum of Revenue
  - Average of Revenue
  - Count of Transaction_ID

Calculated Field:
  - Transactions_Per_Customer = Count_Transactions / Distinct_Customers
  - Revenue_Contribution % = (Segment_Revenue / Total_Revenue) * 100
```

---

## 📐 Key Excel Formulas

### KPI Formulas

**1. Total Revenue**
```excel
=SUMIFS('Raw Data'[revenue], 'Raw Data'[order_date], ">="&StartDate, 'Raw Data'[order_date], "<="&EndDate)
```

**2. Revenue Growth %**
```excel
=LET(
    CurrentRevenue, SUMIFS('Raw Data'[revenue], 'Raw Data'[year_month], CurrentMonth),
    PreviousRevenue, SUMIFS('Raw Data'[revenue], 'Raw Data'[year_month], PreviousMonth),
    IFERROR((CurrentRevenue - PreviousRevenue) / PreviousRevenue, 0)
)
```

**3. Unique Customers**
```excel
=SUMPRODUCT(1/COUNTIFS('Raw Data'[customer_id], 'Raw Data'[customer_id], 
    'Raw Data'[order_date], ">="&StartDate, 'Raw Data'[order_date], "<="&EndDate))
```

**4. Average Order Value**
```excel
=AVERAGEIFS('Raw Data'[revenue], 'Raw Data'[order_date], ">="&StartDate, 
    'Raw Data'[order_date], "<="&EndDate)
```

**5. Repeat Purchase Rate**
```excel
=LET(
    TotalCustomers, SUMPRODUCT(1/COUNTIF('Raw Data'[customer_id], 'Raw Data'[customer_id])),
    RepeatCustomers, SUMPRODUCT(--(COUNTIF('Raw Data'[customer_id], 'Raw Data'[customer_id]) > 1) / 
                                  COUNTIF('Raw Data'[customer_id], 'Raw Data'[customer_id])),
    RepeatCustomers / TotalCustomers
)
```

**6. Top Category by Revenue**
```excel
=INDEX('Raw Data'[product_category], 
       MATCH(MAX(SUMIF('Raw Data'[product_category], 'Raw Data'[product_category], 'Raw Data'[revenue])),
             SUMIF('Raw Data'[product_category], 'Raw Data'[product_category], 'Raw Data'[revenue]), 0))
```

**7. Conversion Rate (Proxy)**
```excel
=LET(
    Transactions, COUNTA('Raw Data'[transaction_id]),
    Customers, SUMPRODUCT(1/COUNTIF('Raw Data'[customer_id], 'Raw Data'[customer_id])),
    Transactions / (Customers * 1.5)
)
```

---

## 🎨 Conditional Formatting Rules

### Dashboard KPI Cards

**Revenue Growth Cell:**
```
Rule 1: If >0, Fill: Green (RGB: 146, 208, 80), Font: White
Rule 2: If <0, Fill: Red (RGB: 255, 0, 0), Font: White
Rule 3: If =0, Fill: Yellow (RGB: 255, 192, 0), Font: Black
```

**AOV vs Benchmark:**
```
Rule 1: If >$150, Fill: Light Green
Rule 2: If $100-$150, Fill: Yellow
Rule 3: If <$100, Fill: Light Red
```

**Repeat Purchase Rate:**
```
Rule 1: If >50%, Fill: Green
Rule 2: If 30-50%, Fill: Yellow
Rule 3: If <30%, Fill: Red
```

### Data Tables

**Revenue Column (Color Scale):**
- Minimum: White
- Midpoint: Light Blue
- Maximum: Dark Blue

**Performance Indicators (Icon Sets):**
- Use 3-arrow icon set for growth metrics
- Green up arrow: >10% growth
- Yellow right arrow: 0-10% growth
- Red down arrow: <0% growth

---

## 🔧 VBA Macros (Optional Automation)

### Macro 1: Refresh All Data

```vba
Sub RefreshAllData()
    Application.ScreenUpdating = False
    Application.Calculation = xlCalculationManual
    
    ' Refresh Power Query
    ActiveWorkbook.Queries.Refresh
    
    ' Refresh all pivot tables
    Dim pt As PivotTable
    Dim ws As Worksheet
    
    For Each ws In ActiveWorkbook.Worksheets
        For Each pt In ws.PivotTables
            pt.RefreshTable
        Next pt
    Next ws
    
    Application.Calculation = xlCalculationAutomatic
    Application.ScreenUpdating = True
    
    MsgBox "Data refresh completed!", vbInformation
End Sub
```

### Macro 2: Export Dashboard as PDF

```vba
Sub ExportDashboard()
    Dim FilePath As String
    Dim FileName As String
    
    FileName = "Sales_Dashboard_" & Format(Date, "yyyy-mm-dd") & ".pdf"
    FilePath = ThisWorkbook.Path & "\" & FileName
    
    Sheets("Dashboard").ExportAsFixedFormat _
        Type:=xlTypePDF, _
        Filename:=FilePath, _
        Quality:=xlQualityStandard, _
        OpenAfterPublish:=True
        
    MsgBox "Dashboard exported to: " & FilePath, vbInformation
End Sub
```

### Macro 3: Update Date Range

```vba
Sub UpdateDateRange()
    Dim StartDate As Date
    Dim EndDate As Date
    
    StartDate = InputBox("Enter start date (mm/dd/yyyy):", "Date Range")
    EndDate = InputBox("Enter end date (mm/dd/yyyy):", "Date Range")
    
    ' Update named ranges
    Range("StartDate").Value = StartDate
    Range("EndDate").Value = EndDate
    
    ' Refresh calculations
    Call RefreshAllData
End Sub
```

---

## ⚙️ Named Ranges

Create named ranges for easy formula management:

| Name | Refers To | Purpose |
|------|-----------|---------|
| `StartDate` | Dashboard!$B$45 | Filter start date |
| `EndDate` | Dashboard!$B$46 | Filter end date |
| `CurrentMonth` | `=TEXT(TODAY(),"yyyy-mm")` | Current month identifier |
| `PreviousMonth` | `=TEXT(EDATE(TODAY(),-1),"yyyy-mm")` | Previous month identifier |
| `TotalRevenue` | `=SUM('Raw Data'[revenue])` | Total revenue metric |
| `Categories` | `='Raw Data'[product_category]` | Category list |

---

## 📱 Dashboard Interactivity

### Slicers

**Add 4 slicers for filtering:**

1. **Date Slicer (Timeline)**
   - Connected to all pivot tables
   - Period: Months
   - Default: Last 12 months

2. **Category Slicer**
   - Multi-select
   - Columns: 3
   - Style: Light

3. **Region Slicer**
   - Multi-select
   - Columns: 5 (one per region)

4. **Channel Slicer**
   - Single select
   - Radio button style

**Slicer Positioning:**
- Row 44-50 on Dashboard sheet
- Columns B:M

---

## 🚀 Performance Optimization

### Best Practices

1. **Use Tables Instead of Ranges**
   - Convert raw data to Excel Table (Ctrl+T)
   - Name the table: `SalesData`
   - Benefits: Auto-expand, structured references

2. **Optimize Formulas**
   - Replace SUMIF/COUNTIF with pivot tables where possible
   - Use SUMPRODUCT sparingly
   - Avoid volatile functions (NOW, TODAY, RAND) in large ranges

3. **Pivot Table Settings**
   - Disable "Save source data with file" for smaller file size
   - Use external data cache
   - Refresh on open (not on every change)

4. **Calculation Mode**
   - Set to Manual during large data updates
   - Use F9 to recalculate when needed

5. **Chart Optimization**
   - Limit data points to <1000 per chart
   - Use pivot charts instead of regular charts
   - Minimize chart animations

---

## 📊 Time Savings Analysis

### Manual Process (Before Automation)

| Task | Time (minutes) |
|------|----------------|
| Download/import data | 10 |
| Clean and format data | 15 |
| Create pivot tables | 20 |
| Update charts | 15 |
| Calculate KPIs | 10 |
| Format report | 20 |
| **Total** | **90 minutes** |

### Automated Process (After)

| Task | Time (minutes) |
|------|----------------|
| Click "Refresh All" button | 0.5 |
| Review updated dashboard | 5 |
| Export reports if needed | 2 |
| **Total** | **7.5 minutes** |

**Time Savings:** 82.5 minutes (92% reduction)  
**Monthly Savings:** 5.5 hours (assuming weekly reporting)  
**Annual Savings:** 66 hours

---

## ✅ Testing Checklist

**Before Deployment:**

- [ ] Power Query connection works on different machines
- [ ] All formulas calculate correctly
- [ ] Pivot tables refresh without errors
- [ ] Charts update automatically
- [ ] Conditional formatting displays correctly
- [ ] Slicers filter all relevant tables
- [ ] Named ranges are properly defined
- [ ] Macros run without errors (if used)
- [ ] File size is optimized (<10 MB)
- [ ] Print layout is configured
- [ ] PDF export works correctly
- [ ] Date filters function properly
- [ ] KPIs match SQL query results

---

## 📚 User Guide (Quick Reference)

### Daily Usage

1. **Open Workbook**
   - Data auto-refreshes on open
   - Wait for "Data Refresh Complete" message

2. **Adjust Filters**
   - Use slicers to filter by date, category, or region
   - Click "Clear Filter" to reset

3. **View Insights**
   - Dashboard tab: Executive summary
   - Other tabs: Detailed breakdowns

4. **Export Report**
   - Click "Export Dashboard" button
   - PDF saved to project folder

### Weekly Maintenance

1. Verify data source path is correct
2. Check for any #REF or #N/A errors
3. Validate KPIs against source data
4. Update benchmarks if needed

---

## 🔗 Integration with Other Tools

### Python Integration (Optional)

**Use Python to generate Excel with openpyxl:**

See: `notebooks/03_excel_export_automation.ipynb`

### Power BI Alternative

If Excel performance becomes an issue with larger datasets:
- Import same CSV files to Power BI
- Recreate dashboard with DAX measures
- Publish to Power BI Service

---

**Document Owner:** Data Analytics Team  
**Last Updated:** January 2026  
**Version:** 1.0
