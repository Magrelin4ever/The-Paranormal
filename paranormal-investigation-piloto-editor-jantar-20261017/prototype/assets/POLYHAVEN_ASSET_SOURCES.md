# Registro de fontes Poly Haven — candidata C1

Todos os materiais e modelos abaixo vêm das páginas oficiais Poly Haven e estão sob [CC0](https://polyhaven.com/license), confirmada em 16/10/2026. A atribuição não é exigida; registramos fontes e, quando disponíveis, autores e hashes para rastreabilidade. Mapas PBR e texturas de modelos foram baixados em 1K para o perfil Compatibility/OpenGL e GPU integrada.

## Modelos glTF 1K usados no térreo

Há **11 modelos únicos** e **26 instâncias colocadas** na cena C1, conforme a sonda estrutural. Os arquivos glTF, dependências e hashes estão discriminados em [`models/POLYHAVEN_ASSET_SOURCES.md`](models/POLYHAVEN_ASSET_SOURCES.md).

| Modelo | Uso principal | Fonte oficial |
|---|---|---|
| `sofa_02` | sala familiar e estar separado | [Poly Haven](https://polyhaven.com/a/sofa_02) |
| `dining_table` | jantar | [Poly Haven](https://polyhaven.com/a/dining_table) |
| `dining_chair_02` | jantar e cadeira do escritório | [Poly Haven](https://polyhaven.com/a/dining_chair_02) |
| `modern_arm_chair_01` | sala familiar e biblioteca | [Poly Haven](https://polyhaven.com/a/modern_arm_chair_01) |
| `modern_wooden_cabinet` | sala, cozinha, despensa e mudroom | [Poly Haven](https://polyhaven.com/a/modern_wooden_cabinet) |
| `Shelf_01` | biblioteca e escritório | [Poly Haven](https://polyhaven.com/a/Shelf_01) |
| `desk_lamp_arm_01` | escritório | [Poly Haven](https://polyhaven.com/a/desk_lamp_arm_01) |
| `modern_coffee_table_01` | sala familiar, biblioteca e estar | [Poly Haven](https://polyhaven.com/a/modern_coffee_table_01) |
| `Television_01` | sala familiar | [Poly Haven](https://polyhaven.com/a/Television_01) |
| `metal_office_desk` | escritório | [Poly Haven](https://polyhaven.com/a/metal_office_desk) |
| `electric_stove` | cozinha; autor Kuutti Siitonen | [Poly Haven](https://polyhaven.com/a/electric_stove) |

## Materiais PBR CC0 da estrutura

Todos os mapas abaixo são JPEG 1K. O código usa os conjuntos em pisos/parede e no porão, reduzindo a dependência de cores chapadas.

**Atualização C2:** os mapas 1K abaixo registram a importação original. O build atual prefere mapas JPEG 2K de difuso, normal OpenGL, roughness e AO para os quatro materiais estruturais; os URLs e SHA-256 dos arquivos ativos estão em `prototype/assets/textures/polyhaven/c2_pbr_textures_2k_manifest.json`. O projeto mantém o UV atual e não altera a geometria de paredes/pisos.

### wood_floor — piso de madeira
Origem: [wood_floor](https://polyhaven.com/a/wood_floor), autor Dimitrios Savva.
- `wood_floor_diff_1k.jpg` — SHA-256 `2a1c07687b6dbb214c4b9213739c6d92d425f1f0fc8ab3ac157f105d78240789`
- `wood_floor_nor_gl_1k.jpg` — SHA-256 `452247f0d0d1b7fc7f8324ff3b6ed60bcc6de1405f4284eeb8d9bce90d4939c2`
- `wood_floor_rough_1k.jpg` — SHA-256 `061f1e1293251b2d28c76e3fac1ea9452b0e8648bb8f9b3728e09db386166e5c`

### brown_floor_tiles — ladrilho da cozinha/serviço
Origem: [brown_floor_tiles](https://polyhaven.com/a/brown_floor_tiles).
- `brown_floor_tiles_diff_1k.jpg` — SHA-256 `64a5e4af8521883fb82a2e17971f785bfedcbb55bc14fa2d339bc806cbea61b6`
- `brown_floor_tiles_nor_gl_1k.jpg` — SHA-256 `d492f802a76c6335dfbed96a1089c88c0143783d19bd9a660cae36b9967f1f4d`
- `brown_floor_tiles_rough_1k.jpg` — SHA-256 `5824c9c38c8c863b6ce8d58b114c43a33bf7e789020bb55567f526692ace65a0`

### beige_wall_001 — paredes pintadas neutras
Origem: [beige_wall_001](https://polyhaven.com/a/beige_wall_001), fotografia de Dimitrios Savva e processamento de Rico Cilliers.
- `beige_wall_001_diff_1k.jpg` — SHA-256 `72104704d0b9bd3713c5f6238971252b63eccf6e61263059c674caa8f3d0fa6d`
- `beige_wall_001_nor_gl_1k.jpg` — SHA-256 `cec747be50f91da0693986080b6f59ef868d53cb2ab7d577982165ece63ed75e`
- `beige_wall_001_rough_1k.jpg` — SHA-256 `fc8328f47f4d2d82d5311a75bcb5c8cd8979d171a0ee097ad9e44ca9c5a00d60`

### concrete_floor_01 — concreto do porão
Origem: [concrete_floor_01](https://polyhaven.com/a/concrete_floor_01), autor Rob Tuytel.
- `concrete_floor_01_diff_1k.jpg` — SHA-256 `db7c800f1464359b5f359fc743e82ac51b34e014fdfd53844f4af34bb1949229`
- `concrete_floor_01_nor_gl_1k.jpg` — SHA-256 `28be1f6fa82eeab137c84954bf7ea0f5d8a4434352d01c29f15e20926eb7227e`
- `concrete_floor_01_rough_1k.jpg` — SHA-256 `f5239e1c6db5f0ddb4c2397e881a5938ab511386aab19a23c20d40f4ab2c181b`

## Observação visual

O `electric_stove` tem marcas de uso mais evidentes que os demais móveis. A licença permite substituição, edição ou retexturização; reavaliar a peça caso o acabamento final exija uma cozinha mais nova e bem cuidada.
