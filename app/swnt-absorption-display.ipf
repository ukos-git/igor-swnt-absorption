#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#include <Peak AutoFind>

//Absorption-Load
// Version 5: removed "default unit" in SetWaveScale
// Version 6: Added interpolate2 function to SetWaveScale, Added test for not equally spaced waves.
// Version 7: added linear Background removal function
// Version 8: added Differentition
// Version 9: split to different Files
// Version 10: Peak Find
// Version 11: Background Fit to Minima

Menu "AKH"
	Submenu "absorption"
		"Load File", AbsorptionLoadFile()
		"Load Directory", AbsorptionLoadFolder()
		"Differentiate", AbsorptionDifferentiateDisplay()
		"Differentiate2", AbsorptionDifferentiate2Display(0)
		"Differentiate2 offset", AbsorptionDifferentiate2Display(1)
		"Show Peaks", AbsorptionPeakDisplay()
		"Show Background 2exp", AbsorptionBackgroundDisplay()
		"Show Background exp", AbsorptionBackgroundDisplay(doubleExp = 0)
		"Remove Background 2exp", AbsorptionBackgroundDisplay(bgcorr = 1)
		"Remove Background exp", AbsorptionBackgroundDisplay(bgcorr = 1, doubleExp = 0)
		"Remove Jump at 800nm", AbsorptionRemoveJumpDisplay()
		"Linear Background on cursor", AbsorptionBgLinear()
		"Kataura", AbsorptionKatauraDisplay()
		"-"
		"SetWaveScale", SetWaveScale()
		"DisplayWave", DisplayWave()
		"-"
	end
End

Function AbsorptionDifferentiateDisplay()
	wave input = AbsorptionPrompt()
	wave output = AbsorptionDifferentiateWave(input, 10, 0)

	RemoveFromGraph/Z derivative1
	RemoveFromGraph/Z derivative2

	if (Dimsize(output, 1) == 3)
		AppendToGraph/R=axisderivative1 output[][%intensity]/TN=derivative1 vs output[][%wavelength]
	else
		AppendToGraph/R=axisderivative1 output/TN=derivative1
	endif

	SetAxis/A=2 axisderivative1
	ModifyGraph freePos(axisderivative1)=0
	ModifyGraph noLabel(axisderivative1)=1
	ModifyGraph lblPosMode(axisderivative1)=1
	ModifyGraph axisEnab(axisderivative1)={0.5,1}
	ModifyGraph zero(axisderivative1)=1
	Label axisderivative1 "1st derivative"

	ModifyGraph mode(derivative1)=7
	ModifyGraph rgb(derivative1)=(0,0,0)
End

Function AbsorptionDifferentiate2Display(setMinimum)
	Variable setMinimum
	wave output = AbsorptionDifferentiate2Wave(AbsorptionPrompt(), 10)
	if (setMinimum)
		Wavestats/Q output
		output-=V_max
	endif

	RemoveFromGraph/Z derivative1
	RemoveFromGraph/Z derivative2

	if (Dimsize(output, 1) == 3)
		AppendToGraph/R=axisderivative2 output[][%intensity]/TN=derivative2 vs output[][%wavelength]
	else
		AppendToGraph/R=axisderivative2 output/TN=derivative2
	endif

	SetAxis/A=2 axisderivative2
	ModifyGraph freePos(axisderivative2)=0
	ModifyGraph noLabel(axisderivative2)=1
	ModifyGraph axisEnab(axisderivative2)={0.5,1}
	Label axisderivative2 "2nd derivative"

	ModifyGraph mode(derivative2)=7
	ModifyGraph usePlusRGB(derivative2)=0,useNegRGB(derivative2)=1
#if IgorVersion() >= 7
	ModifyGraph negRGB(derivative2)=(65535,54607,32768)
	ModifyGraph plusRGB(derivative2)=(65535,0,0,32768)
#else
	ModifyGraph negRGB(derivative2)=(65535,54607,32768)
	ModifyGraph plusRGB(derivative2)=(65535,0,0)
#endif
	ModifyGraph hbFill=0, hBarNegFill(derivative2)=2
	ModifyGraph useNegPat(derivative2)=1
	ModifyGraph rgb(derivative2)=(0,0,0)

	ModifyGraph grid(axisderivative2)=1,lblPosMode(axisderivative2)=1
	ModifyGraph nticks(axisderivative2)=10
End

Function AbsorptionRemoveJumpDisplay()
	Wave wavInput = AbsorptionPrompt()
	Wave wavOutput = AbsorptionRemoveJump(wavInput)
	AppendToGraph wavOutput
