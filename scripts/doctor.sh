#!/usr/bin/env bash
# Проверка окружения и ограничений GitHub по размерам.
set -uo pipefail
failures=0; warnings=0
ok()   { printf '  \033[32mok\033[0m    %s\n' "$1"; }
bad()  { printf '  \033[31mfail\033[0m  %s\n' "$1"; failures=$((failures+1)); }
warn() { printf '  \033[33mwarn\033[0m  %s\n' "$1"; warnings=$((warnings+1)); }

printf '\nИнструменты\n'
command -v git >/dev/null 2>&1 && ok "git" || bad "git не найден"
command -v sha256sum >/dev/null 2>&1 && ok "sha256sum" || bad "sha256sum не найден"
if python3 -c "import pptx, docx" 2>/dev/null; then
  ok "python-pptx и python-docx установлены"
else
  warn "нет python-pptx/python-docx: make formats и make outline недоступны (pip install python-pptx python-docx)"
fi
command -v git-lfs >/dev/null 2>&1 && ok "git-lfs установлен" || warn "git-lfs не установлен (сейчас не требуется)"

printf '\nЛимиты GitHub\n'
# 100 МБ — жёсткий лимит на файл; 50 МБ — предупреждение.
big=0
while IFS= read -r f; do
  size="$(stat -c%s "$f")"
  human="$(du -h "$f" | cut -f1)"
  if [ "$size" -ge 104857600 ]; then bad "$f ($human) — превышает лимит GitHub 100 МБ"; big=1
  elif [ "$size" -ge 52428800 ]; then warn "$f ($human) — больше 50 МБ, стоит рассмотреть Git LFS"; big=1
  fi
done < <(find . -maxdepth 1 -type f \( -name '*.pptx' -o -name '*.pdf' -o -name '*.docx' -o -name '*.mp4' -o -name '*.html' \))
[ "$big" -eq 0 ] && ok "все артефакты в пределах лимитов GitHub"

printf '\nРепозиторий\n'
if [ -f MANIFEST.sha256 ]; then ok "MANIFEST.sha256 присутствует"; else bad "MANIFEST.sha256 отсутствует"; fi
[ -f README.md ] && ok "README.md" || bad "README.md отсутствует"
[ -d docs ] && ok "docs/ присутствует" || warn "нет docs/"
if [ -n "$(git status --porcelain 2>/dev/null | head -1)" ]; then
  warn "в рабочем каталоге есть незакоммиченные изменения"
fi

printf '\n'
if [ "$failures" -gt 0 ]; then printf '\033[31m%d проверок провалено\033[0m, предупреждений: %d\n' "$failures" "$warnings"; exit 1; fi
printf '\033[32mГотово к работе\033[0m, предупреждений: %d\n' "$warnings"
