#!/usr/bin/env bash
# ============================================================================
# TUYYO.CLUB — Етап 0: Фундамент + SEO-інфраструктура + якість
# Ціль: працюючий скелет сайту (Django 5.2 LTS, SSR, i18n EN/ES, SEO,
#       base.html 1:1 з m_2.html, styleguide, CI, ADR, тести)
# Платформа: Linux Mint (Ubuntu-based)
# ============================================================================
set -euo pipefail

PROJECT_DIR="${1:-tuyyo_club}"

echo "═══════════════════════════════════════════════════════════"
echo " TUYYO.CLUB · Етап 0 · Фундамент"
echo " Директорія: $(pwd)/$PROJECT_DIR"
echo "═══════════════════════════════════════════════════════════"

# ── 01. Системні залежності ─────────────────────────────────────────────────
python3 -c 'import sys; assert sys.version_info >= (3, 10), "Потрібен Python 3.10+"' \
  || { echo "❌ Встановіть Python 3.10+: sudo apt install python3"; exit 1; }

need_pkgs=()
command -v xgettext >/dev/null 2>&1 || need_pkgs+=(gettext)
command -v curl     >/dev/null 2>&1 || need_pkgs+=(curl)
command -v git      >/dev/null 2>&1 || need_pkgs+=(git)
python3 -c "import venv" 2>/dev/null || need_pkgs+=(python3-venv python3-dev)

if [ ${#need_pkgs[@]} -gt 0 ]; then
  echo "📦 Встановлення системних пакетів: ${need_pkgs[*]} (sudo запитає пароль)"
  sudo apt update && sudo apt install -y "${need_pkgs[@]}" \
    || { echo "❌ Виконайте вручну: sudo apt install ${need_pkgs[*]}"; exit 1; }
fi

# ── 02. Директорія проєкту + venv ───────────────────────────────────────────
mkdir -p "$PROJECT_DIR" && cd "$PROJECT_DIR"
git init -q 2>/dev/null || true

python3 -m venv venv
# shellcheck disable=SC1091
source venv/bin/activate
pip install --upgrade pip -q

# ── 03. Залежності Python ───────────────────────────────────────────────────
cat > requirements.txt << 'EOF'
# ── Core ──
Django>=5.2,<5.3
django-parler>=2.3
django-environ>=0.11
whitenoise>=6.7
# ── Quality (dev) ──
pytest>=8.0
pytest-django>=4.8
ruff>=0.6
EOF

cat > requirements-prod.txt << 'EOF'
-r requirements.txt
dj-database-url>=2.2
psycopg[binary]>=3.2
sentry-sdk>=2.0
gunicorn>=22.0
EOF

pip install -r requirements.txt -q

# ── 04. Django-проєкт і застосунки (канонічні команди) ─────────────────────
django-admin startproject config .

python manage.py startapp core
python manage.py startapp cms
python manage.py startapp catalog
python manage.py startapp guides
python manage.py startapp content
python manage.py startapp bookings
python manage.py startapp dashboard

mkdir -p config/settings
rm config/settings.py

mkdir -p templates/core templates/partials static/css static/images locale docs/adr \
         scripts bin data/seed media .github/workflows

# ── 05. Налаштування: split-settings (base / dev / prod) ───────────────────
cat > config/settings/__init__.py << 'EOF'
EOF

cat > config/settings/base.py << 'EOF'
"""Базові налаштування TUYYO.CLUB (спільні для dev/prod)."""
from pathlib import Path

import environ
from django.utils.translation import gettext_lazy as _

BASE_DIR = Path(__file__).resolve().parent.parent.parent

env = environ.Env()
environ.Env.read_env(BASE_DIR / ".env")  # безпечно, якщо файла немає

SECRET_KEY = env("SECRET_KEY", default="dev-insecure-key-override-in-env")
DEBUG = env.bool("DEBUG", default=False)
ALLOWED_HOSTS = env.list("ALLOWED_HOSTS", default=["*"])
SITE_URL = env("SITE_URL", default="https://tuyyo.club")

INSTALLED_APPS = [
    "django.contrib.admin",
    "django.contrib.auth",
    "django.contrib.contenttypes",
    "django.contrib.sessions",
    "django.contrib.messages",
    "django.contrib.staticfiles",
    "django.contrib.sitemaps",
    # ── third-party ──
    "parler",
    # ── проєкт ──
    "core",
    "cms",
    "catalog",
    "guides",
    "content",
    "bookings",
    "dashboard",
]

MIDDLEWARE = [
    "django.middleware.security.SecurityMiddleware",
    "whitenoise.middleware.WhiteNoiseMiddleware",
    "django.contrib.sessions.middleware.SessionMiddleware",
    "django.middleware.locale.LocaleMiddleware",
    "django.middleware.common.CommonMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.contrib.auth.middleware.AuthenticationMiddleware",
    "django.contrib.messages.middleware.MessageMiddleware",
    "django.middleware.clickjacking.XFrameOptionsMiddleware",
]

ROOT_URLCONF = "config.urls"
WSGI_APPLICATION = "config.wsgi.application"

TEMPLATES = [
    {
        "BACKEND": "django.template.backends.django.DjangoTemplates",
        "DIRS": [BASE_DIR / "templates"],
        "APP_DIRS": True,
        "OPTIONS": {
            "context_processors": [
                "django.template.context_processors.debug",
                "django.template.context_processors.request",
                "django.contrib.auth.context_processors.auth",
                "django.contrib.messages.context_processors.messages",
                "core.context_processors.site_settings",
            ],
        },
    },
]

DATABASES = {
    "default": env.db_url("DATABASE_URL", default=f"sqlite:///{BASE_DIR / 'db.sqlite3'}")
}

AUTH_PASSWORD_VALIDATORS = [
    {"NAME": "django.contrib.auth.password_validation.UserAttributeSimilarityValidator"},
    {"NAME": "django.contrib.auth.password_validation.MinimumLengthValidator"},
    {"NAME": "django.contrib.auth.password_validation.CommonPasswordValidator"},
    {"NAME": "django.contrib.auth.password_validation.NumericPasswordValidator"},
]

# ── i18n / L10n ──────────────────────────────────────────────────────────────
LANGUAGE_CODE = "en"
LANGUAGES = [
    ("en", "English"),
    ("es", "Español"),
]
LOCALE_PATHS = [BASE_DIR / "locale"]
TIME_ZONE = "Europe/Madrid"
USE_I18N = True
USE_TZ = True

# ── django-parler (переклади моделей; моделі з'являться в Етапі 1) ──────────
PARLER_LANGUAGES = {
    None: ({"code": "en"}, {"code": "es"}),
    "default": {"fallbacks": ["en"], "hide_untranslated": False},
}
PARLER_DEFAULT_LANGUAGE_CODE = "en"

# ── Static / Media ──────────────────────────────────────────────────────────
STATIC_URL = "static/"
STATICFILES_DIRS = [BASE_DIR / "static"]
STATIC_ROOT = BASE_DIR / "staticfiles"
MEDIA_URL = "media/"
MEDIA_ROOT = BASE_DIR / "media"

DEFAULT_AUTO_FIELD = "django.db.models.BigAutoField"

EMAIL_BACKEND = env("EMAIL_BACKEND", default="django.core.mail.backends.console.EmailBackend")

# ── Бізнес-дані (тимчасово; в Етапі 1 переїдуть у модель SiteSettings) ─────
# Канонічна адреса бази — Finestrat (за m_2.html; рішення v1).
TUYYO_BUSINESS = {
    "name": "TUYYO.CLUB",
    "tagline": _("Costa Blanca SUP Rental"),
    "company_legal_name": "TUYYO GROUP S.L.",
    "cif": "B-03918234",
    "licencia": "VA-TUR-2024/9182",
    "seguro_rc": "AXA № 78192834-RC (€600,000)",
    "phone": "+34 623 575 015",
    "whatsapp_number": "34623575015",
    "bizum_phone": "+34 623 575 015",
    "email": "tuyyogroup@gmail.com",
    "address": "Av. Miguel Hernández 25, Finestrat",
    "maps_url": "https://maps.google.com/?q=Av.+Miguel+Hern%C3%A1ndez,+25,+03509+Finestrat",
    "deposit_amount": 150,
    "delivery_fee": 20,
    "default_meta_title": _("TUYYO.CLUB — Costa Blanca SUP Rental & Beach Delivery"),
    "default_meta_description": _(
        "SUP paddleboard rental with direct beach & hotel delivery in Benidorm, "
        "Altea, Villajoyosa, Calpe & Alicante. From €35. No credit card required."
    ),
    "copyright": "© 2026 TUYYO GROUP S.L.",
    # Локації (в Етапі 2 — з БД; тут — для навігації та футера)
    "locations": [
        {"slug": "benidorm", "name": "Benidorm", "beaches_count": 4},
        {"slug": "altea", "name": "Altea", "beaches_count": 4},
        {"slug": "villajoyosa", "name": "Villajoyosa", "beaches_count": 4},
        {"slug": "calpe", "name": "Calpe", "beaches_count": 4},
        {"slug": "alicante", "name": "Alicante", "beaches_count": 4},
    ],
}
EOF

cat > config/settings/dev.py << 'EOF'
"""Налаштування розробки."""
from .base import *  # noqa: F403

DEBUG = True
SECRET_KEY = "dev-insecure-key-do-not-use-in-production"
ALLOWED_HOSTS = ["*"]
EMAIL_BACKEND = "django.core.mail.backends.console.EmailBackend"
INTERNAL_IPS = ["127.0.0.1"]
EOF

cat > config/settings/prod.py << 'EOF'
"""Продакшн-налаштування (Docker/gunicorn; Етап 9)."""
from .base import *  # noqa: F403

DEBUG = False
SECRET_KEY = env("SECRET_KEY")  # noqa: F405
ALLOWED_HOSTS = env.list("ALLOWED_HOSTS", default=[])  # noqa: F405
CSRF_COOKIE_SECURE = True
SESSION_COOKIE_SECURE = True
SECURE_SSL_REDIRECT = env.bool("SECURE_SSL_REDIRECT", default=True)  # noqa: F405
SECURE_HSTS_SECONDS = 31536000
SECURE_HSTS_INCLUDE_SUBDOMAINS = True
SECURE_HSTS_PRELOAD = True
X_FRAME_OPTIONS = "DENY"

STORAGES = {
    "default": {"BACKEND": "django.core.files.storage.FileSystemStorage"},
    "staticfiles": {"BACKEND": "whitenoise.storage.CompressedStaticFilesStorage"},
}

# Sentry (опційно)
SENTRY_DSN = env("SENTRY_DSN", default="")  # noqa: F405
if SENTRY_DSN:
    try:
        import sentry_sdk

        sentry_sdk.init(dsn=SENTRY_DSN, traces_sample_rate=0.1, send_default_pii=False)
    except ImportError:
        pass
EOF

# manage.py / wsgi / asgi — правильні посилання на settings-пакет
cat > manage.py << 'EOF'
#!/usr/bin/env python
import os
import sys


def main():
    os.environ.setdefault("DJANGO_SETTINGS_MODULE", "config.settings.dev")
    try:
        from django.core.management import execute_from_command_line
    except ImportError as exc:
        raise ImportError(
            "Django не встановлений. Активуйте venv: source venv/bin/activate"
        ) from exc
    execute_from_command_line(sys.argv)


if __name__ == "__main__":
    main()
EOF
chmod +x manage.py

cat > config/wsgi.py << 'EOF'
import os

from django.core.wsgi import get_wsgi_application

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "config.settings.prod")
application = get_wsgi_application()
EOF

cat > config/asgi.py << 'EOF'
import os

from django.core.asgi import get_asgi_application

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "config.settings.prod")
application = get_asgi_application()
EOF

