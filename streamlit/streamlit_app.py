"""
DEMO PROJECT: AI Document Processing for Entertainment Industry
Streamlit Dashboard

⚠️  NOT FOR PRODUCTION USE - EXAMPLE IMPLEMENTATION ONLY

PURPOSE:
    Interactive dashboard for business users to explore document processing
    results, view insights, and monitor pipeline health.

FEATURES:
    - Pipeline health monitoring
    - Document processing metrics
    - Searchable document insights
    - Business value analytics
    - Manual review queue

Author: SE Community
Created: 2025-11-24 | Expires: 2025-12-24
"""

import streamlit as st
from snowflake.snowpark.context import get_active_session
import pandas as pd
import altair as alt

# ============================================================================
# PAGE CONFIGURATION
# ============================================================================

st.set_page_config(
    page_title="AI Document Processing Dashboard",
    page_icon="📄",
    layout="wide",
    initial_sidebar_state="expanded"
)

# Get Snowflake session
session = get_active_session()

# ============================================================================
# HEADER & INTRO
# ============================================================================

st.title("📄 AI Document Processing Dashboard")
st.markdown("""
**Demo Project:** AI-powered document processing for entertainment industry  
**Expires:** 2025-12-24 | **Author:** SE Community
""")

st.markdown("---")

# ============================================================================
# SIDEBAR FILTERS
# ============================================================================

st.sidebar.header("🔍 Filters")

# Document type filter
doc_types = st.sidebar.multiselect(
    "Document Type",
    options=["Invoice", "Royalty Statement", "Contract"],
    default=["Invoice", "Royalty Statement", "Contract"]
)

# Priority filter
priority_levels = st.sidebar.multiselect(
    "Priority Level",
    options=["High", "Medium", "Low"],
    default=["High", "Medium", "Low"]
)

# Manual review filter
show_review_only = st.sidebar.checkbox("Show Manual Review Queue Only", value=False)

# Date range filter
date_range = st.sidebar.date_input(
    "Document Date Range",
    value=None,
    help="Filter by document date (leave blank for all dates)"
)

st.sidebar.markdown("---")
st.sidebar.markdown("**Quick Actions**")
refresh_btn = st.sidebar.button("🔄 Refresh Data", use_container_width=True)

# ============================================================================
# SECTION 1: PIPELINE HEALTH (Top KPIs)
# ============================================================================

st.header("🏥 Pipeline Health")

# Query monitoring view
monitoring_sql = "SELECT * FROM SNOWFLAKE_EXAMPLE.SFE_ANALYTICS_ENTERTAINMENT.V_PROCESSING_METRICS"
monitoring_df = session.sql(monitoring_sql).to_pandas()

if not monitoring_df.empty:
    row = monitoring_df.iloc[0]
    
    # KPI Columns
    col1, col2, col3, col4, col5 = st.columns(5)
    
    with col1:
        st.metric(
            "Pipeline Health",
            row['PIPELINE_HEALTH_STATUS'],
            delta=f"{row['COMPLETION_PERCENTAGE']:.1f}% Complete"
        )
    
    with col2:
        st.metric(
            "Documents Processed",
            f"{int(row['INSIGHT_DOCUMENTS']):,}",
            delta=f"of {int(row['RAW_DOCUMENTS']):,} raw"
        )
    
    with col3:
        st.metric(
            "Avg Confidence",
            f"{row['AVG_OVERALL_CONFIDENCE']:.2%}",
            delta="Quality Score"
        )
    
    with col4:
        st.metric(
            "Manual Review Queue",
            f"{int(row['DOCUMENTS_NEEDING_REVIEW']):,}",
            delta=f"{row['MANUAL_REVIEW_PERCENTAGE']:.1f}% of total",
            delta_color="inverse"
        )
    
    with col5:
        st.metric(
            "Total Value Processed",
            f"${row['TOTAL_VALUE_PROCESSED_USD']:,.0f}",
            delta="USD"
        )

st.markdown("---")

# ============================================================================
# SECTION 2: DOCUMENT INSIGHTS TABLE
# ============================================================================

st.header("📊 Document Insights")

