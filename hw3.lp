% TIME STEPS
#const t=40. 
time(1..t).


%========== REPRESENT THE INPUT ==========
% Represent the nodes and edges of the graph with node/1 and edge/2.
node(1..6).
edge(1,2).
edge(2,3).
edge(3,4).
edge(4,5).
edge(2,6).
edge(3,6).

% Edges are undirected, so we need to add both directions.
edge(X,Y) :- edge(Y,X).

% Represent the warehouse with warehouse_point/1.
warehouse_point(1).

% Represent the delivery points with delivery_point/1.
delivery_point(4; 5).

% Represent the charging points with charging_point/1.
charging_point(2; 6).

% Input requirements: not both a factory and a delivery point, not both a factory and a charging point, not both a delivery point and a charging point.
:- warehouse_point(X), delivery_point(X).
:- warehouse_point(X), charging_point(X).
:- delivery_point(X), charging_point(X).

% Represent the trucks with truck_ID/1, truck_capacity(truck id, load capacity), truck_charge_capacity(truck id, charge capacity).
truck_ID(1; 2).
truck_capacity(1, 1).
truck_capacity(2, 1).
truck_charge_capacity(1, 10).
truck_charge_capacity(2, 10).


% ========== INITIAL STATE ==========
% warehouse_state(warehouse point, load, time step).
warehouse_state(1, 10, 1).

% delivery_state(delivery point, demand, time step).
delivery_state(4, 2, 1).
delivery_state(5, 2, 1).

% truck_at(truck id, initial location).
truck_at(1, 1).
truck_at(2, 2).

% truck(truck id, time step, location, load level, charge level).
truck(1, 1, 1, 0, 2).
truck(2, 1, 2, 0, 2).


% ========== AVAILABLE ACTIONS ==========
action(wait, ID) :- truck(ID, _, _, _, _).
action(move_to(Y), ID) :- truck(ID, _, X, _, _), edge(X, Y).
action(load_package, ID) :- truck(ID, _, _, _, _). 
action(unload_package, ID) :- truck(ID, _, _, _, _).
action(charge, ID) :- truck(ID, _, _, _, _).

% ========== SEQUENCE OF ACTIONS ==========
% Generate sequence of actions for each truck at each time step.
1 { do(T, ID, A) : action(A, ID) } 1 :- time(T), truck(ID, _, _, _, _), T < t.


% ========== SUBSEQUENT CHANGE AFTER ACTIONS ==========
% after (truck) wait
truck(ID, T + 1, location, load, charge) :- truck(ID, T, location, load, charge), do(T, ID, wait).

% after (truck) move
truck(ID, T + 1, to_location, load, charge - 1) :- truck(ID, T, from_location, load, charge), do(T, ID, move_to(to_location)).

% after (truck) load package
truck(ID, T + 1, location, load + 1, charge) :- truck(ID, T, location, load, charge), do(T, ID, load_package).
warehouse_state(warehouse_point, load - 1, T + 1) :- warehouse_state(warehouse_point, load, T), do(T, _, load_package), truck(_, T, warehouse_point, _, _).

% after (truck) unload package
truck(ID, T + 1, location, load - 1, charge) :- truck(ID, T, location, load, charge), do(T, ID, unload_package).
delivery_state(delivery_point, demand - 1, T + 1) :- delivery_state(delivery_point, demand, T), do(T, _, unload_package), truck(_, T, delivery_point, _, _).

% after (truck) charge
truck(ID, T + 1, location, load, charge + 1) :- truck(ID, T, location, load, charge), do(T, ID, charge).

% warehouse state does not change if not loading occured
% loaded(X, T) :- warehouse_state(X, _, T), do(T, _, load_package), truck(_,T, X, _, _).
% warehouse_state(X, load, T + 1) :- warehouse_state(X, load, T), do(T, _, A), not A = load_package, not loaded(X, T).
warehouse_state(warehouse_point, load, T + 1) :- warehouse_state(warehouse_point, load, T), do(T, _, A), not A = load_package. 

% delivery state does not change if not unloading occured 



# % predicate to check whether an unloading action occured in timestep T.
# delivered(X, T) :- delivery(X, N, T), do(_, T, unload(X)), truck(_, T, X, _, _).
# delivery(X, N, T + 1) :- delivery(X, N, T), do(_, T, A), not A = unload(X), not delivered(X, T).


% time step
% truck location
% truck charging level
% truck load level
% warehouse load level
% delivery point demand




% ========== CONSTRAINT ACTIONS ==========

% helpful literals 
% truck(truck id, time step, location, load level, charge level).
% warehouse_state(warehouse point, load, time step).
% delivery_state(delivery point, demand, time step)

% ==== move contraints ====
% cannot move when no battery left
:- do(T, ID, move_to(_)), truck(ID, T, _, _, B), B < 1.

% cannot swap
:- do(T, ID, move_to(Y)), do(T, ID2, move_to(X)), edge(X, Y), edge(Y, X), ID != ID2.

% cannot move from X if not on X in time step
:- do(T, ID, move_to(Y)), truck(ID, T, X2, _, _), edge(X, Y), X != X2.

% ==== load contraints ====
% cannot load when no package at warehouse
:- do(T, ID, load_package), warehouse_state(X, N, T), truck(ID, T, X, _, _), N < 1.

% cannot load when package on the truck already reached it capacity
:- do(T, ID, load_package), truck(ID, T, _, L, _), truck_capacity(_, ML), L >= ML.

% cannot load at not warehouse 
:- do(T, ID, load_package), truck(ID, T, X, _, _), not warehouse_point(X).

% ==== unload contraints ====
% cannot unload when no package on the truck 
:- do(T, ID, unload_package), truck(ID, T, _, L, _), L < 1.

% cannot unload when no demand at delivery point
:- do(T, ID, unload_package), truck(ID, T, X, _, _), delivery_state(X, D, T), D < 1.

% cannot unload at not delivery point
:- do(T, ID, unload_package), truck(ID, T, X, _, _), not delivery_point(X).

% ==== charge contraints ====
% cannot charge at not charging point
:- do(T, ID, charge), truck(ID, T, X, _, _), not charging_point(X).

% cannot overcharge
:- do(T, ID, charge), truck(ID, T, _, _, B), truck_charge_capacity(ID, MB), B > MB.

% ==== singularity contraints ====
% cannot have more than one truck at a node at a time
:- truck(ID, T, X, _, _), truck(ID2, T, X, _, _), ID != ID2.


% ========== GOAL REACHED ==========
goal_reached(T) :-  delivery_state(_, D, T), D < 1, truck(ID, T, X, L, _), L < 1, charging_point(X).
:- not goal_reached(T).


% ========== OPTIMIZATION ==========
% symmetry breaking
:- do(T, ID, move_to(Y)), do(T+1, ID, move_to(X)), edge(X, Y). 
% wait at charging point most 
