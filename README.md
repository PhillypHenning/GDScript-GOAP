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



## Potential improvements (after OpenAI Review)
### 1. Action Class
- [DISREGARD] **Constructor Improvement**: Use `_ready()` instead of `_init()` to initialize node properties since Godot handles the lifecycle of nodes more efficiently this way.
    - _ready doesn't allow for parameter variables, disregard.
- [DISREGARD] **Preconditions Check**: Improve the `is_valid` method to better handle cases where preconditions aren't simple key-value pairs.
    - Currently K/V pairs can include callables which adds a lot of flexability to what a precondition can be. Disregarding.. 
- [DONE] **String Typing for `cost`**: Although you mentioned `cost` as a `Dictionary`, consider using a `float` or `int` instead for easier calculation and consistency.

### 2. Goal Class
- **Initialization Refactor**: Simplify and unify the creators of the `Goal` instance.
- **Callable Validation**: Add checks to ensure `Callable` is valid before attempting to call.

### 3. Planner Class
- **Combining and Sorting Actions**: Ensure action sets are unique and sort necessary actions by cost efficiently.
- **Plan Building**: Optimize the recursive `build_node_plan` function, including memoizing states already evaluated.
