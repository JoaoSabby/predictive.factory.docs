# models.factory

Documentação arquitetural e metodológica da Fábrica Preditiva, em
Quarto/Markdown com publicação pelo pkgdown.

## Executar no RStudio Server

Abrir `models.factory.docs.Rproj`. No console R:

```r
install.packages(c("pkgdown", "quarto", "knitr", "rmarkdown", "stringr"))
source("build.R", encoding = "UTF-8")
```

A instalação dos pacotes é necessária apenas na preparação do ambiente.
A construção gera `site/index.html`. O diretório de saída é `site/`,
preservando `docs/functions/` como fonte dos arquivos Rd.

Requisitos: R 4.1 ou posterior, pkgdown 2.1.0 ou posterior e Quarto CLI
1.5 ou posterior no PATH da sessão R. O pacote R `quarto` não substitui
a instalação do Quarto CLI. Em ambiente sem internet, disponibilizar
previamente os pacotes e o executável. A construção não instala dependências.

## Arquivos principais

| Caminho | Conteúdo |
|---|---|
| `vignettes/arquitetura.qmd` | Documento principal, com capítulos, equações e referências |
| `vignettes/publicacao.qmd` | Construção e manutenção da documentação |
| `pdf-format.yml` | Configuração da exportação PDF |
| `citations.bib` | Bibliografia científica, normativa e técnica |
| `assets/associacao-brasileira-de-normas-tecnicas.csl` | Estilo ABNT |
| `_pkgdown.yml` | Navegação, aparência e diretório de saída |
| `docs/functions/*.Rd` | Fontes da documentação de funções |
| `scripts/prepareDocs.R` | Preparação das referências Rd e dos exemplos incluídos |
| `examples/feature-lineage.json` | Exemplo hipotético com OpenLineage, Dublin Core e JSON Schema |
| `schemas/feature-lineage.schema.json` | Contrato do perfil ilustrativo |
| `schemas/vendor/` | Especificações OpenLineage utilizadas na validação |
| `assets/modelo-er-reservado.png` | Espaço reservado para imagem do modelo ER |
| `VALIDACAO.md` | Verificações realizadas e limites da validação |

## Referência de funções

Adicionar os arquivos Rd diretamente a `docs/functions/` e executar
novamente `build.R`. O script lê exclusivamente `docs/functions/*.Rd`,
prepara as páginas de referência e atualiza o índice do capítulo
**Referência de funções**.

O campo `\name{}` deve conter um nome de tópico simples e único.
Os arquivos em `man/` gerados pelo script são derivados; manter a fonte
em `docs/functions/`. Sem arquivos Rd, o capítulo permanece vazio.
Os exemplos das funções não são executados na construção.

## Modelo ER e dicionário

Substituir `assets/modelo-er-reservado.png` ou atualizar sua referência no
documento principal. As seções das sete tabelas estão reservadas para
documentação posterior. Nenhuma chave ou definição de campo é proposta como
DDL definitivo dessas entidades.

## Exportações independentes

```r
source("buildHtml.R", encoding = "UTF-8")
source("buildPdf.R", encoding = "UTF-8")
```

O HTML independente é gerado em `export/arquitetura.html`.
O PDF requer XeLaTeX, o pacote LaTeX `fvextra` e as famílias completas
DejaVu Serif, DejaVu Sans e DejaVu Sans Mono disponíveis no servidor.
O arquivo é gerado em `export/arquitetura.pdf`.
A publicação pkgdown utiliza HTML; PDF é uma exportação separada.
A versão PDF preserva o cenário estático das ilustrações interativas.

## Manutenção

Editar o conteúdo principal em `vignettes/arquitetura.qmd`.
Editar o exemplo e o contrato nos respectivos arquivos JSON. Os arquivos
`_functions.qmd`, `_lineage-example.qmd` e `_lineage-schema.qmd` são
preparados automaticamente pelo script.

A data é calculada na renderização. Atualizar as fontes quando houver
mudança de norma, versão ou produto. O campo de e-mail da autoria em
`DESCRIPTION` é um placeholder e pode ser substituído pelo contato
institucional antes de eventual distribuição como pacote.

A documentação descreve a arquitetura e seus critérios. Não executa cargas,
treinamento, conversão de modelos nem comandos no Oracle.

