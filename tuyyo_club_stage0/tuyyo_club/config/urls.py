"""URL-конфігурація TUYYO.CLUB.

Локалізовані префікси /en/ /es/ (i18n_patterns, prefix_default_language=True).
Карта URL (v3): /en/sup-rental-benidorm/ ↔ /es/alquiler-sup-benidorm/ тощо.
"""
from django.contrib import admin
from django.contrib.sitemaps.views import sitemap
from django.urls import path
from django.conf.urls.i18n import i18n_patterns
from django.views.generic import RedirectView, TemplateView

from core.sitemaps import StaticViewSitemap
from core.views import BookingPlaceholderView, HomeView, StyleguideView

sitemaps = {"static": StaticViewSitemap}

urlpatterns = [
    path("admin/", admin.site.urls),
    path("sitemap.xml", sitemap, {"sitemaps": sitemaps}, name="sitemap"),
    path(
        "robots.txt",
        TemplateView.as_view(template_name="robots.txt", content_type="text/plain"),
    ),
]

# ── Легасі-URL React-версії → 302 (тимчасово; після Етапів 2/4/8 — 301 на
#    фінальні локалізовані адреси: /en/terms-and-safety/ тощо) ──
_legacy = ["terms", "privacy", "cookies", "legal", "booking", "admin"]
_legacy += [f"sup-rental-{c}" for c in ("benidorm", "altea", "villajoyosa", "calpe", "alicante")]
for _path in _legacy:
    urlpatterns.append(path(_path, RedirectView.as_view(url="/en/", permanent=False)))

urlpatterns += i18n_patterns(
    path("", HomeView.as_view(), name="home"),
    path("booking/", BookingPlaceholderView.as_view(), name="booking"),
    path("styleguide/", StyleguideView.as_view(), name="styleguide"),
    prefix_default_language=True,
)
