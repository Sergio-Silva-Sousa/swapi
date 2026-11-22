# APIs

Antes de implementar qualquer parser, faça uma chamada real e confirme o formato. Onde este documento tiver `[confirmar]`, a informação ainda não foi verificada.

---

## 1. SWAPI: https://swapi.dev/api/

### Endpoints usados
| Recurso | Endpoint | Total | Observação |
|---------|----------|-------|------------|
| Filmes | `/films/` | 6 | Lista completa em uma página |
| Personagens | `/people/` | 82 | Paginado |
| Planetas | `/planets/` | 60 | Paginado |

### Paginação e busca
- Paginação: `?page=N`. Cada página traz 10 itens.
- Campo `next` indica a próxima página. Quando for `null`, acabou.
- Busca: `?search=termo`. Use para o campo de busca quando a lista ainda não estiver completa em cache.

### Campos que são URL (cuidado principal)
A SWAPI devolve relações como URLs, não como dados. Cada uma exige uma requisição separada para virar nome ou dado.

| Objeto | Campos de URL |
|--------|---------------|
| Film | `characters`, `planets`, `starships`, `vehicles`, `species` |
| Person | `homeworld`, `films`, `species`, `vehicles`, `starships` |
| Planet | `residents`, `films` |

Regras:
- **Não resolva na lista.** Só na tela de detalhe.
- **Lista grande = muitas requisições.** Um planeta pode ter dezenas de `residents`, e um filme pode ter mais de 20 `characters`. Para esses casos:
  - resolva só o que aparece na tela (lazy, conforme o scroll), ou
  - mostre só os primeiros N e carregue o restante sob demanda ("ver todos").
- **Cache por URL completa.** Se `https://swapi.dev/api/planets/1/` já foi resolvido em qualquer lugar, não busque de novo.
- **Use `name` ou `title`.** Para personagens e planetas, o campo é `name`. Para filmes, `title`.
- **Extraia o ID da URL** (`/people/1/` → `1`). Use como chave do objeto na sua base local.

### Armadilhas
- Valores numéricos vêm como string, e podem ser `"unknown"` ou `"n/a"`. Ex.: `height`, `mass`, `population`, `rotation_period`. Faça parse com fallback para `null`.
- Listas vazias (`[]`) são válidas e comuns em `residents` ou `vehicles`.
- `birth_year` pode ser `"unknown"`, `"BBY"` ou `"ABY"`. Para filtrar por ano, separe o número da sigla.
- O campo `url` de cada objeto é a chave canônica. Use-o como identificador ao cachear.
- Verifique redirecionamento. Se a SWAPI responder com redirect, siga o host final e registre a mudança aqui.

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

Regras:
- O primeiro segmento do path é a **primeira letra do termo em minúsculo**, não uma constante. Ex.: `x` só serve para termos que começam com x.
- Encode o termo na URL.
- Estrutura esperada `[confirmar]`: `{ "d": [ { "id", "l" (título), "y" (ano), "q" (tipo), "i": { "imageUrl", ... } } ] }`.
- Escolha o resultado cujo `l` bate com o título da SWAPI e cujo `y` bate com o ano de lançamento. Prefira `q` de tipo filme (`feature`). `[confirmar valores de q]`.
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

Regras:
- **Personagens têm três endpoints possíveis.** Tente nesta ordem e pare no primeiro sucesso: `characters` → `creatures` → `droids`. Memorize qual funcionou para aquele nome.
- **Nome deve ser URL-encoded** e precisa bater com o nome da SWAPI (ex.: `Luke Skywalker`). Diferenças de grafia, acento ou sufixo podem fazer a busca falhar. Trate 404 como "não encontrado", sem erro na tela.
- **Cold start.** O serviço está no Render, e o plano gratuito pode dormir. A primeira requisição pode demorar bastante. Use timeout maior nessa API (`[definir]`) e mostre loading próprio, sem bloquear a lista de texto.
- **Schema da imagem** `[confirmar]`: campo exato da URL da imagem na resposta. Documente aqui depois de inspecionar uma resposta real.

---

## Resumo do fluxo de requisições

1. Lista de filmes: `/films/` (1 requisição, cache 24 h)
2. Lista de personagens: `/people/?page=N` (9 páginas, cache 24 h, carregadas sob demanda ao rolar)
3. Lista de planetas: `/planets/?page=N` (7 páginas, cache 24 h, sob demanda)
4. Imagem de cada item: uma requisição por item, somente quando visível, cache 30 dias
5. Detalhe: resolve URLs relacionadas, uma por vez, com concorrência máxima de 4 e cache por URL
