class ApiConfig {
  // Production Render Backend URL
  static const String baseUrl = 'https://learnyor-backend.onrender.com';

  // Staff and Auth are at the ROOT level
  static const String employeesUrl = '$baseUrl/employees';
  static const String internsUrl = '$baseUrl/interns';
  static const String authUrl = '$baseUrl/auth';
  static const String uploadUrl = '$baseUrl/upload';
  
  // Reports and Attendance are prefixed with /api
  static const String reportsUrl = '$baseUrl/api/reports';
  static const String attendanceUrl = '$baseUrl/attendance';
  static const String leavesUrl = '$baseUrl/api/leaves';

  static String getFullImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    if (path.startsWith('/') || path.contains(':\\') || path.startsWith('file:')) {
      return path;
    }
    return '$baseUrl$path';
  }
}
