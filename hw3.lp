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
action(load_package(X), ID) :- truck(ID, _, X, _, _). 
action(unload_package(X), ID) :- truck(ID, _, X, _, _).
action(charge, ID) :- truck(ID, _, _, _, _).


% ========== SEQUENCE OF ACTIONS ==========
% Generate sequence of actions for each truck at each time step.
1 { do(T, ID, A) : action(A, ID) } 1 :- time(T), truck(ID, _, _, _, _), T < t.


% ========== SUBSEQUENT CHANGE AFTER ACTIONS ==========
% after (truck) wait
truck(ID, T + 1, X, L, C) :- truck(ID, T, X, L, C), do(T, ID, wait).

% after (truck) move
truck(ID, T + 1, Y, L, C - 1) :- truck(ID, T, X, L, C), do(T, ID, move_to(Y)).

% after (truck) load package
truck(ID, T + 1, X, L + 1, C) :- truck(ID, T, X, L, C), do(T, ID, load_package(X)).
warehouse_state(X, WL - 1, T + 1) :- warehouse_state(X, WL, T), do(T, _, load_package(X)), truck(_, T, X, _, _).

% after (truck) unload package
truck(ID, T + 1, X, L - 1, C) :- truck(ID, T, X, L, C), do(T, ID, unload_package(X)).
delivery_state(X, D - 1, T + 1) :- delivery_state(X, D, T), do(T, _, unload_package(X)), truck(_, T, X, _, _).

% after (truck) charge
truck(ID, T + 1, X, load, C + 1) :- truck(ID, T, X, load, C), do(T, ID, charge).

% warehouse state does not change if not loading occured
loaded(X, T) :- warehouse_state(X, _, T), do(T, _, load_package(X)), truck(_,T, X, _, _).
warehouse_state(X, WL, T + 1) :- warehouse_state(X, WL, T), do(T, _, A), not A = load_package(X), not loaded(X, T).

% delivery state does not change if not unloading occured 
delivered(X, T) :- delivery_state(X, _, T), do(T, _, unload_package(X)), truck(_,T, X, _, _).
delivery_state(X, D, T + 1) :- delivery_state(X, D, T), do(T, _, A), not A = unload_package(X), not delivered(X, T).


% ========== CONSTRAINT ACTIONS ==========

% helpful literals 
% truck(truck id, time step, location, load level, charge level). ID, T, X, L, C 
% warehouse_state(warehouse point, load, time step). N, WL, T
% delivery_state(delivery point, demand, time step). N, D, T

% ==== move contraints ====
% cannot move when no battery left
:- do(T, ID, move_to(_)), truck(ID, T, _, _, C), C < 1.

% cannot swap
:- do(T, ID, move_to(Y)), do(T, ID2, move_to(X)), edge(X, Y), edge(Y, X), ID != ID2.

% cannot move from X if not on X in time step
:- do(T, ID, move_to(Y)), truck(ID, T, X2, _, _), edge(X, Y), X != X2.

% ==== load contraints ====
% cannot load when no package at warehouse
:- do(T, ID, load_package(X)), warehouse_state(X, WL, T), truck(ID, T, X, _, _), WL < 1.

% cannot load when package on the truck already reached it capacity
:- do(T, ID, load_package(X)), truck(ID, T, X, L, _), truck_capacity(_, ML), L >= ML.

% cannot load at not warehouse 
% DIFFERENT WAY TO WRITE THIS CONSTRAINT
% :- do(T, ID, load_package(X)), truck(ID, T, X, _, _), not warehouse_point(X).
:- do(T, ID, load_package(X)), truck(ID, T, X, _, _), warehouse_point(Y), not X = Y.
% loadable(ID, T) :- warehouse_point(X) : truck(ID, T, X, _, _); do(T, ID, load_package(X)).
% :- do(T, ID, load_package(X)), not loadable(ID, T).

% ==== unload contraints ====
% cannot unload when no package on the truck 
:- do(T, ID, unload_package(X)), truck(ID, T, X, L, _), L < 1.

% cannot unload when no demand at delivery point
:- do(T, ID, unload_package(X)), truck(ID, T, X, _, _), delivery_state(X, D, T), D < 1.

% cannot unload at not delivery point 
% DIFFERENT WAY TO WRITE THIS CONSTRAINT
% :- do(T, ID, unload_package(X)), truck(ID, T, X, _, _), not delivery_point(X).
:- do(T, ID, unload_package(X)), truck(ID, T, X, _, _), delivery_point(Y), not X = Y.
% deliverable(ID, T) :- delivery_point(X) : truck(ID, T, X, _, _); do(T, ID, unload_package(X)).
% :- do(T, ID, unload_package(X)), not deliverable(ID, T).


% ==== charge contraints ====
% cannot charge at not charging point 
% DIFFERENT WAY TO WRITE THIS CONSTRAINT
% :- do(T, ID, charge), truck(ID, T, X, _, _), not charging_point(X).
:- do(T, ID, charge), truck(ID, T, X, _, _), charging_point(Y), not X = Y.
% chargable(ID, T) :- charging_point(X) : truck(ID, T, X, _, _); do(T, ID, charge).
% :- do(T, ID, charge), not chargable(ID, T).

% cannot overcharge
:- do(T, ID, charge), truck(ID, T, _, _, C), truck_charge_capacity(ID, MC), C > MC.

% ==== singularity contraints ====
% cannot have more than one truck at a node at a time
:- truck(ID, T, X, _, _), truck(ID2, T, X, _, _), ID != ID2.


% ========== GOAL REACHED ==========
% goal reached if all demands are met, all trucks are empty and all trucks are at a charging point
goal_reached(T) :-  delivery_state(X, D, T), D < 1 : delivery_point(X); truck(ID, T, X, L, _), L < 1, charging_point(X) : truck_ID(ID).
:- not goal_reached(t).


% ========== OPTIMIZATION ==========
% symmetry breaking
:- do(T, ID, move_to(Y)), do(T+1, ID, move_to(X)), edge(X, Y).
 
% maximise time step at charging point 
all_truck_at_charging_point(T) :- truck(ID, T, X, _, _), charging_point(X) : truck_ID(ID).
#maximize {1, all_truck_at_charging_point(T) : all_truck_at_charging_point(T)}.
