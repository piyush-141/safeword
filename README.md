# 🔐 SafeWord — Zero-Knowledge Password Manager

A production-ready, zero-knowledge password manager built with **Flutter** (mobile), **Node.js + Express** (backend), and **Supabase** (auth + database).

> **Zero-Knowledge**: The backend _never_ sees your plaintext passwords. All encryption/decryption happens on-device using AES-256-CBC + PBKDF2.

---

## 🗂 Project Structure

```
project_3/
├── safeword/               # Flutter mobile app
│   └── lib/
│       ├── main.dart
│       ├── config.dart
│       ├── models/
│       │   └── credential.dart
│       ├── services/
│       │   ├── auth_service.dart
│       │   ├── encryption_service.dart
│       │   └── api_service.dart
│       ├── screens/
│       │   ├── login_screen.dart
│       │   ├── otp_screen.dart
│       │   ├── vault_list_screen.dart
│       │   ├── credential_detail_screen.dart
│       │   ├── add_edit_credential_screen.dart
│       │   └── lock_screen.dart
│       ├── widgets/
│       │   └── credential_card.dart
│       └── theme/
│           └── app_theme.dart
├── safeword-backend/       # Node.js API
│   ├── index.js
│   ├── .env.example
│   └── src/
│       ├── middleware/
│       │   └── auth.js
│       └── routes/
│           └── credentials.js
└── supabase_schema.sql     # Database schema
```

---

## 🚀 Quick Start

### Step 1: Supabase Setup

1. Create a project at [supabase.com](https://supabase.com)
2. Go to **Authentication → Providers → Email** → enable **Confirm email**
3. Go to **SQL Editor** → paste `supabase_schema.sql` → **Run**
4. Note your credentials from **Settings → API**:
   - `Project URL`
   - `anon/public key`
   - `service_role key`

---

### Step 2: Backend Setup

```bash
cd safeword-backend
cp .env.example .env
# Edit .env with your Supabase credentials
npm install
npm run dev        # Development with nodemon
# npm start        # Production
```

The server starts on `http://localhost:3000`. Health check: `GET /health`

**`.env` template:**
```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your_anon_key
SUPABASE_SERVICE_KEY=your_service_role_key
PORT=3000
NODE_ENV=development
ALLOWED_ORIGINS=http://localhost:3000
```

---

### Step 3: Flutter App Setup

1. **Update `lib/config.dart`:**
   ```dart
   static const String supabaseUrl = 'https://your-project.supabase.co';
   static const String supabaseAnonKey = 'your_anon_key';
   static const String apiBaseUrl = 'http://10.0.2.2:3000'; // Android emulator
   ```

2. **Android: Update `android/app/src/main/AndroidManifest.xml`**  
   Add inside `<application>`:
   ```xml
   <uses-permission android:name="android.permission.INTERNET"/>
   ```

3. **Run:**
   ```bash
   cd safeword
   flutter pub get
   flutter run
   ```

---

## 🔒 Security Architecture

### Encryption Flow

```
User enters Master Password
        │
        ▼
PBKDF2-SHA256 (100,000 iterations + per-user salt)
        │
        ▼
256-bit Derived Key (in memory only, never stored)
        │
        ├──► Encrypt password ──► AES-256-CBC + random IV
        │                               │
        │                               ▼
        │                    { ciphertext, IV } ──► Backend (API)
        │
        └──► Decrypt on fetch ──► AES-256-CBC(ciphertext, key, IV)
                                          │
                                          ▼
                                    Plaintext Password (shown to user)
```

### Key Properties

| Property | Value |
|---|---|
| Algorithm | AES-256-CBC |
| Key Derivation | PBKDF2-SHA256 |
| Iterations | 100,000 |
| Key Size | 256-bit (32 bytes) |
| IV Size | 128-bit (16 bytes, random per credential) |
| Salt | 256-bit (32 bytes, random per user) |
| Master password storage | **Never** — memory only |
| Backend sees plaintext | **Never** |

### Auto-Lock
- Vault auto-locks after **5 minutes** of inactivity
- Clipboard auto-clears after **30 seconds**
- Revealed passwords auto-hide after **30 seconds**

---

## 📡 API Reference

Base URL: `http://localhost:3000`

All routes (except `/health`) require: `Authorization: Bearer <supabase_access_token>`

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/health` | Health check |
| GET | `/api/credentials` | List credentials (supports `?search=`) |
| GET | `/api/credentials/:id` | Get single credential |
| POST | `/api/credentials` | Create credential |
| PUT | `/api/credentials/:id` | Update credential |
| DELETE | `/api/credentials/:id` | Delete credential |

**POST/PUT body:**
```json
{
  "title": "GitHub",
  "username": "john@example.com",
  "password": "<base64-encrypted-ciphertext>",
  "more_info": "Work account",
  "iv": "<base64-iv>",
  "salt": "<base64-salt>"
}
```

---

## 🚢 Deployment

### Backend (Render / Railway / Fly.io)

1. Push `safeword-backend/` to GitHub
2. Create a new Web Service on [Render](https://render.com)
3. Set environment variables (all from `.env`)
4. Build command: `npm install`
5. Start command: `npm start`

### Flutter

1. Update `config.dart` → set `apiBaseUrl` to your deployed backend URL
2. Build release APK:
   ```bash
   flutter build apk --release
   ```

---

## 🧪 Running Tests

```bash
# Backend
cd safeword-backend
npm test

# Flutter
cd safeword
flutter test
```

---

## ✅ Acceptance Criteria

- [x] Email + password signup with OTP email verification
- [x] JWT session persistence via Supabase
- [x] Auto-lock after 5 minutes inactivity
- [x] Add / edit / delete credentials
- [x] Real-time search (debounced)
- [x] Password hidden by default, toggle visible
- [x] One-tap copy to clipboard
- [x] Clipboard auto-clears after 30 seconds
- [x] Pull-to-refresh credential list
- [x] Master password never stored anywhere
- [x] Backend never receives plaintext passwords
- [x] Unique IV per credential
- [x] RLS prevents cross-user data access
- [x] Password generator with strength indicator
- [x] Loading states + user-friendly error messages
- [x] Swipe-to-delete credentials
