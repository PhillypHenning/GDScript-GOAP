extends Node


func calculate_time_to_reach_destination(speed: float, start_position: Vector2, desired_position: Vector2) -> float:
	# Calculate the distance between the two positions
	var distance = start_position.distance_to(desired_position)

	# Calculate the time to reach the target
	var time_to_reach = distance / speed

	print("Time to reach target: " + str(time_to_reach) + " seconds")
	
	return time_to_reach
