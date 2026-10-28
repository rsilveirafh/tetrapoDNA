# Listas de espécies por grupo -------------------------------------------------
#
# Uma função por grupo, todas devolvendo o MESMO esquema de colunas
# (ver `ESQUEMA`). Para trocar a fonte de um grupo (ex.: anfíbios 2021 ->
# lista SBH 2026), basta reescrever a função do grupo e atualizar a linha
# correspondente em `GRUPOS`. O resto do pipeline lê só `data/especies.csv`.

ESQUEMA <- c("grupo", "classe", "ordem", "familia", "genero", "especie",
             "autoria", "ano_descricao", "endemica_br", "categoria_ameaca",
             "fonte_ameaca", "ufs", "uf_fonte", "biomas", "nota_lista",
             "fonte_lista", "versao_lista")

GRUPOS <- tibble::tribble(
  ~grupo,      ~rotulo,     ~classe,    ~versao,
  "anfibios",  "Anfíbios",  "Amphibia", "Segalla et al. 2021 (SBH)",
  "repteis",   "Répteis",   "Reptilia", "ReptiliaBR 0.4.0 (2026)",
  "aves",      "Aves",      "Aves",     "CBRO 2021 (2ª ed.)",
  "mamiferos", "Mamíferos", "Mammalia", "SBMz 2025-1"
)

# Citações e licenças (aparecem na página "Sobre").
FONTES_LISTAS <- tibble::tribble(
  ~grupo, ~citacao, ~licenca, ~url,
  "anfibios",
  "Segalla, M. et al. (2021). List of Brazilian Amphibians. Herpetologia Brasileira 10(1): 121-216. Dados estruturados (UF, bioma, categoria MMA) do pacote amphiBR (Barros, P.).",
  "Lista: CC-BY 4.0. Pacote amphiBR: GPL (>= 3) (só os dados são usados).",
  "https://doi.org/10.5281/zenodo.4716176",
  "repteis",
  "Entiauspe-Neto, O. M., Costa, H. C. & Guedes, T. B. ReptiliaBR: checklists and distribution maps for Brazilian reptiles (v0.4.0), a partir da lista da SBH.",
  "MIT",
  "https://github.com/omarentiauspe/ReptiliaBR",
  "aves",
  "Pacheco, J. F. et al. (2021). Annotated checklist of the birds of Brazil by the Brazilian Ornithological Records Committee, second edition. Ornithology Research 29: 94-105. Lista Primária.",
  "CC-BY 4.0",
  "https://doi.org/10.5281/zenodo.5138368",
  "mamiferos",
  "Abreu, E. F. et al. Lista de Mamíferos do Brasil (v2025-1). Comitê de Taxonomia da Sociedade Brasileira de Mastozoologia (CT-SBMz).",
  "CC-BY 4.0",
  "https://doi.org/10.5281/zenodo.18378485"
)

URLS_FONTES <- list(
  anfibios = "https://github.com/paulobarros/amphiBR/raw/master/data/segalla2021.rda",
  repteis = "https://raw.githubusercontent.com/omarentiauspe/ReptiliaBR/main/ReptiliaBR/data-raw/lista_repteis_raw.csv",
  aves = "https://zenodo.org/api/records/5138368/files/2021.07.26%20CBRO%202021%20Zenodo%20Release.xlsx/content",
  mamiferos = "https://zenodo.org/api/records/18378485/files/Mammalia_SBMz_v2025-1.xlsx/content"
)

ARQUIVOS_FONTES <- list(
  anfibios = "data-raw/amphiBR_segalla2021.rda",
  repteis = "data-raw/lista_repteis_raw.csv",
  aves = "data-raw/aves_cbro_2021.xlsx",
  mamiferos = "data-raw/mamiferos_sbmz_2025-1.xlsx"
)

padroniza <- function(x, grupo) {
  faltam <- setdiff(ESQUEMA, names(x))
  for (f in faltam) x[[f]] <- NA
  x$grupo <- grupo
  x$classe <- GRUPOS$classe[GRUPOS$grupo == grupo]
  x$versao_lista <- GRUPOS$versao[GRUPOS$grupo == grupo]
  x$fonte_lista <- FONTES_LISTAS$url[FONTES_LISTAS$grupo == grupo]
  x$endemica_br <- as.logical(x$endemica_br)
  x$ano_descricao <- as.integer(x$ano_descricao)
  x[ESQUEMA] |>
    mutate(across(where(is.character), str_squish)) |>
    filter(!is.na(especie), str_detect(especie, "^[A-Z][a-z-]+ [a-z-]+$")) |>
    distinct(especie, .keep_all = TRUE) |>
    arrange(ordem, familia, especie)
}

