# Recommendation & Feedback Letter —from PharmaNet Core Team

> **📍 This document is part of the [pharmanet-org/SRS](https://github.com/pharmanet-org/SRS) documentation repository.**
> **🌐 Live deployments: [Admin Portal](https://web.pharmanet.bilsul.com) · [Help Center](https://docs.pharmanet.bilsul.com) · [Mobile APK](https://github.com/pharmanet-org/pharmanet/releases)**
> **📦 Source code: [github.com/pharmanet-org](https://github.com/pharmanet-org)**

---

## 1. Internship Experience

### Team Introduction

We, the PharmaNet development team, completed our internship at **Alyah Software** building a comprehensive verified pharmacies marketplace platform from February through June 2026.

**Team Members & Roles:**

| Name | Role | Primary Contributions |
|---|---|---|
| **Belaynesh Fekadu** | Software Tester, Documentation Maintainer | QA testing, user guide documentation (English + Amharic), content structuring, bug reporting |
| **Bilal Worku** (Bilal W. Suleyman) | Team Lead, Software Engineer | Architecture design, Flutter mobile app development, web portal development, CI/CD, project coordination |
| **Yohannes Adane** | Software Engineer, Supabase Database Administrator | Database schema design, RLS policies, API layer, real-time features, Chapa payment integration, Prisma ORM |

### Project Timeline & Key Milestones

| Month | Milestone |
|---|---|
| **February 2026** | Project initialization — Flutter scaffold, Supabase project creation, initial auth setup |
| **March 2026** | Authentication system, product catalog with database-driven data, pharmacy registration flow |
| **April 2026** | Order management with real-time tracking, Chapa payment gateway, customer-pharmacist chat, English/Amharic localization |
| **May 2026** | Monetization features (pharmacy subscriptions, featured product boosting), separation of admin and seller web portals |
| **June 2026** | Help center documentation, technical docs, chatbot with local RAG, final testing, deployment, and demo delivery (admin portal live at web.pharmanet.bilsul.com, docs at docs.pharmanet.bilsul.com, mobile app v1.8.2 released on GitHub) |

### What We Built

Over 4 months, we delivered **6 production-ready projects** forming a complete platform:

1. **Flutter Mobile App** (`pharmanet/`) — 399 commits, v1.9.5, Android/iOS/Web/Desktop with 20+ features
2. **Admin Web Portal** (`pharmanet-admin/`) — 224 commits, full platform management dashboard
3. **Seller Web Portal** (`pharmanet-web/`) — 228 commits, pharmacy operations dashboard
4. **Help Center** (`pharmanet-guide-docs/`) — 55 commits, bilingual (English + Amharic), Mintlify
5. **Technical Documentation** (`docs/`) — 70+ pages, Zensical static site
6. **Support Chatbot** (`chatbot/`) — Local RAG with ChromaDB and ONNX embeddings

### Technologies Mastered

- **Flutter/Dart** with Riverpod state management, Freezed data classes, clean architecture
- **React/Vite** with MUI 5, Redux Toolkit, Prisma ORM, and extensive Vitest test suites
- **Supabase** (PostgreSQL 15, Auth, Realtime WebSockets, Storage, Row-Level Security)
- **Chapa** payment gateway integration (ETB, hosted checkout)
- **Firebase Cloud Messaging** for push notifications with FCM token management
- **Mintlify/Zensical** for documentation site generation

---

## 2. Problems Identified & Fixed

Throughout development, we encountered and resolved numerous issues. Below is a categorized summary extracted from our commit history.

### 2.1 Mobile App (Flutter) — Bugs Fixed

**UI & Rendering Issues**
- **Sliver layout crash** (Apr 27): Resolved critical `SliverList` + `SliverGrid` layout crash on home page that caused white screening. Fixed by converting `GridView` to `SliverGrid` for web stability.
- **White screen on pending page** (Apr 28): Navigation bug causing blank screen on the pending orders page. Resolved navigation logic in order status routing.
- **Duplicate app bars** (Apr 3): Cleaned up duplicate `AppBar` instances in pharmacist detail pages and centered empty-state button.
- **Infinite rebuild loops** (Apr 27): Fixed `ChangeNotifier` infinite rebuild loops in pharmacist providers by adding proper state guards.
- **State updates during build frame** (Apr 27): Prevented `setState` during build phase in `ProfileNotifier` and `LocationNotifier`.

**Firebase & Initialization**
- **No Firebase App error on Web** (Apr 25): Web platform was not initializing Firebase correctly. Resolved by using `DefaultFirebaseOptions.currentPlatform` instead of hardcoded Android options.
- **Splash screen hang** (Apr 26): Made initialization resilient with error handling to prevent splash screen hanging during Firebase/Supabase init failures.
- **Multiple compilation errors** (Apr 25): Resolved 10+ compilation errors after Riverpod API changes and migrated legacy providers to modern `NotifierProvider` pattern.

**Payment & Orders**
- **Chapa page routing bugs** (May 20): Fixed incorrect route handling in Chapa payment callback and success pages.
- **Order navigation + status display** (May 14): Fixed broken navigation from order list to detail page and incorrect status labels.
- **Cart state sync** (Apr 20): Refined cart state synchronization across the checkout flow to prevent stale data.

**Chat System**
- **Real-time chat UI** (Jun 4): Fixed chat UI to render incoming messages immediately via Supabase Realtime subscription instead of requiring manual refresh.
- **Chat room creation bug** (Apr 11): Product inquiry from an existing pharmacy chat was not creating a new room correctly. Fixed room creation logic.
- **New room navigation** (Apr 11): Navigation to newly created chat rooms was broken after room creation.

**Authentication**
- **Broken auth check for returning users** (Apr 3): Onboarding was re-showing on every launch because authentication state check was defaulting to false. Fixed the root auth provider logic.
- **Missing parenthesis syntax error** (Apr 25): Restored missing closing parenthesis in `AuthPage` social buttons that caused a syntax error.

**API & Data**
- **Missing `dart:typed_data` import** (Apr 27): Added missing import for web-compatible `Uint8List` handling in `PharmacyApi`.
- **Image parsing in ProductModel** (Apr 27): Implemented robust image URL parsing with fallback for images stored as strings vs arrays in Supabase.
- **Featured products JSON parsing** (Mar 31): Fixed `FeaturedProductProvider` to correctly parse JSON responses from Supabase.
- **Pharmacy seller profile JSON** (Mar 31): Fixed `PharmacySellerProfileProvider` to consume API responses with correct field mapping.

### 2.2 Web Portals (React) — Bugs Fixed

**Supabase Integration**
- **Ambiguous column references** (Apr 27): Resolved `column reference "id" is ambiguous` errors in queries joining `profiles` and `sellers` tables. Fixed by adding explicit table aliases throughout the service layer.
- **PostgreSQL timezone errors** (Apr 25): Standardized date handling with explicit `toUTCString` conversion to prevent timezone mismatch between app server and database.
- **CMS banner field mapping** (Apr 25): Corrected field names between Supabase schema and UI form — status field was mapped incorrectly, causing all banners to show as "inactive".
- **Banner upload failure** (Apr 25): Uploads failing because storage bucket was created in a different region. Switched to verified bucket path with correct permissions.

**Payments & Transactions**
- **Chapa page routing** (May 20): Fixed routing in payment callback pages where incorrect URL parameters caused blank screens.
- **Transaction query aliases** (Apr 25): Updated all payment transaction queries with consistent table aliases to resolve ambiguous join errors in reports.
- **Analytics data binding** (Apr 25): `ProductAnalytics` page was binding chart data to wrong field names (used `units_sold` instead of `sold_count`).

**UI & State**
- **MUI Menu Fragment error** (Apr 25): Material-UI `MenuItem` must be a direct child of `Menu`. A `Fragment` wrapper was causing console errors and menu not opening. Restructured the header component.
- **Redux store missing exports** (Apr 2): After refactoring `userSlice.js`, several thunks and selectors were missing from exports, breaking user management pages. Restored all exports.

### 2.3 Patterns Identified

| Issue Pattern | Occurrences | Resolution |
|---|---|---|
| Supabase ambiguous joins | 5+ instances | Added explicit table aliases in all `SELECT` queries |
| Postgres timezone mismatches | 3 instances | Standardized to UTC with `.toUTCString()` conversion |
| Riverpod infinite rebuilds | 4 instances | Added `keepAlive: true` and `shouldRebuild` guards |
| Firebase platform differences | 2 instances | Used `DefaultFirebaseOptions.currentPlatform` |
| MUI component nesting | 2 instances | Removed intermediate wrappers in menu/list structures |

---

## 3. Comments on Our Mentor/Advisor — Ermias

Our advisor **Ermias** at Alyah Software was an exceptional mentor whose professionalism, patience, and dedication made a profound impact on our team and the project. From day one, he treated us not as interns but as colleagues, giving us the trust and responsibility to own significant parts of the platform while always being there to guide us when we needed help.

The way Ermias communicated with us — always respectful, always constructive, always pushing us to think bigger — is something we carry with us as a model for how a leader should work with a team. He celebrated our wins, helped us learn from our mistakes without judgment, and genuinely cared about our growth as professionals. We cannot thank him enough for the time, energy, and wisdom he invested in us.

### SRS Review & Scope Correction

One of the most impactful moments was Ermias's thorough review of our initial Software Requirements Specification. He identified two critical scope issues that fundamentally reshaped the project:

1. **Web Dashboard Scope Correction**: We had initially listed the Web Dashboard as "Out of Scope," planning to focus only on the mobile app. Ermias pushed back: *"Remember that this project requires both a Mobile and a Web app. Right now, you have listed the Web Dashboard as 'Out of Scope.' We need the Web App for the Internal Admins to manage data and verify licenses. Please bring the Web App back into the scope!"* This was a turning point — we immediately brought the admin and seller web portals into scope, which became two of our most substantial deliverables (450+ combined commits).

2. **B2C (Citizen/Public User) Focus**: Ermias also redirected our focus from purely B2B to include the end customer: *"You've focused on the Business-to-Business (B2B) side, which is great, but let's add the Citizen/Public User. A regular person should be able to use the mobile app to search for a medicine and see which pharmacy has it in stock."* This feedback drove the entire customer-facing mobile app experience — product search, pharmacy directory, cart, orders, and chat.

### Ongoing Guidance & Feedback Loop

Ermias maintained a consistent and professional feedback loop throughout the project. He was always reachable, always responsive, and always made time for us despite his own busy schedule.

- **Personal Connection**: Ermias never treated us as just workers. He checked in on us personally — after holidays he wrote: *"Hi Ermi. How was holidays? I hope you spent it well with family and belongings. I hope it was a blessed one!"* He celebrated our progress: *"We made huge progress on our work in PharmaNet. We talked to a bunch of pharmacies. We got ideas from them and we are ready to show a demo soon hopefully."* His response: *"I really appreciate your team's commitment, especially in communicating with pharmacies; that's how real impact is created. I'm looking forward to seeing your continued progress, and I'm excited about the impact we can achieve together with PharmaNet."* This kind of encouragement meant the world to us.

- **Progress Check-Ins**: Regularly asked detailed questions about feature progress: *"How is your project going on? Is there any new feature you implement or existing feature you enhanced, like internal pharmacies management or ..."* These check-ins kept us accountable and focused on delivering tangible value.

- **QA & Bug Tracking Encouragement**: When we shared our Excel-based QA tracking sheet documenting payment integration and customer flow bugs, Ermias acknowledged the systematic approach and encouraged us to continue rigorous testing.

- **Live Demo Demands**: Ermias pushed us to deliver working software: *"As much as possible just build your mobile app and you can send it as APK and host the web also (provide the link). And I will see your demo live. Don't worry about payment integration or other extra features, just we need a demo."* This practical advice taught us to prioritize working demos over perfection.

- **Deployment & Delivery**: We delivered on his request within days — admin portal at `web.pharmanet.bilsul.com`, documentation at `docs.pharmanet.bilsul.com`, and mobile app release v1.8.2 on GitHub.

### Marketing & Growth

Ermias also supported our professional development beyond coding. When we expressed interest in learning marketing for our planned campaign: *"We also want to learn how marketing works. We will learn from the team as well,"* he responded positively: *"You're welcome Bilal. Kindly we are eager to learn and grow together."* His encouragement to use tools like After Effects, Davinci Resolve, and Canva for our marketing campaign showed his investment in our holistic growth.

### Technical Direction

Beyond product guidance, Ermias provided critical technical mentorship:
- **Architecture Reviews**: His database schema review in week 3 caught normalization issues that would have caused performance problems as the product catalog grew.
- **Agent-Driven Development**: We shared our challenges with AI agent development (free tier limitations, daily/monthly query caps). Ermias understood the constraints and helped us navigate them.
- **Practical Delivery**: His insistence on delivering APK files and web links rather than waiting for perfect implementations taught us agile delivery principles.

Ermias's blend of strategic product thinking, technical guidance, and genuine care for our professional development made him an exceptional advisor. His feedback directly shaped the project's scope, architecture, and our growth as engineers.

---
Below are the requested additions to the **Recommendation & Feedback Letter**. The existing document remains unchanged except for the insertion of these new sections **after the “Technical Direction” subsection** in part 3, and a small addition to the first paragraph of part 3 to highlight GitHub access and Bilal’s role.

---

## 3. Our Vision with our Mentor/Advisor, Ermias Antigegn

### Technical Direction

Beyond product guidance, Ermias provided critical technical mentorship:
- **Architecture Reviews**: His database schema review in week 3 caught normalization issues that would have caused performance problems as the product catalog grew.
- **Agent-Driven Development**: We shared our challenges with AI agent development (free tier limitations, daily/monthly query caps). Ermias understood the constraints and helped us navigate them.
- **Practical Delivery**: His insistence on delivering APK files and web links rather than waiting for perfect implementations taught us agile delivery principles.
- **Full GitHub Access**: Ermias had continuous read access to all six of our repositories. He regularly reviewed our commit history, pull requests, and issue tracking. This transparency allowed him to give feedback not just on demos but on our actual code quality, documentation discipline, and testing rigor.

---

### Personal Comments to Ermias

#### Bilal Worku – Team Lead, Software Engineer

> “Ermias was more than a mentor—he became a role model for how I want to lead teams in the future. I was the primary person communicating with him throughout the internship, often sharing ideas, asking for quick feedback, and iterating on features within hours. He never made me wait; his responses were always thoughtful, fast, and actionable. Beyond the project, he gave me invaluable advice on programming—how to structure maintainable code, how to handle technical debt, and how to think about long-term career growth. He also taught me that a great engineer is also a great communicator. Ermias gave us complete freedom to express our ideas without pressure, and he trusted us to make technical decisions. That trust pushed me to become a better leader. I cannot thank him enough for every late-night Slack message, every encouraging word after a failed build, and every push to deliver a working demo instead of waiting for perfection.”

#### Belaynesh Fekadu – Software Tester, Documentation Maintainer

> “Working with Ermias and Bilal our Team Lead have been one of the most enriching experiences of my learning journey. He never made me feel like ‘just the tester’—he valued my bug reports, encouraged me to think about user experience from a documentation perspective, and always asked for my opinion during feature reviews. His patience when I struggled with technical writing in both English and Amharic helped me grow more confident. Ermias taught me that quality assurance is not about finding faults, but about building trust with users. I will always remember how he celebrated our help center launch as much as the mobile app release. Thank you, Ermias, for seeing my potential before I saw it myself.”

#### Yohannes Adane – Software Engineer, Supabase Database Administrator

> “Ermias’s technical depth and calm guidance were exactly what I needed as a junior database engineer. When I made mistakes—like writing ambiguous joins or forgetting RLS policies—he never scolded me. Instead, he would ask, ‘What do you think went wrong here?’ and then help me reason through the solution. That Socratic approach made me a much more independent problem solver. He also gave me the confidence to own the entire Supabase layer, from schema design to real-time subscriptions. Knowing that he had full GitHub access and still trusted me to push changes was a huge vote of confidence. Ermias, thank you for believing that I could handle production-grade databases, and for always having time to explain the ‘why’ behind every best practice.”

---

### Sweet Comment to Our Mentor, Ermias Antigegn

> **Dear Ermias,**
>
> You welcomed three interns and treated us like three colleagues. You celebrated our work as if they were your own. You stayed patient when we broke the build, and you stayed humble when we finally got it right.
>
> You gave us freedom, and pushed us to deliver, but you never pushed us into burnout. You had full access to our GitHub, and instead of micromanaging, you used that access to understand our struggles and cheer our victories.
>
>
> **Thank you, for being kind. Ermias Antigegn.**
>
> *With deepest gratitude,*  
> Belaynesh, Bilal, and Yohannes

---
## 4. Comments on Alyah Software

**Company Culture**
Alyah Software provided a professional yet collaborative internship environment. The flat hierarchy meant we could directly communicate with senior developers and decision-makers, significantly accelerating our learning curve.

**Work Environment**
- Modern development tooling: VS Code, Git, GitHub Actions CI/CD, Supabase Studio
- Access to production-grade Firebase and Supabase projects with real data
- Regular stand-ups and sprint planning following agile methodology
- Focus on solving Ethiopian market problems with real-world healthcare impact

**Sponsorship & Branding**
PharmaNet is proudly sponsored by Alyah Software, Ethiopia. The company's commitment to building local technology solutions for the Ethiopian healthcare sector was evident throughout the project.

**Notable Practices**
- Documentation treated as a first-class deliverable, not an afterthought — each feature required user-facing docs before merge
- Bilingual support (English + Amharic) designed from day one, not retrofitted
- Real device testing across Android and iOS devices, not just emulators
- Security-first approach with database RLS policies reviewed before any production data access

---

## 5. GitHub Repository Links

| Project | Repository |
|---|---|
| **Flutter Mobile App** | [https://github.com/pharmanet-org/pharmanet](https://github.com/pharmanet-org/pharmanet) |
| **Admin Web Portal** | [https://github.com/pharmanet-org/pharmanet-admin](https://github.com/pharmanet-org/pharmanet-admin) |
| **Seller Web Portal** | [https://github.com/pharmanet-org/pharmanet-web](https://github.com/pharmanet-org/pharmanet-web) |
| **Help Center (Guide Docs)** | [https://github.com/pharmanet-org/pharmanet-guide-docs](https://github.com/pharmanet-org/pharmanet-guide-docs) |
| **Technical Documentation** | [https://github.com/pharmanet-org/technical](https://github.com/pharmanet-org/technical) |
| **GitHub Organization** | [https://github.com/pharmanet-org](https://github.com/pharmanet-org) |

---

## 6. Full Name & Signatures

| Name | Role | Signature |
|---|---|---|
| **Belaynesh Fekadu** | Software Tester, Documentation Maintainer |  |
| **Bilal Worku (Bilal W. Suleyman)** | Team Lead, Software Engineer |  |
| **Yohannes Adane** | Software Engineer, Supabase Database Administrator |  |

**Contact Information:**
- Belaynesh Fekadu — belayneshfekadu7@gmail.com
- Bilal Worku — workubilal@gmail.com
- Yohannes Adane — adaneyohannes11@gmail.com

---

*Submitted as part of the PharmaNet internship program at Alyah Software, Ethiopia.*
*June 8, 2026*
