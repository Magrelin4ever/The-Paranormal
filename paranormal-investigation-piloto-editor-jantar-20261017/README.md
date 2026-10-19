# Casa — piloto de edição da sala de jantar

Candidata independente baseada na C2 atual. **Somente a sala de jantar foi convertida para cenas editáveis.** Produção e baseline C2 não são destinos de edição.

## Comece aqui

Abra `project.godot` no **Godot 4.7.2** e depois `prototype/editor_pilot/sala_jantar_editavel.tscn`. O guia **[COMECE_AQUI_EDITOR.md](COMECE_AQUI_EDITOR.md)** explica selecionar, arrastar, rotacionar, duplicar móveis e importar seus próprios `.glb`, sem editar código.

A cena principal continua sendo `prototype/house_environment.tscn`; use **F5** para jogar. O piloto é uma instância dessa mesma composição, portanto alterações salvas no editor aparecem no jogo sem geração duplicada.

## Organização

- `prototype/editor_pilot/sala_jantar_editavel.tscn`: composição do cômodo, com posições editáveis.
- `prototype/editor_pilot/items/`: cenas reutilizáveis de móveis e decoração. As colisões dos móveis bloqueáveis acompanham suas raízes.
- `prototype/assets/user_imports/`: pasta sugerida para seus GLB e texturas.
- `prototype/editor_pilot/editor_reference.gd`: exibe a referência estrutural apenas no editor e a remove no jogo; não gera móveis.
- `qa/editor_pilot/`: validações e previews desta candidata. Logs fora dessa pasta são históricos herdados, não comprovantes deste piloto.

Mesa e aparador levam os objetos apoiados junto ao mover. Use **Editable Children / Filhos editáveis** para selecionar esses adereços separadamente. A referência de paredes é travada, sem teto e apenas para posicionamento; a estrutura jogável e as portas continuam originais.

Os assets e os avisos de licença existentes foram mantidos. Esta conversão não regulariza licenças pendentes nem transforma o protótipo em arte final. Veja os registros em `prototype/assets/`.

**Não migrar os demais cômodos antes de Richard revisar e aprovar este fluxo.**
