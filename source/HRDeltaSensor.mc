//
// Copyright 2015-2016 by Garmin Ltd. or its subsidiaries.
// Subject to Garmin SDK License Agreement and Wearables
// Application Developer Agreement.
//

using Toybox.Ant as Ant;
using Toybox.Time as Time;
using Toybox.System as Sys;

(:previousAntHandler)
class AuxHRSensor extends Ant.GenericChannel {
    const DEVICE_TYPE = 120;
    const PERIOD = 8070;

    hidden var chanAssign;

    var data;
    var mSearching;
    var deviceCfg;

    class AuxHRData {
        var currentHeartRate;
        var OHRHeartRateDelta;
        var OHRHeartRate;

        function initialize() {
            currentHeartRate = 0;
            OHRHeartRateDelta = 0;
            OHRHeartRate = 0;
        }
    }

    class HeartRateDataPage {
        static const INVALID_HR = 0x00;

        function parse(payload, data) {
            data.currentHeartRate = parseCurrentHR(payload);
        }

        hidden function parseCurrentHR(payload) {
            return payload[7];
        }
    }

    function initialize(mAntID) {
        // Get the channel
        chanAssign = new Ant.ChannelAssignment(
            Ant.CHANNEL_TYPE_RX_NOT_TX,
            Ant.NETWORK_PLUS);
        GenericChannel.initialize(method(:onMessage), chanAssign);

        // Set the configuration
        deviceCfg = new Ant.DeviceConfig( {
            :deviceNumber => mAntID,             //Set to 0 to use wildcard search
            :deviceType => DEVICE_TYPE,
            :transmissionType => 0,
            :messagePeriod => PERIOD,
            :radioFrequency => 57,              //Ant+ Frequency
            :searchTimeoutLowPriority => 10,    //Timeout in 25s
            :searchThreshold => 0} );           //Pair to all transmitting sensors
        GenericChannel.setDeviceConfig(deviceCfg);

        data = new AuxHRData();
        mSearching = true;
    }

    function open() {
        // Open the channel
        GenericChannel.open();

        data = new AuxHRData();
        mSearching = true;
    }

    function closeSensor() {
        GenericChannel.close();
    }

    function onMessage(msg) {
        // Parse the payload
        var payload = msg.getPayload();

        if( Ant.MSG_ID_BROADCAST_DATA == msg.messageId ) {
            // Were we searching?
            if (mSearching) {
                mSearching = false;
                // Update our device configuration primarily to see the device number of the sensor we paired to
                deviceCfg = GenericChannel.getDeviceConfig();
            }
            var dp = new HeartRateDataPage();
            dp.parse(msg.getPayload(), data);
        } else if(Ant.MSG_ID_CHANNEL_RESPONSE_EVENT == msg.messageId) {
            if (Ant.MSG_ID_RF_EVENT == (payload[0] & 0xFF)) {
                if (Ant.MSG_CODE_EVENT_CHANNEL_CLOSED == (payload[1] & 0xFF)) {
                    // Channel closed, re-open
                    open();
                } else if( Ant.MSG_CODE_EVENT_RX_FAIL_GO_TO_SEARCH  == (payload[1] & 0xFF) ) {
                    mSearching = true;
                }
            } else {
                //It is a channel response.
            }
        }
    }

}

(:Post_0_2_7_AntHandler)
class AuxHRSensor extends Ant.GenericChannel {
    const DEVICE_TYPE = 120;  //strap
	const PERIOD = 8070; // 4x per second

    var data;
    var mSearching;

    class AuxHRData {
        var currentHeartRate;
        var OHRHeartRateDelta;
        var OHRHeartRate;

        function initialize() {
            currentHeartRate = 0;
            OHRHeartRateDelta = 0;
            OHRHeartRate = 0;
        }
    }
	
	hidden var mChanAssign;
	var deviceCfg;
	hidden var mMessageCount=0;
	hidden var mSavedAntID;
	hidden var isChOpen;
	
