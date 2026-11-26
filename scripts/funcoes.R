# Gera e organiza a Parte IV do livro (Referência das funções)
#
# Uso, a partir da raiz deste projeto:
#   Rscript scripts/funcoes.R ../predictive.factory   # gera as paginas e atualiza os indices
#   Rscript scripts/funcoes.R                          # so atualiza os indices
# No console R:
#   Sys.setenv(PF_PROJETO = "../predictive.factory")
#   source("scripts/funcoes.R", encoding = "UTF-8")
#
# Entrada:
#   - pasta do projeto predictive.factory (primeiro argumento ou variavel PF_PROJETO). Quando
#     informada, a funcao RenderRoxygenToQuarto() do proprio projeto gera uma pagina .qmd por
#     funcao em referencia/funcoes/. Sem a pasta, as paginas ja copiadas para referencia/funcoes/
#     sao mantidas e apenas os indices sao refeitos;
#   - referencia/ordem-pipeline.csv: etapa de cada funcao, na ordem do pipeline.
# Saida:
#   referencia/funcoes/<Funcao>.qmd          paginas de ajuda (geradas pela RenderRoxygenToQuarto)
#   _quarto.yml                              lista de capitulos da Parte IV, entre os marcadores
#   referencia/_indice-funcoes.qmd           tabelas por etapa, incluidas em referencia/index.qmd
#   pipeline/_funcoes-<etapa>.qmd            listas de funcoes incluidas nos capitulos do pipeline
#   _referencia-pdf.qmd                      paginas das funcoes como secoes, para o ebook_pdf.qmd

# Garante leitura e gravacao em UTF-8
if(!isTRUE(l10n_info()[["UTF-8"]])){
  invisible(Sys.setlocale("LC_CTYPE", "C.UTF-8"))
}

# Parametros de entrada e caminhos fixos do livro
argumentos <- commandArgs(trailingOnly = TRUE)
projetoPath <- if(length(argumentos) > 0L) argumentos[1L] else Sys.getenv("PF_PROJETO", "")
funcoesDir <- file.path("referencia", "funcoes")
ordemPath <- file.path("referencia", "ordem-pipeline.csv")
marcadorInicio <- "# >>> funcoes: lista gerada por scripts/funcoes.R"
marcadorFim <- "# <<< funcoes"
avisoGerado <- "<!-- Gerado por scripts/funcoes.R a partir de referencia/ordem-pipeline.csv. -->"

# Le o valor de um campo do cabecalho YAML de uma pagina gerada
LerCampoYaml <- function(linhas, campo){
  valor <- sub(paste0("^", campo, ":\\s*"), "", grep(paste0("^", campo, ":"), linhas, value = TRUE))
  if(length(valor) == 0L) return("")
  valor <- sub('^"(.*)"$', "\\1", valor[1L])
  gsub('\\\\"', '"', valor)
}

# Converte o nome da etapa em identificador de arquivo (sem acentos e espacos)
SlugEtapa <- function(etapa){
  slug <- iconv(tolower(etapa), "UTF-8", "ASCII//TRANSLIT")
  slug <- gsub("[^a-z0-9]+", "-", slug)
  gsub("^-|-$", "", slug)
}

# Gera as paginas a partir do projeto, quando a pasta e informada
if(nzchar(projetoPath)){
  renderPath <- file.path(projetoPath, "Funcoes", "RenderRoxygenToQuarto.R")
  if(!file.exists(renderPath)){
    stop("RenderRoxygenToQuarto.R nao encontrado em ", renderPath)
  }
  source(renderPath, encoding = "UTF-8")
  RenderRoxygenToQuarto(
    listFunctions = list.files(file.path(projetoPath, "Funcoes"), pattern = "\\.R$",
                               full.names = TRUE),
    pathOutputQmd = funcoesDir
  )
  # O indice por familia gerado pela funcao e substituido pelo indice por etapa do livro
  unlink(file.path(funcoesDir, "index.qmd"))
}

# Paginas disponiveis e ordem definida no CSV
paginas <- tools::file_path_sans_ext(list.files(funcoesDir, pattern = "\\.qmd$"))
paginas <- setdiff(paginas, "index")
ordem <- read.csv(ordemPath, encoding = "UTF-8", stringsAsFactors = FALSE)

