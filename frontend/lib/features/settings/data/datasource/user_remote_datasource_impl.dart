import 'package:dio/dio.dart';
import 'package:frontend/features/settings/data/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';
import '../../domain/entities/user.dart';

class UserRemoteDataSourceImpl {
  final _dio = Dio();
  final _baseUrl = dotenv.env['django_api'] ?? 'http://127.0.0.1:8000';
  final _logger = Logger();

  Future<UserModel> getUserProfile() async {
    try {
      String? token = await SharedPreferences.getInstance().then(
        (prefs) => prefs.getString('access_token'),
      );

      _logger.i('Attempting to fetch user profile from: $_baseUrl/api/user/');
      _logger.i('Token available: ${token != null}');

      if (token == null) {
        throw Exception('Authentication Error: No access token found. Please log in again.');
      } else if (_baseUrl.isEmpty) {
         throw Exception('Configuration Error: Backend base URL is not set.');
      }

      final response = await _dio.get(
        '$_baseUrl/api/user/',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          validateStatus: (status) => status! < 500,
        ),
      );

      _logger.i('Response status code: ${response.statusCode}');
      _logger.i('Response data: ${response.data}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = Map<String, dynamic>.from(response.data);

        // Construct the full image URL here
        if (responseData.containsKey('profile_image') && responseData['profile_image'] is String && responseData['profile_image'].isNotEmpty) {
           String relativePath = responseData['profile_image'];
           // Ensure relative path doesn't start with a slash if baseUrl already has one
           if (relativePath.startsWith('/') && _baseUrl.endsWith('/')) {
               relativePath = relativePath.substring(1);
           }
           try {
               _logger.i('Base URL for image construction: $_baseUrl'); // Log base URL
               final baseUri = Uri.parse(_baseUrl);
               final fullUri = baseUri.resolve(relativePath); // Use resolve for robust path joining
                responseData['profile_image'] = fullUri.toString();
               _logger.i('Constructed full profile image URL using Uri.resolve: ${responseData['profile_image']}');
           } catch (e) {
               _logger.e('Error constructing profile image URL', error: e);
               // Keep original path or set to null on error
                // responseData['profile_image'] = null;
           }
        }

        _logger.i('Data being passed to UserModel.fromJson after URL construction: ${responseData}'); // Log data before parsing
        final user = UserModel.fromJson(responseData); // Pass the modified data
        return user;
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          error: 'Request failed with status code ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      _logger.e('DioException occurred', error: e, stackTrace: StackTrace.current);
      String errorMessage = 'Network Error: An unexpected error occurred.';
      if (e.response != null) {
        errorMessage = 'Server Error: ${e.response!.statusCode}';
        if (e.response!.data != null && e.response!.data is Map) {
           final responseData = e.response!.data as Map<String, dynamic>;
           _logger.e('Error response data: ${responseData}');
           if(responseData.containsKey('detail')){
              errorMessage = responseData['detail'].toString();
           } else if(responseData.containsKey('message')){
              errorMessage = responseData['message'].toString();
           } else if(responseData.containsKey('error')){
              errorMessage = responseData['error'].toString();
           } else if (responseData.isNotEmpty) { // Catch other non-empty error bodies
             errorMessage = 'Server Error: ${e.response!.statusCode}: ${responseData.toString()}';
          }
        } else if (e.response!.data != null) { // Catch non-Map error bodies
             errorMessage = 'Server Error: ${e.response!.statusCode}: ${e.response!.data.toString()}';
        }
      } else {
        errorMessage = 'Network Error: ${e.message}';
      }
      throw Exception(errorMessage);
    } catch (e, stackTrace) {
      _logger.e('Unexpected error occurred', error: e, stackTrace: stackTrace);
      throw Exception('An unexpected error occurred: ${e.toString()}');
    }
  }

