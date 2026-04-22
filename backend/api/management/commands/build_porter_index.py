# backend/api/management/commands/build_all_indexes.py

from django.core.management.base import BaseCommand
from api.news.porter_stemmer   import build_index as build_news,   INDEX_PATH as NEWS_PATH
from api.telegram.amh_ir       import build_index as build_amhir, INDEX_PATH as AMH_PATH

class Command(BaseCommand):
    help = "Build both the News TF–IDF index and the Amharic IR index"

    def handle(self, *args, **options):
        self.stdout.write("🔨 Building News index…")
        build_news()
        self.stdout.write(self.style.SUCCESS(f"✅ News index at {NEWS_PATH}"))

        self.stdout.write("🔨 Building Amharic IR index…")
        build_amhir()
        self.stdout.write(self.style.SUCCESS(f"✅ Amharic IR index at {AMH_PATH}"))
