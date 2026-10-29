#!/usr/bin/env bash
# Проверка целостности артефактов по MANIFEST.sha256.
#
# Смысл: бинарные документы нельзя проверить глазами в diff. Контрольная сумма —
# единственный способ заметить, что презентация подменена или обрезана.
set -uo pipefail
failures=0
ok()  { printf '  \033[32mok\033[0m    %s\n' "$1"; }
bad() { printf '  \033[31mfail\033[0m  %s\n' "$1"; failures=$((failures+1)); }

printf '\nЦелостность (MANIFEST.sha256)\n'
if [ ! -f MANIFEST.sha256 ]; then
  bad "MANIFEST.sha256 отсутствует"
else
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    expected="${line%% *}"
    file="${line#*  }"
    if [ ! -f "$file" ]; then
      bad "$file отсутствует"
      continue
    fi
    actual="$(sha256sum "$file" | awk '{print $1}')"
    if [ "$actual" = "$expected" ]; then ok "$file"; else bad "$file изменён (сумма не совпадает)"; fi
  done < MANIFEST.sha256
fi

printf '\nФайлы вне манифеста\n'
shopt -s nullglob
extra=0
for f in *.pptx *.pdf *.docx *.mp4 *.html; do
  grep -q "  $f\$" MANIFEST.sha256 2>/dev/null || { bad "$f не описан в MANIFEST.sha256"; extra=$((extra+1)); }
done
[ "$extra" -eq 0 ] && ok "все артефакты учтены"

printf '\n'
if [ "$failures" -gt 0 ]; then printf '\033[31m%d проблем\033[0m\n' "$failures"; exit 1; fi
printf '\033[32mЦелостность подтверждена\033[0m\n'
