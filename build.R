# Construcao do site a partir da raiz do projeto
requiredPackages <- c("pkgdown", "quarto", "knitr", "rmarkdown", "stringr")
for(packageName in requiredPackages){
  if(!requireNamespace(packageName, quietly = TRUE)){
    stop("Dependência ausente. Instale os pacotes indicados em README.md.")
  }
}

library(stringr)
library(pkgdown)

if(!file.exists("DESCRIPTION")){
  stop("Execute o script a partir da pasta que contém DESCRIPTION.")
}

if(packageVersion("pkgdown") < "2.1.0"){
  stop("A construção requer pkgdown 2.1.0 ou posterior.")
}

quartoPath <- Sys.which("quarto")
if(!nzchar(quartoPath)){
  stop("Quarto CLI não encontrado no PATH da sessão R.")
}

source("scripts/prepareDocs.R", encoding = "UTF-8")
build_site(new_process = FALSE, install = FALSE, examples = FALSE, preview = FALSE)
message("Site gerado em site/index.html.")
