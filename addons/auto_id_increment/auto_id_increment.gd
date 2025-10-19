@tool
extends EditorPlugin

const ID_PROPERTY_NAME = "ObjId"
const UNASSIGNED_ID = -1
const SETTINGS_PATH = "editor_tools/last_sdk_id"

var last_known_id: int = 0

func _enter_tree() -> void:
	if ProjectSettings.has_setting(SETTINGS_PATH):
		last_known_id = ProjectSettings.get_setting(SETTINGS_PATH)
	else:
		ProjectSettings.set_setting(SETTINGS_PATH, 0)
		ProjectSettings.save()

	get_editor_interface().get_selection().selection_changed.connect(_on_selection_changed)
	_scan_scene_for_max_id(get_editor_interface().get_edited_scene_root())
	print("Auto ID Increment: Plugin activated. Current highest ID is %d." % last_known_id)


func _exit_tree() -> void:
	var selection = get_editor_interface().get_selection()
	if selection.selection_changed.is_connected(_on_selection_changed):
		selection.selection_changed.disconnect(_on_selection_changed)

	print("Auto ID Increment: Plugin deactivated")

func _on_selection_changed():
	var selected_nodes = get_editor_interface().get_selection().get_selected_nodes()

	for node in selected_nodes:
		_assign_id_if_needed(node)

	ProjectSettings.set_setting(SETTINGS_PATH, last_known_id)
	ProjectSettings.save()


func _assign_id_if_needed(node: Node):
	if not is_instance_valid(node):
		return -1

	if ID_PROPERTY_NAME in node and node.get(ID_PROPERTY_NAME) == UNASSIGNED_ID:
		last_known_id += 1
		node.set(ID_PROPERTY_NAME, last_known_id)

	for child in node.get_children():
		_assign_id_if_needed(child)

func _scan_scene_for_max_id(start_node: Node):
	if not is_instance_valid(start_node):
		return

	var max_id_found = _recursive_scan_for_max(start_node)

	if max_id_found > last_known_id:
		last_known_id = max_id_found
		ProjectSettings.set_setting(SETTINGS_PATH, last_known_id)
		ProjectSettings.save()

func _recursive_scan_for_max(node: Node) -> int:
	var max_id = -1
	if ID_PROPERTY_NAME in node:
		max_id = max(max_id, node.get(ID_PROPERTY_NAME))
	
	for child in node.get_children():
		max_id = max(max_id, _recursive_scan_for_max(child))

	return max_id
