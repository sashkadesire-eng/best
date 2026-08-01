"""SEO-теги: canonical, hreflang alternates.

Для CMS-сторінок alternates будуються з lang_urls (перекладені slug'и, ADR-0007) —
translate_url не підходить, бо реверсить той самий slug в іншу мову.
"""
from django import template
from django.conf import settings
from django.urls import translate_url
from django.utils.safestring import mark_safe

register = template.Library()


@register.simple_tag(takes_context=True)
def canonical_url(context):
    return context["request"].build_absolute_uri(context["request"].path)


@register.simple_tag(takes_context=True)
def canonical(context):
    return mark_safe(f'<link rel="canonical" href="{canonical_url(context)}" />')


@register.simple_tag(takes_context=True)
def render_alternates(context):
    request = context["request"]
    lang_urls = context.get("lang_urls")
    lines = []
    if lang_urls:
        for code, _name in settings.LANGUAGES:
            url = lang_urls.get(code)
            if url:
                lines.append(f'<link rel="alternate" hreflang="{code}" href="{request.build_absolute_uri(url)}" />')
        if lang_urls.get("en"):
            lines.append(f'<link rel="alternate" hreflang="x-default" href="{request.build_absolute_uri(lang_urls["en"])}" />')
    else:
        path = request.path
        for code, _name in settings.LANGUAGES:
            url = request.build_absolute_uri(translate_url(path, code))
            lines.append(f'<link rel="alternate" hreflang="{code}" href="{url}" />')
        default_url = request.build_absolute_uri(translate_url(path, "en"))
        lines.append(f'<link rel="alternate" hreflang="x-default" href="{default_url}" />')
    return mark_safe("\n  ".join(lines))
