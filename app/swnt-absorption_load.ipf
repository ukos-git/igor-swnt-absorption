#pragma rtGlobals=3		// Use modern global access method and strict wave access.

//Absorption-Load
// Version 5: removed "default unit" in SetWaveScale
// Version 6: Added interpolate2 function to SetWaveScale, Added test for not equally spaced waves.
// Version 7: added linear Background removal function

menu "Absorption"
	"Load File", AbsorptionLoadFile()
	"Linear Background on cursor", AbsorptionBgCorrPrompt()
	"-"
	"SetWaveScale", SetWaveScale()
	"DisplayWave", DisplayWave()
	"-"
end

//adapted function GetListOfFolderCont() from http://www.entorb.net/wickie/IGOR_Pro
Function /S GetListOfFolderCont(objectType)
	Variable objectType //1==Waves, 2==Vars, 3==Strings, 4==Folders
	//local variables
	String strSourceFolder, strList
	Variable i
	
	//init
	strSourceFolder = GetDataFolder(1) //":" is already added at the end of the string
	strList = ""
	
	//get List
	for(i=0;i<CountObjects(strSourceFolder, objectType ); i+=1)
		strList += strSourceFolder + GetIndexedObjName(strSourceFolder, objectType, i )+";"
	endFor
	
	return strList
End

//adapted function PopUpChooseFolder() from http://www.entorb.net/wickie/IGOR_Pro 
Function/S PopUpChooseFolder()
	//init local var
	String strSaveDataFolder, strList, strFolders
	
	//Save current DataFolder
	strSaveDataFolder = GetDataFolder(1)	
	//Move to root	
	SetDataFolder root:
	//Get List of Folders in root and add root foler
	strList = GetListOfFolderCont(4)
	strList = "root:;" + strList
	strFolders = "root:"
	Prompt strFolders,"Folder",popup,strList
	DoPrompt "",strFolders
	if (V_Flag == 1) 
		strFolders="" //return ""
	endif 
	//Move back to Old Data Folder
	SetDataFolder $strSaveDataFolder	
	Return strFolders
End


Function/S PopUpChooseWave(strDataFolder, [strText])
	String strDataFolder, strText
	strText = selectstring(paramIsDefault(strText), strText, "choose wave")
	//init local var
	String strSaveDataFolder, strList, strWave
	
	//Save current DataFolder
	strSaveDataFolder = GetDataFolder(1)	
	//Move to root	
	SetDataFolder $strDataFolder
	//Get List of Waves in root and add root foler
	strList = GetListOfFolderCont(1)

	Prompt strWave,strText,popup,strList
	DoPrompt "",strWave
	if (V_Flag == 1) 
		strWave=""//return ""
	endif 
	//Move back to Old Data Folder
	SetDataFolder $strSaveDataFolder	
	Return strWave
End

//adapted from function OpenFileDialog on http://www.entorb.net/wickie/IGOR_Pro
Function/S PopUpChooseFile([strPrompt])
	String strPrompt
	strPrompt = selectstring(paramIsDefault(strPrompt), strPrompt, "choose file")
	
	Variable refNum
	String outputPath
	String fileFilters = "Delimited Text Files (*.csv):.csv;"

	//Browse to Absorption-Folder
	String strPath = "Z:RAW:Absorption:"
	//String strPath = "C:Users:mak24gg:Documents:RAW:Absorption:"
	NewPath/O/Q path, strPath
	PathInfo/S path
	
	Open/D/F=fileFilters/R/M=strPrompt refNum
	outputPath = S_fileName
	return outputPath
End 

Function/S PopUpChooseDirectory()
	//Go to Base Path
	String strPath = "C:Users:mak24gg:Documents:AKHertel:RAW:Absorption:"
	NewPath/O/Q path, strPath
	PathInfo/S path
	//Open Dialog Box for choosing path
	NewPath/M="choose Folder"/O/Q path
	PathInfo path
	strPath = S_path
	GetFileFolderInfo/Q/Z=1 strPath

	if (V_isFolder)
		return strPath
	else
		return ""
	endif
End

