from django.db import migrations

def create_initial_settings(apps, schema_editor):
    AdminSettings = apps.get_model('api', 'AdminSettings')
    AdminSettings.objects.update_or_create(
        setting_key='moderation_threshold',
        defaults={
            'setting_value': '3',
            'description': 'Number of reports before auto-flag',
        }
    )
    AdminSettings.objects.update_or_create(
        setting_key='platform_name',
        defaults={
            'setting_value': 'Neqat',
            'description': 'Platform display name',
        }
    )

class Migration(migrations.Migration):
    dependencies = [
        ('api', '0018_systemlog_outcome'),
    ]
    operations = [
        migrations.RunPython(create_initial_settings),
    ] 