# Anfíbios: amphiBR::segalla2021 (UF e bioma 0/1, categoria MMA, endemismo).
lista_anfibios <- function(baixar = TRUE) {
  arq <- ARQUIVOS_FONTES$anfibios
  if (baixar) baixar_fonte(URLS_FONTES$anfibios, arq)
  amb <- new.env()
  load(arq, envir = amb)
  d <- amb$segalla2021
  uf_cols <- intersect(UFS, names(d))
  biomas <- c(AF = "Mata Atlântica", AMZ = "Amazônia", CER = "Cerrado",
              CAA = "Caatinga", PAN = "Pantanal", PAM = "Pampa")
  ufs <- apply(as.matrix(d[uf_cols]), 1, function(r) junta_ufs(uf_cols[r %in% 1]))
  bio <- apply(as.matrix(d[names(biomas)]), 1, function(r) {
    b <- unname(biomas[r %in% 1]); if (length(b)) paste(b, collapse = ";") else NA_character_
  })
  tibble(
    ordem = d$order, familia = d$family, genero = d$genus,
    especie = binomio(d$genus, d$epithet), autoria = d$author,
    ano_descricao = extrai_ano(d$author),
    endemica_br = case_when(d$endemic_br == "Yes" ~ TRUE, d$endemic_br == "No" ~ FALSE),
    categoria_ameaca = na_if(d$category, ""), fonte_ameaca = "MMA 2022 (via amphiBR)",
    ufs = ufs, uf_fonte = ifelse(is.na(ufs), NA, "lista"), biomas = bio,
    nota_lista = d$status
  ) |> padroniza("anfibios")
}

# Répteis: ReptiliaBR (1 linha por táxon, inclusive subespécies; colunas de UF
# com "X" = confirmado, "?" = duvidoso, "!" = contestado). Aqui só entra "X".
lista_repteis <- function(baixar = TRUE) {
  arq <- ARQUIVOS_FONTES$repteis
  if (baixar) baixar_fonte(URLS_FONTES$repteis, arq)
  raw <- read.csv(arq, stringsAsFactors = FALSE, encoding = "UTF-8",
                  na.strings = c("", "NA"), check.names = FALSE)
  raw[] <- lapply(raw, function(x) if (is.character(x)) str_squish(x) else x)
  # Epíteto abreviado ("Boa c. constrictor"): expande pela subespécie
  # nominotípica do grupo (a que começa com a mesma letra).
  abrev <- !is.na(raw$Species) & str_detect(raw$Species, "^[a-z]\\.$")
  chave <- paste(raw$Genus, raw$Species)
  for (k in unique(chave[abrev])) {
    i <- which(chave == k)
    letra <- substr(raw$Species[i[1]], 1, 1)
    nomin <- unique(raw$Subspecies[i][startsWith(raw$Subspecies[i], letra)])
    if (length(nomin) == 1) raw$Species[i] <- nomin
  }
  uf_cols <- intersect(UFS, names(raw))
  m <- as.matrix(raw[uf_cols])
  raw$uf_linha <- apply(m, 1, function(r) paste(uf_cols[toupper(r) %in% "X"], collapse = ";"))
  raw |>
    mutate(especie = binomio(Genus, Species)) |>
    group_by(especie) |>
    summarise(
      ordem = str_to_title(first(Order)), familia = first(Family), genero = first(Genus),
      endemica_br = any(End == "X", na.rm = TRUE),
      ufs = junta_ufs(unlist(strsplit(uf_linha, ";"))),
      nota_lista = paste(na.omit(unique(REVIEW)), collapse = "; "),
      .groups = "drop"
    ) |>
    mutate(uf_fonte = ifelse(is.na(ufs), NA, "lista"),
           nota_lista = na_if(nota_lista, "")) |>
    padroniza("repteis")
}

# Aves: CBRO 2021, aba "Lista Primária", só linhas de categoria "Espécie".
# A coluna Status traz residência (BR, VI, VA) e "En" = endêmica do Brasil.
lista_aves <- function(baixar = TRUE) {
  arq <- ARQUIVOS_FONTES$aves
  if (baixar) baixar_fonte(URLS_FONTES$aves, arq)
  d <- readxl::read_xlsx(arq, sheet = "Lista Primária", col_types = "text")
  names(d) <- sem_acento(names(d))
  d |>
    filter(categoria == "Espécie") |>
    transmute(
      ordem = ordem, familia = familia, genero = genero,
      especie = binomio(genero, especie),
      autoria = paste0(autoria, ", ", data), ano_descricao = extrai_ano(data),
      endemica_br = str_detect(coalesce(status, ""), "\\bEn\\b"),
      nota_lista = paste("Status CBRO:", status)
    ) |>
    padroniza("aves")
}

