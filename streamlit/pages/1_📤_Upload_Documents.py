"""
DEMO PROJECT: AI Document Processing for Entertainment Industry
Streamlit File Upload Page

⚠️  NOT FOR PRODUCTION USE - EXAMPLE IMPLEMENTATION ONLY

PURPOSE:
    Allow users to upload PDF documents directly to Snowflake stage via
    drag-and-drop interface, automatically catalog them, and trigger AI processing.

FEATURES:
    - Multi-file drag-and-drop uploader
    - Automatic stage upload with SSE encryption
    - Document catalog registration
    - Processing status tracking
    - Support for multiple languages (EN, ES, DE, PT, RU, ZH)

Author: SE Community
Created: 2025-12-09 | Updated: 2025-12-10 | Expires: 2026-01-09
"""

import streamlit as st
from snowflake.snowpark.context import get_active_session
import uuid
from datetime import datetime
from pathlib import Path
import tempfile

# ============================================================================
# PAGE CONFIGURATION
# ============================================================================

st.set_page_config(
    page_title="Upload Documents",
    page_icon="📤",
    layout="wide"
)

# Get Snowflake session
session = get_active_session()

# ============================================================================
# HEADER
# ============================================================================

st.title("📤 Upload Documents")
st.markdown("""
Upload PDF documents to process with AI Functions. Documents will be:
1. Uploaded to encrypted Snowflake stage (`@DOCUMENT_STAGE`)
2. Cataloged in `DOCUMENT_CATALOG` table
3. Queued for AI processing (Parse → Translate → Classify → Extract)
""")

st.markdown("---")

# ============================================================================
# UPLOAD SECTION
# ============================================================================

st.header("📁 Upload Files")

# Document type selector
doc_type = st.selectbox(
    "Document Type",
    options=["INVOICE", "ROYALTY_STATEMENT", "CONTRACT", "OTHER"],
    help="Select the type of document you're uploading"
)

# Language selector
language = st.selectbox(
    "Original Language",
    options=["en", "es", "de", "pt", "ru", "zh", "fr", "ja", "ko"],
    format_func=lambda x: {
        "en": "English",
        "es": "Spanish",
        "de": "German",
        "pt": "Portuguese",
        "ru": "Russian",
        "zh": "Chinese",
        "fr": "French",
        "ja": "Japanese",
        "ko": "Korean"
    }.get(x, x),
    help="Select the primary language of the document"
)

# File uploader
uploaded_files = st.file_uploader(
    "Choose PDF files",
    type=["pdf"],
    accept_multiple_files=True,
    help="Upload one or more PDF documents (max 200MB each)"
)

st.markdown("---")

# ============================================================================
# UPLOAD PROCESSING
# ============================================================================

