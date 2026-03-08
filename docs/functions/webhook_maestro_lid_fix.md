# 🛠️ Fix: Resolução de Erro 400 (@lid) - Evolution API

Este documento registra a correção aplicada para mensagens que chegavam com IDs de privacidade (@lid), impedindo o envio de respostas automáticas [cite: 2026-03-07].

## 📋 Diagnóstico
* **Cenário**: Usuários (ex: Ricardo Carvalho) enviando mensagens onde o `remoteJid` terminava em `@lid`.
* **Falha**: A Evolution API v2.1.2 não traduzia esse ID, resultando em `400 Bad Request` ao tentar responder.

## 🚀 Solução Aplicada
A solução consistiu na atualização do ecossistema para a versão **v2.3.7** no repositório oficial `evoapicloud`.

### 1. Backend (Docker)
* **Imagem**: `evoapicloud/evolution-api:latest`
* **Configuração**: Habilitado `CONFIG_SESSION_PHONE_LID_TO_JID: "true"` para forçar o mapeamento de IDs.

### 2. Edge Function (TypeScript)
Atualizamos o `webhook_maestro` para interceptar o campo `senderPn` (Phone Number) que a nova API fornece.
* **Lógica**: Se `remoteJid` incluir `@lid`, o script reconstrói o JID usando o número real do remetente.

## ✅ Validação
* **Teste realizado**: Mensagem enviada com sucesso para o contato Salão Rico.
* **Log de Sucesso**: `🚀 MENSAGEM ENVIADA! Processando como JID normal: 55719... @s.whatsapp.net`.

---
*Atualizado em: 07/03/2026*