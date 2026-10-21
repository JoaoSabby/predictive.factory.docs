# Exportacao HTML independente do site
if(!requireNamespace("stringr", quietly = TRUE)){
  stop("Instale o pacote stringr antes da construção.")
}
library(stringr)
source("scripts/prepareDocs.R", encoding = "UTF-8")
quartoPath <- Sys.which("quarto")
if(!nzchar(quartoPath)){
  stop("Quarto CLI não encontrado no PATH da sessão R.")
}
dir.create("export", showWarnings = FALSE)
renderStatus <- system2(quartoPath, c("render", "vignettes/arquitetura.qmd",
  "--to", "html"))
if(renderStatus != 0L){
  stop("A renderização HTML não foi concluída.")
}
if(!file.rename("vignettes/arquitetura.html", "export/arquitetura.html")){
  stop("Não foi possível mover o HTML para export/arquitetura.html.")
}
message("HTML gerado em export/arquitetura.html.")
