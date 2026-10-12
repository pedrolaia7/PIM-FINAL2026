// ===========================
// TELA 2: CADASTRO
// ===========================
const TIME_CLASSES = {
  "palmeiras":   "time-palmeiras",
  "flamengo":    "time-flamengo",
  "corinthians": "time-corinthians",
  "sao paulo":   "time-sao-paulo",
  "santos":      "time-santos",
};

document.getElementById('cad-plano').addEventListener('change', function () {
  const secao = document.getElementById('secao-pagamento-cadastro');
  const plano = parseInt(this.value);
  if (plano > 0) {
    secao.classList.remove('hidden');
    document.getElementById('cad-bloco-pix').classList.add('hidden');
    const btnPix = document.getElementById('btn-pix-toggle');
    if (btnPix) { btnPix.classList.remove('ativo'); btnPix.textContent = 'PAGAR POR PIX'; }
  } else {
    secao.classList.add('hidden');
  }
  document.getElementById('cad-time').dispatchEvent(new Event('change'));
});

function togglePixCad() {
  const bloco = document.getElementById('cad-bloco-pix');
  const btn   = document.getElementById('btn-pix-toggle');
  const aberto = !bloco.classList.contains('hidden');
  bloco.classList.toggle('hidden', aberto);
  btn.classList.toggle('ativo', !aberto);
  btn.textContent = aberto ? 'PAGAR POR PIX' : 'FECHAR PIX';
}

document.getElementById('cad-time').addEventListener('change', function () {
  const sel = this;
  Object.values(TIME_CLASSES).forEach(c => sel.classList.remove(c));
  const timeNorm = normalizarTime(this.value);
  const classe   = TIME_CLASSES[timeNorm];
  const tema     = TEMAS_TIMES[timeNorm];
  const cor    = (classe && tema) ? tema.primary : 'var(--neon-cyan)';
  const bg     = (classe && tema) ? tema.bg      : 'rgba(0, 229, 255, 0.04)';
  const sombra = (classe && tema) ? `0 0 0 2px ${tema.primary}22` : '0 0 0 2px rgba(0,229,255,0.08)';
  if (classe && tema) sel.classList.add(classe);
  document.querySelectorAll('.secao-cartao').forEach(s => {
    s.style.borderColor = cor;
    s.style.background  = bg;
    s.style.boxShadow   = sombra;
    const label = s.querySelector('.label-pagamento');
    if (label) label.style.color = cor;
  });
  const btnPix = document.getElementById('btn-pix-toggle');
  if (btnPix) { btnPix.style.borderColor = cor; btnPix.style.color = cor; }
  const qrcode   = document.querySelector('#cad-bloco-pix .qrcode');
  const pixChave = document.querySelector('#cad-bloco-pix .pix-chave');
  if (qrcode)   qrcode.style.borderColor = cor;
  if (pixChave) pixChave.style.color = cor;
});

// ============================================================
// FUNÇÃO PRINCIPAL DE CADASTRO
// A função é async para poder checar duplicatas no SQL
// antes de avançar. Toda saída antecipada usa "return"
// garantindo que o usuário NUNCA avança sem estar liberado.
// ============================================================
async function finalizarCadastro() {
  const nome  = document.getElementById('cad-nome').value.trim();
  const cpf   = document.getElementById('cad-cpf').value.trim();
  const email = document.getElementById('cad-email').value.trim();
  const senha = document.getElementById('cad-senha').value.trim();
  const time  = document.getElementById('cad-time').value;
  const plano = parseInt(document.getElementById('cad-plano').value) || 0;

  // ── PASSO 1: Campos obrigatórios ──────────────────────────
  if (!nome || !cpf || !email || !senha || !time) {
    mostrarToast('Preencha todos os campos obrigatórios.', 'warning');
    return; // PARA — não avança
  }

  // ── PASSO 2: Duplicatas no localStorage ──────────────────
  const usuarios   = carregarUsuariosDB();
  const cpfExiste  = usuarios.find(u => u.cpf === cpf);
  const emailExiste = usuarios.find(u => u.email.toLowerCase() === email.toLowerCase());

  if (cpfExiste) {
    mostrarToast('Este CPF já está cadastrado.\nFaça login ou use outros dados.', 'error');
    return; // PARA — não avança
  }
  if (emailExiste) {
    mostrarToast('Este e-mail já está cadastrado.\nFaça login ou use outros dados.', 'error');
    return; // PARA — não avança
  }

  // ── PASSO 3: Duplicatas no banco SQL (se API online) ─────
  // Garante que cadastros feitos em outros dispositivos
  // também sejam detectados antes de avançar.
  const bloqueado = await _verificarDuplicataNoSQL(cpf, email);
  if (bloqueado) {
    return; // PARA — toast já exibido dentro da função
  }

  // ─── Liberado para cadastrar ──────────────────────────────

  const timeNorm = normalizarTime(time);
  const cartaoCredito = {
    numero:   document.getElementById('cad-credito-numero')?.value.trim()   || '',
    validade: document.getElementById('cad-credito-validade')?.value.trim() || '',
    cvv:      document.getElementById('cad-credito-cvv')?.value.trim()      || '',
  };
  const cartaoDebito = {
    numero:   document.getElementById('cad-debito-numero')?.value.trim()    || '',
    validade: document.getElementById('cad-debito-validade')?.value.trim()  || '',
    cvv:      document.getElementById('cad-debito-cvv')?.value.trim()       || '',
  };

  let codigoSocio = null;
  if (plano > 0) codigoSocio = gerarCodigoSocio();

  const novoUsuario = {
    nome, cpf, email, senha, plano,
    time: timeNorm,
    cartaoCredito,
    cartaoDebito,
    codigoSocio,
  };

  // Salva localmente (garante funcionamento do site)
  salvarUsuarioDB(novoUsuario);

  // Seta o estado da sessão
  estado.usuarioLogado = novoUsuario;
  estado.timeDoUsuario = timeNorm;
  aplicarTema(timeNorm);

  // Sincroniza com SQL em segundo plano (não bloqueia o fluxo)
  _sincronizarComBancoSQL(novoUsuario);

  // Exibe mensagem de sucesso e navega
  if (codigoSocio) {
    mostrarToast(`Cadastro realizado!\n🎫 SEU CÓDIGO DE SÓCIO: ${codigoSocio}\nAnote este código para usar nos ingressos.`, 'success');
  }

  setTimeout(() => {
    mostrarSplashTime(timeNorm, () => {
      carregarPartidas();
      irPara('screen-partidas');
    });
  }, codigoSocio ? 1800 : 300);
}

