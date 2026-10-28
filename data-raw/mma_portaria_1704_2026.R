# Extrai do PDF da Portaria MMA nº 1.704, de 16/06/2026 (Anexo I: Lista Nacional
# Oficial das Espécies da Fauna Ameaçadas de Extinção) as linhas de tetrápodes.
# Roda uma vez (precisa do pacote pdftools); o CSV resultante é versionado e é
# o que o pipeline lê. Peixes e invertebrados aquáticos estão em outra portaria
# (GM/MMA nº 1.667/2026) e ficam fora do recorte.
#
# Uso: Rscript data-raw/mma_portaria_1704_2026.R

library(pdftools)

url <- "https://www.gov.br/icmbio/pt-br/assuntos/biodiversidade/pan/saiba-mais/documentos-e-downloads/10-portaria-mma-no-1-704-de-16-de-junho-de-2026.pdf"
pdf <- tempfile(fileext = ".pdf")
download.file(url, pdf, mode = "wb", quiet = TRUE)

classes <- c("Amphibia", "Reptilia", "Aves", "Mammalia")
cat_rx <- "^(CR|EN|VU|EW|EX|RE|\\(PE\\)|\\(PEW\\))$"

paginas <- pdf_data(pdf)
txt <- pdf_text(pdf)
fim <- which(grepl("ANEXO II", txt))[1]   # Anexo II = extintas; fora
if (is.na(fim)) fim <- length(paginas)

registros <- list()
for (p in seq_len(fim)) {
  w <- paginas[[p]]
  if (p == fim) {
    y_fim <- w$y[w$text == "ANEXO"][which(w$text[which(w$text == "ANEXO") + 1] == "II")]
    if (length(y_fim)) w <- w[w$y < min(y_fim), ]
  }
  w$linha <- round(w$y / 2)
  linhas <- split(w, w$linha)
  ancoras <- Filter(function(l) {
    l <- l[order(l$x), ]
    grepl("^[0-9]+$", l$text[1]) && any(l$text %in% classes)
  }, linhas)
  if (!length(ancoras)) next
  y_anc <- vapply(ancoras, function(l) mean(l$y), numeric(1))
  x_fam <- min(unlist(lapply(ancoras, function(l) l$x[grepl("idae$", l$text)])))
  # palavras da coluna de espécie/categoria (à direita da família), fora das âncoras
  for (k in seq_along(ancoras)) {
    a <- ancoras[[k]][order(ancoras[[k]]$x), ]
    i_fam <- which(grepl("idae$", a$text))[1]
    i_cls <- which(a$text %in% classes)[1]
    registros[[length(registros) + 1]] <- list(
      pagina = p, y = y_anc[k], numero = as.integer(a$text[1]),
      classe = a$text[i_cls], ordem = a$text[i_cls + 1], familia = a$text[i_fam],
      palavras = a[a$x > a$x[i_fam], c("x", "y", "text")]
    )
  }
  resto <- w[!(w$linha %in% as.numeric(names(ancoras))) & w$x > x_fam + 30, c("x", "y", "text")]
  resto <- resto[!grepl("^(Espécie|ou|Subespécie|Categoria|de|risco)$", resto$text), ]
  for (j in seq_len(nrow(resto))) {
    d <- abs(y_anc - resto$y[j])
    if (min(d) > 14) next
    k <- which.min(d)
    idx <- which(vapply(registros, function(r) r$pagina == p && r$y == y_anc[k], logical(1)))
    registros[[idx]]$palavras <- rbind(registros[[idx]]$palavras, resto[j, ])
  }
}

lista <- do.call(rbind, lapply(registros, function(r) {
  pw <- r$palavras[order(r$palavras$y, r$palavras$x), ]
  categ <- pw$text[grepl(cat_rx, pw$text)]
  nome <- pw$text[!grepl(cat_rx, pw$text) & pw$text != "*"]
  data.frame(numero = r$numero, classe = r$classe, ordem = r$ordem, familia = r$familia,
             taxon = paste(nome, collapse = " "),
             categoria = paste(categ, collapse = " "), stringsAsFactors = FALSE)
}))
lista$especie <- sub("^(\\S+ \\S+).*$", "\\1", lista$taxon)
lista <- lista[order(lista$classe, lista$numero), ]
rownames(lista) <- NULL

print(lista[!grepl("^(CR|EN|VU)", lista$categoria), ])
print(table(lista$classe))
write.csv(lista, "data-raw/mma_portaria_1704_2026.csv", row.names = FALSE, fileEncoding = "UTF-8")
