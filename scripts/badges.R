# Geracao offline dos shields (badges) em SVG no estilo flat do shields.io, com icone
# Nao acessa a internet. Atualizar a tabela abaixo e executar:
#   Rscript scripts/badges.R
# Icones: images/badges/icones/ (si-*: Simple Icons, CC0; bi-*: Bootstrap Icons, MIT).
# Para um icone novo, copie o SVG para essa pasta e informe o nome sem extensao na coluna icone.
# Saida: images/badges/<arquivo>.svg e _badges.qmd (fragmento incluido no index)

if(!isTRUE(l10n_info()[["UTF-8"]])){
  invisible(Sys.setlocale("LC_CTYPE", "C.UTF-8"))
}

badgeTable <- read.csv(text = "
arquivo,rotulo,valor,cor,icone,grupo
lang-r,linguagem,R,#276DC3,si-r,Linguagens
lang-c,linguagem,C,#283593,si-c,Linguagens
lang-cpp,linguagem,C++,#00599C,si-cplusplus,Linguagens
lang-fortran,linguagem,Fortran,#734F96,si-fortran,Linguagens
lang-bash,linguagem,Shell Script (Bash),#3E7F1E,si-gnubash,Linguagens
lang-css,linguagem,CSS,#663399,si-css,Linguagens
lang-html,linguagem,HTML,#C9431E,si-html5,Linguagens
lang-javascript,linguagem,JavaScript,#8A7300,si-javascript,Linguagens
lang-typescript,linguagem,TypeScript,#3178C6,si-typescript,Linguagens
lang-quarto,publicação,Quarto,#39729E,si-quarto,Linguagens
tec-avx512,SIMD,AVX-512,#0071C5,si-intel,Tecnologias
tec-oneapi,toolkit,Intel oneAPI,#0071C5,si-intel,Tecnologias
tec-hpc,computação,HPC (High Performance Computing),#1F425F,bi-cpu,Tecnologias
tec-intel-compilers,compiladores,Intel icx · icpx · ifx,#0068B5,si-intel,Tecnologias
tec-mkl,álgebra linear,Intel oneMKL,#0068B5,si-intel,Tecnologias
tec-tbb,paralelismo,Intel oneTBB,#0068B5,si-intel,Tecnologias
tec-openmp,paralelismo,OpenMP,#4D6E91,bi-diagram-3,Tecnologias
tec-mimalloc,alocador,mimalloc,#4A4A4A,bi-memory,Tecnologias
tec-tuned,sistema,tuned,#B30000,bi-speedometer2,Tecnologias
tec-tuna,sistema,tuna,#8F0000,bi-sliders,Tecnologias
tec-duckdb,banco analítico,DuckDB,#7A6A00,si-duckdb,Tecnologias
tec-oracle,banco de dados,Oracle Database,#C74634,bi-database,Tecnologias
", stringsAsFactors = FALSE, encoding = "UTF-8", strip.white = TRUE)

# Largura aproximada de texto em Verdana 11 px, suficiente para o layout do shield
textWidth <- function(text){
  chars <- strsplit(enc2utf8(text), "")[[1]]
  widths <- ifelse(chars %in% c("i", "l", "j", ".", ",", ":", ";", "|", "!", "'", " ", "·", "(", ")", "t", "f", "I"), 4,
    ifelse(chars %in% c("m", "w", "M", "W"), 10.5,
      ifelse(grepl("[A-Z+]", chars), 7.6, 6.6)))
  ceiling(sum(widths))
}

escapeXml <- function(text){
  text <- gsub("&", "&amp;", text, fixed = TRUE)
  text <- gsub("<", "&lt;", text, fixed = TRUE)
  gsub(">", "&gt;", text, fixed = TRUE)
}

# Le um icone SVG e devolve viewBox e desenho interno (sem titulo)
readIcon <- function(iconName){
  iconPath <- file.path("images/badges/icones", sprintf("%s.svg", iconName))
  if(!nzchar(iconName) || !file.exists(iconPath)){
    return(NULL)
  }
  svgText <- paste(readLines(iconPath, warn = FALSE, encoding = "UTF-8"), collapse = " ")
  viewBox <- sub('.*viewBox="([^"]+)".*', "\\1", svgText)
  inner <- sub("^.*?<svg[^>]*>(.*)</svg>.*$", "\\1", svgText, perl = TRUE)
  inner <- gsub("<title>.*?</title>", "", inner, perl = TRUE)
  list(viewBox = viewBox, inner = inner)
}

dir.create("images/badges", recursive = TRUE, showWarnings = FALSE)
fragmentLines <- c("<!-- Gerado por scripts/badges.R -->")
currentGroup <- ""
iconSize <- 14

for(rowIndex in seq_len(nrow(badgeTable))){
  badge <- badgeTable[rowIndex, ]
  icon <- readIcon(badge$icone)
  iconSpace <- if(is.null(icon)) 0 else iconSize + 3
  leftWidth <- textWidth(badge$rotulo) + 12 + iconSpace
  rightWidth <- textWidth(badge$valor) + 12
  totalWidth <- leftWidth + rightWidth
  label <- escapeXml(badge$rotulo)
  value <- escapeXml(badge$valor)
  labelCenter <- iconSpace + (leftWidth - iconSpace) / 2
  iconSvg <- if(is.null(icon)) "" else sprintf(
    '<svg x="5" y="3" width="%d" height="%d" viewBox="%s" fill="#fff" color="#fff">%s</svg>',
    iconSize, iconSize, icon$viewBox, icon$inner)
  svg <- sprintf(paste(
    '<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="20" role="img" aria-label="%s: %s">',
    '<title>%s: %s</title>',
    '<linearGradient id="s" x2="0" y2="100%%"><stop offset="0" stop-color="#bbb" stop-opacity=".1"/><stop offset="1" stop-opacity=".1"/></linearGradient>',
    '<clipPath id="r"><rect width="%d" height="20" rx="3" fill="#fff"/></clipPath>',
    '<g clip-path="url(#r)"><rect width="%d" height="20" fill="#555"/><rect x="%d" width="%d" height="20" fill="%s"/><rect width="%d" height="20" fill="url(#s)"/></g>',
    '%s',
    '<g fill="#fff" text-anchor="middle" font-family="Verdana,Geneva,DejaVu Sans,sans-serif" font-size="11">',
    '<text x="%.1f" y="15" fill="#010101" fill-opacity=".3">%s</text><text x="%.1f" y="14">%s</text>',
    '<text x="%.1f" y="15" fill="#010101" fill-opacity=".3">%s</text><text x="%.1f" y="14">%s</text>',
    '</g></svg>', sep = ""),
    totalWidth, label, value, label, value, totalWidth, leftWidth, leftWidth, rightWidth, badge$cor, totalWidth,
    iconSvg,
    labelCenter, label, labelCenter, label,
    leftWidth + rightWidth / 2, value, leftWidth + rightWidth / 2, value)
  writeLines(svg, file.path("images/badges", sprintf("%s.svg", badge$arquivo)), useBytes = TRUE)

  if(badge$grupo != currentGroup){
    if(nzchar(currentGroup)){
      fragmentLines <- c(fragmentLines, "</p>")
    }
    fragmentLines <- c(fragmentLines, sprintf('<p class="pf-badges" aria-label="%s">', badge$grupo))
    currentGroup <- badge$grupo
  }
  fragmentLines <- c(fragmentLines, sprintf('<img src="images/badges/%s.svg" alt="%s: %s">',
    badge$arquivo, label, value))
}
fragmentLines <- c(fragmentLines, "</p>")
writeLines(c("```{=html}", fragmentLines, "```"), "_badges.qmd", useBytes = TRUE)
message(sprintf("Shields gerados: %d.", nrow(badgeTable)))
