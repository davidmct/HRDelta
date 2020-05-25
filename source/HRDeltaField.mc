using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Graphics as Graphics;
using Toybox.System as System;
//using Toybox.Lang as Lg;

const BORDER_PAD = 4;
const UNITS_SPACING = 2;
const TOP_PAD = 30;

const DEBUGGING = false;  // skip ANT search
const DEBUGGING2 = false; // HR data output
const mDebuggingANT  = false;

var fonts = [Graphics.FONT_XTINY,Graphics.FONT_TINY,Graphics.FONT_SMALL,Graphics.FONT_MEDIUM,Graphics.FONT_LARGE];
//           Graphics.FONT_NUMBER_MILD,Graphics.FONT_NUMBER_MEDIUM,Graphics.FONT_NUMBER_HOT,Graphics.FONT_NUMBER_THAI_HOT];

class DataViewBlock {
    var mLabelString;
    var mLabelX;
    var mLabelY;
	var mDataString;
    var mDataX;
    var mDataY;
    var mUnitsX;
    var mUnitsY;

    function initialize() {
    	mLabelString = "--";
    }
}

class HRDeltaView extends Ui.DataField {

    // should get strings from rez file
    hidden var AuxDataBlock = new DataViewBlock();
    hidden var OHRDataBlock = new DataViewBlock();
    hidden var DeltaDataBlock = new DataViewBlock();
    hidden var PercentDataBlock = new DataViewBlock();
    
    // Units string
    hidden var mUnitsString = Ui.loadResource(Rez.Strings.lHeartRateUnits);
    hidden var mUnitsWidth;
    hidden var mUnitsMaxWidth;
    
    // Font values
    hidden var mLabelFont = Graphics.FONT_SMALL;
    hidden var mDataFont;
    hidden var mDataFontAscent;
    hidden var mLabelFontAscent;
    hidden var mUnitsFont = Graphics.FONT_TINY;

    // field separator line
    hidden var separator;

    hidden var xCenter;
    hidden var yCenter;
    
    hidden var mFitContributor;
    //hidden var $._mApp.mAntSensor;
    hidden var mSensorFound = false;
    hidden var mTicker = 0;

    function initialize() {
        DataField.initialize();
        //$._mApp.mAntSensor = sensor;
        mSensorFound = false;
        mFitContributor = new AuxHRFitContributor(self);

    }

