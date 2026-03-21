// supabase_service.dart - Supabase Edge Function 연동 설정
// 실제 Supabase를 사용하지 않는 경우 아래 값을 비워두면 됩니다.

class SupabaseConfig {
  // Supabase 프로젝트 URL 및 Anon Key
  // 실제 키를 입력하면 Edge Function(이메일/결제 확인)이 활성화됩니다.
  static const String supabaseUrl = '';
  static const String supabaseAnonKey = '';

  /// Supabase가 설정되었는지 여부
  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
