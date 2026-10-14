#!/usr/bin/env bash
# Uploads a file to a Google Drive folder.
#
# Usage: upload_to_drive.sh <file> <folder id>
#
# Auth, first match wins:
#   1. OAuth user:      GDRIVE_CLIENT_ID, GDRIVE_CLIENT_SECRET, GDRIVE_REFRESH_TOKEN
#   2. Service account: GDRIVE_SA_KEY (the JSON key). Only works for Shared Drive
#      folders: service accounts have no storage quota in a personal My Drive.
# With neither set, prints a notice and exits 0 so the build stays green.
set -euo pipefail

file="$1"
folder_id="$2"
name="$(basename "$file")"

b64url() { openssl base64 -A | tr '+/' '-_' | tr -d '='; }

if [[ -n "${GDRIVE_REFRESH_TOKEN:-}" ]]; then
  token="$(curl -sSf https://oauth2.googleapis.com/token \
    -d client_id="$GDRIVE_CLIENT_ID" \
    -d client_secret="$GDRIVE_CLIENT_SECRET" \
    -d refresh_token="$GDRIVE_REFRESH_TOKEN" \
    -d grant_type=refresh_token | jq -r .access_token)"
elif [[ -n "${GDRIVE_SA_KEY:-}" ]]; then
  email="$(jq -r .client_email <<<"$GDRIVE_SA_KEY")"
  key_file="$(mktemp)"
  trap 'rm -f "$key_file"' EXIT
  jq -r .private_key <<<"$GDRIVE_SA_KEY" >"$key_file"
  now="$(date +%s)"
  header="$(printf '{"alg":"RS256","typ":"JWT"}' | b64url)"
  claims="$(jq -cn --arg iss "$email" --argjson iat "$now" \
    '{iss: $iss, scope: "https://www.googleapis.com/auth/drive",
      aud: "https://oauth2.googleapis.com/token", iat: $iat, exp: ($iat + 3600)}' | b64url)"
  signature="$(printf '%s.%s' "$header" "$claims" | openssl dgst -sha256 -sign "$key_file" | b64url)"
  token="$(curl -sSf https://oauth2.googleapis.com/token \
    -d grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer \
    -d assertion="$header.$claims.$signature" | jq -r .access_token)"
else
  echo "::notice::Drive upload skipped: no GDRIVE_* secrets set. The APK is still attached to this run as an artifact."
  exit 0
fi

if [[ -z "$token" || "$token" == "null" ]]; then
  echo "::error::Could not get a Google access token."
  exit 1
fi

# Resumable upload: the first request creates the session, the second sends the bytes.
metadata="$(jq -cn --arg name "$name" --arg parent "$folder_id" '{name: $name, parents: [$parent]}')"
session_url="$(curl -sSf -D - -o /dev/null -X POST \
  "https://www.googleapis.com/upload/drive/v3/files?uploadType=resumable&supportsAllDrives=true" \
  -H "Authorization: Bearer $token" \
  -H "Content-Type: application/json; charset=UTF-8" \
  -H "X-Upload-Content-Type: application/vnd.android.package-archive" \
  -d "$metadata" | grep -i '^location:' | cut -d' ' -f2 | tr -d '\r')"
if [[ -z "$session_url" ]]; then
  echo "::error::Drive did not start an upload session. Check that the folder is shared with this account."
  exit 1
fi

response="$(curl -sS -w '\n%{http_code}' -X PUT "$session_url" \
  -H "Content-Type: application/vnd.android.package-archive" \
  --data-binary @"$file")"
status="${response##*$'\n'}"
body="${response%$'\n'*}"

if [[ "$status" != 200 && "$status" != 201 ]]; then
  echo "::error::Drive upload failed (HTTP $status): $body"
  exit 1
fi

file_id="$(jq -r .id <<<"$body")"
echo "Uploaded $name to Drive: https://drive.google.com/file/d/$file_id/view"
if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
  echo "Uploaded [$name](https://drive.google.com/file/d/$file_id/view) to Google Drive." >>"$GITHUB_STEP_SUMMARY"
fi
