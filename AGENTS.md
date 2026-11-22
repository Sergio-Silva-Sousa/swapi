# Star Wars Databank: instruções para o agente

## Stack
- Flutter via FVM (canal stable). Use sempre `fvm flutter` e `fvm dart`, nunca `flutter` direto.
- Estado: Riverpod (`flutter_riverpod`, `riverpod_annotation`)
- Rotas: `go_router`
- HTTP: `dio`
- Banco local: `drift` (SQLite). Usado para cache de API, favoritos e usuários.
- Sessão: `flutter_secure_storage` (guarda só o id da sessão ativa)
- Senhas: PBKDF2 via `cryptography`, salt aleatório por usuário
- Imagens: `cached_network_image`

## Comandos
- Dependências: `fvm flutter pub get`
- Codegen (drift, riverpod): `fvm dart run build_runner build -d`
- Rodar: `fvm flutter run`
- Testes: `fvm flutter test`
- Análise: `fvm flutter analyze` (precisa passar sem erros antes de concluir qualquer tarefa)

## Estrutura
```
lib/
  core/            api client (dio), cache, status de rede, erros, ttl, config
  features/
    auth/          login, cadastro, sessão
    films/         lista, busca, filtros, detalhe
    people/        lista, busca, filtros, detalhe
    planets/       lista, busca, filtros, detalhe
    favorites/     favoritos por usuário
  each feature:    data/ (datasources, repositories, models)
                   presentation/ (telas, providers, widgets)
```
- Features não importam outras features. Código compartilhado vai para `core/`.

## Regras de requisição (obrigatórias)
- Antes de mexer em qualquer chamada, leia `docs/apis.md`.
- Toda requisição passa pelo `ApiClient` do core, que aplica cache, timeout e retry (máximo 2, com backoff).
- Nunca faça requisição dentro de `build()`. Use providers.
- Campos da SWAPI que são URL (`homeworld`, `films`, `species`, `residents`, `characters`, etc.) são resolvidos **somente na tela de detalhe**, nunca na lista.
- Concorrência máxima de 4 requisições simultâneas ao resolver URLs.
- Cache de URL resolvida usa a URL completa como chave.
- Busca com debounce de 400 ms. Filtros aplicam sobre dados já em cache sempre que possível.
- Imagem de personagem: tente `characters` → `creatures` → `droids` em sequência, parando no primeiro sucesso. Memorize qual endpoint funcionou para aquele nome.
- Respostas 404 também são cacheadas com TTL curto, para não repetir a mesma busca.
- Nunca dispare requisições em paralelo "por garantia". Justifique qualquer fan-out.

## Cache
- Tabela `api_cache(url PK, body, fetched_at, expires_at)`.
- TTLs centralizados em `core/cache/ttl.dart`:
  - listas: 24 h
  - detalhes: 7 dias
  - imagens resolvidas: 30 dias
- Sem internet: retorne o cache mesmo expirado, marcado com `stale: true`. A UI mostra o aviso "offline".
- Sem cache e sem rede: estado de erro com botão "tentar novamente".

## Auth e favoritos
- Cadastro e login locais (e-mail + senha). Senha nunca em texto puro, nunca em log.
- Sessão persiste: ao reabrir o app, o usuário continua logado.
- Logout limpa só a sessão. Favoritos permanecem salvos.
- Favoritos têm chave composta `(user_id, tipo, item_id)`. Um usuário nunca lê favoritos de outro.
- Favoritos funcionam offline (são locais). Os dados exibidos vêm do cache.

## Testes obrigatórios
- Parser de cada model, incluindo campos "unknown", listas vazias e URLs.
- Extração de ID a partir da URL da SWAPI.
- Política de cache: fresh, stale e expired.
- Hash e verificação de senha.
- Isolamento de favoritos entre usuários.

## Processo
- Uma fatia por vez: feature completa (dados → provider → tela → teste).
- Não adicione dependência sem justificar em uma linha na resposta final.
- Ao concluir um passo que funciona, sugira o commit.

## Resposta ao usuário
- Curta. Mostre resumo e diff, nunca o arquivo inteiro.
- Se algo nas APIs não bater com esta documentação, avise antes de adaptar o código.
