"""Налаштування розробки."""
from .base import *  # noqa: F403

DEBUG = True
SECRET_KEY = "dev-insecure-key-do-not-use-in-production"
ALLOWED_HOSTS = ["*"]
EMAIL_BACKEND = "django.core.mail.backends.console.EmailBackend"
INTERNAL_IPS = ["127.0.0.1"]
