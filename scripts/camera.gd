@tool
extends Camera3D
var player:Player

func _process(delta:float)-> void:
	var vis = get_node('../../../VisualPlayer')
	var mesh:MeshInstance3D = get_node('../../Mesh')
	var off = 1.5
	DebugDraw3D.draw_arrow(self.global_transform.origin-(Vector3(0,0,0)), global_transform*Vector3(0,0,-1), Color.RED, .05,true)
	#DebugDraw3D.draw_arrow(vis.global_position+(Vector3(0,off,0)), Vector3(0,off,0)+(vis.global_transform*Vector3(0,0,-.5)), Color.RED, .1,true)
