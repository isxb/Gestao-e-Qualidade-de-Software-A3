# EvoluaPRO — Análise do sistema e roteiro de melhorias

Documento pós-refatoração. Revisão 1 · 21/04/2026.

---

## 1. Estado atual — o que foi entregue

**Redesign completo**
- Nova paleta vibrante (indigo → violeta → rosa) + secundárias (teal, sky, amber, pink, rose, lime) para dashboards.
- Novo logotipo `AppLogo` (CustomPainter com linha de pulso cardíaco) + lockup `EvoluaPRO`.
- Tokens de tema consolidados (`radiusXs…radiusXl`, `space1…space10`), tipografia DM Sans + DM Serif Display, shadows suaves e elevadas.
- Breakpoints responsivos (600/900/1280/1600) e helper `AppTheme.responsive<T>(…)`.
- Cabeçalho (`AppHeader`) com gradiente assinado, logotipo wordmark, menu de usuário com avatar, atalho para painel admin e logout.

**Autenticação local robusta**
- `CryptoService` com PBKDF2-HMAC-SHA256 (150.000 iterações), salt por usuário, comparação em tempo constante.
- Senhas temporárias no formato `EV-XXXX-XXXX` (alfabeto sem caracteres ambíguos).
- Sessão TTL 12h armazenada em `flutter_secure_storage` (Keychain/KeyStore/DPAPI).
- Bloqueio automático após 5 tentativas falhas (15 minutos).
- Bootstrap do admin padrão (`admin/admin123`, `mustChangePassword: true`).
- Política de senha (mínimo 8, força ≥ 2) e medidor de força em tempo real.

**Auditoria completa**
- 30+ `ActivityType` categorizados em 6 `LogCategory`.
- Cap automático de 5000 eventos em disco.
- Consulta com filtros combinados (usuário, categoria, janela temporal).

**Painel administrativo**
- Dashboard com KPIs (usuários, admins, logins em 7 dias, eventos totais).
- CRUD completo de usuários com chips de estado (ativo, inativo, bloqueado, admin).
- Reset de senha com modal exibindo a senha temporária copiável.
- Visualizador de logs com filtros por usuário/categoria/período.
- **Jornada do usuário**: timeline agrupada por dia com todos os eventos, estatísticas consolidadas, ações rápidas (redefinir, desativar, desbloquear).

**Dashboard do usuário padrão**
- Hero saudação contextual (bom dia / tarde / noite + nome).
- KPIs reais calculados a partir das evoluções (hoje, semana, mês, arquivadas).
- Atalho destacado para admins com acesso direto ao painel.
- Cartões de ação rápida (nova evolução, banco de dados, configurações).
- Lista de evoluções recentes com preview e timestamp.

---

## 2. Quality pass — pendências de polimento baixo esforço

São ajustes cosméticos identificados durante a refatoração. Todos resolvíveis em minutos:

1. **Lints info-level restantes (6)** — sugestões de `const` em `app_logo.dart` e `login_screen.dart`. Não afetam funcionamento; limpar quando conveniente.
2. **Localização pt-BR do `intl`** — o `DateFormat` com padrão `EEEE, dd/MM` em pt está sendo renderizado em en-US. Basta registrar `initializeDateFormatting('pt_BR', null)` no `main.dart` e passar `'pt_BR'` nos `DateFormat`.
3. **`progress_stepper.dart`** herdado — manter visualmente consistente com o novo header (o gradiente do topo continua igual; vale um review rápido para usar `AppColors.brandGradient` ali também).
4. **Ícone do app** (Android/iOS/Web/Windows) — hoje ainda é o padrão do template Flutter. Renderizar o `AppLogo` para PNG e rodar `flutter_launcher_icons`.

---

## 3. Roadmap inovador — ordem por impacto/esforço

### Nível 1 — retorno imediato para o clínico (1–3 dias cada)

- **Busca global com atalho `Ctrl/⌘ + K`** — procurar evoluções por paciente, enfermeiro ou conteúdo, saltar direto para a edição. Transforma o "Banco de dados" num índice vivo.
- **Templates de evolução** por unidade (UTI adulto, UTI neo, enfermaria, pronto-socorro). Um combo no topo do wizard define pré-seleções (aspectos, dispositivos, pad-respiratório) e reduz em ~40 % os cliques.
- **Rascunho automático** — se o usuário sai no meio do wizard, persiste o `EvolutionForm` em `shared_preferences` e oferece "Retomar onde parou" na home.
- **Favoritar evoluções** para reuso como template rápido — botão ★ no banco de dados.

### Nível 2 — inteligência clínica (3–7 dias cada)

- **Sugestão de cuidados com base em contexto** — quando o usuário marca "SVD", "TOT" ou "cateter central", propor no painel lateral cuidados padronizados (banho diário de CHX, mudança de decúbito, prevenção de VAP). Pode usar o próprio Gemini com prompt específico de sugestão, sem regerar o texto completo.
- **Scoring automático de risco** (MEWS, Braden, Morse) — o wizard já captura sinais vitais, Glasgow, mobilidade e continência. Calcular esses escores em tempo real e incluir no texto é pouco código e muito valor.
- **Comparação longitudinal** — na tela do paciente, mostrar gráfico simples (pressão arterial, FC, SatO₂, temperatura) a partir das evoluções salvas. Usar o próprio `chartPalette`.
- **Modelo de linguagem clínica offline** — avaliar `llama.cpp` / `gemma` no dispositivo para quando a chave Gemini não estiver configurada ou a conexão falhar. Pode ficar atrás de uma flag.

### Nível 3 — colaboração e governança (1–2 semanas cada)

