#!/usr/bin/env python3
"""
Generate Sample PDF Documents for AI Document Processing Demo

Creates realistic sample documents across multiple types and languages
for demonstrating Snowflake Cortex AI Functions.

Document Types:
- Invoices (billing documents)
- Royalty Statements (entertainment industry payments)
- Contracts (licensing agreements)

Languages:
- English (en)
- Spanish (es)
- German (de)
- Portuguese (pt)
- Russian (ru)
- Chinese (zh)

Author: SE Community
"""

from fpdf import FPDF
from datetime import datetime, timedelta
import random
import os

# Output directory
OUTPUT_DIR = os.path.join(os.path.dirname(os.path.dirname(__file__)), "pdfs", "generated")


class MultilingualPDF(FPDF):
    """PDF class with Unicode support for multiple languages."""
    
    def __init__(self):
        super().__init__()
        # Use built-in fonts that support basic Latin characters
        # For full Unicode (Russian, Chinese), we'd need to add custom fonts
        self.set_auto_page_break(auto=True, margin=15)


def generate_invoice(lang: str, invoice_num: int) -> str:
    """Generate an invoice PDF in the specified language."""
    
    # Content templates by language
    content = {
        "en": {
            "title": "INVOICE",
            "invoice_number": "Invoice Number",
            "date": "Date",
            "due_date": "Due Date",
            "bill_to": "Bill To",
            "description": "Description",
            "quantity": "Qty",
            "unit_price": "Unit Price",
            "total": "Total",
            "subtotal": "Subtotal",
            "tax": "Tax (8%)",
            "grand_total": "Grand Total",
            "payment_terms": "Payment Terms: Net 30",
            "thank_you": "Thank you for your business!",
            "company": "Acme Production Services",
            "items": [
                ("Video Production Services", 40, 150.00),
                ("Post-Production Editing", 24, 125.00),
                ("Sound Design & Mixing", 16, 175.00),
                ("Color Grading", 8, 200.00),
            ]
        },
        "es": {
            "title": "FACTURA",
            "invoice_number": "Numero de Factura",
            "date": "Fecha",
            "due_date": "Fecha de Vencimiento",
            "bill_to": "Facturar A",
            "description": "Descripcion",
            "quantity": "Cant",
            "unit_price": "Precio Unitario",
            "total": "Total",
            "subtotal": "Subtotal",
            "tax": "Impuesto (8%)",
            "grand_total": "Total General",
            "payment_terms": "Terminos de Pago: 30 dias netos",
            "thank_you": "Gracias por su negocio!",
            "company": "Servicios de Produccion Acme",
            "items": [
                ("Servicios de Produccion de Video", 40, 150.00),
                ("Edicion de Post-Produccion", 24, 125.00),
                ("Diseno de Sonido y Mezcla", 16, 175.00),
                ("Correccion de Color", 8, 200.00),
            ]
        },
        "de": {
            "title": "RECHNUNG",
            "invoice_number": "Rechnungsnummer",
            "date": "Datum",
            "due_date": "Faelligkeitsdatum",
            "bill_to": "Rechnung An",
            "description": "Beschreibung",
            "quantity": "Menge",
            "unit_price": "Einzelpreis",
            "total": "Gesamt",
            "subtotal": "Zwischensumme",
            "tax": "Steuer (8%)",
            "grand_total": "Gesamtbetrag",
            "payment_terms": "Zahlungsbedingungen: 30 Tage netto",
            "thank_you": "Vielen Dank fuer Ihren Auftrag!",
            "company": "Acme Produktionsdienstleistungen",
            "items": [
                ("Videoproduktionsdienste", 40, 150.00),
                ("Postproduktionsbearbeitung", 24, 125.00),
                ("Sounddesign und Mischung", 16, 175.00),
                ("Farbkorrektur", 8, 200.00),
            ]
        },
        "pt": {
            "title": "FATURA",
            "invoice_number": "Numero da Fatura",
            "date": "Data",
            "due_date": "Data de Vencimento",
            "bill_to": "Cobrar De",
            "description": "Descricao",
            "quantity": "Qtd",
            "unit_price": "Preco Unitario",
            "total": "Total",
            "subtotal": "Subtotal",
            "tax": "Imposto (8%)",
            "grand_total": "Total Geral",
            "payment_terms": "Condicoes de Pagamento: 30 dias liquidos",
            "thank_you": "Obrigado pelo seu negocio!",
            "company": "Servicos de Producao Acme",
            "items": [
                ("Servicos de Producao de Video", 40, 150.00),
                ("Edicao de Pos-Producao", 24, 125.00),
                ("Design de Som e Mixagem", 16, 175.00),
                ("Correcao de Cores", 8, 200.00),
            ]
        },
    }
    
    c = content.get(lang, content["en"])
    
    pdf = MultilingualPDF()
    pdf.add_page()
    
    # Header
    pdf.set_font("Helvetica", "B", 24)
    pdf.cell(0, 15, c["title"], ln=True, align="C")
    
    pdf.set_font("Helvetica", "", 10)
    pdf.cell(0, 8, c["company"], ln=True, align="C")
    pdf.cell(0, 5, "123 Media Boulevard, Los Angeles, CA 90028", ln=True, align="C")
    pdf.ln(10)
    
    # Invoice details
    pdf.set_font("Helvetica", "B", 11)
    invoice_date = datetime.now() - timedelta(days=random.randint(1, 60))
    due_date = invoice_date + timedelta(days=30)
    
    pdf.cell(95, 8, f"{c['invoice_number']}: INV-2024-{invoice_num:04d}", ln=False)
    pdf.cell(95, 8, f"{c['date']}: {invoice_date.strftime('%Y-%m-%d')}", ln=True, align="R")
    pdf.cell(95, 8, f"{c['due_date']}: {due_date.strftime('%Y-%m-%d')}", ln=True, align="R")
    pdf.ln(5)
    
    # Bill to
    pdf.set_font("Helvetica", "B", 11)
    pdf.cell(0, 8, c["bill_to"] + ":", ln=True)
    pdf.set_font("Helvetica", "", 10)
    clients = ["Global Studios Inc", "MediaTech Solutions", "Film Finance Co", "Creative Partners LLC"]
    pdf.cell(0, 6, random.choice(clients), ln=True)
    pdf.cell(0, 6, "456 Entertainment Way", ln=True)
    pdf.cell(0, 6, "Beverly Hills, CA 90210", ln=True)
    pdf.ln(10)
    
    # Table header
    pdf.set_font("Helvetica", "B", 10)
    pdf.set_fill_color(240, 240, 240)
    pdf.cell(80, 8, c["description"], border=1, fill=True)
    pdf.cell(25, 8, c["quantity"], border=1, fill=True, align="C")
    pdf.cell(40, 8, c["unit_price"], border=1, fill=True, align="R")
    pdf.cell(45, 8, c["total"], border=1, fill=True, align="R", ln=True)
    
    # Table rows
    pdf.set_font("Helvetica", "", 10)
    subtotal = 0
    for desc, qty, price in c["items"]:
        line_total = qty * price
        subtotal += line_total
        pdf.cell(80, 7, desc, border=1)
        pdf.cell(25, 7, str(qty), border=1, align="C")
        pdf.cell(40, 7, f"${price:,.2f}", border=1, align="R")
        pdf.cell(45, 7, f"${line_total:,.2f}", border=1, align="R", ln=True)
    
    # Totals
    pdf.ln(5)
    tax = subtotal * 0.08
    grand_total = subtotal + tax
    
    pdf.set_font("Helvetica", "", 10)
    pdf.cell(145, 7, c["subtotal"] + ":", align="R")
    pdf.cell(45, 7, f"${subtotal:,.2f}", align="R", ln=True)
    pdf.cell(145, 7, c["tax"] + ":", align="R")
    pdf.cell(45, 7, f"${tax:,.2f}", align="R", ln=True)
    pdf.set_font("Helvetica", "B", 11)
    pdf.cell(145, 8, c["grand_total"] + ":", align="R")
    pdf.cell(45, 8, f"${grand_total:,.2f}", align="R", ln=True)
    
    # Footer
    pdf.ln(15)
    pdf.set_font("Helvetica", "I", 10)
    pdf.cell(0, 8, c["payment_terms"], ln=True, align="C")
    pdf.cell(0, 8, c["thank_you"], ln=True, align="C")
    
    filename = f"invoice_{lang}_{invoice_num:03d}.pdf"
    filepath = os.path.join(OUTPUT_DIR, filename)
    pdf.output(filepath)
    return filename