Function/S PopUpChooseFileFolder([strPrompt])
	String strPrompt
	strPrompt = selectstring(paramIsDefault(strPrompt), strPrompt, "choose file")
	String strPath, strFiles, strFile	
	
	strPath = PopUpChooseDirectory()
	NewPath/O/Q path, strPath
	strFiles = IndexedFile(path,-1,".csv")
	if (strlen(strFiles)==0)
		print "No Files in selected Folder"
		return ""
	endif
	
	Prompt strFile,strPrompt,popup,strFiles
	DoPrompt "",strFile
	if (V_Flag == 1) 
		return ""
	endif
	
	return (strPath + strFile)
End

Function AbsorptionLoadFile()
	String strFile, strFileName, strFileType
	Variable numStart, numEnd
	
	strFile=PopUpChooseFile(strPrompt="Choose Absorption File")
	if (strlen(strFile)>0)
		//Headings are in 2nd(0-1-2-->1) line, data starts in 2nd line, load all (0) from 1 to 2 columns, where d
		LoadWave/A/D/J/K=1/L={1,2,0,0,2}/O/Q strFile
		wave wavWaveLength	= $stringfromlist(0,S_waveNames)
		wave wavIntensity = $stringfromlist(1,S_waveNames)
		//Delete last point.
		WaveStats/Q/Z/M=1 wavWaveLength		
		DeletePoints/M=0 (V_npnts),1, wavWaveLength, wavIntensity

		strFileName = ParseFilePath(3, strFile, ":", 0, 0)
		strFileType  = ParseFilePath(4, strFile, ":", 0, 0)
		strFileName = ReplaceString(" ",strFileName,"")
		
		if (WaveExists($strFileName))			
			//strFileName += "_autoload"
			Killwaves/Z $strFileName
		endif
		String strScaledWave = SetWaveScale(strX = nameofwave(wavWaveLength), strY = nameofwave(wavIntensity), strXUnit = "nm", strYUnit = "a.u.")
		wave wavScaledWave = $strScaledWave
		if (strlen(strScaledWave) > 0)
			duplicate/O wavScaledWave $strFileName		
			KillWaves/Z wavWaveLength, wavIntensity, wavScaledWave
			Display $strFileName
			return 1
		else
			KillWaves/Z wavWaveLength, wavIntensity
			return 0
		endif
		
		
	endif
End

Function/S GetWave([strPrompt])
	String strPrompt
	//This Function basically tests the String for convertability to a wave reference.
	String strWave = PopUpChooseWave(PopUpChooseFolder(), strText=strPrompt)
	wave wavWave = $strWave
	if (stringmatch(GetWavesDataFolder(wavWave, 2), strWave))
		return strWave
	else
		return ""
	endif
End

Function DisplayWave()
	wave wavWave = $GetWave(strPrompt="test")
	display wavWave
End

