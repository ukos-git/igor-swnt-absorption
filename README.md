# igor-swnt-absorption
A loader/plotter for absorption files of carbon nanotubes. Examples for spectra and experiment files included.

# Installation
You can navigate to the Igor Pro User Files folder from the menu bar: ![Igor Pro User Files Folder](images/installation-igor-procedures-folder.png?raw=true "Show Igor Procedures Folder in Igor7")
All files from the Igor Procedures Folder are loaded by default on program start. So navigate there and copy or link the this Repo to your Igor Procedures Folder. 

# Basics of SWNT
A typical Spectra of Nanotubes is seen in the following picture.
![nanotube_example](images/nanotube_example.png?raw=true "typical Nanotube Spectra")

 The visible Regions indicate the regions of the first and second subband exciton transitions. See elsewhere for details.
With carbon nanotubes the Kataura Plot is a very common plot type. It is explained in the following picture:
![nanotube_kataura](images/kataura-explained.png?raw=true "Kataura Plot for Nanotube Spectra")

# Generated Spectra
The Program uses WMs PeakFind to quickly yield a table with peaks. Also the second derivative is plotted for better peak identification.
![nanotube_peakfind](images/igor-swnt-peak-find.png?raw=true "Peakfind for Nanotube Spectra")

A special type of Kataura Plot can be used for peak identification:
![nanotube_kataura](images/kataura-example.png?raw=true "Kataura Plot for Nanotube Spectra")

# Get started
A sample experiment is also included. Start by opening it.
Work yourself through the menu AKH->Absorption. 
* Start with load Directory
* Display one of the loaded files in a Graph
* Use the menu to perform different analysis methods.

A directory named ''spectra'' is also included where you can take a look at the (rather strict) file format that is used during loading process.
