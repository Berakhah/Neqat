def test_admin_access(api_client, admin_token):
    api_client.credentials(HTTP_AUTHORIZATION=f'Bearer {admin_token}')
    response = api_client.get('/api/user/permissions/')
    assert response.status_code == 200

def test_editor_denied_admin_access(api_client, editor_token):
    api_client.credentials(HTTP_AUTHORIZATION=f'Bearer {editor_token}')
    response = api_client.get('/api/admin-only-endpoint/')
    assert response.status_code == 403

def test_object_level_permission_owner(api_client, user_token, post_owned_by_user):
    api_client.credentials(HTTP_AUTHORIZATION=f'Bearer {user_token}')
    response = api_client.patch(f'/api/posts/{post_owned_by_user.id}/', {'title': 'New Title'})
    assert response.status_code in (200, 202)

def test_object_level_permission_non_owner(api_client, user_token, post_not_owned_by_user):
    api_client.credentials(HTTP_AUTHORIZATION=f'Bearer {user_token}')
    response = api_client.patch(f'/api/posts/{post_not_owned_by_user.id}/', {'title': 'New Title'})
    assert response.status_code == 403 