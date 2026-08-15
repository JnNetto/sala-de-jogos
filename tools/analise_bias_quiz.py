import json
import re
from collections import Counter
from pathlib import Path
from statistics import mean, median

path = Path("quiz_da_vez_banco_v2_1050_perguntas (1).json")
data = json.loads(path.read_text(encoding="utf-8"))
perguntas = data["perguntas"]


def lens(p):
    return [len(str(a)) for a in p["alternativas"]]


def is_uniquely_longest_correct(p):
    L = lens(p)
    i = p["resposta_correta"]
    mx = max(L)
    return L[i] == mx and L.count(mx) == 1


def length_gap(p):
    L = lens(p)
    i = p["resposta_correta"]
    others = [L[j] for j in range(4) if j != i]
    return L[i] - max(others)


def looks_descriptive(p):
    """Heurística: alternativas longas/conceituais (frases), não nomes curtos."""
    alts = [str(a).strip() for a in p["alternativas"]]
    L = [len(a) for a in alts]
    avg = mean(L)
    med = median(L)
    word_counts = [len(a.split()) for a in alts]
    avg_words = mean(word_counts)
    q = p["pergunta"].lower()
    q_concept = bool(
        re.search(
            r"o que (é|significa)|qual (é )?(a |o )?(definição|conceito|função|objetivo|característica|nome do processo|efeito|resultado)|define-se|consiste em|significa",
            q,
        )
    )
    long_opts = avg >= 45 or med >= 40 or avg_words >= 7
    many_long = sum(1 for x in L if x >= 35) >= 3
    return long_opts or many_long or (q_concept and avg >= 30)


desc = [p for p in perguntas if looks_descriptive(p)]

suspects = []
for p in desc:
    gap = length_gap(p)
    uniq = is_uniquely_longest_correct(p)
    L = lens(p)
    i = p["resposta_correta"]
    others = sorted([L[j] for j in range(4) if j != i], reverse=True)
    ratio = L[i] / others[0] if others[0] else 999
    if uniq and (gap >= 10 or (ratio >= 1.25 and gap >= 8)):
        suspects.append((gap, ratio, p))
    elif uniq and gap >= 6 and mean(L) >= 50:
        suspects.append((gap, ratio, p))

suspects.sort(key=lambda x: (-x[0], -x[1]))

uniq_desc = sum(1 for p in desc if is_uniquely_longest_correct(p))
mild = [
    (length_gap(p), p)
    for p in desc
    if is_uniquely_longest_correct(p) and 1 <= length_gap(p) < 10
]

print("total", len(perguntas))
print("descritivas", len(desc))
print("descritivas uniq longest", uniq_desc)
print("suspeitas fortes", len(suspects))
print("mild gap<10", len(mild))

out = Path("analise_bias_comprimento_quiz.md")
lines = [
    "# Análise: viés de comprimento em respostas descritivas/conceituais\n",
    f"Arquivo: `{path.name}`\n",
    f"- Total de perguntas: **{len(perguntas)}**",
    f"- Classificadas como descritivas/conceituais: **{len(desc)}**",
    f"- Dessas, correta é unicamente a mais longa: **{uniq_desc}**",
    f"- **Suspeitas de não reformuladas** (correta claramente mais longa): **{len(suspects)}**\n",
    "Critério de suspeita: pergunta conceitual/descritiva E resposta correta é a única mais longa E (diferença ≥ 10 caracteres OU razão ≥ 1.25 com diferença ≥ 8).\n",
    "---\n",
    f"## Suspeitas ({len(suspects)})\n",
]

for gap, ratio, p in suspects:
    alts = p["alternativas"]
    i = p["resposta_correta"]
    lines.append(f"### {p['id']} — {p['categoria']} / {p['dificuldade']}")
    lines.append(f"**Pergunta:** {p['pergunta']}")
    lines.append(f"- Gap vs 2ª maior: **{gap}** chars | razão: **{ratio:.2f}**")
    for j, a in enumerate(alts):
        mark = " ✅ CORRETA" if j == i else ""
        lines.append(f"  - [{j}] ({len(str(a))} chars) {a}{mark}")
    lines.append("")

# also list mild ones briefly
lines.append("---\n")
lines.append(
    f"## Borderline (correta mais longa, gap 1–9 chars) — {len(mild)} itens\n"
)
lines.append(
    "Podem ser coincidência; ainda assim vale revisar se forem muito conceituais.\n"
)
for gap, p in sorted(mild, key=lambda x: -x[0]):
    L = lens(p)
    i = p["resposta_correta"]
    lines.append(
        f"- **{p['id']}** gap={gap} | correta={L[i]} | alts={L} | {p['pergunta'][:80]}..."
    )

out.write_text("\n".join(lines), encoding="utf-8")
print("wrote", out)

print("\nIDS_FORTES:")
print(", ".join(p["id"] for _, __, p in suspects))
print("by cat", dict(Counter(p["categoria"] for _, __, p in suspects)))
print("by dif", dict(Counter(p["dificuldade"] for _, __, p in suspects)))

# Also export JSON of suspects for clarity
json.dump(
    [
        {
            "id": p["id"],
            "categoria": p["categoria"],
            "dificuldade": p["dificuldade"],
            "pergunta": p["pergunta"],
            "alternativas": p["alternativas"],
            "resposta_correta": p["resposta_correta"],
            "gap": gap,
            "ratio": round(ratio, 2),
            "lens": lens(p),
        }
        for gap, ratio, p in suspects
    ],
    open("analise_bias_suspeitas.json", "w", encoding="utf-8"),
    ensure_ascii=False,
    indent=2,
)
print("wrote analise_bias_suspeitas.json")
