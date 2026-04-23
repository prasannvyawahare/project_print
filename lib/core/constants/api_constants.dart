class ApiConstants {
  const ApiConstants._();

  static const String baseUrl = 'https://print-hub-xdgd.onrender.com/api/v1/';
  static const String verifyAndSaveUserPath = 'user/verify-and-save';

  static const String checkStorageExists = 'user/storage-exists';
  static const String createStorage = 'user/create-storage';
  static const String printTypePath = 'print-type/get';

  static const String uploadRequestPath = 'upload/request';
  static const String uploadCompletePath = 'upload/complete';

  // Keep existing demo endpoint working with an absolute URL.
  static const String welcomePath =
      'https://jsonplaceholder.typicode.com/posts/1';
}