    // Set your layout here. Anytime the size of obscurity of
    // the draw context is changed this will be called.
    function onLayout(dc) {
        var width = dc.getWidth();
        var height = dc.getHeight();

        var vLayoutWidth;
        var vLayoutHeight;
        var vLayoutFontIdx;
        
        xCenter = width / 2;
        yCenter = height / 2;

		//System.println( "Layout started");
		
	    AuxDataBlock.mLabelString = Ui.loadResource(Rez.Strings.lAuxHeartRate);
	    OHRDataBlock.mLabelString = Ui.loadResource(Rez.Strings.lOHRHeartRate);
	    DeltaDataBlock.mLabelString = Ui.loadResource(Rez.Strings.lDeltaHeartRate);
	    PercentDataBlock.mLabelString = Ui.loadResource(Rez.Strings.lDeltaPercent);

	    var top = TOP_PAD + BORDER_PAD;
	    
        // Units width does not change, compute only once
        if (mUnitsWidth == null) {
            mUnitsWidth = dc.getTextWidthInPixels(mUnitsString, mUnitsFont) + UNITS_SPACING;
        }

        // Compute data width/height for vertical layouts - now side by side!
        vLayoutWidth = width - (2 * BORDER_PAD);
        // We have 4 sets of lable/data to fit in remaining vertical height
        // Allow same space at bottom as top to avoid circle cut off
        vLayoutHeight = (height - top * 2 - (4 * BORDER_PAD)) / 4;
        // test font in strip for text results
        // Use longest string here
        vLayoutFontIdx = selectFont(dc, AuxDataBlock.mLabelString, (vLayoutWidth / 2) - (2 * BORDER_PAD) - 30, vLayoutHeight);

        mDataFont = fonts[vLayoutFontIdx];
        // Set all text same size except units
        mLabelFont = mDataFont;
        mDataFontAscent = Graphics.getFontAscent(mDataFont);
        mLabelFontAscent = mDataFontAscent;
        
        // units font same as others for now
        mUnitsFont = mLabelFont;
        
        // now set coordinates of all elements               
		// May need to check that if data and label font size different still works
     	
     	// Center the field label in left hand side of watch ie width/2 - width/4
        AuxDataBlock.mLabelX = xCenter - (dc.getTextWidthInPixels(AuxDataBlock.mLabelString, mLabelFont) + BORDER_PAD);
       	OHRDataBlock.mLabelX = xCenter - (dc.getTextWidthInPixels(OHRDataBlock.mLabelString, mLabelFont) + BORDER_PAD);
       	DeltaDataBlock.mLabelX = xCenter - (dc.getTextWidthInPixels(DeltaDataBlock.mLabelString, mLabelFont) + BORDER_PAD);
       	PercentDataBlock.mLabelX = xCenter - (dc.getTextWidthInPixels(PercentDataBlock.mLabelString, mLabelFont) + BORDER_PAD);
       	
       	// Data X position as per Label but other side    	
	   	//AuxDataBlock.mDataX = BORDER_PAD + (vLayoutWidth / 2) - (mUnitsWidth / 2);
	   	AuxDataBlock.mDataX = xCenter + (vLayoutWidth / 5) - (mUnitsWidth / 2);
	    OHRDataBlock.mDataX = xCenter + (vLayoutWidth / 5) - (mUnitsWidth / 2);
	   	DeltaDataBlock.mDataX = xCenter + (vLayoutWidth / 5) - (mUnitsWidth / 2);
	   	PercentDataBlock.mDataX = xCenter + (vLayoutWidth / 5) - (mUnitsWidth / 2);
	   		    
	    // This order defines draw order
	    var mPosition1 = top;
	    var mPosition2 = mPosition1 + (BORDER_PAD + vLayoutHeight) * 1;
	    var mPosition3 = mPosition2 + (BORDER_PAD + vLayoutHeight) * 1;
	    var mPosition4 = mPosition3 + (BORDER_PAD + vLayoutHeight) * 1;
	    
	    // OHR label and variable
	    OHRDataBlock.mLabelY = mPosition1;
	    OHRDataBlock.mDataY = OHRDataBlock.mLabelY;
	   	//Strap label and value
	   	AuxDataBlock.mLabelY = mPosition2;
	    AuxDataBlock.mDataY = AuxDataBlock.mLabelY;
	    // Delta label and data
	    DeltaDataBlock.mLabelY = mPosition3;
	    DeltaDataBlock.mDataY = DeltaDataBlock.mLabelY;
	    // Percentage field
	    PercentDataBlock.mLabelY = mPosition4;
	    PercentDataBlock.mDataY = PercentDataBlock.mLabelY;
	    	    
	    // Precalculate units as far as possible
	    AuxDataBlock.mUnitsX = AuxDataBlock.mDataX + UNITS_SPACING;
	    AuxDataBlock.mUnitsY = AuxDataBlock.mDataY + mDataFontAscent - Graphics.getFontAscent(mUnitsFont);
    	OHRDataBlock.mUnitsX = OHRDataBlock.mDataX + UNITS_SPACING;
	    OHRDataBlock.mUnitsY = OHRDataBlock.mDataY + mDataFontAscent - Graphics.getFontAscent(mUnitsFont);
	    DeltaDataBlock.mUnitsX = DeltaDataBlock.mDataX + UNITS_SPACING;
	    DeltaDataBlock.mUnitsY = DeltaDataBlock.mDataY + mDataFontAscent - Graphics.getFontAscent(mUnitsFont);
      	PercentDataBlock.mUnitsX = PercentDataBlock.mDataX + UNITS_SPACING;
	    PercentDataBlock.mUnitsY = PercentDataBlock.mDataY + mDataFontAscent - Graphics.getFontAscent(mUnitsFont);
        // Do not use a separator line for vertical layout
        separator = null;

		if (DEBUGGING == true) {
        	System.println( "width " + vLayoutWidth);
        	System.println( "height "+ vLayoutHeight);
        	System.println( "Font "+ vLayoutFontIdx);
        	System.println("Field layout done");
        	
        	System.println("AuxDataBlock = "+AuxDataBlock.mLabelX+","+AuxDataBlock.mLabelY+","+AuxDataBlock.mDataX+","+AuxDataBlock.mDataY+","+AuxDataBlock.mUnitsX+","+AuxDataBlock.mUnitsY );
    		System.println("OHRDataBlock = "+OHRDataBlock.mLabelX+","+OHRDataBlock.mLabelY+","+OHRDataBlock.mDataX+","+OHRDataBlock.mDataY+","+OHRDataBlock.mUnitsX+","+OHRDataBlock.mUnitsY );
    		System.println("DeltaDataBlock = "+DeltaDataBlock.mLabelX+","+DeltaDataBlock.mLabelY+","+DeltaDataBlock.mDataX+","+DeltaDataBlock.mDataY+","+DeltaDataBlock.mUnitsX+","+DeltaDataBlock.mUnitsY );
    		System.println("PercentDataBlock = "+PercentDataBlock.mLabelX+","+PercentDataBlock.mLabelY+","+PercentDataBlock.mDataX+","+PercentDataBlock.mDataY+","+PercentDataBlock.mUnitsX+","+PercentDataBlock.mUnitsY );
        }
    }

