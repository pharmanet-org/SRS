#!/usr/bin/env bash
set -euo pipefail

# PharmaNet Recommendation PDF Generator
# Converts RECOMMENDATION.md → DOCX + PDF via HTML/ODT intermediate

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
OUTPUT_DIR="${SCRIPT_DIR}/output"
REC_MD="${SCRIPT_DIR}/SRS/RECOMMENDATION.md"
DOCX_FILE="${OUTPUT_DIR}/pharmanet-recommendation.docx"
PDF_FILE="${OUTPUT_DIR}/pharmanet-recommendation.pdf"

mkdir -p "$OUTPUT_DIR"

echo "=== PharmaNet Recommendation PDF Generator ==="
echo "Source: $REC_MD"
echo ""

# Step 1: Markdown → styled HTML
echo "[1/3] Converting Markdown to HTML..."
python3 << PYEOF
import markdown

with open("$REC_MD") as f:
    md_content = f.read()

html_body = markdown.markdown(
    md_content,
    extensions=['fenced_code', 'tables', 'codehilite', 'toc', 'nl2br']
)

html_full = f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>PharmaNet — Internship Recommendation</title>
<style>
  @page {{ margin: 2cm; }}
  body {{
    font-family: 'Liberation Serif', 'Georgia', serif;
    font-size: 11pt;
    line-height: 1.6;
    color: #1a1a1a;
    max-width: 800px;
    margin: 0 auto;
    padding: 20px;
  }}
  h1 {{ font-size: 22pt; color: #1a3a5c; border-bottom: 2px solid #1a3a5c; padding-bottom: 8px; }}
  h2 {{ font-size: 16pt; color: #1a3a5c; margin-top: 30px; border-bottom: 1px solid #ccc; padding-bottom: 4px; }}
  h3 {{ font-size: 13pt; color: #2a5a8c; margin-top: 20px; }}
  h4 {{ font-size: 11pt; color: #333; }}
  table {{ border-collapse: collapse; width: 100%; margin: 15px 0; font-size: 9pt; }}
  th, td {{ border: 1px solid #999; padding: 6px 8px; text-align: left; }}
  th {{ background-color: #e8edf2; font-weight: bold; }}
  tr:nth-child(even) {{ background-color: #f8f8f8; }}
  code {{ font-family: 'Liberation Mono', 'Courier New', monospace; font-size: 9pt; background: #f0f0f0; padding: 1px 4px; border-radius: 2px; }}
  pre {{ background: #f4f4f4; border: 1px solid #ddd; padding: 10px; overflow-x: auto; font-size: 9pt; line-height: 1.3; }}
  pre code {{ background: none; padding: 0; }}
  blockquote {{ border-left: 4px solid #1a3a5c; margin: 15px 0; padding: 8px 15px; background: #f9f9f9; font-style: italic; }}
  ul, ol {{ margin: 8px 0; padding-left: 25px; }}
  li {{ margin: 3px 0; }}
  hr {{ border: none; border-top: 1px solid #ccc; margin: 25px 0; }}
  p {{ margin: 8px 0; }}
</style>
</head>
<body>
{html_body}
</body>
</html>"""

with open("/tmp/pharmanet-recommendation.html", 'w') as f:
    f.write(html_full)
print("      Done")
PYEOF

# Step 2: HTML → ODT (intermediate format for LibreOffice)
echo "[2/3] Converting to ODT..."
cp /tmp/pharmanet-recommendation.html /tmp/odt-convert-rec.odt

# Step 3: ODT → DOCX
echo "[3/3] Converting to DOCX..."
libreoffice --headless --convert-to "docx:MS Word 2007 XML" --outdir "$OUTPUT_DIR" /tmp/odt-convert-rec.odt 2>/dev/null
mv "$OUTPUT_DIR/odt-convert-rec.docx" "$DOCX_FILE"

# Step 4: ODT → PDF
echo "        Converting to PDF..."
libreoffice --headless --convert-to pdf --outdir "$OUTPUT_DIR" /tmp/odt-convert-rec.odt 2>/dev/null
mv "$OUTPUT_DIR/odt-convert-rec.pdf" "$PDF_FILE"

echo ""
echo "=== Done ==="
echo "  DOCX: $DOCX_FILE"
echo "  PDF:  $PDF_FILE"
