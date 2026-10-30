import {randomInt} from "node:crypto";
import {HttpsError} from "firebase-functions/v2/https";

export type SalaLobby = {
  rooms: string;
  codes: string;
  maxPlayers: number;
  roomExtra?: Record<string, unknown>;
  playerExtra?: Record<string, unknown>;
};

export function requireUid(uid: string | undefined): string {
  if (!uid) {
    throw new HttpsError("unauthenticated", "Faça login para continuar");
  }
  return uid;
}

/**
 * Tira caracteres de controle e de formatação invisíveis (zero-width,
 * inversão de direção do texto), que serviriam para disfarçar um nome ou
 * bagunçar a tela dos outros, e junta espaços repetidos.
 */
export function limparTexto(value: string): string {
  return value
    .replace(/[\p{Cc}\p{Cf}]/gu, "")
    .replace(/\s+/g, " ")
    .trim();
}

/** O que as chamadas trazem de quem chamou (o `req.auth`). */
type Autenticacao = {
  uid: string;
  token: {firebase?: {sign_in_provider?: string}};
} | undefined;

/**
 * As salas online só aceitam quem entrou com uma conta: sessões anônimas
 * (sem login) ficam de fora.
 */
export function requireConta(auth: Autenticacao): string {
  const uid = requireUid(auth?.uid);
  if (auth?.token?.firebase?.sign_in_provider === "anonymous") {
    throw new HttpsError("unauthenticated", "Entre com sua conta para jogar online");
  }
  return uid;
}

export function normalizeDisplayName(value: unknown): string {
  if (typeof value !== "string") {
    throw new HttpsError("invalid-argument", "Nome inválido");
  }
  const name = limparTexto(value);
  if (name.length < 1 || name.length > 24) {
    throw new HttpsError("invalid-argument", "Nome deve ter 1 a 24 caracteres");
  }
  return name;
}

export function normalizeCode(value: unknown): string {
  if (typeof value !== "string") {
    throw new HttpsError("invalid-argument", "Código inválido");
  }
  const code = value.trim().toUpperCase();
  if (!/^[A-Z0-9]{4,6}$/.test(code)) {
    throw new HttpsError("invalid-argument", "Código inválido");
  }
  return code;
}

export function requireRoomId(value: unknown): string {
  if (typeof value !== "string" || value.trim().length < 1) {
    throw new HttpsError("invalid-argument", "Sala inválida");
  }
  return value.trim();
}

export function requireTargetUid(value: unknown): string {
  if (typeof value !== "string" || value.trim().length < 1) {
    throw new HttpsError("invalid-argument", "Jogador inválido");
  }
  return value.trim();
}

/** Tamanho do código: 32^6 ≈ 1 bilhão, para não dar para chutar salas. */
export const TAMANHO_CODIGO = 6;

export function createRoomCode(): string {
  const alphabet = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
  let code = "";
  for (let i = 0; i < TAMANHO_CODIGO; i++) {
    code += alphabet[randomInt(alphabet.length)];
  }
  return code;
}

/** Embaralha com RNG criptográfico: papéis e cartas não dão para prever. */
export function shuffle<T>(items: T[]): T[] {
  const list = [...items];
  for (let i = list.length - 1; i > 0; i--) {
    const j = randomInt(i + 1);
    [list[i], list[j]] = [list[j], list[i]];
  }
  return list;
}

export function entradaBloqueada(
  jogadorJaEsta: boolean,
  playerCount: number,
  maxPlayers: number,
): boolean {
  return !jogadorJaEsta && playerCount >= maxPlayers;
}

export function hostDepoisDeSair(
  hostUid: string,
  quemSai: string,
  restantes: string[],
): string | null {
  if (restantes.length === 0) return null;
  return hostUid === quemSai ? restantes[0] : hostUid;
}
