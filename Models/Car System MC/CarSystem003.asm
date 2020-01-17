//Second refinement of Adaptive Exterior Light and Speed Control System
//Low Beam headlights and Cornering light
//from ELS-1 to ELS-29
//from ELS-39 to ELS-41
//from ELS-30 to ELS-38

asm CarSystem003
import ../StandardLibrary
import ../CTLlibrary

signature:
	// DOMAINS
	enum domain MarketCode = {USA | CANADA | EU} // Name of the market for which the car is to be built
	enum domain PitmanArmUpDown = {DOWNWARD5 | DOWNWARD5_LONG| UPWARD5 | UPWARD5_LONG | DOWNWARD7 | UPWARD7 | NEUTRAL_UD} // Pitman arm positions - vertical position
	// DOWNWARD5 -> move pitman arm for less than 0.5 seconds DOWNWARD5_LONG -> move pitman arm for more than 0.5 seconds 
	enum domain KeyPosition = {NOKEYINSERTED | KEYINSERTED | KEYINIGNITIONONPOSITION} // Key state
	enum domain PulseRatio = {NOPULSE | PULSE11 | PULSE12} //* Pulse ratio of direction lights
	enum domain TailLampStatus = {FIX | BLINK} //* Tail lamp status, blink if it is USA or CANADA car and turns left/right, is fixed otherwise
	enum domain LightSwitch = {OFF | AUTO | ON} // Light rotary switch positions
	enum domain LeftRight = {LEFT | RIGHT}
//====================================	
	enum domain CameraState = {CAMERA_READY | CAMERA_DIRTY | CAMERA_NOTREADY} // Camera state
	enum domain CruiseControlMode = {CCM0 | CCM1 | CCM2}		
	enum domain PitmanArmForthBack = {BACKWARD | FORWARD | NEUTRAL_FB} // Pitman arm positions - horizontal position
   	
	domain LightPercentage subsetof Integer // Light percentage
	domain Brightness subsetof Integer // Brightness domain
	domain CurrentSpeed subsetof Integer // Speed
	domain SteeringAngle subsetof Integer // Steering wheel angle	
	domain BrakePedal subsetof Integer // Deflection of the brake pedal
//====================================	
	domain HighBeamRange subsetof Integer // High beam luminous strenght
	domain HighBeamMotor  subsetof Integer // High beam illumination distance
	//0=65,1=100,2 = 120, 3 = 140, 4 = 160, 5= 180, 6 = 200, 7=220, etc. See table at page 23.
		
	// FUNCTIONS
	
	//Parameters setted initially
	static armoredVehicle: Boolean // The vehicle is armored or not
	static marketCode: MarketCode //Market code
	//Daytime light and ambient light are determined before starting the model and remain unchanged throughout simulation (see web page of ABZ2020)
	static daytimeLight: Boolean // Daytime running light activation. True -> ON, False -> OFF
	static ambientLighting: Boolean // Ambient light activation. True -> ON, False -> OFF
	
	monitored pitmanArmUpDown: PitmanArmUpDown // Position of the pitman arm - vertical position
	controlled pitmanArmUpDown_Buff: PitmanArmUpDown // Save the last position of the pitman arm if something is in execution
	controlled pitmanArmUpDown_RunnReq: PitmanArmUpDown // Save the action running based on pitmanArmUpDown request
	monitored hazardWarningSwitchOn: Boolean // Position of the Hazard Warning Light Switch. True -> ON, False -> OFF
	controlled hazardWarningSwitchOn_Runn: Boolean // Hazard Warning Light Switch is running or not
	controlled hazardWarningSwitchOn_Start: Boolean // Start Hazard Warning Light Switch in the next cycle
	monitored keyState: KeyPosition // Position of the key
	
	controlled blinkLeft: LightPercentage // Direction indicators A_left, B_left and C_left don't blink (0%) or blink with a specific percentage of brightness
	controlled blinkLeftPulseRatio: PulseRatio //* Pulse ratio of left direction indicators
	controlled blinkRight: LightPercentage // Direction indicators A_right, B_right and C_right don't blink (0%) or blink with a specific percentage of brightness
	controlled blinkRightPulseRatio: PulseRatio //* Pulse ratio of right direction indicators
	controlled tailLampLeftFixValue: LightPercentage // Tail lamp left is off (0%) or is on with a specific percentage of brightness
	controlled tailLampLeftBlinkValue: LightPercentage // Tail lamp left is off (0%) or is on with a specific percentage of brightness
	controlled tailLampLeftStatus: TailLampStatus // Tail lamp left status
	controlled tailLampRightFixValue: LightPercentage // Tail lamp right is off (0%) or is on with a specific percentage of brightness
	controlled tailLampRightBlinkValue: LightPercentage // Tail lamp right is off (0%) or is on with a specific percentage of brightness
	controlled tailLampRightStatus: TailLampStatus // Tail lamp right status
	
	monitored threeBlinkingCycle: Boolean // Indicators have flashed for three flashing cycles (true) or less (false)
	
	monitored lightRotarySwitch: LightSwitch // Position of the light rotary switch
	controlled lightRotarySwitchPrevious: LightSwitch // Position of the light rotary switch in the previous state
	monitored brightnessSensor: Brightness // The sensor provides the measured outside brightness 
	monitored reverseGear: Boolean // Reverse gear is engaged (True) or not (False)
	monitored passed30Sec: Boolean // Are 30 seconds passed?
	monitored passed5Sec: Boolean // Are 5 seconds passed?
	monitored passed3Sec: Boolean // Are 3 seconds passed?
	monitored darknessModeSwitchOn: Boolean // Position of the Darkness Switch, available only at armored vehicles. True -> ON, False -> OFF
	monitored currentSpeed: CurrentSpeed // Current speed of the vehicle
	monitored steeringAngle: SteeringAngle // Angle of the steering wheel
	monitored brakePedal: BrakePedal //It is discritezed 0 - 0°, 225 - 45° Resolution 0.2°
		
	controlled lowBeamLeft: LightPercentage // Low beam headlight left is off (0%) or is on with a specific percentage of brightness
	controlled lowBeamRight: LightPercentage // Low beam headlight right is off (0%) or is on with a specific percentage of brightness
	controlled corneringLightLeft: LightPercentage // Cornering light left is off (0%) or is on with a specific percentage of brightness
	controlled corneringLightRight: LightPercentage // Cornering light right is off (0%) or is on with a specific percentage of brightness
	controlled keyState_Previous: KeyPosition // Position of the key in the previous state
	controlled parkingLightON : Boolean //parking light is on
	controlled reverseLight: LightPercentage // Reverse light is off (0%) or is on with a specific percentage of brightness
	controlled brakeLampLeft: LightPercentage // Brake lamp left is off (0%) or is on with a specific percentage of brightness
	controlled brakeLampRight: LightPercentage // Brake lamp right is off (0%) or is on with a specific percentage of brightness 
	controlled brakeLampCenter: LightPercentage // Brake lamp center is off (0%) or is on with a specific percentage of brightness
	controlled brakeLampCenterStatus: TailLampStatus // Brake lamp center is off (0%) or is on with a specific percentage of brightness
