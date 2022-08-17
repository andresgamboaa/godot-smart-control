extends Control
class_name SmartControl

var controls_binded_with_var := {}
var controls_binded_with_func := []

var prev_state := {}

enum BindingType {
  FUNCTION,
  VARIABLE,
  NONE,
}

onready var method_list = get_method_list()

func _ready():
	_find_and_bind(self)
	_initialize_ui()

func _get_method_args_count(method_name):
	for m in method_list:
		if m.name == method_name:
			return m.args.size()

# Recursively find and bind control nodes with code in their names
func _find_and_bind(control) -> void:
	for child in control.get_children():
		var results = _get_code(child.name)
		for result in results:
			match result.binding_type:
				BindingType.VARIABLE:
					bind_control_with_var(child, result.data.prop_name, result.data.var_name)
				BindingType.FUNCTION:
					bind_control_with_func(child, result.data.signal_name, result.data.func_name)
		if not child.has_method("_find_and_bind"):
			_find_and_bind(child)


func bind_control_with_var(control:Control, prop_name, var_name:String) -> void:
	var type = typeof(self[var_name])
	if type == TYPE_ARRAY or type == TYPE_DICTIONARY:
		prev_state[var_name] = self[var_name].duplicate(true)
	else:
		prev_state[var_name] = self[var_name]
	
	if not controls_binded_with_var.has(var_name):
		controls_binded_with_var[var_name] = []
	
	controls_binded_with_var[var_name].append({
		"control": control,
		"prop_name":prop_name
	})

func bind_control_with_func(control:Control, signal_name, func_name:String) -> void:
	var args_count = _get_method_args_count(func_name)
	match args_count:
		0: control.connect(signal_name, self, "_call_function", [func_name])
		1: control.connect(signal_name, self, "_call_function_one_arg", [func_name])
		2: control.connect(signal_name, self, "_call_function_two_arg", [func_name])
		3: control.connect(signal_name, self, "_call_function_three_arg", [func_name])
		4: control.connect(signal_name, self, "_call_function_four_arg", [func_name])
		5: control.connect(signal_name, self, "_call_function_five_arg", [func_name])

#___________________________________________________________________________________________________
func _call_function(function) -> void:
	var expression = Expression.new()
	expression.parse(function+"()", [])
	expression.execute([], self)
	_update_ui()

func _call_function_one_arg(one, function) -> void:
	var expression = Expression.new()
	expression.parse(""+function+"(one)", ["one"])
	expression.execute([one], self)
	_update_ui()
	
func _call_function_two_arg(one, two, function) -> void:
	var expression = Expression.new()
	expression.parse(""+function+"(one, two)", ["one", "two"])
	expression.execute([one, two], self)
	_update_ui()

func _call_function_three_arg(one, two, three, function) -> void:
	var expression = Expression.new()
	expression.parse(""+function+"(one, two, three)", ["one", "two", "three"])
	expression.execute([one, two, three], self)
	_update_ui()

func _call_function_four_arg(one, two, three, four, function) -> void:
	var expression = Expression.new()
	expression.parse(""+function+"(one, two, three, four)", ["one", "two", "three", "four"])
	expression.execute([one, two, three, four], self)
	_update_ui()

func _call_function_five_arg(one, two, three, four, five, function) -> void:
	var expression = Expression.new()
	expression.parse(""+function+"(one, two, three)", ["one", "two", "three", "four", "five"])
	expression.execute([one, two, three, four, five], self)
	_update_ui()
#___________________________________________________________________________________________________


func _initialize_ui() -> void:
	for variable in controls_binded_with_var:
		for control in controls_binded_with_var[variable]:
			_update_control(control.control, control.prop_name, variable)


func _update_ui() -> void:
	_before_update_ui()
	var vars_changed = _find_changed_vars()
	print(vars_changed)
	for variable_changed in vars_changed:
		for control in controls_binded_with_var[variable_changed]:
			if is_instance_valid(control.control):
				_update_control(control.control, control.prop_name, variable_changed)


func _find_changed_vars() -> Array:
	var output = []
	for key in prev_state.keys():
		var type = typeof(self[key])
		if type == TYPE_ARRAY or type == TYPE_DICTIONARY:
			if prev_state[key].hash() != self[key].hash():
				output.append(key)
				prev_state[key] = self[key].duplicate(true)
				output.append_array(_find_changed_vars())
		else:
			if prev_state[key] != self[key]:
				output.append(key)
				prev_state[key] = self[key]
				output.append_array(_find_changed_vars())
	return output


func _update_control(control, prop_name, var_name) -> void:
	if prop_name == "items":
#		print(var_name + str(self[var_name]))
		if control.get_children().size() < self[var_name].size():
			for x in range(control.get_children().size(), self[var_name].size()):
				var child = self[var_name][x].scene.instance()
				for key in self[var_name][x]:
					if key != "scene":
						child[key] = self[var_name][x][key]
				control.add_child(child)
				
		return
	
	if prop_name == "text":
		control.text = str(self[var_name])
	else:
		control[prop_name] = self[var_name]


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
				binding_type = BindingType.FUNCTION,
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
				binding_type = BindingType.VARIABLE,
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
