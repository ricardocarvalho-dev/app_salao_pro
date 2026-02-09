# Trigger: trg_profissional_especialidades_atualizar_horarios_fn

## Tabela monitorada
`profissional_especialidades`

## Quando dispara
- Adição, remoção ou alteração de especialidade.

## Ação
- Identifica os serviços da especialidade afetada.
- Chama `public.atualizar_horarios_por_servico(servico_id)`.

## Efeito
Atualiza os horários dos serviços vinculados à especialidade.