//====================================	
	monitored cameraState: CameraState // Camera state: ready, dirty or not ready
	monitored oncomingTraffic: Boolean // Camera signal to detect oncoming vehicles. True -> vehicles oncoming, False -> no vehicles
	monitored pitmanArmForthBack: PitmanArmForthBack // Position of the pitman arm - horizontal position
	monitored cruiseControlMode: CruiseControlMode // State of cruise control
	controlled highBeamOn: Boolean // High beam headlights (left and right) are on (True) or not (False)
	controlled highBeamRange: HighBeamRange // High beam luminous strenght
	controlled highBeamMotor: HighBeamMotor // Control the high beam illumination - 20m step size
	//controlled lightRotarySwitchPrevious: LightSwitch // Position of the light rotary switch in the previous state
	controlled pitmanArmForthBackPrevious: PitmanArmForthBack // Position of the pitman arm - horizontal position - in the previous state
	controlled setVehicleSpeed: CurrentSpeed // Desired speed in case an adaptive cruise control is part of the vehicle
		
	derived turnLeft_RunnReq: Boolean //True if pitmanArmUpDown_RunnReq is in position turn left (DOWNWARD5 or DOWNWARD5_LONG or DOWNWARD7)
	derived turnRight_RunnReq: Boolean //True if pitmanArmUpDown_RunnReq is in position turn right (UPWARD5 or UPWARD5_LONG or UPWARD7)
	derived turnLeft_Buff: Boolean //True if pitmanArmUpDown_Buff is in position turn left (DOWNWARD5 or DOWNWARD5_LONG or DOWNWARD7)
	derived turnRight_Buff: Boolean //True if pitmanArmUpDown_Buff is in position turn right (UPWARD5 or UPWARD5_LONG or UPWARD7)
	derived turnLeft_Mon: Boolean //True if pitmanArmUpDown is in position turn left (DOWNWARD5 or DOWNWARD5_LONG or DOWNWARD7)
	derived turnRight_Mon: Boolean //True if pitmanArmUpDown is in position turn right (UPWARD5 or UPWARD5_LONG or UPWARD7)
	derived tailLampAsIndicator: Boolean //True if the car is sold in USA or CANADA, it does not have a separate direction ndicator at position C	
	derived engineOn: Boolean // Depending on keyState engineOn is true or false
	derived engineOn_Previous: Boolean // Depending on keyState engineOn is true or false
	derived lowBeamLightingOn: Boolean // Low beam lights are on or off
	derived parkingLight: Boolean //Parking light on or off
	derived ambientLightingConditionOn: Boolean // Ambient lighting is available
	derived ambientLightingAvailable: Boolean // Ambient lighting is activated
	//It is obtained by the value assumed by tail lamp in blinking mode and tail lamp as position lamp
	derived tailLampRight: LightPercentage // Tail lamp right is off (0%) or is on with a specific percentage of brightness. 
	derived tailLampLeft: LightPercentage // Tail lamp right is off (0%) or is on with a specific percentage of brightness
	derived brakeIsOn: Boolean //Brake lamps are on
//====================================	
	derived adaptiveHighBeamActivated: Boolean
	derived adaptiveHighBeamDeactivated: Boolean
	derived headlampFlasherActivated: Boolean //Temporary activation of the high beam (without engaging, so-called flasher)
	derived headlampFlasherDeactivated: Boolean
	derived headlampFixedActivated: Boolean //Fixed activation of the high beam
	derived headlampFixedDeactivated: Boolean
	derived lightIlluminationDistance: HighBeamMotor
	derived luminousStrength: HighBeamRange
	derived calculateSpeed: CurrentSpeed
	

definitions:
	// DOMAIN DEFINITIONS
	domain LightPercentage = {0, 10, 50, 100}
	domain Brightness = {0..300} // 100000  Si può ridurre a 300? (valore massimo da specifica)	
	domain SteeringAngle = {0..1022}
	//0 = sensor is calibrating
	//1-410 = steering wheel rotation to the left (Resolution: 1 starting from 10 deflection)
	//411-510 = steering wheel rotation to the left (Resolution: 0.1 for 0-10 deflection)
	//511-513 = steering wheel in neutral position
	//514-613 = steering wheel rotation to the right (Resolution: 0.1 for 0-10 deflection)
	//614-1022 = steering wheel rotation to the right (Resolution: 1 starting from 10 deflection)
	domain CurrentSpeed = {0..2000} //5000 Si può ridurre a 2000? che corrisponde a velocità massima di 200km/h??
	//1km/h = 10 unità
	domain BrakePedal = {0..225} //res 0.2° 0° - 45° -> 1° = 5 unità
//====================================		
	domain HighBeamRange = {0..100} //Percentage of high beam brightness (0..300 desired light range)
	domain HighBeamMotor = {0..14} 
		
	// FUNCTION DEFINITIONS
	
	function marketCode = EU
	function armoredVehicle = true
	function daytimeLight = true
	function ambientLighting = true
