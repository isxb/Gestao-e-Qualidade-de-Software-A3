# Setup do EvoluaPRO

Este documento concentra **tudo que precisa ser configurado fora do código** para o app rodar em produção: Google Sign-In, AdMob e Asaas. O código já está pronto — falta apenas plugar credenciais.

## TL;DR de modelo de monetização

| Plataforma | Sem assinatura | Com assinatura |
|---|---|---|
| **Android / iOS** | Acesso completo + anúncios | Acesso completo, sem anúncios |
| **Windows** | **Bloqueado por paywall** | Acesso completo |
| **Web / macOS / Linux** | (mesmo do Windows: bloqueado por paywall) | Acesso completo |

A regra fica em [`lib/utils/platform_check.dart`](../lib/utils/platform_check.dart) — `requiresPremium` e `supportsAds`. Se um dia quiser, por exemplo, liberar o macOS sem assinatura, é só editar lá.

---

## 1. Google Sign-In

### Pré-requisitos
1. Crie um projeto no [Google Cloud Console](https://console.cloud.google.com/).
2. Habilite a API "Google Identity Services".
3. Em **APIs & Services → Credentials**, crie OAuth 2.0 Client IDs separados para cada plataforma:

### Android
- Tipo: **Android**
- Package name: o `applicationId` do `android/app/build.gradle`
- SHA-1 (debug e release): rode `cd android && ./gradlew signingReport`
- Baixe o `google-services.json` e coloque em `android/app/`
- O plugin do `google_sign_in` carrega automaticamente.

### iOS
- Tipo: **iOS**
- Bundle ID: o `PRODUCT_BUNDLE_IDENTIFIER` do `ios/Runner.xcodeproj`
- Baixe o `GoogleService-Info.plist` para `ios/Runner/`
- No `ios/Runner/Info.plist`, adicione:
  ```xml
  <key>CFBundleURLTypes</key>
  <array>
    <dict>
      <key>CFBundleURLSchemes</key>
      <array>
        <string>com.googleusercontent.apps.SEU_REVERSED_CLIENT_ID</string>
      </array>
    </dict>
  </array>
  ```

### Web
- Tipo: **Web application**
- Origens autorizadas: `http://localhost:5000`, `https://seu-dominio.com.br`, etc.
- No `web/index.html`, antes do fechamento de `</head>`:
  ```html
  <meta name="google-signin-client_id" content="SEU_CLIENT_ID.apps.googleusercontent.com">
  ```

### Windows / macOS / Linux
O plugin `google_sign_in` **não suporta desktop oficialmente**. O app
detecta isso em runtime ([`PlatformCheck.supportsGoogleSignIn`](../lib/utils/platform_check.dart))
e desabilita o botão com mensagem amigável. Se for crítico ter login Google
em desktop, alternativas são:

- OAuth via browser externo + servidor local de callback (`url_launcher` + `shelf`).
- Implementar um login web e usar deep link de volta.

---

## 2. Asaas (assinaturas)

### Conta + chaves

1. Crie conta de **sandbox** em [sandbox.asaas.com](https://sandbox.asaas.com/).
2. Em **Integrações → API**, gere um access token.
3. Use **sempre sandbox** durante o desenvolvimento — chamadas em produção criam cobranças reais.

### ⚠️ Onde colocar a API key

A chave do Asaas **NÃO PODE ficar embutida no APK** em produção. Qualquer
pessoa que extrair o APK consegue ler a string em texto plano. Você tem
dois caminhos:

#### Caminho A — Proxy próprio (recomendado para produção)

1. Suba um backend (Cloud Function, Supabase Edge Function, AWS Lambda,
   sua própria API REST — qualquer um serve).
2. O backend guarda a API key em variável de ambiente do servidor.
3. O backend exige autenticação do cliente (ex.: Bearer JWT da sessão do app).
4. O backend recebe `POST /customers`, `POST /subscriptions` etc. e
   repassa para `https://api.asaas.com/v3/...` adicionando o header
   `access_token`.
5. No app, defina:
   ```env
   ASAAS_PROXY_BASE_URL=https://api.suaempresa.com.br/payments
   ```
   E **deixe `ASAAS_API_KEY` vazia** — o `AsaasService` nem tenta enviar
   o header se estiver no modo proxy.

#### Caminho B — Direto (apenas dev/sandbox)

Para acelerar testes locais com sandbox:

```env
ASAAS_PROXY_BASE_URL=
ASAAS_BASE_URL=https://sandbox.asaas.com/api/v3
ASAAS_API_KEY=$aact_sandbox_xxxxxxxx
```

### Webhook (essencial!)

Sem webhook, o app **nunca sabe quando o pagamento foi confirmado**. O
fluxo correto é:

1. Cliente paga no link Asaas (boleto/Pix/cartão).
2. Asaas chama o webhook do seu backend (`PAYMENT_CONFIRMED`,
   `SUBSCRIPTION_CREATED` etc.).
3. Seu backend marca o usuário como ativo no banco.
4. Quando o app chama `SubscriptionProvider.sync()`, recebe o status
   atualizado.

Cadastre o webhook em **Integrações → Webhooks** apontando para seu
backend. Os eventos mínimos a escutar:
- `PAYMENT_CONFIRMED`
- `PAYMENT_RECEIVED`
- `PAYMENT_OVERDUE`
- `SUBSCRIPTION_INACTIVATED`
- `SUBSCRIPTION_DELETED`

### Planos / preços

Os preços e ciclos são definidos em código, em
[`lib/models/subscription_plan.dart`](../lib/models/subscription_plan.dart) → `PlanCatalog`.
Edite `priceCents`, `cycle`, `features`, `savingsLabel` conforme a sua
oferta comercial. O `cycle` é convertido para `MONTHLY`/`YEARLY` no
Asaas automaticamente.

---

## 3. AdMob

### Conta + ad units

1. Crie conta em [admob.google.com](https://admob.google.com/).
2. Adicione o app (Android e iOS são ad units separados).
3. Para cada ad unit, copie o ID:
   - Banner Android (formato `ca-app-pub-XXX/YYY`)
   - Banner iOS
   - Intersticial Android
   - Intersticial iOS
4. Cole no `.env`:
   ```env
   ADMOB_BANNER_ID_ANDROID=ca-app-pub-...
   ADMOB_BANNER_ID_IOS=ca-app-pub-...
   ADMOB_INTERSTITIAL_ID_ANDROID=ca-app-pub-...
   ADMOB_INTERSTITIAL_ID_IOS=ca-app-pub-...
   ```

### Configuração nativa (obrigatória)

#### Android — `android/app/src/main/AndroidManifest.xml`

Dentro de `<application>`:

```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY"/>
```

#### iOS — `ios/Runner/Info.plist`

```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY</string>

<key>SKAdNetworkItems</key>
<array>
  <!-- ver lista oficial em developers.google.com/admob/ios/quick-start#skadnetwork -->
</array>
```

> Em **dev** o app já roda com IDs de teste oficiais do Google
> (`ca-app-pub-3940256099942544/...`). Você pode rodar `flutter run`
> sem nenhuma configuração e os anúncios de teste aparecem.

---

## 4. Variáveis no `.env`

Resumo:

```env
GEMINI_API_KEY=...
ASAAS_PROXY_BASE_URL=https://api.suaempresa.com.br/payments
ASAAS_BASE_URL=https://sandbox.asaas.com/api/v3
ASAAS_API_KEY=                       # vazio se usar proxy
ADMOB_BANNER_ID_ANDROID=
ADMOB_BANNER_ID_IOS=
ADMOB_INTERSTITIAL_ID_ANDROID=
ADMOB_INTERSTITIAL_ID_IOS=
GOOGLE_WEB_CLIENT_ID=
```

`flutter_dotenv` carrega esse arquivo no `main()`. Reinicie o app
toda vez que mudar o `.env` (hot reload não relê).

---

## 5. Liberação rápida de premium em desenvolvimento

Para testar a versão paga sem passar pelo Asaas:

```dart
// Em qualquer ponto após o login (debug only):
context.read<SubscriptionProvider>().grantPremiumForDev(PlanType.yearly);
```

Esse método está no provider e bypassa o gateway. **Não chame em
produção.** Em release, considere envolver com `assert(!kReleaseMode)`.

---

## 6. Checklist antes de subir para a loja

- [ ] `.env` com chaves de **produção** (Asaas e AdMob), nunca sandbox
- [ ] `ASAAS_PROXY_BASE_URL` configurado e backend rodando
- [ ] Webhook do Asaas apontado para o backend
- [ ] `google-services.json` (Android) e `GoogleService-Info.plist` (iOS) commitados no repo de release
- [ ] AdMob `APPLICATION_ID` no `AndroidManifest.xml` e no `Info.plist`
- [ ] App registrado no console do AdMob com SKAdNetworkItems
- [ ] Política de privacidade atualizada (mencionar AdMob, Google Sign-In, Asaas)
- [ ] Termos de uso falando explicitamente sobre cobrança recorrente
- [ ] Texto da loja (Play Store / App Store) descrevendo a comissão por anúncios em mobile e a obrigatoriedade de assinatura em desktop