end

// see AutoFindPeaksWorker from WM's <Peak AutoFind>
Function AbsorptionPeakDisplay()
	Wave/Z wavInput, wavOutput

	String tablename, tracename

	Wave wavInput = AbsorptionPrompt()
	Wave wavOutput = AbsorptionPeakFind(wavInput)

	tracename = "peaks_" + NameOfWave(wavInput)
	RemoveFromGraph/Z $tracename

	AppendToGraph wavOutput[][%positionY]/TN=$tracename vs wavOutput[][%wavelength]
	ModifyGraph rgb($tracename)=(0,0,65535)
	ModifyGraph mode($tracename)=3
	ModifyGraph marker($tracename)=19

	// show table for peak wave if not yet present
	tablename = "table_" + NameOfWave(wavOutput)
	DoWindow $tablename
	if (V_flag)
		DoWindow/F $tablename
		CheckDisplayed/W=$tablename wavOutput
		if(!V_Flag)
			AppendToTable wavOutput.ld // .ld: table with column names
		endif
	else
		Edit/N=$tablename wavOutput.ld as "Peaks for " + NameOfWave(wavInput) 
	endif
End

Function AbsorptionBackgroundDisplay([bgcorr, debugging, doubleExp])
	Variable bgcorr, debugging, doubleExp
	String trace_bgcorr, trace_bg
	if (ParamIsDefault(bgcorr))
		bgcorr = 0
	endif
	if (ParamIsDefault(debugging))
		debugging = 0
	endif
	if (ParamIsDefault(doubleExp))
		doubleExp = 1
	endif

	Wave wavInput = AbsorptionPrompt()
	if (bgcorr)
		Wave wavOutput = AbsorptionBackgroundRemove(wavInput, doubleExp = doubleExp)
	else
		Wave wavOutput = AbsorptionBackgroundConstruct(wavInput, debugging = debugging, doubleExp = doubleExp)
	endif

	trace_bgcorr = "corrected_" + NameOfWave(wavInput)
	trace_bg = "background_" + NameOfWave(wavInput)

	RemoveFromGraph/Z $trace_bgcorr
	RemoveFromGraph/Z $trace_bg
	if (bgcorr)
		AppendToGraph wavOutput/TN=$trace_bgcorr
		ModifyGraph zero(left)=1
	else
		AppendToGraph wavOutput/TN=$trace_bg
		ModifyGraph mode($trace_bg)=7,usePlusRGB($trace_bg)=1
#if (IgorVersion() >= 7.0)
		ModifyGraph plusRGB($trace_bg)=(65535,0,0,16384)
#else
		ModifyGraph plusRGB($trace_bg)=(65535,0,0)
#endif
		ModifyGraph hbFill($trace_bg)=2
		ModifyGraph zero(left)=0
	endif

	if (debugging)

	endif
End

