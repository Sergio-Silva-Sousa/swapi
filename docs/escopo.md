# Star Wars Databank: escopo

## Objetivo
App Flutter que reúne filmes, personagens e planetas do universo Star Wars, com busca, filtros, favoritos por usuário e uso offline dos dados já visualizados.

## Público
Fãs da franquia, usando o celular, nem sempre com conexão estável.

## Telas

1. **Login / cadastro**: e-mail e senha. Ao abrir o app, pula direto para a home se houver sessão ativa.
2. **Filmes**: lista com imagem e título. Busca por título. Filtro por ano de lançamento e diretor. Detalhe com abertura, personagens e planetas relacionados.
3. **Personagens**: lista paginada com imagem e nome. Busca por nome. Filtros por gênero, espécie e ano de nascimento. Detalhe com imagem, planeta natal, espécie, filmes em que aparece.
4. **Planetas**: lista com imagem e nome. Busca por nome. Filtros por clima e terreno. Detalhe com imagem, residentes e filmes.
5. **Favoritos**: abas Filmes, Personagens e Planetas. Funciona offline.
6. **Perfil**: nome do usuário e botão de sair.

Navegação: bottom navigation com Filmes, Personagens, Planetas e Favoritos. Perfil acessível pelo AppBar.

## Requisitos funcionais

| ID | Requisito |
|----|-----------|
| RF01 | Listar filmes, personagens e planetas com texto e imagem |
| RF02 | Busca por nome em cada lista |
| RF03 | Filtros conforme a seção de telas |
| RF04 | Detalhe resolve as URLs relacionadas em nomes legíveis |
| RF05 | Favoritar e desfavoritar itens a partir da lista e do detalhe |
| RF06 | Cadastro e login com senha protegida |
| RF07 | Sessão persiste após fechar o app |
| RF08 | Favoritos são isolados por usuário |
| RF09 | Dados já carregados ficam disponíveis sem internet |
| RF10 | Aviso visual quando os dados estiverem desatualizados (offline) |

## Requisitos não funcionais

- **Número de requisições**: lista carrega com o mínimo de chamadas. Resolução de URLs só no detalhe. Cache em todas as camadas.
- **Resiliência**: timeout de 10 s, retry limitado, tratamento de cold start do servidor de imagens (Render).
- **Segurança**: senha com PBKDF2 e salt. Nada sensível em log.
- **Desempenho**: uma lista já em cache deve aparecer sem esperar a rede.
- **Acessibilidade básica**: textos com contraste e tamanho legível; imagens com `semanticLabel`.

## Fonte das imagens
- Filmes: IMDb suggestion (ver `docs/apis.md`).
- Personagens, criaturas, droides e planetas: Databank.
- Se nenhuma imagem for encontrada, exibir placeholder local.

## Fora de escopo (v1)
- Sincronização de favoritos na nuvem entre dispositivos
- Recuperação de senha por e-mail
- Telas próprias para naves, veículos e espécies (aparecem só como texto no detalhe)
- Publicação nas lojas
- Internacionalização (somente português)

## Critérios de aceite do MVP
- [ ] Os três catálogos carregam com texto e imagem
- [ ] Busca e filtros funcionam nos três catálogos
- [ ] Detalhe resolve pelo menos planeta natal, filmes e espécie de um personagem
- [ ] Cadastro, login e logout funcionam; sessão sobrevive a fechar o app
- [ ] Dois usuários diferentes veem apenas os próprios favoritos
- [ ] Com o modo avião ligado, listas e detalhes já visitados continuam aparecendo, com aviso de offline
- [ ] `fvm flutter analyze` e `fvm flutter test` passam

## Decisões em aberto
- **Login local vs. Firebase Auth.** Padrão assumido: local (SQLite + hash). Se quiser favoritos sincronizados entre aparelhos, trocar para Firebase Auth + Firestore antes de começar a fatia de auth.
