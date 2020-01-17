//Sixth refinement of Adaptive Exterior Light and Speed Control System
//Setting and modifying desired speed - 
//Cruise control - Speed limit - Traffic sign detection
//from SCS-1 to SCS-17
//from SCS-29 to SCS-35
//from SCS-36 to SCS-39

asm CarSystem006
import ../StandardLibrary
import ../CTLlibrary

signature:
	// DOMAINS
	enum domain SCSLever = {DOWNWARD5_SCS | UPWARD5_SCS | DOWNWARD7_SCS | UPWARD7_SCS | NEUTRAL | FORWARD_SCS | BACKWARD_SCS | HEAD} // Cruise control lever positions
	enum domain KeyPosition = {NOKEYINSERTED | KEYINSERTED | KEYINIGNITIONONPOSITION} // Key state
	enum domain CruiseControlMode = {CCM0 | CCM1 | CCM2}
	//CCM0: cruise control disabled
	//CCM1: cruise control active
	//CCM2: adaptive cruise control active
	
	enum domain SpeedLimitSignDetection = {UNLIMITED | SIGNDETECTED | NOSIGNDETECTED}
	domain CurrentSpeed subsetof Integer // Speed
	domain BrakePedal subsetof Integer // Deflection of the brake pedal
//====================================	
	domain GasPedalPerc subsetof Integer // Deflection of the gas pedal in percentage
	// FUNCTIONS
	
	//Parameters setted initially

	monitored cruiseControlMode: CruiseControlMode // State of cruise control
	monitored sCSLever: SCSLever // Position of the Cruise control lever
	controlled sCSLeve_Previous: SCSLever // Position of the Cruise control lever in previous state 
	//-- sCSLeve_Previous (senza r perchè quando traduce in model checker la vede come regola e dice che non la trova)
	monitored currentSpeed: CurrentSpeed // Current speed of the vehicle
	monitored keyState: KeyPosition // Position of the key
	controlled keyState_Previous: KeyPosition // Position of the key in the previous state
	controlled setVehicleSpeed: CurrentSpeed // Cruise control speed 
	controlled desiredSpeed: CurrentSpeed // Desired speed 
	monitored brakePedal: BrakePedal //It is discritezed 0 - 0°, 225 - 45° Resolution 0.2°
	monitored passed1Sec: Boolean // Is 1 second passed?
	monitored passed2Sec: Boolean // Are 2 seconds passed?
	controlled passed2SecYes: Boolean // Are 2 seconds passed?
	monitored accelerationUserHighCruiseControl: Boolean // User acceleration is higher than cruise control
//====================================			
	controlled orangeLed: Boolean //The orange led is on (true) or off (false)
	monitored gasPedal: GasPedalPerc //Gas pedal value in percentage
	controlled speedLimitActive: Boolean //speedLimiter is running
	controlled speedLimitSpeed: CurrentSpeed //Limit speed
	controlled speedLimitTempDeacti: Boolean //speedLimiter is temporarily deactivated
	monitored detectedTrafficSign: SpeedLimitSignDetection //Type of signed recognized
	monitored speedLimitDetected: CurrentSpeed //Speed detected when traffic sign detection is active
	//monitored setSpeedLimitManually: Boolean //Set speed limit manually or automaticcly using traffic sign detection
	monitored trafficSignDetectionOn: Boolean // Traffic sign detector is on
	
	derived engineOn: Boolean // Depending on keyState engineOn is true or false
	derived engineOn_Previous: Boolean // Depending on keyState engineOn is true or false
//====================================	
	derived manualSpeed: Boolean // True if user changes desired speed manually	
	
definitions:	
	//NOTE: The domain has been reduced because of MA -> 0..5000
	domain CurrentSpeed = {0..300}
	//1km/h = 10 unità
	//NOTE: The domain has been reduced because of MA -> 0..255
	domain BrakePedal = {0..2} //res 0.2° 0° - 45° -> 1° = 5 unità 
//====================================		
	domain GasPedalPerc = {0..100}
	
	// FUNCTION DEFINITIONS
	
	//Engine state is determined by KeyPosition value. If the key is on the engine is on, otherwise is off
	function engineOn =
		(keyState = KEYINIGNITIONONPOSITION)
		
	function engineOn_Previous =
		(keyState_Previous = KEYINIGNITIONONPOSITION)