def generate_royalty_statement(lang: str, stmt_num: int) -> str:
    """Generate a royalty statement PDF in the specified language."""
    
    content = {
        "en": {
            "title": "ROYALTY STATEMENT",
            "period": "Reporting Period",
            "territory": "Territory",
            "recipient": "Payee",
            "title_col": "Title",
            "units": "Units",
            "rate": "Rate",
            "amount": "Amount",
            "total_royalties": "Total Royalties Due",
            "payment_date": "Payment Date",
            "company": "Global Entertainment Royalties Inc.",
            "territories": ["North America", "Europe", "Asia Pacific", "Latin America"],
        },
        "es": {
            "title": "DECLARACION DE REGALIAS",
            "period": "Periodo de Informe",
            "territory": "Territorio",
            "recipient": "Beneficiario",
            "title_col": "Titulo",
            "units": "Unidades",
            "rate": "Tasa",
            "amount": "Monto",
            "total_royalties": "Total de Regalias Adeudadas",
            "payment_date": "Fecha de Pago",
            "company": "Global Entertainment Royalties Inc.",
            "territories": ["America del Norte", "Europa", "Asia Pacifico", "America Latina"],
        },
        "de": {
            "title": "LIZENZGEBUEHRENABRECHNUNG",
            "period": "Berichtszeitraum",
            "territory": "Territorium",
            "recipient": "Zahlungsempfaenger",
            "title_col": "Titel",
            "units": "Einheiten",
            "rate": "Satz",
            "amount": "Betrag",
            "total_royalties": "Gesamte faellige Lizenzgebuehren",
            "payment_date": "Zahlungsdatum",
            "company": "Global Entertainment Royalties Inc.",
            "territories": ["Nordamerika", "Europa", "Asien-Pazifik", "Lateinamerika"],
        },
        "pt": {
            "title": "DEMONSTRATIVO DE ROYALTIES",
            "period": "Periodo do Relatorio",
            "territory": "Territorio",
            "recipient": "Beneficiario",
            "title_col": "Titulo",
            "units": "Unidades",
            "rate": "Taxa",
            "amount": "Valor",
            "total_royalties": "Total de Royalties Devidos",
            "payment_date": "Data de Pagamento",
            "company": "Global Entertainment Royalties Inc.",
            "territories": ["America do Norte", "Europa", "Asia-Pacifico", "America Latina"],
        },
    }
    
    c = content.get(lang, content["en"])
    
    pdf = MultilingualPDF()
    pdf.add_page()
    
    # Header
    pdf.set_font("Helvetica", "B", 20)
    pdf.cell(0, 12, c["title"], ln=True, align="C")
    pdf.set_font("Helvetica", "", 10)
    pdf.cell(0, 6, c["company"], ln=True, align="C")
    pdf.ln(10)
    
    # Statement details
    period_start = datetime(2024, random.choice([1, 4, 7, 10]), 1)
    period_end = period_start + timedelta(days=89)
    territory = random.choice(c["territories"])
    
    pdf.set_font("Helvetica", "B", 11)
    pdf.cell(50, 8, c["period"] + ":")
    pdf.set_font("Helvetica", "", 11)
    pdf.cell(0, 8, f"{period_start.strftime('%Y-%m-%d')} to {period_end.strftime('%Y-%m-%d')}", ln=True)
    
    pdf.set_font("Helvetica", "B", 11)
    pdf.cell(50, 8, c["territory"] + ":")
    pdf.set_font("Helvetica", "", 11)
    pdf.cell(0, 8, territory, ln=True)
    
    pdf.set_font("Helvetica", "B", 11)
    pdf.cell(50, 8, c["recipient"] + ":")
    pdf.set_font("Helvetica", "", 11)
    artists = ["Stellar Productions", "Creative Artists Group", "Independent Films LLC", "Music Rights Holdings"]
    pdf.cell(0, 8, random.choice(artists), ln=True)
    pdf.ln(10)
    
    # Titles table
    pdf.set_font("Helvetica", "B", 10)
    pdf.set_fill_color(240, 240, 240)
    pdf.cell(70, 8, c["title_col"], border=1, fill=True)
    pdf.cell(35, 8, c["units"], border=1, fill=True, align="C")
    pdf.cell(40, 8, c["rate"], border=1, fill=True, align="R")
    pdf.cell(45, 8, c["amount"], border=1, fill=True, align="R", ln=True)
    
    titles = [
        ("The Last Horizon", random.randint(10000, 50000), 0.15),
        ("Midnight Symphony", random.randint(5000, 25000), 0.12),
        ("Desert Wind", random.randint(8000, 40000), 0.18),
        ("City Lights", random.randint(15000, 60000), 0.10),
        ("Ocean Dreams", random.randint(3000, 15000), 0.20),
    ]
    
    pdf.set_font("Helvetica", "", 10)
    total = 0
    for title, units, rate in titles:
        amount = units * rate
        total += amount
        pdf.cell(70, 7, title, border=1)
        pdf.cell(35, 7, f"{units:,}", border=1, align="C")
        pdf.cell(40, 7, f"${rate:.2f}", border=1, align="R")
        pdf.cell(45, 7, f"${amount:,.2f}", border=1, align="R", ln=True)
    
    # Total
    pdf.ln(5)
    pdf.set_font("Helvetica", "B", 12)
    pdf.cell(145, 10, c["total_royalties"] + ":", align="R")
    pdf.cell(45, 10, f"${total:,.2f}", align="R", ln=True)
    
    pdf.ln(5)
    pdf.set_font("Helvetica", "", 10)
    payment_date = period_end + timedelta(days=45)
    pdf.cell(0, 8, f"{c['payment_date']}: {payment_date.strftime('%Y-%m-%d')}", ln=True)
    
    filename = f"royalty_{lang}_{stmt_num:03d}.pdf"
    filepath = os.path.join(OUTPUT_DIR, filename)
    pdf.output(filepath)
    return filename


