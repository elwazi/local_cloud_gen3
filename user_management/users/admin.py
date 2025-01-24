from django.contrib import admin

from .models import Gen3User, Gen3Group, Gen3Policy, Gen3Resource, Gen3Role, Gen3Permission, Gen3Action, Gen3Client

# Register your models here.

@admin.register(Gen3User)
class Gen3UserAdmin(admin.ModelAdmin):
    filter_horizontal = ('policies', )


@admin.register(Gen3Group)
class Gen3GroupAdmin(admin.ModelAdmin):
    filter_horizontal = ('policies', 'users')


@admin.register(Gen3Policy)
class Gen3PolicyAdmin(admin.ModelAdmin):
    filter_horizontal = ('roles', 'resources')


@admin.register(Gen3Resource)
class Gen3ResourceAdmin(admin.ModelAdmin):
    radio_fields = {'parent_resource': admin.VERTICAL}
    ordering = ['parent_resource__name', 'name']


@admin.register(Gen3Role)
class Gen3RoleAdmin(admin.ModelAdmin):
    filter_horizontal = ('permissions',)


@admin.register(Gen3Permission)
class Gen3PermissionAdmin(admin.ModelAdmin):
    radio_fields = {'action': admin.VERTICAL}


@admin.register(Gen3Action)
class Gen3ActionAdmin(admin.ModelAdmin):
    radio_fields = {'service': admin.VERTICAL}


@admin.register(Gen3Client)
class Gen3ClientAdmin(admin.ModelAdmin):
    filter_horizontal = ('policies', )