//====================================
//It is true if user changes desired speed manually	
	function manualSpeed = 
		(sCSLever = UPWARD5_SCS or sCSLever = UPWARD7_SCS or sCSLever = DOWNWARD5_SCS or sCSLever = DOWNWARD7_SCS)
	
	
	// RULE DEFINITIONS
	
	//SCS-2 SCS-3
	macro rule r_SCSLeverForward = 
		if (sCSLever = FORWARD_SCS or sCSLever = HEAD) then //Guard changed
			if (currentSpeed < 200) then
				if (desiredSpeed = 0) then 
					setVehicleSpeed := 0
				else
					setVehicleSpeed := desiredSpeed
				endif
			else
				if (desiredSpeed = 0) then
					par
						setVehicleSpeed := currentSpeed
						desiredSpeed := currentSpeed
					endpar
				else
					setVehicleSpeed := desiredSpeed
				endif
			endif
		endif
	
	macro rule r_UpwardDownward5EqualSpeed =
		par	
			if (sCSLever = UPWARD5_SCS) then
				desiredSpeed := setVehicleSpeed + 10 //desired speed increased by 1 km/h
			endif
			if (sCSLever = DOWNWARD5_SCS) then
				desiredSpeed := setVehicleSpeed - 10 //desired speed increased by 1 km/h
			endif
		endpar
		
	macro rule r_UpwardDownward5 ($speed in CurrentSpeed) =
		par	
			if (sCSLever = UPWARD5_SCS) then
				$speed := $speed + 10 //desired speed increased by 1 km/h
			endif
			if (sCSLever = DOWNWARD5_SCS) then
				$speed := $speed - 10 //desired speed increased by 1 km/h
			endif
		endpar
	
	macro rule r_UpwardDownward7EqualSpeed =
		par	
			if (sCSLever = UPWARD7_SCS) then
				desiredSpeed := setVehicleSpeed + (100-(setVehicleSpeed mod 100)) //desired speed increased to the next ten's place
			endif
			if (sCSLever = DOWNWARD7_SCS) then
				if (setVehicleSpeed mod 100 = 0) then
					desiredSpeed := setVehicleSpeed - 100 //desired speed decreased to the next ten's place
				else
					desiredSpeed := setVehicleSpeed - (setVehicleSpeed mod 100)
				endif
			endif
		endpar	
		
	macro rule r_UpwardDownward7 ($speed in CurrentSpeed) =
		par	
			if (sCSLever = UPWARD7_SCS) then
				$speed := $speed + (100-($speed mod 100)) //desired speed increased to the next ten's place
			endif
			if (sCSLever = DOWNWARD7_SCS) then
				if ($speed mod 100 = 0) then
					$speed := $speed - 100 //desired speed decreased to the next ten's place
				else
					$speed := $speed - ($speed mod 100)
				endif
			endif
		endpar	
		
	//SCS-4 SCS-5 SCS-6
	macro rule r_setDesiredSpeed = 
		if (setVehicleSpeed != 0) then
		//Lever has different value from previous state
			if (sCSLeve_Previous != sCSLever) then 
				par
					//SCS-4 //SCS-6
					r_UpwardDownward5[setVehicleSpeed] 
					//If CCM2 and desired speed is not euqal to target speed, change desired speed starting from target speed
					if (cruiseControlMode = CCM2 and (desiredSpeed != setVehicleSpeed)) then
						r_UpwardDownward5EqualSpeed[] 
					else
						r_UpwardDownward5[desiredSpeed] 
					endif
					//SCS-5 //SCS-6
					r_UpwardDownward7[setVehicleSpeed] 
					if (cruiseControlMode = CCM2 and (desiredSpeed != setVehicleSpeed)) then
						r_UpwardDownward7EqualSpeed[] 
					else
						r_UpwardDownward7[desiredSpeed] 
					endif
					//SCS-12 SCS-17
					if (sCSLever = BACKWARD_SCS) then
						setVehicleSpeed := 0
					endif
				endpar
			endif
		endif
		
	macro rule r_setVehicleSpeedLongLeverPress = 
		//SCS-7 SCS-8 SCS-9 SCS-10
		if (setVehicleSpeed != 0) then
			if (sCSLeve_Previous = sCSLever and manualSpeed) then 
				if (passed2Sec) then
					par
						//SCS-7 SCS-9
						if (sCSLever = UPWARD5_SCS or sCSLever = DOWNWARD5_SCS) then
							if (passed1Sec) then
								par
									r_UpwardDownward5[setVehicleSpeed] 
									//If CCM2 and desired speed is not euqal to target speed, change desired speed starting from target speed
									if (cruiseControlMode = CCM2 and (desiredSpeed != setVehicleSpeed)) then
										r_UpwardDownward5EqualSpeed[] 
									else
										r_UpwardDownward5[desiredSpeed] 
									endif
								endpar
							endif
						endif
						//SCS-8 SCS-10
						if (sCSLever = UPWARD7_SCS or sCSLever = DOWNWARD7_SCS) then
							if (passed2Sec) then
								par
									r_UpwardDownward7[setVehicleSpeed] 
									if (cruiseControlMode = CCM2 and (desiredSpeed != setVehicleSpeed)) then
										r_UpwardDownward7EqualSpeed[] 
									else
										r_UpwardDownward7[desiredSpeed] 
									endif
								endpar 
							endif
						endif
					endpar
				endif
			endif
		endif
	
	macro rule r_SetModifySpeed = 
		//SCS-1
		if ((not engineOn_Previous) and engineOn) then
			par
				setVehicleSpeed := 0
				desiredSpeed := 0
			endpar
		else
			if (engineOn_Previous and engineOn) then
				par	
					r_SCSLeverForward[] 
					//SCS-11
					if ((sCSLever = UPWARD5_SCS or sCSLever = UPWARD7_SCS or sCSLever = DOWNWARD5_SCS or sCSLever = DOWNWARD7_SCS) and setVehicleSpeed = 0) then
						desiredSpeed := currentSpeed
					endif
					r_setDesiredSpeed[] 
					r_setVehicleSpeedLongLeverPress[] 
				endpar
			endif
		endif
	
	macro rule  r_DesiredSpeedVehicleSpeed =
		if (brakePedal=0) then
			par
				let ($x = currentSpeed) in skip endlet
				if (cruiseControlMode=CCM2) then
					r_SetModifySpeed[] 
				endif
				if (cruiseControlMode=CCM1) then
					//SCS-15
					if (setVehicleSpeed != 0) then
						if (accelerationUserHighCruiseControl) then
							//setVehicleSpeed := 0//Deactivate cruise control
							skip
						else
							r_SetModifySpeed[] 
						endif
					else
						r_SetModifySpeed[] 
					endif
				endif
			endpar
		endif
		
	macro rule r_BrakePedal = 
		if (cruiseControlMode = CCM1 and setVehicleSpeed != 0) then
			//SCS-16
			if (brakePedal != 0) then
				setVehicleSpeed := 0
			endif
		endif
	
	macro rule r_SpeedLimit = 
	//from SCS-29 to SCS-35
		if (speedLimitActive = false) then
			if (sCSLever = HEAD) then
				par
					speedLimitActive := true
					orangeLed := true
				endpar
			endif
		else
			//if ((cruiseControlMode = CCM2 and trafficSignDetectionOn and setSpeedLimitManually) or (cruiseControlMode = CCM1) or (cruiseControlMode = CCM2 and not trafficSignDetectionOn)) then
			//	r_SetModifySpeed[] 
			//endif
			//SCS-35
			if (sCSLever = HEAD or sCSLever = BACKWARD_SCS) then
				par
					speedLimitActive := false
					speedLimitTempDeacti := false
					orangeLed := false
				endpar
			else
				par
					//SCS-33
					if (gasPedal > 90 and not speedLimitTempDeacti) then
						speedLimitTempDeacti := true
					endif
					//SCS-34
					if (gasPedal < 90 and speedLimitTempDeacti) then
						speedLimitTempDeacti := false
					endif
				endpar
			endif
		endif

	macro rule r_TrafficSignDetection = 
		//SCS-36
		//	if (cruiseControlMode = CCM2 and trafficSignDetectionOn and not setSpeedLimitManually) then
		//If traffic sign detection is active, but the user changes the speed manually (SCSLever moved) the speed is modificed by the SCSLever
		if (cruiseControlMode = CCM2 and trafficSignDetectionOn and (not manualSpeed) and brakePedal!=0) then
			//SCS-37
			if (gasPedal = 0) then
				par
				//SCS-39
					if (detectedTrafficSign = UNLIMITED) then
						if (setVehicleSpeed < 1200) then
							setVehicleSpeed := 1200
						endif
					endif
				//SCS-38
					if (detectedTrafficSign = SIGNDETECTED) then
						setVehicleSpeed := speedLimitDetected
					endif
					if (detectedTrafficSign = NOSIGNDETECTED) then
						skip
					endif
				endpar
			endif
		endif
			
	macro rule r_ReadMonitorFunctions = 
		par
			sCSLeve_Previous := sCSLever
			keyState_Previous := keyState
		endpar 
		
			
	// INVARIANTS
	
	
	//PROPERTIES
	
	
	// MAIN RULE
	main rule r_Main =
		par
			r_ReadMonitorFunctions[] 
			r_DesiredSpeedVehicleSpeed[] 
			r_BrakePedal[] 
			r_SpeedLimit[] 
			r_TrafficSignDetection[] 
		endpar 

// INITIAL STATE
default init s0:
	function cruiseControlMode = CCM0
	//Cruise control lever is in NEUTRAL position
	function sCSLeve_Previous = NEUTRAL
	//Key is not inserted
	function keyState_Previous = NOKEYINSERTED
	function setVehicleSpeed = 0
	function desiredSpeed = 0
	function passed2SecYes = false
	function orangeLed = false
	function speedLimitActive = false
	function speedLimitTempDeacti = false