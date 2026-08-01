"""Глобальний контекст: SiteSettings + меню з БД (єдине джерело правди)."""
from django.conf import settings

from cms.models import MenuLink, SiteSettings


def site_settings(request):
    return {
        "site": SiteSettings.get_solo(),
        "menu_links": MenuLink.objects.filter(is_active=True, placement="navbar").order_by("order"),
        "menu_links_footer": MenuLink.objects.filter(is_active=True, placement="footer").order_by("order"),
        "site_url": settings.SITE_URL,
    }
