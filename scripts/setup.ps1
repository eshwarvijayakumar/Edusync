$ErrorActionPreference = "Stop"

if (-not (Test-Path ".env")) {
    Copy-Item ".env.example" ".env"
    Write-Host "Created .env from .env.example. Add your own Supabase values before running the app."
}
else {
    Write-Host ".env already exists; it was not changed."
}

flutter pub get
Write-Host "Setup complete. Run 'flutter test' to verify the project."
