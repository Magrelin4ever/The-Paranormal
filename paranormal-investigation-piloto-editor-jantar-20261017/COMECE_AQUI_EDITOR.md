# Comece aqui — casa inteira editável

O fluxo atual já inclui **porão, térreo, primeiro andar e sótão/segundo andar**. Abra `project.godot` no Godot 4.7.2 e siga o [Guia de edição da casa inteira](GUIA_EDICAO_CASA_INTEIRA.md). A composição principal editável está em `prototype/whole_house/casa_editavel.tscn`; os cômodos estão em `prototype/whole_house/rooms/`.

Salve as cenas com **Ctrl+S** e use **F5**: o jogo carrega os mesmos arquivos salvos. A cozinha de Richard foi mantida. Consulte a [entrega e os testes](ENTREGA_CASA_INTEIRA.md) para os resultados e limitações.

<details>
<summary>Histórico: instruções do antigo piloto da sala de jantar</summary>

# Piloto: arrastar móveis da sala de jantar

Esta é uma **candidata separada**, feita a partir da C2 atual. Apenas a sala de jantar foi convertida. A planta, os outros cômodos, as portas e os controles continuam no sistema anterior. Não é uma conversão da casa inteira.

## Abrir e editar

- [ ] Abra o `project.godot` desta pasta no **Godot 4.7.2**. Aguarde a primeira importação.
- [ ] Em FileSystem, abra `prototype/editor_pilot/sala_jantar_editavel.tscn` com duplo clique.
- [ ] Clique na aba **3D**. Selecione `Mesa` ou `Cadeira_01` na árvore **Scene**, à esquerda, e pressione **F** com o mouse sobre o viewport para enquadrar.
- [ ] Use **W** para mover, **E** para rotacionar e **R** para escalar (atalhos do editor, não do jogo). Arraste as setas/anéis do gizmo. O plano XZ mantém o móvel no chão; Y altera altura.
- [ ] Ative o ímã de snapping para ajustes regulares; ajuste o passo no menu de transformação. Para valores exatos, use **Inspector → Transform**.
- [ ] **Ctrl+D** duplica uma peça; Delete a remove. **Ctrl+Z** desfaz. **Ctrl+S** salva a composição.
- [ ] Pressione **F5** para jogar a casa principal com o layout salvo. **F8** encerra o teste. Não use F6 na cena de composição: ela não tem jogador.

As mudanças salvas nessa cena aparecem na casa principal, pois ela instancia o mesmo arquivo. Não é necessário copiar posições para código. Faça as mudanças na árvore **Local**, nunca na árvore **Remote** de um jogo em execução.

## O que pode selecionar

Mesa, seis cadeiras, tapete, lustre apagado, aparador, quadro e planta são instâncias próprias. A mesa contém chá, quatro pratos, guardanapo e copo infantil; o aparador contém vaso e lamparina. Mover o móvel leva esses objetos junto.

Para mover apenas um adereço, clique com o botão direito na instância `Mesa` ou `Aparador` e ative **Editable Children / Filhos editáveis**. Expanda a árvore e selecione o adereço. Os nós internos continuam disponíveis pelo painel Scene mesmo quando a seleção no viewport agrupa a peça inteira. Não é preciso tornar a cena local nem alterar scripts.

Mesa, cadeiras e aparador têm `Colisao_Acompanha_Movel` como descendente. Ao mover ou rotacionar a raiz da peça, o colisor acompanha. Evite escalar só a malha interna; prefira a raiz e mantenha escala uniforme. Adereços pequenos continuam decorativos, sem bloqueio físico, como na C2.

## Colocar um `.glb` seu — sem programar

1. Copie o `.glb` e eventuais texturas externas para `prototype/assets/user_imports/` pelo gerenciador de arquivos. Espere o Godot importar. Use uma subpasta por asset para evitar conflitos de nomes.
2. Com `sala_jantar_editavel.tscn` aberta, selecione a raiz `SalaJantar_Editavel` e arraste o arquivo do painel **FileSystem** para o viewport 3D. Também pode arrastá-lo para a árvore Scene para escolher o pai com precisão.
3. Renomeie a instância e ajuste **Transform → Position / Rotation / Scale**. O chão jogável está em **Y = 0**; a origem do GLB pode estar no centro em vez da base. A sala ocupa aproximadamente **X −9,19 a −1,96**, **Z −2,69 a 2,39**. Preserve as passagens nas paredes Z −2,8 e 2,5 e para o corredor em X −1,85.
4. Salve com Ctrl+S e teste com F5. **Importar um GLB não cria colisão automaticamente.** Se for apenas decoração, pode ficar sem colisor.

### Se o novo móvel precisar bloquear o jogador

Crie uma cena reutilizável pelo menu **Scene → New Scene**: raiz `Node3D`, modelo GLB como filho e um `StaticBody3D` como outro filho. Dentro do StaticBody3D, adicione `CollisionShape3D`; no Inspector escolha **Shape → New BoxShape3D** e ajuste tamanho/posição para o volume do móvel. Deixe **Collision Layer = 1**. Salve como `.tscn`, depois arraste essa cena para o jantar. Tudo é feito no editor, sem GDScript.

Transforme a raiz Node3D para mover modelo e colisor juntos. Para peças muito complexas, o menu **Mesh** de uma MeshInstance3D oferece geração de colisão; uma caixa simples costuma ser mais previsível para móveis. Confira o resultado com **Debug → Visible Collision Shapes** durante o jogo.

## Referência de paredes e iluminação

`Referencia_EDITOR_so` é uma referência visual travada, sem teto, para posicionar os móveis no viewport. Ela usa os materiais e vãos da sala atual, **não é a estrutura jogável** e é removida automaticamente ao rodar. Não a edite para mudar a planta. Pode ocultá-la no editor para enxergar melhor.

A visualização clara do editor usa a prévia de sol/ambiente do próprio editor; não adicione uma luz à cena só para editar. No jogo, as luzes internas continuam apagadas e a lanterna permanece disponível. Se o GLB novo trouxer luzes ou materiais emissivos, desligue-os no editor para preservar esse comportamento.

## Antes de aprovar o piloto

- [ ] Mover uma cadeira, salvar, jogar com F5 e conferir a posição e colisão.
- [ ] Desfazer/restaurar, rotacionar a mesma cadeira e repetir o teste.
- [ ] Importar um GLB de teste e colocá-lo sem abrir um script.
- [ ] Verificar portas, caminhos livres e lanterna com o layout desejado.

**Os outros cômodos não foram migrados.** O próximo passo depende da sua revisão deste fluxo.

</details>
