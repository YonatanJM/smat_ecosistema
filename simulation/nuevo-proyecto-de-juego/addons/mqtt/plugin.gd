@tool
extends EditorPlugin

func _enter_tree():
	# Registramos el nodo usando un icono nativo de Godot para evitar archivos faltantes
	add_custom_type("MQTTClient", "Node", preload("mqtt.gd"), get_editor_interface().get_base_control().get_theme_icon("Node", "EditorIcons"))

func _exit_tree():
	remove_custom_type("MQTTClient")