if uploaded_files:
    st.header("📊 Upload Status")

    # Progress tracking
    progress_bar = st.progress(0)
    status_text = st.empty()

    uploaded_count = 0
    failed_count = 0

    for idx, uploaded_file in enumerate(uploaded_files):
        try:
            # Update progress
            progress = (idx + 1) / len(uploaded_files)
            progress_bar.progress(progress)
            status_text.text(f"Processing {uploaded_file.name} ({idx + 1}/{len(uploaded_files)})...")

            # Generate unique document ID
            doc_id = f"DOC_{uuid.uuid4().hex[:12].upper()}"

            # Determine subdirectory based on document type
            subdirectory = {
                "INVOICE": "invoices",
                "ROYALTY_STATEMENT": "royalty",
                "CONTRACT": "contracts",
                "OTHER": "other"
            }.get(doc_type, "other")

            # Create stage path (fully qualified)
            stage_path = f"@SNOWFLAKE_EXAMPLE.SWIFTCLAW.DOCUMENT_STAGE/{subdirectory}/{uploaded_file.name}"

            # Upload file to Snowflake stage via PUT using a temporary file

            # Read file content
            file_content = uploaded_file.read()
            file_size = len(file_content)

            with st.spinner(f"Uploading {uploaded_file.name} to stage..."):
                with tempfile.NamedTemporaryFile(delete=False) as tmp:
                    tmp.write(file_content)
                    tmp_path = Path(tmp.name)

                put_sql = f"""
                PUT 'file://{tmp_path}'
                @SNOWFLAKE_EXAMPLE.SWIFTCLAW.DOCUMENT_STAGE/{subdirectory}/
                AUTO_COMPRESS=FALSE
                OVERWRITE=TRUE
                """
                session.sql(put_sql).collect()

                catalog_sql = f"""
                INSERT INTO SNOWFLAKE_EXAMPLE.SWIFTCLAW.RAW_DOCUMENT_CATALOG (
                    document_id,
                    document_type,
                    stage_name,
                    file_path,
                    file_name,
                    file_format,
                    file_size_bytes,
                    original_language,
                    processing_status,
                    metadata
                )
                VALUES (
                    '{doc_id}',
                    '{doc_type}',
                    '@SNOWFLAKE_EXAMPLE.SWIFTCLAW.DOCUMENT_STAGE',
                    '{subdirectory}/{uploaded_file.name}',
                    '{uploaded_file.name}',
                    'PDF',
                    {file_size},
                    '{language}',
                    'PENDING',
                    OBJECT_CONSTRUCT(
                        'upload_method', 'Streamlit UI',
                        'uploaded_at', CURRENT_TIMESTAMP()::STRING,
                        'file_ready', TRUE
                    )
                )
                """

                session.sql(catalog_sql).collect()

            uploaded_count += 1
            st.success(f"✅ {uploaded_file.name} cataloged successfully (ID: {doc_id})")

            # Show file info
            with st.expander(f"📄 {uploaded_file.name} Details"):
                st.write(f"**Document ID:** {doc_id}")
                st.write(f"**Type:** {doc_type}")
                st.write(f"**Language:** {language}")
                st.write(f"**Size:** {file_size:,} bytes ({file_size / 1024 / 1024:.2f} MB)")
                st.write(f"**Stage Path:** `{subdirectory}/{uploaded_file.name}`")

                # Save file temporarily for manual upload
                st.download_button(
                    label="⬇️ Download for Manual Upload",
                    data=file_content,
                    file_name=uploaded_file.name,
                    mime="application/pdf",
                    key=f"download_{doc_id}"
                )

        except Exception as e:
            failed_count += 1
            st.error(f"❌ Failed to process {uploaded_file.name}: {str(e)}")

    # Final summary
    progress_bar.progress(1.0)
    status_text.text("Upload complete!")

    st.markdown("---")
    st.subheader("📈 Upload Summary")

    col1, col2, col3 = st.columns(3)
    with col1:
        st.metric("Total Files", len(uploaded_files))
    with col2:
        st.metric("Successfully Cataloged", uploaded_count)
    with col3:
        st.metric("Failed", failed_count)

    # Next steps
    if uploaded_count > 0:
        st.markdown("---")
        st.success("✅ Files uploaded to stage. Run the AI processing pipeline below.")

        # Provide SQL to run processing
        with st.expander("🚀 Run AI Processing Pipeline"):
            st.markdown("""
            Copy this script into a new Snowsight worksheet and click **Run All**:
            """)

            st.code("""
-- Execute AI processing pipeline
USE ROLE ACCOUNTADMIN;
USE DATABASE SNOWFLAKE_EXAMPLE;
USE WAREHOUSE SFE_DOCUMENT_AI_WH;

-- 1. Parse documents (extract text and layout)
EXECUTE IMMEDIATE FROM @GIT_REPOS.sfe_swiftclaw_repo/branches/main/sql/03_ai_processing/01_parse_documents.sql;

-- 2. Translate non-English content
EXECUTE IMMEDIATE FROM @GIT_REPOS.sfe_swiftclaw_repo/branches/main/sql/03_ai_processing/02_translate_content.sql;

-- 3. Classify by document type and priority
EXECUTE IMMEDIATE FROM @GIT_REPOS.sfe_swiftclaw_repo/branches/main/sql/03_ai_processing/03_classify_documents.sql;

-- 4. Extract entities (amounts, dates, names)
EXECUTE IMMEDIATE FROM @GIT_REPOS.sfe_swiftclaw_repo/branches/main/sql/03_ai_processing/04_extract_entities.sql;

-- 5. Aggregate insights
EXECUTE IMMEDIATE FROM @GIT_REPOS.sfe_swiftclaw_repo/branches/main/sql/03_ai_processing/05_aggregate_insights.sql;

-- 6. View results
SELECT * FROM SNOWFLAKE_EXAMPLE.SWIFTCLAW.FCT_DOCUMENT_INSIGHTS
ORDER BY insight_created_at DESC
LIMIT 20;
            """, language="sql")

            st.info("⏱️ **Processing Time:** ~2-3 minutes for 6 documents")

# ============================================================================
# CURRENT CATALOG VIEW
# ============================================================================

