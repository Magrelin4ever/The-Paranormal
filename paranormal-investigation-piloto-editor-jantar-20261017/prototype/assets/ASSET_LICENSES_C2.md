# Assets e licenças — C2

## Poly Haven

Os novos modelos glTF foram baixados da API oficial em resolução 1K. A licença dos modelos da Poly Haven é CC0; a documentação da API diferencia o uso estático dos arquivos CC0 do uso do serviço ao vivo (que pede crédito visível quando integrado a um produto). Esta C2 usa arquivos baixados e inclui o crédito abaixo.

- Licença oficial: https://polyhaven.com/license
- Documentação da API: https://polyhaven.com/our-api
- Catálogo: https://polyhaven.com/models
- Origem local por asset: `prototype/assets/models/polyhaven/<asset_id>/`
- Registro de nomes, categorias, autores e checksums MD5/SHA-256: `prototype/assets/models/polyhaven_c2_manifest.json`
- Ferramenta reproduzível de download e validação: `qa/download_polyhaven_models_c2.py`

Modelos novos adicionados: `ArmChair_01`, `painted_wooden_bench`, `wooden_bookshelf_worn`, `coffee_table_round_01`, `wooden_display_shelves_01`, `book_encyclopedia_set_01`, `classic_laptop`, `binder_notebook`, `wicker_basket_01`, `ceramic_vase_02`, `fern_02`, `potted_plant_02`, `planter_pot_clay`, `vintage_oil_lamp`, `pot_enamel_01`, `wooden_cutting_board`, `food_apple_01`, `tool_cart`, `plastic_crate_01`, `wooden_crate_01`, `metal_trash_can`, `worn_metal_rack`, `hanging_picture_frame_02`, `wooden_bowl_01`, `small_wooden_table_01`, `metal_jug`, `vintage_cabinet_01` e `wine_bottles_01`.

### Mesa da biblioteca — `coffee_table_round_01`

- Fonte oficial: https://polyhaven.com/a/coffee_table_round_01 — autor Ulan Cabanilla; licença CC0.
- Modelo glTF 1K, 1,3 m de largura e 4 mil triângulos; superfície de mármore branco e pernas metálicas.
- URL, MD5 e SHA-256 de cada arquivo baixado: `prototype/assets/models/polyhaven_c2_manifest.json`.

### Adega compacta — C6

- **Vintage Cabinet 01** — armário de madeira envernizada, portas superiores de vidro e ferragens de latão; fonte oficial: https://polyhaven.com/a/vintage_cabinet_01; licença CC0; 2,2 m de altura e aproximadamente 61 mil triângulos na página oficial.
- **Wine Bottles 01** — conjunto de quatro garrafas de vinho/espumante em vidro com rótulos e detalhes PBR; fonte oficial: https://polyhaven.com/a/wine_bottles_01; licença CC0; 0,7 m de largura e aproximadamente 29 mil triângulos na página oficial.
- Versões glTF 1K, URLs e hashes MD5/SHA-256 dos arquivos usados: `prototype/assets/models/polyhaven_c2_manifest.json`.

## Innerscene — peças GLB CC0 em escala real

Cada página declara a dedicação CC0, permite uso/modificação/redistribuição e descreve o modelo como GLB em metros. Os arquivos estão em `prototype/assets/models/innerscene/`.

| Modelo | Página da peça e download | Dimensões publicadas (m) | SHA-256 do GLB local |
|---|---|---:|---|
| Lavadora/secadora combinada | https://www.innerscene.com/tools/library/3d-parts/washer-dryer-ac3fa07d | 0,598 × 0,590 × 0,848 | `fb3b6e29441cd24665fa04b77a797d970f7b23a0cb8f252f0bb6f4ee706ccaaf` |
| Secadora | https://www.innerscene.com/tools/library/3d-parts/tumble-dryer-93876b28 | 0,598 × 0,613 × 0,842 | `e57135f5656643e174d62aead9835e6ccb270dfbbc5570cd452629cc483021c9` |
| Geladeira de duas portas | https://www.innerscene.com/tools/library/3d-parts/cold-column-large-appliance-26616313 | 0,615 × 0,708 × 1,820 | `8d7e00741cc83dc8e5e60d90b90462968320f1de0405eef7e294257643ed0183` |
| Micro-ondas de bancada | https://www.innerscene.com/tools/library/3d-parts/wave-compact-large-appliance-8d8fbc52 | 0,482 × 0,400 × 0,292 | `6004a250e99394f4911cb4473ae6975ac8e141ee5a1be44d21586fdae134f3ac` |
| Bancada com painel perfurado | https://www.innerscene.com/tools/library/3d-parts/workbench-with-pegboard-e6179c3f | 1,500 × 0,650 × 1,800 | `3942dfc18e95bf7b6c99109c47056e835201967a36dc18b11f5de32d210a1b03` |
| Fogão de quatro bocas | https://www.innerscene.com/tools/library/3d-parts/cook-range-large-appliance-cbf198df | 0,609 × 0,703 × 0,931 | `e22bddd5836b199a4a254564c6b9afc721f8b50f0dab146a423608e14ec45209` |
| Cafeteira francesa Press Eight | https://www.innerscene.com/tools/library/3d-parts/press-eight-coffee-maker-33aa2907 | 0,169 × 0,110 × 0,233 | `b797dfa0080c4f69040c19673ea659073df9b2fdcbea156adee1f391804c116a` |
| Televisão moderna (Kenney Furniture Kit) | https://www.innerscene.com/tools/library/3d-parts/television-modern-9ac9fe77 | 0,685 × 0,455 × 0,128 (medido no GLB) | `d89519ad0a5f28b5b0dccb0d83209dccf610cda959578238dd21bbf9e219cfc6` |