# Funcoes do CSV sem pagina sao ignoradas; paginas fora do CSV entram em "Fora do pipeline"
semPagina <- setdiff(ordem$funcao, paginas)
if(length(semPagina) > 0L){
  warning("Sem pagina em referencia/funcoes: ", paste(semPagina, collapse = ", "), call. = FALSE)
}
ordem <- ordem[ordem$funcao %in% paginas, , drop = FALSE]
foraCsv <- setdiff(paginas, ordem$funcao)
if(length(foraCsv) > 0L){
  warning("Fora de referencia/ordem-pipeline.csv (incluidas em 'Fora do pipeline'): ",
          paste(foraCsv, collapse = ", "), call. = FALSE)
  ordem <- rbind(ordem, data.frame(etapa = "Fora do pipeline", funcao = sort(foraCsv)))
}

# Titulo de cada pagina, lido do subtitulo YAML
ordem$titulo <- vapply(ordem$funcao, function(funcao){
  LerCampoYaml(readLines(file.path(funcoesDir, paste0(funcao, ".qmd")), encoding = "UTF-8"),
               "subtitle")
}, character(1L))

# Atualiza a lista de capitulos da Parte IV no _quarto.yml, entre os marcadores
quartoYml <- readLines("_quarto.yml", encoding = "UTF-8")
posInicio <- which(trimws(quartoYml) == marcadorInicio)
posFim <- which(trimws(quartoYml) == marcadorFim)
if(length(posInicio) != 1L || length(posFim) != 1L || posFim < posInicio){
  stop("Marcadores da lista de funcoes nao encontrados no _quarto.yml")
}
recuo <- sub("#.*$", "", quartoYml[posInicio])
capitulos <- paste0(recuo, "- ", funcoesDir, "/", ordem$funcao, ".qmd")
quartoYml <- c(quartoYml[seq_len(posInicio)], capitulos, quartoYml[posFim:length(quartoYml)])
writeLines(enc2utf8(quartoYml), "_quarto.yml", useBytes = TRUE)

# Indice da Parte IV: uma tabela por etapa, na ordem do pipeline
etapas <- unique(ordem$etapa)
indice <- avisoGerado
for(etapa in etapas){
  bloco <- ordem[ordem$etapa == etapa, , drop = FALSE]
  indice <- c(indice, "", paste0("## ", etapa), "", "| Função | Descrição |", "|---|---|",
              paste0("| [", bloco$funcao, "](funcoes/", bloco$funcao, ".qmd) | ",
                     gsub("|", "\\|", bloco$titulo, fixed = TRUE), " |"))
}
writeLines(enc2utf8(indice), file.path("referencia", "_indice-funcoes.qmd"), useBytes = TRUE)

# Listas por etapa incluidas nos capitulos do pipeline (links relativos a pipeline/)
for(etapa in etapas){
  bloco <- ordem[ordem$etapa == etapa, , drop = FALSE]
  lista <- c(avisoGerado, "", paste0("**", etapa, "**"), "",
             paste0("- [`", bloco$funcao, "()`](../referencia/funcoes/", bloco$funcao, ".qmd): ",
                    bloco$titulo))
  writeLines(enc2utf8(lista), file.path("pipeline", paste0("_funcoes-", SlugEtapa(etapa), ".qmd")),
             useBytes = TRUE)
}

# Versao para o PDF: cada pagina vira uma secao, sem o cabecalho YAML
pdf <- avisoGerado
for(funcao in ordem$funcao){
  linhas <- readLines(file.path(funcoesDir, paste0(funcao, ".qmd")), encoding = "UTF-8")
  fimYaml <- which(linhas == "---")[2L]
  corpo <- linhas[(fimYaml + 1L):length(linhas)]
  corpo <- sub("^## ", "### ", corpo)
  corpo <- corpo[!grepl("^\\[!\\[", corpo)]
  pdf <- c(pdf, "", paste0("## ", funcao, " {.unnumbered}"), "",
           paste0("*", ordem$titulo[ordem$funcao == funcao], "*"), corpo)
}
writeLines(enc2utf8(pdf), "_referencia-pdf.qmd", useBytes = TRUE)

message("Parte IV atualizada: ", nrow(ordem), " funções em ", length(etapas), " etapas.")
