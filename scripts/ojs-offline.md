# Módulo offline do Observable JS

`widgets/ojs-offline.js` reúne `Inputs`, `html`, `svg` e `md` para que as células `{ojs}`
funcionem sem internet. Para recriar (em máquina com acesso ao registro npm):

```bash
mkdir /tmp/ojs && cd /tmp/ojs && npm init -y
npm i @observablehq/inputs@0.10.6 htl@0.3.1 marked@12 esbuild
cp <projeto>/scripts/ojs-offline-entry.js entry.js
# a versao dist do Inputs ja injeta o CSS; troca-se apenas o caminho do htl
sed "s#htl@0.3.1/dist/htl.min.js#htl#g" node_modules/@observablehq/inputs/dist/inputs.js > inputs-dist.cjs
npx esbuild entry.js --bundle --format=esm --minify --outfile=ojs-offline.js
cp ojs-offline.js <projeto>/widgets/ojs-offline.js
```
