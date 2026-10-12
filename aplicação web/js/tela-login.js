// ===========================
// TELA 1: LOGIN
// ===========================
function fazerLogin() {
  const email = document.getElementById('login-email').value.trim();
  const senha = document.getElementById('login-senha').value.trim();
  if (!email || !senha) { mostrarToast('Preencha e-mail e senha.', 'warning'); return; }

  const usuarios = carregarUsuariosDB();
  const usuario  = usuarios.find(u => u.email === email && u.senha === senha);

  if (usuario) {
    estado.usuarioLogado = usuario;
    estado.timeDoUsuario = usuario.time || 'default';
    aplicarTema(estado.timeDoUsuario);
    mostrarSplashTime(estado.timeDoUsuario, () => {
      carregarPartidas();
      irPara('screen-partidas');
    });
  } else {
    mostrarToast('E-mail ou senha incorretos.', 'error');
  }
}

// --- PAINEL SÓCIO NO LOGIN ---
let planoLoginSelecionado = 0;

function toggleOpcaoSocioLogin() {
  const painel = document.getElementById('login-socio-painel');
  const btn    = document.getElementById('btn-toggle-socio-login');
  const aberto = painel.classList.contains('aberto');
  painel.classList.toggle('aberto', !aberto);
  btn.textContent = aberto ? 'QUERO SER SÓCIO' : 'FECHAR';
  planoLoginSelecionado = 0;
  if (!aberto) renderizarPlanosSocio();
}

function renderizarPlanosSocio() {
  const container = document.getElementById('login-planos-socio');
  const planos = [
    { valor: 5,  label: 'SÓCIO BRONZE', desc: '5% de desconto nos ingressos',  cor: '#cd7f32' },
    { valor: 10, label: 'SÓCIO PRATA',  desc: '10% de desconto nos ingressos', cor: '#aaaaaa' },
    { valor: 20, label: 'SÓCIO OURO',   desc: '20% de desconto nos ingressos', cor: '#ffc400' },
  ];
  container.innerHTML = planos.map(p => `
    <div class="plano-card" style="border-color:${p.cor}"
         onclick="selecionarPlanoLogin(${p.valor}, this, '${p.cor}')">
      <span class="plano-nome" style="color:${p.cor}">${p.label}</span>
      <span class="plano-desc">${p.desc}</span>
    </div>
  `).join('');
}

function selecionarPlanoLogin(valor, el, cor) {
  planoLoginSelecionado = valor;
  document.querySelectorAll('.plano-card').forEach(c => {
    c.style.background = 'var(--bg-item)';
  });
  el.style.background = cor + '20';
  document.getElementById('login-socio-pagamento').classList.remove('hidden');
  const primeiroBtn = document.querySelector('#login-metodos-adesao .btn-metodo');
  selecionarMetodoAdesaoLogin('credito', primeiroBtn);
}

function selecionarMetodoAdesaoLogin(metodo, btn) {
  estado.metodoPagamentoAdesao = metodo;
  atualizarBotoesMetodo('login-metodos-adesao', btn);
  const camposCartao = document.getElementById('login-campos-cartao-adesao');
  const camposPix    = document.getElementById('login-pix-adesao');
  if (metodo === 'pix') {
    camposCartao.style.display = 'none';
    camposPix.classList.remove('hidden');
  } else {
    camposCartao.style.display       = 'flex';
    camposCartao.style.flexDirection = 'column';
    camposCartao.style.gap           = '10px';
    camposPix.classList.add('hidden');
  }
}

function confirmarSocioLogin() {
  const email = document.getElementById('login-email').value.trim();
  const senha = document.getElementById('login-senha').value.trim();

  if (!email || !senha) { mostrarToast('Preencha seu e-mail e senha acima antes de assinar o plano.', 'warning'); return; }
  if (!planoLoginSelecionado) { mostrarToast('Selecione um plano de sócio.', 'warning'); return; }

  const usuarios = carregarUsuariosDB();
  const usuario  = usuarios.find(u => u.email === email && u.senha === senha);
  if (!usuario) { mostrarToast('E-mail ou senha incorretos. Verifique seus dados acima.', 'error'); return; }

  if (usuario.plano > 0) {
    mostrarToast(`Você já é sócio!\nSeu código: ${usuario.codigoSocio}\nPlano atual: ${usuario.plano}% de desconto.`, 'info');
    return;
  }

  const metodo = estado.metodoPagamentoAdesao;
  if (metodo !== 'pix') {
    const numeroEl = document.querySelector('#login-campos-cartao-adesao .input-field');
    if (!numeroEl || !numeroEl.value.trim()) { mostrarToast('Preencha o número do cartão.', 'warning'); return; }
  }

  const codigo = gerarCodigoSocio();
  usuario.plano       = planoLoginSelecionado;
  usuario.codigoSocio = codigo;
  salvarUsuarioDB(usuario);

  estado.usuarioLogado = usuario;
  estado.timeDoUsuario = usuario.time || 'default';
  aplicarTema(estado.timeDoUsuario);

  mostrarToast(`Parabéns! Você agora é sócio!\n🎫 SEU CÓDIGO: ${codigo}\nGuarde este código para usar nos ingressos.`, 'success');

  document.getElementById('login-socio-painel').classList.remove('aberto');
  document.getElementById('btn-toggle-socio-login').textContent = 'QUERO SER SÓCIO';

  setTimeout(() => {
    mostrarSplashTime(estado.timeDoUsuario, () => {
      carregarPartidas();
      irPara('screen-partidas');
    });
  }, 1500);
}