# Mamíferos: SBMz 2025-1, aba "LISTA" (UF e biomas por extenso, endemismo,
# categoria MMA 2023).
lista_mamiferos <- function(baixar = TRUE) {
  arq <- ARQUIVOS_FONTES$mamiferos
  if (baixar) baixar_fonte(URLS_FONTES$mamiferos, arq)
  d <- readxl::read_xlsx(arq, sheet = "LISTA", col_types = "text")
  names(d) <- str_replace_all(sem_acento(names(d)), "[^a-z0-9]+", "_")
  tibble(
    ordem = d$ordem, familia = d$familia, genero = d$genero,
    especie = binomio(d$genero, d$especie),
    autoria = paste0(d$autor, ", ", d$ano), ano_descricao = extrai_ano(d$ano),
    endemica_br = case_when(sem_acento(d$endemico_br) == "sim" ~ TRUE,
                            sem_acento(d$endemico_br) == "nao" ~ FALSE),
    categoria_ameaca = na_if(d$mma_2023, "N/A"), fonte_ameaca = "MMA 2023 (via SBMz)",
    ufs = vapply(d$ocorrencia_uf, uf_por_extenso, character(1)),
    biomas = vapply(d$ocorrencia_biomas, bioma_por_extenso, character(1))
  ) |>
    mutate(uf_fonte = ifelse(is.na(ufs), NA, "lista")) |>
    padroniza("mamiferos")
}

# Nome por extenso -> sigla, tolerante a acento e erro de digitação comum.
NOMES_UF <- c(
  "acre" = "AC", "alagoas" = "AL", "amapa" = "AP", "amazonas" = "AM",
  "bahia" = "BA", "ceara" = "CE", "distrito federal" = "DF",
  "espirito santo" = "ES", "goias" = "GO", "maranhao" = "MA",
  "mato grosso" = "MT", "mato groso" = "MT", "mato grosso do sul" = "MS",
  "minas gerais" = "MG", "para" = "PA", "paraiba" = "PB", "parana" = "PR",
  "pernambuco" = "PE", "piaui" = "PI", "piau" = "PI", "rio de janeiro" = "RJ",
  "rio grande do norte" = "RN", "rio grande norte" = "RN",
  "rio grande do sul" = "RS", "rio grando sul" = "RS", "rondonia" = "RO",
  "roraima" = "RR", "roraima?" = "RR", "santa catarina" = "SC",
  "sao paulo" = "SP", "sergipe" = "SE", "tocantins" = "TO"
)

uf_por_extenso <- function(txt) {
  if (is.na(txt)) return(NA_character_)
  partes <- sem_acento(unlist(strsplit(txt, "[,;.]")))
  partes <- str_trim(str_remove(partes, "\\(.*\\)"))
  # "rio de janeiro rio grande do sul" (vírgula faltando)
  partes <- unlist(lapply(partes, function(p) {
    if (p %in% names(NOMES_UF)) return(p)
    achados <- names(NOMES_UF)[vapply(names(NOMES_UF), function(n) str_detect(p, fixed(n)), logical(1))]
    achados <- achados[!vapply(achados, function(a) any(str_detect(setdiff(achados, a), fixed(a))), logical(1))]
    achados
  }))
  junta_ufs(unname(NOMES_UF[partes]))
}

bioma_por_extenso <- function(txt) {
  if (is.na(txt)) return(NA_character_)
  p <- sem_acento(txt)
  b <- c(
    "Amazônia" = str_detect(p, "amazon"),
    "Caatinga" = str_detect(p, "caati"),
    "Cerrado" = str_detect(p, "cerr"),
    "Mata Atlântica" = str_detect(p, "mata at"),
    "Pampa" = str_detect(p, "pampa"),
    "Pantanal" = str_detect(p, "pantanal"),
    "Marinho/costeiro" = str_detect(p, "marinho|costeiro|estuarin")
  )
  if (!any(b)) NA_character_ else paste(names(b)[b], collapse = ";")
}

# Monta a união de todas as listas no esquema comum.
monta_listas <- function(grupos = GRUPOS$grupo, baixar = TRUE) {
  funs <- list(anfibios = lista_anfibios, repteis = lista_repteis,
               aves = lista_aves, mamiferos = lista_mamiferos)
  purrr::map(grupos, function(g) {
    msg("Lista: ", g)
    funs[[g]](baixar = baixar)
  }) |> bind_rows()
}
