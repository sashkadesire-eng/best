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
