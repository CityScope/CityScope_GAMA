/***
* Name: AutonomousCovidCommunity
* Author: Arno
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model AutonomousCovidCommunity

/* Insert your model definition here */

global{
	bool autonomy;
	float crossRatio;
	bool drawTrajectory;
	int trajectoryLength<-100;
	float trajectoryTransparency<-0.5;
	int nbBuildingPerDistrict<-10;
	int nbPeople<-100;
	float districtSize<-250#m;
	float buildingSize<-40#m;
	geometry shape<-square (1#km);
	file district_shapefile <- file("../includes/AutonomousCities/district.shp");
	//map<string, rgb> buildingColors <- ["residential"::#purple, "shopping"::#cyan, "business"::#orange];
	rgb districtColor <-rgb(225,235,241);
	rgb macroGraphColor<-rgb(245,135,51);
	map<string, rgb> buildingColors <- ["residential"::rgb(168,192,208), "shopping"::rgb(245,135,51), "business"::rgb(217,198,163)];
	map<string, geometry> buildingShape <- ["residential"::circle(buildingSize/2), "shopping"::square(buildingSize) rotated_by 45, "business"::triangle(buildingSize*1.25)];
	
	
	
	
	
	graph<district, district> macro_graph;
	bool drawMacroGraph<-true;
	bool pandemy<-false;
	init{	
		
		create district from:district_shapefile{
			create building number:nbBuildingPerDistrict{
			  shape<-square(20#m);
			  location<-any_location_in(myself.shape*0.9);
			  myself.myBuildings<<self;
			  myDistrict <- myself;
		    }
		}
		create people number:nbPeople{
		  	current_trajectory <- [];
		}
		macro_graph<- graph<district, district>(district as_distance_graph (500#m ));
		do updateSim(autonomy); 
				
		//save district to:"../results/district.shp" type:"shp";
		//save building to:"../results/building.shp" type:"shp"; 
	}


action updateSim(bool _autonomy){
	do updateDistrict(_autonomy);
	do updatePeople(_autonomy);
}

action updatePeople(bool _autonomy){
	if (!_autonomy){
	  ask people{
		myPlaces[0]<-one_of(building where (each.type="residential"));
		myPlaces[1]<-one_of(building where (each.type="shopping"));
		myPlaces[2]<-one_of(building where (each.type="business"));
		my_target<-any_location_in(myPlaces[0]);
		myCurrentDistrict<- myPlaces[0].myDistrict;
	  }	
	}
	else{
	  ask people{
	  	myCurrentDistrict<-one_of(district);
		myPlaces[0]<-one_of(myCurrentDistrict.myBuildings where (each.type="residential"));
		myPlaces[1]<-one_of(myCurrentDistrict.myBuildings where (each.type="shopping"));
		myPlaces[2]<-one_of(myCurrentDistrict.myBuildings where (each.type="business"));
		my_target<-any_location_in(myPlaces[0]);
	  }
	  ask (length(people)*crossRatio) among people{
	  	myCurrentDistrict<-one_of(district);
		myPlaces[0]<-one_of(myCurrentDistrict.myBuildings where (each.type="residential"));
		myCurrentDistrict<-one_of(district);
		myPlaces[1]<-one_of(myCurrentDistrict.myBuildings where (each.type="shopping"));
		myCurrentDistrict<-one_of(district);
		myPlaces[2]<-one_of(myCurrentDistrict.myBuildings where (each.type="business"));
		my_target<-any_location_in(myPlaces[0]);
	  }		
	}
}

action updateDistrict( bool _autonomy){
	if (!_autonomy){
		ask first(district where (each.name = "district0")).myBuildings{
			type<-"residential";
		}
		ask first(district where (each.name = "district1")).myBuildings{
			type<-"shopping";
		}
		ask first(district where (each.name = "district2")).myBuildings{
			type<-"business";
		}
	}
	else{
		ask district{
			ask myBuildings{
				type<-flip(0.3) ? "residential" : (flip(0.3) ? "shopping" : "business");
			}
		}
	}	
}	
}

species district{
	list<building> myBuildings;
	bool isQuarantine<-false;
	aspect default{
		//draw string(self.name) at:{location.x+districtSize*1.1,location.y-districtSize*0.5} color:#white perspective: true font:font("Helvetica", 30 , #bold);
		if (isQuarantine){
			draw shape*1.1 color:rgb(#red,1) empty:true border:#red;
		}
		draw shape color:districtColor border:districtColor-50;
	}
}



species building{
	rgb color;
	string type;
	district myDistrict;
	aspect default{
		draw buildingShape[type] at: location color:buildingColors[type] border:buildingColors[type]-50;
	}
}

species people skills:[moving]{
	list<building> myPlaces<-[one_of(building),one_of(building),one_of(building)];
	point my_target;
	int curPlaces<-0;
	list<point> current_trajectory;
	district myCurrentDistrict;
	district target_district;
	bool go_outside <- false;
	
	reflex move_to_target_district when: target_district != nil {
		if (go_outside) {
			do goto target: myCurrentDistrict.location speed:5.0;
			if (location = myCurrentDistrict.location) {
				go_outside <- false;
				
			}
		} else {
			do goto target: target_district.location  speed:10.0;
			if (location = target_district.location) {
				myCurrentDistrict <- target_district;
				target_district <- nil;
			}
		}
	}
	reflex move_inside_district when: target_district = nil{
	    do goto target:my_target speed:5.0;
    	if (my_target = location){
    		curPlaces<-(curPlaces+1) mod 3;
			building bd <- myPlaces[curPlaces];
			my_target<-any_location_in(bd);
			if (bd.myDistrict != myCurrentDistrict) {
				go_outside <- true;
				target_district <- bd.myDistrict;
			}
		}
		
    }
    
    reflex computeTrajectory{
    	loop while:(length(current_trajectory) > trajectoryLength){
	    		current_trajectory >> first(current_trajectory);
       		}
        	current_trajectory << location;
    }
    
    reflex rnd_move {
    	do wander speed:1.0;
    }
	
	aspect default{
		draw circle(5#m) color:color;
		if(drawTrajectory){
			draw line(current_trajectory) color: rgb(color,trajectoryTransparency);
		}
	}
}

experiment autonomousCity{
	float minimum_cycle_duration<-0.02;
	parameter "Autonomy" category:"Policy" var: autonomy <- "Conventional"  on_change: {ask world{do updateSim(autonomy);}} enables:[crossRatio] ;
	parameter "Cross District Autonomy Ratio:" category: "Policy" var:crossRatio <-0.1 min:0.0 max:1.0 on_change: {ask world{do updateSim(autonomy);}};
	parameter "Trajectory:" category: "Visualization" var:drawTrajectory <-true ;
	parameter "Trajectory Length:" category: "Visualization" var:trajectoryLength <-100 min:0 max:100 ;
	parameter "Trajectory Transparency:" category: "Visualization" var:trajectoryTransparency <-0.5 min:0 max:1.0 ;
	parameter "Draw Macro Graph:" category: "Visualization" var:drawMacroGraph <-false;
	
	
	output {
			
		display GotoOnNetworkAgent type:opengl background:rgb(39,62,78) draw_env:false synchronized:true toolbar:false
		camera_pos: {398.5622,522.9339,1636.0924} camera_look_pos: {398.5622,522.9053,-4.0E-4} camera_up_vector: {0.0,1.0,0.0} 
		
		{
			overlay position: { 0, 25 } size: { 240 #px, 680 #px } background: #black border: #black {				    
		      draw !autonomy ? "Conventional" : "Autonomy" color:#white at:{50,100} font:font("Helvetica", 50 , #bold);
		      loop i from:0 to:length(buildingColors)-1{
				draw buildingShape[buildingColors.keys[i]] empty:false color: buildingColors.values[i] at: {75, 200+i*100};
				draw buildingColors.keys[i] color: buildingColors.values[i] at:  {120, 210+i*100} perspective: true font:font("Helvetica", 30 , #bold);
			  }
			}
			
			species district;
			species building;
			species people;
			
			graphics "macro_graph" {
				if (macro_graph != nil and drawMacroGraph) {
					loop eg over: macro_graph.edges {
						geometry edge_geom <- geometry(eg);
						float w <- macro_graph weight_of eg;
						if(autonomy="Conventional"){
							//draw curve(edge_geom.points[0],edge_geom.points[1], 0.5, 200, 90) width: 10#m color:macroGraphColor;	
						  draw line(edge_geom.points[0],edge_geom.points[1]) width: 10#m color:macroGraphColor;	
						}
						if(autonomy="Autonomy"){
							//draw curve(edge_geom.points[0],edge_geom.points[1], 0.5, 200, 90) width: 2#m color:macroGraphColor;
						  draw line(edge_geom.points[0],edge_geom.points[1]) width: 2#m color:macroGraphColor;	
						}
						
					}

				}
			}
			event["c"] action: {autonomy<-"Conventional";ask world{do updateSim(autonomy);}};
			event["a"] action: {autonomy<-"Autonomy";ask world{do updateSim(autonomy);}};
		}
		
	}
}