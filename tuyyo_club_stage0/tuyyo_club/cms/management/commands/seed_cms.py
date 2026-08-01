"""Seed CMS: SiteSettings, MenuLink, Review, Page (оболонки + секції).

Джерело початкових значень — settings.TUYYO_BUSINESS (див. ADR-0006).
Ідемпотентна: безпечний повторний запуск.
"""
from django.conf import settings
from django.core.management.base import BaseCommand

from cms.models import MenuLink, Page, Review, Section, SiteSettings


class Command(BaseCommand):
    help = "Seed CMS: налаштування, меню, відгуки, сторінки"

    def handle(self, *args, **options):
        self.seed_settings()
        self.seed_menu()
        self.seed_reviews()
        self.seed_pages()
        self.stdout.write(self.style.SUCCESS("✅ CMS seeded"))

    # ── SiteSettings ──
    def seed_settings(self):
        src = settings.TUYYO_BUSINESS  # початкові значення (seed-джерело)
        s = SiteSettings.get_solo()
        s.name = src["name"]
        s.company_legal_name = src["company_legal_name"]
        s.cif = src["cif"]
        s.licencia = src["licencia"]
        s.seguro_rc = src["seguro_rc"]
        s.phone = src["phone"]
        s.whatsapp_number = src["whatsapp_number"]
        s.bizum_phone = src["bizum_phone"]
        s.email = src["email"]
        s.address = src["address"]
        s.maps_url = src["maps_url"]
        s.deposit_amount = src["deposit_amount"]
        s.delivery_fee = src["delivery_fee"]
        s.copyright = src["copyright"]
        s.locations = src["locations"]
        s.set_current_language("en")
        s.tagline = "Costa Blanca SUP Rental"
        s.footer_description = (
            "Mobile Stand-Up Paddleboard rental service with direct beach and hotel "
            "delivery across Benidorm, Altea, Villajoyosa, Calpe, and Alicante."
        )
        s.default_meta_title = "TUYYO.CLUB — Costa Blanca SUP Rental & Beach Delivery"
        s.default_meta_description = (
            "SUP paddleboard rental with direct beach & hotel delivery in Benidorm, "
            "Altea, Villajoyosa, Calpe & Alicante. From €35. No credit card required."
        )
        s.set_current_language("es")
        s.tagline = "Alquiler de SUP en Costa Blanca"
        s.footer_description = (
            "Servicio móvil de alquiler de tablas de paddle surf con entrega directa "
            "en playa y hotel en Benidorm, Altea, Villajoyosa, Calpe y Alicante."
        )
        s.default_meta_title = "TUYYO.CLUB — Alquiler de SUP en Costa Blanca con Entrega en Playa"
        s.default_meta_description = (
            "Alquiler de tablas de paddle surf con entrega en playa u hotel en "
            "Benidorm, Altea, Villajoyosa, Calpe y Alicante. Desde €35. Sin tarjeta."
        )
        s.save()

    # ── MenuLink ──
    def seed_menu(self):
        navbar = [
            (10, "Tariffs", "Tarifas", "#tariffs", "sparkles"),
            (20, "Gallery", "Galería", "#gallery", "image"),
            (30, "SUP Guide", "Guía SUP", "#guide", "file-text"),
            (40, "FAQ", "FAQ", "#faq", "help-circle"),
            (50, "Terms & Safety", "Términos y Seguridad", "/terms-and-safety/", ""),
        ]
        footer = [
            (10, "Terms & Conditions", "Términos y Condiciones", "/terms-and-safety/"),
            (20, "Privacy Policy", "Política de Privacidad", "/privacy-policy/"),
            (30, "Cookie Policy", "Política de Cookies", "/cookie-policy/"),
            (40, "Legal Notice", "Aviso Legal", "/legal-notice/"),
        ]
        for order, en, es, url, ic in navbar:
            self._menu(url, "navbar", order, en, es, ic)
        for order, en, es, url in footer:
            self._menu(url, "footer", order, en, es, "")

    def _menu(self, url, placement, order, en, es, ic):
        link, _ = MenuLink.objects.get_or_create(
            url=url, placement=placement, defaults={"order": order, "icon": ic}
        )
        link.set_current_language("en")
        link.label = en
        link.set_current_language("es")
        link.label = es
        link.save()

    # ── Review ──
    def seed_reviews(self):
        reviews = [
            (
                "Markus T. (Germany)",
                "Super convenient! They delivered two SUPs right to Levante Beach in Benidorm. Boards were top condition.",
                "¡Super cómodo! Nos entregaron dos tablas directamente en la Playa de Levante en Benidorm. Tablas en perfecto estado.",
            ),
            (
                "Elena M. (Madrid)",
                "The convertible kayak model was perfect for exploring the coves of Altea. 10/10 service.",
                "El modelo convertible en kayak fue perfecto para recorrer las calas de Altea. Servicio de 10.",
            ),
            (
                "David & Sarah (UK)",
                "Quick WhatsApp coordination, arrived on time at Playa Paraíso Villajoyosa. Deposit returned immediately.",
                "Coordinación rápida por WhatsApp, puntuales en Playa Paraíso Villajoyosa. Depósito devuelto al instante.",
            ),
        ]
        for i, (author, en, es) in enumerate(reviews, start=1):
            r, _ = Review.objects.get_or_create(author=author, defaults={"order": i * 10, "rating": 5})
            r.set_current_language("en")
            r.text = en
            r.set_current_language("es")
            r.text = es
            r.save()

    # ── Page ──
    def seed_pages(self):
        home = self._page("home", "home", "Home", "Inicio", "cms/page_home.html", is_home=True)
        # CTA-банер на головній — демонстрація рушія секцій
        self._section(home, "cta_banner", 100, "", "Ready to paddle Costa Blanca?",
                      "¿Listo para navegar Costa Blanca?",
                      "Reserve in 60 seconds with zero credit card required. Free pickup or direct beach delivery.",
                      "Reserva en 60 segundos sin tarjeta. Recogida gratis o entrega directa en la playa.",
                      config={"button_url": "/booking/",
                              "button_label": {"en": "Book SUP Now", "es": "Reservar SUP"}})

        legal = [
            ("terms-and-safety", "terminos-y-seguridad", "Terms & Safety", "Términos y Seguridad"),
            ("privacy-policy", "politica-de-privacidad", "Privacy Policy", "Política de Privacidad"),
            ("cookie-policy", "politica-de-cookies", "Cookie Policy", "Política de Cookies"),
            ("legal-notice", "aviso-legal", "Legal Notice", "Aviso Legal"),
        ]
        placeholder_en = "<p>Full legal text (1:1 from the reference) is seeded in Stage 2.</p>"
        placeholder_es = "<p>El texto legal completo (1:1 del referente) se carga en la Etapa 2.</p>"
        for en_slug, es_slug, en_title, es_title in legal:
            page = self._page(en_slug, es_slug, en_title, es_title, "cms/page_standard.html")
            self._section(page, "richtext", 10, "", en_title, es_title, "", "",
                          body_en=placeholder_en, body_es=placeholder_es)

    def _page(self, en_slug, es_slug, en_title, es_title, template, is_home=False):
        # Спочатку шукаємо за EN-slug
        page = Page.objects.filter(
            translations__language_code="en", translations__slug=en_slug
        ).first()
        if page is None:
            # Якщо не знайдено, шукаємо за ES-slug (на випадок якщо створено з іншої мови)
            page = Page.objects.filter(
                translations__language_code="es", translations__slug=es_slug
            ).first()
        
        if page is None:
            # Якщо це homepage, спочатку скидаємо is_homepage у всіх інших
            if is_home:
                Page.objects.update(is_homepage=False)
            page = Page.objects.create(template=template, is_homepage=is_home, published=True)
        else:
            # Для ідемпотентності: якщо це homepage, переконуємось що тільки одна сторінка має is_homepage=True
            if is_home:
                Page.objects.exclude(pk=page.pk).update(is_homepage=False)
                page.is_homepage = True
                page.save()
        page.set_current_language("en")
        page.slug, page.title = en_slug, en_title
        page.set_current_language("es")
        page.slug, page.title = es_slug, es_title
        page.save()
        return page

    def _section(self, page, stype, order, eyebrow_en, title_en, title_es,
                 desc_en, desc_es, config=None, body_en="", body_es=""):
        section, _ = Section.objects.get_or_create(
            page=page, section_type=stype, order=order,
            defaults={"config": config or {}, "anchor_id": "" if stype != "cta_banner" else "cta"},
        )
        section.set_current_language("en")
        section.eyebrow, section.title, section.description, section.body = eyebrow_en, title_en, desc_en, body_en
        section.set_current_language("es")
        section.eyebrow, section.title, section.description, section.body = eyebrow_en, title_es, desc_es, body_es
        section.save()
        return section
