#!/usr/bin/env bash
# Проверка документации: обязательные файлы, живые ссылки, актуальность индекса слайдов.
set -uo pipefail
failures=0
ok()  { printf '  \033[32mok\033[0m    %s\n' "$1"; }
bad() { printf '  \033[31mfail\033[0m  %s\n' "$1"; failures=$((failures+1)); }

printf '\nОбязательные документы\n'
for f in README.md MANIFEST.sha256 docs/index.md docs/content/slides.md \
         docs/content/materials.md docs/verification/matrix.md; do
  [ -s "$f" ] && ok "$f" || bad "$f отсутствует или пуст"
done

printf '\nИндекс слайдов соответствует презентации\n'
if python3 -c "import pptx" 2>/dev/null; then
  expected="$(python3 -c "from pptx import Presentation; print(len(Presentation('Концепция_счастья.pptx').slides))")"
  actual="$(grep -c '^## [0-9]' docs/content/slides.md)"
  if [ "$expected" = "$actual" ]; then ok "слайдов в файле: $expected, в индексе: $actual"
  else bad "слайдов в файле: $expected, в индексе: $actual — запустите make outline"; fi
else
  echo "  skip  python-pptx не установлен, сверка индекса пропущена"
fi

printf '\nСсылки\n'
broken=0
while IFS= read -r line; do
  file="${line%%:*}"; target="$(printf '%s' "$line" | sed -n 's/.*](\([^)#]*\).*/\1/p')"
  [ -z "$target" ] && continue
  case "$target" in http*|mailto:*|\#*|/*) continue ;; esac
  base="$(dirname "$file")"
  if [ ! -e "$base/$target" ] && [ ! -e "$target" ]; then bad "$file -> $target (битая ссылка)"; broken=$((broken+1)); fi
done < <(grep -rnoE '\[[^]]*\]\([^)]+\)' --include='*.md' . 2>/dev/null)
[ "$broken" -eq 0 ] && ok "битых относительных ссылок нет"

printf '\n'
if [ "$failures" -gt 0 ]; then printf '\033[31m%d проблем в документации\033[0m\n' "$failures"; exit 1; fi
printf '\033[32mДокументация согласована\033[0m\n'