Crédito do projeto: **Assets 3D de Poly Haven (CC0) e Innerscene (CC0)**. A C2 não consulta a API da Poly Haven durante a execução.

## Polimento da sala de estar — referência visual C3

- **Luminária tripé Beacon** — GLB CC0 da Innerscene, 0,623 × 0,592 × 1,57 m; materiais PBR embutidos. Página: https://www.innerscene.com/tools/library/3d-parts/beacon-tripod-floor-lamp-81bd9790. Arquivo/hash: `prototype/assets/models/innerscene/innerscene_c2_manifest.json`.
- **Ventilador de teto Ceiling Fan** — GLB CC0 disponibilizado pela Innerscene a partir da Poly Haven (autor Ulan Cabanilla), 1,46 × 1,46 × 0,52 m. Origem: https://polyhaven.com/a/ceiling_fan. Arquivo/hash: `prototype/assets/models/innerscene/innerscene_c2_manifest.json`.
- **Carpet012** — mapas PBR 2K JPG em CC0: color, normal GL, roughness e ambient occlusion. Página: https://ambientcg.com/view?id=Carpet012. Mapas/hashes: `prototype/assets/textures/ambientcg/Carpet012/ambientcg_c3_manifest.json`.
- **Cortina aberta** — modelo GLB CC0 da Innerscene, 2,120 × 0,078 × 2,193 m; a própria peça inclui varão, argolas e amarrações. Página: https://www.innerscene.com/tools/library/3d-parts/curtain-pair-open-original-interior-furnishing-8c8dbd3d.
- **Manta decorativa** — modelo GLB CC0 da Innerscene, 1,350 × 1,751 × 0,197 m. Página: https://www.innerscene.com/tools/library/3d-parts/throw-blanket-original-interior-decor-f452871f.
- **Almofadas Throw Pillows 01** — GLB CC0 de Poly Haven servido pela Innerscene, cerca de 1,02 × 0,63 × 0,45 m, com mapas PBR; origem: https://polyhaven.com/a/throw_pillows_01.
- **Planta interna Potted Plant 02** — modelo Poly Haven CC0 em glTF 1K, 69.806 triângulos; dimensões medidas na importação Godot: 0,701 × 0,841 × 0,657 m (a página oficial indica 0,8 m de altura). Origem: https://polyhaven.com/a/potted_plant_02. Arquivos e hashes: `prototype/assets/models/polyhaven_c2_manifest.json`.
- Manifesto, tamanhos e hashes das peças C4: `prototype/assets/models/innerscene/innerscene_c2_manifest.json`; referências completas: `qa/c4_living_room_external_sources.md`.


## Cozinha — assets C1

Os props Poly Haven abaixo são CC0, carregados localmente em glTF 1K; dimensões medidas no importador Godot (largura × altura × profundidade, em metros). URLs oficiais e checksums completos estão em `prototype/assets/models/polyhaven_c2_manifest.json`.

| Modelo | Dimensões locais (m) | Origem oficial |
|---|---:|---|
| Potted Plant 02 | 0,701 × 0,841 × 0,657 | https://polyhaven.com/a/potted_plant_02 |
| Pot Enamel 01 | 0,263 × 0,178 × 0,180 | https://polyhaven.com/a/pot_enamel_01 |
| Wooden Cutting Board | 0,450 × 0,041 × 0,247 | https://polyhaven.com/a/wooden_cutting_board |
| Food Apple 01 | 0,098 × 0,085 × 0,096 | https://polyhaven.com/a/food_apple_01 |
| Wooden Bowl 01 | 0,313 × 0,094 × 0,309 | https://polyhaven.com/a/wooden_bowl_01 |
| Metal Jug | 0,197 × 0,288 × 0,195 | https://polyhaven.com/a/metal_jug |
| Ceramic Pot | 0,656 × 0,372 × 0,502 | https://polyhaven.com/a/ceramic_pot |
| Brass Pan 01 | 0,191 × 0,053 × 0,450 | https://polyhaven.com/a/brass_pan_01 |
| Wooden Spoon | 0,087 × 0,025 × 0,278 | https://polyhaven.com/a/wooden_spoon |
| Russian Food Cans 01 | 0,142 × 0,085 × 0,046 | https://polyhaven.com/a/russian_food_cans_01 |
| Yellow Onion | 0,072 × 0,086 × 0,069 | https://polyhaven.com/a/yellow_onion |

