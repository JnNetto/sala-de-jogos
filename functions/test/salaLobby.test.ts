import assert from "node:assert/strict";
import {test} from "node:test";

import {
  createRoomCode,
  entradaBloqueada,
  hostDepoisDeSair,
  normalizeCode,
  normalizeDisplayName,
} from "../src/salaLobbyRegras.ts";

test("sala cheia só bloqueia quem ainda não entrou", () => {
  assert.equal(entradaBloqueada(false, 10, 10), true);
  assert.equal(entradaBloqueada(true, 10, 10), false);
  assert.equal(entradaBloqueada(false, 6, 7), false);
});

test("host que sai passa a vez para o próximo que ficou", () => {
  assert.equal(hostDepoisDeSair("host", "host", ["b", "c"]), "b");
  assert.equal(hostDepoisDeSair("host", "b", ["host", "c"]), "host");
  assert.equal(hostDepoisDeSair("host", "host", []), null);
});

test("código da sala tem 4 caracteres sem letras ambíguas", () => {
  const code = createRoomCode();
  assert.match(code, /^[ABCDEFGHJKLMNPQRSTUVWXYZ23456789]{4}$/);
});

test("nome e código do lobby recusam entrada fora do formato", () => {
  assert.equal(normalizeDisplayName("  Ana  "), "Ana");
  assert.throws(() => normalizeDisplayName(""));
  assert.equal(normalizeCode(" ab12 "), "AB12");
  assert.throws(() => normalizeCode("ABC"));
});
