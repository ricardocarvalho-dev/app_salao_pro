# Trigger: trg_horarios_servicos_atualizar_horarios_fn

## Tabela monitorada
`horarios_servicos`

## Quando dispara
- Alteração em `horario_inicio` ou `horario_fim`.

## Ação
- Identifica o `servico_id` afetado.
- Chama `public.atualizar_horarios_por_servico(servico_id)`.

## Efeito
Recalcula os horários disponíveis do serviço alterado.
