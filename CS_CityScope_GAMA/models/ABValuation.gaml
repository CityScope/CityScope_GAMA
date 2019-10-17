/***
* Name: ABValuation
* Author: crisjf
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model ABValuation

global{
	// Model mode
	bool updateUnitSize<-true;
	bool modeCar <- false;	
	
	// Grid parameters
	int grid_width<-16;
	int grid_height<-16;
	float cell_width<-100.0/grid_width;
	float cell_height<-100.0/grid_height;
	
	int firm_pos_1 <- int(0.5*grid_width);
	
	// Global model parameters
	float rentFarm<- 5.0;
	float buildingSizeGlobal <- 1.2;
	int unitsPerBuilding <- 5; 
	float globalWage <-1.0;
	float wageRatio<-7.0;
	float commutingCost <- 0.35;
	float commutingCostCar <- 0.3;
	float commutingCostCarFixed <- 0.5;
	float landUtilityParameter <- 10.0;
	
	int nAgents <- int(0.95*(unitsPerBuilding)*((grid_width+1)*(grid_height+1)-1));
	
	// Update parameters (non-equilibrium)
	float rentSplit<- 0.75;
	float rentDelta <- 0.05;
	float sizeDelta <- 0.05;
	float randomMoveRate <- 0.001;
	
	// Display parameters
	bool controlBool;
	string firmTypeToAdd<-'low';
	bool firmDeleteMode <- false;
	bool reflexPause<-false;
	
	rgb servicesColor<-rgb('#a50f15');
	rgb manufactoringColor<-rgb('#fc9272');
	
	action change_color 
	{
		write "change color";
	}
	

	reflex update_pop when: (reflexPause=false) {
//		loop while: (length(worker)<nAgents) {
////			Create people
//		}
//		if (length(worker)<nAgents) {
////			Create people
//		}
	}
	
	action create_firm {
		if (firmDeleteMode=false) {
			building toKill<- (building closest_to(#user_location));
			create firm {
				myCity<-one_of(city);
				shape<-square(0.95*cell_width);
				myType<-firmTypeToAdd;
				wage<-wageRatio*globalWage;	
				location <- toKill.location;
				nbWorkers<-0;
			}
			reflexPause<-true;
			ask worker {
				if (myBuilding=toKill) {
					do forceBuildingUpdate;				
				}
			}
			ask toKill {
				do die;
			}
			reflexPause<-false;
		} else {
			if (length(firm)>1) {
				firm toKill<- (firm closest_to(#user_location));
				create building {
					myCity<-one_of(city);
					shape<-square(0.95*cell_width);
				
					rent <- rentFarm;
					buildingSize <- buildingSizeGlobal;
					vacant <- buildingSizeGlobal;
					unitSize <- buildingSizeGlobal/float(unitsPerBuilding);
				
					location <- toKill.location;
				}
				reflexPause<-true;
				ask worker {
					if (myFirm=toKill) {
						do forceFirmUpdate;
					}
				}				
				ask toKill {
					do die;
				}
				reflexPause<-false;
			}
		}
		
	}

	init{
		write "Number of units " +unitsPerBuilding*((grid_width+1)*(grid_height+1)-2);
		write "Number of workers "+nAgents;
		create city {
			maxRent<-rentFarm;
		}
		
		int i<-0;
		int j<-0;
		create building number:((grid_width+1)*(grid_height+1)-1){
			myCity<-one_of(city);
			shape<-square(0.95*cell_width);
			
			rent <- rentFarm;
			buildingSize <- buildingSizeGlobal;
			vacant <- buildingSizeGlobal;
			unitSize <- buildingSizeGlobal/float(unitsPerBuilding);
			
			location <- {cell_width*i,cell_height*j};
			i<-((i+1) mod (grid_width+1));			
			if (i=0) {
				j<-j+1;
			}
			if (i=firm_pos_1 and j=firm_pos_1) {
				i<-((i+1) mod (grid_width+1));
			}
		}
		
		create firm {
			myCity<-one_of(city);
			shape<-square(0.95*cell_width);
			myType<-'high';
			wage<-globalWage;
			location <- {cell_width*firm_pos_1,cell_height*firm_pos_1};
			nbWorkers<-0;
		}
		
		create worker number:nAgents {
			myFirm <- one_of(firm);
			myFirm.nbWorkers <- myFirm.nbWorkers+1;
			
			list<building> possibleBuildings<-(building where (each.vacant>0));
			
			if (length(possibleBuildings)!=0) {
				myBuilding <- one_of(possibleBuildings);
				myBuilding.vacant <- myBuilding.vacant-myBuilding.unitSize;
			} else {
				
			}
			location <- any_location_in(myBuilding);
		}
		
		ask one_of(city) {
			do updateCityParams;
		}
			
	}
	
}

species city {
	float maxRent;
	float maxDensity;
	float maxWage;
	float maxSupportedDensity;
	
	action updateCityParams{
		maxRent <- max(building collect each.rent);
		maxDensity <- max(building collect each.density);
		maxSupportedDensity <- max(building collect each.supportedDensity);
		maxWage <- max(firm collect each.wage);
	}
	
	reflex update when: (reflexPause=false) {
		do updateCityParams;
	}
}

species firm{
	int nbWorkers;
	string myType;
	float wage;
	city myCity;

	aspect base{
		draw shape color:#blue;
	}
	
	reflex updateWage when: (reflexPause=false) {
		if (myType='high') {
			wage <- wageRatio*globalWage;
		} else {
			wage <- globalWage;
		}
	}
	
	aspect threeD {
		if (myType='high') {
			color <- servicesColor;
		} else {
			color <- manufactoringColor;
		}
		draw shape color: color depth: 20;
	}
	aspect twoD {
		if (myType='high') {
			color <- servicesColor;
		} else {
			color <- manufactoringColor;
		}
		draw shape color: color;
	}
}

species building {
	city myCity;
	float buildingSize;
	
	float rent;
	float unitSize;
	float vacant;
	
	float density;
	float supportedDensity;
	float heightValue;
	
	reflex lowerRent when: (reflexPause=false) {  
		if (vacant>=unitSize) {
			rent <- rent-rentDelta*rent;
			if (rent<rentFarm){
				rent <-rentFarm;
			}
		} 
		if (rent<rentFarm){
			rent <-rentFarm;
		}
	}
	
	reflex raiseUnitSize when: (updateUnitSize=true) {
		float newUnitSize;
		newUnitSize <- (1.0+sizeDelta)*unitSize;
		if (vacant>=(1.0+sizeDelta)*(buildingSize-vacant) and newUnitSize<=buildingSize) {
			vacant <- buildingSize-(1.0+sizeDelta)*(buildingSize-vacant); 
			unitSize <- newUnitSize;
		}
	}
	
	reflex updateParameters {
		density <- float(int((buildingSize-vacant)/(unitSize)));
		if (density<0) {
			density<-0.0;
		}
		
		supportedDensity <- buildingSize/unitSize;
		if (supportedDensity=0) {
			heightValue<-0.0;
		} else {
			heightValue<-supportedDensity;
		}
		heightValue<-0.3*heightValue;
		
	}

	aspect density_aspect {
		int colorValue <- int(220-220*density/myCity.maxDensity);
		draw shape color: rgb(colorValue,colorValue,colorValue);
	}
	
	aspect threeD{
		int colorValue<- 35+ int(220-220*log(rent+1.0)/log(myCity.maxRent+1.0));
		draw shape color: rgb(colorValue,colorValue,colorValue) depth: heightValue;
    }
    
    aspect twoD{
		int colorValue<- 35+ int(220-220*log(rent+1.0)/log(myCity.maxRent+1.0));
		draw shape color: rgb(colorValue,colorValue,colorValue);
    }
	
}

species worker {
	building myBuilding;
	firm myFirm;
	bool useCar;
	float currentUtility;

	float myUtility (building referenceBuilding, firm referenceFirm, bool useCarLocal, float myUnitSize<-nil) {
		float utility;
		float workDistance <- (referenceBuilding distance_to referenceFirm);
		if (myUnitSize=nil){
			utility <- referenceFirm.wage - commutingValue(workDistance,useCarLocal) - referenceBuilding.rent * referenceBuilding.unitSize + landUtilityParameter * log(referenceBuilding.unitSize);
		} else {
			utility <- referenceFirm.wage - commutingValue(workDistance,useCarLocal) - referenceBuilding.rent * myUnitSize + landUtilityParameter * log(myUnitSize);
		}
		return utility;
	}
	
	float commutingValue (float distance, bool useCarLocal) {
		float outValue;
		if (modeCar=true) {
			if (useCarLocal=false){
				outValue <- commutingCost*distance;
			} else {
				outValue <- commutingCostCarFixed+commutingCostCar*distance;
			}
		} else {
			outValue <- commutingCost*distance;
		}
		return outValue; 
	}
	
	action checkMyStuff {
		if (myFirm=nil){
			myFirm <- one_of(firm);
		}
		if (myBuilding=nil){
			myBuilding <- one_of(building);
		}
	}
	
	action forceFirmUpdate {
		bool updateSuccess<-false;
		firm newFirm;
		loop while: (updateSuccess=false) {
			newFirm <- one_of(firm);
			if (newFirm!=myFirm) {
				do attemptFirmUpdate(newFirm);
				updateSuccess<-true;
			} 
		}
	}
	
	action forceBuildingUpdate {
		bool updateSuccess<-false;
		building newBuilding;
		
		loop while: (updateSuccess=false) {
			newBuilding <- one_of(building);
			if (newBuilding!=myBuilding) {
				if (newBuilding.vacant>=newBuilding.unitSize) {
					myBuilding.vacant <- myBuilding.vacant + myBuilding.unitSize;
					newBuilding.vacant <- newBuilding.vacant - newBuilding.unitSize;
					myBuilding <- newBuilding;
					location <- any_location_in(myBuilding);
					updateSuccess<-true;
				}
			} 
		}
	}
		
	action attemptFirmUpdate (firm newFirm) {
		myFirm.nbWorkers<-myFirm.nbWorkers-1;
		newFirm.nbWorkers<-newFirm.nbWorkers+1;
		myFirm <- newFirm;
	}
	
	action attemptBuildingUpdate (building newBuilding, float utilityChange<-0.0) {
		if (newBuilding.vacant<newBuilding.unitSize) {
			if (utilityChange!=0) {
				newBuilding.rent <- newBuilding.rent + rentSplit * utilityChange/newBuilding.unitSize;
			}
		} else {
			myBuilding.vacant <- myBuilding.vacant + myBuilding.unitSize;
			newBuilding.vacant <- newBuilding.vacant - newBuilding.unitSize;
			myBuilding <- newBuilding;
			location <- any_location_in(myBuilding);
		}
	}
	
	reflex updateUtility when: (reflexPause=false) {
		do checkMyStuff;
		float utility<-myUtility(myBuilding,myFirm,useCar);
		currentUtility<-utility;
	}
	
	reflex updateCommutingMode when: (reflexPause=false) {
		do checkMyStuff;
		float utilityCar<-myUtility(myBuilding,myFirm,true);
		float utilityNoCar<-myUtility(myBuilding,myFirm,false);
		if (utilityCar>utilityNoCar){
			useCar<-true;
		} else {
			useCar<-false;
		}
	}
	
	reflex updateBuilding when: (reflexPause=false) {
		do checkMyStuff;
		float utility <- myUtility(myBuilding,myFirm,useCar);
		building possibleBuilding <- one_of(building);
		float possibleUtility <- myUtility(possibleBuilding,myFirm,useCar);
		float utilityChange <- possibleUtility-utility;
		
		if (utilityChange>0.0){
			do attemptBuildingUpdate(possibleBuilding, utilityChange);
		}
	}
	
	reflex updateWork when: (reflexPause=false) {	
		do checkMyStuff;	
		float utility <- myUtility(myBuilding,myFirm,useCar);
		firm possibleFirm <- one_of(firm);
		float possibleUtility<- myUtility(myBuilding,possibleFirm,useCar);
		if (possibleUtility>utility){
			do attemptFirmUpdate(possibleFirm);
		}
	}
	
	reflex updateBuildingRandom when: (reflexPause=false) {
		if (rnd(1.0)<randomMoveRate) {
			building possibleBuilding <- one_of(building);
			do attemptBuildingUpdate(possibleBuilding);
		}
	}
	
	reflex updateWorkRandom when: (reflexPause=false) {
		if (rnd(1.0)<randomMoveRate) {
			firm possibleFirm;
			possibleFirm <- one_of(firm);
			do attemptFirmUpdate(possibleFirm);
		}
	}
	
	reflex updateUnitSize when: (updateUnitSize=true and reflexPause=false) {
		float utility;		
		float newUnitSizem;
		float newUnitSizep;
		float possibleUtilitym;
		float possibleUtilityp;
		bool updateFlag<-true;
		
		loop while: (updateFlag=true) {
			updateFlag<-false;
			
			do checkMyStuff;
			utility <- myUtility(myBuilding,myFirm,useCar);
			newUnitSizem <- (1.0-sizeDelta)*myBuilding.unitSize;
			newUnitSizep <- (1.0+sizeDelta)*myBuilding.unitSize;
			
			possibleUtilitym <- myUtility(myBuilding,myFirm,useCar,newUnitSizem);
			possibleUtilityp <- myUtility(myBuilding,myFirm,useCar,newUnitSizep);
			
			if (possibleUtilityp>utility and myBuilding.vacant>=(1.0+sizeDelta)*(myBuilding.buildingSize-myBuilding.vacant) and newUnitSizep<=myBuilding.buildingSize) {
				myBuilding.vacant <- myBuilding.buildingSize-(1.0+sizeDelta)*(myBuilding.buildingSize-myBuilding.vacant); 
				myBuilding.unitSize <- newUnitSizep;
				updateFlag<-true;
			} else {
				if (possibleUtilitym>utility) {
					myBuilding.vacant <- myBuilding.buildingSize-(1.0-sizeDelta)*(myBuilding.buildingSize-myBuilding.vacant); 
					myBuilding.unitSize <- newUnitSizem;
					updateFlag<-true;
				}
			}
			updateFlag<-false; // Force exit
		}
	}
	
	aspect threeD {
		int colorValue <- int(30+220*myFirm.wage/myFirm.myCity.maxWage);
		draw sphere(1.0) color: rgb(0,0,colorValue);
	}
	
	aspect base{
		draw circle(0.25) color:#green;					
	}
	
	aspect wage_aspect {
		if (myFirm.myType='high') {
			color<-rgb('#08519c');
		} else {
			color<-rgb('#6baed6');
		}
		draw circle(0.25) color: color;
	}
	
	aspect threeD {
		if (myFirm.myType='high') {
			color<-rgb('#08519c');
		} else {
			color<-rgb('#6baed6');
		}
		draw cylinder(0.2,0.75) at_location {location.x,location.y,rnd(myBuilding.heightValue)} color: color;	
	}
	
}

grid cell width: grid_width height: grid_height {
	aspect dark_aspect {
		draw shape color: #black;
	}
}

experiment ABValuationDemo type: gui autorun:true{
	parameter "Commuting cost" var: commutingCost min: 0.0 max: 1.0 step: 0.05; 
	output { 
		display map_3D  type:opengl background: #black draw_env: false  toolbar:false fullscreen:1
		camera_pos: {-31.3849,154.8123,60.965} camera_look_pos: {39.7081,49.4125,-9.5042} camera_up_vector: {0.2711,0.4019,0.8746}
		//camera_interaction:false
		{
			species cell aspect: dark_aspect;			
			species worker aspect:threeD;
			species firm aspect: threeD transparency: 0.25;
			species building aspect:threeD transparency: 0.35;
			
			
			event "e" action: {controlBool <- !controlBool;}; //<- Do this in the aspect (aspect++ will allow you to show aspects)

			event mouse_down action: create_firm;
			event "p" action: {if(commutingCost<1){commutingCost<-commutingCost+0.1;}};
			event "m" action: {if(commutingCost>0){commutingCost<-commutingCost-0.1;}};
			event "u" action: {if(wageRatio<10.0){wageRatio<-wageRatio+0.1;}};
			event "e" action: {if(wageRatio>1.0){wageRatio<-wageRatio-0.1;}};
			event "s" action: {updateUnitSize<-!updateUnitSize;};
			event "h" action: {firmTypeToAdd<-'high'; firmDeleteMode<-false;};
			event "l" action: {firmTypeToAdd<-'low'; firmDeleteMode<-false;};
			event "d" action: {firmDeleteMode<-true;};
			
			overlay position: { 5, 5 } size: { 180 #px, 100 #px } background: # black transparency: 0.5 border: #black rounded: true
            {   
            	float y1;
            	draw string("MULTI EMPLOYER HOUSING MARKET SIMULATION") at: { 10#px, 20#px } color: #white font: font("Helvetica", "bold" ,72); 
            	y1<-y1+20#px;
            	draw string("This model represents the effect business and their location can have on housing markets. \n In contracts to site-by-site analysis, this ABM model allows users to understand the impact of multiple employers within a given housing market.") at: { 10#px, 20#px+y1 } color: #white font: font("Helvetica", "bold" ,72); 
            	
            	float y <- 150#px;
            	draw string("Population (Income)") at: { 10#px, y-20#px } color: #white font: font("Helvetica", "bold" ,32);
                draw circle(10#px) at: { 20#px, y } color: rgb('#08519c') border: rgb('#08519c')-25;
                draw string("High") at: { 40#px, y + 4#px } color: #white font: font("Helvetica","plain", 18);
                y <- y + 25#px;
                draw circle(10#px) at: { 20#px, y } color: rgb('#6baed6') border: rgb('#6baed6')-25;
                draw string("Medium") at: { 40#px, y + 4#px } color: #white font: font("Helvetica", 18);
                y <- y + 25#px;
                draw string("Employement (Sector)") at: { 10#px, y } color: #white font: font("Helvetica", "bold" ,32);
                y <- y + 25#px;
                draw square(20#px) at: { 20#px, y } color: servicesColor border: servicesColor-25;
                draw string("Services") at: { 40#px, y + 4#px } color: #white font: font("Helvetica", 18);
                y <- y + 25#px;
                draw square(20#px) at: { 20#px, y } color: manufactoringColor border: manufactoringColor-25;
                draw string("Manufacturing") at: { 40#px, y + 4#px } color: #white font: font("Helvetica", 18);
                
                y <- y + 25#px;
                draw string("Housing (Cost)") at: { 10#px, y } color: #white font: font("Helvetica", "bold" ,32);
                y <- y + 25#px;
                draw square(20#px) at: { 20#px, y } color: rgb(50,50,50) border: rgb(50,50,50)-25;
                draw string("High") at: { 40#px, y + 4#px } color: #white font: font("Helvetica", 18);  
                
                y <- y + 25#px;
                draw square(20#px) at: { 20#px, y } color: #lightgray border: #lightgray-25;
                draw string("Low") at: { 40#px, y + 4#px } color: #white font: font("Helvetica", 18); 
                
                y <- y + 100#px;
                draw string("Comutting Cost") at: { 0#px, y + 4#px } color: #white font: font("Helvetica", 32);
                y <- y + 25#px;
                draw rectangle(200#px,2#px) at: { 50#px, y } color: #white;
                draw rectangle(2#px,10#px) at: { commutingCost*100#px, y } color: #white;

                y <- y + 25#px;
                draw string("Inequality") at: { 0#px, y + 4#px } color: #white font: font("Helvetica", 32);
                y <- y + 25#px;
                draw rectangle(200#px,2#px) at: { 50#px, y } color: #white;
                draw rectangle(2#px,10#px) at: { wageRatio*100#px, y } color: #white;
                
                y <- y + 25#px;
                float x<-0#px;
                draw string("Housing Supply") at: { 0#px + x , y + 4#px } color: #white font: font("Helvetica", 32);
                y <- y + 25#px;
                draw rectangle(200#px,2#px) at: { 50#px, y } color: #white;
                draw rectangle(2#px,10#px) at: { (updateUnitSize ? 0.25 :0.75)*100#px, y } color: #white;
                y<-y+15#px; 
                draw string("     Market Driven        Fixed") at: { 10#px + x , y + 4#px } color: #white font: font("Helvetica", 12);       	          	 
            }

						

		}
		display map_2D  type:opengl background: #black draw_env: false fullscreen:0 toolbar:false
		camera_pos: {14.4668,47.5198,191.0387} camera_look_pos: {14.4668,47.5165,0.0} camera_up_vector: {0.0,1.0,0.0}
		{
			species cell aspect: dark_aspect;			
			species worker aspect:threeD;
			species building aspect:twoD transparency: 0.5;
			species firm aspect: twoD transparency: 0.5;
			
			event "e" action: {controlBool <- !controlBool;}; //<- Do this in the aspect (aspect++ will allow you to show aspects)

			event mouse_down action: create_firm;
			event "p" action: {if(commutingCost<1){commutingCost<-commutingCost+0.1;}};
			event "m" action: {if(commutingCost>0){commutingCost<-commutingCost-0.1;}};
			event "u" action: {if(wageRatio<10.0){wageRatio<-wageRatio+0.1;}};
			event "e" action: {if(wageRatio>1.0){wageRatio<-wageRatio-0.1;}};
			event "s" action: {updateUnitSize<-!updateUnitSize;};
			event "h" action: {firmTypeToAdd<-'high'; firmDeleteMode<-false;};
			event "l" action: {firmTypeToAdd<-'low'; firmDeleteMode<-false;};
			event "d" action: {firmDeleteMode<-true;};
				
			overlay position: { 5, 5 } size: { 180 #px, 100 #px } background: # black transparency: 0.5 border: #black rounded: true

            {   
            	
            	draw string("MULTI EMPLOYER HOUSING MARKET SIMULATION") at: { 10#px, 20#px } color: #white font: font("Helvetica", "bold" ,72);
            	
            	float y <- 150#px;
            	draw string("Population (Income)") at: { 10#px, y-20#px } color: #white font: font("Helvetica", "bold" ,32);
                draw circle(10#px) at: { 20#px, y } color: rgb('#08519c') border: rgb('#08519c')-25;
                draw string("High") at: { 40#px, y + 4#px } color: #white font: font("Helvetica","plain", 18);
                y <- y + 25#px;
                draw circle(10#px) at: { 20#px, y } color: rgb('#6baed6') border: rgb('#6baed6')-25;
                draw string("Medium") at: { 40#px, y + 4#px } color: #white font: font("Helvetica", 18);
                y <- y + 25#px;
                draw string("Employement (Sector)") at: { 10#px, y } color: #white font: font("Helvetica", "bold" ,32);
                y <- y + 25#px;
                draw square(20#px) at: { 20#px, y } color: servicesColor border: servicesColor-25;
                draw string("Services") at: { 40#px, y + 4#px } color: #white font: font("Helvetica", 18);
                y <- y + 25#px;
                draw square(20#px) at: { 20#px, y } color: manufactoringColor border: manufactoringColor-25;
                draw string("Manufacturing") at: { 40#px, y + 4#px } color: #white font: font("Helvetica", 18);
                
                y <- y + 25#px;
                draw string("Housing (Cost)") at: { 10#px, y } color: #white font: font("Helvetica", "bold" ,32);
                y <- y + 25#px;
                draw square(20#px) at: { 20#px, y } color: rgb(50,50,50) border: rgb(50,50,50)-25;
                draw string("High") at: { 40#px, y + 4#px } color: #white font: font("Helvetica", 18);  
                
                y <- y + 25#px;
                draw square(20#px) at: { 20#px, y } color: #lightgray border: #lightgray-25;
                draw string("Low") at: { 40#px, y + 4#px } color: #white font: font("Helvetica", 18); 
                
                y <- y + 100#px;
                draw string("Comutting Cost") at: { 0#px, y + 4#px } color: #white font: font("Helvetica", 32);
                y <- y + 25#px;
                draw rectangle(200#px,2#px) at: { 50#px, y } color: #white;
                draw rectangle(2#px,10#px) at: { commutingCost*100#px, y } color: #white;

                y <- y + 25#px;
                draw string("Inequality") at: { 0#px, y + 4#px } color: #white font: font("Helvetica", 32);
                y <- y + 25#px;
                draw rectangle(200#px,2#px) at: { 50#px, y } color: #white;
                draw rectangle(2#px,10#px) at: { wageRatio*100#px, y } color: #white;
                
                y <- y + 25#px;
                float x<-0#px;
                draw string("Housing Supply") at: { 0#px + x , y + 4#px } color: #white font: font("Helvetica", 32);
                y <- y + 25#px;
                draw rectangle(200#px,2#px) at: { 50#px, y } color: #white;
                draw rectangle(2#px,10#px) at: { (updateUnitSize ? 0.25 :0.75)*100#px, y } color: #white;
                y<-y+15#px; 
                draw string("     Market Driven        Fixed") at: { 10#px + x , y + 4#px } color: #white font: font("Helvetica", 12);  
            }
		}
	}
	
}