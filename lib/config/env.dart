/// Configuración que llega al compilar con `--dart-define-from-file=env.json`
/// (ver env.example.json). La publishable key es pública por diseño: lo que
/// protege los datos es RLS. Nunca poner aquí la secret key ni la service_role.
class Env {
  Env._();

  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabasePublishableKey =
      String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  static bool get configurado =>
      supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;
}
