extends Control
class_name SmartControl


export var control_parent_node := false
export var check_changes_every_frame := false
var print_changed_vars := false
var print_called_func := false

var target = self
var connected_with_var := {}
var connected_with_func := []

var prev_state := {}

enum ConnectionType {
  FUNCTION,
  VARIABLE,
  NONE,
}

func _ready():
	if control_parent_node:
		target = get_parent()
	_find_and_connect(target)
	initialize()

func _process(delta):
	if check_changes_every_frame:
		update_ui()

func _get_method_args_count(control, method_name):
	var method_list = control.get_method_list()
	for m in method_list:
		if m.name == method_name:
			return m.args.size()

# Recursively find and connect control nodes with code in their names
func _find_and_connect(control) -> void:
	for child in control.get_children():
		if not child is Control and not child is CanvasLayer: continue
		var results = _get_code(child.name)
		for result in results:
			match result.connection_type:
				ConnectionType.VARIABLE:
					connect_var(result.data.var_name, child, result.data.prop_name)
				ConnectionType.FUNCTION:
					connect_func(result.data.func_name, child, result.data.signal_name)
		if not child.has_method("_find_and_connect"):
			_find_and_connect(child)


func connect_var(var_name:String, control:Control, prop_name) -> void:
	var type = typeof(target[var_name])
	if type == TYPE_ARRAY or type == TYPE_DICTIONARY:
		prev_state[var_name] = target[var_name].duplicate(true)
	else:
		prev_state[var_name] = target[var_name]
	
	if not connected_with_var.has(var_name):
		connected_with_var[var_name] = []
	
	connected_with_var[var_name].append({
		"control": control,
		"prop_name":prop_name
	})

func connect_func(func_name:String, control:Control, signal_name) -> void:
	var args_count = _get_method_args_count(target, func_name)
	match args_count:
		0: control.connect(signal_name, target, "_call_function", [func_name])
		1: control.connect(signal_name, target, "_call_function_one_arg", [func_name])
		2: control.connect(signal_name, target, "_call_function_two_arg", [func_name])
		3: control.connect(signal_name, target, "_call_function_three_arg", [func_name])
		4: control.connect(signal_name, target, "_call_function_four_arg", [func_name])
		5: control.connect(signal_name, target, "_call_function_five_arg", [func_name])

#___________________________________________________________________________________________________
func _call_function(function) -> void:
	var expression = Expression.new()
	expression.parse(function+"()", [])
	expression.execute([], target)
	if print_called_func:
		print("SMARTCONTROL["+str(name)+"] called function: " + function)
	update_ui()

func _call_function_one_arg(one, function) -> void:
	var expression = Expression.new()
	expression.parse(""+function+"(one)", ["one"])
	expression.execute([one], target)
	if print_called_func:
		print("SMARTCONTROL["+str(name)+"] called function: " + function)
	update_ui()
	
func _call_function_two_arg(one, two, function) -> void:
	var expression = Expression.new()
	expression.parse(""+function+"(one, two)", ["one", "two"])
	expression.execute([one, two], target)
	if print_called_func:
		print("SMARTCONTROL["+str(name)+"] called function: " + function)
	update_ui()

func _call_function_three_arg(one, two, three, function) -> void:
	var expression = Expression.new()
	expression.parse(""+function+"(one, two, three)", ["one", "two", "three"])
	expression.execute([one, two, three], target)
	if print_called_func:
		print("SMARTCONTROL["+str(name)+"] called function: " + function)
	update_ui()

func _call_function_four_arg(one, two, three, four, function) -> void:
	var expression = Expression.new()
	expression.parse(""+function+"(one, two, three, four)", ["one", "two", "three", "four"])
	expression.execute([one, two, three, four], target)
	if print_called_func:
		print("SMARTCONTROL["+str(name)+"] called function: " + function)
	update_ui()

func _call_function_five_arg(one, two, three, four, five, function) -> void:
	var expression = Expression.new()
	expression.parse(""+function+"(one, two, three)", ["one", "two", "three", "four", "five"])
	expression.execute([one, two, three, four, five], target)
	if print_called_func:
		print("SMARTCONTROL["+str(name)+"] called function: " + function)
	update_ui()
#___________________________________________________________________________________________________


func initialize() -> void:
	for var_name in connected_with_var:
		for connection in connected_with_var[var_name]:
			_update_control(connection.control, connection.prop_name, var_name)


func update_ui(var_names:Array=[]) -> void:
	_before_update_ui()
	var changed_vars = _find_changed_vars() if var_names.size() == 0 else var_names
	
	if not check_changes_every_frame and print_changed_vars and changed_vars.size() > 0:
		print("SMARTCONTROL["+str(target.name)+"] changed vars: "+str(changed_vars))
		
	for var_name in changed_vars:
		for connection in connected_with_var[var_name]:
			if is_instance_valid(connection.control):
				_update_control(connection.control, connection.prop_name, var_name)


func _find_changed_vars() -> Array:
	var output = []
	for key in prev_state.keys():
		var type = typeof(target[key])
		if type == TYPE_ARRAY or type == TYPE_DICTIONARY:
			if prev_state[key].hash() != target[key].hash():
				output.append(key)
				prev_state[key] = target[key].duplicate(true)
				output.append_array(_find_changed_vars())
		else:
			if prev_state[key] != target[key]:
				output.append(key)
				prev_state[key] = target[key]
				output.append_array(_find_changed_vars())
	return output


func _update_control(control, prop_name, var_name) -> void:
	if prop_name == "children":
		if control.get_children().size() < target[var_name].size():
			for x in range(control.get_children().size(), target[var_name].size()):
				var child = target[var_name][x]
				control.add_child(child)
		return
	
	if prop_name == "text":
		control.text = str(target[var_name])
		if control.has_method("update_ui"):
			control.update_ui()
		if control.has_focus():
			control.caret_position = control.text.length()
	else:
		control[prop_name] = target[var_name]


func _before_update_ui() -> void:
	pass

func _called_method() -> void:
	pass

func _get_code(text:String)-> Array:
	var output = []
	var results = _get_func(text)
	results.append_array(_get_var(text))
	return results


func _get_func(text:String) -> Array:
	var output = []
	var regex = RegEx.new()
	regex.compile("\\([a-z+|_]+=[a-z+|_]+\\)")
	for result in regex.search_all(text):
		var data = _get_data(result.get_string())
		if data:
			output.append({
				connection_type = ConnectionType.FUNCTION,
				data = {
					signal_name = data[0],
					func_name = data[1]
				}
			})
	return output

func _get_var(text:String) -> Array:
	var output = []
	var regex = RegEx.new()
	regex.compile("\\[[a-z+|_]+=[a-z+|_]+\\]")
	for result in regex.search_all(text):
		var data = _get_data(result.get_string())
		if data:
			output.append({
				connection_type = ConnectionType.VARIABLE,
				data = {
					prop_name = data[0],
					var_name = data[1]
				}
			})
	return output

func _get_data(text:String):
	var result = text.split("=")
	if result.size() == 2:
		var key = result[0].trim_prefix("(").trim_prefix("[")
		var value = result[1].trim_suffix(")").trim_suffix("]")
		return [key, value]

func set_var(var_name:String, value) -> void:
	target[var_name] = value
	update_ui()