As peças adicionais Innerscene também declaram CC0 nas páginas oficiais e no manifesto local:

- Pia dupla embutida: https://www.innerscene.com/tools/library/3d-parts/twin-sink-double-undermount-sink-2b2be750 — `undermount-double-sink.glb`, SHA-256 `c939a13dcd6b9fba0299e6af056c452e426aab2ddec166c34473bda1159c352a`.
- Torneira com ducha retrátil: https://www.innerscene.com/tools/library/3d-parts/spray-mixer-pull-down-kitchen-faucet-b292a842 — `pull-down-kitchen-faucet.glb`, SHA-256 `1e8a1d5acb155a3a59738d6162660646a373b8d3c0a1ef073656d06d35465968`.

Armários, ilha, prateleiras e banquetas são geometria procedural própria, sem licença externa. O minibar foi removido da composição do estar; seus arquivos de origem ficam no inventário local para eventual retrabalho futuro.


## Cozinha — atualização C7/C9

- **Kitchen Coffee Machine** (Kenney Furniture Kit), GLB CC0: https://www.innerscene.com/tools/library/3d-parts/kitchen-coffee-machine-3d3747f4. Bounds medidos no Godot: **0,190 × 0,177 × 0,241 m**; tamanho do arquivo: 13.332 bytes; SHA-256 `063f582c6fa0f00a9f24e3393dac2295491c4becdaf5513c893ab1a2826b6ec3`. Registro completo no manifesto `prototype/assets/models/innerscene/innerscene_c2_manifest.json`.
- O fogão de piso `kitchen-range.glb` permanece como asset CC0 documentado, mas não é instanciado na cozinha atual; foi substituído por um cooktop de indução geométrico procedural, sem dependência de asset externo. O forno e o micro-ondas ficam integrados à torre de nogueira.
- A revisão C9 manteve todas as luminárias internas desligadas e a navegação validada em 38/38 waypoints. As capturas finais 1280 × 720 estão em `qa/evidence/kitchen_c9_*.png`; script: `qa/capture_kitchen_c9.gd`.

## Cozinha — atualização C10

- **Wood Floor** (Poly Haven), usado no piso: mapas PBR JPG 2K (diffuse, normal GL, roughness e AO), licença CC0. Origem e hashes por arquivo: `prototype/assets/textures/polyhaven/c2_pbr_textures_2k_manifest.json`; página: https://polyhaven.com/a/wood_floor.
- **Marble002** (ambientCG), usado nas bancadas de pedra: 2048 × 2048, CC0 1.0, mapas Color, NormalGL e Roughness. **Wood026** (ambientCG), usado na nogueira da ilha, marcenaria, torre e prateleiras: 2048 × 2048, CC0 1.0, mapas Color, NormalGL e Roughness. Os pacotes baixados não incluem mapa AO; os manifests locais contêm URLs, tamanhos e SHA-256: `prototype/assets/textures/ambientcg/Marble002/ambientcg_c1_manifest.json` e `prototype/assets/textures/ambientcg/Wood026/ambientcg_c1_manifest.json`. Páginas oficiais: https://ambientcg.com/view?id=Marble002 e https://ambientcg.com/view?id=Wood026.
- **Forno embutido `kitchen_builtin_oven_c1.glb` (histórico C10)**: asset gerado por IA; o material contém o identificador `tripo_material_24ed640a-2b59-41aa-86f7-420ed9ed9c3e`. Bounds medidos: **0,583 × 0,600 × 0,612 m**, uma superfície texturizada. Foi usado temporariamente no checkpoint C10 e removido do projeto ativo na revisão C11. O GLB, mapas, metadados de importação e hashes estão preservados fora do projeto em `/workspace/paranormal-investigation-casa-polimento-c2-20261016_ai_quarantine/kitchen_builtin_oven_c1/`.
- **Direitos do forno IA: não confirmados — não é CC0.** O plano e o recibo da geração não estão registrados; nenhum direito comercial é afirmado. O modelo não é instanciado no C11. Reintegrar apenas se os termos do plano efetivamente usado permitirem o uso pretendido. Ver `qa/c1_ai_asset_terms.md` e o README da quarentena.
- Compilação, capturas e rota C10 permanecem como evidência histórica do checkpoint não aprovado: `qa/kitchen_c10_compile.log`, `qa/kitchen_c10_capture.log` e `qa/kitchen_c10_routes.log`; as auditorias então registraram 0 luzes internas e 0 materiais emissivos.
- Interação pela tecla E verificada no abre/fecha da porta frontal: `qa/kitchen_c10_key_e.log`; probe: `qa/c10_key_e_probe.gd`.

