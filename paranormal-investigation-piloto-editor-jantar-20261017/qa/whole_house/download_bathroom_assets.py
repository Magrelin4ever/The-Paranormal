#!/usr/bin/env python3
"""Downloads estáticos de páginas oficiais abertas e verificadas; nenhum serviço em runtime."""
from pathlib import Path
import hashlib, json, requests
root=Path(__file__).resolve().parents[2]
out=root/'prototype/assets/models/bathroom_20261019'
out.mkdir(parents=True,exist_ok=True)
items=[
 ('banheira_vintage','clawfoot-clawfoot-bathtub-fd250e8d',[.762,1.58,.81],9000),
 ('banheira_familiar','inset-bath-inset-bathtub-118db49b',[.802,1.71,.527],5000),
 ('vaso_sanitario','compact-wc-close-coupled-toilet-84214efd',[.432,.741,.932],5000),
 ('suporte_papel','roll-holder-toilet-roll-holder-cb0a7419',[.205,.111,.064],1000),
]
manifest=[]
for name,slug,size,tris in items:
    source='https://www.innerscene.com/tools/library/3d-parts/'+slug
    url='https://www.innerscene.com/api/library/'+slug+'/download'
    response=requests.get(url,timeout=60); response.raise_for_status()
    data=response.content
    if data[:4]!=b'glTF': raise RuntimeError('Download não é GLB: '+name)
    (out/(name+'.glb')).write_bytes(data)
    manifest.append(dict(file=name+'.glb',author='Innerscene — original model',source=source,download=url,license='CC0 1.0',license_url='https://creativecommons.org/publicdomain/zero/1.0/',terms='https://www.innerscene.com/tools/library/terms',declared_size_W_D_H_m=size,declared_triangles_approx=tris,sha256=hashlib.sha256(data).hexdigest(),bytes=len(data)))
    print(name,len(data),'bytes')
(out/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n')
text='# Banheiros: assets CC0 usados na casa\n\n'
text+='Os modelos foram disponibilizados pela biblioteca oficial da Innerscene como originais em domínio público (CC0), com materiais PBR embutidos e escala em metros. As páginas foram abertas para conferir licença e dimensões antes do download. A origem e o SHA-256 de cada arquivo estão em `manifest.json`.\n\n'
for item in manifest:
    text+=f"- **{item['file']}** — [página oficial]({item['source']}), autor Innerscene, licença [CC0 1.0]({item['license_url']}); dimensões declaradas largura × profundidade × altura: {item['declared_size_W_D_H_m']} m; cerca de {item['declared_triangles_approx']} triângulos. SHA-256: `{item['sha256']}`.\n"
text+='\nA banheira familiar é uma banheira real embutida; a suíte usa a banheira vintage com pés. Nenhum tanque de lavanderia foi usado como banheira. Nenhuma luz interna foi adicionada.\n'
(out/'FONTES_E_LICENCAS.md').write_text(text)