- **Plantão & handoff digital** — uma "vitrine" com as evoluções do seu plantão e uma assinatura digital (hash do texto + timestamp + coren) que garante não adulteração. O admin vê o handoff consolidado.
- **Workflow de aprovação** — evoluções criadas por estudantes entram com status `pendente`, o enfermeiro preceptor valida antes de virar `oficial`. Registra no log quem aprovou.
- **Exportação auditável** — PDF com cabeçalho institucional, assinatura, QR code para validação. HTML também, para sistemas de prontuário.
- **Integração HL7/FHIR** — endpoint opcional para enviar `Observation` e `Encounter` para um backend hospitalar. Mantém o app funcionando local-first mas oferece a ponte.

### Nível 4 — UX avançada

- **Comando por voz** no wizard clínico — `flutter_speech_to_text` para ditar aspectos, comorbidades, observações em campo livre. Incrível no leito.
- **Atalhos de teclado completos** no desktop — `Alt+1..9` para saltar entre steps, `Ctrl+Enter` para gerar, `Ctrl+S` para salvar. Já temos o escopo responsivo.
- **PWA instalável** com service worker — abre no Chrome como app, funciona offline no plantão com rede instável, sincroniza quando volta.
- **Tema sazonal/hospitalar** — permitir ao admin personalizar paleta e logotipo por instituição (white-label light). O `ColorScheme.fromSeed` já facilita.
- **Modo leitura/edição limpa** da evolução — fonte monoespaçada opcional, "copiar apenas o texto", "copiar como HL7", "imprimir evolução", "enviar para email do médico responsável".

### Nível 5 — segurança e conformidade

- **2FA via TOTP** — opcional por usuário, usando `otp` package. O admin pode tornar obrigatório para perfis com acesso sensível.
- **Política de senha configurável pelo admin** — comprimento mínimo, complexidade, histórico (últimas N senhas), expiração.
- **Logs imutáveis** — cada log armazena hash do anterior (estilo Merkle), impede edição silenciosa. Painel admin mostra quando uma cadeia foi rompida.
- **LGPD ready** — "Exportar meus dados" (JSON) e "Solicitar anonimização" com trilha no log. O admin tem botão para atender a solicitação.
- **Consent banner** — no primeiro uso, registra o aceite do enfermeiro ao uso dos dados para geração via IA.

### Nível 6 — sustentabilidade técnica

- **Migração para SQLite (drift)** — o `shared_preferences` já começa a ficar pesado com 5000 logs + evoluções. Drift dá índices, queries e migrações reais. Interface `StorageService` já isola isso.
- **Testes de integração** com `integration_test` — cobrir o fluxo `login → gerar → salvar → editar → logout`. Previne regressões visuais e de dados.
- **Observabilidade** — sentry ou grafana-faro para crashes e performance. Pode ser opt-in pelo admin.
- **CI/CD no GitHub Actions** — build Android (APK), iOS (TestFlight), Web (gh-pages), Windows (msix). Tag semântica gera release automática.
- **Internacionalização** — pt-BR é o padrão, mas o módulo de evoluções pode ser exportado para es/en com `flutter_localizations` + `.arb`.

---

## 4. Ideias de nicho (altíssimo impacto, efeito "wow")

- **Assistente de handoff** — o admin aperta um botão ao final do plantão e o sistema gera um resumo em áudio ou texto de tudo que aconteceu (usando os logs + as evoluções criadas).
- **Copilot in-line** — no wizard, um balão sugere "Você digitou 'dispneia leve'; considere adicionar padrão respiratório 'taquipneico' e SatO₂". Aprende com evoluções anteriores do próprio enfermeiro.
- **Mapa visual do paciente** — silhueta humana onde o usuário toca áreas (cabeça, tórax, abdome, MMSS, MMII) para marcar achados; gera texto estruturado automaticamente.
- **Cronômetro inteligente de cuidados** — lembretes configuráveis (próxima troca de curativo, próxima HGT, próximo banho) integrados à evolução.
- **Modo silencioso noturno** — tema preto OLED + fonte aumentada + redução de brilho/azul, ativa sozinho entre 22h e 6h.
- **Compartilhar link temporário** — o enfermeiro envia uma URL expirável (24h) com a evolução somente-leitura para o médico de plantão. Token no secure storage.

---

## 5. Priorização sugerida (próximo sprint de 2 semanas)

Se eu fosse priorizar **agora** pensando em custo/benefício e no que amplifica o que já foi entregue:

1. Ícone do app + splash nativos com o `AppLogo` (meio dia).
2. Inicialização de `pt_BR` no `intl` (15 minutos) — corrige datas e dias da semana.
3. Rascunho automático do wizard (1 dia) — resolve uma frustração clássica.
4. Busca global `Ctrl+K` (1–2 dias) — turbina o banco de dados.
5. Templates de evolução por unidade (2 dias) — reduz atrito de forma dramática.
6. 2FA opcional + política de senha configurável (2 dias) — fecha uma lacuna de compliance.
7. Export PDF com QR code de validação (1 dia) — valor institucional imediato.

Total: ~10 dias úteis. Entrega algo que conversa com o enfermeiro, conversa com o admin e conversa com a instituição.

---

## 6. Arquitetura em um parágrafo

O app é local-first: `shared_preferences` (via `StorageService`) guarda usuários, logs e evoluções; `flutter_secure_storage` guarda sessão e chave Gemini. `CryptoService` é puro Dart, zero dependência de backend. Todo o domínio passa por `Providers` (`AuthProvider`, `AdminProvider`, `EvolutionProvider`) que só lêem/escrevem através dos services. Para migrar para backend no futuro, só `StorageService` precisa ser reescrito — toda a UI, models e providers continuam iguais. Essa separação deixa o projeto pronto para virar um SaaS quando a instituição quiser.
