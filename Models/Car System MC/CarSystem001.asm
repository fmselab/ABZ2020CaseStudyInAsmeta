//Ground model of Adaptive Exterior Light and Speed Control System
//Direction Blinking
//Hazard warning light
//from ELS-1 to ELS-13

asm CarSystem001
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
	domain LightPercentage subsetof Integer // Light percentage
	
	// FUNCTIONS
	
	//Parameters setted initially
	static marketCode: MarketCode //Market code
	
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
	controlled tailLampLeftBlinkValue: LightPercentage // Tail lamp left is off (0%) or is on with a specific percentage of brightness
	controlled tailLampLeftStatus: TailLampStatus // Tail lamp left status
	controlled tailLampRightBlinkValue: LightPercentage // Tail lamp right is off (0%) or is on with a specific percentage of brightness
	controlled tailLampRightStatus: TailLampStatus // Tail lamp right status
	
	monitored threeBlinkingCycle: Boolean // Indicators have flashed for three flashing cycles (true) or less (false)
		
	derived turnLeft_RunnReq: Boolean //True if pitmanArmUpDown_RunnReq is in position turn left (DOWNWARD5 or DOWNWARD5_LONG or DOWNWARD7)
	derived turnRight_RunnReq: Boolean //True if pitmanArmUpDown_RunnReq is in position turn right (UPWARD5 or UPWARD5_LONG or UPWARD7)
	derived turnLeft_Buff: Boolean //True if pitmanArmUpDown_Buff is in position turn left (DOWNWARD5 or DOWNWARD5_LONG or DOWNWARD7)
	derived turnRight_Buff: Boolean //True if pitmanArmUpDown_Buff is in position turn right (UPWARD5 or UPWARD5_LONG or UPWARD7)
	derived turnLeft_Mon: Boolean //True if pitmanArmUpDown is in position turn left (DOWNWARD5 or DOWNWARD5_LONG or DOWNWARD7)
	derived turnRight_Mon: Boolean //True if pitmanArmUpDown is in position turn right (UPWARD5 or UPWARD5_LONG or UPWARD7)
	derived tailLampAsIndicator: Boolean //True if the car is sold in USA or CANADA, it does not have a separate direction ndicator at position C	
	
definitions:
	// DOMAIN DEFINITIONS
	domain LightPercentage = {0, 50, 100} //0..100 -> SEMPLIFICATO CON I SOLI VALORI UTILIZZATI NELLA SPECIFICA
	
	
	// FUNCTION DEFINITIONS
	
	function marketCode = EU
	
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
				if (threeBlinkingCycle = true) then
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
							if (not(pitmanArmUpDown_RunnReq = DOWNWARD5_LONG or pitmanArmUpDown_RunnReq = UPWARD5_LONG)) then 
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
	
	// MAIN RULE
	main rule r_Main =
		r_HazardWarningLight[] 
		

// INITIAL STATE
default init s0:
	//Pitman arm Up Down is in NEUTRAL position
	function pitmanArmUpDown = NEUTRAL_UD
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
	function keyState = NOKEYINSERTED
	//Tail lamp is fixed
	function tailLampLeftBlinkValue = 0
	function tailLampLeftStatus = FIX
	function tailLampRightBlinkValue = 0
	function tailLampRightStatus = FIX