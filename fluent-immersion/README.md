# FLUENT IMMERSION

Plataforma de prática de **Inglês e Espanhol — A0 a C2**.

## Estrutura
- Reading
- Writing
- Listening
- Speaking
- Grammar
- Vocabulary
- Vídeos, áudios, textos e materiais
- Exercícios interativos
- XP, streak e progresso

## Supabase
O banco usa um schema isolado chamado `fluent_immersion` para não conflitar com as tabelas existentes do projeto.

Projeto Supabase: `ingles-para-nacoes`

Tabelas:
- languages
- cefr_levels
- courses
- units
- lessons
- content
- exercises
- exercise_items
- user_profiles
- progress
- attempts

A migration está em `supabase/migrations/20261004160000_create_fluent_immersion_schema.sql`.

> Não coloque service_role key no frontend. Para usar o schema pelo Supabase Data API, adicione `fluent_immersion` aos schemas expostos nas configurações de API do projeto.
