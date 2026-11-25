# Gera uma pagina Quarto por funcao a partir da documentacao roxygen2
#
# Uso no console R, a partir da raiz deste projeto:
#   source("scripts/funcoes.R", encoding = "UTF-8")
# ou no terminal:
#   Rscript scripts/funcoes.R ../predictive.factory
#
# Entrada (primeiro argumento ou variavel PF_PACOTE):
#   - raiz do pacote (pasta com DESCRIPTION): executa roxygen2::roxygenise()
#     e le <pacote>/man/*.Rd. Defina PF_ROXYGENISE=false para apenas ler man/;
#   - ou uma pasta contendo arquivos .Rd ja gerados.
# Saida:
#   referencia/<funcao>.qmd    uma pagina por topico Rd (listadas no menu lateral)
#   _referencia-indice.qmd     tabela de funcoes incluida no capitulo 18
#   _referencia-pdf.qmd        mesmas paginas, como secoes, para o ebook_pdf.qmd
# Requisitos: R (pacote tools, nativo) e Quarto CLI no PATH (usa o pandoc embutido).

if(!isTRUE(l10n_info()[["UTF-8"]])){
  invisible(Sys.setlocale("LC_CTYPE", "C.UTF-8"))
}
commandArgs <- commandArgs(trailingOnly = TRUE)
sourcePath <- if(length(commandArgs) > 0L) commandArgs[1L] else Sys.getenv("PF_PACOTE", "../predictive.factory")
runRoxygen <- !identical(tolower(Sys.getenv("PF_ROXYGENISE", "true")), "false")
generatedMark <- "<!-- Gerado por scripts/funcoes.R. Edite o roxygen2 da funcao, nao este arquivo. -->"

if(!dir.exists(sourcePath)){
  message("Pasta de origem nao encontrada: ", sourcePath, ". Paginas de funcoes mantidas sem alteracao.")
} else {
  rdDir <- sourcePath
  if(file.exists(file.path(sourcePath, "DESCRIPTION"))){
    if(runRoxygen && requireNamespace("roxygen2", quietly = TRUE)){
      roxygen2::roxygenise(sourcePath, roclets = "rd")
    }
    rdDir <- file.path(sourcePath, "man")
  }
  rdFiles <- sort(list.files(rdDir, pattern = "\\.[Rr]d$", full.names = TRUE))

  quartoPath <- Sys.which("quarto")
  if(!nzchar(quartoPath)){
    stop("Quarto CLI nao encontrado no PATH da sessao R.")
  }

  sectionNames <- c(
    "Description" = "Descri\u00e7\u00e3o", "Usage" = "Uso", "Arguments" = "Argumentos",
    "Details" = "Detalhes", "Value" = "Valor", "Note" = "Observa\u00e7\u00e3o",
    "Author(s)" = "Autoria", "References" = "Refer\u00eancias", "See Also" = "Veja tamb\u00e9m",
    "Examples" = "Exemplos", "Format" = "Formato", "Source" = "Fonte")

  dir.create("referencia", showWarnings = FALSE)
  generatedFiles <- character()
  indexRows <- character()
  pdfLines <- character()

  for(rdPath in rdFiles){
    rdObject <- tools::parse_Rd(rdPath, encoding = "UTF-8")
    tags <- vapply(rdObject, function(node) attr(node, "Rd_tag"), character(1))
    docType <- paste(unlist(rdObject[tags == "\\docType"]), collapse = "")
    isPackageDoc <- grepl("package", docType)
    if(any(tags == "\\keyword") && any(grepl("internal", unlist(rdObject[tags == "\\keyword"])))){
      next
    }
    rdName <- trimws(paste(unlist(rdObject[tags == "\\name"]), collapse = ""))
    rdTitle <- trimws(gsub("\\s+", " ", paste(unlist(rdObject[tags == "\\title"]), collapse = "")))
    fileStem <- gsub("[^A-Za-z0-9_-]", "-", rdName)

    htmlFile <- tempfile(fileext = ".html")
    mdFile <- tempfile(fileext = ".md")
    tools::Rd2HTML(rdPath, out = htmlFile, no_links = TRUE, outputEncoding = "UTF-8")
    status <- system2(quartoPath, c("pandoc", shQuote(htmlFile), "-f", "html",
      "-t", "gfm",
      "--wrap=none", "-o", shQuote(mdFile)))
    if(status != 0L){
      stop("Falha na conversao do topico ", rdName, ".")
    }
    bodyLines <- readLines(mdFile, warn = FALSE, encoding = "UTF-8")

    # Remove a tabela de cabecalho e o titulo gerados pelo Rd2HTML
    titleLine <- grep("^## ", bodyLines)[1L]
    if(!is.na(titleLine)){
      bodyLines <- bodyLines[-seq_len(titleLine)]
    }
    # Secoes em portugues e no nivel 2
    for(englishName in names(sectionNames)){
      pattern <- sprintf("^#{2,4} %s\\s*$", gsub("([()])", "\\\\\\1", englishName))
      bodyLines <- sub(pattern, sprintf("## %s", sectionNames[[englishName]]), bodyLines)
    }
    bodyLines <- sub("^#{3,4} ", "## ", bodyLines)
    bodyLines <- sub("^``` *R$", "``` r", bodyLines)
    bodyLines <- bodyLines[!grepl("^</?div[^>]*>$", bodyLines)]

    pageLines <- c(
      generatedMark,
      "",
      sprintf("# `%s` {#fn-%s}", rdName, fileStem),
      "",
      sprintf("::: {.pf-fn-title}\n%s\n:::", rdTitle),
      "",
      bodyLines)
    targetPath <- file.path("referencia", sprintf("%s.qmd", fileStem))
    writeLines(pageLines, targetPath, useBytes = TRUE)
    generatedFiles <- c(generatedFiles, targetPath)

    rowLabel <- if(isPackageDoc) "pacote" else "fun\u00e7\u00e3o"
    indexRows <- c(indexRows, sprintf("| [`%s`](referencia/%s.qmd) | %s | %s |",
      rdName, fileStem, rdTitle, rowLabel))
    # No PDF cada funcao vira secao do capitulo de referencia (titulos um nivel abaixo)
    pdfPage <- pageLines[-1L]
    pdfPage <- sub("^(#+) ", "#\\1 ", pdfPage)
    pdfLines <- c(pdfLines, pdfPage, "")
  }

  # Remove paginas geradas anteriormente cujo topico deixou de existir
  previousFiles <- list.files("referencia", pattern = "\\.qmd$", full.names = TRUE)
  for(previousPath in setdiff(previousFiles, generatedFiles)){
    firstLine <- readLines(previousPath, n = 1L, warn = FALSE, encoding = "UTF-8")
    if(identical(firstLine, generatedMark)){
      unlink(previousPath)
    }
  }

  if(length(indexRows) == 0L){
    indexLines <- c(generatedMark, "", "Nenhuma fun\u00e7\u00e3o documentada foi encontrada.")
  } else {
    indexLines <- c(generatedMark, "", "| Fun\u00e7\u00e3o | Descri\u00e7\u00e3o | Tipo |", "|---|---|---|", indexRows)
  }
  writeLines(indexLines, "_referencia-indice.qmd", useBytes = TRUE)
  writeLines(c(generatedMark, "", pdfLines), "_referencia-pdf.qmd", useBytes = TRUE)
  message("Paginas de funcoes geradas: ", length(generatedFiles), ".")
}
