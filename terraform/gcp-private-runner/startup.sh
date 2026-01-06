
set -euo pipefail
echo "Requesting registration token for ${{ github.repository }}"

# Ensure token is present
: "${GH_TOKEN:?GH_TOKEN is not set}"

# Call the API with proper headers
HTTP_BODY=$(curl -sS -X POST \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer ${GH_TOKEN}" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  "https://api.github.com/repos/${{ github.repository }}/actions/runners/registration-token" \
  -w "\n%{http_code}")

HTTP_CODE=$(echo "$HTTP_BODY" | tail -n1)
TOKEN_JSON=$(echo "$HTTP_BODY" | sed '$d')  # body without status code

if [ "$HTTP_CODE" != "201" ]; then
  echo "Failed to get registration token (HTTP $HTTP_CODE)" >&2
  echo "Response: $TOKEN_JSON" >&2
  exit 1
fi

REG_TOKEN=$(echo "$TOKEN_JSON" | jq -r '.token')
if [ -z "$REG_TOKEN" ] || [ "$REG_TOKEN" = "null" ]; then
  echo "Registration token missing in response" >&2
  echo "Response: $TOKEN_JSON" >&2
  exit 1
fi

echo "token=$REG_TOKEN" >> "$GITHUB_OUTPUT"