//====================================		
	//Engine state is determined by KeyPosition value. If the key is on the engine is on, otherwise is off
	function engineOn =
		(keyState = KEYINIGNITIONONPOSITION)
		
	function engineOn_Previous =
		(keyState_Previous = KEYINIGNITIONONPOSITION)
		
	//Low beam lights are on or off
	function lowBeamLightingOn = 
		(lowBeamLeft != 0 and lowBeamRight != 0) 
	
	//Activate parking light if true
	function parkingLight = 	
		(keyState = NOKEYINSERTED and lightRotarySwitch = ON and (pitmanArmUpDown = UPWARD7 or pitmanArmUpDown = DOWNWARD7)) 
			
	
	//ambient lighting is not activated if it is true but the vehicle is armored vehicle with darknewss mode on ELS-21
	function ambientLightingAvailable = 
		(ambientLighting  and not (armoredVehicle and darknessModeSwitchOn )) 
	
	//ambient light if active is activated only if this function is true
	function ambientLightingConditionOn = 
		(engineOn_Previous and (not engineOn) and brightnessSensor<200) 
			
	
	//True if pitman is in position turn left (DOWNWARD5 or DOWNWARD5_LONG or DOWNWARD7)
	function turnLeft_Mon  = 
		(pitmanArmUpDown = DOWNWARD5 or pitmanArmUpDown = DOWNWARD5_LONG or pitmanArmUpDown = DOWNWARD7) 
	
	function turnLeft_RunnReq  = 
		(pitmanArmUpDown_RunnReq = DOWNWARD5 or pitmanArmUpDown_RunnReq = DOWNWARD5_LONG or pitmanArmUpDown_RunnReq = DOWNWARD7) 
	
	function turnLeft_Buff  = 
		(pitmanArmUpDown_Buff = DOWNWARD5 or pitmanArmUpDown_Buff = DOWNWARD5_LONG or pitmanArmUpDown_Buff = DOWNWARD7)
	
	//True if pitman is in position turn right (UPWARD5 or UPWARD5_LONG or UPWARD7)
	function turnRight_Mon  = 
		(pitmanArmUpDown = UPWARD5 or pitmanArmUpDown = UPWARD5_LONG or pitmanArmUpDown = UPWARD7)
	
	function turnRight_RunnReq  = 
		(pitmanArmUpDown_RunnReq = UPWARD5 or pitmanArmUpDown_RunnReq = UPWARD5_LONG or pitmanArmUpDown_RunnReq = UPWARD7)
	
	function turnRight_Buff  = 
		(pitmanArmUpDown_Buff = UPWARD5 or pitmanArmUpDown_Buff = UPWARD5_LONG or pitmanArmUpDown_Buff = UPWARD7)
	
	//True if the car is sold in USA or CANADA, it does not have a separate direction ndicator at position C
	function tailLampAsIndicator = 
		(marketCode = USA or marketCode = CANADA)
		
	//Tail lamp value
	function tailLampLeft =
		if (tailLampLeftBlinkValue != 0 and not parkingLightON ) then
			tailLampLeftBlinkValue
		else
			tailLampLeftFixValue
		endif
		
	function tailLampRight =
		if (tailLampRightBlinkValue != 0  and not parkingLightON ) then
			tailLampRightBlinkValue
		else
			tailLampRightFixValue
		endif
	
	function brakeIsOn = 
		 (brakeLampLeft != 0 and brakeLampRight != 0 and brakeLampCenter != 0)			
