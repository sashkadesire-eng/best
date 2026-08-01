"""Ядро CMS: повністю динамічний сайт.

SiteSettings — singleton (власна реалізація, ADR-0006; django-solo не потрібен).
Page → Section → SectionItem — конструктор сторінок.
Усі текстові поля — TranslatedFields (parler), slug — перекладний (ADR-0007).
"""
from django.db import models
from parler.fields import TranslatedField
from parler.models import TranslatableModel, TranslatedFields

PAGE_TEMPLATES = [
    ("cms/page_home.html", "Головна"),
    ("cms/page_standard.html", "Стандартна сторінка"),
    ("catalog/location.html", "Лендінг локації (Етап 4)"),
]

SECTION_TYPES = [
    ("hero", "Hero"),
    ("features_banner", "Features-банер"),
    ("tariffs", "Тарифи"),
    ("gallery", "Галерея"),
    ("fleet", "Флот"),
    ("guide_cards", "Guide-картки"),
    ("locations", "Локації"),
    ("reviews", "Відгуки"),
    ("faq", "FAQ"),
    ("cta_banner", "CTA-банер"),
    ("richtext", "Rich text"),
    ("location_hero", "Hero локації"),
    ("paddle_guide", "Paddle-гайд"),
    ("other_locations", "Інші локації"),
]


class SingletonModel(models.Model):
    """Abstract singleton: pk завжди 1 (ADR-0006)."""

    class Meta:
        abstract = True

    def save(self, *args, **kwargs):
        self.pk = 1
        super().save(*args, **kwargs)

    @classmethod
    def get_solo(cls):
        obj, _created = cls.objects.get_or_create(pk=1)
        return obj


class SiteSettings(SingletonModel, TranslatableModel):
    """Глобальні налаштування сайту. Єдине джерело правди після seed."""

    # Ідентичність
    name = models.CharField("Назва сайту", max_length=60, default="TUYYO.CLUB")
    copyright = models.CharField(max_length=120, default="© 2026 TUYYO GROUP S.L.")
    # Юридичний блок (футер, ваучер, legal)
    company_legal_name = models.CharField(max_length=120, default="TUYYO GROUP S.L.")
    cif = models.CharField("CIF / NIF", max_length=30, default="B-03918234")
    licencia = models.CharField("Туристична ліцензія", max_length=60, default="VA-TUR-2024/9182")
    seguro_rc = models.CharField("Страховка RC", max_length=120, default="AXA № 78192834-RC (€600,000)")
    # Контакти
    phone = models.CharField(max_length=30, default="+34 623 575 015")
    whatsapp_number = models.CharField(max_length=20, default="34623575015")
    bizum_phone = models.CharField(max_length=30, default="+34 623 575 015")
    email = models.EmailField(default="tuyyogroup@gmail.com")
    address = models.CharField(max_length=200, default="Av. Miguel Hernández 25, Finestrat")
    maps_url = models.URLField(blank=True)
    google_maps_reviews_url = models.URLField(blank=True)
    # Фінанси
    deposit_amount = models.PositiveIntegerField(default=150)
    delivery_fee = models.PositiveIntegerField(default=20)
    # Медіа
    hero_video_url = models.URLField(blank=True)
    # Локації — JSON тимчасово; в Етапі 2 замінюється моделлю catalog.Location
    locations = models.JSONField(default=list, blank=True)

    translations = TranslatedFields(
        tagline=models.CharField(max_length=160, blank=True),
        footer_description=models.TextField(blank=True),
        default_meta_title=models.CharField(max_length=200, blank=True),
        default_meta_description=models.CharField(max_length=320, blank=True),
    )

    class Meta:
        verbose_name = "Налаштування сайту"

    def __str__(self):
        return self.name


