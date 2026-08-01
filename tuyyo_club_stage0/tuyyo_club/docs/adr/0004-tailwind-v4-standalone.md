# ADR-0004: Tailwind v4 standalone CLI

**Статус:** ухвалено · **Дата:** 2026-08-01

Без Node.js-ланцюжка: бінарник tailwindcss-linux-x64 у bin/ (gitignored),
збірка через scripts/build_css.sh. Конфіг — CSS-first (@theme, @custom-variant
dark за data-theme). Токени анімацій — 1:1 з index.css референсу.
