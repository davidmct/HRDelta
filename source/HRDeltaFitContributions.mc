//
// Copyright 2015-2016 by Garmin Ltd. or its subsidiaries.
// Subject to Garmin SDK License Agreement and Wearables
// Application Developer Agreement.
//

using Toybox.WatchUi as Ui;
using Toybox.System as Sys;
using Toybox.FitContributor as Fit;

const AUX_HR_FIELD_ID    = 0;
const DELTA_HR_FIELD_ID  = 1;
const AUX_HR_AVG_FIELD_ID  = 2;
const OHR_HR_AVG_FIELD_ID  = 3;

class AuxHRFitContributor {

    hidden var mTimerRunning = false;

    // OHR is recorded already in the FIT file so just need Aux and Difference
    // Difference could come by post processing but for fun added in
    // FIT Contributions variables
    hidden var mAuxHRField       = null;
    hidden var mDeltaHRField     = null;
    hidden var mAuxHRAvgField	= null;
	hidden var mOHRAvgField 	= null;
	
    // Constructor
    function initialize(dataField) {
    	// assume SINT is signed!
        mAuxHRField    = dataField.createField("AuxHeartRate",   AUX_HR_FIELD_ID,     Fit.DATA_TYPE_UINT16, { :mesgType=>Fit.MESG_TYPE_RECORD, :units=>"bpm" });
        mDeltaHRField  = dataField.createField("DeltaHeartRate", DELTA_HR_FIELD_ID,   Fit.DATA_TYPE_SINT16, { :mesgType=>Fit.MESG_TYPE_RECORD, :units=>"bpm" });
       	mAuxHRAvgField = dataField.createField("AuxBPMavg",      AUX_HR_AVG_FIELD_ID, Fit.DATA_TYPE_UINT16, { :mesgType=>Fit.MESG_TYPE_RECORD, :units=>"bpm" });
       	mOHRAvgField =   dataField.createField("OpticalBPMavg",  OHR_HR_AVG_FIELD_ID, Fit.DATA_TYPE_UINT16, { :mesgType=>Fit.MESG_TYPE_RECORD, :units=>"bpm" });
       	       	
        mAuxHRField.setData(0);
        mDeltaHRField.setData(0);
        mAuxHRAvgField.setData( 0);
        mOHRAvgField.setData( 0);
    }

(:pre0_2_8Code)
    function compute(sensor, mSensorFoundX) {
        if( sensor != null ) {
            var heartRate = sensor.data.currentHeartRate;

			// we have a sensor and a heart rate
            if ((heartRate != null) && mSensorFoundX)  {
                mAuxHRField.setData( heartRate.toNumber() );
               
                // intialisation should have happened as we have a heartrate
                // maybe simulator issue until you start faking data
                var OHRRate = sensor.data.OHRHeartRate;
                if (OHRRate != null) {
                	sensor.data.OHRHeartRateDelta = OHRRate - heartRate;
                	mDeltaHRField.setData( sensor.data.OHRHeartRateDelta.toNumber());
                } else {
                	// No OHR so hence no delta either!!
                	sensor.data.OHRHeartRateDelta = 0;
            		mDeltaHRField.setData( sensor.data.OHRHeartRateDelta.toNumber());
                }
            } else {
            	sensor.data.OHRHeartRateDelta = 0;
            	mDeltaHRField.setData( sensor.data.OHRHeartRateDelta.toNumber());
            	mAuxHRField.setData( 0 );
            }
            
            Sys.println( "OHR " + sensor.data.OHRHeartRate);
            Sys.println( "Strap HR " + heartRate);
            Sys.println( "Delta HR " + sensor.data.OHRHeartRateDelta);
        }
    }

(:post0_2_8Code)    
    function compute(sensor, mSensorFoundX) {
        if( sensor != null ) {
            var heartRate = $._mApp.currentHeartRate;

			// we have a sensor and a heart rate
            if ((heartRate != null) && mSensorFoundX)  {
                mAuxHRField.setData( heartRate.toNumber() );
                
                $._mApp.cntStrap++;
                $._mApp.sumStrap += heartRate;
                mAuxHRAvgField.setData( ($._mApp.sumStrap / $._mApp.cntStrap).toNumber() );
                
				//Sys.println("B1: s cnt "+$._mApp.cntStrap);
                
                // intialisation should have happened as we have a heartrate
                // maybe simulator issue until you start faking data
                var OHRRate = $._mApp.OHRHeartRate;            
                
                if (OHRRate != null) {                 
                	$._mApp.cntOHR++;
                	$._mApp.sumOHR += OHRRate;
                	mOHRAvgField.setData( ($._mApp.sumOHR / $._mApp.cntOHR).toNumber() );                  
                
                	$._mApp.OHRHeartRateDelta = OHRRate - heartRate;
                	mDeltaHRField.setData( $._mApp.OHRHeartRateDelta.toNumber());
                	
                	//Sys.println("B2: o cnt "+$._mApp.cntOHR);
                	
                } else {
                	// No OHR so hence no delta either!!
                	$._mApp.OHRHeartRateDelta = 0;
            		mDeltaHRField.setData( $._mApp.OHRHeartRateDelta.toNumber());
            		
            		//Sys.println("B3");
            		
                }
                
            } else {
            	$._mApp.OHRHeartRateDelta = 0;
            	mDeltaHRField.setData( $._mApp.OHRHeartRateDelta.toNumber());
            	mAuxHRField.setData( 0 );
            	mAuxHRAvgField.setData( 0);
            	mOHRAvgField.setData( 0);
            	
            	//Sys.println("B4");
            }
            
            //Sys.println( "OHR, Strap, Delta: " + $._mApp.OHRHeartRate+", "+heartRate+", "+$._mApp.OHRHeartRateDelta );
        }
    }

    function setTimerRunning(state) {
        mTimerRunning = state;
    }

    function onTimerLap() {
        
    }

    function onTimerReset() {
 
    }

}
