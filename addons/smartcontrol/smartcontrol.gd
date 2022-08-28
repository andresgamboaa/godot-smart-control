extends Control
class_name SmartControl
# Connect a variable to a property of a node and SmartControl will update that
# property automatically every time the variable changes


export var control_parent_node := false
export var check_changes_every_frame := false
var print_changed_vars := false
var print_called_func := false

var target = self
var connected_with_var := {}
var called_after_var := {}
var connected_with_func := {}
var repeatables = {}

var items_list = {}

var prev_state := {}

enum ConnectionType {
  FUNCTION,
  VARIABLE,
  NONE,
}

func _ready():
	if control_parent_node:
		target = get_parent()
	_connections()
	_find_and_connect(target)
	connect("ready", self, "_after_ready")

func _after_ready():
	_initialize()


func _connections():
	pass

func _process(delta):
	if check_changes_every_frame:
		update_control_nodes()

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


func connect_var(var_name:String, control:Control, prop_name, mod=null):
	var type = typeof(target[var_name])
	if type == TYPE_ARRAY or type == TYPE_DICTIONARY:
		prev_state[var_name] = target[var_name].duplicate(true)
	else:
		prev_state[var_name] = target[var_name]
	
	if not connected_with_var.has(var_name):
		connected_with_var[var_name] = []
	
	connected_with_var[var_name].append({
		"control": control,
		"prop_name":prop_name,
		"mod": mod
	})


func connect_func_to_var(func_name:String, control, var_name):
	if not called_after_var.has(var_name):
		called_after_var[var_name] = []
	called_after_var[var_name].append(func_name)
	return self

func connect_func(func_name:String, control:Control, signal_name):
	var args_count = _get_method_args_count(target, func_name)
	match args_count:
		0: control.connect(signal_name, target, "_call_function", [func_name])
		1: control.connect(signal_name, target, "_call_function_one_arg", [func_name])
		2: control.connect(signal_name, target, "_call_function_two_arg", [func_name])
		3: control.connect(signal_name, target, "_call_function_three_arg", [func_name])
		4: control.connect(signal_name, target, "_call_function_four_arg", [func_name])
		5: control.connect(signal_name, target, "_call_function_five_arg", [func_name])
	
#___________________________________________________________________________________________________
func _call_function(function):
	var expression = Expression.new()
	expression.parse(function+"()", [])
	expression.execute([], target)
	if print_called_func:
		print("SMARTCONTROL["+str(name)+"] called function: " + function)
	update_control_nodes()

func _call_function_one_arg(one, function):
	var expression = Expression.new()
	expression.parse(function+"(one)", ["one"])
	expression.execute([one], target)
	if print_called_func:
		print("SMARTCONTROL["+str(name)+"] called function: " + function)
	update_control_nodes()

func _call_function_two_arg(one, two, function):
	var expression = Expression.new()
	expression.parse(function+"(one, two)", ["one", "two"])
	expression.execute([one, two], target)
	if print_called_func:
		print("SMARTCONTROL["+str(name)+"] called function: " + function)
	update_control_nodes()

func _call_function_three_arg(one, two, three, function):
	var expression = Expression.new()
	expression.parse(function+"(one, two, three)", ["one", "two", "three"])
	expression.execute([one, two, three], target)
	if print_called_func:
		print("SMARTCONTROL["+str(name)+"] called function: " + function)
	update_control_nodes()

func _call_function_four_arg(one, two, three, four, function):
	var expression = Expression.new()
	expression.parse(function+"(one, two, three, four)", ["one", "two", "three", "four"])
	expression.execute([one, two, three, four], target)
	if print_called_func:
		print("SMARTCONTROL["+str(name)+"] called function: " + function)
	update_control_nodes()

func _call_function_five_arg(one, two, three, four, five, function):
	var expression = Expression.new()
	expression.parse(function+"(one, two, three)", ["one", "two", "three", "four", "five"])
	expression.execute([one, two, three, four, five], target)
	if print_called_func:
		print("SMARTCONTROL["+str(name)+"] called function: " + function)
	update_control_nodes()
#___________________________________________________________________________________________________


func _initialize():
	for var_name in connected_with_var:
		for connection in connected_with_var[var_name]:
			_update_control(connection.control, connection.prop_name, var_name, connection.mod)
	
	for key in repeatables.keys():
		for item in target[key]:
			var child = repeatables[key].control.duplicate()
			for prop in item.keys():
				child[prop] = item[prop]
			item.control_node = child
			repeatables[key].parent.add_child(child)
			_connect_repeatable(child, repeatables[key].connections)
		prev_state[key] = target[key].duplicate(true)


func update_control_nodes():
	_before_update_control_nodes()
	var changed_vars = _find_changed_vars()
	if not check_changes_every_frame and print_changed_vars and changed_vars.size() > 0:
		print("SMARTCONTROL["+str(target.name)+"] changed vars: "+str(changed_vars))
	
	for var_name in changed_vars:
		if connected_with_var.has(var_name):
			for connection in connected_with_var[var_name]:
				if is_instance_valid(connection.control):
					_update_control(connection.control, connection.prop_name, var_name, connection.mod)
			if called_after_var.has(var_name):
				for f in called_after_var[var_name]:
					var expression = Expression.new()
					expression.parse(f+"()", [])
					expression.execute([], target)
		_update_repeatables(var_name)
	_update_prev_state(changed_vars)