Function AbsorptionKatauraDisplay()
	DFREF dfr
	String tableName, katauraWindow, traceAbsorption, oldTraceAbsorption, tracePeaks
	Variable numColumns
	Wave/Z peaks, diameter, lambda11, lambda22, absorption
	Wave/Z/T nmindex

	// SHOW ABSORPTION Spectrum in new Window
	// get wave
	Wave absorption = AbsorptionPrompt()
	numColumns = DimSize(absorption,1)
	katauraWindow = "kataura_" + NameOfWave(absorption)
	traceAbsorption = "absorption_" + NameOfWave(absorption)
	oldTraceAbsorption = ""
	DoWindow $katauraWindow
	if (V_flag)
		// modifiy old window
		DoWindow/F $katauraWindow
		// remember old trace
		CheckDisplayed/W=$katauraWindow absorption
		if(V_Flag)
			oldTraceAbsorption = AbsorptionWaveRefToTraceName(katauraWindow, absorption)
		endif
		// append new
		if(numColumns == 0)
			AppendToGraph/W=$katauraWindow/B=bottom_right/L=wavelength absorption/TN=$traceAbsorption
		elseif(numColumns == 3)
			AppendToGraph/W=$katauraWindow/B=bottom_right/L=wavelength absorption[][%wavelength]/TN=$traceAbsorption vs absorption[][%intensity]
		endif
		// remove old
		RemoveFromGraph/Z/W=$katauraWindow $oldTraceAbsorption
	else
		// create new window
		if(numColumns == 0)
			Display/B=bottom_right/L=wavelength/N=$katauraWindow absorption/TN=$traceAbsorption as "Kataura Plot for " + NameOfWave(absorption) 
		elseif(numColumns == 3)
			Display/B=bottom_right/L=wavelength/N=$katauraWindow absorption[][%wavelength]/TN=$traceAbsorption vs absorption[][%intensity] as "Kataura Plot for " + NameOfWave(absorption)
		endif
	endif
	Label/W=$katauraWindow bottom_right "optical density"

	// SHOW KATAURA
	// get waves
	if (!AbsorptionChiralityLoad(type="sds"))
		return 0
	endif
	dfr = AbsorptionChiralityDFR(type="sds")

	Wave diameter = dfr:diameter
	Wave lambda11 = dfr:lambda11
	Wave lambda22 = dfr:lambda22
	Wave/T nmindex = dfr:nmindex

	// remove old traces
	RemoveFromGraph/W=$katauraWindow/Z kataura1
	RemoveFromGraph/W=$katauraWindow/Z kataura2
	RemoveFromGraph/W=$katauraWindow/Z kataura3
	RemoveFromGraph/W=$katauraWindow/Z kataura4

	// add new traces
	AppendToGraph/W=$katauraWindow/B=bottom_left/L=wavelength lambda11/TN=kataura1 vs diameter
	AppendToGraph/W=$katauraWindow/B=bottom_left/L=wavelength lambda22/TN=kataura2 vs diameter
	AppendToGraph/W=$katauraWindow/B=bottom_left/L=wavelength lambda11/TN=kataura3 vs diameter
	AppendToGraph/W=$katauraWindow/B=bottom_left/L=wavelength lambda22/TN=kataura4 vs diameter
	ModifyGraph rgb(kataura2)=(0,0,0), rgb(kataura4)=(0,0,0)
	ModifyGraph mode(kataura1)=3, mode(kataura2)=3, mode(kataura3)=3, mode(kataura4)=3
	ModifyGraph marker(kataura1)=1,marker(kataura2)=1
	ModifyGraph textMarker(kataura3)={:Packages:Absorption:chirality:sds:nmindex,"default",0,0,5,0.00,10.00}
	ModifyGraph textMarker(kataura4)={:Packages:Absorption:chirality:sds:nmindex,"default",0,0,5,0.00,10.00}

	Label/W=$katauraWindow wavelength "wavelength / nm"
	Label/W=$katauraWindow bottom_left "diameter / nm"

	// show peaks
	tracePeaks = "peaks_" + NameOfWave(absorption)
	Wave peaks =  AbsorptionPeakFind(absorption)
	RemoveFromGraph/Z $tracePeaks
	AppendToGraph/W=$katauraWindow/B=bottom_right/L=wavelength peaks[][%wavelength]/TN=$tracePeaks vs peaks[][%positionY]
	ModifyGraph/W=$katauraWindow rgb($tracePeaks)=(0,0,65535)
	ModifyGraph/W=$katauraWindow mode($tracePeaks)=3
	ModifyGraph/W=$katauraWindow marker($tracePeaks)=19

	// set axis
	SetAxis/A=2
	SetAxis bottom_left 0.65,1.15
	ModifyGraph axisEnab(bottom_left)={0,0.79}, axisEnab(bottom_right)={0.8,1}
	ModifyGraph freePos=0
	ModifyGraph lblPosMode=1

	// set axis grid
	dfr = AbsorptionDFR(subDFR = NameOfWave(absorption))
	Make/O/T/N=(Dimsize(peaks, 0)) 	dfr:peakAxis_label/WAVE=axis_label 	= num2str(round(peaks[p][%wavelength]))
	Make/O/N=(Dimsize(peaks, 0)) 	dfr:peakAxis_tick/WAVE=axis_tick 	= peaks[p][%wavelength]
	ModifyGraph userticks(wavelength)={axis_tick,axis_label}
	ModifyGraph grid=1

	// add legend
	Legend/C/N=text0/J/F=0/A=MC "\\s(kataura1) E11\r\\s(kataura2) E22\r"

	// show table for peak wave if not yet present
	tablename = "table_" + NameOfWave(absorption)
	DoWindow $tablename
	if (V_flag)
		DoWindow/F $tablename
		CheckDisplayed/W=$tablename peaks
		if(!V_Flag)
			AppendToTable peaks.ld // .ld: table with column names
		endif
	else
		Edit/N=$tablename peaks.ld as "Peaks for " + NameOfWave(absorption)
	endif
End

Function DisplayWave()
	wave wavWave = $GetWave(strPrompt="test")
	if (WaveExists(wavWave))
		display wavWave
	endif
End
