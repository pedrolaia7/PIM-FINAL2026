// ===========================
// ESTADO GLOBAL
// ===========================
let estado = {
  usuarioLogado:         null,
  timeDoUsuario:         'default',
  partidaSelecionada:    null,
  setorSelecionado:      null,
  metodoPagamentoAdesao: 'credito',
  metodoPagamentoCompra: 'credito',
  ehVisitante:           false,
};

// ===========================
// TOAST — NOTIFICAÇÕES (#1)
// ===========================
function mostrarToast(msg, tipo = 'info') {
  const existente = document.getElementById('toast-global');
  if (existente) existente.remove();

  const icones = { success: '✅', error: '❌', warning: '⚠️', info: 'ℹ️' };
  const icone = icones[tipo] || 'ℹ️';

  const toast = document.createElement('div');
  toast.id = 'toast-global';
  toast.className = `toast toast-${tipo}`;
  toast.innerHTML = `
    <span class="toast-icon">${icone}</span>
    <span class="toast-msg">${msg.replace(/\n/g, '<br>')}</span>
    <button class="toast-close" onclick="this.parentElement.remove()">✕</button>
  `;
  document.body.appendChild(toast);

  requestAnimationFrame(() => toast.classList.add('toast-show'));

  setTimeout(() => {
    toast.classList.remove('toast-show');
    setTimeout(() => toast.remove(), 400);
  }, 4000);
}

// ===========================
// NAVEGAÇÃO
// ===========================
const _historico = [];

function irPara(id, adicionarHistorico = true) {
  const telaAtual = document.querySelector('.screen.active');
  if (adicionarHistorico && telaAtual) _historico.push(telaAtual.id);
  document.querySelectorAll('.screen').forEach(s => s.classList.remove('active'));
  document.getElementById(id).classList.add('active');
  window.scrollTo({ top: 0, behavior: 'smooth' });
}

window.addEventListener('popstate', function () {
  const anterior = _historico.pop();
  if (anterior) irPara(anterior, false);
});
history.pushState(null, '', window.location.href);

// ===========================
// UTILITÁRIOS GERAIS
// ===========================
function calcularPreco(precoBase) {
  const desconto = estado.usuarioLogado?.plano || 0;
  return precoBase * (1 - desconto / 100);
}

function atualizarBotoesMetodo(containerId, btnAtivo) {
  document.querySelectorAll(`#${containerId} .btn-metodo`).forEach(b => b.classList.remove('active'));
  if (btnAtivo) btnAtivo.classList.add('active');
}

function alternarCamposPagamento(idCartao, idPix, metodo) {
  const camposCartao = document.getElementById(idCartao);
  const camposPix    = document.getElementById(idPix);
  if (metodo === 'pix') {
    camposCartao.style.display = 'none';
    camposPix.classList.remove('hidden');
  } else {
    camposCartao.style.display       = 'flex';
    camposCartao.style.flexDirection = 'column';
    camposCartao.style.gap           = '12px';
    camposPix.classList.add('hidden');
  }
}

function normalizarTime(time) {
  return time.toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g, '');
}

// ===========================
// MÁSCARAS DE CARTÃO
// ===========================
function aplicarMascarasCartao() {
  ['cad-credito-numero', 'cad-debito-numero'].forEach(id => {
    document.getElementById(id)?.addEventListener('input', function () {
      let v = this.value.replace(/\D/g, '').slice(0, 16);
      this.value = v.replace(/(.{4})/g, '$1 ').trim();
    });
  });
  ['cad-credito-validade', 'cad-debito-validade'].forEach(id => {
    document.getElementById(id)?.addEventListener('input', function () {
      let v = this.value.replace(/\D/g, '').slice(0, 4);
      if (v.length > 2) v = v.slice(0, 2) + '/' + v.slice(2);
      this.value = v;
    });
  });
  ['cad-credito-cvv', 'cad-debito-cvv'].forEach(id => {
    document.getElementById(id)?.addEventListener('input', function () {
      this.value = this.value.replace(/\D/g, '').slice(0, 4);
    });
  });
}

// ===========================
// ANIMAÇÃO LOGO NO HOVER (#3)
// ===========================
function inicializarLogoHover() {
  const logo = document.querySelector('.logo-champions');
  if (!logo) return;
  logo.addEventListener('mouseenter', () => {
    logo.classList.remove('logo-hover-anim');
    void logo.offsetWidth;
    logo.classList.add('logo-hover-anim');
  });
  logo.addEventListener('animationend', (e) => {
    if (e.animationName === 'logoHoverBounce') {
      logo.classList.remove('logo-hover-anim');
    }
  });
}