# 1 1
#   2

func _update_repeatables(var_name):
	if not repeatables.has(var_name): 
		return
		
	var skip = 0 # when a prev_item is queue_free skip an index
	
	var big_state = max(target[var_name].size(), prev_state[var_name].size())
	
	for i in range(0, big_state):
		var prev_item
		var item
		
		if i+skip < prev_state[var_name].size(): 
			prev_item = prev_state[var_name][i+skip]
			
		if i < target[var_name].size():
			item = target[var_name][i]
		
		if not item:
			if not prev_item:
				continue
			if not _has_control(prev_item.control_node, var_name):
				prev_item.control_node.queue_free()
				skip += 1
			continue
		
		# if item is new
		if not item.has("control_node"):
			item.control_node = repeatables[var_name].control.duplicate()
			for prop in item.keys():
				if prop == "control_node": 
					continue
				item.control_node[prop] = item[prop]
			
		if not prev_item:
			if item.control_node.get_parent():
				var parent = item.control_node.get_parent()
				parent.remove_child(item.control_node)
			repeatables[var_name].parent.add_child(item.control_node)
			_connect_repeatable(item.control_node, repeatables[var_name].connections)
			continue
			
		# if there is a different item at its pos
		if prev_item.control_node != item.control_node:
			if item.control_node.get_parent():
				var parent = item.control_node.get_parent()
				parent.remove_child(item.control_node)
				
			var parent = prev_item.control_node.get_parent()
			parent.add_child_below_node(prev_item.control_node, item.control_node)
			_connect_repeatable(item.control_node, repeatables[var_name].connections)
			
			if not _has_control(prev_item.control_node, var_name):
				prev_item.control_node.queue_free()
				skip += 1


func _has_control(control, var_name):
	for item in target[var_name]:
		if item.control_node == control:
			return true
	return false


func _find_changed_vars():
	var output = []
	for key in prev_state.keys():
		var type = typeof(target[key])
		if type == TYPE_ARRAY or type == TYPE_DICTIONARY:
			if prev_state[key].hash() != target[key].hash():
				output.append(key)
		else:
			if prev_state[key] != target[key]:
				output.append(key)
	return output


func _update_prev_state(vars):
	for key in vars:
		var type = typeof(target[key])
		if type == TYPE_ARRAY or type == TYPE_DICTIONARY:
			if prev_state[key].hash() != target[key].hash():
				prev_state[key] = target[key].duplicate(true)
		else:
			if prev_state[key] != target[key]:
				prev_state[key] = target[key]


func _update_control(control, prop_name, var_name, mod=null) -> void:
	if control == null: return
	if prop_name == "children":
		if control.get_children().size() < target[var_name].size():
			for x in range(control.get_children().size(), target[var_name].size()):
				var child = target[var_name][x]
				control.add_child(child)
		return
	
	if prop_name == "child":
		for child in control.get_children():
			child.queue_free()
		if is_instance_valid(target[var_name]) and not target[var_name].get_parent():
			control.add_child(target[var_name])
		return
	
	var result
	if mod:
		var expression = Expression.new()
		expression.parse(mod+"(x)", ["x"])
		result = expression.execute([target[var_name]], target)
	
	if prop_name == "text":
		control.text = str(result) if mod else str(target[var_name])
		if control.has_method("update_control_nodes"):
			control.update_control_nodes()
		if control.has_focus() and control is LineEdit or control is TextEdit:
			control.caret_position = control.text.length()
	else:
		control[prop_name] = result if mod else target[var_name]


func _before_update_control_nodes():
	pass


func _called_method():
	pass


func _get_code(text:String):
	var output = []
	var results = _get_func(text)
	results.append_array(_get_var(text))
	return results


func _get_func(text:String):
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


func _get_var(text:String):
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


func set_var(var_name:String, value):
	target[var_name] = value
	update_control_nodes()


func create_binary_toggle(initial):
	return BinaryToggle.new(initial)


func repeat(control, array_name):
	prev_state[array_name] = target[array_name].duplicate(true)
	
	repeatables[array_name] = {
		control=control,
		parent=control.get_parent(),
		connections=_get_connections(control)
	}
	
	control.get_parent().remove_child(control)

func _connect_repeatable(control, connections):
	for list in connections:
		for con in list:
			if not control.is_connected(con.signal, con.target, con.method):
				control.connect(con.signal, con.target, con.method, con.binds)

func _get_connections(control):
	var connections = []
	for s in control.get_signal_list():
		var list = control.get_signal_connection_list(s.name)
		if list.size() > 0:
			connections.append(list)
	return connections

func remove_repeatable(control, array):
#	var index = 0
	for item in array:
		if item.control_node == control:
			array.erase(item)
#			return index
#		index+=1
#	return -1
