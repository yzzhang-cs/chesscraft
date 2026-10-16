class_name Army
extends RefCounted
## The three armies a side can field: Xiangqi, Shogi, and 大肥鱼的象棋 (a
## Xiangqi-variant army that differs only in its opening placement). Pure model
## -- no Node/scene dependency.


enum Type {
	XIANGQI,
	BIG_FAT_WHALE,
	SHOGI,
}


const NAMES := {
	Type.XIANGQI: "Xiangqi",
	Type.BIG_FAT_WHALE: "大肥鱼的象棋",
	Type.SHOGI: "Shogi",
}


## Human-readable army name, for the menu and status text.
static func display_name(type: Type) -> String:
	return NAMES[type]


## All armies, in menu order.
static func all() -> Array:
	return [Type.XIANGQI, Type.BIG_FAT_WHALE, Type.SHOGI]
