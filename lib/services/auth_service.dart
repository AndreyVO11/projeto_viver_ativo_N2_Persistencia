import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/telefone_utils.dart';

/// Exceção com mensagem já traduzida para o vocabulário do DERS (RF001/RF002),
/// para que as telas exibam exatamente os textos especificados nos fluxos
/// alternativos, sem vazar mensagens técnicas do Supabase.
class AuthException implements Exception {
  final String message;
  AuthException(this.message);
}

/// O DERS especifica login/cadastro por número de telefone. Para evitar o
/// custo e a complexidade de um provedor de SMS real, o telefone é convertido
/// em um pseudo-email interno usado apenas pelo Supabase Auth (e-mail/senha).
/// O usuário nunca vê esse detalhe: a UI sempre trabalha com "telefone".
class AuthService {
  AuthService({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const _emailDomain = '@ders.app';

  String _telefoneParaEmail(String telefone) => '${normalizarTelefone(telefone)}$_emailDomain';

  /// O Supabase já abre uma sessão ao criar a conta. Durante o cadastro ela não
  /// conta como "logado": a pessoa só entra no app depois de fazer o login.
  bool _cadastrando = false;

  /// Emite true/false conforme o usuário está logado ou não.
  Stream<bool> get authStateChanges =>
      _client.auth.onAuthStateChange.map((estado) => estado.session != null && !_cadastrando);

  String? get currentUserId => _client.auth.currentUser?.id;

  /// RF001 - Fluxo básico de cadastro. A resposta da pergunta padrão de
  /// recuperação de senha é obrigatória para que a conta possa ser recuperada.
  ///
  /// Ao terminar, a sessão aberta pelo cadastro é encerrada: a pessoa volta à
  /// tela de login e entra com o telefone e a senha que acabou de criar.
  Future<void> cadastrar({
    required String nome,
    required String telefone,
    required String senha,
    required String respostaRecuperacao,
    required List<String> condicoesSaude,
  }) async {
    final telefoneNormalizado = normalizarTelefone(telefone);
    _cadastrando = true;
    try {
      final response = await _client.auth.signUp(
        email: _telefoneParaEmail(telefone),
        password: senha,
      );
      final uid = response.user!.id;

      await _client.from('usuarios').insert({
        'id': uid,
        'nome': nome,
        'telefone': telefoneNormalizado,
        'is_admin': false,
      });

      if (condicoesSaude.isNotEmpty) {
        final condicoes = await _client
            .from('condicoes_saude')
            .select('id')
            .inFilter('nome', condicoesSaude);
        if (condicoes.isNotEmpty) {
          await _client.from('usuario_condicao_saude').insert([
            for (final condicao in condicoes)
              {'usuario_id': uid, 'condicao_saude_id': condicao['id']},
          ]);
        }
      }

      await definirRespostaRecuperacao(respostaRecuperacao);
    } on AuthApiException catch (e) {
      throw AuthException(_mensagemCadastro(e));
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        // unique_violation na coluna telefone.
        throw AuthException('Este número já está cadastrado. Deseja fazer login?');
      }
      throw AuthException('Não foi possível concluir o cadastro. Tente novamente.');
    } finally {
      try {
        await _client.auth.signOut();
      } catch (_) {
        // Sem rede para avisar o servidor: o cadastro em si já foi (ou não) feito.
      }
      _cadastrando = false;
    }
  }

  /// RF008 - Cadastrar Administrador (Quadro 27/28), feito pelo administrador
  /// inicial sem deslogar a própria sessão.
  ///
  /// `signUp` troca a sessão ativa do cliente Supabase para a conta recém
  /// criada — por isso a sessão do administrador atual é guardada antes e
  /// restaurada no `finally`, mesmo se algo falhar no meio do caminho.
  Future<void> criarAdministrador({
    required String nome,
    required String telefone,
    required String senha,
  }) async {
    final sessaoAtual = _client.auth.currentSession;
    assert(sessaoAtual != null, 'Só o administrador logado pode cadastrar outro administrador.');

    try {
      try {
        final response = await _client.auth.signUp(
          email: _telefoneParaEmail(telefone),
          password: senha,
        );
        final uid = response.user!.id;
        await _client.from('usuarios').insert({
          'id': uid,
          'nome': nome,
          'telefone': normalizarTelefone(telefone),
          'is_admin': true,
          'is_admin_inicial': false,
        });
      } on AuthApiException catch (e) {
        throw AuthException(_mensagemCadastro(e));
      } on PostgrestException catch (e) {
        if (e.code == '23505') {
          throw AuthException('Este número já está cadastrado para outro administrador.');
        }
        throw AuthException('Não foi possível cadastrar o administrador. Tente novamente.');
      }
    } finally {
      if (sessaoAtual != null) {
        await _client.auth.setSession(sessaoAtual.refreshToken!);
      }
    }
  }

  /// RF002 - Fluxo básico de login.
  Future<void> login({required String telefone, required String senha}) async {
    try {
      await _client.auth.signInWithPassword(
        email: _telefoneParaEmail(telefone),
        password: senha,
      );
    } on AuthApiException catch (e) {
      throw AuthException(_mensagemLogin(e));
    }
  }

  Future<void> logout() => _client.auth.signOut();

  /// RF001, fluxo A3 - Recuperar senha, sem SMS: confere a resposta da pergunta
  /// padrão (guardada como hash no banco) e define a nova senha.
  Future<void> redefinirSenha({
    required String telefone,
    required String resposta,
    required String novaSenha,
  }) async {
    final String status;
    try {
      status = await _client.rpc('redefinir_senha_por_resposta', params: {
        'p_telefone': normalizarTelefone(telefone),
        'p_resposta': normalizarResposta(resposta),
        'p_nova_senha': novaSenha,
      }) as String;
    } on PostgrestException {
      throw AuthException('Não foi possível redefinir a senha. Tente novamente.');
    }
    switch (status) {
      case 'ok':
        return;
      case 'bloqueado':
        throw AuthException('Muitas tentativas incorretas. Tente novamente em 15 minutos.');
      case 'senha_invalida':
        throw AuthException('A senha deve ter ao menos 6 caracteres');
      default:
        throw AuthException(
          'Telefone ou resposta incorretos. Tente novamente.',
        );
    }
  }

  /// Cadastra (ou troca) a resposta de recuperação do usuário logado.
  Future<void> definirRespostaRecuperacao(String resposta) async {
    await _client.rpc('definir_resposta_recuperacao', params: {
      'p_resposta': normalizarResposta(resposta),
    });
  }

  /// Indica se o usuário logado já cadastrou a resposta de recuperação.
  Future<bool> temRespostaRecuperacao() async {
    final resultado = await _client.rpc('tem_resposta_recuperacao');
    return resultado == true;
  }

  /// RF001, fluxo A1 - troca o telefone usado para entrar no aplicativo.
  Future<void> alterarTelefoneLogin(String novoTelefone) async {
    final String status;
    try {
      status = await _client.rpc('alterar_telefone_login', params: {
        'p_novo_telefone': normalizarTelefone(novoTelefone),
      }) as String;
    } on PostgrestException {
      throw AuthException('Não foi possível alterar o telefone. Tente novamente.');
    }
    switch (status) {
      case 'ok':
        return;
      case 'telefone_em_uso':
        throw AuthException('Este número já está cadastrado em outra conta.');
      default:
        throw AuthException('Informe o telefone com DDD, por exemplo (64) 99999-9999');
    }
  }

  String _mensagemCadastro(AuthApiException e) {
    if (e.message.toLowerCase().contains('already registered') ||
        e.message.toLowerCase().contains('already exists')) {
      return 'Este número já está cadastrado. Deseja fazer login?';
    }
    if (e.message.toLowerCase().contains('password')) {
      return 'A senha informada é muito fraca. Escolha uma senha mais forte.';
    }
    return 'Não foi possível concluir o cadastro. Tente novamente.';
  }

  String _mensagemLogin(AuthApiException e) {
    return 'Número ou senha incorretos. Tente novamente.';
  }
}
