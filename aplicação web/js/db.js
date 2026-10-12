// ===========================
// LOCALSTORAGE — PERSISTÊNCIA
// ===========================
const DB_KEY = 'ticketfut_usuarios';

function carregarUsuariosDB() {
  const admin = {
    email: "admin@ticketfut.com", senha: "1234", plano: 0,
    time: "default", nome: "Admin", cpf: "",
    cartaoCredito: {}, cartaoDebito: {}, codigoSocio: null
  };
  try {
    const salvo = localStorage.getItem(DB_KEY);
    const lista = salvo ? JSON.parse(salvo) : [];
    const temAdmin = lista.find(u => u.email === admin.email);
    return temAdmin ? lista : [admin, ...lista];
  } catch {
    return [admin];
  }
}

function salvarUsuarioDB(usuario) {
  try {
    const salvo = localStorage.getItem(DB_KEY);
    const lista = salvo ? JSON.parse(salvo) : [];
    const idx = lista.findIndex(u => u.email === usuario.email);
    idx >= 0 ? lista[idx] = usuario : lista.push(usuario);
    localStorage.setItem(DB_KEY, JSON.stringify(lista));
  } catch (e) {
    console.error('Erro ao salvar no localStorage:', e);
  }
}

// ===========================
// CÓDIGO DE SÓCIO ÚNICO
// ===========================
function gerarCodigoSocio() {
  const letras = 'ABCDEFGHJKLMNPQRSTUVWXYZ';
  const nums   = '0123456789';
  const usuarios = carregarUsuariosDB();
  const codigosUsados = new Set(usuarios.map(u => u.codigoSocio).filter(Boolean));
  let codigo, tentativas = 0;
  do {
    const L = () => letras[Math.floor(Math.random() * letras.length)];
    const N = () => nums[Math.floor(Math.random() * nums.length)];
    codigo = `${L()}${L()}${L()}${N()}${N()}${N()}`;
    tentativas++;
  } while (codigosUsados.has(codigo) && tentativas < 1000);
  return codigo;
}
