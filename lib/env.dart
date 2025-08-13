import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static Future<void> load() async {
    await dotenv.load(fileName: ".env");
  }

  static String get webApiKey => dotenv.env['WEB_API_KEY']!;
  static String get webAppId => dotenv.env['WEB_APP_ID']!;
  static String get webMessagingSenderId => dotenv.env['WEB_MESSAGING_SENDER_ID']!;
  static String get webProjectId => dotenv.env['WEB_PROJECT_ID']!;
  static String get webAuthDomain => dotenv.env['WEB_AUTH_DOMAIN']!;
  static String get webDatabaseUrl => dotenv.env['WEB_DATABASE_URL']!;
  static String get webStorageBucket => dotenv.env['WEB_STORAGE_BUCKET']!;
  static String get webMeasurementId => dotenv.env['WEB_MEASUREMENT_ID']!;
  static String? get webRecaptchaV3SiteKey => dotenv.env['WEB_RECAPTCHA_V3_SITE_KEY'];
  static String get androidApiKey => dotenv.env['ANDROID_API_KEY']!;
  static String get androidAppId => dotenv.env['ANDROID_APP_ID']!;
  static String get androidMessagingSenderId => dotenv.env['ANDROID_MESSAGING_SENDER_ID']!;
  static String get androidProjectId => dotenv.env['ANDROID_PROJECT_ID']!;
  static String get androidDatabaseUrl => dotenv.env['ANDROID_DATABASE_URL']!;
  static String get androidStorageBucket => dotenv.env['ANDROID_STORAGE_BUCKET']!;
  static String get iosApiKey => dotenv.env['IOS_API_KEY']!;
  static String get iosAppId => dotenv.env['IOS_APP_ID']!;
  static String get iosMessagingSenderId => dotenv.env['IOS_MESSAGING_SENDER_ID']!;
  static String get iosProjectId => dotenv.env['IOS_PROJECT_ID']!;
  static String get iosDatabaseUrl => dotenv.env['IOS_DATABASE_URL']!;
  static String get iosStorageBucket => dotenv.env['IOS_STORAGE_BUCKET']!;
  static String get iosBundleId => dotenv.env['IOS_BUNDLE_ID']!;
}