from rest_framework.permissions import BasePermission
from api.constants import KeycloakRoles
from api.utils import log_permission_denial

class IsAdmin(BasePermission):
    """
    Allows access only to users with the admin role.
    """
    def has_permission(self, request, view):
        user = request.user
        # Check both Django superuser and Keycloak admin role
        if hasattr(user, 'is_superuser') and user.is_superuser:
            return True
        roles = getattr(user, 'roles', [])
        allowed = KeycloakRoles.ADMIN in roles or KeycloakRoles.REALM_ADMIN in roles
        if not allowed:
            log_permission_denial(request, 'PERMISSION_DENIED', f"IsAdmin: User denied admin access to {view.__class__.__name__}")
        return allowed

class IsEditor(BasePermission):
    """
    Allows access only to users with the admin role (was editor).
    """
    def has_permission(self, request, view):
        user = request.user
        roles = getattr(user, 'roles', [])
        allowed = KeycloakRoles.ADMIN in roles
        if not allowed:
            log_permission_denial(request, 'PERMISSION_DENIED', f"IsEditor: User denied admin access to {view.__class__.__name__}")
        return allowed

class HasKeycloakRole(BasePermission):
    """
    Allows access only to users with a specific Keycloak role.
    Set required_role as a class attribute or on the view.
    """
    required_role = None

    def has_permission(self, request, view):
        user = request.user
        roles = getattr(user, 'roles', [])
        required_role = getattr(self, 'required_role', None) or getattr(view, 'required_role', None)
        allowed = required_role in roles if required_role else False
        if not allowed:
            log_permission_denial(request, 'PERMISSION_DENIED', f"HasKeycloakRole: User denied role '{required_role}' access to {view.__class__.__name__}")
        return allowed

class IsOwnerOrAdmin(BasePermission):
    """
    Object-level permission to only allow owners of an object or admins to edit/delete it.
    """
    def has_object_permission(self, request, view, obj):
        roles = getattr(request.user, 'roles', [])
        if 'admin' in roles or 'realm-admin' in roles:
            return True
        is_owner = hasattr(obj, 'created_by') and obj.created_by == request.user
        if not is_owner:
            log_permission_denial(request, 'PERMISSION_DENIED', f"IsOwnerOrAdmin: User denied object-level permission for {obj.__class__.__name__} (id={getattr(obj, 'id', None)})")
        return is_owner 