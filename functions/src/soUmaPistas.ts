// shortcut: mesma regra de lib/core/utils/so_uma_pista_matcher.dart, unificar quando Dart e Functions compartilharem runtime

export type Pista = {
  clueId: string;
  autorUid: string;
  texto: string;
  anulada: boolean;
  motivoAutoAnulacao: string | null;
};

export type MatchResultado = {anulada: boolean; motivo?: string};

const COM_ACENTO = "àáâãäåèéêëìíîïòóôõöùúûüçñ";
const SEM_ACENTO = "aaaaaaeeeeiiiiooooouuuucn";

export function pistasPorEscritor(playerCount: number): number {
  return playerCount === 3 ? 2 : 1;
}

export function normalizarPalavra(texto: string): string {
  let resultado = texto.trim().toLowerCase();
  for (let i = 0; i < COM_ACENTO.length; i++) {
    resultado = resultado.split(COM_ACENTO[i]).join(SEM_ACENTO[i]);
  }
  resultado = resultado.replace(/^[^a-z0-9]+|[^a-z0-9]+$/g, "");
  resultado = resultado.replace(/\s+/g, " ");
  return resultado;
}

function radicalPlural(palavra: string): string {
  if (palavra.endsWith("oes") || palavra.endsWith("aes") || palavra.endsWith("ais")) {
    return palavra;
  }
  if (palavra.endsWith("es") && palavra.length > 3) return palavra.slice(0, -2);
  if (palavra.endsWith("s") && palavra.length > 3) return palavra.slice(0, -1);
  return palavra;
}

function mesmoPlural(a: string, b: string): boolean {
  return a !== b && radicalPlural(a) === radicalPlural(b);
}

function mesmoGenero(a: string, b: string): boolean {
  const termina = (s: string, sufixo: string) => s.length > 3 && s.endsWith(sufixo);
  if (termina(a, "o") && termina(b, "a")) return a.slice(0, -1) === b.slice(0, -1);
  if (termina(a, "a") && termina(b, "o")) return a.slice(0, -1) === b.slice(0, -1);
  return false;
}

function possivelMesmaRaiz(a: string, b: string): boolean {
  if (a.length < 4 || b.length < 4 || a === b) return false;
  const menor = a.length < b.length ? a : b;
  const maior = a.length < b.length ? b : a;
  let comuns = 0;
  while (comuns < menor.length && menor[comuns] === maior[comuns]) comuns++;
  return comuns >= 3 && comuns / menor.length >= 0.7;
}

export function compararComAlvo(pista: string, alvo: string): MatchResultado {
  const p = normalizarPalavra(pista);
  const a = normalizarPalavra(alvo);
  if (!p) return {anulada: false};
  if (p === a) return {anulada: true, motivo: "palavra_alvo"};
  if (mesmoPlural(p, a) || mesmoGenero(p, a)) return {anulada: true, motivo: "palavra_alvo"};
  if (possivelMesmaRaiz(p, a)) return {anulada: true, motivo: "palavra_alvo_raiz"};
  return {anulada: false};
}

export function compararPistas(x: string, y: string): MatchResultado {
  const nx = normalizarPalavra(x);
  const ny = normalizarPalavra(y);
  if (!nx || !ny) return {anulada: false};
  if (nx === ny) return {anulada: true, motivo: "identica"};
  if (mesmoPlural(nx, ny)) return {anulada: true, motivo: "plural"};
  if (mesmoGenero(nx, ny)) return {anulada: true, motivo: "genero"};
  if (possivelMesmaRaiz(nx, ny)) return {anulada: true, motivo: "raiz"};
  return {anulada: false};
}

export function palpiteCorreto(palpite: string, alvo: string): boolean {
  return normalizarPalavra(palpite) === normalizarPalavra(alvo);
}

export function aplicarAnulacoes(clues: Pista[], palavraAlvo: string): Pista[] {
  const atualizadas = clues.map((clue) => ({...clue}));

  for (const clue of atualizadas) {
    const resultado = compararComAlvo(clue.texto, palavraAlvo);
    if (resultado.anulada) {
      clue.anulada = true;
      clue.motivoAutoAnulacao = resultado.motivo ?? null;
    }
  }

  for (let i = 0; i < atualizadas.length; i++) {
    for (let j = i + 1; j < atualizadas.length; j++) {
      const resultado = compararPistas(atualizadas[i].texto, atualizadas[j].texto);
      if (resultado.anulada) {
        atualizadas[i].anulada = true;
        atualizadas[i].motivoAutoAnulacao =
          atualizadas[i].motivoAutoAnulacao ?? resultado.motivo ?? null;
        atualizadas[j].anulada = true;
        atualizadas[j].motivoAutoAnulacao =
          atualizadas[j].motivoAutoAnulacao ?? resultado.motivo ?? null;
      }
    }
  }

  return atualizadas;
}
