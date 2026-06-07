# EvoluaPRO — Flutter

Gerador de **evoluções de enfermagem** baseado em templates clínicos, reescrito em **Flutter** a partir do projeto React original.

Um único código-fonte roda em **Android, iOS, Windows, macOS, Linux e Web**, com tema claro/escuro, layout totalmente responsivo (celular, tablet, desktop) e interface moderna Material 3.

---

## ✨ O que há de novo em relação à versão React

- **Multiplataforma nativa**: mesmo app em Android / iOS / Windows (.exe) / macOS / Linux / Web.
- **Responsivo de verdade**: grid que se adapta de 1 coluna (celular) até 3 colunas (desktop), paddings e larguras calculados por `MediaQuery`.
- **Tema claro e escuro** automáticos (respeita o modo do sistema).
- **Templates por conta**: cada usuário cria e gerencia seus próprios templates de evolução, personalizados para sua rotina clínica.
- **Persistência cross-platform** via `shared_preferences` — sem banco nativo, funciona igual em todas as plataformas.
- **Fonte das letras** (Google Fonts *DM Sans* + *DM Serif Display*) baixada em runtime: zero configuração de assets.
- **Arquitetura escalável**: `models/`, `services/`, `providers/`, `widgets/`, `screens/` bem separados — fácil de estender.
- **Correlações clínicas cruzadas preservadas** (ex.: TOT/TQT automaticamente marcam ventilação mecânica; SVD preenche aspecto da diurese; "Sem acesso venoso" zera os campos de acesso).

---

## 📋 Requisitos

- **Flutter SDK 3.19+** (`flutter --version`)
- **Dart 3.3+**
- Para **Android**: Android Studio + SDK / NDK
- Para **iOS**: Xcode (macOS apenas)
- Para **Windows** (`.exe`): Visual Studio 2022 com **"Desktop development with C++"**

---

## 🚀 Instalação passo a passo

### 1. Gere as pastas nativas das plataformas

As pastas `android/`, `ios/`, `windows/`, `macos/`, `linux/` e `web/` precisam ser geradas pelo Flutter CLI. Entre na pasta do projeto e execute **uma única vez**:

```bash
flutter create . --org com.evoluapro --project-name evolua_pro --platforms=android,ios,windows,macos,linux,web
```

Isso cria todos os diretórios nativos preservando os arquivos Dart já existentes.

### 2. Instale as dependências

```bash
flutter pub get
```

### 3. Rode o app

```bash
# Android (emulador ou dispositivo USB)
flutter run -d android

# iOS
flutter run -d ios

# Windows
flutter run -d windows

# Web (Chrome)
flutter run -d chrome
```

---

## 📦 Builds para distribuição

### Android — APK
```bash
flutter build apk --release
# Saída: build/app/outputs/flutter-apk/app-release.apk
```

### Android — AppBundle (Play Store)
```bash
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
# Depois, abra ios/Runner.xcworkspace no Xcode e faça Archive → Distribute App
```

### Windows — .exe
```bash
flutter build windows --release
# Saída: build/windows/x64/runner/Release/
# Copie a pasta inteira — ela contém o .exe e as DLLs necessárias.
```

### macOS — .app
```bash
flutter build macos --release
# Saída: build/macos/Build/Products/Release/evolua_pro.app
```

### Web
```bash
flutter build web --release
# Saída: build/web/
```

---

## 🏗️ Arquitetura

