## Quality control checklist (Flutter)

O campo `quality_control` no JSON de saída deve seguir esta estrutura:

```json
{
  "linting": { "dart_analyze": bool, "analysis_options": "path", "run_command": "cmd", "fix_command": "cmd" },
  "formatting": { "dart_format": bool, "run_command": "cmd" },
  "type_checking": { "dart_analyzer": bool, "run_command": "cmd" },
  "unit_tests": { "flutter_test": bool, "run_command": "cmd", "coverage_command": "cmd" },
  "e2e_tests": { "flutter_integration_test": bool, "maestro": bool },
  "feedback_loop_tools": { "flutter_hot_reload": bool, "flutter_hot_restart": bool, "notes": "string" }
}
```

Ferramentas típicas neste projeto (só Flutter/Dart):

**Feedback imediato (durante a tarefa):**

- `dart analyze` — análise estática após edições
- `dart format` / `dart fix --apply` — formatação e fixes automáticos
- `flutter test <arquivo>` — teste unitário pontual
- Flutter hot reload / hot restart

**Validação mais lenta (fim da tarefa):**

- `flutter test` — suíte do pacote
- `flutter test integration_test` — se existir pasta `integration_test/`
- Maestro (se houver flows em `.maestro/`)
- `flutter build apk` / `flutter build ios` — validação nativa quando necessário

**Onde procurar no repo:**

- `pubspec.yaml` — deps e scripts
- `analysis_options.yaml` — regras de lint
- `Makefile` / scripts em `tool/` — alvos `lint`, `test`, `analyze`
- CI (`.github/workflows/*.yml`) — o que significa "passar"
- `test/` e `integration_test/`
