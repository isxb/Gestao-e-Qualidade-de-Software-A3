// Testes de integração — EvolutionTemplate + EvolutionForm
// Tipo: Teste de Integração | Abordagem: Caixa Preta
// Justificativa: verifica a colaboração entre dois modelos distintos
import 'package:evolua_pro/models/evolution_form.dart';
import 'package:evolua_pro/models/evolution_template.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  EvolutionTemplate buildTemplate({
    String setor = 'UTI Adulto',
    String padResp = 'taquipneico',
    String enfermeiroNome = 'Ana Lima',
  }) {
    final DateTime now = DateTime(2025, 6, 1, 8);
    return EvolutionTemplate(
      id: 'tmpl-01',
      userId: 'u1',
      name: 'Template UTI',
      createdAt: now,
      updatedAt: now,
      setor: setor,
      padResp: padResp,
      enfermeiroNome: enfermeiroNome,
    );
  }

  // =========================================================
  // applyTo — integração Template → Form
  // =========================================================
  group('EvolutionTemplate.applyTo (integração)', () {
    test('substitui campos clínicos do template no formulário', () {
      final EvolutionForm form = EvolutionForm();
      final EvolutionForm resultado = buildTemplate().applyTo(form);

      expect(resultado.setor, 'UTI Adulto');
      expect(resultado.padResp, 'taquipneico');
    });

    test('preserva nome e EVA do paciente (dados específicos do encontro)', () {
      final EvolutionForm form =
          EvolutionForm().copyWith(pacienteNome: 'Maria Souza', eva: 5);
      final EvolutionForm resultado = buildTemplate().applyTo(form);

      expect(resultado.pacienteNome, 'Maria Souza');
      expect(resultado.eva, 5);
    });

    test('applyTo sobre form com nome do enfermeiro usa o do template', () {
      final EvolutionForm form = EvolutionForm().copyWith(enfermeiroNome: '');
      final EvolutionForm resultado =
          buildTemplate(enfermeiroNome: 'Ana Lima').applyTo(form);
      expect(resultado.enfermeiroNome, 'Ana Lima');
    });

    test('applyTo preserva nome do enfermeiro do form quando template está vazio', () {
      final EvolutionForm form =
          EvolutionForm().copyWith(enfermeiroNome: 'Carlos Ramos');
      final EvolutionForm resultado =
          buildTemplate(enfermeiroNome: '').applyTo(form);
      expect(resultado.enfermeiroNome, 'Carlos Ramos');
    });
  });

  // =========================================================
  // fromForm — integração Form → Template
  // =========================================================
  group('EvolutionTemplate.fromForm (integração)', () {
    test('captura setor e padResp do formulário', () {
      final EvolutionForm form =
          EvolutionForm().copyWith(setor: 'UCO', padResp: 'eupneico');
      final EvolutionTemplate tmpl = EvolutionTemplate.fromForm(
        id: 'tmpl-02',
        userId: 'u2',
        name: 'Template UCO',
        description: 'Para a UCO',
        form: form,
      );
      expect(tmpl.setor, 'UCO');
      expect(tmpl.padResp, 'eupneico');
      expect(tmpl.name, 'Template UCO');
    });

    test('round-trip fromForm → applyTo recupera os campos', () {
      final EvolutionForm formOriginal =
          EvolutionForm().copyWith(setor: 'Cirúrgico', padResp: 'bradipneico');
      final EvolutionTemplate tmpl = EvolutionTemplate.fromForm(
        id: 'tmpl-03',
        userId: 'u3',
        name: 'Cirúrgico',
        description: '',
        form: formOriginal,
      );
      final EvolutionForm formAplicado = tmpl.applyTo(EvolutionForm());
      expect(formAplicado.setor, 'Cirúrgico');
      expect(formAplicado.padResp, 'bradipneico');
    });
  });

  // =========================================================
  // copyWith
  // =========================================================
  group('EvolutionTemplate.copyWith', () {
    test('altera apenas o campo especificado', () {
      final EvolutionTemplate original = buildTemplate();
      final EvolutionTemplate copia = original.copyWith(name: 'Novo Nome');
      expect(copia.name, 'Novo Nome');
      expect(copia.setor, original.setor);
      expect(copia.id, original.id);
    });

    test('não altera updatedAt se não fornecido', () {
      final EvolutionTemplate original = buildTemplate();
      final EvolutionTemplate copia = original.copyWith(padResp: 'eupneico');
      expect(copia.updatedAt, original.updatedAt);
    });
  });

  // =========================================================
  // toJson / fromJson
  // =========================================================
  group('EvolutionTemplate serialização', () {
    test('toJson / fromJson é round-trip fiel', () {
      final EvolutionTemplate original = buildTemplate();
      final EvolutionTemplate restaurado =
          EvolutionTemplate.fromJson(original.toJson());
      expect(restaurado.id, original.id);
      expect(restaurado.name, original.name);
      expect(restaurado.setor, original.setor);
      expect(restaurado.padResp, original.padResp);
      expect(restaurado.createdAt, original.createdAt);
    });
  });
}
