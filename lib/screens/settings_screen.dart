import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/evolution_provider.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/action_button.dart';
import '../widgets/app_header.dart';
import '../widgets/form_fields.dart';
import '../widgets/section_card.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _ctrl;
  bool _obscure = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
      text: StorageService.instance.loadApiKey() ?? '',
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await StorageService.instance.saveApiKey(_ctrl.text.trim());
    if (!mounted) return;
    setState(() => _saving = false);

    context.read<EvolutionProvider>().refreshAPIStatus();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('API key salva localmente com sucesso.')),
    );
  }

  Future<void> _clear() async {
    await StorageService.instance.clearApiKey();
    if (!mounted) return;
    _ctrl.clear();
    context.read<EvolutionProvider>().refreshAPIStatus();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('API key removida.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppHeader(
        showHomeButton: true,
        onHomeTap: () =>
            Navigator.of(context).popUntil((Route<dynamic> r) => r.isFirst),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: AppTheme.contentMaxWidth(context),
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: AppTheme.horizontalPadding(context),
              vertical: 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                      tooltip: 'Voltar',
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Configurações',
                      style: Theme.of(context).textTheme.displayMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SectionCard(
                  title: 'Integração com Google Gemini',
                  subtitle:
                      'Informe sua API key para habilitar a geração via IA',
                  icon: Icons.smart_toy_rounded,
                  children: <Widget>[
                    LabeledField(
                      label: 'API Key',
                      helper:
                          'A chave é armazenada somente no seu dispositivo. Você pode obter uma em aistudio.google.com/apikey.',
                      child: TextFormField(
                        controller: _ctrl,
                        obscureText: _obscure,
                        decoration: InputDecoration(
                          hintText: 'AIza...',
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_rounded
                                  : Icons.visibility_off_rounded,
                            ),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        ActionButton(
                          label: 'Remover',
                          kind: ActionButtonKind.secondary,
                          icon: Icons.delete_outline_rounded,
                          onPressed: _saving ? null : _clear,
                        ),
                        const SizedBox(width: 10),
                        ActionButton(
                          label: 'Salvar',
                          kind: ActionButtonKind.primary,
                          icon: Icons.save_rounded,
                          loading: _saving,
                          onPressed: _saving ? null : _save,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SectionCard(
                  title: 'Sobre',
                  subtitle: 'EvoluaPRO v1.0.0',
                  icon: Icons.info_outline_rounded,
                  children: <Widget>[
                    Text(
                      'Aplicativo multiplataforma para gerar evoluções de enfermagem estruturadas a partir de dados clínicos, utilizando IA generativa. Funciona em Android, iOS, Windows, macOS, Linux e Web.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Todas as evoluções e a API key ficam armazenadas apenas no seu dispositivo. Nada é enviado para servidores externos, exceto o próprio prompt para a API do Gemini no momento da geração.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