    function initialize(mAntID) {
    	mSavedAntID = mAntID;
    	isChOpen = false;

       // Get the channel
        try {
	        mChanAssign = new Ant.ChannelAssignment(
	            //Ant.CHANNEL_TYPE_RX_NOT_TX,
	            Ant.CHANNEL_TYPE_RX_ONLY,
	            Ant.NETWORK_PLUS);
		} catch (ex) {
			Sys.println("Can't assign ANT channel");
			Sys.println(ex.getErrorMessage());
			closeSensor();	
	        mChanAssign = new Ant.ChannelAssignment(
	            Ant.CHANNEL_TYPE_RX_ONLY,
	            Ant.NETWORK_PLUS);			
		}
		finally {
		}
            		
        // Set the configuration
        deviceCfg = new Ant.DeviceConfig( {
            :deviceNumber => mAntID,             //Set to 0 to use wildcard search
            :deviceType => DEVICE_TYPE,
            :transmissionType => 0,
            :messagePeriod => PERIOD,
            :radioFrequency => 57,              //Ant+ Frequency
            :searchTimeoutLowPriority => 10,    // was 10 Timeout in 25s
            //:searchTimeoutHighPriority => 2, 
            :searchThreshold => 0} );           //Pair to all transmitting sensors, 0 disabled, 1 = nearest
       	//mChanAssign.setBackgroundScan(true);
       	GenericChannel.initialize(method(:onAntMsg), mChanAssign);
       	GenericChannel.setDeviceConfig(deviceCfg);
       	//isChOpen = GenericChannel.open();
       	
       	data = new AuxHRData();
        mSearching = true;
       	
		// will now be searching for strap after openCh()
		Sys.println("ANT initialised");
	}	
	
	function open() {
        // Open the channel
        isChOpen = GenericChannel.open();
        //data = new AuxHRData();
        mSearching = true;
    }

	function closeSensor() {
		Sys.println("Stopping external sensors");
		if (isChOpen ) {
    		GenericChannel.close();
    	}
    	GenericChannel.release();
	}

    function onAntMsg(msg)
    {
		var payload = msg.getPayload();		
		if (mDebuggingANT == true) {
	        //Sys.println("device ID = " + msg.deviceNumber);
			//Sys.println("deviceType = " + msg.deviceType);
			//Sys.println("transmissionType= " + msg.transmissionType);
			//Sys.println("getPayload = " + msg.getPayload());
			//Sys.println("messageId = " + msg.messageId);	
			//Sys.println("A - "+mMessageCount);
			mMessageCount++;
		}
		
        if( Ant.MSG_ID_BROADCAST_DATA == msg.messageId  ) {
        	if (mSearching) {
                mSearching = false;
                // Update our device configuration primarily to see the device number of the sensor we paired to
                deviceCfg = GenericChannel.getDeviceConfig();
                //mSavedAntID = deviceCfg.deviceNumber;
                //Sys.println("ANT: ANT ID = "+mSavedAntID);
            }
			// not sure this handles all page types and 65th special page correctly
    		
    		data.currentHeartRate = payload[7].toNumber();
			//var beatEvent = ((payload[4] | (payload[5] << 8)).toNumber() * 1000) / 1024;
			//var beatCount = payload[6].toNumber();
        }
        else if( Ant.MSG_ID_CHANNEL_RESPONSE_EVENT == msg.messageId ) {
        	if (mDebuggingANT) {
        		Sys.println("ANT EVENT msg of length "+payload.size());
        	}
        	// catch case when payload is only one byte!
       		if ((Ant.MSG_ID_RF_EVENT == (payload[0] & 0xFF)) && (payload.size() > 1)) {
	            var event = (payload[1] & 0xFF);	            
	            switch( event) {
	            	case Ant.MSG_CODE_EVENT_CHANNEL_CLOSED:
	            		Sys.println("ANT:EVENT: closed");
	            		// initialise again
	            		//deviceCfg = null;
	            		//initialize(mSavedAntID);
	            		// reopen channel
	            		open();
						//data.currentHeartRate = 0;
						// should still get data
						//mSearching = true;	            			            		
	            		break;
	            	case Ant.MSG_CODE_EVENT_RX_FAIL:
						//data.currentHeartRate = 0;
						//mSearching = true;
						// wait for another message?
						Sys.println( "RX_FAIL in AntHandler");
						break;
					case Ant.MSG_CODE_EVENT_RX_FAIL_GO_TO_SEARCH:
						Sys.println( "ANT:RX_FAIL, search/wait");
						// wait for more messages
						//data.currentHeartRate = 0;
						mSearching = true;	
						break;
					case Ant.MSG_CODE_EVENT_RX_SEARCH_TIMEOUT:
						Sys.println( "ANT: EVENT SEARCH TIMEOUT");
						//closeSensor();
						//deviceCfg = null;
	            		//initialize(mSavedAntID);
						//data.currentHeartRate = 0;
						//mSearching = true;	            			            		
						break;
	            	default:
	            		// channel response
	            		//Sys.println( "ANT:EVENT: default");
	            		break;
	    		} 
        	} else {
        		//Sys.println("Not an RF EVENT");
        	} 
        } else {
    		//other message!
    		//Sys.println( "ANT other message " + msg.messageId);
    	}
    }
 }
