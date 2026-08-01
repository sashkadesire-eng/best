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
