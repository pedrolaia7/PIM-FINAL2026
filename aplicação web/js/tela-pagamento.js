// ===========================
// TELA 5: PAGAMENTO
// ===========================
function preencherCartaoSalvo(tipo) {
  const u = estado.usuarioLogado;
  if (!u) return;
  const cartao = tipo === 'credito' ? u.cartaoCredito : u.cartaoDebito;
  if (!cartao || !cartao.numero) return;
  const campos = document.querySelectorAll('#campos-cartao-compra .input-field');
  if (campos[0]) campos[0].value = cartao.numero;
  if (campos[1]) campos[1].value = cartao.validade;
  if (campos[2]) campos[2].value = cartao.cvv;
}

function selecionarMetodoCompra(metodo, btn) {
  estado.metodoPagamentoCompra = metodo;
  atualizarBotoesMetodo('metodos-compra', btn);
  alternarCamposPagamento('campos-cartao-compra', 'pix-compra', metodo);
  if (metodo === 'credito' || metodo === 'debito') preencherCartaoSalvo(metodo);
}

function confirmarCompra() {
  const metodo = estado.metodoPagamentoCompra;

  if (estado.usuarioLogado?.plano > 0) {
    const inputCodigo    = document.getElementById('input-codigo-socio');
    const codigoDigitado = inputCodigo?.value.trim().toUpperCase();
    const codigoCorreto  = estado.usuarioLogado?.codigoSocio;
    if (!codigoDigitado) {
      mostrarToast('Informe seu código de sócio para aplicar o desconto.', 'warning');
      return;
    }
    if (codigoDigitado !== codigoCorreto) {
      mostrarToast('Código de sócio incorreto.\nVerifique o código recebido no seu cadastro.', 'error');
      return;
    }
  }

  if (metodo === 'pix') {
    mostrarTelaConfirmacao();
  } else {
    const numero = document.querySelector('#campos-cartao-compra .input-field')?.value.trim();
    if (!numero) { mostrarToast('Preencha o número do cartão.', 'warning'); return; }
    mostrarTelaConfirmacao();
  }

  const inputCodigo = document.getElementById('input-codigo-socio');
  if (inputCodigo) inputCodigo.value = '';
}
