

## Teste físico por cômodo (adicionado)

- `qa/whole_house/audit_physics_rooms.gd` instancia a cena indicada por `WHOLE_HOUSE_SCENE` (default: baseline), obtém a `CapsuleShape3D` real do `CharacterBody3D`, usa raio esperado **0,35 m**, amostra uma grade de **0,18 m** e chama `PhysicsDirectSpaceState3D.intersect_shape()` em cada célula.
- Cada cômodo é descoberto genericamente pelo grupo `whole_house_room`, com metadados `room_id`, `audit_bounds_min`, `audit_bounds_max` e `audit_y`. Vãos/saídas são descendentes no grupo `whole_house_exit`, com `audit_room_id` e posição global.
- Para cada cômodo calcula células livres/bloqueadas, faz BFS 8-conectado (inclui diagonais para contornar móveis) e reprova qualquer vão que não seja alcançável. Assim mede circulação interna e fuga pelo vão, não somente waypoints globais.
- Execução headless na baseline após import: o script carregou e chegou ao teste, mas reportou `room_contract` porque a baseline ainda não possui nós `whole_house_room`; não é falha física de rota. Também apareceram avisos existentes `Cannot adjust_bcs in compressed image formats` no tratamento de tecidos e `C16_MODEL_INSTANCED ... colliders=14`.
- Ao criar `Casa_Editavel`, adicione os marcadores por cômodo antes de rodar. O teste pode ser direcionado à cena final com `WHOLE_HOUSE_SCENE=res://.../Casa_Editavel.tscn`. O JSON de resultado é temporário de QA e não deve ser versionado como produção.
