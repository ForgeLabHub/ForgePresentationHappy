# ForgePresentationHappy — репозиторий артефактов, а не кода.
#
# Здесь нет «сборки приложения». Есть три вещи, которые нужно уметь проверять:
#   1) целостность файлов (их нельзя незаметно подменить или обрезать);
#   2) читаемость содержимого (индекс слайдов и докладов — текст в репозитории);
#   3) комплектность поставки (что отдавать, в каком формате).

SHELL := /usr/bin/env bash
.DEFAULT_GOAL := help

PYTHON ?= python3
DECK   ?= Концепция_счастья.pptx
DIST   ?= dist

.PHONY: help doctor verify checksums outline formats docs-check package verify-all clean

help: ## Список целей
	@grep -hE '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) \
	  | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-14s\033[0m %s\n", $$1, $$2}'

doctor: ## Проверить инструменты, размеры файлов и лимиты GitHub
	@./scripts/doctor.sh

checksums: ## Пересчитать MANIFEST.sha256 (ТОЛЬКО при осознанной замене файлов)
	sha256sum *.pptx *.pdf *.docx *.mp4 *.html > MANIFEST.sha256
	@echo "MANIFEST.sha256 обновлён — проверьте diff перед коммитом"

verify: ## Проверить целостность по MANIFEST.sha256
	@./scripts/verify.sh

outline: ## Пересобрать индекс слайдов из презентации
	$(PYTHON) tools/pptx_outline.py "$(DECK)" > docs/content/slides.md
	@echo "docs/content/slides.md обновлён"

formats: ## Проверить, что все артефакты открываются
	$(PYTHON) tools/check_formats.py

docs-check: ## Проверить документацию, ссылки и полноту индекса
	@./scripts/docs-check.sh

package: ## Собрать комплект для сдачи в dist/ с контрольными суммами
	@mkdir -p $(DIST)
	cp "$(DECK)" "Концепция_счастья.pdf" "Концепция_счастья_один_лист.pdf" \
	   "Речь_доклада.docx" "Инструкция_защиты.docx" "Возможные_вопросы.docx" $(DIST)/
	cd $(DIST) && sha256sum * > SHA256SUMS && ls -la

verify-all: verify formats docs-check ## Полная проверка репозитория
	@echo "verify-all: ok"

clean: ## Удалить собранные комплекты
	rm -rf $(DIST)
