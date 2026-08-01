from django.test import TestCase


class Stage0SmokeTests(TestCase):
    def test_home_en_200(self):
        self.assertEqual(self.client.get("/en/").status_code, 200)

    def test_home_es_200(self):
        self.assertEqual(self.client.get("/es/").status_code, 200)

    def test_root_redirects_by_language(self):
        self.assertEqual(self.client.get("/").status_code, 302)

    def test_robots_txt(self):
        r = self.client.get("/robots.txt")
        self.assertEqual(r.status_code, 200)
        self.assertIn("Sitemap", r.content.decode())

    def test_sitemap_xml(self):
        self.assertEqual(self.client.get("/sitemap.xml").status_code, 200)

    def test_legacy_terms_redirects_permanently(self):
        r = self.client.get("/terms")
        self.assertEqual(r.status_code, 301)
        self.assertEqual(r.headers["Location"], "/en/terms-and-safety/")

    def test_legacy_booking_redirects(self):
        r = self.client.get("/booking")
        self.assertEqual(r.status_code, 301)
        self.assertEqual(r.headers["Location"], "/en/booking/")

    def test_styleguide_available_in_debug(self):
        # Styleguide доступен тільки з префіксом мови через i18n_patterns
        response = self.client.get("/en/styleguide/")
        self.assertEqual(response.status_code, 200)

    def test_hreflang_in_head(self):
        html = self.client.get("/en/").content.decode()
        self.assertIn('hreflang="es"', html)
        self.assertIn('hreflang="x-default"', html)