class Page(TranslatableModel):
    """Сторінка сайту. Slug перекладається: /en/privacy-policy/ ↔ /es/politica-de-privacidad/."""

    template = models.CharField(max_length=60, choices=PAGE_TEMPLATES, default="cms/page_standard.html")
    is_homepage = models.BooleanField(default=False)
    published = models.BooleanField(default=True)
    updated_at = models.DateTimeField(auto_now=True)

    translations = TranslatedFields(
        slug=models.SlugField(max_length=120, blank=True),
        title=models.CharField(max_length=200, blank=True),
        meta_title=models.CharField(max_length=200, blank=True),
        meta_description=models.CharField(max_length=320, blank=True),
    )

    class Meta:
        verbose_name = "Сторінка"

    def __str__(self):
        return f"Page #{self.pk} [{self.safe_title}]"

    @property
    def safe_title(self):
        try:
            return self.title or self.slug or f"#{self.pk}"
        except Exception:
            return f"#{self.pk}"


class Section(TranslatableModel):
    """Секція сторінки. Спільні поля eyebrow/title/description — як SectionHeader.tsx."""

    page = models.ForeignKey(Page, related_name="sections", on_delete=models.CASCADE)
    order = models.PositiveIntegerField(default=0)
    section_type = models.CharField(max_length=30, choices=SECTION_TYPES)
    is_active = models.BooleanField(default=True)
    anchor_id = models.SlugField(max_length=60, blank=True, help_text="Якір для навігації, напр. tariffs")
    config = models.JSONField(default=dict, blank=True, help_text="Скалярні налаштування типу")

    translations = TranslatedFields(
        eyebrow=models.CharField(max_length=160, blank=True),
        title=models.CharField(max_length=220, blank=True),
        description=models.TextField(blank=True),
        body=models.TextField(blank=True, help_text="HTML для richtext-секцій"),
    )

    class Meta:
        verbose_name = "Секція"
        ordering = ["order"]
        constraints = [
            models.UniqueConstraint(fields=["page", "order"], name="uniq_section_page_order")
        ]

    def __str__(self):
        return f"{self.get_section_type_display()} (page #{self.page_id}, order {self.order})"

    @property
    def template_name(self):
        return f"cms/sections/{self.section_type}.html"


class SectionItem(TranslatableModel):
    """Універсальний повторюваний елемент: фіча, guide-картка, відгук, крок."""

    section = models.ForeignKey(Section, related_name="items", on_delete=models.CASCADE)
    order = models.PositiveIntegerField(default=0)
    icon = models.CharField(max_length=30, blank=True, help_text="Назва іконки з icons.py")
    image = models.ImageField(upload_to="sections/", blank=True)
    link_url = models.CharField(max_length=300, blank=True)

    translations = TranslatedFields(
        title=models.CharField(max_length=220, blank=True),
        text=models.TextField(blank=True),
        badge=models.CharField(max_length=120, blank=True),
    )

    class Meta:
        verbose_name = "Елемент секції"
        ordering = ["order"]

    def __str__(self):
        return self.title or f"Item #{self.pk}"


class MenuLink(TranslatableModel):
    """Пункти навігації (navbar та футер)."""

    PLACEMENTS = [("navbar", "Navbar"), ("footer", "Footer (Legal)")]

    url = models.CharField(max_length=300, help_text="'#tariffs' або '/terms-and-safety/'")
    icon = models.CharField(max_length=30, blank=True)
    placement = models.CharField(max_length=10, choices=PLACEMENTS, default="navbar")
    order = models.PositiveIntegerField(default=0)
    is_active = models.BooleanField(default=True)

    translations = TranslatedFields(label=models.CharField(max_length=120))

    class Meta:
        verbose_name = "Пункт меню"
        ordering = ["order"]

    def __str__(self):
        return f"{self.url} [{self.placement}]"


class Review(TranslatableModel):
    """Відгук клієнта."""

    author = models.CharField(max_length=120)
    rating = models.PositiveSmallIntegerField(default=5)
    order = models.PositiveIntegerField(default=0)
    is_active = models.BooleanField(default=True)

    translations = TranslatedFields(text=models.TextField(blank=True))

    class Meta:
        verbose_name = "Відгук"
        ordering = ["order"]

    def __str__(self):
        return self.author
