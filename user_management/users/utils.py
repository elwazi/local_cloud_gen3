from yaml import dump

from .models import Gen3Group, Gen3Resource, Gen3Policy, Gen3Role, Gen3Client, Gen3User

def create_user_yaml() -> str:
    the_dict = {
        'authz': {
            'anonymous_policies': [
                policy.id for policy in Gen3Policy.objects.filter(is_anonymous_policy=True)
            ],
            'all_users_policies': [
                policy.id for policy in Gen3Policy.objects.filter(is_all_users_policy=True)
            ],
            'groups': [
                group.to_dict for group in Gen3Group.objects.all()
            ],
            'resources': [
                resource.to_dict for resource in Gen3Resource.objects.filter(parent_resource=None)
            ],
            'policies': [
                policy.to_dict for policy in Gen3Policy.objects.all()
            ],
            'roles': [
                role.to_dict for role in Gen3Role.objects.all()
            ],
        },
        'clients': {
            client.name: {'policies': [policy.id for policy in client.policies.all()]} for client in Gen3Client.objects.all()
        },
        'users': {
            user.name: {
                'tags': user.tags,
                'policies': [policy.id for policy in user.policies.all()]
            } for user in Gen3User.objects.all()
        }
    }
    return dump(the_dict)
