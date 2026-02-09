# Trigger: trg_servicos_atualizar_horarios_fn

## Tabela monitorada
`servicos`

## Quando dispara
- Mudança em `duracao_minutos` ou `especialidade_id`.

## Ação
- Chama `public.atualizar_horarios_por_servico(NEW.id)`.

## Efeito
Recalcula os horários com nova duração ou especialidade.
