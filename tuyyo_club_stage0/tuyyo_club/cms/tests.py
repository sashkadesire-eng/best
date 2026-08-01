from django.core.management import call_command
from django.test import TestCase

from cms.models import Page, Section, SiteSettings


def make_page(en_slug, es_slug, title="Test"):
    page = Page.objects.create(template="cms/page_standard.html", published=True)
    page.set_current_language("en")
    page.slug, page.title = en_slug, title
    page.set_current_language("es")
    page.slug, page.title = es_slug, title
    page.save()
    return page


class SingletonTests(TestCase):
    def test_get_solo_returns_same_instance(self):
        a = SiteSettings.get_solo()
        b = SiteSettings.get_solo()
        self.assertEqual(a.pk, b.pk)
        self.assertEqual(a.pk, 1)


class PageResolutionTests(TestCase):
    def setUp(self):
        self.page = make_page("privacy-policy", "politica-de-privacidad", "Privacy")
        Section.objects.create(page=self.page, order=10, section_type="richtext", is_active=True)

    def test_en_slug_resolves(self):
        self.assertEqual(self.client.get("/en/privacy-policy/").status_code, 200)

    def test_es_slug_resolves(self):
        self.assertEqual(self.client.get("/es/politica-de-privacidad/").status_code, 200)

    def test_wrong_language_slug_is_404(self):
        # Суворий мовний резолвер: EN-slug під /es/ не працює
        self.assertEqual(self.client.get("/es/privacy-policy/").status_code, 404)

    def test_unpublished_page_is_404(self):
        self.page.published = False
        self.page.save()
        self.assertEqual(self.client.get("/en/privacy-policy/").status_code, 404)

    def test_hreflang_points_to_localized_slugs(self):
        html = self.client.get("/en/privacy-policy/").content.decode()
        self.assertIn("/es/politica-de-privacidad/", html)
        self.assertIn('hreflang="x-default"', html)


class SectionOrderTests(TestCase):
    def test_sections_render_in_order(self):
        page = make_page("order-test", "order-test")
        Section.objects.create(page=page, order=20, section_type="richtext", anchor_id="second", is_active=True)
        Section.objects.create(page=page, order=10, section_type="richtext", anchor_id="first", is_active=True)
        html = self.client.get("/en/order-test/").content.decode()
        self.assertLess(html.index('id="first"'), html.index('id="second"'))

    def test_inactive_section_hidden(self):
        page = make_page("hidden-test", "hidden-test")
        Section.objects.create(page=page, order=10, section_type="richtext", anchor_id="visible", is_active=True)
        Section.objects.create(page=page, order=20, section_type="richtext", anchor_id="hidden", is_active=False)
        html = self.client.get("/en/hidden-test/").content.decode()
        self.assertIn('id="visible"', html)
        self.assertNotIn('id="hidden"', html)


class SeedCommandTests(TestCase):
    def test_seed_creates_core_content(self):
        call_command("seed_cms")
        self.assertTrue(SiteSettings.objects.filter(pk=1).exists())
        self.assertEqual(self.client.get("/en/").status_code, 200)
        self.assertEqual(self.client.get("/es/").status_code, 200)
        self.assertEqual(self.client.get("/en/terms-and-safety/").status_code, 200)
        self.assertEqual(self.client.get("/es/terminos-y-seguridad/").status_code, 200)
        self.assertEqual(self.client.get("/en/legal-notice/").status_code, 200)

    def test_seed_is_idempotent(self):
        call_command("seed_cms")
        call_command("seed_cms")
        self.assertEqual(Page.objects.filter(is_homepage=True).count(), 1)
        self.assertEqual(SiteSettings.objects.count(), 1)

    def test_menu_links_rendered_on_home(self):
        call_command("seed_cms")
        html = self.client.get("/en/").content.decode()
        self.assertIn("Tariffs", html)
        self.assertIn("#tariffs", html)
        html_es = self.client.get("/es/").content.decode()
        self.assertIn("Tarifas", html_es)

    def test_home_cta_section_from_db(self):
        call_command("seed_cms")
        html = self.client.get("/en/").content.decode()
        self.assertIn("Ready to paddle Costa Blanca?", html)