## Cozinha — revisão C11 (validada tecnicamente; aguardando revisão visual)

- O forno ativo foi reconstruído com geometria procedural própria (carcaça, moldura metálica, vidro escuro, puxador e controles sem emissão), sem dependência do GLB Tripo.
- A ilha ganhou faca de preparo com ponta arredondada apoiada na tábua, pano de tecido fosco, potes de sal/pimenta e conjunto de frutas; a estação de café recebeu canecas e pote de açúcar; as prateleiras receberam pratos, canecas, temperos e utensílios agrupados.
- Materiais de madeira receberam reflexão mais difusa; o pano procedural foi ajustado para não penetrar na bancada nem gerar uma dobra sobreposta. Ilha e prateleiras mantêm espaço livre intencional para preparo e circulação.
- Compilação Godot 4.7.2: **PASS**. Capturas: **13 vistas 1280 × 720** em `qa/evidence/kitchen_c11_*.png`; script: `qa/capture_kitchen_c11.gd`.
- Auditorias C11: **3 camadas de lanterna**, **0 luzes interiores**, **0 materiais emissivos**; forno procedural presente e forno Tripo ausente da cena ativa. Logs em `qa/kitchen_c11_compile.log` e `qa/kitchen_c11_capture.log`.
- Jogabilidade: **38/38 waypoints PASS** e porta abre/fecha com **E** (`qa/kitchen_c11_routes.log`, `qa/kitchen_c11_key_e.log`).
- A C10 permanece preservada como checkpoint não aprovado. A C11 está tecnicamente validada, mas **não está aprovada visualmente por Richard**; o pacote de revisão está em `qa/evidence/kitchen_c11_review_pack.zip`.


## Cozinha — atualização C12 (checkpoint provisório; revisão visual pendente)

- **Vintage Microwave** (Poly Haven, autor Adam Nekola), modelo glTF 1K CC0, integrado ao nicho superior da torre a escala 0,55 e rotação 270°. Bounds antes de escala medidos no Godot: **1,074 × 0,526 × 0,746 m**; aproximadamente 8 mil triângulos segundo a página oficial. A configuração local mantém o aparelho apagado e sem emissão. Origem: https://polyhaven.com/a/vintage_microwave.
- **Tea Set 01** (CC0, glTF 1K), **Jug 01**, **Carved Wooden Plate** (três pratos empilhados) e **Wooden Bowl 02** (CC0, glTF 1K) integrados em agrupamentos nas prateleiras abertas. Bounds medidos antes de escala no Godot: tea set **0,918 × 0,165 × 0,484 m**; jarro **0,275 × 0,211 × 0,168 m**; prato **0,272 × 0,038 × 0,269 m**; bowl **0,131 × 0,073 × 0,125 m**. Fontes oficiais: https://polyhaven.com/a/tea_set_01, https://polyhaven.com/a/jug_01, https://polyhaven.com/a/carved_wooden_plate e https://polyhaven.com/a/wooden_bowl_02. Licença CC0: https://polyhaven.com/license. Arquivos e checksums por mapa/modelo: `prototype/assets/models/polyhaven_c2_manifest.json`.
- A cor da bancada usa `Marble002_Kitchen_Color_2K.jpg`, derivação tonal local do mapa de cor CC0 `Marble002_Color_2K.jpg`; o original foi preservado e os mapas normal/roughness/AO continuam originais. A fonte, fórmula de transformação e hashes estão em `qa/c12_asset_research_sources.md`. Origem: https://ambientcg.com/view?id=Marble002 (CC0 1.0).
- A ilha mantém o tampo de nogueira; pedra, ilha, estação de café e prateleiras recebem agrupamentos funcionais sem alterar o volume estrutural ou a circulação. A panela do cooktop é geometria procedural fosca e sem chama; `Electric Stove` foi sondado apenas para bounds e não foi integrado.
- Gate C12: Godot 4.7.2 **PASS**, build `0d5b4f970e9299d6be161a04dc53178ded0c6f555a2c6e3c0fb18aac854dae7b`; **15 capturas**, **3 camadas de lanterna**, **0 luzes interiores**, **0 superfícies emissivas ativas** acima de 0,001, rota **38/38**, tecla **E PASS**, bounds **6/6** e apoio **AABB PASS**. O relatório, manifesto e limites estão em `qa/KITCHEN_C12_REVIEW.md` e `qa/kitchen_c12_validation_manifest.json`.
- C12 continua **pendente de revisão visual**. O forno Tripo permanece fora da cena e em quarentena; os termos do plano de geração não foram confirmados e não se declara liberação comercial. A execução de captura em Xvfb/llvmpipe emite somente aviso não bloqueante de V-Sync do driver virtual.


