# 🎓 EduSync - India-First AI Study Companion (v1.1.0)

[![Flutter](https://img.shields.io/badge/Flutter-3.24.5-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.5.4-0175C2?logo=dart)](https://dart.dev)
[![Supabase](https://img.shields.io/badge/Supabase-Auth%20%26%20Database-3ECF8E?logo=supabase)](https://supabase.com)
[![Platform](https://img.shields.io/badge/Platform-Android%20APK%20%7C%20AAB-3DDC84?logo=android)](https://developer.android.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

**EduSync** is an India-first AI personal study companion designed specifically for school students (**Grades 9–12 across CBSE and Tamil Nadu State Board**) and college students (**B.Tech, B.Sc, B.Com, BA, MBBS, BBA, Law, etc.**). It provides contextual, curriculum-aligned study assistance tailored to each student's grade, board, degree, department, semester, subjects, preferred Indian language, and learning goal.

Package name: `com.edusync.app`  
Current Version: `1.1.0` (Version Code: `2`)

---

## 📱 Features

- **Personalised Onboarding & Badging:** 
  - Dynamic profile setup: School (Grades 9–12, CBSE / Tamil Nadu State Board, Medium, Subjects, Goal) or College (Degree, Department, Semester, Subjects, Goal, College Name).
  - Dynamic badges like `CBSE • Grade 10`, `Tamil Nadu State Board • Grade 10`, or `B.Tech CSE • Semester 4`.
  - Secure profile editing at any time.

- **ChatGPT-Style Study Companion Chat:**
  - Connected to a secure server-side LLM service via Supabase Edge Function (`ai-companion`).
  - No AI API key is ever embedded in the mobile application.
  - Contextual responses personalized to the student's curriculum with Indian real-world analogies (e.g. UPI, ISRO missions, local infrastructure).
  - Loading state: *"EduSync is thinking…"*.
  - Error recovery: Inline error card with a **Retry Question** button on network or AI service drops.
  - Horizontally scrolling smart suggestions (e.g., *"Explain photosynthesis for CBSE Grade 10"*, *"Explain waterfall model for B.Tech CSE"*).
  - One-tap response action chips that invoke AI follow-up queries with conversation memory:
    - 💡 **Explain Simpler**
    - 📖 **Give an Example**
    - 📝 **Create Quiz**
    - 🗂️ **Make Flashcards**
    - 🌐 **Translate** (Hindi, Tamil, Malayalam, Telugu, Kannada, etc.)
    - 🚩 **Report Answer**
  - Academic disclaimer: *"AI can make mistakes. Verify important academic answers with your textbook or teacher."*

- **Notes & PDF Upload (RAG Study Help):**
  - Select PDFs and text files from device storage.
  - Safe size validation (up to 15 MB) and format verification.
  - Ask questions directly about uploaded documents with source page citations.

- **Study Tools:**
  - **Interactive Quiz Generator:** MCQ and Short-Answer modes with instant feedback and pedagogical explanations.
  - **3D Flip Flashcards:** Interactive gesture-based flip cards with active recall and mastery tracking (*"Got It"* vs *"Review Again"*).
  - **Saved Decks & Quizzes:** Review past attempts, scores, and track weekly learning streaks.

- **Robust Security & Fair Use:**
  - Supabase Authentication with Row-Level Security (RLS) ensuring strict student data isolation.
  - Rate limiting of **10 free AI questions per day** with midnight reset.
  - Server-side LLM gateway via Supabase Edge Functions.
  - Valid email and 10-digit Indian mobile number validation with duplicate registration protection.

---

## 🎨 Design System

| Element | Specification | Hex / Value |
| :--- | :--- | :--- |
| **Background** | Clean Crisp White / Light Slate | `#F8FAFC` / `#FFFFFF` |
| **Typography** | Deep Navy | `#0F172A` |
| **Primary Buttons** | Vibrant Indigo | `#4F46E5` |
| **Accent / Highlights** | Soft Warm Orange | `#F59E0B` |
| **Success / Mastery** | Emerald Green | `#10B981` |
| **Card Radii** | Smooth Rounded Corners | `14px – 20px` |

---

## 📦 Build Outputs

The project includes pre-built release artifacts ready for distribution and installation:

1. **`EduSync-v1.1.apk`**: Installable Android release APK file (Version 1.1.0, Code 2). Retains the exact same package name (`com.edusync.app`) and debug/release keystore so it installs seamlessly as an in-place update over previous builds.
2. **`EduSync.aab`**: Android App Bundle for Google Play Store console upload.

---

## 🚀 Building from Source

To compile the release APK locally:

```bash
# 1. Fetch dependencies
flutter pub get

# 2. Run unit and verification tests
flutter test

# 3. Build the installable release APK
flutter build apk --release
```

The compiled binary is generated at:
- `build/app/outputs/flutter-apk/app-release.apk` (copied to `EduSync-v1.1.apk`)

---

## ⚙️ Environment Configuration

Copy the template `.env.example` to `.env`:

```bash
cp .env.example .env
```

Set your configuration values:

```env
# 1. Supabase Client Configuration (Public / Mobile App)
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your-anon-public-key

# 2. Supabase Server-Side Environment Variables (Edge Function Secrets)
SUPABASE_SERVICE_ROLE_KEY=your-supabase-service-role-key
AI_PROVIDER=gemini # Options: gemini, openai, groq, anthropic
AI_API_KEY=your-ai-api-key
AI_MODEL=gemini-1.5-flash
```

---

## 🗄️ Database Schema & Edge Functions

1. **Run Database Migrations:**
   Execute `supabase/schema.sql` in the Supabase SQL Editor. This sets up:
   - `student_profiles`
   - `curriculum_topics` (Curriculum grounding for CBSE, Tamil Nadu State Board, and Engineering SDLC)
   - `conversations` & `messages`
   - `study_materials` & `material_chunks`
   - `quizzes` & `flashcards`
   - `usage_limits`
   - Strict Row-Level Security policies.

2. **Seed Curriculum Data:**
   Execute `supabase/seed_data.sql` to populate reference topics for:
   - CBSE Grade 10 Science (Life Processes: Photosynthesis)
   - Tamil Nadu State Board Grade 10 Science (Plant Physiology: Photosynthesis & Plastids)
   - B.Tech CSE (Software Engineering: Waterfall Model)

3. **Deploy the Edge Function:**
   Deploy `supabase/functions/ai-companion/index.ts` to your Supabase project:
   ```bash
   supabase functions deploy ai-companion
   supabase secrets set AI_API_KEY=your_key AI_PROVIDER=gemini AI_MODEL=gemini-1.5-flash
   ```

---

## 🧪 Testing

Run automated tests:

```bash
flutter test
```

Includes test suites covering:
- CBSE Grade 10 Photosynthesis with chemical equation, 3 steps, stomata/guard cells, and starch test
- Tamil Nadu State Board Grade 10 Science with Samacheer Kalvi Hill reaction & Calvin cycle
- B.Tech CSE Waterfall Model with 6 sequential phases, advantages, limitations, and software engineering applications
- General questions outside syllabus (e.g. Microwave Oven) with clear, concise answers without claiming syllabus alignment
- Follow-up "Give an example" leveraging conversation memory
- Network or API key failure handling with inline error card and Retry Question button
- Daily AI usage quota tracking and student badge generation

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 📋 Submission documents

- [Technical Design Document](docs/TECHNICAL_DESIGN.md) — architecture, data design, security, and AI flow.
- [Sample Data](tests/sample-data.json) — fictional records for local/demo testing only.
- [Test Cases](tests/TEST_CASES.md) — functional and security acceptance checks.
- [GitHub Publishing Guide](docs/GITHUB_SETUP.md) — safe steps to publish this repository.

## 🛠 Setup helper scripts

After copying `.env.example` to `.env` and setting the required values, use one of the setup helpers:

```powershell
./scripts/setup.ps1
```

```bash
bash scripts/setup.sh
```

The scripts install dependencies only. They do not create cloud accounts, deploy database changes, or insert secret keys.
