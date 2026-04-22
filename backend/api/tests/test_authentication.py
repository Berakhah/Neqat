def test_protected_endpoint_requires_auth(api_client):
    response = api_client.get('/api/user/permissions/')
    assert response.status_code == 401
 
def test_protected_endpoint_with_valid_token(api_client, admin_token):
    api_client.credentials(HTTP_AUTHORIZATION=f'Bearer {admin_token}')
    response = api_client.get('/api/user/permissions/')
    assert response.status_code == 200
    assert 'roles' in response.data 