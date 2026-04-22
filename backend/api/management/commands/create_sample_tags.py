from django.core.management.base import BaseCommand
from api.models import Tag

class Command(BaseCommand):
    help = 'Creates sample tags for testing'

    def handle(self, *args, **kwargs):
        # Define sample tags
        sample_tags = [
            {
                'name': 'Politics', 
                'description': 'News about politics, governance, and policy'
            },
            {
                'name': 'Business', 
                'description': 'News about companies, markets, and the economy'
            },
            {
                'name': 'Technology', 
                'description': 'News about innovations, gadgets, and tech companies'
            },
            {
                'name': 'Health', 
                'description': 'News about medicine, wellness, and healthcare'
            },
            {
                'name': 'Science',
                'description': 'News about scientific discoveries and research'
            },
            {
                'name': 'Sports',
                'description': 'News about various sports and athletics'
            },
            {
                'name': 'Entertainment',
                'description': 'News about celebrities, movies, music, and pop culture'
            },
            {
                'name': 'Education',
                'description': 'News about schools, universities, and learning'
            },
            {
                'name': 'Environment',
                'description': 'News about climate change and environmental issues'
            },
            {
                'name': 'World',
                'description': 'International news from around the globe'
            },
            {
                'name': 'top_headlines',
                'description': 'Top news headlines from major sources'
            }
        ]
        
        # Create tags
        created_count = 0
        existing_count = 0
        
        for tag_data in sample_tags:
            tag, created = Tag.objects.get_or_create(
                name=tag_data['name'],
                defaults={'description': tag_data.get('description', '')}
            )
            
            if created:
                created_count += 1
                self.stdout.write(self.style.SUCCESS(f'Created tag: {tag.name}'))
            else:
                existing_count += 1
                self.stdout.write(self.style.WARNING(f'Tag already exists: {tag.name}'))
        
        self.stdout.write(self.style.SUCCESS(
            f'Successfully created {created_count} tags. {existing_count} already existed.'
        ))