```
lib/
├── main.dart                      # entry point (inicializa dotenv, storage)
├── app.dart                       # MaterialApp + temas + home
│
├── theme/
│   ├── app_colors.dart            # paleta (light + dark + estados clínicos)
│   └── app_theme.dart             # ThemeData + helpers responsivos
│
├── models/                        # imutáveis, copyWith, JSON
│   ├── evolution_form.dart        # modelo principal do formulário (60+ campos)
│   ├── evolution_template.dart    # template reutilizável por conta de usuário
│   ├── medication.dart
│   ├── infusion.dart
│   └── saved_evolution.dart
│
├── services/
│   ├── crypto_service.dart        # PBKDF2-HMAC-SHA256 (hash de senha)
│   └── storage_service.dart       # shared_preferences (evoluções + templates)
│
├── providers/
│   └── evolution_provider.dart    # ChangeNotifier: state + correlações + geração
│
├── widgets/                       # componentes reutilizáveis responsivos
│   ├── app_header.dart
│   ├── action_button.dart
│   ├── form_fields.dart
│   ├── pill_buttons.dart
│   ├── progress_stepper.dart
│   ├── responsive_grid.dart
│   ├── section_card.dart
│   ├── stat_card.dart
│   ├── tag_chip.dart
│   └── vital_card.dart
│
├── utils/
│   └── markdown_bold.dart         # renderiza **bold** do output
│
└── screens/
    ├── home_screen.dart           # home com cards de resumo
    ├── settings_screen.dart       # configurações da conta
    ├── database_screen.dart       # banco de evoluções salvas
    ├── view_saved_screen.dart     # visualizar / editar / copiar / deletar
    ├── generator_screen.dart      # wizard de 9 passos
    └── steps/
        ├── step_admission.dart      # 1 — Admissão
        ├── step_hpp.dart            # 2 — HPP (comorbidades + medicações)
        ├── step_physical_exam.dart  # 3 — Exame Físico
        ├── step_vital_signs.dart    # 4 — Sinais Vitais + Glasgow + EVA
        ├── step_skin.dart           # 5 — Pele + Braden
        ├── step_devices.dart        # 6 — Acessos + dispositivos + infusões
        ├── step_exams.dart          # 7 — Exames
        ├── step_signature.dart      # 8 — Assinatura + COREN
        └── step_output.dart         # 9 — Resultado (edição / cópia / salvar)
```

### Princípios aplicados

- **Single source of truth**: `EvolutionProvider` centraliza todo o estado.
- **Models imutáveis**: cada alteração cria um novo `EvolutionForm` via `copyWith`.
- **Escalável**: para adicionar um novo passo, basta criar um `StepX` em `screens/steps/` e registrar em `generator_screen.dart` + aumentar o total no provider.
- **Responsivo**: `ResponsiveGrid` + `AppTheme.horizontalPadding(context)` + `AppTheme.contentMaxWidth(context)`.
- **Clean Architecture leve**: separação UI / state / services / models.

---

## 🎨 Design System

- **Cor primária**: `#1A6B9A` (azul clínico)
- **Tipografia**: DM Sans (corpo) + DM Serif Display (títulos)
- **Material 3** com `ColorScheme.fromSeed`
- **Breakpoints**: mobile <640, tablet <960, desktop <1280, wide ≥1280

---

## 🧪 Testes

```bash
# Executar todos os testes
flutter test

# Executar com relatório de cobertura
flutter test --coverage
```

### Suíte de testes (Fase 2 – A3 Qualidade de Software)

| Nível | Arquivo | Testes |
|---|---|---|
| Unitário (caixa branca) | `test/services/crypto_service_test.dart` | 25 |
| Unitário (caixa preta) | `test/models/user_test.dart` | 12 |
| Unitário (caixa preta) | `test/models/medication_test.dart` | 9 |
| Unitário (caixa preta) | `test/models/infusion_test.dart` | 6 |
| Unitário (caixa preta) | `test/models/saved_evolution_test.dart` | 5 |
| Unitário (caixa preta) | `test/evolution_form_test.dart` | 4 |
| Integração | `test/models/evolution_template_test.dart` | 9 |
| Sistema (widget) | `test/widget_test.dart` | 9 |
| **Total** | | **90 / 90 ✅** |

**Cobertura:** 75,9% (552/727 linhas) — medida nos arquivos testados.

O pipeline CI/CD (`.github/workflows/flutter_ci.yml`) executa automaticamente lint + testes + build Android a cada push no branch `main`.

---

## 📝 Licença

Projeto interno para uso clínico. As evoluções geradas devem sempre ser revisadas pelo enfermeiro responsável antes de serem inseridas no prontuário do paciente.
