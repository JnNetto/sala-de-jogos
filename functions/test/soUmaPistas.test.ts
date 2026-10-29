import assert from "node:assert/strict";
import {test} from "node:test";

import {
  aplicarAnulacoes,
  compararPistas,
  palpiteCorreto,
  pistasPorEscritor,
} from "../src/soUmaPistas.ts";

test("três jogadores escrevem duas pistas cada", () => {
  assert.equal(pistasPorEscritor(3), 2);
  assert.equal(pistasPorEscritor(5), 1);
});

test("pista idêntica, plural e gênero se anulam; casa e carro não", () => {
  assert.equal(compararPistas("Gato", "gato").motivo, "identica");
  assert.equal(compararPistas("gatos", "gato").motivo, "plural");
  assert.equal(compararPistas("gato", "gata").motivo, "genero");
  assert.equal(compararPistas("casa", "carro").anulada, false);
});

test("palpite ignora acento e anula a pista igual ao alvo", () => {
  assert.equal(palpiteCorreto("Café", "cafe"), true);
  const [pista] = aplicarAnulacoes(
    [{
      clueId: "1",
      autorUid: "a",
      texto: "Gatos",
      anulada: false,
      motivoAutoAnulacao: null,
    }],
    "gato",
  );
  assert.equal(pista.anulada, true);
  assert.equal(pista.motivoAutoAnulacao, "palavra_alvo");
});
