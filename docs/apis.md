# APIs

Antes de implementar qualquer parser, faça uma chamada real e confirme o formato. Este documento foi verificado com chamadas reais em **2026-11-22**; todos os pontos antes marcados como `[confirmar]`/`[definir]` foram confirmados.

---

## 1. SWAPI: https://swapi.dev/api/

### Endpoints usados
| Recurso | Endpoint | Total | Observação |
|---------|----------|-------|------------|
| Filmes | `/films/` | 6 | Lista completa em uma página (`next: null`) |
| Personagens | `/people/` | 82 | Paginado, 10 itens por página |
| Planetas | `/planets/` | 60 | Paginado, 10 itens por página |

Confirmado: `GET /api/` devolve as raízes dos recursos; nenhum redirecionamento observado — a URL final das respostas é a mesma solicitada (`https://swapi.dev/...`). Latência observada: ~0,3 s.

### Paginação e busca
- Paginação: `?page=N`. Cada página traz 10 itens.
- Campo `next` indica a próxima página. Quando for `null`, acabou.
- Busca: `?search=termo`. Confirmado: sem resultado devolve `{"count":0,"next":null,"previous":null,"results":[]}` (HTTP 200).
- Use para o campo de busca quando a lista ainda não estiver completa em cache.

### Campos que são URL (cuidado principal)
A SWAPI devolve relações como URLs, não como dados. Cada uma exige uma requisição separada para virar nome ou dado.

| Objeto | Campos de URL |
|--------|---------------|
| Film | `characters`, `planets`, `starships`, `vehicles`, `species` |
| Person | `homeworld`, `films`, `species`, `vehicles`, `starships` |
| Planet | `residents`, `films` |

Exemplo real: `Film.characters` de A New Hope tem 18 URLs; `Planet.residents` pode ter dezenas.

Regras:
- **Não resolva na lista.** Só na tela de detalhe.
- **Lista grande = muitas requisições.** Um planeta pode ter dezenas de `residents`, e um filme pode ter mais de 20 `characters`. Para esses casos:
  - resolva só o que aparece na tela (lazy, conforme o scroll), ou
  - mostre só os primeiros N e carregue o restante sob demanda ("ver todos").
- **Cache por URL completa.** Se `https://swapi.dev/api/planets/1/` já foi resolvido em qualquer lugar, não busque de novo.
- **Use `name` ou `title`.** Para personagens e planetas, o campo é `name`. Para filmes, `title`.
- **Extraia o ID da URL** (`/people/1/` → `1`). Use como chave do objeto na sua base local.
- O campo `url` de cada objeto é a chave canônica. Use-o como identificador ao cachear.

### Armadilhas
- Valores numéricos vêm como string, e podem ser `"unknown"` ou `"n/a"`. Ex.: `height`, `mass`, `population`, `rotation_period`. Faça parse com fallback para `null`.
- Listas vazias (`[]`) são válidas e comuns em `residents` ou `vehicles` — confirmado em `people/1/` (`species: []`).
- `birth_year` pode ser `"unknown"`, `"BBY"` ou `"ABY"`. Exemplo real: `"19BBY"`. Para filtrar por ano, separe o número da sigla.
- Campo `episode_id` de filme é número inteiro, não string.
- `created`/`edited` são ISO-8601 com `Z`.

---

## 2. Imagens de filmes: IMDb suggestion (não oficial)

URL:
```
https://v2.sg.media-imdb.com/suggestion/{primeira_letra}/{termo}.json
```

Exemplo: para "A New Hope", a primeira letra é `a`:
```
https://v2.sg.media-imdb.com/suggestion/a/a%20new%20hope.json
```

Regras confirmadas:
- O primeiro segmento do path é a **primeira letra do termo em minúsculo**, não uma constante. Ex.: `x` só serve para termos que começam com x.
- Encode o termo na URL. `Uri.https` do Dart já codifica espaços (`a new hope` → `a%20new%20hope`); não combine com `Uri.encodeComponent`, que geraria `%2520`.
- Estrutura real: `{ "d": [ { "id", "l" (título), "y" (ano, **inteiro**), "q" (tipo), "qid", "i": { "imageUrl", ... } } ], "q": <termo>, "v": 1 }`.
- **`l` não bate exatamente com o título da SWAPI**: IMDb devolve `"Star Wars: Episode IV - A New Hope"` para `"A New Hope"`. O mesmo vale para os 6 filmes (`"Star Wars: Episode V - The Empire Strikes Back"`, etc.). Critério que funciona para todos os 6: `l.toLowerCase().contains(tituloSwapi.toLowerCase())` **e** `y == anoDeLancamento` **e** `qid == 'movie'`.
- Valores observados de `q`: `feature`, `TV movie`, `video`, `short`. Prefira `feature` (todos os 6 filmes têm um resultado `feature` com `qid: movie`).
- A resposta também contém **pessoas** (`id` começando com `nm`, sem `qid`) que têm `i.imageUrl`. Filtrar por `qid == 'movie'` evita foto de ator como capa de filme.
- O campo `q` do envelope é o termo da busca, não o tipo do item.
- Faça **uma requisição por filme**, cacheie por 30 dias.
- Se não encontrar, use placeholder local. Não tente de novo na mesma sessão.

Aviso: é um endpoint não documentado. Pode mudar ou bloquear. Por isso o app precisa de placeholder e de cache forte.

---

## 3. Databank: imagens de personagens, criaturas, droides e planetas

Base:
```
https://starwars-databank-server.onrender.com/api/v1
```

Endpoints:
```
/characters/name/{nome}
/creatures/name/{nome}
/droids/name/{nome}
/locations/name/{nome}     (planetas)
```

Regras confirmadas:
- **Personagens têm três endpoints possíveis.** Tente nesta ordem e pare no primeiro sucesso: `characters` → `creatures` → `droids`. Memorize qual funcionou para aquele nome. Exemplo real: `R2-D2` está em `characters`, não em `droids`.
- **Nome deve ser URL-encoded** e precisa bater com o nome da SWAPI (ex.: `Luke Skywalker`). Diferenças de grafia, acento ou sufixo podem fazer a busca falhar.
- **"Não encontrado" é HTTP 200 com corpo `[]`**, não 404 — confirmado para `/characters/name/Nome Inexistente XYZ`, `/creatures/name/Yoda` e `/droids/name/R2-D2`. Trate lista vazia como miss e cacheie por TTL curto (1 h), para não repetir a busca. Respostas 404, se ocorrerem, devem seguir a mesma política.
- **Cold start:** o serviço está no Render, e o plano gratuito pode dormir. Medido: **17,5 s** na primeira requisição (Luke Skywalker) e ~0,2 s nas seguintes. Definido: **timeout de 45 s** para esta API, com loading próprio, sem bloquear a lista de texto.
- **Schema da imagem:** o endpoint devolve uma **lista**; o primeiro item contém `image` com URL absoluta. Confirmado para `characters/name/Luke Skywalker` (`https://lumiere-a.akamaihd.net/...`), `locations/name/Tatooine` e `characters/name/R2-D2`.

---

## Resumo do fluxo de requisições

1. Lista de filmes: `/films/` (1 requisição, cache 24 h)
2. Lista de personagens: `/people/?page=N` (9 páginas, cache 24 h, carregadas sob demanda ao rolar)
3. Lista de planetas: `/planets/?page=N` (7 páginas, cache 24 h, sob demanda)
4. Imagem de cada item: uma requisição por item, somente quando visível, cache 30 dias; misses 1 h
5. Detalhe: resolve URLs relacionadas, uma por vez, com concorrência máxima de 4 e cache por URL (7 dias)
