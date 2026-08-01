"""PageView-рушій: сторінка = Page + впорядковані активні Section."""
from django.conf import settings
from django.http import Http404
from django.utils.translation import get_language
from django.views.generic import TemplateView

from cms.models import Page


def active_sections(page):
    return page.sections.filter(is_active=True).order_by("order").prefetch_related("items")


def page_lang_urls(page):
    """URL сторінки кожною мовою (локалізовані slug'и, ADR-0007).

    Використовується перемикачем мов та hreflang — замість translate_url,
    який не знає про перекладені slug'и.
    """
    if page.is_homepage:
        return {code: f"/{code}/" for code, _ in settings.LANGUAGES}
    urls = {}
    for tr in page.translations.all():
        if tr.slug:
            urls[tr.language_code] = f"/{tr.language_code}/{tr.slug}/"
    return urls


def page_context(page, lang_code=None):
    ctx = {"page": page, "sections": active_sections(page), "lang_urls": page_lang_urls(page)}
    if lang_code:
        ctx["lang_code"] = lang_code
    if page.meta_title:
        ctx["meta_title"] = page.meta_title
    if page.meta_description:
        ctx["meta_description"] = page.meta_description
    return ctx


class HomeView(TemplateView):
    template_name = "cms/page_home.html"

    def get_context_data(self, **kwargs):
        ctx = super().get_context_data(**kwargs)
        page = Page.objects.filter(is_homepage=True, published=True).first()
        lang_code = get_language()
        ctx["lang_code"] = lang_code
        if page:
            ctx.update(page_context(page, lang_code))
        else:
            ctx["lang_urls"] = {code: f"/{code}/" for code, _ in settings.LANGUAGES}
            ctx["sections"] = []
        return ctx


class PageDetailView(TemplateView):
    """Суворий мовний резолвер: /es/privacy-policy/ → 404 (ES-slug інший)."""

    def dispatch(self, request, *args, **kwargs):
        lang = get_language()
        self.page = (
            Page.objects.filter(
                published=True,
                is_homepage=False,
                translations__language_code=lang,
                translations__slug=kwargs["slug"],
            )
            .distinct()
            .first()
        )
        if self.page is None:
            raise Http404("Сторінку не знайдено для цієї мови")
        return super().dispatch(request, *args, **kwargs)

    def get_template_names(self):
        return [self.page.template]

    def get_context_data(self, **kwargs):
        ctx = super().get_context_data(**kwargs)
        ctx.update(page_context(self.page, get_language()))
        return ctx
