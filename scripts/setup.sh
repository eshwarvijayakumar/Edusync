#!/usr/bin/env bash
set -euo pipefail

if [ ! -f .env ]; then
  cp .env.example .env
  echo "Created .env from .env.example. Add your own Supabase values before running the app."
else
  echo ".env already exists; it was not changed."
fi

flutter pub get
echo "Setup complete. Run 'flutter test' to verify the project."
