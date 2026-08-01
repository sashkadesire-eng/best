"""Глобальний контекст: бізнес-дані сайту (Етап 1 замінить на SiteSettings з БД)."""
from django.conf import settings


def site_settings(request):
    return {"site": settings.TUYYO_BUSINESS, "site_url": settings.SITE_URL}
