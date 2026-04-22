from .models import NeqatUser

def create_neqat_user(strategy, details, backend, user=None, *args, **kwargs):
    if user:
        return {'is_new': False}
    email = details.get('email')
    if not email:
        return {'is_new': False, 'error': 'Email is required for registration'}

    username = details.get('username') or email.split('@')[0]
    # Ensure username is unique
    base_username = username
    counter = 1
    while NeqatUser.objects.filter(user_name=username).exists():
        username = f"{base_username}{counter}"
        counter += 1

    fields = {
        'user_name': username,
        'email': email,
        'first_name': details.get('first_name', ''),
        'last_name': details.get('last_name', ''),
    }
    user = NeqatUser.objects.create_user(**fields)
    return {'is_new': True, 'user': user}