## C13 — Sala de jantar (17/10/2026)

Todos os modelos externos desta composição vêm das páginas oficiais Poly Haven e estão sob CC0; os autores são registrados por rastreabilidade. Os detalhes, bounds e fontes completas ficam em [`qa/c13_asset_research_sources.md`](../../qa/c13_asset_research_sources.md).

| Asset | Autor | Uso C13 | Licença |
|---|---|---|---|
| `dining_table` | Aron Łyczek | Mesa principal; malha de toalha do modelo oculta | [CC0](https://polyhaven.com/a/dining_table) |
| `dining_chair_02` | James Ray Cock | Seis cadeiras; quatro lugares usados e duas cadeiras extras | [CC0](https://polyhaven.com/a/dining_chair_02) |
| `Chandelier_03` | Kirill Sannikov | Lustre ornamental, apagado e sem nós de luz | [CC0](https://polyhaven.com/a/Chandelier_03) |
| `tea_set_01` | James Ray Cock, Rico Cilliers e Jurita Burger | Centro de mesa | [CC0](https://polyhaven.com/a/tea_set_01) |
| `modern_wooden_cabinet` | Patrik Pangerl | Aparador periférico | [CC0](https://polyhaven.com/a/modern_wooden_cabinet) |
| `ceramic_vase_02` | James Ray Cock | Vaso no aparador | [CC0](https://polyhaven.com/a/ceramic_vase_02) |
| `hanging_picture_frame_02` | James Ray Cock | Um quadro ampliado acima do aparador; a tela reaproveita a textura CC0 incluída no mesmo modelo | [CC0](https://polyhaven.com/a/hanging_picture_frame_02) |
| `vintage_oil_lamp` | Monsta3D | Prop apagado no aparador; emissão da malha da chama desligada em runtime | [CC0](https://polyhaven.com/a/vintage_oil_lamp) |
| `planter_pot_clay` | Amal Kumar | Vaso de piso | [CC0](https://polyhaven.com/a/planter_pot_clay) |
| `fern_02` | Rob Tuytel e Rico Cilliers | Folhagem para a composição de piso | [CC0](https://polyhaven.com/a/fern_02) |
| `Carpet012` | AmbientCG | Mapas Color/NormalGL/Roughness/AO em 2K no tapete C13 | [CC0 1.0](https://ambientcg.com/view?id=Carpet012) |

As dimensões medidas dos principais modelos estão no relatório de fontes C13. Quatro pratos e aros, uma caneca/copo pequeno e um guardanapo dobrado são geometria procedural própria; o material cerâmico não é emissivo. O tapete usa material PBR exclusivo `dining_rug`; nenhuma outra sala teve o material de tapete alterado. Não foi integrado modelo gerado por IA na sala C13; o forno Tripo da cozinha permanece em quarentena, sem declaração de liberação comercial.


## C14 — Biblioteca (checkpoint provisório; revisão visual pendente)

| Asset | Uso na biblioteca | Fonte e licença |
|---|---|---|
| `filled-bookshelf-large-original-interior-furnishing.glb` | Cinco estantes cheias, distribuídas em duas paredes | [Innerscene](https://www.innerscene.com/tools/library/3d-parts/filled-bookshelf-large-original-interior-furnishing-584afc77), CC0; SHA-256 `ed18fd3a2aed3fac8d2d4fa5932e6dc4ccc451b5967e68ced24eb092ec372e47` |
| `ArmChair_01` | Duas poltronas do canto de leitura | [Poly Haven](https://polyhaven.com/a/ArmChair_01), CC0 |
| `coffee_table_round_01` | Mesa circular de leitura com conjunto de livros | [Poly Haven](https://polyhaven.com/a/coffee_table_round_01), CC0; também documentada na seção “Mesa da biblioteca” acima |
| `book_encyclopedia_set_01` | Livros agrupados sobre a mesa central | [Poly Haven](https://polyhaven.com/a/book_encyclopedia_set_01), CC0 |
| `small_wooden_table_01` e `vintage_oil_lamp` | Mesa lateral e lamparina decorativa, ambas apagadas | [Mesa](https://polyhaven.com/a/small_wooden_table_01) e [lamparina](https://polyhaven.com/a/vintage_oil_lamp), CC0 |
| `hanging_picture_frame_02` | Quadros de parede; a arte paisagística reutiliza a textura incluída no próprio asset | [Poly Haven](https://polyhaven.com/a/hanging_picture_frame_02), CC0 |
| `planter_pot_clay` e `fern_02` | Planta de piso junto ao perímetro | [Vaso](https://polyhaven.com/a/planter_pot_clay) e [samambaia](https://polyhaven.com/a/fern_02), CC0 |
| `Carpet012` | Tapete da área de leitura com mapas PBR dedicados | [AmbientCG](https://ambientcg.com/view?id=Carpet012), CC0 1.0; mapas e checksums em `prototype/assets/textures/ambientcg/Carpet012/ambientcg_c3_manifest.json` |

Os manifestos locais de modelos, caminhos e hashes estão em `prototype/assets/models/innerscene/innerscene_c2_manifest.json` e `prototype/assets/models/polyhaven_c2_manifest.json`. Os materiais de madeira, tecido e tapete recebem ajustes locais no código; não há mudança de exposição global. A lamparina permanece sem luz ativa e sem emissão. Uma manta CC0 foi testada durante a composição, mas removida antes do checkpoint final por parecer uma placa rígida sobre a poltrona; ela não está instanciada na C14. Não há modelos gerados por IA na biblioteca.

A auditoria runtime C14 verifica as superfícies carregadas e os nós de luz ativos; não inspeciona flags de importação do arquivo-fonte. A cena pode conter nós Light3D inativos, todos ocultos pela rotina global de desligamento; nenhum é contabilizado como fonte acesa.


## C15 — Escritório (checkpoint provisório; revisão visual pendente)

A composição combina uma estação de trabalho residencial, uma estante cheia, um aparador, planta e quadro; a sala permanece limpa, como recém-mudada. Na retomada após C16, mesa, cadeira giratória, apoio de escrita e três livros são geometria autoral feita no Blender para o projeto; os demais modelos e mapas PBR indicados abaixo são CC0. A luminária de mesa é apenas um prop desligado; não há emissão interna nem novos nós de luz ativos.

| Asset | Uso no escritório | Fonte e licença |
|---|---|---|
| `custom/c15/c15_furniture_original.glb` | Mesa com gaveta, cadeira giratória de cinco raios, apoio de escrita e três livros | Geometria original do projeto, criada em Blender; **não declarada CC0 de terceiros**. Fonte editável `.blend`, geradores `qa/build_c15_blender.py` e `qa/blender_c15_office_chair.py`, procedência em `c15_original_manifest.json` |
| `Wood026` | Albedo, roughness e normal da mesa autoral | [AmbientCG](https://ambientcg.com/a/Wood026), CC0 1.0; três mapas 2K e hashes do manifesto local |
| `desk_lamp_arm_01` | Luminária articulada de mesa, sem fonte de luz ou emissão | [Poly Haven](https://polyhaven.com/a/desk_lamp_arm_01), CC0; Kuutti Siitonen (modelagem/texturas) e Yann Kervran (rigging) |
| `classic_laptop` | Laptop sobre o tampo, tela escura | [Poly Haven](https://polyhaven.com/a/classic_laptop), CC0; Arrangemonk |
| `filled-bookshelf-large-original-interior-furnishing.glb` | Estante cheia junto à parede leste | [Innerscene](https://www.innerscene.com/tools/library/3d-parts/filled-bookshelf-large-original-interior-furnishing-584afc77), CC0; SHA-256 `ed18fd3a2aed3fac8d2d4fa5932e6dc4ccc451b5967e68ced24eb092ec372e47` |
| `modern_wooden_cabinet` | Aparador periférico; modelo também registrado na C13 | [Poly Haven](https://polyhaven.com/a/modern_wooden_cabinet), CC0; Patrik Pangerl |
| `potted_plant_02` | Planta em vaso integrado, apoiada no aparador fora do vão de entrada; contato com o tampo verificado | [Poly Haven](https://polyhaven.com/a/potted_plant_02), CC0; Rico Cilliers |
| `hanging_picture_frame_02` e sua textura de arte | Quadro com paisagem; a imagem usa a textura CC0 incluída no próprio modelo | [Poly Haven](https://polyhaven.com/a/hanging_picture_frame_02), CC0; James Ray Cock |
| `Carpet012` | Tapete PBR sob a estação de trabalho; material local exclusivo C15 | [AmbientCG](https://ambientcg.com/view?id=Carpet012), CC0 1.0; os quatro mapas e hashes estão no manifesto AmbientCG local |

Os modelos de terceiros são conferidos por SHA-256 contra os manifestos Poly Haven, Innerscene e AmbientCG. Para os dois modelos Poly Haven que não constam no manifesto C2, `qa/office_c15_asset_manifest.json` registra cada arquivo e hash. A auditoria da retomada é `qa/c15_resumed_asset_audit.py`, com log `qa/office_c15_resumed_asset_audit.log`. O antigo conjunto Innerscene `desk-with-chair-original-hotel-furnishing.glb` continua registrado no acervo CC0, mas **não está integrado no escritório retomado**. A trama oatmeal autoral existente foi reutilizada sem gerar nova imagem. Nenhum asset Tripo ou outra peça de licença não confirmada foi acrescentado à composição C15. As escolhas visuais permanecem provisórias, aguardando revisão de Richard.

## C16 — kitchen004 fornecido por Richard (provisório)

`custom/kitchen004/source/kitchen004.glb` é uma cópia exata de `/home/ubuntu/upload/kitchen004.glb`, fornecida por Richard. SHA-256 original: `9225794d7b8565311bbd65b01e52b01053e03591d7bf66e83f06013209b03ac0`. O glTF registra somente o exportador Khronos glTF Blender I/O v5.0.21; não contém autor, licença, copyright ou URL de origem. **Autoria e termos desconhecidos; não classificado como CC0/CC BY nem comercialmente liberado.** A verificação de direitos inclui as sete imagens embutidas e permanece pendente antes de distribuição/comercialização.

`kitchen004_unlit.glb` é uma derivação técnica local reproduzível por `qa/prepare_kitchen004.py`: emissão removida de todos os materiais e displays/faixas luminosas desligados. O upload e a cópia bruta não são alterados. Ajustes de encaixe e materiais na cena, quando realizados, não modificam o status de licença. Metadados e hashes: `qa/kitchen004_source_manifest.json`. Durante C16 o escritório permaneceu pausado; foi retomado somente após a correção do arremate e a gate final da cozinha.

### Derivação efetivamente integrada na C16

A cena carrega **somente** `custom/kitchen004/kitchen004_fitted.glb`. O original e o intermediário sem emissão estão arquivados em `custom/kitchen004/source/`, com `.gdignore`. O Blender foi usado para remover quatro módulos superiores que cobriam a janela, retirar a coifa/detalhes que também interferiam no vão e um marcador degenerado, reposicionar rigidamente a ilha já existente no GLB, rebaixar o espelho da bancada e adequar os armários altos ao teto. Não foi criado um novo conjunto de cozinha do zero.

A paleta foi ajustada para grafite quase preto, torre marrom com Wood026 e pedra escura com Marble002. Wood026 e Marble002 são texturas AmbientCG CC0 já registradas neste projeto; suas fontes são https://ambientcg.com/a/Wood026 e https://ambientcg.com/a/Marble002. Os demais mapas embutidos no GLB continuam com direitos desconhecidos. Vidros dos eletrodomésticos foram adaptados para uma leitura escura/apagada no renderer Compatibility. Emissões seguem desativadas.

Scripts de edição: `qa/prepare_kitchen004.py`, `qa/fit_kitchen004.py`, `qa/finalize_kitchen004_glb.py`; manifesto de edição/hashes: `qa/kitchen004_fit_manifest.json`. **A edição não transforma este modelo em obra livre: original e derivados continuam bloqueados para distribuição comercial até comprovação dos termos.** Nenhum build distribuível foi preparado nesta fase; o pacote de revisão contém capturas, relatório e evidências, não o jogo ou o GLB.

## C17 — Área de serviço e conexão imediata com o porão

A bancada contínua, gabinete com tanque oco e dreno, torneira curva, aéreos, cesto com toalhas, frascos neutros e sabonete são **geometria original criada no Blender para este projeto**; não são apresentados como modelos CC0 de terceiros. Gerador: `qa/build_service_c17_blender.py`; GLB: `custom/c17/c17_laundry_service_original.glb`; fonte editável: `custom/c17/source/c17_laundry_service_original.blend`, isolada da importação por `.gdignore`. Direitos e hashes dos mapas e medidas constam em `custom/c17/c17_geometry_manifest.json`.

A marcenaria reutiliza os mapas 2K de **Wood026**, AmbientCG CC0 1.0, já registrados acima. Piso e pequeno acabamento local de parede reutilizam **Brown Floor Tiles** e **Beige Wall 001** da Poly Haven, CC0; não houve novo download de texturas. As fontes e hashes continuam em `textures/polyhaven/c2_pbr_textures_2k_manifest.json`. O aro, guarda-corpo e corrimãos são geometria procedural própria criada no Godot.

Lavadora `washer-dryer.glb` e secadora `tumble-dryer.glb` são os modelos **Innerscene CC0** da tabela deste documento; as páginas oficiais foram consultadas e declaram uso, modificação e redistribuição inclusive comercial. Reutilizam-se também o banco `painted_wooden_bench` e quadro `hanging_picture_frame_02`, ambos Poly Haven CC0, já registrados no acervo local. Os ajustes de esmalte, metal e displays são materiais duplicados somente nas duas instâncias C17: aparelhos do porão e outros cômodos não são alterados. Displays permanecem escuros e toda emissão interna fica desativada.

A auditoria C17 mantém separadas a geometria própria e as texturas/modelos CC0. Nenhum modelo Tripo ou outro asset de licença não comprovada foi acrescentado à área de serviço. **O `kitchen004` permanece apenas no protótipo C2, com direitos desconhecidos; o pacote de revisão C17 não deve conter esse GLB nem um build distribuível da casa.**

## C18 — área de serviço em L e penumbra da lanterna

`custom/c18/c18_laundry_service_original.glb`: geometria original do projeto, gerada por código no Blender; não declarada como CC0 de terceiros. Fonte editável em `custom/c18/source/c18_laundry_service_original.blend`, gerador em `qa/build_service_c18_blender.py` e medidas reais em `custom/c18/c18_geometry_manifest.json`. Inclui retorno com cubículos abertos, aéreos, tanque oco/torneira, escorredor, cesta, produtos sem marcas, aspirador e balde oco. Nenhum modelo Tripo ou fonte externa não verificada foi acrescentado.

Mapas Wood026: [AmbientCG](https://ambientcg.com/a/Wood026), CC0 1.0, origem e hashes no manifesto. O albedo de madeira clara é um derivado determinístico com preservação dos veios, reproduzível por `qa/prepare_service_c18_textures.py`. Roughness e NormalGL foram copiados sem alteração. Os três mapas ficam em `custom/c18/textures/`; a autoria da malha não se confunde com a licença CC0 dos mapas.

Lavadora/secadora Innerscene, banco/quadro e materiais Poly Haven já integrados permanecem os registrados em C17. C18 substitui apenas o conjunto autoral C17 na cena; seus arquivos antigos continuam como checkpoint histórico. A referência de Richard é referência visual, não textura incorporada. O shader `haunted_film_grain_c18.gdshader` é código original do projeto: acrescenta penumbra angular vinculada à lanterna e não cria luz ou emissão.

O GLB `kitchen004` continua com licença desconhecida, exclusivamente provisório no protótipo; esta revisão não o libera para distribuição. C18 permanece pendente de revisão visual de Richard.

## C19 — hall/entrada familiar

`custom/c19/c19_hall_entry_original.glb`: geometria original do projeto, criada por código no Blender; **não declarada CC0 de terceiros**. Fonte editável em `custom/c19/source/c19_hall_entry_original.blend`, gerador `qa/build_hall_c19_blender.py`, medidas, grupos e hashes em `custom/c19/c19_geometry_manifest.json`. Inclui console, bandeja/chaves, caixa de mudança fechada, banco, sapatos, ganchos e um casaco. O conjunto refinado tem 14.864 triângulos e 9 meshes na exportação; a gate C19 também mede as malhas carregadas no Godot.

Madeira: [Wood026, AmbientCG](https://ambientcg.com/view?id=Wood026), CC0 1.0, mapas já existentes reutilizados sem alterar os originais. Capacho: Carpet012 CC0 já registrado acima, com tonalidade local de material. Os detalhes da folha frontal e da fechadura são geometria procedural própria, filhos da mesma porta interativa. Nenhuma luz interior ou emissão foi criada; o shader e os controles C18 foram preservados.

C19 é uma prévia para Helena/Richard, sem aceitação visual antecipada. A aceitação provisória de C18 foi dada por Richard antes desta etapa. A licença desconhecida de `kitchen004` permanece bloqueando sua distribuição; este passe não modifica essa condição.


## Entrega single-player — filtro de distribuição (2026-10-30)

- Como a autoria e os termos de `kitchen004` não foram comprovados, a branch desta entrega remove o GLB original, os GLBs/texturas derivados e os meshes/materiais C16 sem outros usos. A nota `custom/kitchen004/DISTRIBUTION_BLOCKED.md` permanece como registro; `qa/whole_house/kitchen_baseline_snapshot.json` guarda apenas nomes, transforms e bounds para comparação estrutural, não os dados de geometria.
- A cena da cozinha ativa foi reconstruída com meshes primitivos autorais do Godot e materiais com proveniência documentada. Os props Poly Haven CC0 usados em outras cenas permanecem com os glTFs e checksums de origem presentes no manifesto local.
- O forno gerado por Tripo continua fora do projeto ativo e sem liberação de direitos; nenhum arquivo dele integra esta branch.
