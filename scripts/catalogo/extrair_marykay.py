#!/usr/bin/env python3
"""Extrai o catálogo da Mary Kay da loja oficial (VTEX) para catalogo_dados/marykay.jsonl + fotos.

Usa a API pública de catálogo da loja (loja.marykay.com.br/api/catalog_system/pub/products/search),
liberada no robots.txt do site. Um item por PRODUTO (as variações de tom ficam de fora).
Retomável: pula o que já tem foto. Educado: User-Agent identificado e pausa entre requisições.

Uso: /usr/bin/python3 -I scripts/catalogo/extrair_marykay.py
"""
import json, re, subprocess, sys, tempfile, time, urllib.error, urllib.parse, urllib.request
from pathlib import Path

HOST = "https://loja.marykay.com.br"
UA = "SouConsultoraCatalogo/0.1 (carga do catalogo do app, leitura leve)"
# Primeira categoria da loja → categoria padrão do app (None = a consultora escolhe).
CATEGORIAS = {
    "Maquiagem": "Maquiagem",
    "Cuidados com a Pele": "Cuidados com a pele",
    "Cuidados Faciais": "Cuidados com a pele",
    "Cuidados Corporais": "Corpo e banho",
    "Skin Care": "Cuidados com a pele",
    "Fragrâncias": "Perfumaria",
    "Perfumes": "Perfumaria",
    "Corpo": "Corpo e banho",
    "Corpo e Banho": "Corpo e banho",
    "Cabelos": "Cabelos",
    "Masculino": "Masculino",
    "Homens": "Masculino",
    "Presentes": "Presentes",
    "Kits": "Presentes",
}


def get(url, binario=False):
    # URLs de imagem trazem espaços e símbolos (ex.: ®) que precisam de percent-encoding.
    url = urllib.parse.quote(url, safe=":/?=&%~,+")
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    try:
        with urllib.request.urlopen(req, timeout=60) as r:
            d = r.read()
            return d if binario else json.loads(d)
    except urllib.error.HTTPError as e:
        if e.code in (403, 429):
            raise SystemExit(f"BLOQUEIO HTTP {e.code}, parando.")
        raise


def para_jpeg(bruto, destino):
    with tempfile.NamedTemporaryFile(suffix=".img") as f:
        f.write(bruto); f.flush()
        r = subprocess.run(["sips", "-s", "format", "jpeg", "-s", "formatOptions", "85", "-Z", "800", f.name, "--out", str(destino)], capture_output=True)
    return r.returncode == 0 and destino.exists() and destino.stat().st_size > 2000


def foto_do_produto(p):
    """Imagens da melhor variação: pula as "Saindo de Linha", cujas fotos trazem um selo promocional."""
    com_foto = [it for it in p["items"] if it.get("images")]
    boas = [it for it in com_foto if not re.search(r"saindo de linha|descontinuad|esgotad", it["name"], re.I)]
    # Se todas as variações estão saindo de linha, todas as fotos têm o selo: melhor sem foto.
    return boas[0]["images"] if boas else []


def main():
    raiz = Path("catalogo_dados"); pasta = raiz / "marykay"; pasta.mkdir(parents=True, exist_ok=True)
    produtos, ini = [], 0
    while True:
        lote = get(f"{HOST}/api/catalog_system/pub/products/search?_from={ini}&_to={ini + 49}")
        if not lote:
            break
        produtos += lote
        print(f"produtos {ini}-{ini + 49}: {len(lote)}", flush=True)
        if len(lote) < 50:
            break
        ini += 50; time.sleep(1.5)

    Path(raiz / "marykay_api.json").write_text(json.dumps(produtos, ensure_ascii=False), encoding="utf-8")
    vistos, saida = set(), []
    for p in produtos:
        cod = str(p.get("productReference") or p["productId"]).strip()
        if cod in vistos:
            continue
        vistos.add(cod)
        topo = None
        for caminho in p.get("categories") or []:
            topo = caminho.strip("/").split("/")[0]
            break
        imgs = foto_do_produto(p)
        destino = pasta / f"{cod}.jpg"
        ok = destino.exists()
        if not ok and imgs:
            try:
                ok = para_jpeg(get(imgs[0]["imageUrl"], binario=True), destino)
            except Exception as e:
                print(f"  falha foto {cod}: {str(e)[:60]}", flush=True)
            time.sleep(0.4)
        saida.append({"marca": "Mary Kay", "codigo": cod, "nome": " ".join(p["productName"].split()),
                      "categoria": CATEGORIAS.get(topo), "categoria_site": topo,
                      "foto": f"marykay/{cod}.jpg" if ok else None})
    Path(raiz / "marykay.jsonl").write_text("\n".join(json.dumps(r, ensure_ascii=False) for r in saida) + "\n", encoding="utf-8")
    print(f"\nFim: {len(saida)} produtos; sem foto: {sum(1 for r in saida if not r['foto'])}", flush=True)


if __name__ == "__main__":
    sys.exit(main())
