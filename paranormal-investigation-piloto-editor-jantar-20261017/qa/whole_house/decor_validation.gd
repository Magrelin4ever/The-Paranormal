extends SceneTree
const ROOMS = ["porao__Lavanderia_Porao", "porao__Deposito", "porao__Oficina", "porao__Circulacao_Porao", "sotao__Arquivo_Sotao", "sotao__Deposito_Sotao"]
func _count(n: Node, typ: String) -> int:
 var c := 0
 for x in n.get_children():
  if (typ == "collision" and (x is CollisionShape3D or x is CollisionPolygon3D or x is PhysicsBody3D)) or (typ == "light" and x is Light3D): c += 1
  c += _count(x, typ)
 return c
func _initialize() -> void:
 var ok := true
 for name in ROOMS:
  var path := "res://prototype/whole_house/rooms/%s.tscn" % name
  var packed := ResourceLoader.load(path, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
  if packed == null: print("FAIL load ", path); ok = false; continue
  var inst := packed.instantiate()
  var coll := _count(inst, "collision")
  var lights := _count(inst, "light")
  print("ROOM %s collision=%d lights=%d" % [name, coll, lights])
  if coll < 1 or lights > 0: ok = false
  inst.free()
 print("DECOR_VALIDATION=%s" % ("PASS" if ok else "FAIL"))
 quit(0 if ok else 1)
