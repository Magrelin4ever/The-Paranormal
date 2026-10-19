# Guia de edição — casa inteira (Godot 4.7.2 Linux Compatibility)

## Abrir e orientar-se

1. Abra o projeto `project.godot` no Godot **4.7.2 — Linux Compatibility**.
2. Para editar, abra `prototype/whole_house/casa_editavel.tscn` (casa completa) ou uma cena de cômodo em `prototype/whole_house/rooms/`.
3. A cena principal é `prototype/house_environment.tscn`: ela instancia a casa editável e o jogador. Portanto, **F5** inicia o jogo principal com as mesmas cenas salvas; a casa não é regenerada proceduralmente.
4. **F6** executa apenas a cena atualmente aberta. Uma cena de cômodo isolada não tem o player; use-a para edição/inspeção, não como teste de gameplay.

Na primeira abertura após clonar, aguarde a indexação dos recursos. Para trabalhar com menos nós na tela, prefira abrir a cena do cômodo desejado: as mudanças também aparecem na casa completa e no F5. Se a primeira varredura ficar lenta com a casa aberta, feche o editor e faça a importação sem viewport, no terminal da pasta do projeto: `godot --headless --editor --path . --import` (use o nome/caminho do seu executável Godot 4.7.2). Depois reabra o editor normalmente. Isso não reconstrói nem altera o layout salvo.

Na árvore, expanda as setas para acessar os filhos. Em `casa_editavel.tscn`, organize mentalmente por raiz: `Porao`, `Terreo`, `Primeiro_Andar`, `Sotao_Segundo_Andar` e `Exterior`. Dentro deles ficam estrutura, pisos/acabamentos, tetos, portas, escadas e os cômodos (por exemplo, `Terreo/Cozinha_Richard`, que deve ser preservada). Não mova uma subpeça interna quando a intenção for mover o móvel inteiro.

## Viewport 3D e filtro de pisos

O plugin **Casa — edição 3D** adiciona a barra no menu do viewport e o painel lateral. Em **Piso**, use `Casa completa`, `Porão`, `Térreo`, `Primeiro andar`, `Sótão / segundo andar` ou `Exterior`. **Tetos** mostra/oculta tetos e cobertura somente no viewport do editor.

O filtro atua somente na prévia de renderização do editor; ele não altera as propriedades salvas `visible`, `layers`, `owner`, as transformações nem o que aparece no jogo. Os bits visuais usados atualmente são: Exterior = camada 1 (bit 0), Porão = camada 2 (bit 1), Térreo = camada 3 (bit 2), Primeiro andar = camada 4 (bit 3), Sótão = camada 5 (bit 4). Tetos usam as camadas seguintes (bits 5–9). O plugin usa esses bits para decidir quais peças mostrar na prévia; a câmera e os gizmos continuam operacionais.

Para trabalhar com cômodos, abra a cena diretamente (por exemplo `terreo__Sala_Jantar.tscn`); o plugin tenta selecionar o piso correspondente pelo nome. Para retornar, use **Restaurar visão completa**.

## Selecionar e transformar objetos

- Selecione a **raiz móvel** (a raiz com `metadata/_edit_group_ = true` quando existir), como uma cama, armário, mesa ou conjunto de louça. Assim o objeto inteiro é manipulado como grupo.
- Atalhos padrão do editor 3D: **W** mover/translate, **E** girar/rotate, **R** escalar/scale, **F** focar a seleção. Use os botões/gizmos se o atalho não estiver ativo. Esses atalhos são do editor; no jogo, W/A/S/D são movimento.
- A colisão que estiver dentro da raiz acompanha a transformação. Depois de mover, confira que o objeto não atravessa piso, parede, porta ou outro móvel.
- **Ctrl+S** salva a cena da aba atual: `casa_editavel.tscn` se você editou a composição inteira, ou a cena do cômodo se abriu o cômodo diretamente. F5 carrega ambas. Evite alternar os dois fluxos para a mesma propriedade: um override feito na casa completa tem prioridade sobre o valor original do cômodo.

Depois de selecionar um móvel na árvore, deixe o teclado focado no viewport: se **F** não enquadrar a seleção, dê um clique com o botão do meio do mouse dentro do viewport, sem arrastar, e pressione **F** novamente. Isso foi confirmado no editor real e não move o asset. A origem de um pavimento não é necessariamente o centro dos móveis; prefira enquadrar a seleção, em vez de navegar só a partir da origem.

## Adicionar assets

No painel do plugin, **Abrir assets prontos** leva a `prototype/whole_house/real_assets/` (cenas `.tscn`). Também é possível arrastar um `.tscn` da biblioteca ou um `.glb` para a árvore/viewport. Prefira inserir com **Casa completa** selecionada e depois configurar o piso correto: um GLB novo normalmente começa na camada 1 e pode sumir quando um piso isolado é filtrado.

Após inserir, renomeie e coloque o nó no cômodo/piso adequado. Selecione a raiz do asset, escolha o pavimento em **Piso** e clique em **Aplicar piso à seleção** no painel **Casa — edição 3D**. Isso ajusta as camadas visuais de todas as malhas do asset, habilita os overrides necessários para os filhos de GLB persistirem ao salvar e agrupa a seleção como um asset; não muda sua posição. **Ctrl+Z** desfaz. Assim você não precisa editar GDScript nem ajustar cada malha manualmente.

Como alternativa, em cada `MeshInstance3D` do asset, no Inspector, marque a camada visual do pavimento: Porão 2, Térreo 3, Primeiro andar 4, Sótão 5 (Exterior 1). São as camadas **1–5** da interface, correspondentes aos bits **0–4**; isso não é a máscara física de colisão.

GLB pode vir sem colisão. Na raiz do objeto, crie `StaticBody3D` e, como filho, `CollisionShape3D` com uma forma adequada; não deixe a colisão como irmão fora da raiz móvel. Para geração nativa, selecione o `MeshInstance3D` e use no menu **Mesh**: **Create Trimesh Static Body** para geometria detalhada, ou **Create Single Convex Collision Sibling** para uma aproximação simples. Verifique no viewport e no F5 se o player não atravessa o asset.

## Teste e limites

Não acenda luzes novas nem adicione emissão para “compensar” a edição. No jogo, **F** alterna a lanterna, **E** interage com portas, e **Esc** libera o cursor. Não adicione entidades, networking ou multiplayer neste trabalho.

Não use o “olhinho” de `Node.visible` para isolar pavimentos: salvar `visible = false` também os oculta no jogo. Use **Piso/Tetos**: o plugin restaura os valores originais antes de salvar e reaplica a prévia depois. O salvamento real com filtro ativo foi testado sem gravar overrides de objetos ocultos. Capturas reais e verificações estão em `qa/whole_house/`; consulte `ENTREGA_CASA_INTEIRA.md` para os resultados. Depois das suas próprias alterações, valide novamente com F5.

Na máquina de teste com OpenGL por software (llvmpipe), a vista superior muito afastada da composição inteira não apresentou uma imagem confiável. Não foi possível confirmar a causa. Prefira editar as cenas dos cômodos e focar um móvel com **F**; essas cenas continuam sendo as mesmas carregadas na casa e no F5. Não troque o renderer nem altere a iluminação do jogo para contornar essa limitação da prévia.
