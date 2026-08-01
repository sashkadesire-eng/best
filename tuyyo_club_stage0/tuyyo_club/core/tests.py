from django.test import TestCase, override_settings


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

    def test_legacy_terms_redirects(self):
        self.assertEqual(self.client.get("/terms").status_code, 302)

    def test_booking_placeholder(self):
        self.assertEqual(self.client.get("/en/booking/").status_code, 200)

    @override_settings(DEBUG=True)
    def test_styleguide_available_in_debug(self):
        self.assertEqual(self.client.get("/en/styleguide/").status_code, 200)

    def test_hreflang_in_head(self):
        html = self.client.get("/en/").content.decode()
        self.assertIn('hreflang="es"', html)
        self.assertIn('hreflang="x-default"', html)
