#!/usr/bin/env bash

CURRENT_TAG=$(git tag | sort -r | head -1)
PREV_TAG=$(git tag | sort -r | head -1 | tail -1)
AUTHOR=$(git show "$CURRENT_TAG" --pretty=format:"%an" --no-patch)
DATE=$(git show "$CURRENT_TAG" --pretty=format:"%ad" --no-patch)

CHANGELOG=$(git log ${PREV_TAG}.. --pretty=format:"%s | %an, %ad\n" --date=short | tr -s "\n" " ")
DESCRIPTION="${AUTHOR} \n ${DATE} \n Номер версии: ${CURRENT_TAG} \n changelog: ${CHANGELOG}"
UNIQUE_KEY="https://github.com/Concinnity888/hw8-infastructure/releases/tag/${CURRENT_TAG}"
URL="https://api.tracker.yandex.net/v2/issues/"

REQUEST='{
  "summary": "'"Релиз ${CURRENT_TAG}"'",
  "description": "'"${DESCRIPTION}"'",
  "queue": "TMP",
  "unique": "'"${UNIQUE_KEY}"'"
}'

echo "\nREQUEST: ${REQUEST}\n"

RESPONSE=$(
  curl -so dev/null -w '%{http_code}' -X POST ${URL} \
  --header "Authorization: OAuth ${OAUTH}" \
  --header "X-Org-ID: ${ORG}" \
  --header "Content-Type: application/json" \
  --data "${REQUEST}"
)
echo "\nStatus code: ${RESPONSE}\n"

TASK_NAME=$(
  curl -X POST "https://api.tracker.yandex.net/v2/issues/_search" \
  --header "Authorization: OAuth $OAUTH " \
  --header "X-Org-Id: $ORG" \
  --header "Content-Type: application/json" \
  --data '{
    "filter": {
      "unique": "'"${UNIQUE_KEY}"'"
    }
  }' | jq -r '.[0].key'
)
echo "TASK_NAME: ${TASK_NAME}"

if [ ${RESPONSE} = 201 ]; then
  echo "Задача создана"
  exit 0
elif [ ${RESPONSE} = 409 ]; then
  echo 'Задача с таким релизом уже создана'
  UPDATE=$(curl -so dev/null -w '%{http_code}' -X PATCH \
    "https://api.tracker.yandex.net/v2/issues/${TASK_NAME}" \
    --header "Content-Type: application/json" \
    --header "Authorization: OAuth ${OAUTH} " \
    --header "X-Org-Id: ${ORG}" \
    --data '{
      "summary": "'"Релиз ${CURRENT_TAG}"'",
      "description": "'"${DESCRIPTION}"'",
    }'
  )
  echo "\nStatus code: ${UPDATE}\n"
  if [ ${UPDATE} = 200 ]; then
    echo "Задача успешно обновлена"
    exit 0
  if [ ${UPDATE} = 201 ]; then
    echo "201"
    exit 0
  else
    echo "Ошибка обновления"
    exit 1
  fi
else
  echo "Ошибка"
  exit 1
fi
