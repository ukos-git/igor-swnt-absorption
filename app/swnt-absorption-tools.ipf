#pragma rtGlobals=3		// Use modern global access method and strict wave access.

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

Function/S PopUpChooseDirectory(strPath)
    String strPath

	// set start path
	NewPath/Z/O/Q path, strPath
	PathInfo/S path
	if(!V_flag)
		strPath = SpecialDirPath("Documents", 0, 0, 0)
		NewPath/Z/O/Q path, strPath
		PathInfo/S path
	endif

	NewPath/Z/M="choose Folder"/O/Q path
	PathInfo path
	if(!V_flag)
		return PopUpChooseDirectory(strPath)
	endif
	strPath = S_path

	GetFileFolderInfo/Q/Z=1 strPath
	if (!V_isFolder)
		return ""
	endif

    return strPath
End

Function/S PopUpChooseFileFolder([strPrompt])
	String strPrompt
	strPrompt = selectstring(paramIsDefault(strPrompt), strPrompt, "choose file")
	String strPath, strFiles, strFile	
	
	strPath = PopUpChooseDirectory("X:Documents:RAW:Absorption")
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

Function/S GetWave([strPrompt])
	String strPrompt
	//This Function basically tests the String for convertability to a wave reference.
	String strWave = PopUpChooseWave(PopUpChooseFolder(), strText=strPrompt)
	wave wavWave = $strWave
	if (WaveExists(wavWave))
	//if (stringmatch(GetWavesDataFolder(wavWave, 2), strWave))
		return strWave
	else
		return ""
	endif
End

Function SetWaveScale([wavX, wavY, strUnit])
	Wave wavX, WavY
	String strUnit
	strUnit	= SelectString(ParamIsDefault(strUnit), strUnit, "")	
	
	if (ParamIsDefault(wavX))
		// todo: strDirectory = PopUpChooseFolder()
		wave wavX = $PopUpChooseWave("root:", strText="choose x wave")
	endif
	if (ParamIsDefault(wavY))
		wave wavY = $PopUpChooseWave("root:", strText="choose y wave")
	endif

	Variable numOffset, numDelta

	if (!WaveExists(wavX) || !WaveExists(wavY))
		print "Error: Waves do not exist"
		return 0
	endif

	numOffset	= wavX[0]
	numDelta 	= AbsorptionDelta(wavX, normal=1)
	

	SetScale/P x, numOffset, numDelta, strUnit, wavY	

	return 1
End

Function AbsorptionDelta(wavInput, [normal])
	Wave wavInput
	Variable normal
	if (ParamIsDefault(normal))
		normal = 0
	endif
	
	Variable numSize, numDelta, i
	String strDeltaWave

	numSize		= DimSize(wavInput,0)
	if (numSize > 1)
		if (normal)
			numDelta = (wavInput[inf] - wavInput[0])/(numSize-1)
		else
			// calculate numDelta
			Make/FREE/O/N=(numSize-1) wavDeltaWave
			for (i=0; i<(numSize-1); i+=1)
				wavDeltaWave[i] = (wavInput[(i+1)] - wavInput[i])
			endfor
			WaveStats/Q/W wavDeltaWave
	
			wave M_WaveStats
			numDelta = M_WaveStats[3] //average
			//print "Wave " + nameofwave(wavInput) + " has a Delta of " + num2str(numDelta) + " with a standard deviation of " + num2str(M_WaveStats[4])
			//if X-Wave is not equally spaced, set the half minimum delta at all points.
			// controll by calculating statistical error 2*sigma/rms		
			if ((2*M_WaveStats[4]/M_WaveStats[5]*100)>5)
				print "PLEMd2Delta: Wave is not equally spaced. Check Code and calculate new Delta."
				// minimum
				numDelta = M_WaveStats[10]
				// avg - 2 * sdev : leave out the minimum 5% for statistical resaons
				if (M_WaveStats[3] > 0)		// sdev is always positive ;-)
					numDelta = M_WaveStats[3] - 2 * M_WaveStats[4]
				else
					numDelta = M_WaveStats[3] + 2 * M_WaveStats[4]
				endif
			endif
			// not used put possibly needed, when a new Delta Value is returned.
			
			KillWaves/Z  M_WaveStats
		endif
	else
		numDelta = 0
	endif
	return numDelta
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

// See WM's CheckDisplayed
Function AbsorptionIsWaveInGraph(search)
	Wave search

	String currentTraces
	Variable countTraces, i
	Variable isPresent = 0

	currentTraces = TraceNameList("",";",1)
	countTraces = ItemsInList(currentTraces)

	for (i=0;i<countTraces;i+=1)
		Wave wv = TraceNameToWaveRef("", StringFromList(i,currentTraces) )
			if (cmpstr(NameOfWave(wv),NameOfWave(search)) == 0)
				isPresent = 1
			endif
		WaveClear wv
	endfor

	return isPresent
End

Function/S AbsorptionWaveRefToTraceName(graphNameStr, WaveRef)
	String graphNameStr
	Wave WaveRef
	
	String traces, trace
	Variable numTraces, i
	Variable isPresent = 0
		
	traces = TraceNameList(graphNameStr,";",1)
	numTraces = ItemsInList(traces)
	trace = ""
	for(i = 0; i < numTraces; i += 1)
		trace = StringFromList(i,traces)
		Wave wv = TraceNameToWaveRef(graphNameStr, trace)
			if (cmpstr(GetWavesDataFolder(wv, 1), GetWavesDataFolder(WaveRef, 1)) == 0)
				break
			endif
		WaveClear wv
	endfor

	return trace
End
