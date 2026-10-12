// ===========================
// TELA DE CARREGAMENTO DO TIME (#4)
// ===========================
const SPLASH_TIMES = {
  "palmeiras": {
    cor1: "#00c853", cor2: "#ffffff",
    bg: "linear-gradient(135deg, #0a1a0a 0%, #0d2a0d 50%, #0a1a0a 100%)",
    frases: ["O MAIOR CAMPEÃO DO BRASIL", "SOCIEDADE ESPORTIVA PALMEIRAS", "VERDÃO IMORTAL"],
    subtitulo: "BEM-VINDO, PALMEIRENSE!"
  },
  "flamengo": {
    cor1: "#e53935", cor2: "#000000",
    bg: "linear-gradient(135deg, #1a0808 0%, #2a0a0a 50%, #1a0808 100%)",
    frases: ["MENGÃO, O CLUBE DO POVO", "UMA VEZ FLAMENGO, SEMPRE FLAMENGO", "NAÇÃO RUBRO-NEGRA"],
    subtitulo: "BEM-VINDO, FLAMENGUISTA!"
  },
  "corinthians": {
    cor1: "#ffffff", cor2: "#888888",
    bg: "linear-gradient(135deg, #101010 0%, #1a1a1a 50%, #101010 100%)",
    frases: ["FIEL ATÉ O FIM", "SPORT CLUB CORINTHIANS PAULISTA", "O TIME DO POVO"],
    subtitulo: "BEM-VINDO, FIEL!"
  },
  "sao paulo": {
    cor1: "#e53935", cor2: "#ffffff",
    bg: "linear-gradient(135deg, #1a0808 0%, #0d0d1a 50%, #1a0808 100%)",
    frases: ["TRICOLOR CAMPEÃO MUNDIAL", "SÃO PAULO FUTEBOL CLUBE", "SOBERANO DO BRASIL"],
    subtitulo: "BEM-VINDO, SÃO-PAULINO!"
  },
  "santos": {
    cor1: "#f5f5f5", cor2: "#aaaaaa",
    bg: "linear-gradient(135deg, #0a0a12 0%, #12121a 50%, #0a0a12 100%)",
    frases: ["O REI DO FUTEBOL VEIO DAQUI", "SANTOS FUTEBOL CLUBE", "A VILA BELMIRO TE AGUARDA"],
    subtitulo: "BEM-VINDO, SANTISTA!"
  },
  "default": {
    cor1: "#00ff6a", cor2: "#00e5ff",
    bg: "linear-gradient(135deg, #0a0a0a 0%, #111418 50%, #0a0a0a 100%)",
    frases: ["BEM-VINDO AO CHAMPIONS CARD", "SEU INGRESSO COM DESCONTO", "FUTEBOL É PAIXÃO"],
    subtitulo: "BEM-VINDO!"
  }
};

function mostrarSplashTime(time, callback) {
  const cfg = SPLASH_TIMES[time] || SPLASH_TIMES["default"];

  const antigo = document.getElementById('splash-time');
  if (antigo) antigo.remove();

  const splash = document.createElement('div');
  splash.id = 'splash-time';
  splash.style.cssText = `
    position:fixed;top:0;left:0;width:100%;height:100%;z-index:9999;
    background:${cfg.bg};
    display:flex;flex-direction:column;align-items:center;justify-content:center;gap:24px;
    opacity:0;transition:opacity 0.5s ease;
  `;

  const logo = LOGOS_BASE64[time] ? logoHtmlBig(time, 90) : '';

  splash.innerHTML = `
    <style>
      @keyframes splashPulse { 0%,100%{transform:scale(1);} 50%{transform:scale(1.08);} }
      @keyframes splashFraseIn { from{opacity:0;transform:translateY(12px);} to{opacity:1;transform:translateY(0);} }
      .splash-frase { animation: splashFraseIn 0.6s ease forwards; }
    </style>
    ${logo}
    <p style="font-size:0.78rem;letter-spacing:4px;color:${cfg.cor2};opacity:0.7;">${cfg.subtitulo}</p>
    <div id="splash-frase-container" style="text-align:center;"></div>
    <div style="display:flex;gap:6px;margin-top:8px;">
      <div style="width:6px;height:6px;border-radius:50%;background:${cfg.cor1};animation:splashPulse 0.8s ease-in-out infinite;"></div>
      <div style="width:6px;height:6px;border-radius:50%;background:${cfg.cor1};animation:splashPulse 0.8s ease-in-out 0.2s infinite;"></div>
      <div style="width:6px;height:6px;border-radius:50%;background:${cfg.cor1};animation:splashPulse 0.8s ease-in-out 0.4s infinite;"></div>
    </div>
  `;
  document.body.appendChild(splash);
  requestAnimationFrame(() => { splash.style.opacity = '1'; });

  const fraseContainer = splash.querySelector('#splash-frase-container');
  let idx = 0;
  function mostrarFrase() {
    fraseContainer.innerHTML = `<p class="splash-frase" style="font-size:1.5rem;font-weight:900;letter-spacing:3px;color:${cfg.cor1};text-shadow:0 0 20px ${cfg.cor1}88;text-align:center;padding:0 24px;">${cfg.frases[idx]}</p>`;
    idx = (idx + 1) % cfg.frases.length;
  }
  mostrarFrase();
  const intervalo = setInterval(mostrarFrase, 900);

  setTimeout(() => {
    clearInterval(intervalo);
    splash.style.opacity = '0';
    setTimeout(() => {
      splash.remove();
      if (callback) callback();
    }, 500);
  }, 3000);
}

// ===========================
// TELA DE CONFIRMAÇÃO DE COMPRA (#5)
// ===========================
function mostrarTelaConfirmacao() {
  const time = estado.timeDoUsuario;
  const cfg  = SPLASH_TIMES[time] || SPLASH_TIMES["default"];

  const tela = document.getElementById('screen-confirmacao');
  if (!tela) return;

  const logoHtmlConfirm = LOGOS_BASE64[time] ? logoHtmlBig(time, 50) : '';

  tela.querySelector('#confirm-titulo').style.color = cfg.cor1;
  tela.querySelector('#confirm-titulo').style.textShadow = `0 0 20px ${cfg.cor1}66`;
  tela.querySelector('#confirm-subtitulo').style.color = '#ffffff';
  tela.querySelector('#confirm-logo-time').innerHTML = logoHtmlConfirm;

  irPara('screen-confirmacao');
}
