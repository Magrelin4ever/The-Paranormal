# Validação do piloto de jantar

## O que foi convertido

A composição de jantar agora vive em `prototype/editor_pilot/sala_jantar_editavel.tscn`, instanciada pela cena principal. São 12 instâncias principais reutilizáveis, com 21 conjuntos selecionáveis contando os adereços aninhados. Há uma mesa, seis cadeiras, tapete, lustre apagado, aparador, quadro, planta e os objetos apoiados.

O código que gerava essa composição no runtime foi retirado somente desse bloco. Os índices dos assets seguintes foram preservados. Os outros cômodos não foram convertidos.

## Testes executados no Godot 4.7.2

- **Composição e iluminação:** uma mesa, seis cadeiras, quatro pratos, copo, guardanapo, chá e lustre. Nenhuma luz interna ou superfície emissiva ativa; três camadas da lanterna presentes. Dez capturas reais de runtime em `qa/editor_pilot/previews/`.
- **Preservação visual e física:** comparação da candidata com o script C2 original carregado dentro da candidata: **5.566 malhas individuais** com transformações globais, limites e materiais iguais, e **539 colisores de caixa** com poses/tamanhos iguais. A malha procedural agregada é excluída dessa comparação, pois o tapete foi separado dela; o restante do código estrutural está intacto.
- **Jogabilidade:** rota contínua de 38 pontos passou com as portas abertas para o teste; tecla E abriu/fechou a porta frontal por raycast. A sonda de acesso usou a cápsula do jogador em 65 pontos, mantendo as portas no estado inicial fechado, sem colisões nos caminhos amostrados. Isso não equivale a testar toda a casa em todas as posições possíveis dos móveis.
- **Apoio dos adereços:** folgas geométricas AABB da mesa e do aparador dentro das tolerâncias, sem reposicionamento da composição. Os adereços continuam sem colisores físicos, como no baseline.
- **Edição e persistência:** seleção no editor, arraste real de `Cadeira_02` pelo gizmo e salvamento da posição; rotação real pelo anel Y e salvamento. A cadeira foi deslocada de X −5,3 para −4,807675 e girada pelo anel Y apenas durante o teste. A cena principal carregou o resultado salvo, com o colisor acompanhando a raiz. O layout de entrega foi restaurado byte a byte após esse teste.
- **GLB e cenas:** instância de GLB existente empacotada, salva e recarregada em arquivo temporário; nenhum arquivo da composição foi alterado por esse smoke test. O guia explica o procedimento pelo editor para assets do usuário.

Os detalhes estão nos logs `validation.log`, `compare.log`, `capture.log`, `c13_routes.log`, `c13_key_e_probe.log`, `dining_c13_contact_probe.log`, `dining_c13_access_physics_probe.log`, `mouse_saved_runtime.log` e `mouse_test.json`, todos em `qa/editor_pilot/`.

## Importação do editor

A primeira importação paralela abortou com erro de memória; houve também um crash na primeira sessão gráfica durante reimportação de artefatos herdados. A candidata passou a ignorar `qa/` na importação automática (`qa/.gdignore`) e limitar o paralelismo. A importação final passou e o editor foi reaberto para o teste de mouse. O projeto também foi extraído do pacote em uma pasta separada, sem `.godot`, e passou por importação limpa com código de saída 0 (`clean_package_import.log`); a cena principal extraída também passou no validador de runtime (`clean_package_runtime.log`). Esses ajustes não mudam a planta nem as regras do jogo.

## Proteção dos originais

Os hashes de todos os arquivos fora do cache `.godot` foram comparados: **produção e baseline C2 preservados, sem arquivos modificados, removidos ou adicionados**. Registros: `protected_before.json` e `protected_after.json`.

## Limite da aprovação

Este é um piloto de fluxo de edição, não a migração completa da casa. A referência estrutural sem teto é apenas de editor e é removida no runtime; as paredes e portas jogáveis permanecem no sistema original. Móveis novos precisam de colisores próprios quando forem bloqueáveis. Qualquer layout alterado pelo usuário exige novo teste de passagens.