//====================================	

	//Formulas for graphs in Figure 7 and 8 (as "reverse engineered") 
	//Figure 7
	//f(x) = x^2.2 * 0.0025 + 95     if x <= 171
	//f(x) = 300     if x > 171
	//Figure 8
	//f(x) = (7*x+60)/9

	    
	//Formulas for graphs in Figure 7 and 8 (as "reverse engineered") 
	function lightIlluminationDistance =
		if calculateSpeed < 300 then 0 
		else if calculateSpeed < 400 then 1  
		else if calculateSpeed < 500 then 2 
		else if calculateSpeed < 600 then 3 
		else if calculateSpeed < 700 then 4 
		else if calculateSpeed < 800 then 5 
		else if calculateSpeed < 900 then 6 
		else if calculateSpeed < 1000 then 7 
		else if calculateSpeed < 1100 then 8 
		else if calculateSpeed < 1200 then 9 
		else if calculateSpeed < 1300 then 10
		else if calculateSpeed < 1400 then 11 
		else if calculateSpeed < 1500 then 12 
		else if calculateSpeed < 1600 then 13 
		else if calculateSpeed > 1700 then 14 
		endif endif endif endif endif endif endif endif endif endif endif endif endif endif endif
	
	//Discretized
	function luminousStrength = 
	if calculateSpeed >= 0 and calculateSpeed < 300 then 0 
	else if calculateSpeed < 400 then 30  //=(7*speed+60)/9
	else if calculateSpeed < 500 then 37 
	else if calculateSpeed < 600 then 45 
	else if calculateSpeed < 700 then 53 
	else if calculateSpeed < 800 then 61 
	else if calculateSpeed < 900 then 68 
	else if calculateSpeed < 1000 then 76 
	else if calculateSpeed < 1100 then 84 
	else if calculateSpeed < 1200 then 92 
	else if calculateSpeed > 1200 then 100 
	endif endif endif endif endif endif endif endif endif endif endif
	//ELS-37 If an adaptive cruise control is part of the vehicle, the light illumination distance is not calculated upon the actual 
   //vehicle speed but the target speed provided by the advanced cruise control.
	function calculateSpeed =
	  if (cruiseControlMode=CCM2) then setVehicleSpeed 
	  	else  currentSpeed
	  endif
	
	//ELS32 If the light rotary switch is in position Auto, the adaptive high beam is activated by moving the pitman arm to the back
	function adaptiveHighBeamActivated =
		(lightRotarySwitch = AUTO and  engineOn and pitmanArmForthBack = BACKWARD)
	
	//ELS-38 If the pitman arm is moved again in the horizontal neutral position, the adaptive high beam headlight is deactivated.	
	function adaptiveHighBeamDeactivated =
		(lightRotarySwitch = AUTO and  pitmanArmForthBack = NEUTRAL_FB and pitmanArmForthBackPrevious = BACKWARD)
	
	function headlampFlasherActivated = 
	 	(pitmanArmForthBack = FORWARD and pitmanArmForthBackPrevious = NEUTRAL_FB)
	 	
	function headlampFlasherDeactivated = 
	 	(pitmanArmForthBack = NEUTRAL_FB and pitmanArmForthBackPrevious = FORWARD)
	
	function headlampFixedActivated = 
		(pitmanArmForthBack = BACKWARD and lightRotarySwitch = ON and (keyState = KEYINSERTED or engineOn))
		
	function headlampFixedDeactivated =
		//( (pitmanArmForthBack = NEUTRAL_FB and pitmanArmForthBackPrevious = BACKWARD and lightRotarySwitch = ON) or lightRotarySwitch = OFF or keyState = NOKEYINSERTED)
    ( (pitmanArmForthBack = NEUTRAL_FB and pitmanArmForthBackPrevious = BACKWARD and lightRotarySwitch = ON) or 
    ((lightRotarySwitch = OFF or keyState = NOKEYINSERTED) and not headlampFlasherActivated))
    
	// RULE DEFINITIONS
	
	//Set tail lamp status
	macro rule r_setTailLampLeft ($value in LightPercentage , $status in TailLampStatus) = 
		par
			tailLampLeftStatus := $status 
			tailLampLeftBlinkValue := $value 
		endpar
	
	macro rule r_setTailLampRight ($value in LightPercentage , $status in TailLampStatus) = 
		par
			tailLampRightStatus := $status 
			tailLampRightBlinkValue := $value 
		endpar
		
	macro rule r_BlinkLeft ($value in LightPercentage, $pulse in PulseRatio) = 
		par
			blinkLeft := $value 
			blinkLeftPulseRatio := $pulse
			//ELS-6
			if (tailLampAsIndicator) then
				if ($value = 0) then
					r_setTailLampLeft[0,FIX] 
				else
					r_setTailLampLeft[50,BLINK] 
				endif
			endif 
		endpar
		
	macro rule r_BlinkRight ($value in LightPercentage, $pulse in PulseRatio) = 
		par
			blinkRight := $value 
			blinkRightPulseRatio := $pulse
			//ELS-6
			if (tailLampAsIndicator) then
				if ($value = 0) then
					r_setTailLampRight[0,FIX] 
				else
					r_setTailLampRight[50,BLINK] 
				endif
			endif 
		endpar
	
	//ELS-1
	macro rule r_RunDirectionBlinkingMon  =
		par
			//when new Direction Blinking starts, delete value in the buffer and set the current value as running request
			pitmanArmUpDown_Buff := NEUTRAL_UD 
			pitmanArmUpDown_RunnReq := pitmanArmUpDown
			//If pitman is downward of 5° turn left
			if (turnLeft_Mon) then
				r_BlinkLeft[100,PULSE11] 	
			endif
			//If pitman is downward of 5° turn right
			if (turnRight_Mon) then
				r_BlinkRight[100,PULSE11] 
			endif
		endpar
		
	macro rule r_RunDirectionBlinkingBuff =
		par
			//when new Direction Blinking starts, delete value in the buffer and set the current value as running request
			pitmanArmUpDown_Buff := NEUTRAL_UD 
			pitmanArmUpDown_RunnReq := pitmanArmUpDown_Buff
			//If pitman is downward of 5° turn left
			if (turnLeft_Buff) then
				r_BlinkLeft[100,PULSE11] 	
			endif
			//If pitman is downward of 5° turn right
			if (turnRight_Buff) then
				r_BlinkRight[100,PULSE11] 
			endif
		endpar
	
	//Interrupt blinking	
	macro rule r_InterruptBlinking =
		par
			pitmanArmUpDown_RunnReq := NEUTRAL_UD
			//If pitman is downward turn left
			if (turnLeft_RunnReq) then
				r_BlinkLeft[0,NOPULSE] 
			endif
			//If pitman is upward turn right
			if (turnRight_RunnReq) then
				r_BlinkRight[0,NOPULSE] 
			endif
		endpar
			
	macro rule r_CompleteFlashingCycle =
		par
			//ELS-1
			if (pitmanArmUpDown_RunnReq = DOWNWARD7 or pitmanArmUpDown_RunnReq = UPWARD7) then
				if (pitmanArmUpDown = NEUTRAL_UD) then
					r_InterruptBlinking[] 
				endif
			endif
			//ELS-2
			if (pitmanArmUpDown_RunnReq = DOWNWARD5 or pitmanArmUpDown_RunnReq = UPWARD5) then
				if (threeBlinkingCycle) then
					r_InterruptBlinking[] 
				endif
			endif
			//ELS-4
			if (pitmanArmUpDown_RunnReq = DOWNWARD5_LONG or pitmanArmUpDown_RunnReq = UPWARD5_LONG) then
				if (pitmanArmUpDown = NEUTRAL_UD) then
					r_InterruptBlinking[] 
				endif
			endif
		endpar
	
	macro rule r_DirectionBlinking =
		//Function available only if key is on ON position
		if (keyState = KEYINIGNITIONONPOSITION) then
			//No request is running
				if (pitmanArmUpDown_RunnReq = NEUTRAL_UD) then
					//Run current request if present
					if (pitmanArmUpDown != NEUTRAL_UD) then
						r_RunDirectionBlinkingMon[] 
					//Run request in buffer if present
					else 
						if (pitmanArmUpDown_Buff != NEUTRAL_UD) then
							r_RunDirectionBlinkingBuff[] 
						endif
					endif
				//ELS-7 Request is running and current request is activated
				else 
					if (pitmanArmUpDown_RunnReq != NEUTRAL_UD and pitmanArmUpDown != NEUTRAL_UD) then
							//Running request is equal direction as current request
							//if (pitmanArmUpDown_RunnReq = pitmanArmUpDown) then
							if ((turnLeft_RunnReq = turnLeft_Mon) or (turnRight_RunnReq = turnRight_Mon)) then
								//par
									//r_InterruptBlinking[]
									//Interrupt previous and start immediatly new request
									if (not((pitmanArmUpDown_RunnReq = DOWNWARD5_LONG and pitmanArmUpDown = DOWNWARD5_LONG) or (pitmanArmUpDown_RunnReq = UPWARD5_LONG and pitmanArmUpDown = UPWARD5_LONG))) then 
										par
											pitmanArmUpDown_RunnReq := pitmanArmUpDown
											pitmanArmUpDown_Buff := NEUTRAL_UD
										endpar
									endif
								//endpar
							//Running request and current request are different
							else 
								if (pitmanArmUpDown_RunnReq != pitmanArmUpDown) then
									par
										r_InterruptBlinking[] 
										pitmanArmUpDown_Buff := pitmanArmUpDown
									endpar
								endif
							endif
					//Request is running and no other request is activated
					else 
						if (pitmanArmUpDown_RunnReq != NEUTRAL_UD) then
							r_CompleteFlashingCycle[]  
						endif
					endif
				endif
		//If key is not on ON position interrupt current blinking if exists
		else
			if (pitmanArmUpDown_RunnReq != NEUTRAL_UD) then
				par
					r_InterruptBlinking[] 
					pitmanArmUpDown_RunnReq := NEUTRAL_UD
					pitmanArmUpDown_Buff := NEUTRAL_UD
				endpar
			endif
		endif		
	
	//Deactivate Hazard Warning
	macro rule r_InterruptHazardWarning =
		par
			hazardWarningSwitchOn_Runn := false
			r_BlinkLeft[0,NOPULSE]
			r_BlinkRight[0,NOPULSE]
		endpar
	
	//Set Hazard Warning Pulse ratio ELS-8 ELS-9
	macro rule r_AdaptHazardWarningPulseRatio =
		if (keyState = KEYINIGNITIONONPOSITION or keyState = KEYINSERTED) then
			par
				r_BlinkLeft[100,PULSE11] 
				r_BlinkRight[100,PULSE11] 
			endpar
		else
			par
				r_BlinkLeft[100,PULSE12] 
				r_BlinkRight[100,PULSE12] 
			endpar
		endif
	
	//ELS-12: save pitmanarm request
	macro rule r_SavePitmanArmUpDownReq =
		if (pitmanArmUpDown = DOWNWARD7 or pitmanArmUpDown = UPWARD7 or pitmanArmUpDown = NEUTRAL_UD) then
			pitmanArmUpDown_Buff := pitmanArmUpDown
		endif
	
	//ELS-8
	macro rule r_StartHazardWarning =
		par
			hazardWarningSwitchOn_Start:=false
			hazardWarningSwitchOn_Runn := true
			r_AdaptHazardWarningPulseRatio[] 
		endpar
		
	macro rule r_HazardWarningLight =
		// If Hazard warning is running
		if (hazardWarningSwitchOn_Runn) then
			par
				//If user wants to turn off hazard warning
				if ((not hazardWarningSwitchOn)) then
					par
						hazardWarningSwitchOn_Runn := false
						r_InterruptHazardWarning[]
					endpar
				else
					r_AdaptHazardWarningPulseRatio[]
				endif
				//If HW is running save the request from pitman arm UpDown into the buffer
				r_SavePitmanArmUpDownReq[] 
			endpar
		else // If HW is not running
			// If the user wants to activate hazard warning and he didn't push the button in the previous state
			if ((not hazardWarningSwitchOn_Start)) then
				if (hazardWarningSwitchOn) then
					par 
						//Interrupt Blinking if running ELS-13
						if (pitmanArmUpDown_RunnReq != NEUTRAL_UD) then
							r_InterruptBlinking[] 
						endif
						//Start HW in the next state because of ELS-11
						hazardWarningSwitchOn_Start := true
						//If request from pitman arm UpDown arrives save it into the buffer
						r_SavePitmanArmUpDownReq[] 
					endpar
				else
					r_DirectionBlinking[] 
				endif
			else 
				par
					//Start HW
					r_StartHazardWarning[] 
					//If request from pitman arm UpDown arrives save it into the buffer
					r_SavePitmanArmUpDownReq[] 
				endpar
			endif
		endif
	
	//Set low beam tail lamp on off
	macro rule r_LowBeamTailLampLeftOnOff ($value in LightPercentage) =
		par
			lowBeamLeft := $value
			tailLampLeftFixValue := $value 
		endpar
		
	//Set low beam tail lamp on off	
	macro rule r_LowBeamTailLampRightOnOff ($value in LightPercentage) =
		par
			lowBeamRight := $value
			tailLampRightFixValue := $value
		endpar
	
	//ELS-22
	macro rule r_LowBeamTailLampOnOff ($value in LightPercentage) =
		par
			r_LowBeamTailLampLeftOnOff[$value] 
			r_LowBeamTailLampRightOnOff[$value] 
		endpar
	
	//Turn on parking light ELS-28
	macro rule r_parkingLight = 
		par
			if (pitmanArmUpDown = UPWARD7) then
				par
					r_LowBeamTailLampLeftOnOff[0] 
					r_LowBeamTailLampRightOnOff[10] 
				endpar
			endif
			if (pitmanArmUpDown = DOWNWARD7) then
				par
					r_LowBeamTailLampLeftOnOff[10] 
					r_LowBeamTailLampRightOnOff[0]
				endpar 
			endif
		endpar
	
	macro rule 	r_LowBeamHeadlights =
		par
		//ELS-14
			if (lightRotarySwitch = ON and engineOn) then
				r_LowBeamTailLampOnOff[100] 
			endif
		//ELS-19
			if (ambientLightingAvailable and ambientLightingConditionOn) then
				if ((not lowBeamLightingOn)) then
					r_LowBeamTailLampOnOff[100] 
				endif
			endif
		//ELS-19	
			if (ambientLightingAvailable and lowBeamLightingOn and (not engineOn)) then
				if (passed30Sec) then
					if (parkingLight) then
						par
							r_parkingLight[] //	ELS-28
							parkingLightON := true
						endpar
					else
						r_LowBeamTailLampOnOff[0] 
					endif
				else
					if (parkingLight) then
						parkingLightON := true
					endif
				endif
			endif
		//ELS-15
			//if not (ambientLightingAvailable and ambientLightingConditionOn) then
			if  (not ambientLightingAvailable) then
				par
					if (keyState = KEYINSERTED and lightRotarySwitchPrevious != ON and lightRotarySwitch = ON) then
						r_LowBeamTailLampOnOff[50] 
					endif
					if (not daytimeLight) then
						par
							if (keyState = KEYINSERTED and engineOn_Previous and (not engineOn) and lightRotarySwitchPrevious = ON and lightRotarySwitch = ON) then
								r_LowBeamTailLampOnOff[0] 
							endif
							if (keyState = NOKEYINSERTED and lightRotarySwitchPrevious = ON and lightRotarySwitch = ON and (not parkingLight)) then
								r_LowBeamTailLampOnOff[0]
							endif
						endpar
					endif
				endpar
			endif
		//ELS-17
			if (daytimeLight) then
				if ((not ambientLightingAvailable) or (not (ambientLightingAvailable and ambientLightingConditionOn)))  then 
					//if ((keyState = KEYINSERTED or keyState = KEYINIGNITIONONPOSITION) and (engineOn_Previous = false and engineOn = true)) then
					if (not engineOn_Previous and engineOn) then
						par
							if ((not lowBeamLightingOn)) then
								r_LowBeamTailLampOnOff[100] 
							endif
							//Turn off parking light
							if (parkingLightON) then
								parkingLightON := false
							endif
						endpar
					endif
				endif
			endif
	
			//ELS-16 ELS-17, ELS-16 has priority over ELS-17
			if (not ambientLightingAvailable) then
			//ELS-16
				if ((not engineOn_Previous) and (not engineOn) and lightRotarySwitch = AUTO and lightRotarySwitchPrevious != AUTO) then
					r_LowBeamTailLampOnOff[0] 
				else
					if ((not parkingLight) and daytimeLight and keyState = NOKEYINSERTED and (keyState_Previous = KEYINSERTED or keyState_Previous = KEYINIGNITIONONPOSITION)) then
						r_LowBeamTailLampOnOff[0] 
					endif
				endif
			endif
		//ELS-18
			if (lightRotarySwitch = AUTO and engineOn and brightnessSensor<200) then 
				if ((not lowBeamLightingOn)) then
					r_LowBeamTailLampOnOff[100] 
				endif
			endif
			if (lightRotarySwitch = AUTO and engineOn and brightnessSensor>250) then
				if (lowBeamLightingOn and passed3Sec) then
					r_LowBeamTailLampOnOff[0] 
				endif
			endif
		//ELS-28
			if (not ambientLightingAvailable and parkingLight) then
				par
					r_parkingLight[] 
					parkingLightON := true
				endpar
			endif
		//	if (parkingLightON) then
		//		r_parkingLight[] 
		//	endif
		endpar
	
	//Turn cornering lights off
	macro rule r_CorneringLightsOff =
		par
			if (corneringLightRight != 0) then
				corneringLightRight := 0
			endif
			if (corneringLightLeft != 0) then
				corneringLightLeft := 0
			endif
		endpar
	
	//Turn cornering lights on	
	macro rule r_CorneringLightsOn ($leftRight in LeftRight) = 
	//ELS-24
		par
			if ($leftRight = RIGHT) then
				corneringLightRight := 100
			endif
			if ($leftRight = LEFT) then
				corneringLightLeft := 100
			endif
		endpar
	
		
	//ELS-24 ELS-25 ELS-26 ELS-27
	macro rule r_CorneringLights =
			//ELS-25
			if (not(armoredVehicle and darknessModeSwitchOn ) and lowBeamLightingOn) then
				par
					if (currentSpeed > 0 and  currentSpeed <= 100) then
						par
							//ELS-26 ELS-24
							if ((steeringAngle >= 614 and steeringAngle <= 1022) or (turnRight_RunnReq)) then
								r_CorneringLightsOn[RIGHT] 
							endif
							if ((steeringAngle >= 1 and steeringAngle <= 410) or (turnLeft_RunnReq)) then
								r_CorneringLightsOn[LEFT] 
							endif
						endpar
					endif
					//ELS-27
					if (reverseGear) then
						par
							r_CorneringLightsOn[RIGHT] 
							r_CorneringLightsOn[LEFT] 
						endpar
					endif
					if ((corneringLightRight != 0 and corneringLightLeft != 0 and (not reverseGear)) and ((corneringLightRight != 0 or corneringLightLeft != 0) and ((steeringAngle >= 411 and steeringAngle <= 613) and (pitmanArmUpDown_RunnReq = NEUTRAL_UD and passed5Sec)))) then
						r_CorneringLightsOff[] 
					endif
				endpar
			endif

			
	macro rule r_ReadMonitorFunctions = 
		par
			keyState_Previous := keyState
			lightRotarySwitchPrevious := lightRotarySwitch
			pitmanArmForthBackPrevious := pitmanArmForthBack
		endpar 
		
	//ELS-41
	macro rule r_ReverseLight = 
		if (reverseGear) then
			reverseLight := 100
		else
			reverseLight := 0
		endif
	
	macro rule r_setBrakeValue ($value in LightPercentage) =
		par
			brakeLampLeft := $value 
			brakeLampRight := $value 
			brakeLampCenter := $value 
		endpar
			
	//ELS-39 ELS-40
	macro rule r_EmergencyBrakeLights = 
		par
			if (brakePedal > 15 and (not brakeIsOn)) then
				r_setBrakeValue[100]
			endif
			if (brakePedal < 5 and brakeIsOn) then
				r_setBrakeValue[0]
			endif
			if (brakePedal > 200 and brakeLampCenterStatus = FIX) then
				brakeLampCenterStatus := BLINK
			endif
			if (brakePedal = 0 and brakeLampCenterStatus = BLINK) then 
				brakeLampCenterStatus := FIX
			endif
		endpar
	
		macro rule r_set_high_beam_headlights($v in Boolean, $d in HighBeamMotor, $l in HighBeamRange) =
		par
			highBeamOn := $v
			highBeamMotor := $d 
			highBeamRange := $l 
		endpar
		
	macro rule r_Manual_high_beam_headlights = 
		par
			//ELS-30
			if headlampFlasherActivated then
				r_set_high_beam_headlights[true,14,100] //max illumination area 360m, 100% luminous strenght (percentage)
			endif
			//ELS-30-31
			if headlampFlasherDeactivated or headlampFixedDeactivated then
			    highBeamOn := false
			endif
			//ELS-31
			if headlampFixedActivated then
				r_set_high_beam_headlights[true,7,100] //illumination area of 220m, 100% luminous strenght (percentage)
			endif
	    endpar
		
	//ELS-33 @E_MAPE_HBH
	//Sets the values, as calculated by the planner, for the lighting high beam actuators: highBeamOn to activate and deactivate the high beam, 
	//highBeamRange to control the high beam luminous, and highBeamMotor to control the high beam illumination distance.  
	macro rule r_Execute_HBH ($setHighBeam in Boolean,  $setHighBeamMotor in HighBeamMotor, $setHighBeamRange in HighBeamRange) =
	   	r_set_high_beam_headlights[$setHighBeam,$setHighBeamMotor,$setHighBeamRange]
					
	//ELS-33 @P_MAPE_HBH
	//Plans street illumination according to the characteristic curves for light illumination distance and for luminous strength 
	//depending on the vehicle speed
	macro rule r_IncreasingPlan_HBH =
		r_Execute_HBH[true,lightIlluminationDistance,luminousStrength] 
	    
	//ELS-34 @P_MAPE_HBH
	//Reduce street illumination by reducing the area of illumination to 65 meters by an adjustment of the headlight position 
	//as well as by reduction of the luminous strength to 30%. 
	//depending on the vehicle speed
	macro rule r_DecreasingPlan_HBH =
	   	  r_Execute_HBH[true,30,0]
  
	    
	//ELS-33-34-35 @MA_MAPE_HBH
	//All MAPE computations of the MAPE loop are executed within one single ASM-step machine.
	//Note that we do not model the time constraints ('within 2 seconds', 'within 0.5 seconds')
	macro rule r_Monitor_Analyze_HBH =
	 if adaptiveHighBeamActivated then
	 	par	
	 	 if (currentSpeed>=300) and not oncomingTraffic then //ELS-33 ELS-35 (checks if adaptation is necessary)
	 		//the street should be illuminated accordingly
	 		r_IncreasingPlan_HBH[]
	 	 endif
	 	 if oncomingTraffic then //ELS-34 (checks if adaptation is necessary) 
	 		//an activated high beam headlight is reduced to low beam headlight.
	 		r_DecreasingPlan_HBH[]
	 	 endif
	 	endpar
	 endif
	
	macro rule r_MAPE_HBH = //MAPE loop may start and stop
		par 
		    r_Monitor_Analyze_HBH[] 
			if adaptiveHighBeamDeactivated then highBeamOn := false	endif //ELS-38 If the pitman arm is moved again in the horizontal neutral position, 														  
			//the adaptive high beam headlight is deactivated.
		endpar
	
		
	// INVARIANTS
	
	
	//PROPERTIES
	
	//ELS-1
	CTLSPEC	ag(pitmanArmUpDown_RunnReq = DOWNWARD7 implies (blinkLeft != 0 and blinkRight = 0))
	CTLSPEC	ag(pitmanArmUpDown_RunnReq = UPWARD7 implies (blinkLeft = 0 and blinkRight != 0))
	//ELS-2
	CTLSPEC	ag((pitmanArmUpDown_RunnReq = DOWNWARD5 or pitmanArmUpDown_RunnReq = DOWNWARD5_LONG) implies (blinkLeft != 0 and blinkRight = 0))
	CTLSPEC	ag((pitmanArmUpDown_RunnReq = UPWARD5 or pitmanArmUpDown_RunnReq = UPWARD5_LONG) implies (blinkLeft = 0 and blinkRight != 0))
	CTLSPEC	ag((pitmanArmUpDown_RunnReq = DOWNWARD5 and threeBlinkingCycle) implies ef(blinkLeft = 0 and blinkRight = 0))
	
	CTLSPEC	ag((pitmanArmUpDown_RunnReq = DOWNWARD5) implies e(blinkLeft != 0 , threeBlinkingCycle = true))
	
	CTLSPEC	ag((pitmanArmUpDown_RunnReq = UPWARD5 and threeBlinkingCycle and pitmanArmUpDown=NEUTRAL_UD) implies ex(blinkRight = 0))
	
	//ELS-3 If hazard warning is activated, all others actions must be interrupted
	CTLSPEC ag(pitmanArmUpDown_RunnReq != NEUTRAL_UD and hazardWarningSwitchOn) implies af(pitmanArmUpDown_RunnReq = NEUTRAL_UD and hazardWarningSwitchOn_Start = true)
	//ELS-6
	CTLSPEC ag((marketCode=USA and pitmanArmUpDown_RunnReq != NEUTRAL_UD) implies (tailLampLeftBlinkValue = 50 or tailLampRightBlinkValue = 50))
	//ELS-8 ELS-9
	CTLSPEC	eg((hazardWarningSwitchOn_Runn and keyState = NOKEYINSERTED) implies ax(blinkLeft!=0 and blinkRight!=0 and blinkLeftPulseRatio = PULSE12 and blinkRightPulseRatio = PULSE12))
	CTLSPEC	eg((hazardWarningSwitchOn_Runn and (keyState = KEYINSERTED or keyState = KEYINIGNITIONONPOSITION)) implies ax(blinkLeft!=0 and blinkRight!=0 and blinkLeftPulseRatio = PULSE12 and blinkRightPulseRatio = PULSE12))
	CTLSPEC	ag(hazardWarningSwitchOn_Runn implies (blinkLeft != 0 and blinkRight != 0))
	//
	CTLSPEC	ag(pitmanArmUpDown_RunnReq != NEUTRAL_UD  implies (blinkLeft != 0 or blinkRight != 0))
	
	//ELS-14
	CTLSPEC ag((engineOn and lightRotarySwitch=ON) implies ax(lowBeamLightingOn))
	
	//ELS-15
	CTLSPEC ag((not ambientLightingAvailable and keyState = KEYINSERTED and lightRotarySwitchPrevious != ON and lightRotarySwitch=ON) implies ax(lowBeamLeft = 50 and lowBeamRight = 50))
	
	//ELS-16
	CTLSPEC ag((not engineOn_Previous and not engineOn and lightRotarySwitchPrevious != AUTO and lightRotarySwitch = AUTO and not ambientLightingAvailable) implies ax(lowBeamLeft = 0 and lowBeamRight = 0))
	
	//CTLSPEC ag((engineOn_Previous = false and engineOn = false and lightRotarySwitchPrevious != AUTO and lightRotarySwitch = AUTO and ambientLightingAvailable and passed30Sec = true and (not parkingLight)) implies ax(lowBeamLeft = 0 and lowBeamRight = 0))
	
	
	//ELS-17
	CTLSPEC ag((not ambientLightingAvailable and daytimeLight and not engineOn_Previous and engineOn and not lowBeamLightingOn) implies ax(lowBeamLightingOn))
	CTLSPEC ag((not ambientLightingAvailable and not parkingLight and daytimeLight and lowBeamLightingOn and not parkingLight and (keyState_Previous = KEYINIGNITIONONPOSITION or keyState_Previous = KEYINSERTED) and keyState = NOKEYINSERTED) implies ax(lowBeamLeft = 0 and lowBeamRight = 0))
	CTLSPEC ag((not parkingLight and daytimeLight and not ambientLightingAvailable and lowBeamLightingOn and not parkingLight and (keyState_Previous = KEYINIGNITIONONPOSITION or keyState_Previous = KEYINSERTED) and keyState = NOKEYINSERTED) implies ax(lowBeamLeft = 0 and lowBeamRight = 0))
	
	//ELS-18
	CTLSPEC ag((lightRotarySwitch = AUTO and engineOn and brightnessSensor < 200) implies ax(lowBeamLightingOn))
	CTLSPEC ag((lightRotarySwitch = AUTO and engineOn and lowBeamLightingOn and brightnessSensor > 250 and passed3Sec) implies ax(not lowBeamLightingOn))
	
	//ELS-19
	CTLSPEC ag((ambientLightingAvailable and ambientLightingConditionOn and not lowBeamLightingOn) implies ax (lowBeamLightingOn))
	
	//ELS-21
	CTLSPEC ag(not armoredVehicle implies not ambientLightingAvailable)
	
	//ELS-22
	CTLSPEC ag(lowBeamLeft != 0 implies tailLampLeft !=0)
	CTLSPEC ag(lowBeamRight != 0 implies tailLampRight!=0)
	
	//ELS-23
	CTLSPEC ag((hazardWarningSwitchOn_Runn and  (marketCode=USA or marketCode=CANADA)) implies (tailLampLeftStatus = BLINK and tailLampRightStatus = BLINK))
	CTLSPEC ag((pitmanArmUpDown_RunnReq != NEUTRAL_UD and (marketCode=USA or marketCode=CANADA)) implies (tailLampLeftStatus = BLINK or tailLampRightStatus = BLINK))
	
	//ELS-24 ELS-25 ELS-26
	CTLSPEC ag((not(armoredVehicle and darknessModeSwitchOn) and lowBeamLightingOn and (currentSpeed > 0 and  currentSpeed <= 100) and ((steeringAngle >= 614 and steeringAngle <= 1022) or (turnRight_RunnReq))) implies ax(corneringLightRight = 100))
	CTLSPEC ag((not(armoredVehicle and darknessModeSwitchOn) and lowBeamLightingOn and (currentSpeed > 0 and  currentSpeed <= 100) and ((steeringAngle >= 1 and steeringAngle <= 410) or (turnLeft_RunnReq))) implies ax(corneringLightLeft = 100))
	
	//ELS-27
	CTLSPEC ag((not(armoredVehicle and darknessModeSwitchOn) and lowBeamLightingOn and reverseGear) implies ax(corneringLightLeft = 100 and corneringLightRight = 100))
	
	//ELS-28
	CTLSPEC ag(((ambientLightingAvailable and lowBeamLightingOn and not engineOn) and (passed30Sec) and (parkingLight) and pitmanArmUpDown = UPWARD7) implies ax(lowBeamRight = 10 and tailLampRight = 10 and lowBeamLeft = 0 and tailLampLeft = 0)) 
	CTLSPEC ag(((ambientLightingAvailable and lowBeamLightingOn and not engineOn) and (passed30Sec) and (parkingLight) and pitmanArmUpDown = DOWNWARD7) implies ax(lowBeamRight = 0 and tailLampRight = 0 and lowBeamLeft = 10 and tailLampLeft = 10)) 
	
	//ELS-29
	CTLSPEC ag ((brakePedal > 15 and not brakeIsOn) implies ax(brakeLampLeft !=0 and brakeLampRight != 0 and brakeLampCenter != 0))
	CTLSPEC ag ((brakePedal < 5 and brakeIsOn) implies ax(brakeLampLeft =0 and brakeLampRight = 0 and brakeLampCenter = 0))
	
	//ELS-30
	CTLSPEC ag ((brakePedal > 200 and brakeLampCenterStatus = FIX) implies ax(brakeLampCenterStatus = BLINK))
	CTLSPEC ag ((brakePedal = 0 and brakeLampCenterStatus = BLINK) implies ax(brakeLampCenterStatus = FIX))
	
	//ELS-31
	CTLSPEC ag ((reverseGear) implies ax(reverseLight != 0))
	CTLSPEC ag ((not reverseGear) implies ax(reverseLight = 0))
	
	//ELS-36
	CTLSPEC ag(adaptiveHighBeamActivated  implies (highBeamMotor >= 2 or highBeamMotor <= 11))
	
	//GENERAL PROPERTIES
	CTLSPEC ag ((tailLampLeftStatus = BLINK and tailLampRightStatus = BLINK) implies marketCode != EU)
	CTLSPEC (forall $c in MarketCode with (marketCode = $c implies ag(marketCode = $c)))
	CTLSPEC ag((blinkLeft != 0 and blinkLeftPulseRatio != NOPULSE and blinkRight != 0 and blinkRightPulseRatio != NOPULSE) = hazardWarningSwitchOn_Runn)
	
	
	// MAIN RULE
	main rule r_Main =
		par 
			r_ReadMonitorFunctions[] 
			r_HazardWarningLight[] 
			r_LowBeamHeadlights[]
			r_CorneringLights[] 
			r_ReverseLight[] 
			r_EmergencyBrakeLights[] 
			r_Manual_high_beam_headlights[] 
			r_MAPE_HBH[] 
		endpar

