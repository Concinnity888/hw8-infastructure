#!/usr/bin/env bash

RESULT=$(npm test 2>&1 | tr -s "\n" " ")
echo "RESULT: ${RESULT}"

CURRENT_TAG=$(git tag | sort -r | head -1)
UNIQUE_KEY="https://github.com/Concinnity888/hw8-infastructure/releases/tag/${CURRENT_TAG}"

RELEASE_URL=$(
  curl -s -X POST "https://api.tracker.yandex.net/v2/issues/_search" \
  --header "Authorization: OAuth ${OAUTH}" \
  --header "X-Org-ID: ${ORG}" \
  --header 'Content-Type: application/json' \
  --data "{\"filter\": {\"unique\": \"$UNIQUE_KEY\"} }" | jq -r ".[].self"
)
echo "RELEASE: ${RELEASE_URL}"

RESPONSE=$(
  curl -so dev/null -w '%{http_code}' -X POST "${RELEASE_URL}/comments" \
  --header "Authorization: OAuth ${OAUTH}" \
  --header "X-Org-ID: ${ORG}" \
  --header "Content-Type: application/json" \
  --data '{
      "text": "'"${RESULT}"'"
  }'
)

echo "RESPONSE: ${RESPONSE}"

if [ ${RESPONSE} = 201 ]; then
  echo "Комментарий добавлен в ${RELEASE_URL}"
  exit 0
else 
  echo "Ошибка при добавлении комментариев в ${RELEASE_URL}"
  exit 1
fi
