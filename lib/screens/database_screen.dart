import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/saved_evolution.dart';
import '../providers/evolution_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import 'view_saved_screen.dart';

class DatabaseScreen extends StatelessWidget {
  const DatabaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<SavedEvolution> items =
        context.watch<EvolutionProvider>().savedEvolutions;

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
          child: Padding(
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
                      'Banco de Dados',
                      style: Theme.of(context).textTheme.displayMedium,
                    ),
                    const Spacer(),
                    if (items.isNotEmpty)
                      Text(
                        '${items.length} evoluç${items.length == 1 ? 'ão' : 'ões'}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: items.isEmpty
                      ? _EmptyState()
                      : _EvolutionList(items: items),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.folder_off_outlined,
            size: 56,
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withValues(alpha: 0.3),
          ),
          const SizedBox(height: 14),
          Text(
            'Nenhuma evolução salva ainda.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.55),
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Gere uma nova evolução e salve para vê-la aqui.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _EvolutionList extends StatelessWidget {
  const _EvolutionList({required this.items});

  final List<SavedEvolution> items;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListView.separated(
        itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (BuildContext context, int index) {
          final SavedEvolution e = items[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 8,
            ),
            leading: CircleAvatar(
              backgroundColor: Theme.of(context)
                  .colorScheme
                  .primary
                  .withValues(alpha: 0.12),
              foregroundColor: Theme.of(context).colorScheme.primary,
              child: Text(
                _initials(e.patientName),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            title: Text(
              e.patientName,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 15,
                  ),
            ),
            subtitle: Text(
              '${e.date} às ${e.time}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ViewSavedScreen(evolution: e),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _initials(String name) {
    final String trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    final List<String> parts =
        trimmed.split(RegExp(r'[.\s]+')).where((String s) => s.isNotEmpty).toList();
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }
}