# ── 06. .env / .gitignore / pyproject / pytest ─────────────────────────────
cat > .env.example << 'EOF'
DJANGO_SETTINGS_MODULE=config.settings.dev
SECRET_KEY=згенеруйте-ключ-64-символи
DEBUG=True
ALLOWED_HOSTS=localhost,127.0.0.1
SITE_URL=https://tuyyo.club
DATABASE_URL=sqlite:///db.sqlite3
# Продакшн (Етап 6/9):
SENTRY_DSN=
TELEGRAM_BOT_TOKEN=
TELEGRAM_CHAT_ID=
PLAUSIBLE_DOMAIN=tuyyo.club
EOF
cp .env.example .env

cat > .gitignore << 'EOF'
venv/
__pycache__/
*.pyc
db.sqlite3
.env
staticfiles/
media/
bin/tailwindcss
.pytest_cache/
.ruff_cache/
*.mo
node_modules/
dist/
.DS_Store
EOF

cat > pyproject.toml << 'EOF'
[project]
name = "tuyyo-club"
version = "0.1.0"
description = "TUYYO.CLUB — Costa Blanca SUP Rental (Django SSR, i18n EN/ES)"
requires-python = ">=3.10"

[tool.ruff]
line-length = 100
target-version = "py310"
extend-exclude = ["*/migrations/*"]

[tool.ruff.lint]
select = ["E", "F", "I", "UP", "B", "DJ"]
ignore = ["E501"]
EOF

cat > pytest.ini << 'EOF'
[pytest]
DJANGO_SETTINGS_MODULE = config.settings.dev
python_files = tests.py test_*.py
addopts = -q
EOF

# ── 07. core: context processor, views, sitemaps ───────────────────────────
cat > core/context_processors.py << 'EOF'
"""Глобальний контекст: бізнес-дані сайту (Етап 1 замінить на SiteSettings з БД)."""
from django.conf import settings


def site_settings(request):
    return {"site": settings.TUYYO_BUSINESS, "site_url": settings.SITE_URL}
EOF

cat > core/views.py << 'EOF'
from django.conf import settings
from django.http import Http404
from django.views.generic import TemplateView


class HomeView(TemplateView):
    template_name = "core/home.html"


class BookingPlaceholderView(TemplateView):
    """Заглушка; повний візард — Етап 5."""

    template_name = "core/booking_placeholder.html"


class StyleguideView(TemplateView):
    """Каталог компонентів (патерн HackSoft django-styleguide). Лише dev/staff."""

    template_name = "core/styleguide.html"

    def dispatch(self, request, *args, **kwargs):
        if not (settings.DEBUG or request.user.is_staff):
            raise Http404
        return super().dispatch(request, *args, **kwargs)
EOF

cat > core/sitemaps.py << 'EOF'
from django.contrib.sitemaps import Sitemap
from django.urls import reverse


class StaticViewSitemap(Sitemap):
    """Публічні сторінки. i18n=True → alternates xhtml:link для EN/ES у sitemap."""

    i18n = True
    protocol = "https"
    changefreq = "weekly"
    priority = 1.0

    def items(self):
        return ["home"]

    def location(self, item):
        return reverse(item)
EOF

# ── 08. core: template tags — іконки (lucide 1:1) та SEO ───────────────────
mkdir -p core/templatetags
touch core/templatetags/__init__.py

cat > core/templatetags/icons.py << 'EOF'
"""Іконки lucide як inline-SVG (нуль JS-залежностей). {% icon 'waves' 'w-5 h-5' %}"""
from django import template
from django.utils.safestring import mark_safe

register = template.Library()

