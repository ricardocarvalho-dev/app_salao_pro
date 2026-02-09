# Trigger: trg_profissionais_atualizar_horarios_fn

## Tabela monitorada
`profissionais`

## Quando dispara
- Mudança em `modo_agendamento` ou `salao_id`.

## Ação
- Para cada serviço vinculado ao profissional:
  - Chama `public.atualizar_horarios_por_servico(servico_id)`.

## Efeito
Recalcula os horários dos serviços que o profissional atende.
