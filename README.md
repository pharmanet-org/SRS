# PharmaNet SRS — Software Requirements Specification & Documentation

This repository contains the **Software Requirements Specification (SRS)**, **Internship Recommendation Letter**, and **Database Schema** for the PharmaNet platform — a verified pharmacies network and search marketplace.

All source code repositories are hosted in the [pharmanet-org](https://github.com/pharmanet-org) GitHub organization. This repo serves as the central reference for the project's documentation.

## Contents

| File | Description |
|---|---|
| [`SRS.md`](./SRS.md) | Complete Software Requirements Specification — architecture, API docs, features, deployment guide |
| [`RECOMMENDATION.md`](./RECOMMENDATION.md) | Internship recommendation report — team experience, mentor feedback, bugs, signatures |
| [`supabase_schema.sql`](./supabase_schema.sql) | Full PostgreSQL database schema — 30+ tables with constraints and indexes |

## Deployed Projects

All projects are live and accessible:

| Project | Tech | Deployment | Source Code |
|---|---|---|---|
| **Mobile App** | Flutter / Dart | Android APK on [GitHub Releases](https://github.com/pharmanet-org/pharmanet/releases) | [github.com/pharmanet-org/pharmanet](https://github.com/pharmanet-org/pharmanet) |
| **Admin Portal** | React / Vite | [web.pharmanet.bilsul.com](https://web.pharmanet.bilsul.com) | [github.com/pharmanet-org/pharmanet-admin](https://github.com/pharmanet-org/pharmanet-admin) |
| **Seller Portal** | React / Vite | Hosted via Vercel | [github.com/pharmanet-org/pharmanet-web](https://github.com/pharmanet-org/pharmanet-web) |
| **Help Center** | Mintlify / MDX | [docs.pharmanet.bilsul.com](https://docs.pharmanet.bilsul.com) | [github.com/pharmanet-org/pharmanet-guide-docs](https://github.com/pharmanet-org/pharmanet-guide-docs) |
| **Technical Docs** | Zensical | Hosted via Zensical | [github.com/pharmanet-org/technical](https://github.com/pharmanet-org/technical) |
| **Chatbot** | Python / FastAPI | Docker Compose (local deployment) | [github.com/pharmanet-org/chatbot](https://github.com/pharmanet-org/chatbot) |

## Related Resources

- **GitHub Organization**: [github.com/pharmanet-org](https://github.com/pharmanet-org)
- **Supabase Console**: [egullnxmzmkbhtksjglu.supabase.co](https://egullnxmzmkbhtksjglu.supabase.co)
- **SRS Review & Guidance**: Ermias, Alyah Software — see [`RECOMMENDATION.md`](./RECOMMENDATION.md) for full feedback

## PDF & DOCX Generation

This repo includes scripts to convert the markdown documents into professionally formatted PDF and DOCX files.

### Prerequisites

- **Python 3** with `markdown` package (`pip3 install markdown`)
- **LibreOffice** (`libreoffice --headless` for PDF and DOCX export)

### Scripts

| Script | Input | Output |
|---|---|---|
| [`scripts/generate-srs-pdf.sh`](./scripts/generate-srs-pdf.sh) | [`SRS.md`](./SRS.md) | `output/pharmanet-SRS.pdf`, `output/pharmanet-SRS.docx` |
| [`scripts/generate-recommendation-pdf.sh`](./scripts/generate-recommendation-pdf.sh) | [`RECOMMENDATION.md`](./RECOMMENDATION.md) | `output/pharmanet-recommendation.pdf`, `output/pharmanet-recommendation.docx` |

### Usage

```bash
# Generate SRS PDF + DOCX
bash scripts/generate-srs-pdf.sh

# Generate Recommendation PDF + DOCX
bash scripts/generate-recommendation-pdf.sh
```

Both scripts produce files in the [`output/`](./output/) directory.

### Pipeline

```
Markdown (.md)  →  Python markdown (styled HTML)  →  ODT  →  LibreOffice  →  DOCX + PDF
```

The Python `markdown` module converts the `.md` files into styled HTML with proper typography, tables, code blocks, and syntax highlighting. LibreOffice handles the document-to-PDF conversion with proper page margins and fonts.

### Pre-generated Files

Generated outputs are committed to [`output/`](./output/) for convenience:

| File | Size |
|---|---|
| [`output/pharmanet-SRS.pdf`](./output/pharmanet-SRS.pdf) | 380 KB |
| [`output/pharmanet-SRS.docx`](./output/pharmanet-SRS.docx) | 19 KB |
| [`output/pharmanet-recommendation.pdf`](./output/pharmanet-recommendation.pdf) | 229 KB |
| [`output/pharmanet-recommendation.docx`](./output/pharmanet-recommendation.docx) | 17 KB |

## License

Proprietary — PharmaNet, Alyah Software © 2026

> **Note**: This is a documentation-only repository. For the actual source code, deployment instructions, and test credentials, refer to the individual project repositories listed above.