st.markdown("---")
st.header("📋 Document Catalog")

catalog_query = """
SELECT
    document_id,
    document_type,
    file_name,
    file_format,
    ROUND(file_size_bytes / 1024.0 / 1024.0, 2) AS file_size_mb,
    original_language,
    processing_status,
    upload_date,
    last_processed_at
FROM SNOWFLAKE_EXAMPLE.SWIFTCLAW.RAW_DOCUMENT_CATALOG
ORDER BY upload_date DESC
LIMIT 50
"""

catalog_df = session.sql(catalog_query).to_pandas()

if not catalog_df.empty:
    st.write(f"**Showing {len(catalog_df)} most recent documents**")

    # Format for display
    display_df = catalog_df.copy()
    display_df.columns = [
        'Document ID',
        'Type',
        'File Name',
        'Format',
        'Size (MB)',
        'Language',
        'Status',
        'Uploaded',
        'Last Processed'
    ]

    # Add status emoji
    status_emoji = {
        'PENDING': '⏳',
        'PROCESSING': '🔄',
        'COMPLETED': '✅',
        'FAILED': '❌'
    }
    display_df['Status'] = display_df['Status'].apply(lambda x: f"{status_emoji.get(x, '❓')} {x}")

    st.dataframe(display_df, use_container_width=True, height=400)

    # Export option
    csv = catalog_df.to_csv(index=False).encode('utf-8')
    st.download_button(
        label="⬇️ Export Catalog to CSV",
        data=csv,
        file_name=f"document_catalog_{datetime.now().strftime('%Y%m%d_%H%M%S')}.csv",
        mime="text/csv"
    )
else:
    st.info("No documents in catalog yet. Upload some files above to get started!")

# ============================================================================
# INSTRUCTIONS
# ============================================================================

st.markdown("---")
st.header("📖 How It Works")

with st.expander("🔍 How the AI Pipeline Works"):
    st.markdown("""
    **STEP 1: Upload** 📤
    - Drag and drop PDFs in this interface
    - Files are cataloged in `DOCUMENT_CATALOG`
    - Complete upload via Snowsight UI (see instructions above)

    **STEP 2: Parse** 🔍 (`AI_PARSE_DOCUMENT`)
    - Extracts text and layout from PDFs
    - Handles OCR for scanned documents
    - Preserves document structure and formatting

    **STEP 3: Translate** 🌐 (`AI_TRANSLATE`)
    - Converts non-English content to English
    - Supports 50+ languages
    - Maintains context and proper nouns

    **STEP 4: Classify** 🏷️ (`AI_CLASSIFY`)
    - Determines document type and priority
    - Categorizes by business function
    - Assigns confidence scores

    **STEP 5: Extract** 🎯 (`AI_EXTRACT`)
    - Pulls key entities (amounts, dates, names)
    - No regex patterns required
    - Natural language understanding

    **STEP 6: Insights** 💡
    - Aggregated results in `FCT_DOCUMENT_INSIGHTS`
    - Real-time metrics in monitoring view
    - Manual review queue for low-confidence items

    **View results** in the main dashboard after processing completes!
    """)

with st.expander("🔐 Security & Encryption"):
    st.markdown("""
    **Server-Side Encryption (SSE)**
    - All documents encrypted at rest with `ENCRYPTION = (TYPE = 'SNOWFLAKE_SSE')`
    - Snowflake-managed encryption keys
    - Automatic encryption/decryption (transparent to AI Functions)
    - Zero configuration required

    **Access Controls**
    - Role-based access via `SFE_DEMO_ROLE`
    - Stage read/write permissions properly configured
    - Audit trail in `DOCUMENT_PROCESSING_LOG`
    - Error tracking in `DOCUMENT_ERRORS`

    **Best Practices for Production**
    - Use external stages (S3, Azure, GCS) with customer-managed keys
    - Implement row-level security for sensitive documents
    - Enable tag-based masking for PII fields
    - Configure Snowflake alerts for processing failures
    - Set up Snowpipe for automatic ingestion from cloud storage
    """)

# ============================================================================
# FOOTER
# ============================================================================

st.markdown("---")
st.markdown("""
**Reference Implementation Notice:**
This upload interface demonstrates Streamlit file handling patterns. For production, consider:
- Direct stage uploads via SnowSQL/Snow CLI for large batches
- Snowpipe for automatic ingestion from cloud storage
- External stages with event notifications for real-time processing

**Demo Expires:** 2026-01-09 | **Author:** SE Community
""")
