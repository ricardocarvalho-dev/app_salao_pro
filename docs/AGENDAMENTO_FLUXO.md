# Fluxo de Agendamento – Comportamento Oficial

Este documento descreve o comportamento esperado do fluxo de agendamento
por serviço e por profissional no App Salão Pro.

## Conceitos Fundamentais

O sistema possui **dois modos distintos de agendamento**:

### 1️⃣ Agendamento por Serviço (sem profissional)
- `profissional_id = null`
- Horários são gerados automaticamente via job
- Representa a agenda geral do serviço
- Exemplo: Serviço "Axilas" sem profissional específico

### 2️⃣ Agendamento por Profissional
- `profissional_id != null`
- Serviço deve pertencer à especialidade do profissional
- Horários são específicos daquele profissional
- Exemplo: Serviço "Pés" com a profissional "Manicure Teste"

---

## Regras de Negócio (IMPORTANTES)

### 🔁 Troca de Profissional

Quando o usuário seleciona um profissional:

1. Qualquer serviço previamente selecionado é **invalidado**
2. Os horários carregados anteriormente são **descartados**
3. O dropdown de serviços é **resetado**
4. O usuário deve escolher **um serviço compatível com o profissional**

⚠️ Este comportamento é **intencional e correto**.

---

### 🔁 Troca de Serviço

- Se o serviço for selecionado **sem profissional**:
  - Carrega horários gerais (`profissional_id = null`)
- Se o serviço for selecionado **com profissional**:
  - Carrega horários específicos daquele profissional

---

## Cenário que NÃO é bug (documentado)

### Situação:
- Usuário seleciona um serviço (modo geral)
- Horários são exibidos
- Usuário seleciona um profissional
- Horários somem

### Motivo:
Os horários exibidos pertenciam ao serviço **sem profissional**  
Ao selecionar um profissional, esse contexto deixa de ser válido.

✅ Comportamento esperado  
❌ Não é bug  
❌ Não deve ser alterado

---

## Estado Atual

Fluxo validado manualmente em:
- 31/01/2026
- Commit base: `9bc4cb5`

Qualquer alteração futura neste fluxo deve considerar este documento
como referência oficial.

## 📚 Documentação técnica de triggers e função central Para detalhes da arquitetura de atualização automática dos horários, consulte: - [Função central: atualizar_horarios_por_servico](functions/atualizar_horarios_por_servico.md) - Triggers: - [trg_horarios_servicos_atualizar_horarios_fn](triggers/horarios_servicos.md) - [trg_profissionais_atualizar_horarios_fn](triggers/profissionais.md) - [trg_profissional_especialidades_atualizar_horarios_fn](triggers/profissional_especialidades.md) - [trg_servico_atualizar_horarios](triggers/servicos.md) - [trg_servicos_atualizar_horarios_fn](triggers/servicos_criticos.md) ## 📊 Fluxograma Veja o diagrama completo em [`fluxograma/arquitetura_triggers.png`](fluxograma/arquitetura_triggers.png).
