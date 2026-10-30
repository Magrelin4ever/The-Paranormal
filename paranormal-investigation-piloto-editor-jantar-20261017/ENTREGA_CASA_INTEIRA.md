# The Paranormal — resultado da rodada

**Projeto:** Godot 4.7.2, GDScript, Linux, renderer Compatibility/OpenGL. A cena de entrada é `game/main_menu.tscn`; abra `project.godot` no Godot e pressione **F5** para jogar. Os controles e o ciclo de campanha estão em [`JOGAR_E_CONTROLES.md`](JOGAR_E_CONTROLES.md). Esta branch entrega o **projeto-fonte jogável**, não um executável Linux independente: neste ambiente só há templates de exportação Web e não há preset/template nativo Linux.

## O que está pronto

O jogo é single-player, sem multiplayer. Inclui menu Start/Options/Controls/Exit, QG com computador de casos e notícias ficcionais, contato com a família, compra/equipamento de instrumentos, três ocorrências, quatro categorias obrigatórias de evidência por caso, pistas opcionais, manifestações variáveis, perseguição, fuga/abrigos, extração, relatório parcial/completo e salvamento local de progresso.

A residência está em [`prototype/whole_house/casa_editavel.tscn`](prototype/whole_house/casa_editavel.tscn), com 40 cenas de cômodos e exterior distribuídas em quatro níveis. Móveis, meshes e colisões são persistentes/editáveis no editor. O runtime da campanha usa essa mesma composição salva por meio de `prototype/house_environment.tscn`. Evite executar os construtores históricos de bake/build/refine/finalize/polish: eles podem sobrescrever cenas atuais.

## Cozinha e licenças

A cozinha C16 anterior tinha 81 meshes e 17 colisores, mas sua autoria/termos de redistribuição não eram comprováveis. O GLB e os derivados exclusivos foram removidos; o snapshot de baseline conserva somente metadados estruturais, sem geometria, e a nota de bloqueio permanece em `prototype/assets/models/custom/kitchen004/DISTRIBUTION_BLOCKED.md`.

A substituição é uma cozinha modular autoral com 102 meshes, 6 colisores e nenhum asset externo de licença desconhecida. Os bounds passaram de 7,45 × 2,466 × 5,20 m para 7,42 × 2,50 × 5,04 m, preservando cerca de **96,5% da área de footprint**. Na auditoria física atual, **100% das células livres amostradas** estão na mesma componente acessível, as duas saídas passam e não há exceção de layout. A geometria não é uma réplica mesh-a-mesh nem uma equivalência visual 1:1; essa limitação é intencional para não redistribuir o asset bloqueado.

## Evidências de QA

| Área | Resultado verificado |
|---|---|
| Projeto e assets | Parse/import Godot passou; gate estático passou com zero assets bloqueados nas cenas ativas; auditoria de referências visitou 9.456 recursos sem dependências ausentes. |
| Cenas e edição | 40 cenas; 8.737 meshes, 535 corpos e 563 formas de colisão; zero falha de carga/geometria, zero dependência ausente e zero nó sem owner salvo. |
| Persistência | 58/58 verificações passaram, incluindo salvar/reabrir alterações e carregá-las no jogo. |
| Circulação | 22 áreas passaram; cozinha com conectividade integral das células livres. 61/61 marcadores foram alcançados pelo jogador real, com distância final máxima de 0,059 m; o teste é contínuo por cômodo, com um posicionamento inicial em cada um dos 22 cômodos. |
| Escadas e portas | 6/6 rotas de escada passaram com o CharacterBody3D; 28/28 portas abriram e fecharam pela tecla E real. |
| Iluminação | 9 verificações passaram; na captura 960×540, 291.979 pixels (63,4%) ficaram mais claros com a lanterna ligada, nenhum pixel desligado ficou mais claro, e a luminância média foi 0,133 ligada contra 0,096 desligada. Luzes/emissões internas desligadas. |
| Campanha | Fluxo automatizado passou nos 3 casos, ferramentas e 4 categorias; 15/15 pistas têm linha de visão; saída parcial e relatório final foram exercitados. |
| Assets editáveis | Quatro cenários de asset instanciado/editável salvaram e reabriram com os resultados esperados. O editor headless registrou avisos de recursos liberados no encerramento, mas o JSON do teste não tem falhas. |
| Vista do editor | O botão de enquadramento e captura passou em Compatibility/OpenGL via llvmpipe; a câmera adapta a distância à proporção do viewport e a captura mostra a casa e o exterior completos em perspectiva, não um corte dos interiores. O viewport de QA (926×4895) deixa espaço vazio acima/abaixo; em uma viewport normal, o enquadramento adapta-se à sua proporção. |

Relatórios e scripts estão em `qa/whole_house/` e `qa/gameplay/`. O guia repetível e os limites de cada validação estão em [`qa/whole_house/README.md`](qa/whole_house/README.md).

## Limites ainda não validados

- Não foi feito perfil de desempenho em GPU integrada física; as validações gráficas ocorreram em Mesa/llvmpipe.
- Os 61 marcadores foram percorridos em cada cômodo, mas não há uma única rota ininterrupta que atravesse todos os cômodos; as escadas foram exercitadas em seis rotas separadas.
- Não houve playtest humano de 20–60 minutos nem avaliação auditiva subjetiva da mixagem; o fluxo e a luz foram verificados por testes automatizados.
- Com a lanterna desligada, estantes e silhuetas continuam reconhecíveis, mas o tapete, a porta e partes da poltrona ainda têm sombras profundas; a legibilidade sem lanterna é baixa, conforme revisão visual.
- O gate confirma ausência de assets explicitamente bloqueados nas cenas ativas; os manifestos registram as fontes, mas esta rodada não substitui uma revisão jurídica nova de cada arquivo externo do repositório.
- Não há executável Linux standalone nesta entrega; é preciso abrir o projeto no Godot 4.7.2 e executar com F5.
- A aprovação humana formal de Helena não está registrada nos artefatos desta rodada; os resultados acima são a evidência técnica disponível, não substituem essa assinatura.

Consulte também [`GUIA_EDICAO_CASA_INTEIRA.md`](GUIA_EDICAO_CASA_INTEIRA.md) e o manifesto [`prototype/assets/ASSET_LICENSES_C2.md`](prototype/assets/ASSET_LICENSES_C2.md) para editar a residência e revisar a proveniência dos assets.