ICONS = {
    "waves": '<path d="M2 6c.6.5 1.2 1 2.5 1C7 7 7 5 9.5 5c2.6 0 2.4 2 5 2 2.5 0 2.5-2 5-2 1.3 0 1.9.5 2.5 1"/><path d="M2 12c.6.5 1.2 1 2.5 1 2.5 0 2.5-2 5-2 2.6 0 2.4 2 5 2 2.5 0 2.5-2 5-2 1.3 0 1.9.5 2.5 1"/><path d="M2 18c.6.5 1.2 1 2.5 1 2.5 0 2.5-2 5-2 2.6 0 2.4 2 5 2 2.5 0 2.5-2 5-2 1.3 0 1.9.5 2.5 1"/>',
    "map-pin": '<path d="M20 10c0 6-8 12-8 12s-8-6-8-12a8 8 0 0 1 16 0Z"/><circle cx="12" cy="10" r="3"/>',
    "sparkles": '<path d="m12 3-1.9 5.8a2 2 0 0 1-1.3 1.3L3 12l5.8 1.9a2 2 0 0 1 1.3 1.3L12 21l1.9-5.8a2 2 0 0 1 1.3-1.3L21 12l-5.8-1.9a2 2 0 0 1-1.3-1.3Z"/>',
    "image": '<rect width="18" height="18" x="3" y="3" rx="2" ry="2"/><circle cx="9" cy="9" r="2"/><path d="m21 15-3.1-3.1a2 2 0 0 0-2.8 0L6 21"/>',
    "file-text": '<path d="M15 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V7Z"/><path d="M14 2v4a2 2 0 0 0 2 2h4"/><path d="M10 9H8"/><path d="M16 13H8"/><path d="M16 17H8"/>',
    "help-circle": '<circle cx="12" cy="12" r="10"/><path d="M9.1 9a3 3 0 0 1 5.8 1c0 2-3 3-3 3"/><path d="M12 17h.01"/>',
    "sun": '<circle cx="12" cy="12" r="4"/><path d="M12 2v2"/><path d="M12 20v2"/><path d="m4.9 4.9 1.4 1.4"/><path d="m17.7 17.7 1.4 1.4"/><path d="M2 12h2"/><path d="M20 12h2"/><path d="m6.3 17.7-1.4 1.4"/><path d="m19.1 4.9-1.4 1.4"/>',
    "moon": '<path d="M12 3a6 6 0 0 0 9 9 9 9 0 1 1-9-9Z"/>',
    "menu": '<line x1="4" x2="20" y1="12" y2="12"/><line x1="4" x2="20" y1="6" y2="6"/><line x1="4" x2="20" y1="18" y2="18"/>',
    "x": '<path d="M18 6 6 18"/><path d="m6 6 12 12"/>',
    "smartphone": '<rect width="14" height="20" x="5" y="2" rx="2" ry="2"/><path d="M12 18h.01"/>',
    "shield-check": '<path d="M20 13c0 5-3.5 7.5-7.7 9a1 1 0 0 1-.6 0C7.5 20.5 4 18 4 13V6a1 1 0 0 1 1-1c2 0 4.5-1.2 6.2-2.7a1.2 1.2 0 0 1 1.6 0C14.5 3.8 17 5 19 5a1 1 0 0 1 1 1Z"/><path d="m9 12 2 2 4-4"/>',
    "phone": '<path d="M22 16.9v3a2 2 0 0 1-2.2 2 19.8 19.8 0 0 1-8.6-3 19.5 19.5 0 0 1-6-6 19.8 19.8 0 0 1-3-8.7A2 2 0 0 1 4.1 2h3a2 2 0 0 1 2 1.7c.1 1 .4 1.9.7 2.8a2 2 0 0 1-.4 2.1L8.1 9.9a16 16 0 0 0 6 6l1.3-1.3a2 2 0 0 1 2.1-.4c.9.3 1.8.6 2.8.7a2 2 0 0 1 1.7 2Z"/>',
    "mail": '<rect width="20" height="16" x="2" y="4" rx="2"/><path d="m22 7-9 5.7a2 2 0 0 1-2 0L2 7"/>',
    "heart": '<path d="M19 14c1.5-1.5 3-3.2 3-5.5A5.5 5.5 0 0 0 16.5 3c-1.8 0-3 .5-4.5 2-1.5-1.5-2.7-2-4.5-2A5.5 5.5 0 0 0 2 8.5c0 2.3 1.5 4 3 5.5l7 7Z"/>',
    "cookie": '<path d="M12 2a10 10 0 1 0 10 10 4 4 0 0 1-5-5 4 4 0 0 1-5-5"/><path d="M8.5 8.5v.01"/><path d="M16 15.5v.01"/><path d="M12 12v.01"/><path d="M11 17v.01"/><path d="M7 14v.01"/>',
    "chevron-down": '<path d="m6 9 6 6 6-6"/>',
    "whatsapp": '<path d="M.057 24l1.687-6.163c-1.041-1.804-1.588-3.849-1.587-5.946.003-6.556 5.338-11.891 11.893-11.891 3.181.001 6.167 1.24 8.413 3.488 2.245 2.248 3.481 5.236 3.48 8.414-.003 6.557-5.338 11.892-11.893 11.892-1.99-.001-3.951-.5-5.688-1.448l-6.305 1.654zm6.597-3.807c1.676.995 3.276 1.591 5.392 1.592 5.448 0 9.886-4.434 9.889-9.885.002-5.462-4.415-9.89-9.881-9.892-5.452 0-9.887 4.434-9.889 9.884-.001 2.225.651 3.891 1.746 5.634l-.999 3.648 3.742-.981zm11.387-5.464c-.074-.124-.272-.198-.57-.347-.297-.149-1.758-.868-2.031-.967-.272-.099-.47-.149-.669.149-.198.297-.768.967-.941 1.165-.173.198-.347.223-.644.074-.297-.149-1.255-.462-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.297-.347.446-.521.151-.172.2-.296.3-.495.099-.198.05-.372-.025-.521-.075-.148-.669-1.611-.916-2.206-.242-.579-.487-.501-.669-.51l-.57-.01c-.198 0-.52.074-.792.372s-1.04 1.016-1.04 2.479 1.065 2.876 1.213 3.074c.149.198 2.095 3.2 5.076 4.487.709.306 1.263.489 1.694.626.712.226 1.36.194 1.872.118.571-.085 1.758-.719 2.006-1.413.248-.695.248-1.29.173-1.414z"/>',
}


@register.simple_tag
def icon(name, css="w-5 h-5"):
    inner = ICONS.get(name, "")
    if name == "whatsapp":
        return mark_safe(
            f'<svg class="{css}" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">{inner}</svg>'
        )
    return mark_safe(
        f'<svg class="{css}" viewBox="0 0 24 24" fill="none" stroke="currentColor" '
        f'stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">{inner}</svg>'
    )
EOF

cat > core/templatetags/seo.py << 'EOF'
"""SEO-теги: canonical, hreflang alternates (EN/ES + x-default)."""
from django import template
from django.conf import settings
from django.urls import translate_url
from django.utils.safestring import mark_safe

register = template.Library()


@register.simple_tag(takes_context=True)
def canonical_url(context):
    request = context["request"]
    return request.build_absolute_uri(request.path)


@register.simple_tag(takes_context=True)
def canonical(context):
    return mark_safe(f'<link rel="canonical" href="{canonical_url(context)}" />')


@register.simple_tag(takes_context=True)
def render_alternates(context):
    """hreflang: self-referencing, двонаправлений, x-default → EN."""
    request = context["request"]
    path = request.path
    lines = []
    for code, _name in settings.LANGUAGES:
        url = request.build_absolute_uri(translate_url(path, code))
        lines.append(f'<link rel="alternate" hreflang="{code}" href="{url}" />')
    default_url = request.build_absolute_uri(translate_url(path, "en"))
    lines.append(f'<link rel="alternate" hreflang="x-default" href="{default_url}" />')
    return mark_safe("\n  ".join(lines))
EOF

# ── 09. Шаблони: base + партишали (1:1 з m_2.html / Navbar / Footer) ───────
cat > templates/partials/_theme_script.html << 'EOF'
<script>
(function () {
  try {
    var t = localStorage.getItem('tuyyo_theme');
    if (!t) t = window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
    document.documentElement.dataset.theme = t;
  } catch (e) { document.documentElement.dataset.theme = 'light'; }
})();
</script>
EOF

cat > templates/partials/_meta.html << 'EOF'
{% load seo %}
<title>{% firstof meta_title site.default_meta_title %}</title>
<meta name="description" content="{% firstof meta_description site.default_meta_description %}">
{% canonical %}
{% render_alternates %}
<meta property="og:type" content="website">
<meta property="og:site_name" content="{{ site.name }}">
<meta property="og:title" content="{% firstof meta_title site.default_meta_title %}">
<meta property="og:description" content="{% firstof meta_description site.default_meta_description %}">
{% canonical_url as og_url %}<meta property="og:url" content="{{ og_url }}">
<meta property="og:locale" content="{{ LANGUAGE_CODE }}">
<meta name="twitter:card" content="summary_large_image">
<meta name="theme-color" content="#0284c7">
EOF

