/* Macro for measuring area of segmented images 
 * input: segmented images (e.g. from Ilastik) with 4 different labels, saved as as tif or png, 8bit (optional - will be converted anyway!); grey values increasing from 1 to 4 for different lables.
 * output: csv with pixel-values of area (Px²)
 * SK / VetImaging / VetCore / Vetmeduni Vienna 2019
 */

/* Create interactive Window to set variables for 
 * input/output folder, input/output suffix, scale factor, subfolder-processing
 */

#@ String (visibility=MESSAGE, value="Choose your files and parameter, 4 different labels are required!", required=false)	msg
#@ File (label = "Input directory", style = "directory")	input_folder
#@ File (label = "Output directory for result xls-table", style = "directory")	output_folder
#@ String (label = "Give your result xls-table a name", value="Osteopontin_results")	results_table
#@ String (label = "File suffix input (case sensitive!)", description="*.tif or *.png", choices={".tif", ".png", ".tiff", ".TIF", ".PNG", ".TIFF"}, style="radioButtonHorizontal") 	suffix_in
#@ String (label = "name label #1", value="Osteopontin positive")	label01
#@ String (label = "name label #2", value="Osteopontin negative")	label02
#@ String (label = "name label #3", value="Background in Tumor")	label03
#@ String (label = "name label #4", value="Background around tumor")	label04
#@ String (label = "Include subfolders", choices={"no","yes"}, style="radioButtonHorizontal")	subfolders

resultsfile = output_folder+"\\"+results_table+".xls";

if (File.exists(resultsfile)) {
	Dialog.create("Existing output!")
	Dialog.addMessage("File already exists! Restart & rename output file not to overwrite data.");
	Dialog.show();
	exit();
	} 


run("Collect Garbage");
ImageNumber = 0;
labels = 4;
getImageNumber(input_folder);
processFolder(input_folder);

//run("Close All");
exit();


// function to scan folders/subfolders/files to find files with correct suffix
function getImageNumber(input_folder) {
	filelist = getFileList(input_folder);
	filelist = Array.sort(filelist);
	for (i = 0; i < filelist.length; i++) {
		
		// process recursion for subfolders if option "Include subfolders" is true
		if(subfolders=="yes"){
		if(File.isDirectory(input_folder + File.separator + filelist[i]))
			getImageNumber(input_folder + File.separator + filelist[i]);}
			
		// for images with correct suffix increment ImageNumber
		if(endsWith(filelist[i], suffix_in))
			ImageNumber++;
	}

}

// function to scan folders/subfolders/files to find files with correct suffix
function processFolder(input_folder) {
raw_title = newArray(ImageNumber +1);
plain_title = newArray(ImageNumber +1);
labelAreas = newArray(ImageNumber +1);
osteopontin_positive = newArray(ImageNumber +1);
osteopontin_negative = newArray(ImageNumber +1);
osteopontin_background = newArray(ImageNumber +1);
osteopontin_outer_background = newArray(ImageNumber +1);
perc_pos = newArray(ImageNumber +1);
perc_neg = newArray(ImageNumber +1);
perc_bg = newArray(ImageNumber +1);
whole_Area = newArray(ImageNumber +1);
osteopontin_ratio = newArray(ImageNumber +1);

	actual_image_number = 0;
	filelist = getFileList(input_folder);
	filelist = Array.sort(filelist);
	for (i = 0; i < filelist.length; i++) {
		
		// process recursion for subfolders if option "Include subfolders" is true
		if(subfolders=="yes"){
		if(File.isDirectory(input_folder + File.separator + filelist[i]))
			processFolder(input_folder + File.separator + filelist[i]);}
			
		// for images with correct suffix proceed with processing
		if(endsWith(filelist[i], suffix_in)) {
				
	
		if(suffix_in==".tif"||suffix_in==".tiff"){
	    	run("Bio-Formats Windowless Importer", "open=[" + input_folder + File.separator + filelist[i] +"]");
	    	run("RGB Color");
	    	run("8-bit");
		}
	
		if(suffix_in==".jpg"||suffix_in==".jpeg"||suffix_in==".png"){
	    	open(input_folder + File.separator + filelist[i]);
	    	run("8-bit");
		}
		
		raw_title[actual_image_number] = getTitle();
		plain_title[actual_image_number] = replace(getTitle(), suffix_in, "");
		labelAreas[actual_image_number] = ""; //define as string

		
		//set LUT for better visibility
		run("Fire"); 
		run("Set Measurements...", "area decimal=0");
		   
		for (activeLabel = 0; activeLabel < labels; activeLabel++){
			setThreshold(activeLabel+1, activeLabel+1);
			run("Create Selection");
			run("Measure");
			run("Select None");

		}	
		osteopontin_positive[actual_image_number] = getResult("Area", 0);
		osteopontin_negative[actual_image_number] = getResult("Area", 1);
		osteopontin_background[actual_image_number] = getResult("Area", 2);
		osteopontin_outer_background[actual_image_number] = getResult("Area", 3);
		whole_Area[actual_image_number] = d2s(osteopontin_positive[actual_image_number] + osteopontin_negative[actual_image_number] + osteopontin_background[actual_image_number], 2);
		perc_pos[actual_image_number] = d2s(100 / (osteopontin_positive[actual_image_number]+osteopontin_negative[actual_image_number]+osteopontin_background[actual_image_number]) * osteopontin_positive[actual_image_number], 2);
		perc_neg[actual_image_number] = d2s(100 / (osteopontin_positive[actual_image_number]+osteopontin_negative[actual_image_number]+osteopontin_background[actual_image_number]) * osteopontin_negative[actual_image_number], 2);
		perc_bg[actual_image_number] = d2s(100 / (osteopontin_positive[actual_image_number]+osteopontin_negative[actual_image_number]+osteopontin_background[actual_image_number]) * osteopontin_background[actual_image_number], 2);
		osteopontin_ratio[actual_image_number] = d2s(osteopontin_positive[actual_image_number] / osteopontin_negative[actual_image_number], 2);
		run("Clear Results");

		actual_image_number ++;
		run("Collect Garbage");
}
	run("Close All");
}
		
//report data in xls
	run("Clear Results");
	run("Input/Output...", "file=.csv use_file copy_column save_column");

for (resultline=0; resultline<ImageNumber; resultline++) {
	 setResult("Image",resultline,plain_title[resultline]);
	 setResult(label01,resultline,osteopontin_positive[resultline]);
	 setResult(label02,resultline,osteopontin_negative[resultline]);
	 setResult(label03,resultline,osteopontin_background[resultline]);
	 setResult(label04,resultline,osteopontin_outer_background[resultline]);
	 setResult("Whole Tumor-Area",resultline,whole_Area[resultline]);
	 setResult("% "+label01,resultline,perc_pos[resultline]);
	 setResult("% "+label02,resultline,perc_neg[resultline]);
	 setResult("% "+label03,resultline,perc_bg[resultline]);
	 setResult("Osteopontin ratio",resultline,osteopontin_ratio[resultline]);
	 
}
selectWindow("Results");
saveAs("text", resultsfile);
run("Close");

}