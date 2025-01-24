from django.core.management.base import BaseCommand

from users.utils import create_user_yaml

class Command(BaseCommand):
    help = 'Create user.yaml file to be ingested by gen3'

    def handle(self, *args, **options):

        print(create_user_yaml())
