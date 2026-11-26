# predictive.factory · documentação

![R](images/badges/lang-r.svg) ![C++](images/badges/lang-cpp.svg) ![Fortran](images/badges/lang-fortran.svg)
![Quarto](images/badges/lang-quarto.svg) ![AVX-512](images/badges/tec-avx512.svg)
![Intel oneAPI](images/badges/tec-oneapi.svg) ![oneMKL](images/badges/tec-mkl.svg)
![DuckDB](images/badges/tec-duckdb.svg) ![Oracle Database](images/badges/tec-oracle.svg)

Site Quarto da Fábrica Preditiva, com tema claro/escuro, busca local, widgets interativos e
exportação PDF. Funciona **sem internet**: nenhuma dependência de CDN, fontes remotas ou shields.io.

## Construir

Requisitos: Quarto CLI 1.5 ou posterior no PATH. Para o PDF: XeLaTeX, `fvextra` e fontes DejaVu.
Para a referência de funções: R e, opcionalmente, `roxygen2`.

```r
# RStudio Server, na raiz deste projeto
Sys.setenv(PF_PACOTE = "../predictive.factory")  # pasta do pacote com os roxygen2
source("build.R", encoding = "UTF-8")             # funções + site em _site/
source("buildPdf.R", encoding = "UTF-8")          # PDF em ebook_pdf.pdf
```

```bash
# Terminal
Rscript scripts/funcoes.R ../predictive.factory
quarto render                      # site em _site/
quarto render ebook_pdf.qmd        # PDF
quarto preview                     # servidor local com recarga automática
```

> O Observable JS usa módulos JavaScript, que o navegador bloqueia em `file://`. Para ver o site
> localmente use `quarto preview` ou qualquer servidor estático (por exemplo,
> `python -m http.server -d _site`). Em servidor interno, basta publicar `_site/`.

## Estrutura

| Caminho | Conteúdo |
|---|---|
| `_quarto.yml` | Navegação, tema, menu lateral e opções globais |
| `index.qmd` | Página inicial com shields e cartões de navegação |
| `01`–`17-*.qmd` | Capítulos (esqueleto de títulos e seções) |
| `18-referencia-funcoes.qmd` | Índice das funções; páginas em `referencia/` |
| `90-recursos-interativos.qmd` | Catálogo de widgets, Observable JS e componentes, com código para copiar |
| `99-referencias.qmd` | Bibliografia completa (ABNT) |
| `ebook_pdf.qmd` | Ordem dos capítulos no PDF |
| `widgets/` | Widgets HTML offline e o núcleo `pf-metrics.js`/`pf-metrics.css` |
| `estilo/` | Temas claro/escuro (SCSS) e estilos comuns (`pf.css`) |
| `images/` | Logo, favicon, figuras e `badges/` |
| `scripts/funcoes.R` | roxygen2 → uma página `.qmd` por função |
| `scripts/badges.R` | Gera os shields SVG locais e `_badges.qmd` |
| `referencias.bib`, `abnt.csl` | Bibliografia e estilo ABNT |
| `schemas/`, `examples/` | Contratos JSON Schema e exemplos |

## Referência de funções

`scripts/funcoes.R` recebe a raiz do pacote, executa `roxygen2::roxygenise()` (desative com
`PF_ROXYGENISE=false`) e converte cada `man/*.Rd` em `referencia/<função>.qmd`, com seções em
português (Descrição, Uso, Argumentos, Valor, Exemplos). Tópicos com `@keywords internal` são
ignorados. O menu lateral lista `referencia/*.qmd` automaticamente; o capítulo 18 recebe uma tabela
com todas as funções; no PDF, cada função vira uma seção do capítulo. Páginas de funções removidas
do pacote são apagadas na execução seguinte. Edite sempre o roxygen2, não os `.qmd` gerados.

## Shields

Edite a tabela em `scripts/badges.R` e execute `Rscript scripts/badges.R`.

## Publicação no GitLab Pages

`.gitlab-ci.yml` renderiza o site e publica `_site/` como `public/`. A imagem do runner precisa ter
o Quarto CLI; para incluir a referência de funções gerada, faça commit da pasta `referencia/`
ou instale R no runner.
