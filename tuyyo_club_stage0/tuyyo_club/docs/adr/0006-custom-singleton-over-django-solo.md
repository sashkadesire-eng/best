# ADR-0006: власний SingletonModel замість django-solo

**Статус:** ухвалено · **Дата:** 2026-08-01

django-solo додає залежність заради ~10 рядків коду; можливі конфлікти з
parler TranslatableModel. Власний abstract SingletonModel (pk=1, get_solo())
сумісний з parler, нуль залежностей, pure Django way. settings.TUYYO_BUSINESS
залишається лише як seed-джерело; після `seed_cms` єдине джерело правди — БД.
