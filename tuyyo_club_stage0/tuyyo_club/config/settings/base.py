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
