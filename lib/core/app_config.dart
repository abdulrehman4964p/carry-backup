class AppConfig {
  static const appName = 'Forexlancer';
  static const baseUrl = 'https://forexlancer.com';
  static const homeUrl = '$baseUrl/';
  static const loginUrl = '$baseUrl/login/';
  static const signUpUrl = '$baseUrl/sign-up/';
  static const dashboardUrl = '$baseUrl/student-dashboard/';
  static const learningCenterUrl = '$baseUrl/learning-center/';
  static const myCoursesUrl = '$baseUrl/my-courses/';
  static const membershipsUrl = '$baseUrl/my-memberships/';
  static const freeCourseUrl = '$baseUrl/free-forex-course/';
  static const basicCourseUrl = '$baseUrl/forex-basic-course/';
  static const advanceCourseUrl = '$baseUrl/forex-advance-course/';
  static const signalsUrl = '$baseUrl/premium-forex-signals/';
  static const paymentHistoryUrl = '$baseUrl/payment-history/';
  static const certificatesUrl = '$baseUrl/my-certificates/';
  static const affiliateUrl = '$baseUrl/affiliate-program/';
  static const notificationsUrl = '$baseUrl/notifications/';
  static const supportUrl = '$baseUrl/support-center/';
  static const profileUrl = '$baseUrl/profile-settings/';
  static const tradingChartUrl = '$baseUrl/trading-chart/';
  static const technicalAnalysisUrl = '$baseUrl/technical-analysis/';
  static const fundamentalAnalysisUrl = '$baseUrl/fundamental-analysis/';
  static const forexNewsUrl = '$baseUrl/forex-news/';
  static const privacyUrl = '$baseUrl/privacy-policy/';
  static const termsUrl = '$baseUrl/terms-conditions/';
  static const riskWarningUrl = '$baseUrl/risk-warning/';

  static const allowedHosts = <String>{
    'forexlancer.com',
    'www.forexlancer.com',
  };
}
