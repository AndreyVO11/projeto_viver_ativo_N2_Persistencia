/// Credenciais do projeto Supabase.
///
/// A anon key é uma chave pública (protegida pelas políticas de RLS do banco,
/// não por sigilo), então é seguro deixá-la embutida no código do app — é o
/// mesmo modelo de segurança da apiKey do Firebase.
///
/// SUBSTITUA os valores abaixo pelos do seu projeto em:
/// Supabase Dashboard > Project Settings > API.
class SupabaseConfig {
  SupabaseConfig._();

  static const String url = 'https://pxeqekmtjcedtjznyjgw.supabase.co';
  static const String anonKey = 'sb_publishable_CmdJJ0CYW2LxTFPiMCxUwQ_VOwhsBnm';
}
