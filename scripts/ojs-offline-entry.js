// Entrada do modulo offline do Observable JS (ver scripts/ojs-offline.md)
import * as InputsDist from "./inputs-dist.cjs";
export const Inputs = InputsDist;
export {html, svg} from "htl";
import {marked} from "marked";
export function md(strings, ...values){
  const div = document.createElement("div");
  div.innerHTML = marked.parse(String.raw({raw: strings.raw || strings}, ...values)).trim();
  return div.childElementCount === 1 ? div.firstElementChild : div;
}
