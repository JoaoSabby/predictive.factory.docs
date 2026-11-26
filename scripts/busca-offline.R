# ------------------------------------------------------------------------------
# busca-offline.R
#
# Etapa pos-renderizacao (post-render no _quarto.yml) que habilita a busca do
# livro quando o index.html e aberto direto do disco (protocolo file://), sem
# servidor local.
#
# O script de busca do Quarto le o indice search.json com fetch(), que o
# navegador bloqueia em file://, e exibe um alerta. Este script:
#   1. le o _book/search.json gerado pelo Quarto;
#   2. grava o indice como variavel JavaScript no inicio do quarto-search.js;
#   3. troca a leitura via fetch() pelo uso dessa variavel e remove o alerta.
#
# O arquivo alterado fica apenas em _book/; os arquivos do Quarto nao mudam.
# ------------------------------------------------------------------------------

## Localizar os arquivos gerados pela renderizacao
# Pasta de saida informada pelo Quarto (padrao: _book)
pastaSaida <- Sys.getenv("QUARTO_PROJECT_OUTPUT_DIR", "_book")
arquivoIndice <- file.path(pastaSaida, "search.json")
arquivoBusca <- file.path(pastaSaida, "site_libs", "quarto-search", "quarto-search.js")

# Renderizacao parcial (um unico arquivo) pode nao gerar a busca
if (!file.exists(arquivoIndice) || !file.exists(arquivoBusca)) {
  message("busca-offline: search.json ou quarto-search.js ausente; nada a fazer.")
  quit(save = "no")
}

## Ler o indice e o script de busca
# O indice e JSON valido, portanto tambem e literal JavaScript valido
indice <- paste(readLines(arquivoIndice, encoding = "UTF-8", warn = FALSE), collapse = "\n")
script <- paste(readLines(arquivoBusca, encoding = "UTF-8", warn = FALSE), collapse = "\n")

# Evita aplicar o ajuste duas vezes no mesmo arquivo
marcador <- "/* pf: busca offline */"
if (grepl(marcador, script, fixed = TRUE)) {
  script <- sub("(?s)^.*?/\\* pf: fim do indice \\*/\n", "", script, perl = TRUE)
}

## Remover o alerta de file:// e a leitura via fetch()
# Desativa a condicao que exibe o alerta e interrompe a busca
script <- sub('window.location.protocol === "file:" && !shownWarning',
              'false', script, fixed = TRUE)

# Substitui o fetch() por uma resposta montada com o indice embutido
script <- sub('await fetch(offsetURL("search.json"))',
              '{ status: 200, json: () => Promise.resolve(window.__pfSearchData) }',
              script, fixed = TRUE)

if (!grepl("__pfSearchData", script, fixed = TRUE)) {
  warning("busca-offline: trecho do quarto-search.js nao encontrado; ",
          "verifique a versao do Quarto.")
  quit(save = "no")
}

## Gravar o script com o indice embutido no inicio
cabecalho <- paste0(marcador, "\nwindow.__pfSearchData = ", indice,
                    ";\n/* pf: fim do indice */\n")
writeLines(paste0(cabecalho, script), arquivoBusca, useBytes = TRUE)
message("busca-offline: indice embutido em ", arquivoBusca)
