# Preparacao das referencias Rd e dos exemplos incluidos no documento
library(stringr)
library(tools)

dir.create("vignettes/images", recursive = TRUE, showWarnings = FALSE)
assetSources <- c("assets/modelo-er-reservado.png", "pkgdown/extra.css")
assetTargets <- c("vignettes/images/modelo-er-reservado.png",
  "vignettes/images/document.css")
assetStatus <- file.copy(assetSources, assetTargets, overwrite = TRUE)
if(!all(assetStatus)){
  stop("Não foi possível preparar os recursos visuais da documentação.")
}

dir.create("docs/functions", recursive = TRUE, showWarnings = FALSE)
dir.create("man", showWarnings = FALSE)
rdFiles <- sort(list.files("docs/functions", pattern = "\\.Rd$", full.names = TRUE))
rdTopics <- character()
rdTitles <- character()
rdTargets <- character()
functionLines <- character()

if(length(rdFiles) > 0L){
  for(rdPath in rdFiles){
    rdObject <- parse_Rd(rdPath, encoding = "UTF-8")
    rdName <- ""
    rdTitle <- ""
    for(rdNode in rdObject){
      rdTag <- attr(rdNode, "Rd_tag")
      if(identical(rdTag, "\\name")){
        rdName <- str_trim(str_c(unlist(rdNode), collapse = ""))
      }
      if(identical(rdTag, "\\title")){
        rdTitle <- str_trim(str_c(unlist(rdNode), collapse = ""))
      }
    }
    if(!nzchar(rdName) || !grepl("^[A-Za-z][A-Za-z0-9._-]*$", rdName)){
      stop("O arquivo Rd deve informar um nome de tópico simples e válido.")
    }
    if(rdName %in% rdTopics){
      stop("Dois arquivos Rd utilizam o mesmo nome de tópico.")
    }
    if(!nzchar(rdTitle)){
      rdTitle <- rdName
    }
    rdTarget <- file.path("man", str_c(rdName, ".Rd"))
    file.copy(rdPath, rdTarget, overwrite = TRUE)
    rdTopics <- c(rdTopics, rdName)
    rdTitles <- c(rdTitles, rdTitle)
    rdTargets <- c(rdTargets, rdTarget)
    functionLines <- c(functionLines,
      str_c("- [", rdTitle, "](../reference/", rdName, ".html)"))
  }
}

manifestPath <- "man/.generated-rd-files"
if(file.exists(manifestPath)){
  previousTargets <- readLines(manifestPath, warn = FALSE, encoding = "UTF-8")
  obsoleteTargets <- setdiff(previousTargets, rdTargets)
  for(obsoletePath in obsoleteTargets){
    if(grepl("^man/[A-Za-z][A-Za-z0-9._-]*\\.Rd$", obsoletePath)){
      unlink(obsoletePath)
    }
  }
}
writeLines(rdTargets, manifestPath, useBytes = TRUE)

functionText <- str_c(functionLines, collapse = "\n")
writeLines(c("<!-- Gerado por scripts/prepareDocs.R -->", functionText),
  "vignettes/_functions.qmd", useBytes = TRUE)

exampleText <- readLines("examples/feature-lineage.json", warn = FALSE,
  encoding = "UTF-8")
writeLines(c("```json", exampleText, "```"),
  "vignettes/_lineage-example.qmd", useBytes = TRUE)
schemaText <- readLines("schemas/feature-lineage.schema.json", warn = FALSE,
  encoding = "UTF-8")
writeLines(c("```json", schemaText, "```"),
  "vignettes/_lineage-schema.qmd", useBytes = TRUE)

message(str_c("Referências Rd encontradas: ", length(rdFiles), "."))
