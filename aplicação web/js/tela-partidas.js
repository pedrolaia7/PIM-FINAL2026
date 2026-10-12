// ===========================
// TELA 3: PARTIDAS
// ===========================
function carregarPartidas() {
  const lista   = document.getElementById('lista-partidas');
  const noticia = document.getElementById('noticia-time');
  lista.innerHTML = '';
  if (noticia) noticia.textContent = obterNoticiaTime();

  const time = estado.timeDoUsuario;
  const partidasFiltradas = (time === 'default')
    ? PARTIDAS
    : PARTIDAS.filter(p => p.times.includes(time));

  if (partidasFiltradas.length === 0) {
    lista.innerHTML = `<p style="color:#888;text-align:center;padding:20px;font-size:0.85rem;letter-spacing:1px;">NENHUMA PARTIDA DISPONÍVEL PARA SEU TIME.</p>`;
    return;
  }

  const plano = estado.usuarioLogado?.plano || 0;

  partidasFiltradas.forEach(p => {
    const precoFinal = calcularPreco(p.preco);
    const item = document.createElement('div');
    item.className = 'partida-item';

    const [t1, t2] = p.times;
    const logo1 = logoHtml(t1, 18);
    const logo2 = logoHtml(t2, 18);

    const precoHtml = plano > 0
      ? `<span class="preco-original">R$ ${p.preco.toFixed(2).replace('.', ',')}</span> <span class="preco-desconto">R$ ${precoFinal.toFixed(2).replace('.', ',')} <span class="badge-desc">-${plano}%</span></span>`
      : `R$ ${precoFinal.toFixed(2).replace('.', ',')}`;

    item.innerHTML = `
      <p>${logo1}${t1.toUpperCase()} vs ${logo2}${t2.toUpperCase()}</p>
      <span>📅 ${p.data} &nbsp;⏰ ${p.hora} &nbsp;·&nbsp; ${precoHtml}</span>
    `;
    item.addEventListener('click', () => selecionarPartida(p));
    lista.appendChild(item);
  });
}

function selecionarPartida(partida) {
  estado.partidaSelecionada = partida;
  estado.ehVisitante = (partida.times[1] === estado.timeDoUsuario);
  atualizarMapaArena();
  irPara('screen-mapa');
}

function sair() {
  estado.usuarioLogado      = null;
  estado.timeDoUsuario      = 'default';
  estado.partidaSelecionada = null;
  estado.setorSelecionado   = null;
  aplicarTema('default');
  document.getElementById('login-email').value = '';
  document.getElementById('login-senha').value = '';
  irPara('screen-login');
}
