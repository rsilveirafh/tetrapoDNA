# tetrapoDNA: a lacuna de DNA dos tetrápodes do Brasil

Painel que responde a uma pergunta simples: **quais espécies de anfíbios, répteis, aves e mamíferos
do Brasil ainda não têm nenhuma sequência de DNA pública?** Para cada espécie das listas oficiais
das sociedades científicas, o painel conta os registros no [BOLD Systems](https://boldsystems.org)
e no [GenBank](https://www.ncbi.nlm.nih.gov/genbank/), mostra a lacuna por grupo, família e estado,
e convida pesquisadores a **adotar uma espécie**: dizer em público que vão sequenciá-la.

O recorte é de tetrápodes terrestres (e os marinhos que as listas desses grupos trazem); peixes não
entram.

Atualização automática semanal (GitHub Actions); site estático no GitHub Pages.

## O que o painel mostra

- **Visão geral**: espécies na lista, com DNA, a verificar e sem DNA (total e por grupo); faixas de
  registros no BOLD (as mesmas do [iBOL Europe Gap List](https://species.iboleurope.org));
  famílias com mais espécies sem DNA; as descritas há mais tempo e ainda sem DNA; novidades.
- **Espécies sem DNA**: tabela filtrável por grupo, UF, família, endemismo e ameaça, ordenada por
  prioridade (ameaçada > DD > endêmica > descrita há mais tempo), com botão "adotar".
- **Por estado**: mapa e tabela por UF.
- **Adote uma espécie** e **Fontes e método**.

### Situação de cada espécie

| Situação | Critério |
|---|---|
| com DNA | ao menos um registro no BOLD ou no GenBank sob o nome da lista ou sob outra combinação do mesmo epíteto (transferência de gênero) |
| a verificar | sem DNA sob o nome da lista, mas há motivo para desconfiar do nome: sequências só sob sinônimo/nome aceito no CTFB; nome ausente do CTFB ou não reconhecido pelo GBIF; nome da lista é sinônimo no CTFB; sinônimos conhecidos; nome aparece no GenBank fora do campo Organism; gênero com ≥ 500 registros no GenBank |
| sem DNA | nenhuma sequência pública sob o nome e os sinônimos conhecidos, e nenhum sinal acima |

O painel nunca afirma "não existe DNA" (o risco da **falsa órfã**: o banco usa um nome antigo).
A coluna `observacao` diz o motivo de cada "a verificar".

## Fontes

| Grupo | Lista de referência | Licença |
|---|---|---|
| Anfíbios | Drummond et al. (2026), *Lista de Anfíbios do Brasil*, Herpetologia Brasileira 15(2). [doi:10.5281/zenodo.18340087](https://doi.org/10.5281/zenodo.18340087), via `amphiBR::drummond2026` ([amphiBR](https://github.com/paulobarros/amphiBR); enquanto o PR #2 não entra, do fork `rsilveirafh/amphiBR`). UF, bioma, endemismo e DD/NT/LC de Segalla et al. (2021) ([doi:10.5281/zenodo.4716176](https://doi.org/10.5281/zenodo.4716176)) pelo nome de 2021 | listas CC-BY 4.0; amphiBR GPL ≥ 3 (só dados) |
| Répteis | [ReptiliaBR](https://github.com/omarentiauspe/ReptiliaBR) v0.4.0 (Entiauspe-Neto, Costa & Guedes) | MIT |
| Aves | CBRO: Pacheco et al. (2021), *Annotated checklist of the birds of Brazil*, 2ª ed., Lista Primária. [doi:10.5281/zenodo.5138368](https://doi.org/10.5281/zenodo.5138368) | CC-BY 4.0 |
| Mamíferos | SBMz: Abreu et al., *Lista de Mamíferos do Brasil* v2025-1. [doi:10.5281/zenodo.18378485](https://doi.org/10.5281/zenodo.18378485) | CC-BY 4.0 |

Além das listas:

- **BOLD Systems**, portal v5: `GET https://portal.boldsystems.org/api/summary?query=tax:class:<Classe>&fields=species&reduce=false`
  (uma chamada por classe; outra com `;geo:country/ocean:Brazil`). Sem chave.
- **NCBI E-utilities**: `esearch.fcgi?db=nuccore&term=("Gênero epíteto"[Organism] OR "sinônimo"[Organism])&rettype=count`.
  Sem chave: 3 req/s; com `NCBI_API_KEY`: 10 req/s.
- **Catálogo Taxonômico da Fauna do Brasil** (CTFB/JBRJ), API REST `https://fauna.jbrj.gov.br/rest/mv_planilha_extendida`:
  sinônimos, UF (aves; anfíbios sem UF na lista), endemismo e ano de descrição quando faltam.
- **Portaria MMA nº 1.704/2026** (Lista Nacional Oficial das Espécies da Fauna Ameaçadas de Extinção,
  Anexo I): categoria nacional de ameaça. Extraída do PDF uma vez por `data-raw/mma_portaria_1704_2026.R`
  (precisa de `pdftools`); o pipeline lê o CSV versionado.
- **GBIF Backbone** (`api.gbif.org/v1/species/match` e `/synonyms`): sinônimos das candidatas a órfã
  (o CTFB quase não tem sinônimos de aves e répteis). Cache de 90 dias em `data/gbif_sinonimos.csv`.
- **IBGE**, malha de UFs (API de malhas, qualidade mínima) para o mapa.

## Estrutura

```
R/listas.R      uma função por grupo -> esquema comum (troque a fonte de um grupo aqui)
R/ameaca.R      categoria nacional (Portaria MMA 1.704/2026)
R/ctfb.R        CTFB: sinônimos, UF, endemismo
R/gbif.R        GBIF: sinônimos das candidatas a órfã
R/bold.R        BOLD: resumo por classe, soma sob nome + sinônimos
R/genbank.R     NCBI: contagem incremental com cache, pausa e retry
R/junta.R       situação, observação, histórico e eventos
scripts/atualiza.R  pipeline completo
data/           saídas versionadas (o diff do git é o histórico)
  especies.csv     lista unificada (4 grupos, esquema comum)
  cobertura.csv    1 linha por espécie: contagens, situação, observação
  genbank.csv      cache do GenBank (termo de busca, contagem, data)
  historico.csv    totais por grupo a cada execução
  eventos.csv      espécies que ganharam DNA (data)
  adocoes.csv      adoções aprovadas (lido pelo site)
  ctfb.csv, cache/ insumos (CTFB e resumo do BOLD)
data-raw/       cópias das fontes (usadas se o download falhar)
*.qmd           site Quarto (dashboards com OJS: filtros no navegador, sem servidor)
```

Para trocar a lista de um grupo (por exemplo, aves CBRO 2021 → uma edição nova), reescreva a
função do grupo em `R/listas.R` mantendo as colunas de `ESQUEMA`, e atualize a linha do grupo em
`GRUPOS` e `FONTES_LISTAS`. Nada mais muda. Se a lista nova traz o nome anterior das espécies,
ponha-o em `sinonimos_lista` (como em `lista_anfibios()`): ele entra na busca de DNA.

## Como rodar

Requisitos: R ≥ 4.3 e Quarto ≥ 1.5.

```r
install.packages(c("httr2", "jsonlite", "dplyr", "readr", "tidyr", "stringr", "purrr", "readxl", "tibble"))
```

```sh
# coleta completa (a 1ª vez leva ~1 h sem chave do NCBI; ~15 min com chave)
Rscript scripts/atualiza.R

# só um pedaço do GenBank (o resto fica para a próxima execução)
Rscript scripts/atualiza.R --max-genbank=500
Rscript scripts/atualiza.R --max-minutos=30 --grupos-genbank=anfibios,repteis

# site
quarto preview
```

Variáveis de ambiente opcionais: `NCBI_API_KEY` (chave em *Account settings* da conta NCBI) e
`NCBI_EMAIL` (o NCBI pede um e-mail de contato).

A consulta ao GenBank é incremental: a cada execução vão primeiro as espécies novas ou cujo termo de
busca mudou, depois as que estavam sem DNA (rechecadas toda semana) e por fim as consultadas há
mais de 28 dias. O cache é salvo a cada 100 consultas; se a execução cair, a próxima continua de onde
parou. Se o BOLD ou o CTFB falharem, o pipeline reaproveita o último resultado salvo e registra o
aviso em `data/status.json`.

## Adote uma espécie

1. Na página **Espécies sem DNA**, filtre e clique em **adotar** (abre o formulário
   `.github/ISSUE_TEMPLATE/adote.yml` com a espécie preenchida).
2. Quem mantém o painel revisa, põe a etiqueta `adotada` e acrescenta uma linha em
   `data/adocoes.csv` (`especie,situacao,instituicao,responsavel,desde,issue`), só com o consentimento
   marcado no formulário.
3. Quando a primeira sequência aparece, a atualização semanal registra a espécie em `data/eventos.csv`
   e ela vira **sequenciada** (mude `situacao` em `adocoes.csv`).

Achou sequência sob outro nome? Use o formulário **Corrigir uma espécie**.

Boas práticas: priorizar tecido já depositado em coleções; cadastro no SisGen (Lei 13.123/2015);
depositar as sequências com voucher.

## Publicar (GitHub Pages)

1. Crie o repositório e envie o código.
2. *Settings → Pages → Source: GitHub Actions*.
3. *Settings → Secrets and variables → Actions*: `NCBI_API_KEY` e `NCBI_EMAIL` (opcionais, mas a
   chave deixa a coleta 3× mais rápida).
4. *Actions → Atualiza dados → Run workflow* para a primeira coleta; ela grava os dados e publica.
   Depois roda sozinha todo domingo.

## Licença

Código: MIT. Tabelas derivadas em `data/`: CC-BY 4.0; cite também as listas originais.

---

**In English.** This dashboard tracks the DNA barcode and sequence gap for Brazilian tetrapods
(amphibians, reptiles, birds and mammals). For every species in the official national checklists
(SBH, ReptiliaBR, CBRO, SBMz) it counts public records in BOLD Systems and NCBI GenBank, checking
synonyms from the Brazilian Fauna Taxonomic Catalogue (CTFB) to avoid "false orphans", and
highlights species with no public DNA at all by group, family and state. Researchers can "adopt" a
species, i.e. publicly commit to sequencing it, through a GitHub issue form. Data are refreshed weekly
by GitHub Actions and the site is a static Quarto dashboard on GitHub Pages.
