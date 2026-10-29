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

export function normalizeDisplayName(value: unknown): string {
  if (typeof value !== "string") {
    throw new HttpsError("invalid-argument", "Nome inválido");
  }
  const name = value.trim();
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

export function createRoomCode(): string {
  const alphabet = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
  let code = "";
  for (let i = 0; i < 4; i++) {
    code += alphabet[Math.floor(Math.random() * alphabet.length)];
  }
  return code;
}

export function shuffle<T>(items: T[]): T[] {
  const list = [...items];
  for (let i = list.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
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
