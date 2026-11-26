# Geracao offline dos shields (badges) em SVG no estilo flat do shields.io, com icone
# Nao acessa a internet. Atualizar a tabela abaixo e executar:
#   Rscript scripts/badges.R
# Cada shield e um SVG independente, com o icone embutido (funciona offline) e link no _badges.qmd.
# Coluna icone:
#   si-<nome> ou bi-<nome>: SVG monocromatico em images/badges/icones/ (Simple Icons CC0, Bootstrap Icons MIT),
#                           desenhado em branco;
#   logo-<nome>: logotipo colorido em PNG em images/badges/logos/<nome>.png, embutido em base64.
# Saida: images/badges/<arquivo>.svg e _badges.qmd (fragmento incluido no index)

if(!isTRUE(l10n_info()[["UTF-8"]])){
  invisible(Sys.setlocale("LC_CTYPE", "C.UTF-8"))
}

badgeTable <- read.csv(text = "
arquivo,rotulo,valor,cor,icone,link,grupo
lang-r,language,R,#276DC3,si-r,https://www.r-project.org/,Languages
lang-c,language,C,#283593,si-c,https://www.open-std.org/jtc1/sc22/wg14/,Languages
lang-cpp,language,C++,#00599C,si-cplusplus,https://isocpp.org/,Languages
lang-fortran,language,Fortran,#734F96,si-fortran,https://fortran-lang.org/,Languages
lang-bash,language,Bash,#3E7F1E,si-gnubash,https://www.gnu.org/software/bash/,Languages
lang-css,language,CSS,#663399,si-css,https://www.w3.org/Style/CSS/,Languages
lang-html,language,HTML,#C9431E,si-html5,https://html.spec.whatwg.org/,Languages
lang-javascript,language,JavaScript,#8A7300,si-javascript,https://tc39.es/ecma262/,Languages
lang-typescript,language,TypeScript,#3178C6,si-typescript,https://github.com/microsoft/TypeScript,Languages
lang-quarto,publishing,Quarto,#39729E,si-quarto,https://github.com/quarto-dev/quarto-cli,Languages
tec-hpc,computing,HPC,#1F425F,bi-cpu,https://en.wikipedia.org/wiki/High-performance_computing,Technologies
tec-avx512,SIMD,AVX-512,#0071C5,si-intel,https://www.intel.com/content/www/us/en/architecture-and-technology/avx-512-overview.html,Technologies
tec-oneapi,toolkit,Intel oneAPI,#0071C5,logo-oneapi,https://github.com/oneapi-src,Technologies
tec-intel-compilers,compilers,Intel icx · icpx · ifx,#0068B5,si-intel,https://www.intel.com/content/www/us/en/developer/tools/oneapi/dpc-compiler.html,Technologies
tec-mkl,linear algebra,Intel oneMKL,#0068B5,si-intel,https://github.com/uxlfoundation/oneMath,Technologies
tec-tbb,parallelism,Intel oneTBB,#0068B5,si-intel,https://github.com/uxlfoundation/oneTBB,Technologies
tec-openmp,parallelism,Intel OpenMP,#4D6E91,logo-openmp,https://www.openmp.org/,Technologies
tec-mimalloc,allocator,mimalloc,#4A4A4A,logo-mimalloc,https://github.com/microsoft/mimalloc,Technologies
tec-jemalloc,allocator,jemalloc,#1D4E89,logo-jemalloc,https://github.com/jemalloc/jemalloc,Technologies
tec-numactl,NUMA,numactl,#5A4E8C,bi-motherboard,https://github.com/numactl/numactl,Technologies
tec-tuned,system,tuned,#B30000,bi-speedometer2,https://github.com/redhat-performance/tuned,Technologies
tec-tuna,system,tuna,#8F0000,bi-sliders,https://git.kernel.org/pub/scm/utils/tuna/tuna.git,Technologies
tec-duckdb,analytics database,DuckDB,#7A6A00,si-duckdb,https://github.com/duckdb/duckdb,Technologies
tec-oracle,database,Oracle Database,#C74634,logo-oracle,https://www.oracle.com/database/,Technologies
tec-xgboost,machine learning,XGBoost,#1A6FB5,logo-xgboost,https://github.com/dmlc/xgboost,Technologies
tec-targets,pipeline,targets,#2E6E4F,logo-targets,https://github.com/ropensci/targets,Technologies
tec-tarchetypes,pipeline,tarchetypes,#2E6E4F,logo-tarchetypes,https://github.com/ropensci/tarchetypes,Technologies
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

# Codificacao base64 em R base (sem pacotes)
base64Encode <- function(bytes){
  alphabet <- strsplit("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/", "")[[1]]
  padding <- (3L - length(bytes) %% 3L) %% 3L
  values <- c(as.integer(bytes), integer(padding))
  groups <- matrix(values, nrow = 3L)
  combined <- groups[1L, ] * 65536L + groups[2L, ] * 256L + groups[3L, ]
  indices <- rbind(combined %/% 262144L, (combined %/% 4096L) %% 64L, (combined %/% 64L) %% 64L, combined %% 64L)
  encoded <- alphabet[as.vector(indices) + 1L]
  if(padding > 0L){
    encoded[(length(encoded) - padding + 1L):length(encoded)] <- "="
  }
  paste(encoded, collapse = "")
}

# Le um logotipo PNG e devolve dados em base64 e proporcao largura/altura
readLogo <- function(logoName){
  logoPath <- file.path("images/badges/logos", sprintf("%s.png", logoName))
  if(!file.exists(logoPath)){
    return(NULL)
  }
  bytes <- readBin(logoPath, "raw", file.info(logoPath)$size)
  toInt <- function(raw4) sum(as.integer(raw4) * c(16777216, 65536, 256, 1))
  list(data = base64Encode(bytes), ratio = toInt(bytes[17:20]) / toInt(bytes[21:24]))
}

dir.create("images/badges", recursive = TRUE, showWarnings = FALSE)
fragmentLines <- c("<!-- Gerado por scripts/badges.R -->")
currentGroup <- ""
iconSize <- 14

for(rowIndex in seq_len(nrow(badgeTable))){
  badge <- badgeTable[rowIndex, ]
  isLogo <- startsWith(badge$icone, "logo-")
  icon <- if(isLogo) readLogo(sub("^logo-", "", badge$icone)) else readIcon(badge$icone)
  iconWidth <- if(is.null(icon)) 0 else if(isLogo) ceiling(iconSize * icon$ratio) else iconSize
  iconSpace <- if(is.null(icon)) 0 else iconWidth + 3
  leftWidth <- textWidth(badge$rotulo) + 12 + iconSpace
  rightWidth <- textWidth(badge$valor) + 12
  totalWidth <- leftWidth + rightWidth
  label <- escapeXml(badge$rotulo)
  value <- escapeXml(badge$valor)
  labelCenter <- iconSpace + (leftWidth - iconSpace) / 2
  iconSvg <- if(is.null(icon)) "" else if(isLogo) sprintf(
    '<image x="5" y="3" width="%d" height="%d" preserveAspectRatio="xMidYMid meet" href="data:image/png;base64,%s"/>',
    iconWidth, iconSize, icon$data) else sprintf(
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
  fragmentLines <- c(fragmentLines, sprintf(
    '<a href="%s" target="_blank" rel="noopener" title="%s"><img src="images/badges/%s.svg" alt="%s: %s"></a>',
    badge$link, value, badge$arquivo, label, value))
}
fragmentLines <- c(fragmentLines, "</p>")
writeLines(c("```{=html}", fragmentLines, "```"), "_badges.qmd", useBytes = TRUE)
message(sprintf("Shields gerados: %d.", nrow(badgeTable)))
