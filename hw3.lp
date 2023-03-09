% TIME STEPS
#const t=40. 
time(1..t).


% REPRESENT THE INPUT
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

% Represent the trucks with truck_ID/1.
truck_ID(1; 2).
% truck_capacity(truck id, load capacity).
truck_capacity(1, 1).
truck_capacity(2, 1).
% truck_charge_capacity(truck id, charge capacity).
truck_charge_capacity(1, 10).
truck_charge_capacity(2, 10).


% INITIAL STATE
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


% ACTIONS
action(wait, ID) :- truck(ID, _, _, _, _).
action(move_to(Y), ID) :- truck(ID, _, X, _, _), edge(X, Y).
action(load_package, ID) :- truck(ID, _, _, _, _). 
action(unload_package, ID) :- truck(ID, _, _, _, _).
action(charge, ID) :- truck(ID, _, _, _, _).

% Generate sequence of actions for each truck at each time step.
1 { do(T, ID, A) : action(A, ID) } 1 :- time(T), truck(ID, _, _, _, _), T < t.

% Subsequent state after performing action.
% wait
truck(ID, time_step + 1, location, load, charge) :- truck(ID, time_step, location, load, charge), do(time_step, ID, wait).
% move_to
truck(ID, time_step + 1, to_location, load, charge - 1) :- truck(ID, time_step, from_location, load, charge), do(time_step, ID, move_to(to_location)).
% load_package
truck(ID, time_step + 1, location, load + 1, charge) :- truck(ID, time_step, location, load, charge), do(time_step, ID, load_package).
warehouse_state(warehouse_point, load - 1, time_step + 1) :- warehouse_state(warehouse_point, load, time_step), do(time_step, ID, load_package).
% unload_package REVIEW THIS
truck(ID, time_step + 1, location, load - 1, charge) :- truck(ID, time_step, location, load, charge), do(time_step, ID, unload_package(location)).
delivery_state(delivery_point, demand - 1, time_step + 1) :- delivery_state(delivery_point, demand, time_step), do(time_step, ID, unload_package(delivery_point)).
% charge
truck(ID, time_step + 1, location, load, charge_capacity) :- truck(ID, time_step, location, load, charge), do(time_step, ID, charge).