# Build dynamic SQL query based on filters
base_query = """
SELECT 
    insight_id,
    document_id,
    document_type,
    total_amount,
    currency,
    document_date,
    vendor_territory,
    confidence_score,
    requires_manual_review,
    metadata:priority_level::STRING AS priority_level,
    metadata:business_category::STRING AS business_category,
    processing_time_seconds,
    insight_created_at
FROM SNOWFLAKE_EXAMPLE.SFE_ANALYTICS_ENTERTAINMENT.FCT_DOCUMENT_INSIGHTS
WHERE 1=1
"""

# Apply filters
if doc_types:
    doc_type_list = ", ".join([f"'{dt}'" for dt in doc_types])
    base_query += f" AND document_type IN ({doc_type_list})"

if priority_levels:
    priority_list = ", ".join([f"'{pl}'" for pl in priority_levels])
    base_query += f" AND metadata:priority_level::STRING IN ({priority_list})"

if show_review_only:
    base_query += " AND requires_manual_review = TRUE"

base_query += " ORDER BY insight_created_at DESC LIMIT 1000"

# Execute query
insights_df = session.sql(base_query).to_pandas()

if not insights_df.empty:
    # Display count
    st.write(f"**Showing {len(insights_df):,} documents** (max 1,000)")
    
    # Format dataframe for display
    display_df = insights_df[[
        'DOCUMENT_TYPE', 
        'VENDOR_TERRITORY', 
        'TOTAL_AMOUNT', 
        'DOCUMENT_DATE',
        'PRIORITY_LEVEL',
        'CONFIDENCE_SCORE',
        'REQUIRES_MANUAL_REVIEW'
    ]].copy()
    
    display_df.columns = [
        'Type', 
        'Vendor/Territory', 
        'Amount', 
        'Date',
        'Priority',
        'Confidence',
        'Needs Review'
    ]
    
    # Format columns
    display_df['Amount'] = display_df['Amount'].apply(lambda x: f"${x:,.2f}" if pd.notna(x) else "N/A")
    display_df['Confidence'] = display_df['Confidence'].apply(lambda x: f"{x:.2%}" if pd.notna(x) else "N/A")
    display_df['Needs Review'] = display_df['Needs Review'].apply(lambda x: "⚠️ Yes" if x else "✅ No")
    
    # Display as interactive table
    st.dataframe(
        display_df,
        use_container_width=True,
        height=400
    )
else:
    st.info("No documents match the selected filters.")

st.markdown("---")

# ============================================================================
# SECTION 3: ANALYTICS & CHARTS
# ============================================================================

st.header("📈 Analytics")

if not insights_df.empty:
    # Create two columns for charts
    chart_col1, chart_col2 = st.columns(2)
    
    with chart_col1:
        st.subheader("Value by Document Type")
        
        # Aggregate by document type
        value_by_type = insights_df.groupby('DOCUMENT_TYPE')['TOTAL_AMOUNT'].sum().reset_index()
        value_by_type.columns = ['Document Type', 'Total Value']
        
        # Create bar chart
        chart1 = alt.Chart(value_by_type).mark_bar().encode(
            x=alt.X('Document Type:N', title='Document Type'),
            y=alt.Y('Total Value:Q', title='Total Value (USD)'),
            color='Document Type:N',
            tooltip=['Document Type:N', alt.Tooltip('Total Value:Q', format='$,.2f')]
        ).properties(height=300)
        
        st.altair_chart(chart1, use_container_width=True)
    
    with chart_col2:
        st.subheader("Documents by Priority")
        
        # Count by priority
        priority_counts = insights_df.groupby('PRIORITY_LEVEL').size().reset_index()
        priority_counts.columns = ['Priority', 'Count']
        
        # Create pie chart
        chart2 = alt.Chart(priority_counts).mark_arc().encode(
            theta='Count:Q',
            color=alt.Color('Priority:N', scale=alt.Scale(domain=['High', 'Medium', 'Low'], range=['#FF6B6B', '#FFA500', '#4ECDC4'])),
            tooltip=['Priority:N', 'Count:Q']
        ).properties(height=300)
        
        st.altair_chart(chart2, use_container_width=True)
    
    # Third chart: Confidence Distribution
    st.subheader("Confidence Score Distribution")
    
    chart3 = alt.Chart(insights_df).mark_bar().encode(
        x=alt.X('CONFIDENCE_SCORE:Q', bin=alt.Bin(step=0.05), title='Confidence Score'),
        y=alt.Y('count():Q', title='Number of Documents'),
        tooltip=['count():Q']
    ).properties(height=250)
    
    st.altair_chart(chart3, use_container_width=True)

