#!/usr/bin/env python3
"""Importa um CSV de produtos (colunas: codigo, nome, foto) para catalogo_dados/<marca>.jsonl + fotos.

Retomável (pula foto já baixada) e educado (User-Agent identificado, pausa entre fotos).
Uso: /usr/bin/python3 -I scripts/catalogo/importar_csv.py eudora eudora_produtos.csv "Eudora"
Depois: python3 scripts/catalogo/gerar_sql.py eudora <versao>
"""
import csv, io, json, subprocess, sys, tempfile, time, urllib.error, urllib.parse, urllib.request
from pathlib import Path

UA = "SouConsultoraCatalogo/0.1 (carga do catalogo do app, leitura leve)"


def baixar(url):
    url = urllib.parse.quote(url, safe=":/?=&%~,+")
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    try:
        with urllib.request.urlopen(req, timeout=60) as r:
            return r.read()
    except urllib.error.HTTPError as e:
        if e.code in (403, 429):
            raise SystemExit(f"BLOQUEIO HTTP {e.code}, parando.")
        raise


def para_jpeg(bruto, destino):
    with tempfile.NamedTemporaryFile(suffix=".img") as f:
        f.write(bruto); f.flush()
        r = subprocess.run(["sips", "-s", "format", "jpeg", "-s", "formatOptions", "85", "-Z", "800", f.name, "--out", str(destino)], capture_output=True)
    return r.returncode == 0 and destino.exists() and destino.stat().st_size > 2000


def main():
    chave, caminho_csv, nome_marca = sys.argv[1], sys.argv[2], sys.argv[3]
    raiz = Path("catalogo_dados"); pasta = raiz / chave; pasta.mkdir(parents=True, exist_ok=True)
    linhas = list(csv.DictReader(io.StringIO(Path(caminho_csv).read_text(encoding="utf-8-sig"))))
    vistos, saida = set(), []
    for i, l in enumerate(linhas, 1):
        cod = l["codigo"].strip()
        if not cod or cod in vistos:
            continue
        vistos.add(cod)
        destino = pasta / f"{cod}.jpg"
        ok = destino.exists()
        if not ok and l.get("foto"):
            try:
                ok = para_jpeg(baixar(l["foto"]), destino)
            except SystemExit:
                raise
            except Exception as e:
                print(f"  falha foto {cod}: {str(e)[:70]}", flush=True)
            time.sleep(0.3)
        saida.append({"marca": nome_marca, "codigo": cod, "nome": " ".join(l["nome"].split()), "foto": f"{chave}/{cod}.jpg" if ok else None})
        if i % 100 == 0:
            print(f"{i}/{len(linhas)}", flush=True)
    (raiz / f"{chave}.jsonl").write_text("\n".join(json.dumps(r, ensure_ascii=False) for r in saida) + "\n", encoding="utf-8")
    print(f"\nFim: {len(saida)} produtos; sem foto: {sum(1 for r in saida if not r['foto'])}", flush=True)


if __name__ == "__main__":
    sys.exit(main())
