import assert from "node:assert/strict";
import {test} from "node:test";

import {
  createRoomCode,
  entradaBloqueada,
  hostDepoisDeSair,
  limparTexto,
  normalizeCode,
  normalizeDisplayName,
  requireConta,
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

test("código da sala tem 6 caracteres sem letras ambíguas", () => {
  const code = createRoomCode();
  assert.match(code, /^[ABCDEFGHJKLMNPQRSTUVWXYZ23456789]{6}$/);
});

test("nomes perdem caracteres invisíveis e de controle", () => {
  assert.equal(limparTexto("A\u200Bn\u202Ea\u0007"), "Ana");
  assert.equal(limparTexto("  Bia   Lu  "), "Bia Lu");
  assert.throws(() => normalizeDisplayName("\u200B\u200B"));
});

test("nome e código do lobby recusam entrada fora do formato", () => {
  assert.equal(normalizeDisplayName("  Ana  "), "Ana");
  assert.throws(() => normalizeDisplayName(""));
  assert.equal(normalizeCode(" ab12 "), "AB12");
  assert.throws(() => normalizeCode("ABC"));
});

test("as salas online recusam sessões anônimas", () => {
  assert.throws(() => requireConta(undefined));
  assert.throws(() => requireConta({
    uid: "a",
    token: {firebase: {sign_in_provider: "anonymous"}},
  }));
  assert.equal(requireConta({
    uid: "a",
    token: {firebase: {sign_in_provider: "google.com"}},
  }), "a");
});