// INITIAL STATE
default init s0:
	//Pitman arm Up Down is in NEUTRAL position
	function pitmanArmUpDown_RunnReq = NEUTRAL_UD	
	function pitmanArmUpDown_Buff = NEUTRAL_UD
	// Hazard Warning is not active
	function hazardWarningSwitchOn = false
	function hazardWarningSwitchOn_Runn = false
	function hazardWarningSwitchOn_Start = false
	//Direction blinkers are off
	function blinkLeft = 0
	function blinkLeftPulseRatio = NOPULSE
	function blinkRight = 0
	function blinkRightPulseRatio = NOPULSE
	//Key is not inserted	
	function keyState_Previous = NOKEYINSERTED
	//Tail lamp is fixed
	function tailLampLeftBlinkValue = 0
	function tailLampLeftFixValue = 0
	function tailLampLeftStatus = FIX
	function tailLampRightBlinkValue  = 0
	function tailLampRightFixValue  = 0
	function tailLampRightStatus = FIX
	//Light rotary switch
	function lightRotarySwitchPrevious = OFF
	//Cornering lights off
	function corneringLightRight = 0
	function corneringLightLeft = 0
	//Low beam headlight
	function lowBeamLeft = 0
	function lowBeamRight = 0
	function parkingLightON = false 
	function reverseLight = 0
	function brakeLampLeft = 0
	function brakeLampRight = 0
	function brakeLampCenter = 0
	function brakeLampCenterStatus = FIX
	//High beam
	function highBeamOn = false
	function pitmanArmForthBack = NEUTRAL_FB  
	function pitmanArmForthBackPrevious = NEUTRAL_FB 
	function oncomingTraffic = false
	function cruiseControlMode = CCM0
	function setVehicleSpeed = 0