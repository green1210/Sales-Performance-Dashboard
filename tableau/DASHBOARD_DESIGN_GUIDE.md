# Sales Performance Dashboard - Tableau Design Guide

## 📊 Dashboard Overview

**Purpose:** Interactive executive dashboard for monitoring sales performance, customer behavior, and product analytics

**Target Audience:** Sales managers, executives, marketing teams

**Update Frequency:** Daily/Weekly

---

## 🎯 Dashboard Structure

### Main Dashboard - Sales Performance Overview

**Dimensions:** 1920x1080 (Full HD)

---

## 📈 KPI Cards (Top Row)

Display 8 key performance indicators with color-coded indicators:

### 1. Total Revenue
- **Metric:** SUM([Revenue])
- **Format:** Currency ($)
- **Color:** Green if positive growth, Red if negative
- **Comparison:** MoM % change

### 2. Revenue Growth %
- **Metric:** (Current Month Revenue - Previous Month Revenue) / Previous Month Revenue
- **Format:** Percentage
- **Color:** Green (>0%), Yellow (0-5%), Red (<0%)

### 3. Conversion Rate
- **Metric:** COUNT([Transaction ID]) / (COUNTD([Customer ID]) * 1.5)
- **Format:** Percentage
- **Note:** Proxy calculation based on unique customers

### 4. Average Order Value (AOV)
- **Metric:** SUM([Revenue]) / COUNT([Transaction ID])
- **Format:** Currency ($)
- **Benchmark:** Industry standard $100-150

### 5. Customer Lifetime Value (CLV)
- **Metric:** AVG([Lifetime Value]) from customer_features dataset
- **Format:** Currency ($)
- **Segmentation:** By customer tier

### 6. Repeat Purchase Rate
- **Metric:** COUNT(IF [Purchase Count] > 1 THEN [Customer ID] END) / COUNTD([Customer ID])
- **Format:** Percentage
- **Target:** >40% is considered healthy

### 7. Top Category Revenue
- **Metric:** MAX(SUM([Revenue])) OVER (PARTITION BY [Product Category])
- **Format:** Currency ($) + Category Name
- **Display:** Category name with revenue

### 8. Monthly Sales Trend (Sparkline)
- **Metric:** SUM([Revenue]) by Month
- **Visualization:** Line chart (mini)
- **Color:** Gradient from blue to green

---

## 📊 Primary Visualizations

### Visualization 1: Revenue Over Time (Line Chart)
**Position:** Left, below KPIs  
**Size:** 50% width, 40% height

