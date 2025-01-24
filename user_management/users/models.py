from django.contrib.postgres.fields import HStoreField
from django.db import models
from django.utils.translation import gettext_lazy as _

# Create your models here.


class Gen3GroupManager(models.Manager):
    def get_by_natural_key(self, name):
        return self.get(name=name)


class Gen3Group(models.Model):
    name = models.CharField(max_length=255, primary_key=True)
    policies = models.ManyToManyField('Gen3Policy')
    users = models.ManyToManyField('Gen3User')

    objects = Gen3GroupManager()

    def __str__(self):
        return self.name

    @property
    def to_dict(self) -> dict:
        return {
            'name': self.name,
            'policies': [policy.id for policy in self.policies.all()],
            'users': [user.name for user in self.users.all()]
        }

    def natural_key(self):
        return (self.name,)

    class Meta:
        ordering = ['name']


class Gen3ResourceManager(models.Manager):
    def get_by_natural_key(self, name, parent_resource):
        if parent_resource:
            return self.get(name=name, parent_resource=self.get_by_natural_key(*parent_resource))
        return self.get(name=name, parent_resource=None)


class Gen3Resource(models.Model):
    name = models.CharField(max_length=255)
    parent_resource = models.ForeignKey('self', on_delete=models.CASCADE, blank=True, null=True, related_name='subresources')

    objects = Gen3ResourceManager()

    @property
    def path(self):
        if self.parent_resource:
            return f'{self.parent_resource.path}/{self.name}'
        return f'/{self.name}'

    def __str__(self):
        return self.path

    @property
    def to_dict(self) -> dict:
        the_dict = {
            'name': self.name,
        }
        sub_resources = []
        for sub_resource in self.subresources.all():
            sub_resources.append(sub_resource.to_dict)
        if sub_resources:
            the_dict['subresources'] = sub_resources
        return the_dict

    def natural_key(self):
        if self.parent_resource:
            return (self.name, self.parent_resource.natural_key())
        return (self.name, )

    class Meta:
        ordering = ['parent_resource__name', 'name']
        constraints = [
            models.UniqueConstraint(fields=['name', 'parent_resource'], name='unique_resource_name')
        ]


class Gen3PolicyManager(models.Manager):
    def get_by_natural_key(self, id):
        return self.get(id=id)


class Gen3Policy(models.Model):
    id = models.CharField(max_length=255, primary_key=True)
    description = models.CharField(max_length=255, blank=True)
    roles = models.ManyToManyField('Gen3Role', blank=True)
    resources = models.ManyToManyField('Gen3Resource', blank=True)
    is_anonymous_policy = models.BooleanField(default=False)
    is_all_users_policy = models.BooleanField(default=False)

    objects = Gen3PolicyManager()

    def __str__(self):
        return self.id

    @property
    def to_dict(self) -> dict:
        the_dict = {
            'id': self.id,
            'description': self.description,
            'role_ids': [role.id for role in self.roles.all()],
            'resource_paths': [resource.path for resource in self.resources.all()],
        }
        if not self.description:
            del the_dict['description']
        return the_dict

    def natural_key(self):
        return (self.id,)

    class Meta:
        verbose_name_plural = 'Gen3 policies'
        ordering = ['id']


class Gen3RoleManager(models.Manager):
    def get_by_natural_key(self, id):
        return self.get(id=id)


class Gen3Role(models.Model):
    id = models.CharField(max_length=255, primary_key=True)
    description = models.CharField(max_length=255, blank=True)
    permissions = models.ManyToManyField('Gen3Permission')

    objects = Gen3RoleManager()

    def __str__(self):
        return f'{self.id}: {"; ".join(str(permission) for permission in self.permissions.all())}'

    @property
    def to_dict(self) -> dict:
        the_dict = {
            'id': self.id,
            'description': self.description,
            'permissions': [permission.to_dict for permission in self.permissions.all()],
        }
        if not self.description:
            del the_dict['description']
        return the_dict

    def natural_key(self):
        return (self.id,)

    class Meta:
        ordering = ['id']


class Gen3PermissionManager(models.Manager):
    def get_by_natural_key(self, id):
        return self.get(id=id)


class Gen3Permission(models.Model):
    id = models.CharField(max_length=255, primary_key=True)
    action = models.ForeignKey('Gen3Action', on_delete=models.CASCADE)

    objects = Gen3PermissionManager()

    def __str__(self):
        return f'{self.id} : {self.action}'

    @property
    def to_dict(self) -> dict:
        return {
            'id': self.id,
            'action': self.action.to_dict,
        }

    def natural_key(self):
        return (self.id,)

    class Meta:
        ordering = ['id']


class Gen3ActionManager(models.Manager):
    def get_by_natural_key(self, service, action):
        return self.get(service=service, action=action)


class Gen3Action(models.Model):
    class Methods(models.TextChoices):
        ACCESS = 'AC', _('access')
        ALL = 'AL', _('*')
        CREATE = 'CR', _('create')
        DELETE = 'DL', _('delete')
        FILE_UPLOAD = 'FU', _('file_upload')
        READ = 'RD', _('read')
        READ_STORAGE = 'RS', _('read-storage')
        UPDATE = 'UP', _('update')
        WRITE_STORAGE = 'WS', _('write-storage')

    service = models.ForeignKey('Gen3Resource', on_delete=models.CASCADE)
    action = models.CharField(max_length=2, choices=Methods.choices, default=Methods.ALL)

    def __str__(self):
        return f'{self.service} ({self.get_action_display()})'

    @property
    def to_dict(self) -> dict:
        return {
            'service': self.service.name,
            'method': self.get_action_display(),
        }

    def natural_key(self):
        return (self.service.name, self.action)

    class Meta:
        ordering = ['service', 'action']
        constraints = [
            models.UniqueConstraint(fields=['service', 'action'], name='unique_action')
        ]


class Gen3ClientManager(models.Manager):
    def get_by_natural_key(self, name):
        return self.get(name=name)


class Gen3Client(models.Model):
    name = models.CharField(max_length=255, primary_key=True)
    policies = models.ManyToManyField('Gen3Policy')

    def __str__(self):
        return self.name

    @property
    def to_dict(self):
        return {
            'name': self.name,
            'policies': [policy.id for policy in self.policies.all()],
        }

    def natural_key(self):
        return (self.name,)

    class Meta:
        ordering = ['name']


class Gen3UserManager(models.Manager):
    def get_by_natural_key(self, name):
        return self.get(name=name)


class Gen3User(models.Model):
    name = models.CharField(max_length=255, primary_key=True)
    policies = models.ManyToManyField('Gen3Policy')
    tags = HStoreField(blank=True, null=True)

    def __str__(self):
        return self.name


    @property
    def to_dict(self):
        return {
            f'{self.name}': {
                'policies': [policy.id for policy in self.policies.all()],
                'tags': self.tags,
            }
        }

    def natural_key(self):
        return (self.name,)

    class Meta:
        ordering = ['name']


class Gen3Program(models.Model):
    projects = models.ManyToManyField('Gen3Project')


class Gen3Project(models.Model):
    pass
