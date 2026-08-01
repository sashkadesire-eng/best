from django.conf import settings
from django.http import Http404
from django.views.generic import TemplateView


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
