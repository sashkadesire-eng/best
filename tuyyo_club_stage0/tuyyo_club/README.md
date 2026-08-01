# TUYYO.CLUB — Costa Blanca SUP Rental

Django 5.2 LTS · SSR · i18n EN/ES (parler) · Tailwind v4 · HTMX (з Етапу 3).

## Швидкий старт

```bash
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
python manage.py migrate
python manage.py runserver


## Перевірка Етапу 0

| URL                                             | Очікування                       |
| ----------------------------------------------- | -------------------------------- |
| http://127.0.0.1:8000/                          | 302 → /en/                       |
| http://127.0.0.1:8000/en/ · /es/                | Головна (hero 1:1), ES-переклади |
| http://127.0.0.1:8000/en/styleguide/            | Каталог компонентів              |
| http://127.0.0.1:8000/robots.txt · /sitemap.xml | SEO-ендпоінти, alternates        |
| http://127.0.0.1:8000/admin/                    | admin / admin123 (змінити!)      |

## Дорожня карта

- [x] **Етап 0** — Фундамент + SEO + якість
- [ ] **Етап 1** — Ядро CMS (SiteSettings, Page, Section, перекладені slug'и)
- [ ] **Етап 2** — Контентні моделі + seed 1:1
- [ ] **Етап 3** — Головна + 10 секцій
- [ ] **Етап 4** — Локальні лендінги + SEO-граф
- [ ] **Етап 5–6** — Booking-візард + оплата (MVP LIVE ≈ 15 вересня)
- [ ] **Етап 7–11** — Дашборд, PWA, контент-хаб, DE/NL

## ADR

`docs/adr/` — архітектурні рішення. `docs/wcag-checklist.md` — доступність.
