/******************************************************************
* This file is part of COMOKIT, the GAMA CoVid19 Modeling Kit
* Relase 1.0, May 2020. See http://comokit.org for support and updates
* 
* An activity that can perform in a building.
* 
* Author:Patrick Taillandier
* Tags: covid19,epidemiology
******************************************************************/

@no_experiment

model CoVid19

import "BuildingIndividual.gaml"

import "../Constants.gaml"

import "Building Spatial Entities.gaml"

import "../../Entities/Biological Entity.gaml"

global {
	action create_activities {
		map<string, list<Room>> rooms_type <- Room group_by each.type;
		sanitation_rooms <- rooms_type[sanitation];
		if (use_sanitation and not empty(sanitation_rooms)) {
			create BuildingSanitation with:[activity_places::sanitation_rooms];
		}

		loop i over: BuildingActivity.subspecies{
			create i;
		}
	}
}

// A "singleton" species that provides the destination for different activities
species BuildingActivity virtual: true {
	list<Room> activity_places;
	
	pair<Room, point> get_destination(BuildingIndividual p) virtual: true;
}

species ActivityLeaveBuilding parent: BuildingActivity {
	pair<Room, point> get_destination(BuildingIndividual p) {
		Room r <- BuildingEntrance closest_to p;
		point pt <- r.location;
		return r::pt; 
	}
}

species ActivityWanderAround parent: BuildingActivity{
	pair<Room, point> get_destination(BuildingIndividual p){
		Room r <- first(Room where (each.shape overlaps p.location));
		point pt <- any_location_in(r);
		return r::pt;
	}
}

// Activities of Doctors
species ActivityGoToOffice parent: BuildingActivity {
	pair<Room, point> get_destination(BuildingIndividual p) {
		Room r <- p.working_place;
		point pt <- p.working_desk = nil ? any_location_in(r):p.working_desk.location;
		return r::pt;
	}
}

species ActivityVisitInpatient parent: BuildingActivity {
	pair<Room, point> get_destination(BuildingIndividual p) {
		Inpatient patient_to_visit <- one_of(Inpatient);
		Room r <- patient_to_visit.assigned_ward;
		geometry area_around_patient <- circle(rnd(1#m, 2#m), patient_to_visit.location); 
		point pt <- any_location_in(inter(r, area_around_patient));
		return r::pt;
	}
}

species ActivityGoToAdmissionRoom parent: BuildingActivity {
	pair<Room, point> get_destination(BuildingIndividual p) {
		Room r <- one_of(Room where (each.type = ADMISSION_ROOM));
		point pt <- any_location_in(r);
		return r::pt; 
	}
}

species ActivityGoToMeeting parent: BuildingActivity {
	pair<Room, point> get_destination(BuildingIndividual p) {
		Room r <- first(Room where (each.type = MEETING_ROOM));
		point pt <- any_location_in(r);
		return r::pt; 
	}
}

species ActivityGoToInjecting parent: BuildingActivity{
	pair<Room, point> get_destination(BuildingIndividual p) {
		Room r <- first(Room where (each.type = INJECT));
		point pt <- any_location_in(r);
		return r::pt; 
	}
}

species ActivityGoToMinorOperation parent: BuildingActivity{
	pair<Room, point> get_destination(BuildingIndividual p) {
		Room r <- first(Room where (each.type = MINOPERATION));
		point pt <- any_location_in(r);
		return r::pt; 
	}
}

// Activities of Nurses

species ActivityGetMedicine parent: BuildingActivity{
	pair<Room, point> get_destination(BuildingIndividual p){
		Room r <- first(Room where (each.type = MEDICINE));
		point pt <- any_location_in(r);
		return r::pt;
	}
}

// Activities of Staffs

species ActivityWander parent: BuildingActivity{
	pair<Room, point> get_destination(BuildingIndividual p){
		Room r <- any(Room);
		point pt <- any_location_in(r);
		return r::pt;
	}
}

// Activities of inpatients

species ActivityRest parent: BuildingActivity{
	pair<Room, point> get_destination(BuildingIndividual p){
		Room r <- Inpatient(p).assigned_ward;
		point pt <- Inpatient(p).mybed.location;
		return r::pt;
	}
}

species ActivityWanderInWardI parent: BuildingActivity{
	pair<Room, point> get_destination(BuildingIndividual p){
		Room r <- Inpatient(p).assigned_ward;
		point pt <- any_location_in(r);
		return r::pt;
	}
}

// Activities of outpatients

// Activities of caregivers
species ActivityTakeCare parent: BuildingActivity{
	pair<Room, point> get_destination(BuildingIndividual p){
		Room r <- Caregivers(p).sicker.assigned_ward;
		geometry around_sicker <- circle(rnd(1#m, 2#m), Caregivers(p).sicker.mybed.location);
		point pt <- any_location_in(inter(around_sicker, r));
		return r::pt;
	}
}

species ActivityWait parent: BuildingActivity{
	pair<Room, point> get_destination(BuildingIndividual p){
		Room r <- first(Room where (each.type = HALL));
		point pt;
		if(!empty(BenchWait where (each.is_occupied = false))){
			p.benchw <- any(BenchWait where (each.is_occupied = false));
			p.benchw.is_occupied <- true;
			pt <- p.benchw.location;
		}
		else{
			pt <- any_location_in(r);
		}		
		return r::pt;
	}
}

species ActivityWanderInWardC parent: BuildingActivity{
	pair<Room, point> get_destination(BuildingIndividual p){
		Room r <- Caregivers(p).sicker.assigned_ward;
		point pt <- any_location_in(r);
		return r::pt;
	}
}



// Activities of interns

species ActivityFollow parent: BuildingActivity{
	pair<Room, point> get_destination(BuildingIndividual p){
		Room r <- p.current_room;
		point pt <- p.location;
		return r::pt;
	}
}


species BuildingSanitation parent: BuildingActivity {
	pair<Room, point> get_destination(BuildingIndividual p) {
		Room r;
		if flip(0.3) {
			r <- shuffle(activity_places) with_min_of length(first(each.entrances).people_waiting);
		} else {
			r <- activity_places closest_to p;
		}
		point pt <- any_location_in(r);
		return r::pt;
	}
}
