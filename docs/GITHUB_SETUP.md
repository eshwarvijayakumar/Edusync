# Publishing EduSync to GitHub

## Before publishing

1. Do not upload `.env`, `android/local.properties`, keystore files, APKs, AABs, or real API keys. The included `.gitignore` excludes them.
2. Confirm `.env.example` contains placeholders only.
3. Keep the source folders (`lib`, `android`, `supabase`, `test`), documentation, `README.md`, and `LICENSE`.
4. Run the checks below from the project root:

```bash
flutter pub get
flutter test
```

## Create the repository on GitHub

1. Sign in to [GitHub](https://github.com).
2. Select **New repository**.
3. Repository name: `edusync`.
4. Description: `AI-powered personalised study companion for Indian school and college students.`
5. Select **Public** if the submission requires open-source code.
6. Do **not** initialise it with a README, `.gitignore`, or licence because this project already has those files.
7. Click **Create repository**.

## Upload the source project

Open PowerShell in the EduSync source folder and run the commands GitHub displays, or use this sequence after replacing `YOUR-USERNAME`:

```powershell
git init
git add .
git status
git commit -m "Initial public release of EduSync prototype"
git branch -M main
git remote add origin https://github.com/YOUR-USERNAME/edusync.git
git push -u origin main
```

Before `git add .`, review `git status` and make sure no `.env`, APK, AAB, keystore, or build folders appear. If a secret was ever pushed, revoke it at the provider and replace it; deleting a file later does not remove it from Git history.

## Repository URL to submit

After the push succeeds, copy the browser address from your repository page. It will look like:

```text
https://github.com/YOUR-USERNAME/edusync
```

Paste that URL into the submission form’s **Repository URL** field.

## Suggested final repository contents

```text
edusync/
├── lib/                         # Flutter app source code
├── android/                     # Android configuration
├── supabase/                    # Schema, sample seed data, Edge Function
├── test/                        # Flutter automated tests
├── tests/                       # Sample demo data and acceptance tests
├── docs/                        # Architecture and GitHub setup documents
├── scripts/                     # Setup helpers
├── README.md
├── LICENSE
├── .env.example
└── .gitignore
```
