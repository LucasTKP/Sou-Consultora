#!/usr/bin/env python3
"""Extrai nome, código e foto de uma marca do BR Catálogos para catalogo_dados/<marca>/.

Retomável: roda de novo e só busca o que ainda não está no manifesto/na pasta.
Educado: User-Agent identificado, pausa entre requisições, para em 403/429.

Uso:  /usr/bin/python3 -I scripts/catalogo/extrair_marca.py natura [--paginas N] [--pausa 1.0]
Saída: catalogo_dados/<marca>/<codigo>.jpg  e  catalogo_dados/<marca>.jsonl (manifesto)
As fotos e os dados NÃO vão para o git (ver .gitignore).
"""
import argparse, html, json, re, subprocess, sys, tempfile, time, urllib.error, urllib.parse, urllib.request
from pathlib import Path

BASE = "https://brcatalogos.com.br"
UA = "SouConsultoraCatalogo/0.1 (carga do catálogo do app, leitura leve)"
MARCAS = {  # chave: (slug no BR Catálogos, nome da marca = nome do fornecedor)
    "natura": ("revista-natura", "Natura"),
    "avon": ("catalogo-avon", "Avon"),
    "boticario": ("oboticario", "O Boticário"),
    "eudora": ("catalogo-eudora", "Eudora"),
    "marykay": ("catalogo-marykay", "Mary Kay"),
    "tupperware": ("catalogo-tupperware", "Tupperware"),
}
RE_CARD = re.compile(r'<a class="ProductSearchCard_card[^"]*"[^>]*title="([^"]*)"[^>]*href="([^"]+)"(.*?)</a>', re.S)
RE_TOTAL = re.compile(r'(\d[\d.]*)\s*produtos')


class Bloqueio(Exception):
    pass


def get(url, binario=False):
    req = urllib.request.Request(url, headers={"User-Agent": UA, "Accept-Language": "pt-BR"})
    try:
        with urllib.request.urlopen(req, timeout=40) as r:
            d = r.read()
            return d if binario else d.decode("utf-8", "ignore")
    except urllib.error.HTTPError as e:
        if e.code in (403, 429):
            raise Bloqueio(f"HTTP {e.code} em {url}")
        raise


def cards(pagina_html):
    for titulo, href, corpo in RE_CARD.findall(pagina_html):
        m = re.search(r"-([A-Za-z0-9]+)$", href)
        srcset = re.search(r'srcSet="([^"]+)"', corpo)
        if not m or not srcset:
            continue
        u = html.unescape(srcset.group(1).split(" ")[0])
        q = urllib.parse.parse_qs(urllib.parse.urlparse(u).query).get("url")
        yield {"codigo": m.group(1), "nome": " ".join(html.unescape(titulo).split()), "foto_origem": q[0] if q else None}


def para_jpeg(bruto: bytes, destino: Path) -> bool:
    with tempfile.NamedTemporaryFile(suffix=".img") as f:
        f.write(bruto); f.flush()
        r = subprocess.run(["sips", "-s", "format", "jpeg", "-s", "formatOptions", "85", "-Z", "800", f.name, "--out", str(destino)],
                           capture_output=True)
    return r.returncode == 0 and destino.exists() and destino.stat().st_size > 2000


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("marca", choices=list(MARCAS))
    ap.add_argument("--paginas", type=int, default=0, help="limita páginas (teste); 0 = todas")
    ap.add_argument("--pausa", type=float, default=1.0)
    a = ap.parse_args()
    slug, nome_marca = MARCAS[a.marca]
    raiz = Path("catalogo_dados"); pasta = raiz / a.marca; pasta.mkdir(parents=True, exist_ok=True)
    manifesto = raiz / f"{a.marca}.jsonl"
    feitos = {}
    if manifesto.exists():
        for l in manifesto.read_text(encoding="utf-8").splitlines():
            if l.strip():
                d = json.loads(l); feitos[d["codigo"]] = d
    print(f"{nome_marca}: {len(feitos)} já no manifesto", flush=True)

    pagina, vazias, total_site = 1, 0, None
    with manifesto.open("a", encoding="utf-8") as saida:
        while True:
            if a.paginas and pagina > a.paginas:
                break
            h = get(f"{BASE}/{slug}/produtos?page={pagina}")
            if total_site is None and (m := RE_TOTAL.search(re.sub(r"<[^>]+>", " ", h))):
                total_site = int(m.group(1).replace(".", ""))
                print(f"o site informa {total_site} produtos", flush=True)
            itens = list(cards(h))
            novos = 0
            for it in itens:
                if it["codigo"] in feitos and (pasta / f'{it["codigo"]}.jpg').exists():
                    continue
                destino = pasta / f'{it["codigo"]}.jpg'
                ok = False
                if it["foto_origem"] and not destino.exists():
                    try:
                        ok = para_jpeg(get(it["foto_origem"], binario=True), destino)
                    except Bloqueio:
                        raise
                    except Exception as e:
                        print(f'  falha foto {it["codigo"]}: {str(e)[:60]}', flush=True)
                    time.sleep(0.3)
                else:
                    ok = destino.exists()
                reg = {"marca": nome_marca, "codigo": it["codigo"], "nome": it["nome"], "foto": f'{a.marca}/{it["codigo"]}.jpg' if ok else None}
                if it["codigo"] not in feitos:
                    saida.write(json.dumps(reg, ensure_ascii=False) + "\n"); saida.flush()
                feitos[it["codigo"]] = reg; novos += 1
            print(f"página {pagina}: {len(itens)} itens, {novos} novos, total {len(feitos)}", flush=True)
            if not itens or novos == 0 and len(itens) < 24 and total_site and len(feitos) >= total_site:
                vazias += 1
                if vazias >= 2:
                    break
            else:
                vazias = 0
            pagina += 1
            time.sleep(a.pausa)

    sem_foto = [c for c, d in feitos.items() if not d["foto"]]
    print(f"\nFim: {len(feitos)} produtos (site: {total_site}); sem foto: {len(sem_foto)}", flush=True)


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Bloqueio as e:
        print("BLOQUEIO, parando:", e); sys.exit(2)
