# Construcao do site a partir da raiz do projeto (RStudio Server ou terminal)
#
#   source("build.R", encoding = "UTF-8")
#
# 1. Gera as paginas de funcoes em referencia/funcoes/ (scripts/funcoes.R).
#    Informe a pasta do projeto predictive.factory em PF_PROJETO; sem ela, apenas
#    reorganiza os indices a partir dos .qmd ja existentes em referencia/funcoes/.
# 2. Renderiza o livro em _book/ com o Quarto CLI.
# 3. Opcionalmente gera o PDF (PF_PDF=true).
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
  stop("A renderizacao do livro nao foi concluida.")
}

if(identical(tolower(Sys.getenv("PF_PDF", "false")), "true")){
  source("buildPdf.R", encoding = "UTF-8")
}
message("Livro gerado em _book/index.html (abra com dois cliques).")
