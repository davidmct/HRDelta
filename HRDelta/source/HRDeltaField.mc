using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Graphics as Graphics;
using Toybox.System as System;

const BORDER_PAD = 4;
const UNITS_SPACING = 2;
const TOP_PAD = 10;

const DEBUGGING = false;

var fonts = [Graphics.FONT_XTINY,Graphics.FONT_TINY,Graphics.FONT_SMALL,Graphics.FONT_MEDIUM,Graphics.FONT_LARGE,
             Graphics.FONT_NUMBER_MILD,Graphics.FONT_NUMBER_MEDIUM,Graphics.FONT_NUMBER_HOT,Graphics.FONT_NUMBER_THAI_HOT];

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
    hidden var mSensor;
    hidden var mSensorFound = false;
    hidden var mTicker = 0;

    function initialize(sensor) {
        DataField.initialize();
        mSensor = sensor;
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

	    AuxDataBlock.mLabelString = Ui.loadResource(Rez.Strings.lAuxHeartRate);
	    OHRDataBlock.mLabelString = Ui.loadResource(Rez.Strings.lOHRHeartRate);
	    DeltaDataBlock.mLabelString = Ui.loadResource(Rez.Strings.lDeltaHeartRate);
	    
	    var top = TOP_PAD + BORDER_PAD;
	    
        // Units width does not change, compute only once
        if (mUnitsWidth == null) {
            mUnitsWidth = dc.getTextWidthInPixels(mUnitsString, mUnitsFont) + UNITS_SPACING;
        }

		System.println( "Layout started");

        // Compute data width/height for vertical layouts
        vLayoutWidth = width - (2 * BORDER_PAD);
        // We have 3 sets of lable/data to fit in remaining vertical height
        // Allow same space at bottom as top to avoid circle cut off
        vLayoutHeight = (height - top * 2 - (3 * BORDER_PAD)) / 6;
        // test font in strip for text results
        vLayoutFontIdx = selectFont(dc, (vLayoutWidth - mUnitsWidth), vLayoutHeight);

        mDataFont = fonts[vLayoutFontIdx];
        // Set all text same size except units
        mLabelFont = mDataFont;
        mDataFontAscent = Graphics.getFontAscent(mDataFont);
        mLabelFontAscent = mDataFontAscent;
        
        // now set coordinates of all elements               
		// May need to check that if data and label font size different still works
     	
     	// Center the field label
        AuxDataBlock.mLabelX = width / 2;
       	OHRDataBlock.mLabelX = width / 2;
       	DeltaDataBlock.mLabelX = width / 2;
       	
       	// Data X position always same     	
	   	AuxDataBlock.mDataX = BORDER_PAD + (vLayoutWidth / 2) - (mUnitsWidth / 2);
	    OHRDataBlock.mDataX = BORDER_PAD + (vLayoutWidth / 2) - (mUnitsWidth / 2);
	   	DeltaDataBlock.mDataX = BORDER_PAD + (vLayoutWidth / 2) - (mUnitsWidth / 2);
	   		    
	    // This order defines draw order
	    var mPosition1 = top;
	    var mPosition2 = mPosition1 + (BORDER_PAD + vLayoutHeight) * 2;
	    var mPosition3 = mPosition2 + (BORDER_PAD + vLayoutHeight) * 2;
	    
	    // OHR label and variable
	    OHRDataBlock.mLabelY = mPosition1;
	    OHRDataBlock.mDataY = OHRDataBlock.mLabelY + BORDER_PAD + vLayoutHeight - (mDataFontAscent / 2);
	   	//Strap label and value
	   	AuxDataBlock.mLabelY = mPosition2;
	    AuxDataBlock.mDataY = AuxDataBlock.mLabelY + BORDER_PAD + vLayoutHeight - (mDataFontAscent / 2);
	    // Delta label and data
	    DeltaDataBlock.mLabelY = mPosition3;
	    DeltaDataBlock.mDataY = DeltaDataBlock.mLabelY + BORDER_PAD + vLayoutHeight - (mDataFontAscent / 2);
	    
	    // Precalculate units as far as possible
	    AuxDataBlock.mUnitsX = AuxDataBlock.mDataX + UNITS_SPACING;
	    AuxDataBlock.mUnitsY = AuxDataBlock.mDataY + mDataFontAscent - Graphics.getFontAscent(mUnitsFont);
    	OHRDataBlock.mUnitsX = OHRDataBlock.mDataX + UNITS_SPACING;
	    OHRDataBlock.mUnitsY = OHRDataBlock.mDataY + mDataFontAscent - Graphics.getFontAscent(mUnitsFont);
	    DeltaDataBlock.mUnitsX = DeltaDataBlock.mDataX + UNITS_SPACING;
	    DeltaDataBlock.mUnitsY = DeltaDataBlock.mDataY + mDataFontAscent - Graphics.getFontAscent(mUnitsFont);
      
        // Do not use a separator line for vertical layout
        separator = null;

        xCenter = dc.getWidth() / 2;
        yCenter = dc.getHeight() / 2;
        System.println( "width " + vLayoutWidth);
        System.println( "height "+ vLayoutHeight);
        System.println( "Font "+ vLayoutFontIdx);
        System.println("Field layout done");
    }

    function selectFont(dc, width, height) {
        var testString = "88.88"; //Dummy string to test data width
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
                mSensor.data.OHRHeartRate = info.currentHeartRate;
            } else {
                mSensor.data.OHRHeartRate = null;
            }
        }
    
    	// push data to fit file and calc delta
        mFitContributor.compute(mSensor);
   }
 
	// Display the value you computed here. This will be called
    // once a second when the data field is visible.
    function onUpdate(dc) {
    
        var bgColor = getBackgroundColor();
        var fgColor = Graphics.COLOR_WHITE;

        if (bgColor == Graphics.COLOR_WHITE) {
            fgColor = Graphics.COLOR_BLACK;
        }

        System.println("onUpdate Field started");
        dc.setColor(Graphics.COLOR_TRANSPARENT, bgColor);
        dc.clear();

        dc.setColor(fgColor, Graphics.COLOR_TRANSPARENT);
        
        // force debug
        if (DEBUGGING) {
        	mSensorFound = true;
        	mTicker =6;
        	mSensor.searching = false;
        	mSensor.data.currentHeartRate = 100;
        }

        // Update status
        if (mSensor == null) {
            dc.drawText(xCenter, yCenter-50, Graphics.FONT_MEDIUM, "No Channel!", Graphics.TEXT_JUSTIFY_CENTER);
            mSensorFound = false;
            System.println("state msensor null");
        } else if (true == mSensor.searching) {
            dc.drawText(xCenter, yCenter-50, Graphics.FONT_MEDIUM, "Searching...", Graphics.TEXT_JUSTIFY_CENTER);
            mSensorFound = false;
            System.println("state searching");
        } else {    
        	if (!mSensorFound) {
                mSensorFound = true;
                mTicker = 0;
            }
            
            if (mSensorFound && mTicker < 5) {
                var auxHRAntID = mSensor.deviceCfg.deviceNumber;
                mTicker++;
                dc.drawText(xCenter, yCenter-50, Graphics.FONT_MEDIUM, "Found " + auxHRAntID, Graphics.TEXT_JUSTIFY_CENTER);
            } else {
            	// need to draw all data elements
            	System.println("Entered text draw of field");

	            var dAuxHeartRate;
	            if  (mSensor.data.currentHeartRate == null) {
	            	dAuxHeartRate = "--";
	            } else {
	            	dAuxHeartRate = mSensor.data.currentHeartRate.format("%.0u");
	            }
        		
        		var dOHRHeartRateDelta; 
        		if  (mSensor.data.OHRHeartRateDelta == null) {
	            	dOHRHeartRateDelta = "--";
	            } else {
	            	dOHRHeartRateDelta = mSensor.data.OHRHeartRateDelta.format("%+.0i");
	            }
        		
        		var dOHRHeartRate; 
				if  (mSensor.data.OHRHeartRate == null) {
	            	dOHRHeartRate = "--";
	            } else {
	            	dOHRHeartRate = mSensor.data.OHRHeartRate.format("%.0u");
	            }
				
	            //Draw 3 pairs of HR label, then value then units          
	            dc.drawText(OHRDataBlock.mLabelX, OHRDataBlock.mLabelY, mLabelFont, OHRDataBlock.mLabelString, Graphics.TEXT_JUSTIFY_CENTER);
	            dc.drawText(OHRDataBlock.mDataX, OHRDataBlock.mDataY, mDataFont, dOHRHeartRate, Graphics.TEXT_JUSTIFY_CENTER);
	            dc.drawText(OHRDataBlock.mUnitsX + (dc.getTextWidthInPixels(dOHRHeartRate, mDataFont) / 2), OHRDataBlock.mUnitsY, mUnitsFont, mUnitsString, Graphics.TEXT_JUSTIFY_LEFT);
            
	            dc.drawText(AuxDataBlock.mLabelX, AuxDataBlock.mLabelY, mLabelFont, AuxDataBlock.mLabelString, Graphics.TEXT_JUSTIFY_CENTER);
	            dc.drawText(AuxDataBlock.mDataX, AuxDataBlock.mDataY, mDataFont, dAuxHeartRate, Graphics.TEXT_JUSTIFY_CENTER);
	            dc.drawText(AuxDataBlock.mUnitsX + (dc.getTextWidthInPixels(dAuxHeartRate, mDataFont) / 2), AuxDataBlock.mUnitsY, mUnitsFont, mUnitsString, Graphics.TEXT_JUSTIFY_LEFT);
	            
	            dc.drawText(DeltaDataBlock.mLabelX, DeltaDataBlock.mLabelY, mLabelFont, DeltaDataBlock.mLabelString, Graphics.TEXT_JUSTIFY_CENTER);
	            dc.drawText(DeltaDataBlock.mDataX, DeltaDataBlock.mDataY, mDataFont, dOHRHeartRateDelta, Graphics.TEXT_JUSTIFY_CENTER);
	            dc.drawText(DeltaDataBlock.mUnitsX + (dc.getTextWidthInPixels(dOHRHeartRateDelta, mDataFont) / 2), DeltaDataBlock.mUnitsY, mUnitsFont, mUnitsString, Graphics.TEXT_JUSTIFY_LEFT);
	            	
	            if (separator != null) {
	                dc.setColor(fgColor, fgColor);
	                dc.drawLine(separator[0], separator[1], separator[2], separator[3]);
	            }
	        }
	    }
        // Call parent's onUpdate(dc) to redraw the layout ONLY if using layouts!
        //View.onUpdate(dc);
 		System.println("redraw field complete");
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
