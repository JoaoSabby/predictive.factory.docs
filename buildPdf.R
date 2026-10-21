# Exportacao PDF em duas etapas a partir do mesmo documento
if(!requireNamespace("stringr", quietly = TRUE)){
  stop("Instale o pacote stringr antes da construção.")
}
library(stringr)
source("scripts/prepareDocs.R", encoding = "UTF-8")

quartoPath <- Sys.which("quarto")
xelatexPath <- Sys.which("xelatex")
if(!nzchar(quartoPath) || !nzchar(xelatexPath)){
  stop("Quarto CLI e XeLaTeX devem estar disponíveis no PATH da sessão R.")
}

projectRoot <- normalizePath(".", mustWork = TRUE)
metadataPath <- normalizePath("pdf-format.yml", mustWork = TRUE)
dir.create("export", showWarnings = FALSE)
renderStatus <- system2(quartoPath, c("render", "vignettes/arquitetura.qmd",
  "--to", "latex", "--metadata-file", shQuote(metadataPath)))
if(renderStatus != 0L){
  stop("Não foi possível gerar a fonte LaTeX a partir do documento Quarto.")
}

setwd(file.path(projectRoot, "vignettes"))
auxiliaryFiles <- c("arquitetura.aux", "arquitetura.toc", "arquitetura.out")
existingAuxiliary <- auxiliaryFiles[file.exists(auxiliaryFiles)]
if(length(existingAuxiliary) > 0L){
  file.remove(existingAuxiliary)
}
for(renderPass in seq_len(3L)){
  latexStatus <- system2(xelatexPath, c("-interaction=nonstopmode",
    "-halt-on-error", "arquitetura.tex"))
  if(latexStatus != 0L){
    setwd(projectRoot)
    stop("A compilação PDF não foi concluída. Verifique o arquivo arquitetura.log.")
  }
}
setwd(projectRoot)

if(!file.copy("vignettes/arquitetura.pdf", "export/arquitetura.pdf",
  overwrite = TRUE)){
  stop("Não foi possível copiar o PDF para export/arquitetura.pdf.")
}
message("PDF gerado em export/arquitetura.pdf.")
