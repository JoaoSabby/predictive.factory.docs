# Validação da documentação

Verificações realizadas em 20/10/2026 com R 4.3.3, pkgdown 2.1.0 e
Quarto CLI 1.5.57.

| Item | Resultado |
|---|---|
| Construção pkgdown | Concluída com `build.R`; site disponível em `site/` |
| HTML independente | Gerado com `buildHtml.R` |
| PDF | Gerado com `buildPdf.R` e XeLaTeX; 42 páginas |
| Links locais | Nenhum arquivo de destino ausente nas oito páginas HTML |
| Bibliografia | 66 entradas; 63 citadas no documento principal e três na manutenção; nenhuma chamada ausente |
| Equações | 64 expressões MathML verificadas no navegador |
| Imagens | Nenhuma imagem ausente no documento principal |
| Interatividade | Três controles; score inicial de 99,07%; completude de 50% produz score de 74,47% |
| JavaScript | Nenhum erro de execução identificado no documento principal |
| Exibição | Sem transbordamento horizontal na janela de 1.440 pixels; PDF renderizado para inspeção visual |
| Arquivos Rd | Importação e geração nativa da página de referência verificadas com tópico temporário, fora do projeto entregue |
| Capítulos reservados | Modelagem, Predictive Factory Pipeline e Referência de funções sem conteúdo funcional |
| Modelo ER | Imagem reservada; entidades identificadas sem definição de campos ou relacionamentos |
| Scripts R | Sintaxe verificada; sem criação de funções, operador de namespace ou uso de `paste0` |
| Perfil JSON | Exemplo validado contra o contrato e as versões OpenLineage referenciadas |
| Valores decimais | Casos positivos, negativos e nulos aceitos; terceira casa decimal, limites excedidos e propriedade obrigatória ausente rejeitados |

A validação JSON utilizou aritmética decimal e cópias locais das
especificações OpenLineage. O perfil combinado é ilustrativo; seus blocos
mantêm responsabilidades distintas para linhagem, semântica e constraints.

A documentação não executa cargas, treinamento, conversão XGBoost/ONNX
ou operações no Oracle. Desempenho, equivalência numérica entre modelos
reais e conformidade institucional dependem das evidências operacionais
descritas no conteúdo. Os exemplos de dados e metadados são hipotéticos.

O endereço público do site não está definido. A construção local não
depende de publicação em servidor externo.
