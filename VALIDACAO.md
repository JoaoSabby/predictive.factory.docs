# Validação da documentação

Verificações realizadas em 25/11/2026 com Quarto CLI 1.8.25, R 4.3.3 e XeLaTeX (TeX Live).

| Item | Resultado |
|---|---|
| Site | `quarto render` sem avisos; 21 páginas em `_site/` |
| Execução sem internet | Navegador com todas as requisições externas bloqueadas: nenhuma requisição externa, nenhum erro de JavaScript |
| Fontes | Temas sem importação de Google Fonts (`$web-font-path: false`) |
| Widgets | 10 widgets em iframe carregados, altura ajustada automaticamente sem ciclos |
| Observable JS | Controles, tabela e SVG reativos com `Inputs`, `html`, `svg` e `md` do módulo local `widgets/ojs-offline.js` (sem CDN) |
| Mermaid | Diagrama renderizado no navegador, sem CDN |
| Referência de funções | Pacote de teste com roxygen2: página gerada, seções em português, tópico `internal` ignorado, menu lateral e PDF atualizados |
| PDF | `ebook_pdf.qmd` compilado com XeLaTeX; funções como seções do capítulo de referência |
| Shields | 22 SVG gerados localmente por `scripts/badges.R` |

Limites: o Observable JS exige servidor HTTP (`quarto preview` ou servidor interno), pois navegadores
bloqueiam módulos JavaScript em `file://`. Os widgets usam dados sintéticos ou de exemplo.
