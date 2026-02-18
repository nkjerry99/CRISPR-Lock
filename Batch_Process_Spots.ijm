/*
 * Macro to batch process 2-channel TIFF files for spot detection.
 * 
 * Steps per channel:
 * 1. Rolling Ball Background Subtraction (radius=100)
 * 2. Gaussian Blur (sigma=1)
 * 3. Find Maxima (detect brightest spots)
 * 4. Save spots as ROI Manager selection (.zip)
 * 
 * Author: Antigravity
 */

// --- Parameters ---
var backsubRadius = 100;
var blurSigma = 1;

// Prominence (noise tolerance) is critical for "Find Maxima".
// Adjust this value if you pick up too much noise or miss real spots.
var prominence = 50; 

macro "Batch Process Spots" {
    // 1. Get Input Directory
    inputDir = getDirectory("Choose Input Directory containing TIFFs");
    if (inputDir == "") exit("No input directory selected");

    // 2. Get Output Directory
    outputDir = getDirectory("Choose Output Directory for ROIs");
    if (outputDir == "") exit("No output directory selected");

    // 3. Get list of files
    list = getFileList(inputDir);

    setBatchMode(true); // Run in background for speed

    for (i = 0; i < list.length; i++) {
        showProgress(i+1, list.length);
        filename = list[i];
        
        // Process only .tif or .tiff files
        if (endsWith(toLowerCase(filename), ".tif") || endsWith(toLowerCase(filename), ".tiff")) {
            path = inputDir + filename;
            open(path);
            
            // Get basic image info
            originalTitle = getTitle();
            // Remove extension for simple naming
            baseName = File.nameWithoutExtension;
            
            // 4. Split Channels
            run("Split Channels");
            
            // We assume 2 channels. Split Channels usually names them "C1-[Name]" and "C2-[Name]"
            // We'll loop through expected channel names or windows.
            
            // Channel 1 Processing
            c1Title = "C1-" + originalTitle;
            if (isOpen(c1Title)) {
                selectWindow(c1Title);
                processChannel(baseName + "_C1");
                close(c1Title);
            }
            
            // Channel 2 Processing
            c2Title = "C2-" + originalTitle;
            if (isOpen(c2Title)) {
                selectWindow(c2Title);
                processChannel(baseName + "_C2");
                close(c2Title);
            }
        }
    }
    
    setBatchMode(false);
    showMessage("Batch Processing Complete!");
}

function processChannel(saveName) {
    // (1) Rolling Background Subtraction
    run("Subtract Background...", "rolling=" + backsubRadius);
    
    // (2) Gaussian Blur
    run("Gaussian Blur...", "sigma=" + blurSigma);
    
    // (3) Find Maxima -> Output to ROI Manager
    // "output=[Point Selection]" creates a multipoint selection of maxima
    run("Find Maxima...", "prominence=" + prominence + " output=[Point Selection]");
    
    // Check if any selection was made (if no spots found, skip saving)
    if (selectionType() != -1) {
        roiManager("reset");
        roiManager("Add");
        
        // (4) Save ROIs
        // Saving as a .zip is standard for multiple ROIs, though here it's likely one MultiPoint ROI.
        // We can rename it in the manager for clarity
        roiManager("Select", 0);
        roiManager("Rename", saveName);
        
        savePath = outputDir + saveName + "_ROIs.zip";
        roiManager("Save", savePath);
        roiManager("reset");
    }
}
