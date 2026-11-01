# Validação da classificação

Objetivo: medir quantas vezes o painel erra, nos dois sentidos.

- **Falsa órfã:** o painel diz "sem DNA" (ou "a verificar"), mas há dado de DNA público da espécie.
- **Falso positivo:** o painel diz "com DNA", mas as sequências não são da espécie.

## 1. Amostra

`scripts/amostra_validacao.R` sorteia de `data/cobertura.csv` (dados de 2026-10-30), com semente
20261030. Dentro de cada situação, o número por grupo é proporcional ao tamanho do grupo.

| Situação no painel | Espécies | Para quê |
|---|---|---|
| sem DNA | 50 | taxa de falsa órfã |
| a verificar | 50 | o que as "a verificar" são de fato |
| com DNA | 20 | controle de falso positivo |

`amostra.csv` guarda o sorteio, com os links de busca de cada espécie.

## 2. Checagem assistida

`scripts/confere_amostra.R` junta evidências por caminhos diferentes dos do pipeline, que conta o
BOLD pelo nome exato, por classe, e o GenBank pelo campo Organism com os sinônimos:

- **Taxonomia do NCBI:** nomes que o NCBI conhece para a espécie (sinônimos, grafias) e o taxid.
- **nuccore pelo taxid** (`txid[Organism:exp]`), **SRA** e **BioSample**.
- **nuccore em todos os campos:** o nome, os sinônimos e os nomes do NCBI como frase; e o epíteto em
  registros do gênero ou da família ("sp.", "cf.", gêneros antigos).
- **BOLD:** cada nome exato e, no gênero de cada nome, os nomes com a mesma raiz do epíteto.
- **Para as "com DNA":** título e organismo dos primeiros registros do GenBank.

A saída fica em `checagem.csv`. Em seguida, cada caso com algum sinal foi aberto e julgado: o título
dos registros, o tipo de dado no SRA, o gênero antigo no GenBank. O julgamento de cada espécie, com
o nome no banco, um número de acesso e o motivo, está em `julgamento.csv`. A checagem e o julgamento
foram feitos por um assistente de IA (Claude) em 2026-10-31 e precisam de auditoria humana (seção 4).

**Critérios.** Conta como DNA montado: sequência no GenBank ou no BOLD identificada até a espécie,
sob o nome da lista, um sinônimo, um gênero antigo ou o nome trinomial de um táxon elevado a espécie.
Não contam: registros só até gênero ("sp.", "cf.", "aff.") e sequências de outra espécie que só
compartilham o epíteto. "Só SRA" é a espécie que tem apenas dados brutos de sequenciamento (UCE,
ddRAD, RNA-Seq, genoma) no SRA, sem nada montado no GenBank ou no BOLD. "A verificar" fica para os
desmembramentos em que as sequências estão sob o nome da espécie-mãe e não dá para saber, sem olhar
a localidade, se alguma é da espécie da lista.

## 3. Resultados

`scripts/resume_validacao.R` calcula as proporções, com intervalo de confiança de Wilson (95%), e a
estimativa para o painel inteiro (`resultado.csv`).

| No painel | Conferido | Amostra | % (IC 95%) | Estimativa no painel |
|---|---|---|---|---|
| sem DNA (277) | sem DNA | 36/50 | 72% (58–83%) | ~199 (162–229) |
| | só SRA | 14/50 | 28% (17–42%) | ~78 (48–115) |
| a verificar (444) | sem DNA | 37/50 | 74% (60–84%) | ~329 (268–374) |
| | com DNA | 6/50 | 12% (6–24%) | ~53 (25–106) |
| | só SRA | 4/50 | 8% (3–19%) | ~36 (14–84) |
| | a verificar | 3/50 | 6% (2–16%) | ~27 (9–72) |
| com DNA (4.159) | com DNA | 20/20 | 100% (84–100%) | |

Escopo (decidido em 2026-11-01): o painel mede sequências de DNA **depositadas** no BOLD ou no
GenBank, de qualquer marcador. Leituras brutas no SRA não contam como sequência depositada; viraram
a marca "só dados brutos", que não muda a situação. Nessa leitura, as "só SRA" da tabela continuam
"sem DNA" (ou "a verificar"), e a única correção de fato nas "a verificar" são as 6 com DNA.

O que isso diz:

1. **Para o que o painel mede (sequências montadas no GenBank e no BOLD), não houve falsa órfã**
   entre as 50 "sem DNA" nem falso positivo entre as 20 "com DNA".
2. **O SRA é o ponto cego.** 28% das "sem DNA" têm dados brutos públicos, quase todas aves de um
   projeto de filogenômica de suboscines (UCE), além de ddRAD, RNA-Seq e captura em répteis e num
   mamífero.
3. **A maioria das "a verificar" é sem DNA** (74%). Os alertas valem coisas diferentes:
   - **Nome não reconhecido no GBIF** (19 na amostra): 5 com DNA e 1 só SRA. Cinco das seis "a
     verificar" que têm DNA estão sob um gênero antigo ou um nome trinomial que nenhuma fonte de
     sinônimos conhecia. A sexta (*Thlypopsis pyrrhocoma*) o painel já ligava ao nome antigo.
   - **Sequências só sob nome alternativo** (4): 3 desmembramentos de fato duvidosos e 1 com DNA.
   - **Gênero muito sequenciado** (35): 29 sem DNA, 3 só SRA, 2 desmembramentos e 1 com DNA (que
     também tinha o alerta do GBIF). Sozinho, é um alerta fraco.

## 4. Auditoria humana

`auditoria.xlsx` traz 20 espécies sorteadas por estrato (semente 20261031), com mais peso nos casos
que mudam de situação: 6 "só SRA", 3 "com DNA" sob outro nome, 1 desmembramento, 3 "a verificar" que
são sem DNA, 5 "sem DNA" e 2 "com DNA". Para cada uma estão o julgamento da checagem assistida e os
links de busca.

Quem audita preenche `concorda` (sim, não ou em parte), `situacao_auditor` e um comentário. O ideal
é que duas pessoas auditem sem ver a resposta uma da outra (por exemplo, Ricardo e Adrian), para
medir a concordância. Leva cerca de 5 minutos por espécie.
