from django.contrib import admin
from parler.admin import TranslatableAdmin, TranslatableStackedInline, TranslatableTabularInline

from cms.models import MenuLink, Page, Review, Section, SectionItem, SiteSettings


@admin.register(SiteSettings)
class SiteSettingsAdmin(TranslatableAdmin):
    fieldsets = (
        ("Ідентичність", {"fields": ("name", "tagline", "footer_description", "copyright")}),
        ("Юридичний блок", {"fields": ("company_legal_name", "cif", "licencia", "seguro_rc")}),
        ("Контакти", {"fields": ("phone", "whatsapp_number", "bizum_phone", "email", "address", "maps_url", "google_maps_reviews_url")}),
        ("Фінанси", {"fields": ("deposit_amount", "delivery_fee")}),
        ("SEO", {"fields": ("default_meta_title", "default_meta_description")}),
        ("Медіа", {"fields": ("hero_video_url",)}),
        ("Локації (JSON; до Етапу 2)", {"fields": ("locations",)}),
    )

    def has_add_permission(self, request):
        return not SiteSettings.objects.exists()

    def has_delete_permission(self, request, obj=None):
        return False


class SectionInline(TranslatableStackedInline):
    model = Section
    fields = ("section_type", "order", "anchor_id", "is_active")
    extra = 0


@admin.register(Page)
class PageAdmin(TranslatableAdmin):
    list_display = ("pk", "safe_title", "template", "is_homepage", "published")
    list_filter = ("is_homepage", "published", "template")
    inlines = [SectionInline]


class SectionItemInline(TranslatableTabularInline):
    model = SectionItem
    fields = ("order", "icon", "title", "badge", "link_url", "image")
    extra = 0


@admin.register(Section)
class SectionAdmin(TranslatableAdmin):
    list_display = ("pk", "page", "section_type", "order", "anchor_id", "is_active")
    list_filter = ("section_type", "is_active", "page")
    list_editable = ("order", "is_active")
    ordering = ("page", "order")
    inlines = [SectionItemInline]


@admin.register(MenuLink)
class MenuLinkAdmin(TranslatableAdmin):
    list_display = ("pk", "url", "placement", "order", "is_active")
    list_filter = ("placement", "is_active")
    list_editable = ("order", "is_active")


@admin.register(Review)
class ReviewAdmin(TranslatableAdmin):
    list_display = ("pk", "author", "rating", "order", "is_active")
    list_editable = ("order", "is_active")