    function selectFont(dc, string, width, height) {
        var testString = string; //Dummy string to test data width
        var fontIdx;
        var dimensions;

        //Search through fonts from biggest to smallest
        for (fontIdx = (fonts.size() - 1); fontIdx > 0; fontIdx--) {
            dimensions = dc.getTextDimensions(testString, fonts[fontIdx]);
            if ((dimensions[0] <= width) && (dimensions[1] <= height)) {
                //If this font fits, it is the biggest one that does
                break;
            }
        }

        return fontIdx;
    }    

    // The given info object contains all the current workout information.
    // Calculate a value and save it locally in this method.
    // Note that compute() and onUpdate() are asynchronous, and there is no
    // guarantee that compute() will be called before onUpdate().  
    function compute(info) {
        // See Activity.Info in the documentation for available information.
        if(info has :currentHeartRate){
            if(info.currentHeartRate != null){
                $._mApp.mAntSensor.data.OHRHeartRate = info.currentHeartRate;
            } else {
                $._mApp.mAntSensor.data.OHRHeartRate = null;
            }
        }
    
    	// push data to fit file and calc delta
    	// Only write delta and AUX if sensor is found
        mFitContributor.compute($._mApp.mAntSensor, mSensorFound);
   }
 
	// Display the value you computed here. This will be called
    // once a second when the data field is visible.
    function onUpdate(dc) {
    
        var bgColor = getBackgroundColor();
        var fgColor = Graphics.COLOR_WHITE;

        if (bgColor == Graphics.COLOR_WHITE) {
            fgColor = Graphics.COLOR_BLACK;
        }

        //System.println("onUpdate Field started");
        dc.setColor(Graphics.COLOR_TRANSPARENT, bgColor);
        dc.clear();

        dc.setColor(fgColor, Graphics.COLOR_TRANSPARENT);
        
        // force debug
        if (DEBUGGING) {
        	mSensorFound = true;
        	mTicker =6;
        	$._mApp.mAntSensor.mSearching = false;
        	$._mApp.mAntSensor.data.currentHeartRate = 110;
        	$._mApp.mAntSensor.data.OHRHeartRate = 100;
        	$._mApp.mAntSensor.data.OHRHeartRateDelta = $._mApp.mAntSensor.data.OHRHeartRate - $._mApp.mAntSensor.data.currentHeartRate ;

        }

        // Update status
        if ($._mApp.mAntSensor == null) {
            dc.drawText(xCenter, yCenter-50, Graphics.FONT_MEDIUM, "No Channel!", Graphics.TEXT_JUSTIFY_CENTER);
            mSensorFound = false;
            System.println("state $._mApp.mAntSensor null");
        } else if (true == $._mApp.mAntSensor.mSearching) {
            dc.drawText(xCenter, yCenter-50, Graphics.FONT_MEDIUM, "Searching...", Graphics.TEXT_JUSTIFY_CENTER);
            mSensorFound = false;
            System.println("state searching");
        } else {    
        	if (!mSensorFound) {
                mSensorFound = true;
                mTicker = 0;
            }
            
            if (mSensorFound && mTicker < 5) {
                var auxHRAntID = $._mApp.mAntSensor.deviceCfg.deviceNumber;
                mTicker++;
                dc.drawText(xCenter, yCenter-50, Graphics.FONT_MEDIUM, "Found " + auxHRAntID, Graphics.TEXT_JUSTIFY_CENTER);
            } else {
            	// need to draw all data elements
            	//System.println("Entered text draw of field");

	            var dAuxHeartRate;
	            if  ($._mApp.mAntSensor.data.currentHeartRate == null) {
	            	dAuxHeartRate = "--";
	            } else {
	            	if ($._mApp.mAntSensor.data.currentHeartRate == 0) {
	            		dAuxHeartRate = "--";
	            	} else{
	            		dAuxHeartRate = $._mApp.mAntSensor.data.currentHeartRate.format("%.0u");
	            	}
	            }
        		
        		var dOHRHeartRateDelta; 
        		if  ($._mApp.mAntSensor.data.OHRHeartRateDelta == null) {
	            	dOHRHeartRateDelta = "--";
	            } else {
		            if  ($._mApp.mAntSensor.data.OHRHeartRateDelta == 0) {
		            	dOHRHeartRateDelta = "0";
		            } else {
		            	dOHRHeartRateDelta = $._mApp.mAntSensor.data.OHRHeartRateDelta.format("%+.0i");
		            }
        		}
        		
        		var dOHRHeartRate; 
				if  ($._mApp.mAntSensor.data.OHRHeartRate == null) {
	            	dOHRHeartRate = "--";
	            } else {
	            	if ($._mApp.mAntSensor.data.OHRHeartRate == 0) {
	            		dOHRHeartRate = "--";
	            	} else {	
	            		dOHRHeartRate = $._mApp.mAntSensor.data.OHRHeartRate.format("%.0u");
	            	}
	            }
				
	            //Draw 3 pairs of HR label, then value then units          
	            dc.drawText(OHRDataBlock.mLabelX, OHRDataBlock.mLabelY, mLabelFont, OHRDataBlock.mLabelString, Graphics.TEXT_JUSTIFY_LEFT);
	            dc.drawText(OHRDataBlock.mDataX, OHRDataBlock.mDataY, mDataFont, dOHRHeartRate, Graphics.TEXT_JUSTIFY_CENTER);
	            dc.drawText(OHRDataBlock.mUnitsX + (dc.getTextWidthInPixels(dOHRHeartRate, mDataFont) / 2), OHRDataBlock.mUnitsY, mUnitsFont, mUnitsString, Graphics.TEXT_JUSTIFY_LEFT);
            
	            dc.drawText(AuxDataBlock.mLabelX, AuxDataBlock.mLabelY, mLabelFont, AuxDataBlock.mLabelString, Graphics.TEXT_JUSTIFY_LEFT);
	            dc.drawText(AuxDataBlock.mDataX, AuxDataBlock.mDataY, mDataFont, dAuxHeartRate, Graphics.TEXT_JUSTIFY_CENTER);
	            dc.drawText(AuxDataBlock.mUnitsX + (dc.getTextWidthInPixels(dAuxHeartRate, mDataFont) / 2), AuxDataBlock.mUnitsY, mUnitsFont, mUnitsString, Graphics.TEXT_JUSTIFY_LEFT);
	            
	            dc.drawText(DeltaDataBlock.mLabelX, DeltaDataBlock.mLabelY, mLabelFont, DeltaDataBlock.mLabelString, Graphics.TEXT_JUSTIFY_LEFT);
	            dc.drawText(DeltaDataBlock.mDataX, DeltaDataBlock.mDataY, mDataFont, dOHRHeartRateDelta, Graphics.TEXT_JUSTIFY_CENTER);
	            dc.drawText(DeltaDataBlock.mUnitsX + (dc.getTextWidthInPixels(dOHRHeartRateDelta, mDataFont) / 2), DeltaDataBlock.mUnitsY, mUnitsFont, mUnitsString, Graphics.TEXT_JUSTIFY_LEFT);
	            
	            // add code to display % difference
	            dc.drawText(PercentDataBlock.mLabelX, PercentDataBlock.mLabelY, mLabelFont, PercentDataBlock.mLabelString, Graphics.TEXT_JUSTIFY_LEFT);
	            
	            var mPercent = 0;
	            if ($._mApp.mAntSensor.data.currentHeartRate != 0) {
	            	// avoid divide by zero
	               	mPercent = ($._mApp.mAntSensor.data.OHRHeartRateDelta.toNumber().toFloat() / $._mApp.mAntSensor.data.currentHeartRate.toNumber().toFloat()) * 100;
	            }
	            
	            //if (DEBUGGING2 == true) { System.println("mPercent " + mPercent);}
	            
	            var mCalcPercent;
	            if ($._mApp.mAntSensor.data.OHRHeartRateDelta == 0) {
	            	// green OK
	            	dc.setColor( Graphics.COLOR_DK_GREEN, Graphics.COLOR_TRANSPARENT);
	            	mCalcPercent = "0%";
	            } else {
	            	dc.setColor( Graphics.COLOR_DK_RED, Graphics.COLOR_TRANSPARENT);
	            	mCalcPercent = mPercent.format("%+.0i") + "%";  
	            	mCalcPercent = ( mPercent == 0 ? "0%" : mCalcPercent);
	            	// clean up display of wacky values
	            	mCalcPercent = ( mPercent > 100 ? " >100%" : mCalcPercent); 	            
				}
				
				if (DEBUGGING2 == true) {
					System.println("Delta " + $._mApp.mAntSensor.data.OHRHeartRateDelta);
					System.println("Current " + $._mApp.mAntSensor.data.currentHeartRate);
					System.println("calc percent " + mCalcPercent);
					System.println("mPercent " + mPercent);
				}
				          	
	            dc.drawText(PercentDataBlock.mDataX, PercentDataBlock.mDataY, mDataFont, mCalcPercent, Graphics.TEXT_JUSTIFY_CENTER);
	            	
	            dc.setColor(fgColor, Graphics.COLOR_TRANSPARENT);
	            	
	            if (separator != null) {
	                dc.setColor(fgColor, fgColor);
	                dc.drawLine(separator[0], separator[1], separator[2], separator[3]); 
	            }
	        }
	    }
        // Call parent's onUpdate(dc) to redraw the layout ONLY if using layouts!
        //View.onUpdate(dc);
 		//System.println("redraw field complete");
    }
    
    function onTimerStart() {
        mFitContributor.setTimerRunning( true );
    }

    function onTimerStop() {
        mFitContributor.setTimerRunning( false );
    }

    function onTimerPause() {
        mFitContributor.setTimerRunning( false );
    }

    function onTimerResume() {
        mFitContributor.setTimerRunning( true );
    }

    function onTimerLap() {
        mFitContributor.onTimerLap();
    }

    function onTimerReset() {
        mFitContributor.onTimerReset();
    }

}
