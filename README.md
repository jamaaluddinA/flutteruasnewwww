# 🛒 Shopping List App - Flutter + Supabase

![Flutter](https://img.shields.io/badge/Flutter-3.19.0-blue)
![Supabase](https://img.shields.io/badge/Supabase-Database-green)
![CI/CD](https://img.shields.io/badge/CI/CD-GitHub%20Actions-orange)

## 🚀 Live URLs
- **Staging**: https://staging-shopping-app.vercel.app
- **Production**: https://shopping-app.vercel.app

## 📋 Fitur
- ✅ Login/Logout dengan SharedPreferences
- ✅ CRUD Products dengan Supabase
- ✅ Geolocation & Weather API
- ✅ Dark/Light Mode
- ✅ Caching dengan SharedPreferences

## 🏗️ Tech Stack
- **Frontend**: Flutter 3.19.0
- **Backend**: Supabase (PostgreSQL)
- **CI/CD**: GitHub Actions
- **Deployment**: Vercel
- **Package Manager**: pub.dev

## 🔧 CI/CD Pipeline Architecture

```mermaid
graph LR
    A[Push ke Staging] --> B[GitHub Actions]
    C[PR ke Main] --> B
    B --> D[Build & Test]
    D --> E{Branch?}
    E -->|Staging| F[Deploy Staging]
    E -->|Main| G[Deploy Production]
    F --> H[Vercel Staging]
    G --> I[Vercel Production]
🏷️ Branching Strategy
main → Production (auto-deploy to Vercel)

staging → Staging (auto-deploy to Vercel Staging)

feature/* → Development branch

hotfix/* → Bug fixes

📁 Project Structure
text
uas_flutter/
├── .github/workflows/    # CI/CD Pipeline
├── lib/
│   ├── models/           # Data models
│   ├── pages/            # UI Screens
│   ├── providers/        # State management
│   ├── services/         # API services
│   └── widgets/          # Reusable widgets
├── test/                 # Unit tests
└── pubspec.yaml         # Dependencies
🚀 Deployment Workflow
Staging Deployment:

Push ke branch staging

GitHub Actions otomatis build & test

Auto-deploy ke Vercel Staging

Production Deployment:

Pull request dari staging ke main

Setelah PR di-merge, auto-deploy ke Vercel Production

🔄 Rollback Strategy
Jika deployment gagal:

Otomatis: Vercel menyimpan semua deployment sebelumnya

Manual:

Login ke Vercel Dashboard

Pilih project → Deployments

Klik "..." pada deployment yang stabil

Pilih "Promote to Production"

🧪 Testing
bash
# Run tests locally
flutter test

# Run with coverage
flutter test --coverage
👥 Anggota Tim
[Nama Anda] - Project Lead & Developer

[Anggota 2] - Backend & Supabase

[Anggota 3] - UI/UX & Testing

📞 Kontak
GitHub: jamaaluddinA

Email: [your-email@example.com]

text

---

### ✅ **6. Checklist Deliverables Final Project**

| Deliverable | Status |
|------------|---------|
| ✅ Repository GitHub public/private | ✅ Ada |
| ✅ Source code Flutter lengkap | ✅ Sudah |
| ✅ Folder `.github/workflows/` | ⬜ **Perlu dibuat** |
| ✅ README.md dokumentasi lengkap | ⬜ **Perlu dibuat** |
| ✅ URL Staging (Vercel) | ⬜ **Setelah deploy** |
| ✅ URL Production (Vercel) | ⬜ **Setelah deploy** |
| ✅ Branching strategy | ⬜ **Perlu dibuat** |
| ✅ CI Pipeline (build & test) | ⬜ **Perlu setup GitHub Actions** |
| ✅ CD Pipeline (deploy) | ⬜ **Perlu setup Vercel** |
| ✅ Rollback documentation | ✅ Ada di README |

---

### 🚀 **7. Langkah Eksekusi**

#### **Step 1: Setup Branching**
```bash
cd "D:\tugas adwa\PeMo\uas_flutter"
git checkout -b staging
git push -u origin staging
Step 2: Buat Workflow CI/CD
Buat folder dan file:
D:\tugas adwa\PeMo\uas_flutter\.github\workflows\ci_cd.yml

Step 3: Setup Vercel
Install Vercel CLI: npm i -g vercel

Login: vercel login

Deploy pertama: vercel --prod

Step 4: Tambahkan Secrets di GitHub
Token Vercel

Org ID

Project ID

Step 5: Update README.md
Buat file README.md di root project dengan dokumentasi di atas.

Step 6: Commit & Push
bash
git add .
git commit -m "setup ci/cd pipeline dengan github actions dan vercel"
git push origin staging
