"""routing URL Configuration

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/4.0/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  path('', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  path('', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.urls import include, path
    2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))
"""
from django.contrib import admin
from django.urls import path
from app import views

urlpatterns = [
    path('admin/', admin.site.urls),
    path('events/', views.events, name='events'),
    path('events/<slug:slug>/', views.events_detail, name='events_detail'),
    path('search/', views.search, name='search')
    #path('accounts/register/', views.register, name='register'),
    #path('accounts/logout/', views.logout, name='logout'),
    #path('accounts/login/', views.login, name='login'),
]
