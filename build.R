# Construcao do site a partir da raiz do projeto (RStudio Server ou terminal)
#
#   source("build.R", encoding = "UTF-8")
#
# 1. Gera as paginas de funcoes a partir do roxygen2 do pacote (scripts/funcoes.R).
#    Informe a pasta do pacote em PF_PACOTE; o padrao e ../predictive.factory.
# 2. Renderiza o site em _site/ com o Quarto CLI.
# 3. Opcionalmente gera o PDF e o copia para _site/ (PF_PDF=true).
# Nao instala pacotes e nao acessa a internet.

if(!file.exists("_quarto.yml")){
  stop("Execute o script a partir da pasta que contem _quarto.yml.")
}
quartoPath <- Sys.which("quarto")
if(!nzchar(quartoPath)){
  stop("Quarto CLI nao encontrado no PATH da sessao R.")
}

source("scripts/funcoes.R", encoding = "UTF-8")

renderStatus <- system2(quartoPath, "render")
if(renderStatus != 0L){
  stop("A renderizacao do site nao foi concluida.")
}

if(identical(tolower(Sys.getenv("PF_PDF", "false")), "true")){
  source("buildPdf.R", encoding = "UTF-8")
}
message("Site gerado em _site/index.html.")
