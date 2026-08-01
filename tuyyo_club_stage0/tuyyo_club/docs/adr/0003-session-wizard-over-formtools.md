# ADR-0003: кастомний session-wizard замість django-formtools

**Статус:** ухвалено · **Дата:** 2026-08-01

formtools SessionWizardView — канон, але: застарілі шаблони (несумісні з
дизайном референсу), слабка HTMX-інтеграція, режим підтримки.
Рішення: session state-machine + 6 Form-класів + PRG + HTMX + idempotency.
Патерни formtools (done(), умовні кроки) запозичені в API.
