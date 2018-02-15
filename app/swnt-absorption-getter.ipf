#pragma TextEncoding = "UTF-8"	// For details execute DisplayHelpTopic "The TextEncoding Pragma"
#pragma rtGlobals=3					// Use modern global access method and strict wave access.

Function/DF AbsorptionChiralityDFR([type])
	String type
	If (ParamIsDefault(type))
		type = "sds"
	endif
	DFREF dfrSave, dfr

	dfrSave = GetDataFolderDFR()
	
	dfr = AbsorptionDFR(subDFR = "chirality")
	SetDataFolder dfr
	strswitch(type)
		case "free":
			NewDataFolder/O/S dfr:free
			break
		case "sds":
			NewDataFolder/O/S dfr:sds
	endswitch
	dfr = GetDataFolderDFR()
	
	SetDataFolder dfrSave
	
	return dfr
End

Function/DF AbsorptionDFR([subDFR])
	String subDFR
	if (ParamIsDefault(subDFR))
		subDFR = ""
	Endif
	DFREF dfrSave, dfr

	dfrSave = GetDataFolderDFR()
	
	SetDataFolder root:
	NewDataFolder/O/S root:Packages
	NewDataFolder/O/S root:Packages:Absorption
	if (strlen(subDFR) > 0)
		subDFR = CleanupName(subDFR, 0)
		NewDataFolder/O/S $subDFR
	endif
	dfr = GetDataFolderDFR()
	
	SetDataFolder dfrSave
	
	return dfr
End
	