cat > templates/partials/_navbar.html << 'EOF'
{% load i18n icons %}
<header class="sticky top-0 z-50 border-b bg-white/90 text-slate-800 shadow-sm backdrop-blur-md transition-colors duration-200 dark:border-slate-800 dark:bg-slate-900/90 dark:text-white">
  <div class="mx-auto flex h-16 max-w-7xl items-center justify-between px-4 sm:px-6 lg:px-8">
    {# Логотип #}
    <a href="{% url 'home' %}" class="group flex items-center gap-2.5 text-left focus:outline-none">
      <div class="h-10 w-10 rounded-xl bg-gradient-to-tr from-sky-500 to-teal-400 p-0.5 shadow-md shadow-sky-500/20 transition-transform group-hover:scale-105">
        <div class="flex h-full w-full items-center justify-center rounded-[10px] bg-sky-50 dark:bg-slate-950">
          {% icon 'waves' 'w-5 h-5 text-sky-600' %}
        </div>
      </div>
      <div>
        <span class="text-xl font-black tracking-tight text-slate-900 dark:bg-gradient-to-r dark:from-white dark:via-sky-100 dark:to-sky-300 dark:bg-clip-text dark:text-transparent">{{ site.name }}</span>
        <span class="block text-[10px] font-extrabold uppercase tracking-wider text-sky-600">Costa Blanca SUP</span>
      </div>
    </a>

    {# Desktop-навігація #}
    <nav class="hidden items-center gap-6 text-sm font-semibold lg:flex">
      <div class="group relative">
        <button class="flex items-center gap-1 py-2 transition-colors hover:text-sky-600 dark:text-slate-300 dark:hover:text-sky-400">
          {% icon 'map-pin' 'w-3.5 h-3.5 text-sky-500' %}
          {% trans "Locations" %}
        </button>
        <div class="absolute left-0 top-full z-50 hidden w-56 rounded-2xl border border-slate-200 bg-white p-2 shadow-xl transition-all group-hover:block dark:border-slate-800 dark:bg-slate-900">
          {% for loc in site.locations %}
          <a href="/{{ LANGUAGE_CODE }}/sup-rental-{{ loc.slug }}/"
             class="flex w-full items-center justify-between rounded-xl px-3 py-2 text-left text-xs font-semibold text-slate-700 transition-colors hover:bg-sky-50 hover:text-sky-700 dark:text-slate-300 dark:hover:bg-slate-800 dark:hover:text-sky-400">
            <span>{{ loc.name }}</span>
            <span class="text-[10px] text-slate-400">{{ loc.beaches_count }} {% trans "beaches" %}</span>
          </a>
          {% endfor %}
        </div>
      </div>
      <a href="/#tariffs" class="flex items-center gap-1 transition-colors hover:text-sky-600 dark:text-slate-300 dark:hover:text-sky-400">{% icon 'sparkles' 'w-3.5 h-3.5 text-sky-500' %}<span>{% trans "Tariffs" %}</span></a>
      <a href="/#gallery" class="flex items-center gap-1 transition-colors hover:text-sky-600 dark:text-slate-300 dark:hover:text-sky-400">{% icon 'image' 'w-3.5 h-3.5 text-teal-500' %}<span>{% trans "Gallery" %}</span></a>
      <a href="/#guide" class="flex items-center gap-1 transition-colors hover:text-sky-600 dark:text-slate-300 dark:hover:text-sky-400">{% icon 'file-text' 'w-3.5 h-3.5 text-amber-500' %}<span>{% trans "SUP Guide" %}</span></a>
      <a href="/#faq" class="flex items-center gap-1 transition-colors hover:text-sky-600 dark:text-slate-300 dark:hover:text-sky-400">{% icon 'help-circle' 'w-3.5 h-3.5 text-sky-500' %}<span>{% trans "FAQ" %}</span></a>
      <a href="/{{ LANGUAGE_CODE }}/terms-and-safety/" class="transition-colors hover:text-sky-600 dark:text-slate-300 dark:hover:text-sky-400">{% trans "Terms & Safety" %}</a>
    </nav>

    {# Контроли: тема / мова / CTA #}
    <div class="hidden items-center gap-3 sm:flex">
      <button data-theme-toggle type="button" aria-label="{% trans 'Toggle theme' %}"
              class="rounded-xl border border-slate-200 bg-slate-100 p-2 transition-all hover:bg-slate-200 dark:border-slate-700 dark:bg-slate-800 dark:hover:bg-slate-700">
        <span class="hidden dark:inline">{% icon 'sun' 'w-4 h-4 text-amber-400' %}</span>
        <span class="dark:hidden">{% icon 'moon' 'w-4 h-4 text-slate-700' %}</span>
      </button>
      <div class="flex items-center rounded-xl border border-slate-200 bg-slate-100 p-0.5 text-xs dark:border-slate-700 dark:bg-slate-800">
        {% get_available_languages as LANGS %}
        {% for code, name in LANGS %}
          {% translate_url code as lang_url %}
          <a href="{{ lang_url }}"
             class="rounded-lg px-2.5 py-1 font-bold transition-all {% if code == LANGUAGE_CODE %}bg-sky-500 text-white shadow-sm{% else %}text-slate-600 hover:text-slate-900 dark:text-slate-400 dark:hover:text-slate-200{% endif %}">{{ code|upper }}</a>
        {% endfor %}
      </div>
      <a href="{% url 'booking' %}"
         class="flex items-center gap-1.5 rounded-xl bg-gradient-to-r from-sky-500 to-teal-500 px-4 py-2 text-sm font-extrabold text-white shadow-md shadow-sky-500/20 transition-all hover:from-sky-600 hover:to-teal-600 active:scale-95">
        {% icon 'sparkles' 'w-4 h-4 fill-white' %}
        {% trans "Book SUP Now" %}
      </a>
    </div>

    {# Мобільні контроли #}
    <div class="flex items-center gap-2 sm:hidden">
      <button data-theme-toggle type="button" aria-label="{% trans 'Toggle theme' %}"
              class="rounded-lg border border-slate-200 bg-slate-100 p-2 text-xs dark:border-slate-700 dark:bg-slate-800">
        <span class="hidden dark:inline">{% icon 'sun' 'w-4 h-4 text-amber-400' %}</span>
        <span class="dark:hidden">{% icon 'moon' 'w-4 h-4 text-slate-700' %}</span>
      </button>
      {% get_available_languages as LANGS_M %}
      {% for code, name in LANGS_M %}{% if code != LANGUAGE_CODE %}{% translate_url code as alt_url %}
      <a href="{{ alt_url }}" class="rounded-lg border border-slate-200 bg-slate-100 px-2.5 py-1 text-xs font-bold uppercase text-sky-600 dark:border-slate-700 dark:bg-slate-800 dark:text-sky-400">{{ code }}</a>
      {% endif %}{% endfor %}
      <button data-menu-toggle type="button" aria-label="{% trans 'Toggle menu' %}" class="p-2 text-slate-800 dark:text-slate-300">
        <span data-menu-open-icon>{% icon 'menu' 'w-6 h-6' %}</span>
        <span data-menu-close-icon class="hidden">{% icon 'x' 'w-6 h-6' %}</span>
      </button>
    </div>
  </div>

  {# Мобільне меню #}
  <div data-mobile-menu class="hidden border-b border-slate-200 bg-white px-4 pb-6 pt-3 text-slate-800 dark:border-slate-800 dark:bg-slate-900 dark:text-white sm:hidden">
    <div class="py-2">
      <span class="mb-2 block text-xs font-bold uppercase tracking-wider text-sky-600">{% trans "Locations" %}</span>
      <div class="grid grid-cols-2 gap-2">
        {% for loc in site.locations %}
        <a href="/{{ LANGUAGE_CODE }}/sup-rental-{{ loc.slug }}/"
           class="flex items-center gap-1.5 rounded-lg bg-slate-100 px-3 py-2 text-left text-xs font-semibold text-slate-800 hover:bg-slate-200 dark:bg-slate-800 dark:text-slate-200 dark:hover:bg-slate-700">
          {% icon 'map-pin' 'w-3.5 h-3.5 shrink-0 text-sky-500' %}<span>{{ loc.name }}</span>
        </a>
        {% endfor %}
      </div>
    </div>
    <a href="/#tariffs" class="flex w-full items-center gap-2 py-2 text-left text-sm font-semibold hover:text-sky-600">{% icon 'sparkles' 'w-4 h-4 text-sky-500' %}{% trans "Tariffs" %}</a>
    <a href="/#guide" class="flex w-full items-center gap-2 py-2 text-left text-sm font-semibold hover:text-sky-600">{% icon 'file-text' 'w-4 h-4 text-amber-500' %}{% trans "SUP Guide" %}</a>
    <a href="/#faq" class="flex w-full items-center gap-2 py-2 text-left text-sm font-semibold hover:text-sky-600">{% icon 'help-circle' 'w-4 h-4 text-sky-500' %}{% trans "FAQ" %}</a>
    <a href="https://wa.me/{{ site.whatsapp_number }}" target="_blank" rel="noopener noreferrer"
       class="mt-1 flex w-full items-center justify-center gap-2 rounded-xl bg-emerald-600 py-2.5 text-center text-xs font-extrabold text-white shadow-md">
      {% icon 'smartphone' 'w-4 h-4' %}{% trans "WhatsApp Quick Order" %}
    </a>
    <a href="{% url 'booking' %}" class="mt-2 block w-full rounded-xl bg-gradient-to-r from-sky-500 to-teal-500 py-3 text-center text-base font-extrabold text-white shadow-md">{% trans "Book SUP Now" %}</a>
  </div>
</header>
EOF

cat > templates/partials/_footer.html << 'EOF'
{% load i18n icons %}
<footer class="border-t border-slate-800 bg-slate-950 text-sm text-slate-400">
  <div class="mx-auto max-w-7xl px-4 py-12 sm:px-6 lg:px-8 lg:py-16">
    <div class="grid grid-cols-1 gap-8 md:grid-cols-2 lg:grid-cols-5 lg:gap-12">
      {# Бренд + юридичний блок (1:1 m_2.html) #}
      <div class="space-y-4 lg:col-span-2">
        <div class="flex items-center gap-3">
          <div class="h-10 w-10 rounded-xl bg-gradient-to-tr from-sky-500 to-teal-400 p-0.5">
            <div class="flex h-full w-full items-center justify-center rounded-[10px] bg-slate-950">
              {% icon 'waves' 'w-5 h-5 text-sky-400' %}
            </div>
          </div>
          <div>
            <span class="text-xl font-bold tracking-tight text-white">{{ site.name }}</span>
            <span class="block text-[10px] font-semibold uppercase tracking-widest text-sky-400">Costa Blanca SUP Rental</span>
          </div>
        </div>
        <p class="max-w-sm text-xs leading-relaxed text-slate-400">
          {% blocktrans %}Mobile Stand-Up Paddleboard rental service with direct beach and hotel delivery across Benidorm, Altea, Villajoyosa, Calpe, and Alicante.{% endblocktrans %}
        </p>
        <div class="space-y-1.5 border-l-2 border-sky-500/40 pl-3 text-xs text-slate-400">
          <p><strong class="text-slate-200">{% trans "Legal Entity:" %}</strong> {{ site.company_legal_name }}</p>
          <p><strong class="text-slate-200">{% trans "CIF / NIF:" %}</strong> {{ site.cif }}</p>
          <p><strong class="text-slate-200">{% trans "Tourism License:" %}</strong> {{ site.licencia }}</p>
          <p><strong class="text-slate-200">{% trans "RC Insurance:" %}</strong> {{ site.seguro_rc }}</p>
        </div>
      </div>

      {# Локації #}
      <div class="space-y-3">
        <h3 class="flex items-center gap-1.5 text-xs font-bold uppercase tracking-wider text-slate-200">
          {% icon 'map-pin' 'w-3.5 h-3.5 text-sky-400' %}{% trans "Locations" %}
        </h3>
        <ul class="space-y-2 text-xs">
          {% for loc in site.locations %}
          <li><a href="/{{ LANGUAGE_CODE }}/sup-rental-{{ loc.slug }}/" class="transition-colors hover:text-sky-400">{% blocktrans with name=loc.name %}SUP Rental {{ name }}{% endblocktrans %}</a></li>
          {% endfor %}
        </ul>
      </div>

      {# Legal #}
      <div class="space-y-3">
        <h3 class="flex items-center gap-1.5 text-xs font-bold uppercase tracking-wider text-slate-200">
          {% icon 'shield-check' 'w-3.5 h-3.5 text-teal-400' %}{% trans "Legal Notice" %}
        </h3>
        <ul class="space-y-2 text-xs">
          <li><a href="/{{ LANGUAGE_CODE }}/terms-and-safety/" class="transition-colors hover:text-sky-400">{% trans "Terms & Conditions" %}</a></li>
          <li><a href="/{{ LANGUAGE_CODE }}/privacy-policy/" class="transition-colors hover:text-sky-400">{% trans "Privacy Policy" %}</a></li>
          <li><a href="/{{ LANGUAGE_CODE }}/cookie-policy/" class="transition-colors hover:text-sky-400">{% trans "Cookie Policy" %}</a></li>
          <li><a href="/{{ LANGUAGE_CODE }}/legal-notice/" class="transition-colors hover:text-sky-400">{% trans "Legal Notice" %}</a></li>
        </ul>
      </div>

      {# Контакти + оплата #}
      <div class="space-y-3">
        <h3 class="text-xs font-bold uppercase tracking-wider text-slate-200">{% trans "Contact & Payment" %}</h3>
        <div class="space-y-2 text-xs">
          <a href="https://wa.me/{{ site.whatsapp_number }}" target="_blank" rel="noopener noreferrer" class="flex items-center gap-2 text-slate-300 hover:text-sky-400">{% icon 'phone' 'w-3.5 h-3.5 text-emerald-400' %}{{ site.phone }}</a>
          <a href="mailto:{{ site.email }}" class="flex items-center gap-2 text-slate-300 hover:text-sky-400">{% icon 'mail' 'w-3.5 h-3.5 text-sky-400' %}{{ site.email }}</a>
          <a href="{{ site.maps_url }}" target="_blank" rel="noopener noreferrer" class="flex items-center gap-2 text-slate-300 hover:text-sky-400">{% icon 'map-pin' 'w-3.5 h-3.5 shrink-0 text-rose-400' %}{{ site.address }}</a>
          <div class="flex items-center gap-2 pt-2">
            <span class="rounded border border-slate-800 bg-slate-900 px-2 py-1 text-[10px] font-bold text-sky-400">Bizum</span>
            <span class="rounded border border-slate-800 bg-slate-900 px-2 py-1 text-[10px] font-bold text-emerald-400">Cash on Delivery</span>
          </div>
        </div>
      </div>
    </div>

    {# Нижній бар #}
    <div class="mt-12 flex flex-col items-center justify-between gap-4 border-t border-slate-900 pt-6 text-xs text-slate-500 sm:flex-row">
      <p>{{ site.copyright }} — {% trans "All rights reserved." %}</p>
      <div class="flex items-center gap-1 text-[11px]">
        <span>{% trans "Made with" %}</span>
        {% icon 'heart' 'w-3 h-3 text-red-500 fill-red-500' %}
        <span>{% trans "for SUP lovers along Costa Blanca" %}</span>
      </div>
    </div>
  </div>
</footer>
EOF

cat > templates/partials/_cookie_banner.html << 'EOF'
{% load i18n icons %}
<div data-cookie-banner class="fixed inset-x-0 bottom-0 z-50 hidden border-t border-slate-800 bg-slate-900 p-4 text-xs text-slate-300 shadow-2xl">
  <div class="mx-auto flex max-w-7xl flex-col items-center justify-between gap-4 sm:flex-row">
    <div class="flex items-center gap-3">
      {% icon 'cookie' 'w-6 h-6 shrink-0 text-amber-400' %}
      <p class="leading-relaxed">
        {% blocktrans %}We use strictly necessary cookies to process your SUP booking and ensure smooth PWA functionality. Under LOPDGDD / GDPR laws, no tracking cookies are stored without consent.{% endblocktrans %}
        <a href="/{{ LANGUAGE_CODE }}/cookie-policy/" class="font-semibold text-sky-400 hover:underline">{% trans "Read Cookie Policy" %}</a>
      </p>
    </div>
    <button data-cookie-accept type="button"
            class="flex shrink-0 items-center gap-1 rounded-xl bg-sky-500 px-4 py-2 text-xs font-bold text-slate-950 transition-colors hover:bg-sky-400">
      {% icon 'shield-check' 'w-3.5 h-3.5' %}{% trans "Accept Cookies" %}
    </button>
  </div>
</div>
EOF

cat > templates/partials/_whatsapp_fab.html << 'EOF'
{% load icons %}
<div class="fixed bottom-4 right-4 z-30">
  <a href="https://wa.me/{{ site.whatsapp_number }}?text=Hello%20TUYYO%20SUP!%20I%20would%20like%20to%20book%20a%20SUP."
     target="_blank" rel="noopener noreferrer" aria-label="WhatsApp Quick Order"
     class="flex h-12 w-12 items-center justify-center rounded-full border border-emerald-400/40 bg-emerald-500 text-white shadow-lg shadow-emerald-500/30 transition-colors duration-200 hover:bg-emerald-600 sm:h-14 sm:w-14">
    {% icon 'whatsapp' 'w-6 h-6 sm:w-7 sm:h-7' %}
  </a>
</div>
EOF

cat > templates/base.html << 'EOF'
{% load static i18n %}<!doctype html>
<html lang="{{ LANGUAGE_CODE }}" data-theme="light">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  {% include "partials/_theme_script.html" %}
  {% include "partials/_meta.html" %}
  <link rel="stylesheet" href="{% static 'css/app.css' %}">
  {% block extra_head %}{% endblock %}
</head>
<body class="flex min-h-screen flex-col bg-slate-50 font-sans text-slate-900 transition-colors duration-200 selection:bg-sky-500 selection:text-white dark:bg-slate-950 dark:text-slate-100">
  {% include "partials/_navbar.html" %}
  <main class="flex-1">{% block content %}{% endblock %}</main>
  {% include "partials/_footer.html" %}
  {% include "partials/_cookie_banner.html" %}
  {% include "partials/_whatsapp_fab.html" %}

  <script>
    // Тема (без FOUC — виставляється в <head>)
    document.querySelectorAll('[data-theme-toggle]').forEach(function (btn) {
      btn.addEventListener('click', function () {
        var next = document.documentElement.dataset.theme === 'dark' ? 'light' : 'dark';
        document.documentElement.dataset.theme = next;
        try { localStorage.setItem('tuyyo_theme', next); } catch (e) {}
      });
    });
    // Мобільне меню
    (function () {
      var menu = document.querySelector('[data-mobile-menu]');
      var openIcon = document.querySelector('[data-menu-open-icon]');
      var closeIcon = document.querySelector('[data-menu-close-icon]');
      document.querySelectorAll('[data-menu-toggle]').forEach(function (btn) {
        btn.addEventListener('click', function () {
          menu.classList.toggle('hidden');
          openIcon.classList.toggle('hidden');
          closeIcon.classList.toggle('hidden');
        });
      });
    })();
    // Cookie-банер (LOPDGDD/GDPR)
    (function () {
      var banner = document.querySelector('[data-cookie-banner]');
      try {
        if (!localStorage.getItem('tuyyo_cookie_consent')) banner.classList.remove('hidden');
      } catch (e) { banner.classList.remove('hidden'); }
      document.querySelector('[data-cookie-accept]').addEventListener('click', function () {
        try { localStorage.setItem('tuyyo_cookie_consent', 'accepted'); } catch (e) {}
        banner.classList.add('hidden');
      });
    })();
  </script>
  {% block extra_js %}{% endblock %}
</body>
</html>
EOF

# ── 10. Сторінки: home (hero 1:1), booking-заглушка, styleguide, 404 ───────
cat > templates/core/home.html << 'EOF'
{% extends "base.html" %}
{% load i18n icons %}

{% block content %}
{# HERO — 1:1 з HomePage.tsx #}
<section class="relative flex min-h-[92vh] items-center justify-center overflow-hidden bg-slate-950 px-4 pb-24 pt-16 text-white sm:min-h-[calc(100vh-5rem)] sm:pb-32 sm:pt-24">
  <div class="absolute inset-0 z-0 bg-gradient-to-br from-slate-950 via-sky-950/80 to-slate-950">
    <div class="absolute inset-0 bg-[radial-gradient(ellipse_80%_80%_at_50%_-20%,rgba(14,165,233,0.35),transparent)]"></div>
    <div class="absolute inset-0 bg-[radial-gradient(circle_at_85%_75%,rgba(20,184,166,0.25),transparent_50%)]"></div>
    <div class="absolute inset-0 bg-[radial-gradient(circle_at_15%_65%,rgba(56,189,248,0.2),transparent_45%)]"></div>
  </div>
  <div class="pointer-events-none absolute left-1/2 top-1/4 h-[600px] w-[600px] -translate-x-1/2 -translate-y-1/2 rounded-full bg-sky-500/15 blur-[140px]"></div>

  <div class="relative z-10 mx-auto max-w-7xl space-y-6 text-center">
    <div class="inline-flex items-center gap-1.5 rounded-full border border-sky-500/30 bg-sky-500/20 px-4 py-1.5 text-xs font-extrabold text-sky-300 shadow-lg backdrop-blur-md">
      {% icon 'map-pin' 'w-4 h-4 text-sky-400' %}
      <span>{% trans "Costa Blanca, Spain" %}</span>
    </div>
    <h1 class="text-4xl font-black leading-[1.1] tracking-tight text-white sm:text-6xl lg:text-7xl">
      {% trans "Sea. Sun." %}
      <span class="bg-gradient-to-r from-sky-400 via-teal-300 to-sky-200 bg-clip-text text-transparent">{% trans "Freedom." %}</span>
    </h1>
    <p class="mx-auto max-w-4xl space-y-1.5 text-base font-medium leading-relaxed text-slate-200 sm:text-xl">
      <span class="block font-semibold">{% trans "Explore Benidorm, Altea, Villajoyosa, Calpe & Alicante." %}</span>
      <span class="block text-sm text-slate-300 sm:text-lg">{% trans "Top quality inflatable paddleboards with beach delivery or free base pickup." %}</span>
    </p>
    <div class="flex flex-col items-center justify-center gap-4 pt-4 sm:flex-row">
      <a href="{% url 'booking' %}"
         class="w-full rounded-2xl bg-gradient-to-r from-sky-500 to-teal-400 px-8 py-4 text-lg font-black text-slate-950 shadow-xl shadow-sky-500/25 transition-all hover:-translate-y-0.5 hover:from-sky-400 hover:to-teal-300 sm:w-auto">
        {% trans "Reserve SUP Board" %}
      </a>
      <a href="https://wa.me/{{ site.whatsapp_number }}" target="_blank" rel="noopener noreferrer"
         class="flex w-full items-center justify-center gap-2.5 rounded-2xl bg-emerald-600 px-6 py-4 text-base font-extrabold text-white shadow-lg shadow-emerald-600/30 transition-all hover:bg-emerald-500 sm:w-auto">
        {% icon 'phone' 'w-5 h-5' %}{% trans "WhatsApp Quick Booking" %}
      </a>
    </div>
  </div>
</section>

{# Якірні заглушки секцій (контент — Етап 3; навігаційні хеші вже працюють) #}
{% for anchor, label in anchors %}
<section id="{{ anchor }}" class="mx-auto max-w-7xl scroll-mt-24 px-4 py-16 sm:px-6 lg:px-8">
  <div class="rounded-3xl border border-dashed border-slate-300 p-10 text-center dark:border-slate-700">
    <span class="text-xs font-extrabold uppercase tracking-widest text-sky-600">#{{ anchor }}</span>
    <h2 class="mt-2 text-2xl font-black">{{ label }}</h2>
    <p class="mt-1 text-xs text-slate-500">Секція буде наповнена в Етапі 3 (1:1 з референсом)</p>
  </div>
</section>
{% endfor %}
{% endblock %}
EOF

# Контекст якорів — через view (оновлюємо core/views.py HomeView)
cat > core/views.py << 'EOF'
from django.conf import settings
from django.http import Http404
from django.utils.translation import gettext_lazy as _
from django.views.generic import TemplateView


class HomeView(TemplateView):
    template_name = "core/home.html"

    def get_context_data(self, **kwargs):
        ctx = super().get_context_data(**kwargs)
        ctx["anchors"] = [
            ("tariffs", _("Tariffs")),
            ("gallery", _("Gallery")),
            ("guide", _("SUP Guide")),
            ("faq", _("FAQ")),
        ]
        return ctx


class BookingPlaceholderView(TemplateView):
    """Заглушка; повний 6-кроковий візард — Етап 5."""

    template_name = "core/booking_placeholder.html"


class StyleguideView(TemplateView):
    """Каталог компонентів (патерн HackSoft django-styleguide). Лише dev/staff."""

    template_name = "core/styleguide.html"

    def dispatch(self, request, *args, **kwargs):
        if not (settings.DEBUG or request.user.is_staff):
            raise Http404
        return super().dispatch(request, *args, **kwargs)
EOF

cat > templates/core/booking_placeholder.html << 'EOF'
{% extends "base.html" %}
{% block content %}
<section class="mx-auto max-w-3xl px-4 py-24 text-center">
  <span class="text-xs font-extrabold uppercase tracking-widest text-sky-600">/booking/</span>
  <h1 class="mt-3 text-3xl font-black">6-Step Booking Wizard</h1>
  <p class="mt-3 text-sm text-slate-500">
    Реалізується в Етапі 5–6: session state-machine + HTMX, PricingService,
    серверний календар, Bizum QR, PDF-ваучер, UUID-посилання.
  </p>
  <a href="{% url 'home' %}" class="mt-8 inline-block rounded-2xl bg-sky-500 px-6 py-3 text-sm font-extrabold text-white">← Home</a>
</section>
{% endblock %}
EOF

cat > templates/core/styleguide.html << 'EOF'
{% extends "base.html" %}
{% load icons %}
{% block content %}
<section class="mx-auto max-w-5xl space-y-12 px-4 py-12">
  <header class="space-y-2 border-b border-slate-200 pb-6 dark:border-slate-800">
    <span class="text-xs font-extrabold uppercase tracking-widest text-sky-600">Styleguide · Етап 0</span>
    <h1 class="text-3xl font-black">Компонентна база TUYYO.CLUB</h1>
    <p class="text-sm text-slate-500">Дизайн-токени Tailwind v4 · палітра sky/teal/slate з референсу</p>
  </header>

  <div class="space-y-4">
    <h2 class="text-lg font-black">Кольори</h2>
    <div class="grid grid-cols-2 gap-3 sm:grid-cols-5">
      <div class="h-16 rounded-2xl bg-sky-500"></div>
      <div class="h-16 rounded-2xl bg-teal-400"></div>
      <div class="h-16 rounded-2xl bg-emerald-500"></div>
      <div class="h-16 rounded-2xl bg-amber-500"></div>
      <div class="h-16 rounded-2xl bg-slate-950 ring-1 ring-slate-200"></div>
    </div>
  </div>

  <div class="space-y-4">
    <h2 class="text-lg font-black">Кнопки</h2>
    <div class="flex flex-wrap items-center gap-3">
      <button class="rounded-2xl bg-gradient-to-r from-sky-500 to-teal-500 px-6 py-3 text-sm font-extrabold text-white shadow-lg shadow-sky-500/20">Primary CTA</button>
      <button class="rounded-2xl bg-emerald-600 px-6 py-3 text-sm font-extrabold text-white shadow-lg">WhatsApp</button>
      <button class="rounded-2xl border border-slate-300 bg-white px-6 py-3 text-sm font-bold text-slate-700 dark:border-slate-700 dark:bg-slate-900 dark:text-slate-200">Secondary</button>
      <span class="rounded-full border border-sky-500/20 bg-sky-500/10 px-3.5 py-1.5 text-xs font-extrabold uppercase tracking-widest text-sky-600">Eyebrow Badge</span>
    </div>
  </div>

  <div class="space-y-4">
    <h2 class="text-lg font-black">SectionHeader (патерн референсу)</h2>
    <div class="mx-auto max-w-3xl space-y-3 text-center">
      <span class="inline-flex items-center gap-1.5 rounded-full border border-sky-500/20 bg-sky-500/10 px-3.5 py-1.5 text-xs font-extrabold uppercase tracking-widest text-sky-600">
        {% icon 'sparkles' 'w-3.5 h-3.5 text-sky-500' %} Eyebrow
      </span>
      <h3 class="text-3xl font-black tracking-tight sm:text-4xl">Section Title</h3>
      <p class="mx-auto max-w-2xl text-sm leading-relaxed text-slate-600 dark:text-slate-400">Опис секції — один-два рядки контексту.</p>
    </div>
  </div>

  <div class="space-y-4">
    <h2 class="text-lg font-black">Форми</h2>
    <input type="text" placeholder="Text input"
           class="w-full max-w-sm rounded-2xl border border-slate-200 bg-slate-50 p-3 text-sm focus:border-sky-500 focus:outline-none dark:border-slate-800 dark:bg-slate-950">
    <div class="flex max-w-sm items-center gap-2 rounded-2xl border border-red-500/30 bg-red-500/10 p-4 text-xs text-red-700 dark:text-red-200">
      {% icon 'help-circle' 'w-4 h-4 shrink-0 text-red-500' %} Validation alert
    </div>
  </div>
</section>
{% endblock %}
EOF

cat > templates/404.html << 'EOF'
{% extends "base.html" %}
{% block content %}
<section class="mx-auto max-w-xl px-4 py-32 text-center">
  <h1 class="text-6xl font-black text-sky-500">404</h1>
  <p class="mt-4 text-sm text-slate-500">Сторінку не знайдено. Можливо, URL застарів після редизайну.</p>
  <a href="/en/" class="mt-8 inline-block rounded-2xl bg-sky-500 px-6 py-3 text-sm font-extrabold text-white">← Головна</a>
</section>
{% endblock %}
EOF

cat > templates/robots.txt << 'EOF'
User-agent: *
Allow: /
Disallow: /admin/
Disallow: /styleguide/

Sitemap: {{ site_url }}/sitemap.xml
EOF

# ── 11. URL: i18n_patterns + SEO-ендпоінти + легасі-редиректи ──────────────
cat > config/urls.py << 'EOF'
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
EOF

# ── 12. Тести (димові) ─────────────────────────────────────────────────────
cat > core/tests.py << 'EOF'
from django.test import TestCase


class Stage0SmokeTests(TestCase):
    def test_home_en_200(self):
        self.assertEqual(self.client.get("/en/").status_code, 200)

    def test_home_es_200(self):
        self.assertEqual(self.client.get("/es/").status_code, 200)

    def test_root_redirects_by_language(self):
        self.assertEqual(self.client.get("/").status_code, 302)

    def test_robots_txt(self):
        r = self.client.get("/robots.txt")
        self.assertEqual(r.status_code, 200)
        self.assertIn("Sitemap", r.content.decode())

    def test_sitemap_xml(self):
        self.assertEqual(self.client.get("/sitemap.xml").status_code, 200)

    def test_legacy_terms_redirects(self):
        self.assertEqual(self.client.get("/terms").status_code, 302)

    def test_booking_placeholder(self):
        self.assertEqual(self.client.get("/en/booking/").status_code, 200)

    def test_styleguide_available_in_debug(self):
        self.assertEqual(self.client.get("/en/styleguide/").status_code, 200)

    def test_hreflang_in_head(self):
        html = self.client.get("/en/").content.decode()
        self.assertIn('hreflang="es"', html)
        self.assertIn('hreflang="x-default"', html)
EOF

# ── 13. Tailwind v4 (standalone CLI) ───────────────────────────────────────
cat > static/css/input.css << 'EOF'
@import "tailwindcss";

/* Темна тема через data-theme (без FOUC — скрипт у <head>) */
@custom-variant dark (&:where([data-theme=dark], [data-theme=dark] *));

/* Сканування шаблонів Django */
@source "../../templates";

/* Дизайн-токени 1:1 з index.css референсу */
@theme {
  --animate-fade-in: fade-in 0.3s cubic-bezier(0.16, 1, 0.3, 1) forwards;
  --animate-slide-up: slide-up 0.4s cubic-bezier(0.16, 1, 0.3, 1) forwards;
  --animate-scale-up: scale-up 0.25s cubic-bezier(0.16, 1, 0.3, 1) forwards;

  @keyframes fade-in {
    from { opacity: 0; transform: translateY(6px); }
    to { opacity: 1; transform: translateY(0); }
  }
  @keyframes slide-up {
    from { transform: translateY(100%); }
    to { transform: translateY(0); }
  }
  @keyframes scale-up {
    from { opacity: 0; transform: scale(0.95); }
    to { opacity: 1; transform: scale(1); }
  }
}

@layer base {
  html {
    scroll-behavior: smooth;
    scroll-padding-top: 65px;
  }
}
EOF

cat > scripts/build_css.sh << 'EOF'
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
./bin/tailwindcss -i static/css/input.css -o static/css/app.css --minify
echo "✅ CSS зібрано → static/css/app.css"
EOF
chmod +x scripts/build_css.sh

echo "⬇️  Завантаження Tailwind v4 standalone CLI…"
if curl -sfL -o bin/tailwindcss \
     https://github.com/tailwindlabs/tailwindcss/releases/latest/download/tailwindcss-linux-x64; then
  chmod +x bin/tailwindcss
  ./scripts/build_css.sh
else
  echo "⚠️  Tailwind CLI не завантажився (немає мережі?). Створено fallback-CSS."
  cat > static/css/app.css << 'EOF'
/* FALLBACK: запустіть ./scripts/build_css.sh після завантаження bin/tailwindcss */
*,::before,::after{box-sizing:border-box}body{margin:0;font-family:system-ui,sans-serif}
EOF
fi

# ── 14. i18n: генерація .po, насичення ES-перекладами, компіляція ──────────
if command -v xgettext >/dev/null 2>&1; then
  python manage.py makemessages -l es --no-location -v 0

  python - << 'PY'
"""Заповнення msgstr ES для відомих рядків Етапу 0 (з TRANSLATIONS.es референсу)."""
import pathlib
import re

TRANSLATIONS = {
    "Locations": "Ubicaciones",
    "beaches": "playas",
    "Tariffs": "Tarifas",
    "Gallery": "Galería",
    "SUP Guide": "Guía SUP",
    "FAQ": "FAQ",
    "Terms & Safety": "Términos y Seguridad",
    "Toggle theme": "Cambiar tema",
    "Toggle menu": "Abrir menú",
    "Book SUP Now": "Reservar SUP",
    "WhatsApp Quick Order": "Pedido Rápido por WhatsApp",
    "Legal Entity:": "Entidad Legal:",
    "CIF / NIF:": "CIF / NIF:",
    "Tourism License:": "Licencia Turística:",
    "RC Insurance:": "Seguro RC:",
    "Legal Notice": "Aviso Legal",
    "Terms & Conditions": "Términos y Condiciones",
    "Privacy Policy": "Política de Privacidad",
    "Cookie Policy": "Política de Cookies",
    "Contact & Payment": "Contacto y Pago",
    "All rights reserved.": "Todos los derechos reservados.",
    "Made with": "Hecho con",
    "for SUP lovers along Costa Blanca": "para los amantes del SUP en la Costa Blanca",
    "SUP Rental %(name)s": "Alquiler SUP %(name)s",
    "Mobile Stand-Up Paddleboard rental service with direct beach and hotel delivery across Benidorm, Altea, Villajoyosa, Calpe, and Alicante.": "Servicio móvil de alquiler de tablas de paddle surf con entrega directa en playa y hotel en Benidorm, Altea, Villajoyosa, Calpe y Alicante.",
    "We use strictly necessary cookies to process your SUP booking and ensure smooth PWA functionality. Under LOPDGDD / GDPR laws, no tracking cookies are stored without consent.": "Utilizamos cookies estrictamente necesarias para procesar su reserva y garantizar el correcto funcionamiento de la PWA según la LOPDGDD/RGPD.",
    "Read Cookie Policy": "Ver Política de Cookies",
    "Accept Cookies": "Aceptar Cookies",
    "Costa Blanca, Spain": "Costa Blanca, España",
    "Sea. Sun.": "Mar. Sol.",
    "Freedom.": "Libertad.",
    "Explore Benidorm, Altea, Villajoyosa, Calpe & Alicante.": "Explora Benidorm, Altea, Villajoyosa, Calpe y Alicante.",
    "Top quality inflatable paddleboards with beach delivery or free base pickup.": "Tablas de paddle surf hinchables de alta calidad con entrega en playa o recogida gratis en base.",
    "Reserve SUP Board": "Reservar Tabla SUP",
    "WhatsApp Quick Booking": "Reserva por WhatsApp",
}

po = pathlib.Path("locale/es/LC_MESSAGES/django.po")
if po.exists():
    text = po.read_text(encoding="utf-8")

    def repl(m):
        msgid = m.group(1)
        if msgid in TRANSLATIONS:
            return f'msgid "{msgid}"\nmsgstr "{TRANSLATIONS[msgid]}"'
        return m.group(0)

    text = re.sub(r'msgid "((?:[^"\\]|\\.)+)"\nmsgstr ""', repl, text)
    po.write_text(text, encoding="utf-8")
    print(f"✅ ES-переклади застосовано: {len(TRANSLATIONS)} рядків")
PY

  python manage.py compilemessages -v 0
  echo "✅ .mo скомпільовано"
else
  echo "⚠️  gettext відсутній — i18n-компіляцію пропущено (сайт працюватиме англійською)"
fi

# ── 15. CI, ADR, WCAG-чеклист, README ──────────────────────────────────────
cat > .github/workflows/ci.yml << 'EOF'
name: CI

on: [push, pull_request]

jobs:
  quality:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: "3.12"
          cache: pip
      - name: Install dependencies
        run: pip install -r requirements.txt
      - name: Ruff lint
        run: ruff check .
      - name: Ruff format check
        run: ruff format --check .
      - name: Tests
        run: pytest

  # Етап 9: Lighthouse CI проти staging (розкоментувати після деплою)
  # lighthouse:
  #   needs: quality
  #   runs-on: ubuntu-latest
  #   steps:
  #     - uses: treosh/lighthouse-ci-action@v12
  #       with:
  #         urls: |
  #           https://staging.tuyyo.club/en/
  #         budgetPath: ./lighthouse-budget.json
EOF

cat > docs/adr/0001-django-ssr-over-spa.md << 'EOF'
# ADR-0001: Django SSR замість React SPA

**Статус:** ухвалено · **Дата:** 2026-08-01

React-референс рендериться на клієнті: title/JSON-LD інжектуються в JS,
маршрути через pushState — сайт майже невидимий для Google.
Django SSR дає: індексованість з першого запиту, hreflang, CWV (LCP < 2.5 с),
нульовий JS-бандл для контенту. HTMX — інтерактив без SPA.
EOF

cat > docs/adr/0002-parler-localized-slugs.md << 'EOF'
# ADR-0002: django-parler + локалізовані slug'и

**Статус:** ухвалено · **Дата:** 2026-08-01

Переклади моделей — django-parler (TranslatableModel/TranslatedFields).
Slug — TranslatedField: /en/sup-rental-benidorm/ ↔ /es/alquiler-sup-benidorm/.
Google рекомендує перекладені URL; конкуренти цього не роблять — SEO-перевага.
Мови: EN/ES (x-default → EN). UA-рядки референсу — артефакти, ігноруються.
EOF

cat > docs/adr/0003-session-wizard-over-formtools.md << 'EOF'
# ADR-0003: кастомний session-wizard замість django-formtools

**Статус:** ухвалено · **Дата:** 2026-08-01

formtools SessionWizardView — канон, але: застарілі шаблони (несумісні з
дизайном референсу), слабка HTMX-інтеграція, режим підтримки.
Рішення: session state-machine + 6 Form-класів + PRG + HTMX + idempotency.
Патерни formtools (done(), умовні кроки) запозичені в API.
EOF

cat > docs/adr/0004-tailwind-v4-standalone.md << 'EOF'
# ADR-0004: Tailwind v4 standalone CLI

**Статус:** ухвалено · **Дата:** 2026-08-01

Без Node.js-ланцюжка: бінарник tailwindcss-linux-x64 у bin/ (gitignored),
збірка через scripts/build_css.sh. Конфіг — CSS-first (@theme, @custom-variant
dark за data-theme). Токени анімацій — 1:1 з index.css референсу.
EOF

cat > docs/wcag-checklist.md << 'EOF'
# WCAG 2.2 AA — DoD-чеклист (EAA, обов'язково в ЄС з 28.06.2025)

- [ ] Семантичні landmark'и: header/nav/main/footer (є в base.html)
- [ ] Один H1 на сторінку
- [ ] aria-label на кнопках-іконках (тема, меню, WhatsApp)
- [ ] ARIA для акордеона FAQ / модалок / табів (Етап 3–4)
- [ ] Фокус-менеджмент: модалки trap focus, Esc закриває
- [ ] Контраст тексту ≥ 4.5:1 (sky-600 на білому — ок)
- [ ] alt у всіх зображень (з БД, перекладний)
- [ ] autocomplete/inputmode у формі бронювання (Етап 5)
- [ ] Повна клавіатурна навігація візарда
- [ ] Помилки форм: text + aria-describedby, не лише колір
EOF

cat > README.md << 'EOF'
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
EOF

# ── 16. Міграції, суперюзер, перевірки, тести ──────────────────────────────

python manage.py makemigrations
python manage.py migrate

DJANGO_SUPERUSER_PASSWORD=admin123 python manage.py createsuperuser \
  --noinput --username admin --email admin@tuyyo.club 2>/dev/null \
  || echo "ℹ️  Суперюзер вже існує"

echo "🔍 Django system check…"
python manage.py check

echo "🧪 Тести…"
pytest

# ── 17. Git: перший коміт ──────────────────────────────────────────────────

if command -v git >/dev/null 2>&1; then
  git add -A
  git -c user.name="TUYYO Dev" -c user.email="dev@tuyyo.club" \
      commit -q -m "Етап 0: фундамент + SEO-інфраструктура + base.html 1:1" \
    || echo "ℹ️  Коміт пропущено"
fi

echo ""
echo "═══════════════════════════════════════════════════════════"
echo " ✅ Етап 0 завершено"
echo " ─────────────────────────────────────────────────────────"
echo " Запуск:  source venv/bin/activate"
echo "          python manage.py runserver"
echo ""
echo " Перевірте:"
echo "   http://127.0.0.1:8000/en/          головна + hero"
echo "   http://127.0.0.1:8000/es/          іспанська версія"
echo "   http://127.0.0.1:8000/en/styleguide/"
echo "   http://127.0.0.1:8000/sitemap.xml  (з hreflang alternates)"
echo "   http://127.0.0.1:8000/admin/       admin / admin123"
echo ""
echo " Наступний крок: Етап 1 — Ядро CMS (скажіть «далі»)"
echo "═══════════════════════════════════════════════════════════"