st.markdown("---")

# ============================================================================
# SECTION 4: MANUAL REVIEW QUEUE
# ============================================================================

st.header("⚠️ Manual Review Queue")

st.info("""
**📋 Reference Implementation Note:**  
This section displays documents flagged for manual review based on low confidence scores or business rules. 
To build a production review workflow, consider these next steps:

**Option 1: Interactive Streamlit Review UI**
- Add expandable rows with `st.expander()` to show full document content
- Implement approval/rejection buttons with `st.button()` or `st.form()`
- Create stored procedures to update review status: `CALL UPDATE_REVIEW_STATUS(...)`
- Add user authentication and audit trail columns (reviewed_by, reviewed_at, notes)

**Option 2: Export to External Review System**
- Download queue data with `st.download_button()` as CSV
- Integrate with existing ticketing systems (Jira, ServiceNow)
- Use Snowflake tasks to send alerts via email/Slack
- Sync review decisions back to Snowflake via API/Snowpipe

**Option 3: Snowflake Native Workflow**
- Create dedicated review tables with status columns
- Build Snowsight dashboard with data editor for inline updates
- Use Snowflake alerts to notify reviewers of high-priority items
- Leverage row access policies to assign documents to specific reviewers
""")

review_query = """
SELECT 
    document_id,
    document_type,
    total_amount,
    vendor_territory,
    confidence_score,
    metadata:priority_level::STRING AS priority_level,
    insight_created_at
FROM SNOWFLAKE_EXAMPLE.SFE_ANALYTICS_ENTERTAINMENT.FCT_DOCUMENT_INSIGHTS
WHERE requires_manual_review = TRUE
ORDER BY 
    CASE metadata:priority_level::STRING 
        WHEN 'High' THEN 1 
        WHEN 'Medium' THEN 2 
        ELSE 3 
    END,
    confidence_score ASC
LIMIT 50
"""

review_df = session.sql(review_query).to_pandas()

if not review_df.empty:
    st.write(f"**{len(review_df)} documents require manual review** (showing top 50 by priority)")
    
    # Format for display
    review_display = review_df[[
        'DOCUMENT_TYPE',
        'VENDOR_TERRITORY',
        'TOTAL_AMOUNT',
        'PRIORITY_LEVEL',
        'CONFIDENCE_SCORE',
        'INSIGHT_CREATED_AT'
    ]].copy()
    
    review_display.columns = ['Type', 'Vendor/Territory', 'Amount', 'Priority', 'Confidence', 'Created']
    review_display['Amount'] = review_display['Amount'].apply(lambda x: f"${x:,.2f}" if pd.notna(x) else "N/A")
    review_display['Confidence'] = review_display['Confidence'].apply(lambda x: f"{x:.2%}" if pd.notna(x) else "N/A")
    
    st.dataframe(review_display, use_container_width=True, height=300)
    
    # Export option
    st.download_button(
        label="⬇️ Export Review Queue to CSV",
        data=review_display.to_csv(index=False).encode('utf-8'),
        file_name=f"review_queue_{pd.Timestamp.now().strftime('%Y%m%d_%H%M%S')}.csv",
        mime="text/csv",
        help="Download this queue for offline review or import into external systems"
    )
else:
    st.success("✅ No documents currently require manual review!")

# ============================================================================
# FOOTER
# ============================================================================

st.markdown("---")
st.markdown("""
**Reference Implementation Notice:**  
This dashboard demonstrates production-grade patterns for AI document processing. Review and customize for your organization's specific requirements before deployment.

**Data Source:** `SNOWFLAKE_EXAMPLE.SFE_ANALYTICS_ENTERTAINMENT`  
**Refresh:** Data updates automatically when underlying tables are refreshed  
**Demo Expires:** 2025-12-24
""")

