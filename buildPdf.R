# Exportacao PDF a partir dos mesmos capitulos do site
#
#   source("buildPdf.R", encoding = "UTF-8")
#
# Requer XeLaTeX, o pacote LaTeX fvextra e as familias DejaVu Serif, Sans e Sans Mono.
# O PDF e gerado em ebook_pdf.pdf e copiado para _site/ (link no menu superior do site).

quartoPath <- Sys.which("quarto")
xelatexPath <- Sys.which("xelatex")
if(!nzchar(quartoPath) || !nzchar(xelatexPath)){
  stop("Quarto CLI e XeLaTeX devem estar disponiveis no PATH da sessao R.")
}

renderStatus <- system2(quartoPath, c("render", "ebook_pdf.qmd", "--to", "pdf"))
if(renderStatus != 0L){
  stop("A geracao do PDF nao foi concluida.")
}
if(dir.exists("_site")){
  file.copy("ebook_pdf.pdf", file.path("_site", "ebook_pdf.pdf"), overwrite = TRUE)
}
message("PDF gerado em ebook_pdf.pdf.")
