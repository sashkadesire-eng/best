# ADR-0007: локалізовані slug'и + lang_urls

**Статус:** ухвалено · **Дата:** 2026-08-01

Page.slug — TranslatedField. Резолвер суворий: /es/privacy-policy/ → 404,
бо ES-slug = politica-de-privacidad (SEO: кожна мова має власний keyword-URL).
django.urls.translate_url не підходить для перемикача мов і hreflang (реверсить
той самий slug) — тому views генерують lang_urls з page.translations, а seo.py
будує alternates з них.
