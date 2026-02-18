// Batch ROI Cropping Macro for ImageJ
// This macro processes ROI zip files and corresponding TIF images
// Crops each ROI and saves as a separate file

// Get input and output directories
inputDir = getDirectory("Choose the folder containing ROI zip files and TIF images");
outputDir = getDirectory("Choose the output folder for cropped images");

// Get list of all files in the directory
fileList = getFileList(inputDir);

// Arrays to store zip and tif files
zipFiles = newArray();
tifFiles = newArray();

// Separate zip and tif files
for (i = 0; i < fileList.length; i++) {
    if (endsWith(fileList[i], ".zip")) {
        zipFiles = Array.concat(zipFiles, fileList[i]);
    }
    if (endsWith(fileList[i], ".tif") || endsWith(fileList[i], ".tiff")) {
        tifFiles = Array.concat(tifFiles, fileList[i]);
    }
}

print("Found " + zipFiles.length + " ROI zip files");
print("Found " + tifFiles.length + " TIF files");

// Process each zip file
for (i = 0; i < zipFiles.length; i++) {
    zipFile = zipFiles[i];
    
    // Extract base name (without extension) to find corresponding TIF
    // Assumes zip file name matches TIF file name (e.g., image1.zip -> image1.tif)
    baseName = replace(zipFile, ".zip", "");
    
    // Find corresponding TIF file
    tifFile = "";
    for (j = 0; j < tifFiles.length; j++) {
        if (startsWith(tifFiles[j], baseName)) {
            tifFile = tifFiles[j];
            break;
        }
    }
    
    if (tifFile == "") {
        print("Warning: No matching TIF file found for " + zipFile);
        continue;
    }
    
    print("Processing: " + zipFile + " with " + tifFile);
    
    // Open the TIF image
    open(inputDir + tifFile);
    imageID = getImageID();
    imageTitle = getTitle();
    
    // Load ROI(s) from zip file
    roiManager("reset");
    roiManager("Open", inputDir + zipFile);
    numROIs = roiManager("count");
    
    print("  Found " + numROIs + " ROI(s) in " + zipFile);
    
    // Process each ROI in the zip file
    for (k = 0; k < numROIs; k++) {
        selectImage(imageID);
        
        // Select the ROI
        roiManager("select", k);
        
        // Get ROI name (if available)
        roiName = call("ij.plugin.frame.RoiManager.getName", k);
        if (roiName == "") {
            roiName = "ROI_" + (k + 1);
        }
        
        // Duplicate the ROI area (crops to bounding box)
        run("Duplicate...", "duplicate"); // "duplicate" keeps all channels and slices
        croppedID = getImageID();
        
        // Create output filename
        outputName = baseName + "_" + roiName + ".tif";
        
        // Save the cropped image
        saveAs("Tiff", outputDir + outputName);
        print("  Saved: " + outputName);
        
        // Close the cropped image
        close();
        
        // Return to original image
        selectImage(imageID);
    }
    
    // Close the original image
    close();
}

// Clean up
roiManager("reset");
print("\\nProcessing complete!");
print("Processed " + zipFiles.length + " zip files");
print("Output saved to: " + outputDir);
