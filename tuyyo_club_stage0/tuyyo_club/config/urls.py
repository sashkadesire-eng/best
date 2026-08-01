"""URL-конфігурація TUYYO.CLUB.

i18n_patterns: /en/ /es/ (prefix_default_language=True).
Карта URL (v3): /en/sup-rental-benidorm/ ↔ /es/alquiler-sup-benidorm/.
"""
from django.conf.urls.i18n import i18n_patterns
from django.contrib import admin
from django.contrib.sitemaps.views import sitemap
from django.urls import path
from django.views.generic import RedirectView, TemplateView

from cms.sitemaps import PageSitemap
from cms.views import HomeView, PageDetailView
from core.sitemaps import StaticViewSitemap
from core.views import BookingPlaceholderView, StyleguideView

sitemaps = {"static": StaticViewSitemap, "pages": PageSitemap}

urlpatterns = [
    path("admin/", admin.site.urls),
    path("sitemap.xml", sitemap, {"sitemaps": sitemaps}, name="sitemap"),
    path("robots.txt", TemplateView.as_view(template_name="robots.txt", content_type="text/plain")),
]

# ── Легасі-URL React-версії. Сторінки, що вже існують, — 301 (permanent).
#    sup-rental-* тимчасово 302 → /en/; в Етапі 4 — 301 на фінальні адреси. ──
_legacy_permanent = {
    "terms": "/en/terms-and-safety/",
    "privacy": "/en/privacy-policy/",
    "cookies": "/en/cookie-policy/",
    "legal": "/en/legal-notice/",
    "booking": "/en/booking/",
}
for _path, _target in _legacy_permanent.items():
    urlpatterns.append(path(_path, RedirectView.as_view(url=_target, permanent=True)))
for _city in ("benidorm", "altea", "villajoyosa", "calpe", "alicante"):
    urlpatterns.append(path(f"sup-rental-{_city}", RedirectView.as_view(url="/en/", permanent=False)))

urlpatterns += i18n_patterns(
    path("", HomeView.as_view(), name="home"),
    path("booking/", BookingPlaceholderView.as_view(), name="booking"),
    path("styleguide/", StyleguideView.as_view(), name="styleguide"),
    # Catch-all CMS-сторінок — ОБОВ'ЯЗКОВО останнім (slug суворий до мови)
    path("<slug:slug>/", PageDetailView.as_view(), name="page"),
    prefix_default_language=True,
)
