using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using System;
using System.Collections.Generic;
using System.Linq;

namespace PIM2026API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class ClientesController : ControllerBase
    {
        private readonly string _connectionString = "Server=localhost;Database=PIM2026;Trusted_Connection=True;TrustServerCertificate=True;";

        // 1. ROTA PARA LISTAR CLIENTES (GET)
        [HttpGet]
        public IActionResult ListarClientes()
        {
            var clientes = new List<object>();

            try
            {
                using (SqlConnection conn = new SqlConnection(_connectionString))
                {
                    conn.Open();
                    string sql = @"SELECT id, nome, cpf, email, time_coracao, tipo_socio, codigo_socio,
                                          numero_cartao_credito, validade_credito, cvv_credito,
                                          numero_cartao_debito, validade_debito, cvv_debito
                                   FROM SA1";

                    using (SqlCommand cmd = new SqlCommand(sql, conn))
                    {
                        using (SqlDataReader reader = cmd.ExecuteReader())
                        {
                            while (reader.Read())
                            {
                                clientes.Add(new
                                {
                                    Id = reader["id"],
                                    Nome = reader["nome"].ToString(),
                                    Cpf = reader["cpf"].ToString(),
                                    Email = reader["email"].ToString(),
                                    Time = reader["time_coracao"].ToString(),
                                    Plano = reader["tipo_socio"].ToString(),
                                    CodigoSocio = reader["codigo_socio"].ToString(),
                                    // Cartão de Crédito
                                    NumeroCredito = reader["numero_cartao_credito"] == DBNull.Value ? "" : reader["numero_cartao_credito"].ToString(),
                                    ValidadeCredito = reader["validade_credito"] == DBNull.Value ? "" : reader["validade_credito"].ToString(),
                                    CvvCredito = reader["cvv_credito"] == DBNull.Value ? "" : reader["cvv_credito"].ToString(),
                                    // Cartão de Débito
                                    NumeroDebito = reader["numero_cartao_debito"] == DBNull.Value ? "" : reader["numero_cartao_debito"].ToString(),
                                    ValidadeDebito = reader["validade_debito"] == DBNull.Value ? "" : reader["validade_debito"].ToString(),
                                    CvvDebito = reader["cvv_debito"] == DBNull.Value ? "" : reader["cvv_debito"].ToString(),
                                });
                            }
                        }
                    }
                }
                return Ok(clientes);
            }
            catch (Exception ex)
            {
                return BadRequest(new { mensagem = "Erro ao ler banco de dados", erro = ex.Message });
            }
        }

        // 2. ROTA PARA CADASTRAR CLIENTE (POST)
        [HttpPost]
        public IActionResult Cadastrar([FromBody] ClienteRequest novoCliente)
        {
            try
            {
                string codigoGerado = "N/A";

                if (novoCliente.Plano != "0")
                {
                    Random rand = new Random();
                    const string letras = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
                    const string numeros = "0123456789";

                    string parteLetras = new string(Enumerable.Repeat(letras, 3)
                        .Select(s => s[rand.Next(s.Length)]).ToArray());
                    string parteNumeros = new string(Enumerable.Repeat(numeros, 3)
                        .Select(s => s[rand.Next(s.Length)]).ToArray());

                    codigoGerado = parteLetras + parteNumeros;
                }

                using (SqlConnection conn = new SqlConnection(_connectionString))
                {
                    conn.Open();

                    string sql = @"INSERT INTO SA1 
                                    (nome, cpf, email, senha, socio, tipo_socio, codigo_socio, time_coracao,
                                     numero_cartao_credito, validade_credito, cvv_credito,
                                     numero_cartao_debito,  validade_debito,  cvv_debito)
                                   VALUES 
                                    (@nome, @cpf, @email, @senha, @socio, @tipo_socio, @codigo_socio, @time_coracao,
                                     @numero_cartao_credito, @validade_credito, @cvv_credito,
                                     @numero_cartao_debito,  @validade_debito,  @cvv_debito)";

                    using (SqlCommand cmd = new SqlCommand(sql, conn))
                    {
                        cmd.Parameters.AddWithValue("@nome", novoCliente.Nome);
                        cmd.Parameters.AddWithValue("@cpf", novoCliente.Cpf);
                        cmd.Parameters.AddWithValue("@email", novoCliente.Email);
                        cmd.Parameters.AddWithValue("@senha", novoCliente.Senha);
                        cmd.Parameters.AddWithValue("@socio", novoCliente.Plano != "0");
                        cmd.Parameters.AddWithValue("@tipo_socio", novoCliente.Plano);
                        cmd.Parameters.AddWithValue("@codigo_socio", codigoGerado);
                        cmd.Parameters.AddWithValue("@time_coracao", novoCliente.Time);

                        // Cartão de Crédito — salva NULL se vier vazio
                        cmd.Parameters.AddWithValue("@numero_cartao_credito",
                            string.IsNullOrWhiteSpace(novoCliente.NumeroCredito) ? (object)DBNull.Value : novoCliente.NumeroCredito);
                        cmd.Parameters.AddWithValue("@validade_credito",
                            string.IsNullOrWhiteSpace(novoCliente.ValidadeCredito) ? (object)DBNull.Value : novoCliente.ValidadeCredito);
                        cmd.Parameters.AddWithValue("@cvv_credito",
                            string.IsNullOrWhiteSpace(novoCliente.CvvCredito) ? (object)DBNull.Value : novoCliente.CvvCredito);

                        // Cartão de Débito — salva NULL se vier vazio
                        cmd.Parameters.AddWithValue("@numero_cartao_debito",
                            string.IsNullOrWhiteSpace(novoCliente.NumeroDebito) ? (object)DBNull.Value : novoCliente.NumeroDebito);
                        cmd.Parameters.AddWithValue("@validade_debito",
                            string.IsNullOrWhiteSpace(novoCliente.ValidadeDebito) ? (object)DBNull.Value : novoCliente.ValidadeDebito);
                        cmd.Parameters.AddWithValue("@cvv_debito",
                            string.IsNullOrWhiteSpace(novoCliente.CvvDebito) ? (object)DBNull.Value : novoCliente.CvvDebito);

                        cmd.ExecuteNonQuery();
                    }
                }

                return Ok(new { sucesso = true, mensagem = "Usuário cadastrado!", codigo = codigoGerado });
            }
            catch (Exception ex)
            {
                return BadRequest(new { sucesso = false, erro = ex.Message });
            }
        }
    }

    // Modelo recebido do formulário JS
    public class ClienteRequest
    {
        public string Nome { get; set; }
        public string Cpf { get; set; }
        public string Email { get; set; }
        public string Senha { get; set; }
        public string Plano { get; set; }
        public string Time { get; set; }

        // Cartão de Crédito
        public string NumeroCredito { get; set; }
        public string ValidadeCredito { get; set; }
        public string CvvCredito { get; set; }

        // Cartão de Débito
        public string NumeroDebito { get; set; }
        public string ValidadeDebito { get; set; }
        public string CvvDebito { get; set; }
    }
}