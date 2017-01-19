#pragma rtGlobals=3		// Use modern global access method and strict wave access.

menu "Absorption"
	"Load File", AbsorptionLoadFile()
end

menu "Wave-Toolbox"
	"DisplayWave", DisplayWave()
	"SetWaveScale", SetWaveScale()
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
	String strPath = "C:Users:mak24gg:Documents:AKHertel:RAW:Absorption:"
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
	String strFile, strFileName
	Variable numStart, numEnd
	
	//strFile=PopUpChooseFileFolder(strPrompt="choose csv file")
	strFile=PopUpChooseFile(strPrompt="Choose Absorption File")
	if (strlen(strFile)>0)
		LoadWave/A/D/J/K=1/L={1,2,0,0,2}/O/Q strFile //Headings are in 2nd(0-1-2-->1) line, data starts in 2nd line, load all (0) from 1 to 2 columns, where d
		wave wavWaveLength	= $stringfromlist(0,S_waveNames)
		wave wavIntensity = $stringfromlist(1,S_waveNames)
		//Delete last point.
		WaveStats/Q/Z/M=1 wavWaveLength		
		DeletePoints/M=0 (V_npnts),1, wavWaveLength, wavIntensity

		numEnd = strsearch(strFile, ".",(strlen(strFile)-1),1)-1
		numStart=strsearch(strFile, ":",numEnd,1)
		strFileName = strFile[numStart, numEnd]
		if (WaveExists($strFileName))			
			//strFileName += "_autoload"
		endif

		if (SetWaveScale(strX = nameofwave(wavWaveLength), strY = nameofwave(wavIntensity), strXUnit = "nm", strYUnit = "a.u."))
			KillWaves/Z $strFileName
			duplicate/O wavIntensity $strFileName		
			KillWaves/Z wavWaveLength, wavIntensity
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

Function SetWaveScale([strX, strY, strXUnit strYUnit])
	String strX, strY, strXUnit, strYUnit
	strX	= selectstring(paramIsDefault(strX), strX, "")
	strY	= selectstring(paramIsDefault(strY), strY, "")
	strXUnit	= selectstring(paramIsDefault(strXUnit), strXUnit, "default unit")	
	strYUnit	= selectstring(paramIsDefault(strYUnit), strYUnit, "default unit")		

	//local Variables
	String strDirectory
	Wave wavX, wavY
	Variable numSize, numOffset, numDelta

	//strDirectory = PopUpChooseFolder()
	strDirectory = "root:"	
	if (stringmatch(strX,""))
		strX=PopUpChooseWave(strDirectory, strText="choose x wave")
	endif	
	if (stringmatch(strY,""))
		strY=PopUpChooseWave(strDirectory, strText="choose y wave")
	endif	

	if (!waveExists($strX) && !waveExists($strY))
		print "Error: Waves Do not exist or user cancelled at Prompt"
		return 0
	endif
	
	wave wavX 	= $strX
	wave wavY 	= $strY		

	numSize		= DimSize(wavX,0)
	numOffset	= wavX[0]
	numDelta 	= (wavX[(numSize-1)] - wavX[0]) / (numSize-1)
	
	SetScale/P x, numOffset, numDelta, strXUnit, wavY
	SetScale/P y, 1, 1, strYUnit, wavY
	
	return 1
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