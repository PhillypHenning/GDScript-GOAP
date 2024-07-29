# GDScript-GOAP

The GDScript-GOAP project is a package for adding a GOAP AI to a Godot project.


## Goals
### Variables
| Variable | Summary of usage | Optional |
|:---:|:---:|:---:|
| goal_name | Name of the goal, used for debugging purposes | No |uild_plan* function will loop to the next goal. This will carry on until a plan is produced.
| goal_priority | Priority of the goal | Partial, (Yes if goal_priority_callable is null) |
| goal_priority_callable | Callable to call to calculate priority | Yes |
| goal_criteria | The Criteria the goal is looking to satisfy | No |


### Relationship between a Goal and an Action
**goal_criteria** is a means of expressing a desired world state the goal is searching for. During the *build_plan* function, the **goal_criteria** is compared against all available actions **effects**, actions whose **effects** meet **goal_criteria** are considered well other options would be discarded.

If no available actions **effects** meet the **goal_criteria** then the *build_plan* function will loop to the next goal in the list based on priority.
