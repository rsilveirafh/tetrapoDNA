# Pendências

Lista de trabalho anotada em 2026-11-01. Riscar ou apagar o que for feito.

## Artigo (com Adrian Garda)

- [ ] **Auditoria humana da validação:** Ricardo e Adrian conferem, sem ver a resposta um do outro,
      as 20 espécies de `validacao/auditoria.xlsx` (colunas `concorda`, `situacao_auditor`,
      `comentario_auditor`). Depois, calcular a concordância e juntar ao `validacao/PROTOCOLO.md`.
- [ ] **Congelar a versão dos dados do artigo** no Zenodo, com DOI (o painel muda toda semana).
- [ ] **Refazer a validação com o pipeline final**, depois das melhorias abaixo (nova amostra, mesma
      lógica dos scripts `scripts/amostra_validacao.R`, `confere_amostra.R`, `resume_validacao.R`).
- [ ] **Análises do artigo:**
  - efeito dos sinônimos: quantas espécies só têm DNA por sinônimo ou outra combinação do epíteto;
  - BOLD × GenBank; cobertura por material coletado no Brasil (`n_bold_br`), como Arana et al. 2024;
  - modelos do que explica a lacuna (ano de descrição, endemismo, ameaça, nº de UFs, grupo, com
    família como efeito aleatório), como Oliveira et al. 2024 e Guedes et al. 2024;
  - "só dados brutos" como resultado secundário (22% das sem DNA têm leituras no SRA).
- [ ] **Periódico:** *Perspectives in Ecology and Conservation* (diamante, ABECO paga) é a primeira
      opção; híbridos pela via assinatura como alternativa (ver `notas/literatura.md`).
- [ ] Conferir os itens marcados **[conferir]** em `notas/literatura.md` antes de citar.
- [ ] Mais tarde: versão para a América do Sul (ponto de partida: Šmíd 2022).

Escopo decidido: **sequências de DNA depositadas (qualquer marcador) no BOLD ou no GenBank.**
Genômica e eDNA ficam fora; o SRA entra só como a marca "só dados brutos".

## Pipeline

- [ ] **Epíteto em gêneros antigos:** buscar no GenBank o epíteto dentro da família (como em
      `scripts/confere_amostra.R`) e listar os nomes candidatos na observação, como sinal de "a
      verificar". Excluir candidatos que são espécies válidas da própria lista (ex.: *Mionectes
      rufiventris* ≠ *Nengetus rufiventris*). Teria achado as 6 "a verificar" com DNA da validação
      (*Gastrotheca ernestoi*, *Amazilia rondoniae*, *Neoxolmis rufiventris*, *Nyctipolus
      nigrescens*, *Pyrrhocoma ruficeps*, *Sclerurus mexicanus peruvianus*).
- [ ] **Rebaixar o alerta "gênero muito sequenciado":** sozinho, não deve tornar a espécie "a
      verificar" (na validação, 29 de 35 eram sem DNA). Manter como nota.
- [ ] **Aves sem UF** (901 espécies, 42 delas sem DNA ou a verificar): ocorrência por estado pelo
      eBird (`/v2/product/spplist/BR-XX`, chave gratuita), casando a taxonomia com a CBRO.
- [ ] Mostrar espécies extintas (EX) da Portaria MMA, hoje descartadas.
- [ ] Usar sinônimos na busca de fotos do iNaturalist (mais fotos).

## Site, antes da 1.0

- [ ] Link que guarda os filtros (compartilhar uma visão), como no site do Luypaert.
- [ ] Botão "Citar" com texto, BibTeX e RIS (melhor depois do DOI do Zenodo).
- [ ] Baixar em CSV só as espécies filtradas.
- [ ] Encurtar a observação de "sem DNA" para o trecho do SRA aparecer no cartão.
- [ ] Filtros recolhíveis no celular (Espécies).

## Outros

- [ ] Apagar o branch `atualiza-lista-2026` do fork do amphiBR depois que o PR
      paulobarros/amphiBR#2 entrar (o pipeline lê dele enquanto isso: `R/listas.R`, `AMPHIBR`).
- [ ] Atualizar a página "About" do site pessoal (ainda diz Conciso-TI como emprego atual).
