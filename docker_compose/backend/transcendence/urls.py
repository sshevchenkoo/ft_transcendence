from django.contrib import admin
from django.urls import path, include

#admin.site.register(Message)

urlpatterns = [
    path("admin/", admin.site.urls),
    path("", include("core.urls")),
]
