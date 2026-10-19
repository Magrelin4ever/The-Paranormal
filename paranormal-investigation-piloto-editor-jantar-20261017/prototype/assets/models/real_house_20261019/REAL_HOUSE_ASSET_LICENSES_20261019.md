# Modelos da casa — licença e escala

Os modelos desta pasta vieram da biblioteca oficial Innerscene, que declara **domínio público CC0**, permitindo uso, modificação e redistribuição, inclusive comercial. Os links abaixo são as páginas oficiais; a escala é em metros e a base dos objetos corresponde ao piso. Texturas extraídas pelo importador também pertencem aos modelos.

| Arquivo | Fonte oficial | Largura × profundidade × altura |
|---|---|---|
| `hush_wingback_bed.glb` | [HUSH — Wingback Bed](https://www.innerscene.com/tools/library/3d-parts/hush-wingback-bed-788f5be3) | 1,82 × 2,26 × 1,46 m |
| `studio_loft_study_bed.glb` | [STUDIO — Loft Study Bed](https://www.innerscene.com/tools/library/3d-parts/studio-loft-study-bed-a38f43d7) | 1,14 × 2,41 × 2,04 m |
| `double_bed_bedding.glb` | [Double bed with bedding](https://www.innerscene.com/tools/library/3d-parts/double-bed-with-bedding-original-interior-furnishing-2a680f49) | 1,53 × 2,06 × 1,27 m |
| `single_bed_bedding.glb` | [Single bed with bedding](https://www.innerscene.com/tools/library/3d-parts/single-bed-with-bedding-original-interior-furnishing-6cc48cf8) | 1,08 × 2,06 × 1,27 m |
| `bathroom_vanity.glb` | [BASIN 90](https://www.innerscene.com/tools/library/3d-parts/basin-90-freestanding-bathroom-vanity-c58c9ba0) | 0,94 × 0,56 × 1,17 m |
| `utility_laundry_tub.glb` | [Utility Laundry Tub](https://www.innerscene.com/tools/library/3d-parts/laundry-tub-utility-laundry-tub-49064dac) | 0,638 × 0,575 × 1,11 m |
| `profile_six_drawer_dresser.glb` | [PROFILE 140](https://www.innerscene.com/tools/library/3d-parts/profile-140-six-drawer-dresser-6721514a) | 1,42 × 0,55 × 0,85 m |

Licença: [termos Innerscene](https://www.innerscene.com/tools/library/terms) e [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/).

## Cenas efetivamente usadas

A versão final usa **HUSH** na suíte e duas **STUDIO** no quarto infantil. As camas simples de bedding continuam disponíveis como fontes alternativas; não confundir os modelos alternativos com os wrappers finais.

As raízes das cenas reutilizáveis em `prototype/whole_house/real_assets/` ficam em `(0,0,0)`, com base no piso e centro X/Z corrigido. As colisões são filhas da raiz. Os AABBs medidos no Godot 4.7.2 são:

| Cena | Largura × altura × profundidade |
|---|---|
| `Cama_Casal_Hush.tscn` | 1,820808 × 1,464500 × 2,264500 m |
| `Cama_Infantil_Loft_Studio.tscn` | 1,139000 × 2,041000 × 2,406826 m |
| `Tanque_Utility_Laundry.tscn` | 0,638000 × 1,105184 × 0,574500 m |
| `Pia_Banheiro_Basin90.tscn` | 0,936000 × 1,166005 × 0,561000 m |
| `Comoda_Profile_140.tscn` | 1,420000 × 0,846000 × 0,549000 m |

O tanque é um **tanque de lavanderia**, não uma banheira. Os banheiros usam os modelos sanitários em `prototype/assets/models/bathroom_20261019/`, com seu próprio manifesto de fontes e hashes.

A biblioteca também contém wrappers de cortina Innerscene e de mesas, plantas, luminárias apagadas, livros e cestos Poly Haven já presentes no projeto. Seus créditos continuam em `prototype/assets/ASSET_LICENSES_C2.md` e `prototype/assets/models/POLYHAVEN_ASSET_SOURCES.md`. Nenhuma luz interna ou emissão foi adicionada pelos wrappers finais.
