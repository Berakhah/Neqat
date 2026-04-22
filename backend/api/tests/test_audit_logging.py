def test_permission_denial_logged(api_client, user_token, post_not_owned_by_user):
    from api.models import SystemLog
    initial_count = SystemLog.objects.count()
    api_client.credentials(HTTP_AUTHORIZATION=f'Bearer {user_token}')
    response = api_client.patch(f'/api/posts/{post_not_owned_by_user.id}/', {'title': 'New Title'})
    assert response.status_code == 403
    assert SystemLog.objects.count() == initial_count + 1
    log = SystemLog.objects.latest('timestamp')
    assert 'PERMISSION_DENIED' in log.action 