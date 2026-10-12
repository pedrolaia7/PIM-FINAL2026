# TicketFut — Flutter + .NET + Python (reconhecimento facial)

Versão mobile do projeto web `PIM-FINAL2026`: login, partidas, mapa da arena, pagamento e **biometria**
(login rápido, cadastro facial e confirmação de compra).

```
Flutter App ──HTTPS/JWT──▶ Backend C# (.NET 8) ──rede interna + API key──▶ Microsserviço Python (FastAPI)
                                │                                              │
                           SQL Server                                  compara rostos (ArcFace)
                    (usuários, partidas, pagamentos,                   não guarda nada
                     embedding faciais criptografados)
```
**O app nunca fala com o Python.** Só o C# chama o serviço de IA e decide o resultado.

## Pastas
| Pasta | O que é |
|---|---|
| `flutter_app/` | App Flutter (`core/ data/ domain/ presentation/{auth,home,map,checkout}`) |
| `backend/` | API .NET 8 em Clean Architecture: `Domain → Application → Infrastructure → Api` (+ testes de domínio) |
| `face-service/` | Microsserviço FastAPI: `/v1/faces/enroll` e `/v1/faces/verify` (+ testes) |
| `docker-compose.yml` | SQL Server + API + face-service |

## Subir tudo
```bash
cp .env.example .env        # troque as senhas/chaves
docker compose up --build   # API em http://localhost:8080 (Swagger em /swagger)
```
Login de desenvolvimento (só em `Development`): `admin@ticketfut.com` / `Admin@1234` (vê todos os jogos).

Sem Docker: `cd face-service && pip install -r requirements-dev.txt && EMBEDDER=mock uvicorn app.main:app` e
`cd backend/src/TicketFut.Api && dotnet run` (veja `appsettings.Development.json`). Depois configure o Flutter em
`flutter_app/platform_setup/README.md`.

## Como as regras do app web foram portadas
- Times, cores, textos de boas-vindas e notícias por time → `core/theme/team_theme.dart`.
- Partidas, preços e horários → `DbSeeder` (as datas de maio/2026 já passaram; o seed reaproveita o espaçamento
  a partir do próximo domingo).
- Planos Bronze/Prata/Ouro = 5/10/20% de desconto; **código de sócio** (3 letras + 3 dígitos) exigido na compra.
- Mapa da arena: **mandante nunca no LESTE; visitante só no LESTE** (aplicado no servidor e na UI).
- "Mapa" agora também mostra o estádio (OpenStreetMap), distância do usuário e rota.

## Biometria: o que cada camada garante
| Fluxo | Mecanismo | Observação |
|---|---|---|
| Login rápido | `local_auth` destrava o refresh token guardado no Keychain/Keystore | Conveniência; o servidor não "vê" a biometria |
| Cadastro facial | selfie → C# → Python → **embedding** criptografado (AES-GCM) | A foto não é armazenada |
| Confirmar compra | biometria nativa **+ selfie verificada no servidor** | O servidor decide; o app não consegue "forjar" aprovação |

Em compras, o backend exige o `nonce` da intenção, limita tentativas (5), expira a intenção em 10 min e só então cobra.

## ⚠️ Antes de ir para produção
1. **Prova de vida (liveness) NÃO está implementada** (`face-service/app/services/liveness.py` é um ponto de extensão).
   Sem ela, uma foto impressa ou na tela pode passar. Implemente um provedor e ligue `Face__Policy__RequireLivenessForPayment=true`.
2. **Gateway de pagamento é sandbox** (`SandboxPaymentGateway`) e o app usa `SandboxCardTokenizer`. Troque pelo SDK de um
   gateway real (tokenização no app); cartão/CVV nunca devem chegar ao seu backend. Cartões terminados em `0000` simulam recusa.
3. **Limiares** (`THRESHOLD_LOGIN/PAYMENT`) precisam ser calibrados com dados reais (falsa aceitação × falsa rejeição).
   A "porcentagem" retornada é similaridade de cosseno, não probabilidade de ser a mesma pessoa.
4. **LGPD**: dado biométrico é sensível. Há consentimento no cadastro e `DELETE /api/auth/face` para exclusão; revise
   política de privacidade, retenção e base legal com seu jurídico.
5. HTTPS obrigatório, segredos fora do repositório (`.env`, user-secrets), migrations do EF em vez de `EnsureCreated`,
   preços dos planos (`MemberPlans`) são valores de exemplo.

## Melhorias em relação ao projeto web original
Senhas com hash (o original guardava em texto puro), nenhum dado de cartão/CVV armazenado, validação de CPF, rate limit
no login, JWT com refresh rotativo e tratamento de duplicidade de e-mail/CPF no servidor.

## Testes
```bash
cd face-service && pytest                       # 10 testes (executados e passando)
cd backend && dotnet test                       # regras de domínio (CPF, preço, setores, código de sócio)
cd flutter_app && flutter test                  # validadores e casos de uso
```
> Observação honesta: o ambiente em que gerei o projeto não tinha Flutter nem .NET SDK, então **só o serviço Python foi
> compilado e testado aqui**. O código Dart e C# foi escrito com cuidado, mas rode `flutter analyze` e `dotnet build`
> primeiro — pode haver pequenos ajustes de versão de pacotes.
