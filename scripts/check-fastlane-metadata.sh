#!/bin/bash
# Checks all fastlane metadata files for their maximum lengths.
# Maximum lengths based on https://gitlab.com/-/snippets/1895688.

# Every error should fail
set -e

# Check changelogs (ignoring the ones we know already exceed the limit).
for locale in ./fastlane/metadata/android/*; do
  [[ ! -d $locale ]] && echo "Skipping $locale" && continue
  [[ ! -d $locale/changelogs ]] && echo "Skipping $locale as it contains no changelogs" && continue

  for changelog in $locale/changelogs/*.txt; do
    if [[ $changelog = "./fastlane/metadata/android/en-US/changelogs/11.txt" ]] || [[ $changelog = "./fastlane/metadata/android/en-US/changelogs/13.txt" ]]; then
      echo "Skipping $changelog as it is already released and know to exceed the limit"
      continue
    fi

    chars=$(wc -m "$changelog" | awk -F\  '{print $1}')
    if [[ $chars -gt 500 ]]; then
      echo "$changelog exceeds the 500 character limit"
      exit 1
    fi
  done
done
echo "[i] Changelogs okay"

# Check short descriptions.
for locale in ./fastlane/metadata/android/*; do
  desc=$locale/short_description.txt
  [[ ! -d $locale ]] && echo "Skipping $locale" && continue
  [[ ! -f $desc ]] && echo "Skipping $locale as it contains no short description" && continue

    chars=$(wc -m "$desc" | awk -F\  '{print $1}')
    if [[ $chars -gt 80 ]]; then
      echo "$desc exceeds the 80 character limit"
      exit 1
    fi
done
echo "[i] Short descriptions okay"

# Check full descriptions.
for locale in ./fastlane/metadata/android/*; do
  desc=$locale/full_description.txt
  [[ ! -d $locale ]] && echo "Skipping $locale" && continue
  [[ ! -f $desc ]] && echo "Skipping $locale as it contains no full description" && continue

    chars=$(wc -m "$desc" | awk -F\  '{print $1}')
    if [[ $chars -gt 4000 ]]; then
      echo "$desc exceeds the 4000 character limit"
      exit 1
    fi
done
echo "[i] Long descriptions okay"

exit 0
