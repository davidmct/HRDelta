using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Graphics as Graphics;
using Toybox.System as System;

class HRDeltaApp extends App.AppBase {
	
	var mSensor; 
	var mAntID = 0;

    function initialize() {
        AppBase.initialize();
        var mApp = Application.getApp();
        mAntID = mApp.getProperty("pAuxHRAntID");
    }

    // onStart() is called on application start up
    function onStart(state) {
    	try {
            //Create the sensor object and open it
            mSensor = new AuxHRSensor(mAntID);
            mSensor.open();
        } catch(e instanceof Ant.UnableToAcquireChannelException) {
            System.println(e.getErrorMessage());
            mSensor = null;
        }
    }

    // onStop() is called when your application is exiting
    function onStop(state) {
    	mSensor.closeSensor();
    	return false;
    }

   
    //! Return the initial view of your application here
    function getInitialView() {
        return [ new HRDeltaView(mSensor) ];
    }

}