  Future<void> updateUserProfile(UserModel user) async {
    try {
      String? token = await SharedPreferences.getInstance().then(
        (prefs) => prefs.getString('access_token'),
      );

      if (token == null) {
        throw Exception('Authentication Error: No access token found. Please log in again.');
      } else if (_baseUrl.isEmpty) {
         throw Exception('Configuration Error: Backend base URL is not set.');
      }

      final formData = FormData();

      // Add text fields
      formData.fields.addAll([
        MapEntry('user_name', user.username),
        MapEntry('first_name', user.first_name),
        MapEntry('last_name', user.last_name),
      ]);

      // Add password fields if provided
      if (user.new_password != null && user.new_password!.isNotEmpty) {
        formData.fields.add(MapEntry('new_password', user.new_password!));
      }
      if (user.confirm_password != null && user.confirm_password!.isNotEmpty) {
        formData.fields.add(MapEntry('confirm_password', user.confirm_password!));
      }

      // Add profile image if provided and it's a local file path
      if (user.profile_photo != null && user.profile_photo!.startsWith('/') && !user.profile_photo!.startsWith('http')) { // Check for relative path
        _logger.i('Uploading local profile image: ${user.profile_photo}');
        formData.files.add(
          MapEntry(
            'profile_image',
            await MultipartFile.fromFile(
              user.profile_photo!,
              filename: user.profile_photo!.split('/').last,
            ),
          ),
        );
      } else if (user.profile_photo == null || user.profile_photo!.isEmpty) { // If profile_photo is null or empty, indicate to remove it if backend supports
           _logger.i('Profile photo is null or empty. Sending empty string to potentially clear on backend.');
           // Send an empty string if the backend expects it to clear the image
            formData.fields.add(MapEntry('profile_image', ''));
      } else { // If profile_photo is a non-empty string and not a local path, assume it's an existing URL or not changed
           _logger.i('Profile image is an existing network URL or not changed: ${user.profile_photo}');
            // No need to add to formData if backend expects empty for no change / existing URL
      }

      _logger.i('Sending update request with data fields: ${formData.fields}');
      _logger.i('Sending update request with data files: ${formData.files.map((f) => f.value.filename)}');


      final response = await _dio.patch(
        '$_baseUrl/api/user/',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            // Dio automatically sets Content-Type to multipart/form-data for FormData
          },
          validateStatus: (status) => status! < 500,
        ),
      );

      _logger.i('Update response status code: ${response.statusCode}');
      _logger.i('Update response data: ${response.data}');

      if (response.statusCode == 200) {
         _logger.i('Profile updated successfully. Backend returned updated user data.');
         // The backend returns the updated user data, which will be fetched by the repository's getUser call after this method completes.
         // Optionally, you could parse the response data here and return it, then update the provider with that data.
         // However, re-fetching in the repository is already doing this.
         return; // Successfully updated
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          error: 'Request failed with status code ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      _logger.e('DioException occurred during update', error: e, stackTrace: StackTrace.current);
      String errorMessage = 'Network Error: An unexpected error occurred during update.';
      if (e.response != null) {
        errorMessage = 'Server Error: ${e.response!.statusCode}';
        if (e.response!.data != null && e.response!.data is Map) {
          final responseData = e.response!.data as Map<String, dynamic>;
          _logger.e('Error response data: ${responseData}');
          if (responseData.containsKey('detail')) {
            errorMessage = responseData['detail'].toString();
          } else if (responseData.containsKey('message')) {
            errorMessage = responseData['message'].toString();
          } else if (responseData.containsKey('error')) {
            errorMessage = responseData['error'].toString();
          } else if (responseData.isNotEmpty) { // Catch other non-empty error bodies
             errorMessage = 'Server Error: ${e.response!.statusCode}: ${responseData.toString()}';
          }
        } else if (e.response!.data != null) { // Catch non-Map error bodies
             errorMessage = 'Server Error: ${e.response!.statusCode}: ${e.response!.data.toString()}';
        }
      } else {
        errorMessage = 'Network Error: ${e.message}';
      }
      throw Exception(errorMessage);
    } catch (e, stackTrace) {
      _logger.e('Unexpected error occurred', error: e, stackTrace: stackTrace);
      throw Exception('An unexpected error occurred: ${e.toString()}');
    }
  }
}