def generate_contract(lang: str, contract_num: int) -> str:
    """Generate a contract PDF in the specified language."""
    
    content = {
        "en": {
            "title": "LICENSING AGREEMENT",
            "parties": "PARTIES",
            "party_a": "Party A (Licensor)",
            "party_b": "Party B (Licensee)",
            "effective_date": "Effective Date",
            "term": "Term",
            "territory": "Licensed Territory",
            "consideration": "Consideration",
            "terms_title": "TERMS AND CONDITIONS",
            "signature": "SIGNATURES",
            "terms": [
                "1. GRANT OF LICENSE: Licensor hereby grants to Licensee a non-exclusive license to distribute the Licensed Content in the Territory.",
                "2. TERM: This Agreement shall commence on the Effective Date and continue for the period specified above.",
                "3. PAYMENT: Licensee shall pay Licensor the Consideration amount within 30 days of execution.",
                "4. INTELLECTUAL PROPERTY: All intellectual property rights remain with the Licensor.",
                "5. CONFIDENTIALITY: Both parties agree to maintain confidentiality of all proprietary information.",
                "6. TERMINATION: Either party may terminate with 90 days written notice.",
            ],
        },
        "es": {
            "title": "ACUERDO DE LICENCIA",
            "parties": "PARTES",
            "party_a": "Parte A (Licenciante)",
            "party_b": "Parte B (Licenciatario)",
            "effective_date": "Fecha de Vigencia",
            "term": "Plazo",
            "territory": "Territorio Licenciado",
            "consideration": "Contraprestacion",
            "terms_title": "TERMINOS Y CONDICIONES",
            "signature": "FIRMAS",
            "terms": [
                "1. OTORGAMIENTO DE LICENCIA: El Licenciante otorga al Licenciatario una licencia no exclusiva para distribuir el Contenido en el Territorio.",
                "2. PLAZO: Este Acuerdo comenzara en la Fecha de Vigencia y continuara por el periodo especificado.",
                "3. PAGO: El Licenciatario pagara al Licenciante el monto de Contraprestacion dentro de 30 dias.",
                "4. PROPIEDAD INTELECTUAL: Todos los derechos de propiedad intelectual permanecen con el Licenciante.",
                "5. CONFIDENCIALIDAD: Ambas partes acuerdan mantener la confidencialidad de toda informacion.",
                "6. TERMINACION: Cualquier parte puede terminar con 90 dias de aviso por escrito.",
            ],
        },
        "de": {
            "title": "LIZENZVEREINBARUNG",
            "parties": "PARTEIEN",
            "party_a": "Partei A (Lizenzgeber)",
            "party_b": "Partei B (Lizenznehmer)",
            "effective_date": "Wirksamkeitsdatum",
            "term": "Laufzeit",
            "territory": "Lizenziertes Gebiet",
            "consideration": "Gegenleistung",
            "terms_title": "GESCHAEFTSBEDINGUNGEN",
            "signature": "UNTERSCHRIFTEN",
            "terms": [
                "1. LIZENZGEWAEHRUNG: Der Lizenzgeber gewaehrt dem Lizenznehmer eine nicht-exklusive Lizenz zur Verbreitung.",
                "2. LAUFZEIT: Diese Vereinbarung beginnt am Wirksamkeitsdatum und laeuft fuer den angegebenen Zeitraum.",
                "3. ZAHLUNG: Der Lizenznehmer zahlt dem Lizenzgeber den Gegenleistungsbetrag innerhalb von 30 Tagen.",
                "4. GEISTIGES EIGENTUM: Alle geistigen Eigentumsrechte verbleiben beim Lizenzgeber.",
                "5. VERTRAULICHKEIT: Beide Parteien vereinbaren die Vertraulichkeit aller Informationen.",
                "6. KUENDIGUNG: Jede Partei kann mit 90 Tagen schriftlicher Kuendigung beenden.",
            ],
        },
        "pt": {
            "title": "CONTRATO DE LICENCIAMENTO",
            "parties": "PARTES",
            "party_a": "Parte A (Licenciador)",
            "party_b": "Parte B (Licenciado)",
            "effective_date": "Data de Vigencia",
            "term": "Prazo",
            "territory": "Territorio Licenciado",
            "consideration": "Contraprestacao",
            "terms_title": "TERMOS E CONDICOES",
            "signature": "ASSINATURAS",
            "terms": [
                "1. CONCESSAO DE LICENCA: O Licenciador concede ao Licenciado uma licenca nao exclusiva para distribuir o Conteudo.",
                "2. PRAZO: Este Contrato comecara na Data de Vigencia e continuara pelo periodo especificado.",
                "3. PAGAMENTO: O Licenciado pagara ao Licenciador o valor da Contraprestacao em 30 dias.",
                "4. PROPRIEDADE INTELECTUAL: Todos os direitos de propriedade intelectual permanecem com o Licenciador.",
                "5. CONFIDENCIALIDADE: Ambas as partes concordam em manter a confidencialidade de todas as informacoes.",
                "6. RESCISAO: Qualquer parte pode rescindir com 90 dias de aviso previo por escrito.",
            ],
        },
    }
    
    c = content.get(lang, content["en"])
    
    pdf = MultilingualPDF()
    pdf.add_page()
    
    # Header
    pdf.set_font("Helvetica", "B", 18)
    pdf.cell(0, 12, c["title"], ln=True, align="C")
    pdf.ln(5)
    
    # Parties section
    pdf.set_font("Helvetica", "B", 12)
    pdf.cell(0, 8, c["parties"], ln=True)
    pdf.set_font("Helvetica", "", 10)
    
    licensors = ["Paramount Media Holdings", "Universal Content Group", "Warner Distribution LLC", "Sony Pictures Entertainment"]
    licensees = ["Netflix International", "Amazon Prime Video", "Disney+ Worldwide", "HBO Max Global"]
    
    pdf.cell(50, 7, c["party_a"] + ":")
    pdf.cell(0, 7, random.choice(licensors), ln=True)
    pdf.cell(50, 7, c["party_b"] + ":")
    pdf.cell(0, 7, random.choice(licensees), ln=True)
    pdf.ln(5)
    
    # Contract details
    effective_date = datetime.now() - timedelta(days=random.randint(1, 180))
    term_years = random.choice([1, 2, 3, 5])
    territories = ["Worldwide", "North America", "Europe", "Asia Pacific", "Latin America"]
    consideration = random.randint(50, 500) * 10000
    
    pdf.set_font("Helvetica", "B", 10)
    pdf.cell(50, 7, c["effective_date"] + ":")
    pdf.set_font("Helvetica", "", 10)
    pdf.cell(0, 7, effective_date.strftime("%Y-%m-%d"), ln=True)
    
    pdf.set_font("Helvetica", "B", 10)
    pdf.cell(50, 7, c["term"] + ":")
    pdf.set_font("Helvetica", "", 10)
    pdf.cell(0, 7, f"{term_years} year(s)", ln=True)
    
    pdf.set_font("Helvetica", "B", 10)
    pdf.cell(50, 7, c["territory"] + ":")
    pdf.set_font("Helvetica", "", 10)
    pdf.cell(0, 7, random.choice(territories), ln=True)
    
    pdf.set_font("Helvetica", "B", 10)
    pdf.cell(50, 7, c["consideration"] + ":")
    pdf.set_font("Helvetica", "", 10)
    pdf.cell(0, 7, f"${consideration:,} USD", ln=True)
    pdf.ln(10)
    
    # Terms and conditions
    pdf.set_font("Helvetica", "B", 12)
    pdf.cell(0, 8, c["terms_title"], ln=True)
    pdf.ln(3)
    
    pdf.set_font("Helvetica", "", 9)
    for term in c["terms"]:
        pdf.multi_cell(0, 5, term)
        pdf.ln(2)
    
    # Signature block
    pdf.ln(10)
    pdf.set_font("Helvetica", "B", 12)
    pdf.cell(0, 8, c["signature"], ln=True)
    pdf.ln(15)
    
    pdf.set_font("Helvetica", "", 10)
    pdf.cell(90, 5, "_" * 35)
    pdf.cell(10, 5, "")
    pdf.cell(90, 5, "_" * 35, ln=True)
    pdf.cell(90, 5, c["party_a"])
    pdf.cell(10, 5, "")
    pdf.cell(90, 5, c["party_b"], ln=True)
    
    filename = f"contract_{lang}_{contract_num:03d}.pdf"
    filepath = os.path.join(OUTPUT_DIR, filename)
    pdf.output(filepath)
    return filename


