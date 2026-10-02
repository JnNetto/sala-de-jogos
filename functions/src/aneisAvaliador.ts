const VOGAL = new Set(["a", "e", "i", "o", "u"]);

export type PalavraMeta = {
  normalizada: string;
  silabas: number;
  genero: string;
  inicia: string;
  termina: string;
  temAcento: boolean;
  temHifen: boolean;
  temEspaco: boolean;
};

export type Coisa = {
  id: string;
  texto: string;
  palavra: PalavraMeta;
  tags: string[];
};

export type Avaliacao = {
  tipo: string;
  letra?: string;
  valor?: string | number;
  op?: string;
  qualquer?: string[];
  todas?: string[];
  nenhuma?: string[];
};

export type Regra = {
  id: string;
  anel: "palavra" | "atributo" | "contexto";
  dificuldade: string;
  texto: string;
  avaliacao: Avaliacao;
};

export type AnelPublico = {
  id: string;
  nome: string;
  subtitulo: string;
  cor: string;
};

export const REGIOES_VALIDAS = new Set([
  "nenhum",
  "palavra",
  "atributo",
  "contexto",
  "palavra_atributo",
  "palavra_contexto",
  "atributo_contexto",
  "todos",
]);

function letras(normalizada: string): string {
  return (normalizada ?? "").toLowerCase().replace(/[^a-z]/g, "");
}

function compararQuantidade(
  n: number,
  op: string | undefined,
  valor: string | number | undefined,
): boolean {
  const alvo = typeof valor === "number" ? valor : Number(valor);
  switch (op) {
    case "par":
      return n % 2 === 0;
    case "impar":
      return n % 2 === 1;
    case "min":
      return Number.isFinite(alvo) && n >= alvo;
    case "max":
      return Number.isFinite(alvo) && n <= alvo;
    case "eq":
    default:
      return Number.isFinite(alvo) && n === alvo;
  }
}

export function avaliaRegra(coisa: Coisa, regra: Regra): boolean {
  const av = regra.avaliacao;
  const n = letras(coisa.palavra?.normalizada ?? "");
  switch (av.tipo) {
    case "iniciaComVogal":
      return n.length > 0 && VOGAL.has(n[0]);
    case "iniciaComConsoante":
      return n.length > 0 && !VOGAL.has(n[0]);
    case "iniciaCom":
      return n.startsWith(String(av.letra ?? "").toLowerCase());
    case "terminaCom":
      return n.endsWith(String(av.letra ?? "").toLowerCase());
    case "contemLetra":
      return n.includes(String(av.letra ?? "").toLowerCase());
    case "naoContemLetra":
      return !n.includes(String(av.letra ?? "").toLowerCase());
    case "quantidadeLetras":
      return compararQuantidade(n.length, av.op, av.valor);
    case "quantidadeSilabas":
      return compararQuantidade(coisa.palavra.silabas, av.op, av.valor);
    case "genero":
      return coisa.palavra.genero === String(av.valor ?? "");
    case "temAcento":
      return coisa.palavra.temAcento === true;
    case "temHifen":
      return coisa.palavra.temHifen === true;
    case "temEspaco":
      return coisa.palavra.temEspaco === true;
    case "iniciaETerminaIgual":
      return n.length > 0 && n[0] === n[n.length - 1];
    case "tags": {
      const set = new Set(coisa.tags ?? []);
      if (av.todas && av.todas.length > 0 && !av.todas.every((tag) => set.has(tag))) {
        return false;
      }
      if (
        av.qualquer &&
        av.qualquer.length > 0 &&
        !av.qualquer.some((tag) => set.has(tag))
      ) {
        return false;
      }
      if (av.nenhuma && av.nenhuma.some((tag) => set.has(tag))) {
        return false;
      }
      return true;
    }
    default:
      return false;
  }
}

export function regiaoDe(coisa: Coisa, regras: Regra[]): string {
  const porAnel = new Map(regras.map((regra) => [regra.anel, regra]));
  const inPalavra = porAnel.has("palavra") ?
    avaliaRegra(coisa, porAnel.get("palavra") as Regra) :
    false;
  const inAtributo = porAnel.has("atributo") ?
    avaliaRegra(coisa, porAnel.get("atributo") as Regra) :
    false;
  const inContexto = porAnel.has("contexto") ?
    avaliaRegra(coisa, porAnel.get("contexto") as Regra) :
    false;

  if (inPalavra && inAtributo && inContexto) return "todos";
  if (inPalavra && inAtributo) return "palavra_atributo";
  if (inPalavra && inContexto) return "palavra_contexto";
  if (inAtributo && inContexto) return "atributo_contexto";
  if (inPalavra) return "palavra";
  if (inAtributo) return "atributo";
  if (inContexto) return "contexto";
  return "nenhum";
}

export function escolherPistasIniciais(
  candidatos: Coisa[],
  regras: Regra[],
  quantidade: number,
): Coisa[] {
  const porRegiao = new Map<string, Coisa[]>();
  for (const coisa of candidatos) {
    const regiao = regiaoDe(coisa, regras);
    const lista = porRegiao.get(regiao) ?? [];
    lista.push(coisa);
    porRegiao.set(regiao, lista);
  }

  const escolhidas: Coisa[] = [];
  for (const lista of porRegiao.values()) {
    if (escolhidas.length >= quantidade) break;
    escolhidas.push(lista[0]);
  }

  for (const coisa of candidatos) {
    if (escolhidas.length >= quantidade) break;
    if (!escolhidas.some((item) => item.id === coisa.id)) {
      escolhidas.push(coisa);
    }
  }

  return escolhidas.slice(0, quantidade);
}
