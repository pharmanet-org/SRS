# PharmaNet — Verified Pharmacies Network & Search Platform

Multi-platform marketplace connecting customers with verified pharmacies. Built with Flutter, React, Supabase, and PostgreSQL.

## Projects

| Project | Directory | Tech | Description |
|---|---|---|---|
| Mobile App | [`pharmanet/`](./pharmanet/) | Flutter / Dart | Customer-facing Android, iOS, Web app |
| Seller Portal | [`pharmanet-web/`](./pharmanet-web/) | React / Vite | Pharmacy owner dashboard |
| Admin Portal | [`pharmanet-admin/`](./pharmanet-admin/) | React / Vite | Platform admin dashboard |
| Help Center | [`pharmanet-guide-docs/`](./pharmanet-guide-docs/) | Mintlify / MDX | Public customer & seller documentation |
| Chatbot | [`chatbot/`](./chatbot/) | Python / FastAPI | RAG-powered support chatbot |
| Technical Docs | [`docs/`](./docs/) | Zensical | Internal developer documentation |

## Shared Backend

All apps connect to a single **Supabase** instance with:
- **PostgreSQL** database (24+ tables: profiles, sellers, products, orders, payments, promotions, subscriptions, chats, notifications, reviews, banners, settings, etc.)
- **Supabase Auth** for authentication (email/password)
- **Supabase Realtime** for live order/promotion updates
- **Firebase Cloud Messaging** for push notifications
- **Firebase Crashlytics & Analytics** for mobile monitoring
- **Chapa** payment gateway (ETB currency)
- **Cloudinary** for image uploads

## User Roles

| Role | Description | Accesses |
|---|---|---|
| `customer` | End users browsing, ordering, and chatting with pharmacies | Mobile App |
| `seller` | Pharmacy owners managing products, orders, promotions | Seller Portal + Mobile App |
| `admin` | Platform administrators managing users, approvals, content | Admin Portal |

## Test Credentials (Development Only)

### Supabase
- **Project URL**: `https://egullnxmzmkbhtksjglu.supabase.co`
- **Anon Key**: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVndWxsbnhtem1rYmh0a3NqZ2x1Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MDc2MDM5MiwiZXhwIjoyMDg2MzM2MzkyfQ.XlEex4UmZcXxOrp5f95SyHs9Mdy3szmxLeAFqOufblE`
- **Database (PostgreSQL)**: `postgresql://postgres.egullnxmzmkbhtksjglu:OugyEIsVc11F9L9j@aws-1-eu-west-2.pooler.supabase.com:5432/postgres`

### Chapa Payment (Test Mode)
- **Public Key**: `CHAPUBK_TEST-sTK9QNa1MBvsBipUXiTFg6rb1c7wRIJd`
- **Secret Key**: `CHASECK_TEST-iWOLGti88iaY6ooTKzk9LeXt7c8uOuOD`
- **Encryption Key**: `rpCSDdRO9FzSDHiVhYKrXKSg`
- **Webhook Secret**: `chapa_webhook_secret_2026_change_in_production`

### Firebase
- **Project ID**: `pharmanet-5c66e`
- **Android API Key**: `AIzaSyBhWkEuJ-e9W76mhtaOku5n1Dn274O8ZEs`
- **iOS/macOS API Key**: `AIzaSyArUOcXQDmIq2Y1Mv1QZtV13QgdgTnuF8M`
- **Web/Windows API Key**: `AIzaSyCYo91PYzEVYOUhJN3sYcGNfrtogQ9hg20`
- **Messaging Sender ID**: `927960675698`

### Cloudinary
- **Cloud Name**: `dinhytdqm`
- **API Key**: `469711434959164`
- **API Secret**: `lIRFAQ-5pRBVT-t4QPIapaVWmRA`
- **Upload Preset**: `ml_default`

### Seed Database Accounts
| Email | Role |
|---|---|
| `admin@test.com` | Admin |
| `bole_pharma@test.com` | Seller (pharmacy owner) |
| `dist_owner@test.com` | Seller (distributor) |
| `abebe@test.com` | Customer |
| `chala@test.com` | Customer |

> **⚠️ WARNING**: These credentials are hardcoded for local development and testing only. Rotate all keys before production deployment.

## Quick Start

```bash
# Mobile App
cd pharmanet && flutter pub get && flutter run

# Seller Portal
cd pharmanet-web && npm install && npm run dev

# Admin Portal
cd pharmanet-admin && npm install && npm run dev

# Chatbot
cd chatbot && pip install -r requirements.txt && uvicorn src.main:app --reload

# Help Center
cd pharmanet-guide-docs && npm i -g mint && mint dev

# Technical Docs
cd docs && zensical serve
```

## License

Proprietary — PharmaNet, Alyah Software © 2026
