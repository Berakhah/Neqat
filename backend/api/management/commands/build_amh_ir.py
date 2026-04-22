# api/management/commands/build_amh_ir.py

from django.core.management.base import BaseCommand
from api.telegram.amh_ir import build_index, INDEX_PATH


class Command(BaseCommand):
    help = "Build the Amharic TF–IDF index for TelegramMessages"

    def handle(self, *args, **options):
        self.stdout.write("🔨 Building Amharic IR index…")
        build_index()
        self.stdout.write(self.style.SUCCESS(f"✅ Index written to {INDEX_PATH}"))
