using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Graphics as Graphics;
using Toybox.System as System;


//0.2.7 
// Look at adding check that ANT payload is at least 2 long
// Maybe update to HRV version of code
//0.2.8
// updated ANT code again
// Moved to DeltaWidget code as this works!

var _mApp;

class HRDeltaApp extends App.AppBase {
	
	//var mAntSensor; 
	//var mAntID = 0;
	
	//0.2.8 - restructure
	var mSensor = null; 
	var mOHRsensor = null;
	//var mSensorFound = false;
	var mAntID = 0;
	var currentHeartRate = 0;
	var OHRHeartRateDelta = 0;
	var OHRHeartRate = 0;

    function initialize() {
        AppBase.initialize();
        $._mApp = Application.getApp();
        mAntID = $._mApp.getProperty("pAuxHRAntID");
        System.println("STARTED");
    }

    // onStart() is called on application start up
(:pre0_2_8Code)
    function onStart(state) {
    	try {
            //Create the sensor object and open it
            mAntSensor = new AuxHRSensor(mAntID);
            mAntSensor.open();
        } catch(e instanceof Ant.UnableToAcquireChannelException) {
            System.println(e.getErrorMessage());
            mAntSensor = null;
        }
    }

(:post0_2_8Code) 
	// 0.2.8 null as handled in view    
 	function onStart(state) {
 	}

    // onStop() is called when your application is exiting
(:pre0_2_8Code)
    function onStop(state) {
    	mAntSensor.closeSensor();
    	return false;
    }

(:post0_2_8Code)    
	function onStop(state) {  	
    	System.println("HRDelta onStop() called");
    	
    	if (mSensor != null ) {mSensor.closeSensor();}
    	//if (mOHRsensor !=null ) {mOHRsensor.stopIntSensor();}
    	return false;
    }

   
    //! Return the initial view of your application here
    function getInitialView() {
        return [ new HRDeltaView() ];
    }

}