Function/S SetWaveScale([strX, strY, strXUnit strYUnit])
	String strX, strY, strXUnit, strYUnit
	strX	= selectstring(paramIsDefault(strX), strX, "")
	strY	= selectstring(paramIsDefault(strY), strY, "")
	strXUnit	= selectstring(paramIsDefault(strXUnit), strXUnit, "")	
	strYUnit	= selectstring(paramIsDefault(strYUnit), strYUnit, "")		

	//local Variables
	String strDirectory
	String strScaledWave = "", strDeltaWave = ""
	Wave wavX, wavY
	Variable numSize, numOffset, numDelta, numEnd
	Variable i

	//strDirectory = PopUpChooseFolder()
	strDirectory = "root:"	//by now, function only works in root directory.
	if (stringmatch(strX,""))
		strX=PopUpChooseWave(strDirectory, strText="choose x wave")
	endif
	if (stringmatch(strY,""))
		strY=PopUpChooseWave(strDirectory, strText="choose y wave")
	endif	

	if (!waveExists($strX) && !waveExists($strY))
		print "Error: Waves do not exist or user cancelled at Prompt"
		return ""
	endif
	
	wave wavX 	= $strX
	wave wavY 	= $strY
	

	numSize		= DimSize(wavX,0)
	numOffset	= wavX[0]
	numEnd 		= wavX[(numSize-1)]
	
	// calculate numDelta
	strDeltaWave = nameofwave(wavY) + "_Delta"
	Make/O/N=(numSize-1) $strDeltaWave
	wave wavDeltaWave = $strDeltaWave	
	// extract delta values in wave
	for (i=0; i<(numSize-1); i+=1)
		wavDeltaWave[i] = (wavX[(i+1)] - wavX[i])
	endfor
	WaveStats/Q/W wavDeltaWave
	KillWaves/Z  wavDeltaWave
	wave M_WaveStats
	numDelta = M_WaveStats[3]
	//if X-Wave is not equally spaced, set the half minimum delta at all points.
	// controll by calculating statistical error 2*sigma/rms
	if ((2*M_WaveStats[4]/M_WaveStats[5]*100)>5)
		print "SetWaveScale: Wave is not equally spaced. Setting new Delta."
		print "SetWaveScale: Report this if it happens. Maybe numDelta is not Correct."
		// avg - 2 * sdev
		if (M_WaveStats[3] > 0)
			numDelta = M_WaveStats[3] - 2 * M_WaveStats[4]
		else
			numDelta = M_WaveStats[3] + 2 * M_WaveStats[4]
		endif
	endif
	numSize = ceil(abs((numEnd - numOffset)/numDelta)+1)
	KillWaves/Z  M_WaveStats
	
	// interpolate to new Wave.
	
	// alternative solution:
	//	interpolate can also take /N=(numSize) flag without the l=3 
	//	specify Y=newWave as the new wavename without the need to create the wave prior to call
	//	interpolate2/N=(numSize)/Y=wavScaledWave wavX,wavY
	strScaledWave = nameofwave(wavY) + "_L"	
	Make/O/N=(numSize) $strScaledWave	
	wave wavScaledWave = $strScaledWave	
	//alternative solution: SetScale/P x, numOffset, numDelta, strXUnit, wavScaledWave
	SetScale/I x, numOffset, numEnd, strXUnit, wavScaledWave
	SetScale/P y, 1, 1, strYUnit, wavScaledWave	
	interpolate2/I=3/T=1/Y=wavScaledWave wavX,wavY
	
	return nameofwave(wavScaledWave)
End

Function RemoveWaveScale(wavWave)
	Wave wavWave
	Variable numXOffset, numXDelta, numYOffset, numYDelta
	String strXUnit, strYUnit
	
	strXUnit = ""
	strYUnit = ""
	numYOffset = DimOffset(wavWave,1)
	numXOffset = DimOffset(wavWave,0)
	numYDelta = DimDelta(wavWave,1)
	numXDelta = DimDelta(wavWave,0)
	SetScale/P x, numXOffset, numXDelta, strXUnit, wavWave
	SetScale/P y, numYOffset, numYDelta, strYUnit, wavWave
End

// no error checking here.
Function AbsorptionBgCorr(wavInput)
	wave wavInput
	
	SetDataFolder root:
	make/o/n=2 line
	line={wavInput[pcsr(A)],wavInput[pcsr(B)]}
	SetScale x, x2pnt(wavInput,pcsr(A)), x2pnt(wavInput, pcsr(B)), line
	string strNewWave = nameofwave(wavInput) + "bgcorr"
	duplicate/O wavInput $strNewWave
	wave wavOutput = $strNewWave
	interpolate2/T=1/I=3/Y=wavOutput line
	wavOutput = wavInput-wavOutput
	Killwaves/Z line
End

Function AbsorptionBgCorrPrompt()
	string strWave = "absorption"
	
	Prompt strWave, "Wave for Peak-Analysis",popup TraceNameList("", ";",1)	//top graph "", seperate by ";", option 1: Include contour traces
	DoPrompt "Enter wave", strWave

	//$strIntensity is not possible for renamed traces: tracename#1 tracename#2 (see Instance Notation)
	wave wavInput = TraceNameToWaveRef("",strWave) 
	AbsorptionBgCorr(wavInput)
End