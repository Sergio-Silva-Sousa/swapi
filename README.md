# swapo

Star Wars Databank em Flutter: filmes, personagens e planetas da SWAPI, com busca,
filtros, favoritos por usuário e uso offline dos dados já visualizados.

A interface usa Material 3 com **tema escuro padrão**, cartões arredondados e
pôsteres de filmes; personagens e planetas exibem imagens do Databank quando
disponíveis.

## Requisitos

- Flutter **stable** via FVM (`fvm` instalado; versão em `.fvmrc`)

## Comandos

```bash
fvm flutter pub get                 # dependências
fvm dart run build_runner build -d  # codegen (drift/riverpod), quando necessário
fvm flutter run                     # rodar
fvm flutter test                    # testes
fvm flutter analyze                 # análise (deve passar sem issues)
```

## Estrutura

```
lib/
  core/       ApiClient (cache, timeout, retry), cache Drift, rede, TTL, resolvers de URL e imagem
  features/   auth, films, people, planets, favorites — cada um com data/ e presentation/
```

Features não importam outras features; código compartilhado fica em `core/`.

## Dados e offline

- Origens: SWAPI (catálogos), IMDb suggestion (capas de filme) e Star Wars Databank
  (imagens de personagens/planetas). Formatos e armadilhas: [`docs/apis.md`](docs/apis.md).
- Escopo e critérios do MVP: [`docs/escopo.md`](docs/escopo.md).
- Toda requisição passa pelo `ApiClient`: cache local, timeout e no máximo 2 retries.
- TTLs: listas 24 h, detalhes 7 dias, imagens 30 dias, misses de imagem 1 h.
- Sem rede, o cache expirado é exibido com aviso de dados desatualizados.
- Cadastro/login são locais (SQLite + PBKDF2 com salt); a sessão fica no
  `flutter_secure_storage`. Favoritos são por usuário e funcionam offline.

## Estado

MVP em andamento: catálogos, busca/filtros, autenticação e favoritos já existem.
Detalhes com resolução de relações, paginação de planetas e testes de integração
estão pendentes — ver o checklist em `docs/escopo.md`.