**Configuration:**
- **Chart Type:** Line chart with area fill
- **X-Axis:** Order Date (continuous, monthly aggregation)
- **Y-Axis:** Total Revenue (SUM)
- **Color:** Gradient blue (#2E86AB to #06AED5)
- **Tooltips:** 
  - Month
  - Total Revenue
  - MoM Growth %
  - Transaction Count
  - Unique Customers

**Calculated Fields:**
```tableau
// MoM Growth
(ZN(SUM([Revenue])) - LOOKUP(ZN(SUM([Revenue])), -1)) / 
ABS(LOOKUP(ZN(SUM([Revenue])), -1))

// 3-Month Moving Average
WINDOW_AVG(SUM([Revenue]), -2, 0)
```

**Features:**
- Trend line (linear regression)
- 3-month moving average (dashed line)
- Reference line for average revenue
- Date range filter

---

### Visualization 2: Category Performance (Horizontal Bar Chart)
**Position:** Right, below KPIs  
**Size:** 50% width, 40% height

**Configuration:**
- **Chart Type:** Horizontal bar chart
- **Rows:** Product Category (sorted by revenue descending)
- **Columns:** Total Revenue
- **Color:** Diverging color palette (red to green based on performance)
- **Tooltips:**
  - Category
  - Total Revenue
  - % of Total Revenue
  - Transaction Count
  - Average Order Value

**Calculated Fields:**
```tableau
// Revenue Contribution %
SUM([Revenue]) / TOTAL(SUM([Revenue]))

// Performance Rating
IF SUM([Revenue]) > 2000000 THEN "Excellent"
ELSEIF SUM([Revenue]) > 1000000 THEN "Good"
ELSEIF SUM([Revenue]) > 500000 THEN "Average"
ELSE "Below Average"
END
```

**Features:**
- Color gradient based on revenue
- Data labels showing revenue
- Quick filter for top N categories

---

### Visualization 3: Regional Sales Map
**Position:** Bottom left  
**Size:** 50% width, 30% height

**Configuration:**
- **Chart Type:** Filled map
- **Geography:** Region (custom geographic role)
- **Color:** Revenue (blue gradient)
- **Size:** Transaction count (optional)
- **Tooltips:**
  - Region
  - Total Revenue
  - Market Share %
  - Unique Customers
  - Average Order Value

**Regional Mapping:**
```tableau
// Create calculated field for coordinates
IF [Region] = "North" THEN 40.7128 // Latitude example
ELSEIF [Region] = "South" THEN 25.7617
ELSEIF [Region] = "East" THEN 42.3601
ELSEIF [Region] = "West" THEN 37.7749
ELSE 39.8283 // Central
END
```

**Features:**
- Color intensity by revenue
- Hover tooltips with detailed metrics
- Region selector filter

---

### Visualization 4: Customer Segmentation (Treemap)
**Position:** Bottom right  
**Size:** 50% width, 30% height

**Configuration:**
- **Chart Type:** Treemap
- **Dimensions:** Customer Type, Customer Segment (nested)
- **Size:** Count of Customers
- **Color:** Average Lifetime Value
- **Tooltips:**
  - Customer Type
  - Segment
  - Customer Count
  - Total Revenue
  - Avg CLV

**Customer Segments:**
- Champions
- Loyal Customers
- At Risk
- New Customers
- Lost Customers

---

## 🎨 Design Specifications

### Color Palette
- **Primary:** #2E86AB (Blue)
- **Secondary:** #A23B72 (Purple)
- **Accent 1:** #F18F01 (Orange)
- **Accent 2:** #C73E1D (Red)
- **Success:** #06D6A0 (Green)
- **Warning:** #FFD23F (Yellow)

### Typography
- **Title Font:** Tableau Book, 16pt, Bold
- **Subtitle:** Tableau Book, 12pt, Regular
- **KPI Numbers:** Tableau Medium, 24pt
- **Labels:** Tableau Book, 10pt

### Layout Guidelines
- **Margins:** 20px on all sides
- **Spacing:** 15px between elements
- **KPI Cards:** Equal width, 10px padding
- **Dashboard Background:** #F5F5F5 (Light gray)
- **Card Background:** #FFFFFF (White)

---

## 🔧 Interactive Filters

### Global Filters (Apply to all sheets)

1. **Date Range Filter**
   - Type: Relative date filter
   - Default: Last 12 months
   - Options: Last 30 days, 90 days, 6 months, 1 year, All time
   - Position: Top right

2. **Product Category**
   - Type: Multi-select dropdown
   - Default: All
   - Position: Top right

3. **Region**
   - Type: Multi-select dropdown
   - Default: All
   - Position: Top right

4. **Sales Channel**
   - Type: Single select (Online/Offline/All)
   - Default: All
   - Position: Top right

5. **Customer Type**
   - Type: Single select (New/Returning/All)
   - Default: All
   - Position: Top right

---

## 📊 Secondary Dashboard - Customer Analytics

### Components:

1. **RFM Segment Distribution** (Pie chart)
2. **Customer Lifetime Value by Segment** (Box plot)
3. **Cohort Retention Heatmap**
4. **Purchase Frequency Distribution** (Histogram)
5. **Top 20 Customers** (Table)

---

## 📊 Tertiary Dashboard - Product Performance

### Components:

1. **Top 10 Products by Revenue** (Bar chart)
2. **Bottom 10 Products** (Table)
3. **Discount Impact Analysis** (Scatter plot)
4. **Category-Region Heatmap**
5. **Product Lifecycle Stage** (Bubble chart)

---

## 🔗 Data Source Configuration

### Primary Data Source
- **File:** sales_data_clean.csv
- **Connection:** Extract (Hyper file)
- **Refresh Schedule:** Daily at 6 AM

### Secondary Data Source
- **File:** customer_features.csv
- **Relationship:** customer_id

### Pre-aggregated Sources
- monthly_summary.csv
- category_summary.csv
- region_summary.csv

---

## 📝 Calculated Fields Reference

### Revenue Metrics
```tableau
// Total Revenue
SUM([Revenue])

// Revenue Growth MoM
(ZN(SUM([Revenue])) - LOOKUP(ZN(SUM([Revenue])), -1)) / 
ABS(LOOKUP(ZN(SUM([Revenue])), -1))

// Revenue Per Customer
SUM([Revenue]) / COUNTD([Customer ID])
```

### Customer Metrics
```tableau
// Repeat Purchase Rate
COUNTD(IF [Purchase Count] > 1 THEN [Customer ID] END) / 
COUNTD([Customer ID])

// Average CLV
AVG([Lifetime Value])

// Customer Acquisition
COUNTD(IF [Customer Type] = "New" THEN [Customer ID] END)
```

### Product Metrics
```tableau
// AOV (Average Order Value)
SUM([Revenue]) / COUNTD([Transaction ID])

// Units Per Transaction
SUM([Quantity]) / COUNTD([Transaction ID])

// Discount Rate
AVG([Discount])
```

### Conversion Metrics
```tableau
// Estimated Conversion Rate
COUNTD([Transaction ID]) / (COUNTD([Customer ID]) * 1.5)

// Transaction Rate
COUNTD([Transaction ID]) / COUNTD([Customer ID])
```

---

## 🎬 Dashboard Actions

### Action 1: Filter by Category
- **Source:** Category Performance chart
- **Target:** All sheets
- **Action:** Click on category bar to filter entire dashboard

### Action 2: Regional Drill-Down
- **Source:** Regional map
- **Target:** Opens detail popup with regional KPIs
- **Action:** Click on region

### Action 3: Date Range Selection
- **Source:** Revenue over time chart
- **Target:** All sheets
- **Action:** Drag to select date range on timeline

### Action 4: Customer Segment Detail
- **Source:** Customer segmentation treemap
- **Target:** Opens customer detail dashboard
- **Action:** Click on segment

---

## 📤 Export & Sharing

### Dashboard Publishing
1. Publish to Tableau Public/Server
2. Set permissions (View/Edit)
3. Enable subscriptions for weekly email reports
4. Create mobile-optimized version

### Export Options
- PDF (Executive summary)
- PowerPoint (Presentation mode)
- Image (PNG, 300 DPI)
- Data (CSV export with filters applied)

---

## ✅ Dashboard Validation Checklist

- [ ] All KPIs display correctly with proper formatting
- [ ] Filters apply to all relevant sheets
- [ ] Tooltips show comprehensive information
- [ ] Color coding is consistent and meaningful
- [ ] Performance: Dashboard loads in <5 seconds
- [ ] Mobile responsive layout configured
- [ ] Data accuracy verified against SQL queries
- [ ] No null or error values displayed
- [ ] All calculated fields validated
- [ ] Cross-browser compatibility tested

---

## 🔄 Maintenance & Updates

### Weekly Tasks
- Verify data refresh completed successfully
- Check for any null values or anomalies
- Update benchmark values if needed

### Monthly Tasks
- Review and optimize calculated fields
- Update color thresholds based on business performance
- Add new filters based on user feedback

### Quarterly Tasks
- Performance optimization (extract vs live)
- Add new visualizations based on business needs
- User training and documentation updates

---

## 📚 Additional Resources

### Tableau Files to Create
1. `sales_dashboard_main.twbx` - Main dashboard
2. `customer_analytics.twbx` - Customer deep-dive
3. `product_performance.twbx` - Product analysis
4. `kpi_trends.twbx` - Time-series analysis

### Data Preparation
- Ensure all CSV files are in UTF-8 encoding
- Remove any special characters from column names
- Verify date formats are consistent (YYYY-MM-DD)
- Pre-aggregate large datasets for performance

---

**Dashboard Owner:** Data Analytics Team  
**Last Updated:** January 2026  
**Version:** 1.0
