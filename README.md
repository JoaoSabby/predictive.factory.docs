# predictive.factory · documentação

![R](images/badges/lang-r.svg) ![C++](images/badges/lang-cpp.svg) ![Fortran](images/badges/lang-fortran.svg)
![Quarto](images/badges/lang-quarto.svg) ![AVX-512](images/badges/tec-avx512.svg)
![Intel oneAPI](images/badges/tec-oneapi.svg) ![oneMKL](images/badges/tec-mkl.svg)
![DuckDB](images/badges/tec-duckdb.svg) ![Oracle Database](images/badges/tec-oracle.svg)

Livro Quarto da Fábrica Preditiva, com tema claro e escuro, busca, componentes interativos e
exportação PDF. Funciona **100% offline**: depois de renderizar, basta abrir `_book/index.html`
com dois cliques, sem servidor local e sem internet. d3, Observable Plot e Font Awesome ficam em
`recursos/`; as fórmulas usam MathML, nativo do navegador.

## Construir

Requisitos: Quarto CLI 1.5 ou posterior no PATH e R. Para o PDF: XeLaTeX, `fvextra` e fontes DejaVu.

```r
# RStudio Server, na raiz deste projeto
Sys.setenv(PF_PROJETO = "../predictive.factory")  # pasta do projeto com Funcoes/*.R
source("build.R", encoding = "UTF-8")              # funções + livro em _book/
source("buildPdf.R", encoding = "UTF-8")           # PDF em ebook_pdf.pdf
```

```bash
# Terminal
Rscript scripts/funcoes.R ../predictive.factory
quarto render                      # livro em _book/
quarto render ebook_pdf.qmd        # PDF
```

Ao final do `quarto render`, `scripts/busca-offline.R` embute o índice de busca no próprio
JavaScript do livro, para que a busca funcione em `file://`.

## Estrutura

| Caminho | Conteúdo |
|---|---|
| `_quarto.yml` | Livro: partes, apêndices, tema e opções globais |
| `index.qmd` | Página inicial com cartões de navegação |
| `introducao/` | Parte I: Introdução |
| `teoria/` | Parte II: Fundamentação teórica |
| `pipeline/` | Parte III: Funcionamento do pipeline, com as funções de cada etapa |
| `referencia/` | Parte IV: Referência das funções (`index.qmd`, `ordem-pipeline.csv`) |
| `referencia/funcoes/` | Páginas `.qmd` geradas pela `RenderRoxygenToQuarto`, uma por função |
| `apendices/` | Glossário, recursos interativos (demonstração) e referências bibliográficas |
| `_interativos/` | Um arquivo por componente interativo, usado com `include` nos capítulos |
| `widgets/` | Páginas HTML dos componentes e o núcleo `pf-metrics.js`/`pf-metrics.css` |
| `recursos/` | Cópias locais de d3, Plot e Font Awesome; ajuste de altura dos iframes |
| `ebook_pdf.qmd` | Ordem dos capítulos no PDF |
| `estilo/` | Temas claro e escuro (SCSS) e estilos comuns (`pf.css`) |
| `scripts/funcoes.R` | Gera as páginas de funções e os índices na ordem do pipeline |
| `scripts/busca-offline.R` | Habilita a busca em `file://` após a renderização |
| `referencias.bib`, `abnt.csl` | Bibliografia única do livro e estilo ABNT |

## Referência das funções

As páginas ficam em `referencia/funcoes/` e são geradas pela função `RenderRoxygenToQuarto` do
projeto predictive.factory. O caminho mais simples é:

```bash
Rscript scripts/funcoes.R ../predictive.factory
```

O script carrega `Funcoes/RenderRoxygenToQuarto.R` do projeto, gera um `.qmd` por função em
`referencia/funcoes/` e depois:

- monta o índice da Parte IV na ordem do pipeline, conforme `referencia/ordem-pipeline.csv`;
  as funções sem uso ficam na seção **Fora do pipeline**;
- atualiza a lista de páginas no `_quarto.yml` (entre os marcadores `# >>> funcoes` e `# <<< funcoes`);
- gera `pipeline/_funcoes-<etapa>.qmd`, a tabela de funções incluída em cada capítulo do pipeline;
- gera `_referencia-pdf.qmd` para o PDF.

Também é possível rodar a `RenderRoxygenToQuarto` direto no projeto, com
`pathOutputQmd = "<este repositório>/referencia/funcoes"`, e depois `Rscript scripts/funcoes.R`
sem argumentos para refazer os índices. Uma função nova que não esteja no CSV entra em
**Fora do pipeline** até ser adicionada a ele. Edite sempre o roxygen2, não os `.qmd` gerados.

As citações do roxygen2 (`@references` com `- @chave`) são resolvidas pelo `referencias.bib`, que
é a bibliografia única do livro.

## Componentes interativos

Cada componente tem um arquivo em `_interativos/` e entra no capítulo com uma linha:

```markdown
{{< include ../_interativos/roc-auc.qmd >}}
```

A página **Recursos interativos**, no apêndice, mostra todos eles.

## Shields

Cada shield é um SVG independente em `images/badges/`, com o ícone embutido (funciona offline) e,
na página inicial, link para o site ou repositório oficial. Para editar, altere a tabela em
`scripts/badges.R` (rótulo, valor, cor, ícone e link) e execute `Rscript scripts/badges.R`.

- `si-*` e `bi-*`: ícones monocromáticos em `images/badges/icones/` (Simple Icons, CC0; Bootstrap Icons, MIT).
- `logo-*`: logotipos coloridos em PNG em `images/badges/logos/`, obtidos dos sites oficiais
  (oneAPI, OpenMP, mimalloc, XGBoost, targets, tarchetypes, Oracle) e, no caso do jemalloc, da imagem fornecida.

## Publicação no GitLab Pages

`.gitlab-ci.yml` renderiza o livro e publica `_book/` como `public/`. A imagem do runner precisa ter
o Quarto CLI e R; faça commit da pasta `referencia/funcoes/` com as páginas geradas.
