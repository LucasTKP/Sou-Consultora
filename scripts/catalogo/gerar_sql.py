#!/usr/bin/env python3
"""Gera a migração de carga do catálogo de uma marca a partir de catalogo_dados/<marca>.jsonl.

A carga é idempotente (upsert por marca + código): rodar de novo atualiza, não duplica.
Uso:  python3 scripts/catalogo/gerar_sql.py natura 20261119000004
Saída: supabase/migrations/<versao>_catalogo_<marca>.sql  (+ resumo das categorias no terminal)
"""
import json, re, sys, unicodedata
from collections import Counter
from pathlib import Path

# Categorias padrão de produto da consultora (ver migração conta). Primeira regra que casar vence.
REGRAS = [
    ("Infantil", r"\bnature\b|\bbaby\b|\bbebe\b|\binfantil\b|\bmamae e bebe\b"),
    ("Presentes", r"\bpresente|\bcofre\b|\becobag\b|\bchaveiro\b|\bnecessaire\b|\bsacola\b|\bcartao\b"),
    ("Masculino", r"\bmasculin|\bmalbec\b|\bcoffee man\b|\bbarbear\b|\bhomem\b|\bbarba\b|\bpos[- ]?barba\b"),
    ("Perfumaria", r"\bcolonia\b|\bparfum\b|\bperfume\b|\beau de\b|\bbody splash\b|\bdeo parfum\b|\bdeo colonia\b|\bdes\.? col\b|\bessencial\b|\bkaiak\b"),
    ("Maquiagem", r"\bbrilho labial\b|\blabial\b|\brollette\b|\bcobertura\b|\bcuticula|\blixa\b|\bcorret\b|\bmake b\b|\bqdb\b|\blap olh\b|\bberestick\b|\bbb cream\b|\bbatom\b|\bbase\b|\bpo (compacto|facial|solto)\b|\bblush\b|\bsombra\b|\brimel\b|\bmascara (de |para )?cilios\b|\bcilios\b|\bfaces\b|\bduo\b|\bsuperbrilho\b|\bglitter\b|\blip\b|\bsobrancelhas?\b|\bdelineador\b|\bgloss\b|\bbalm\b|\biluminador\b|\bcorretivo\b|\blapis\b|\bpincel\b|\bpaleta\b|\bpalette\b|\besmalte\b|\bprimer\b|\bfixador\b|\bmaquiagem\b|\bbatons\b|\bcontorno\b|\bsobrancelha\b|\bpo bronzeador\b"),
    ("Cabelos", r"\bsiage\b|\bcondicionante\b|\bmatch\b|\blumina\b|\bsh\b|\bcond\b|\bampola\b|\bshampoo\b|\bxampu\b|\bcondicionador\b|\bcapilar\b|\bcabelo|\bpentear\b|\bleave\b|\bfinalizador\b|\bmascara de tratamento\b"),
    ("Cuidados com a pele", r"\bhidragel\b|\bskin\b|\bdermo\b|\bbotik\b|\bskincare\b|\bsol renov\b|\bbooster\b|\brenew\b|\bserum\b|\bfacial\b|\brosto\b|\bchronos\b|\btonico\b|\bprotetor solar\b|\bfps\b|\bantissinais\b|\bolhos\b|\bdemaquilante\b|\bmicelar\b|\bantiidade\b|\banti-idade\b|\bretinol\b|\bcolageno\b|\bvitamina c\b|\bacido\b"),
    ("Corpo e banho", r"\bshower gel\b|\bantitranspirante\b|\bloc des corp\b|\bsabonetes?\b|\bconcentrado\b|\bcorpo\b|\bcorporal\b|\bhidratante\b|\bdesodorante\b|\besfoliante\b|\bbanho\b|\btododia\b|\bekos\b|\bmaos\b|\bpes\b|\blocao\b|\bmanteiga\b|\bsais\b|\boleo\b|\brefil\b|\bcreme\b"),
]


def normalizar(t):
    t = unicodedata.normalize("NFD", t.lower())
    return "".join(c for c in t if unicodedata.category(c) != "Mn")


def categoria(nome):
    n = normalizar(nome)
    for cat, rx in REGRAS:
        if re.search(rx, n):
            return cat
    return None


def q(s):
    return "null" if s is None else "'" + s.replace("'", "''") + "'"


def main():
    marca_chave, versao = sys.argv[1], sys.argv[2]
    itens = {}
    for l in Path(f"catalogo_dados/{marca_chave}.jsonl").read_text(encoding="utf-8").splitlines():
        if l.strip():
            d = json.loads(l); itens[d["codigo"]] = d
    linhas, dist, sem = [], Counter(), []
    for d in sorted(itens.values(), key=lambda d: d["codigo"]):
        # Tupperware (utilidades) não tem categoria padrão equivalente: a consultora escolhe.
        # Marcas com categoria própria no manifesto (Mary Kay, da loja) usam a dela.
        cat = d["categoria"] if "categoria" in d else (None if marca_chave == "tupperware" else categoria(d["nome"]))
        dist[cat or "(sem categoria)"] += 1
        if cat is None:
            sem.append(d["nome"])
        linhas.append(f"  ({q(d['marca'])}, {q(d['codigo'])}, {q(d['nome'])}, {q(cat)}, {q(d['foto'])})")
    marca = next(iter(itens.values()))["marca"]
    corpo = ",\n".join(linhas)
    sql = f"""-- Carga do catálogo: {marca} ({len(itens)} produtos). GERADO por scripts/catalogo/gerar_sql.py.
-- Idempotente: rodar de novo atualiza nome, categoria e foto sem duplicar (marca + código).
-- Fotos em catalogo/{marca_chave}/<codigo>.jpg (enviadas com `supabase storage cp`).
insert into public.catalogo_produtos (marca, codigo, nome, categoria, foto_caminho) values
{corpo}
on conflict (marca, codigo) do update
  set nome = excluded.nome,
      categoria = coalesce(excluded.categoria, public.catalogo_produtos.categoria),
      foto_caminho = coalesce(excluded.foto_caminho, public.catalogo_produtos.foto_caminho);
"""
    saida = Path(f"supabase/migrations/{versao}_catalogo_{marca_chave}.sql")
    saida.write_text(sql, encoding="utf-8")
    print(f"{saida}: {len(itens)} produtos")
    for c, n in dist.most_common():
        print(f"  {n:5d}  {c}")
    print("exemplos sem categoria:", sem[:12])


if __name__ == "__main__":
    main()