def main():
    """Generate all sample PDFs."""
    
    # Create output directory
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    
    print("=" * 60)
    print("Generating Sample PDFs for AI Document Processing Demo")
    print("=" * 60)
    
    generated_files = []
    
    # Languages to generate (excluding ru/zh which need special font handling)
    languages = ["en", "es", "de", "pt"]
    
    # Generate Invoices (6 total: 2 en, 2 es, 1 de, 1 pt)
    print("\n📄 Generating Invoices...")
    invoice_distribution = [("en", 1), ("en", 2), ("es", 3), ("es", 4), ("de", 5), ("pt", 6)]
    for lang, num in invoice_distribution:
        filename = generate_invoice(lang, num)
        generated_files.append(("Invoice", lang, filename))
        print(f"   ✓ {filename}")
    
    # Generate Royalty Statements (6 total: 2 en, 2 es, 1 de, 1 pt)
    print("\n💰 Generating Royalty Statements...")
    royalty_distribution = [("en", 1), ("en", 2), ("es", 3), ("es", 4), ("de", 5), ("pt", 6)]
    for lang, num in royalty_distribution:
        filename = generate_royalty_statement(lang, num)
        generated_files.append(("Royalty Statement", lang, filename))
        print(f"   ✓ {filename}")
    
    # Generate Contracts (6 total: 2 en, 2 es, 1 de, 1 pt)
    print("\n📝 Generating Contracts...")
    contract_distribution = [("en", 1), ("en", 2), ("es", 3), ("es", 4), ("de", 5), ("pt", 6)]
    for lang, num in contract_distribution:
        filename = generate_contract(lang, num)
        generated_files.append(("Contract", lang, filename))
        print(f"   ✓ {filename}")
    
    # Summary
    print("\n" + "=" * 60)
    print(f"Generated {len(generated_files)} PDF documents")
    print(f"Output directory: {OUTPUT_DIR}")
    print("=" * 60)
    
    print("\n📊 Summary by Type:")
    for doc_type in ["Invoice", "Royalty Statement", "Contract"]:
        count = sum(1 for d in generated_files if d[0] == doc_type)
        print(f"   {doc_type}: {count} documents")
    
    print("\n🌐 Summary by Language:")
    for lang in ["en", "es", "de", "pt"]:
        count = sum(1 for d in generated_files if d[1] == lang)
        lang_name = {"en": "English", "es": "Spanish", "de": "German", "pt": "Portuguese"}[lang]
        print(f"   {lang_name}: {count} documents")
    
    print("\n✅ Ready for upload to Snowflake stage!")
    print("   Use Streamlit 'Upload Documents' page or:")
    print(f"   PUT file://{OUTPUT_DIR}/*.pdf @SNOWFLAKE_EXAMPLE.SWIFTCLAW.DOCUMENT_STAGE AUTO_COMPRESS=FALSE;")


if __name__ == "__main__":
    main()

