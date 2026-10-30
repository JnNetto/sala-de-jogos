// shortcut: mesma regra de ResistenciaConstants no app Dart, unificar quando Dart e Functions compartilharem runtime

export const maxRejeicoes = 5;
export const vitoriasNecessarias = 3;

const teamSizes: Record<number, number[]> = {
  5: [2, 3, 2, 3, 3],
  6: [2, 3, 4, 3, 4],
  7: [2, 3, 3, 4, 4],
  8: [3, 4, 4, 5, 5],
  9: [3, 4, 4, 5, 5],
  10: [3, 4, 4, 5, 5],
};

export function failsRequired(round: number, playerCount: number): number {
  return round === 4 && playerCount >= 7 ? 2 : 1;
}

export function teamSizeFor(playerCount: number, round: number): number {
  const sizes = teamSizes[playerCount];
  if (!sizes) {
    throw new Error("A Expedição precisa de 5 a 10 jogadores");
  }
  return sizes[round - 1];
}

export function legalMissionCard(team: string, success: boolean): boolean {
  return team === "good" ? true : success;
}

export function missionSecretId(proposalId: string): string {
  return `mission_${proposalId}`;
}

export type VoteResolution =
  | {outcome: "mission"}
  | {outcome: "spies"; rejections: number}
  | {outcome: "retry"; rejections: number};

/**
 * Na Expedição, as rejeições contam na partida inteira (as tochas que se
 * apagam), não só em sequência: a quinta entrega o jogo aos saqueadores.
 */
export function resolveVote(input: {
  votes: Record<string, boolean>;
  totalPlayers: number;
  rejections: number;
}): VoteResolution {
  const approvals = Object.values(input.votes).filter(Boolean).length;
  if (approvals > input.totalPlayers / 2) {
    return {outcome: "mission"};
  }

  const rejections = input.rejections + 1;
  if (rejections >= maxRejeicoes) {
    return {outcome: "spies", rejections};
  }
  return {outcome: "retry", rejections};
}

export type MissionResolution = {
  missionSucceeded: boolean;
  missionResults: boolean[];
  failCounts: number[];
  over: boolean;
  winner: "resistance" | "spies" | null;
};

export function resolveMission(input: {
  cards: Record<string, boolean>;
  round: number;
  playerCount: number;
  missionResults: boolean[];
  failCounts: number[];
}): MissionResolution {
  const failCount = Object.values(input.cards).filter((card) => !card).length;
  const missionSucceeded = failCount < failsRequired(input.round, input.playerCount);
  const missionResults = [...input.missionResults, missionSucceeded];
  const failCounts = [...input.failCounts, failCount];
  const successes = missionResults.filter(Boolean).length;
  const failures = missionResults.filter((result) => !result).length;
  const resistanceWins = successes >= vitoriasNecessarias;
  const spiesWin = failures >= vitoriasNecessarias;

  return {
    missionSucceeded,
    missionResults,
    failCounts,
    over: resistanceWins || spiesWin,
    winner: resistanceWins ? "resistance" : spiesWin ? "spies" : null,
  };
}
