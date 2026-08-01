from django.contrib.sitemaps import Sitemap
from django.utils.translation import get_language

from cms.models import Page


class PageSitemap(Sitemap):
    i18n = True
    protocol = "https"
    changefreq = "weekly"
    priority = 0.8

    def items(self):
        return Page.objects.filter(published=True, is_homepage=False).order_by("pk")

    def location(self, obj):
        # i18n=True активує кожну мову; parler повертає slug активної мови
        return f"/{get_language()}/{obj.slug}/"

    def lastmod(self, obj):
        return obj.updated_at