// ============================================================
// CHECA DUPLICATAS NO SQL ANTES DE AVANÇAR
// Retorna true  → bloqueado (duplicata encontrada)
// Retorna false → liberado  (ou API offline, usa só localStorage)
// ============================================================
async function _verificarDuplicataNoSQL(cpf, email) {
  try {
    const resposta = await fetch('http://localhost:5114/api/clientes', {
      method:  'GET',
      headers: { 'Content-Type': 'application/json' },
    });

    if (!resposta.ok) return false; // erro na API → não bloqueia

    const clientes = await resposta.json();

    const cpfNoSQL    = clientes.find(c => c.Cpf === cpf);
    const emailNoSQL  = clientes.find(c => c.Email?.toLowerCase() === email.toLowerCase());

    if (cpfNoSQL) {
      mostrarToast('Este CPF já está cadastrado no sistema.\nFaça login ou use outros dados.', 'error');
      return true; // BLOQUEIA
    }
    if (emailNoSQL) {
      mostrarToast('Este e-mail já está cadastrado no sistema.\nFaça login ou use outros dados.', 'error');
      return true; // BLOQUEIA
    }

    return false; // Tudo ok

  } catch (erro) {
    // API offline → checagem local já foi feita, libera
    console.warn('[SQL] API offline na verificação. Checagem local aplicada.', erro.message);
    return false;
  }
}

// ============================================================
// SINCRONIZA COM SQL EM SEGUNDO PLANO (silencioso)
// Envia todos os dados incluindo cartões.
// ============================================================
async function _sincronizarComBancoSQL(usuario) {
  try {
    const mapaPlano = { 0: '0', 5: 'Bronze', 10: 'Prata', 20: 'Ouro' };

    const dadosParaBanco = {
      Nome:  usuario.nome,
      Cpf:   usuario.cpf,
      Email: usuario.email,
      Senha: usuario.senha,
      Plano: mapaPlano[usuario.plano] ?? '0',
      Time:  usuario.time,
      NumeroCredito:   usuario.cartaoCredito?.numero   || '',
      ValidadeCredito: usuario.cartaoCredito?.validade || '',
      CvvCredito:      usuario.cartaoCredito?.cvv      || '',
      NumeroDebito:    usuario.cartaoDebito?.numero    || '',
      ValidadeDebito:  usuario.cartaoDebito?.validade  || '',
      CvvDebito:       usuario.cartaoDebito?.cvv       || '',
    };

    const resposta = await fetch('http://localhost:5114/api/clientes', {
      method:  'POST',
      headers: { 'Content-Type': 'application/json' },
      body:    JSON.stringify(dadosParaBanco),
    });

    if (resposta.ok) {
      console.log('[SQL] Cadastro sincronizado com sucesso.');
    } else {
      const resultado = await resposta.json();
      console.warn('[SQL] Erro ao sincronizar:', resultado?.erro || 'Erro desconhecido');
    }
  } catch (erro) {
    console.warn('[SQL] API offline. Dados salvos apenas localmente.', erro.message);
  }
}