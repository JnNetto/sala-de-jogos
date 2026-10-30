import assert from "node:assert/strict";
import {test} from "node:test";

import {
  failsRequired,
  legalMissionCard,
  missionSecretId,
  resolveMission,
  resolveVote,
  teamSizeFor,
} from "../src/resistenciaTurno.ts";

test("quarta missão com 7 jogadores exige duas falhas", () => {
  assert.equal(failsRequired(4, 7), 2);
  assert.equal(failsRequired(4, 5), 1);
  assert.equal(failsRequired(3, 8), 1);
});

test("a quinta rejeição da partida entrega o jogo aos saqueadores", () => {
  const fim = resolveVote({
    votes: {a: true, b: true, c: false, d: false, e: false},
    totalPlayers: 5,
    rejections: 4,
  });
  assert.deepEqual(fim, {outcome: "spies", rejections: 5});
});

test("rejeições somam na partida, mesmo sem ser em sequência", () => {
  const segue = resolveVote({
    votes: {a: false, b: false, c: false, d: true, e: true},
    totalPlayers: 5,
    rejections: 2,
  });
  assert.deepEqual(segue, {outcome: "retry", rejections: 3});
});

test("maioria aprova a proposta", () => {
  const aprovada = resolveVote({
    votes: {a: true, b: true, c: true, d: false, e: false},
    totalPlayers: 5,
    rejections: 4,
  });
  assert.deepEqual(aprovada, {outcome: "mission"});
});

test("cartas de propostas diferentes não compartilham o segredo", () => {
  assert.equal(missionSecretId("proposta-a"), "mission_proposta-a");
  assert.notEqual(
    missionSecretId("partida-1"),
    missionSecretId("partida-2"),
  );
});

test("resistência não joga carta de fracasso", () => {
  assert.equal(legalMissionCard("good", false), true);
  assert.equal(legalMissionCard("evil", false), false);
});

test("duas falhas derrubam a quarta missão de 7 e encerram aos três fracassos", () => {
  const segurou = resolveMission({
    cards: {a: false, b: true, c: true, d: true},
    round: 4,
    playerCount: 7,
    missionResults: [false, false],
    failCounts: [1, 1],
  });
  assert.equal(segurou.missionSucceeded, true);
  assert.equal(segurou.over, false);

  const caiu = resolveMission({
    cards: {a: false, b: false, c: true, d: true},
    round: 4,
    playerCount: 7,
    missionResults: [false, false],
    failCounts: [1, 1],
  });
  assert.equal(caiu.missionSucceeded, false);
  assert.equal(caiu.over, true);
  assert.equal(caiu.winner, "spies");
});

test("tamanho da equipe segue a rodada", () => {
  assert.equal(teamSizeFor(7, 1), 2);
  assert.equal(teamSizeFor(7, 4), 4);
});
