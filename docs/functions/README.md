Adicionar nesta pasta os arquivos `.Rd` das funções do projeto.

O script `scripts/prepareDocs.R` lê `docs/functions/*.Rd`, prepara a referência pkgdown e atualiza o índice do capítulo Referência de funções. Sem arquivos Rd, o capítulo permanece vazio.

Os arquivos de `man/` preparados pelo script são derivados. A fonte da documentação permanece nesta pasta. O site é gerado em `site/`, preservando `docs/functions/`.

