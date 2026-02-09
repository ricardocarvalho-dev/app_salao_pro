# Trigger: trg_servico_atualizar_horarios

## Tabela monitorada
`servicos`

## Quando dispara
- `INSERT` ou `UPDATE` direto na tabela.

## Ação
- Chama `public.atualizar_horarios_por_servico(NEW.id)`.

## Efeito
Gera ou atualiza os horários do serviço recém-criado ou modificado.
