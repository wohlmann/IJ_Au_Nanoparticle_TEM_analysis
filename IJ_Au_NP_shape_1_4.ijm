macro "size distribution of Au particles in TEM images, scale via filename" {
	getDateAndTime(year, month, week, day, hour, min, sec, msec);
	while (nImages>0) {
		selectImage(nImages);
		close();
	}
	run("Clear Results");
	updateResults;
	roiManager("reset");
	run("Close All");
	print("\\Clear");
	print("Start process at: "+day+"/"+month+"/"+year+" :: "+hour+":"+min+":"+sec+"");
	dir1=getDirectory("Please choose source directory");
	list=getFileList(dir1);
	dir2=getDirectory("Please choose destination directory ");
	Dialog.create("processing options");
	Dialog.addMessage("analysing "+list.length+" images");
	Dialog.addCheckbox("use batch mode ", true);
	Dialog.addCheckbox("save QC images ", true);
	Dialog.show();
	batch = Dialog.getCheckbox();
	QC = Dialog.getCheckbox();
	setBatchMode(batch);
	if (batch == 1){
		print("batch mode on");
	}else{
		print("batch mode off");
	}
	print("processing directory: "+dir1+"");
	N=0;
	Nf=0;
	NfN=0;
	sumROI=0;
	print("___");
	print("___");
//MAG-Steps and px/nm
	MAGS = newArray("X200", "X250", "X300", "X400", "X500", "X600", "X800", "X1000", "X1200", "X1500", "X2000", "X2500", "X3000", "X4000", "X5000", "X6000", "X8000", "X10k", "X12k", "X15k", "X20k", "X25k", "X30k", "X40k", "X50k", "X60k", "X80k", "X100k", "X120k", "X150k", "X200k", "X250k", "X300k", "X500k", "X600k", "X800k", "X1M", "X1.2M");
	px_nm = newArray(0.012460787, 0.015575979, 0.018691169, 0.024921575, 0.031152007, 0.037382408, 0.049843149, 0.062304014, 0.074764537, 0.093456021, 0.124607252, 0.15575955, 0.186912042, 0.249214503, 0.311523955, 0.373817094, 0.498429006, 0.623028489, 0.72630814, 0.894557823, 1.192743764, 1.490974191, 1.789115646, 2.34987068, 2.937683715, 3.525220459, 4.70084666, 5.875367431, 7.047954866, 8.813051146, 11.74383079, 14.69705882, 17.62610229, 29.39411765, 35.19014085, 46.92018779, 58.78823529, 70.38028169);
	run("Set Measurements...", "shape perimeter feret's redirect=None decimal=3");
	for (i=0; i<list.length; i++) {
		path = dir1+list[i];
		open(path);
		title = getTitle;
		title2 = File.nameWithoutExtension;
		print("image title: "+title+"");
//conversion
		magindex = -1;
		ma = 0;
		for (m=0; m<MAGS.length; m++) {
			ma=(indexOf(title, MAGS[m])+1);
			if (ma>0) {
				magindex = m;
			}
		}
		if (magindex <0) {
			print("ERROR: wrong magnification in Image "+title+" - skipped");
			Nf++;
			selectWindow(""+title+"");	
			close();
			} else {
				pxnm = px_nm [magindex];
				print ("detcted MAG: "+MAGS [magindex]+"");
				print("scale: "+pxnm+" px/nm");	
				selectWindow(""+title+"");
				run("Enhance Contrast...", "saturated=0.35 normalize equalize");
				run("Duplicate...", " ");
				run("Set Scale...", "distance="+pxnm+" known=1 unit=nm");
				run("Bandpass Filter...", "filter_large=60 filter_small=15 suppress=None tolerance=5 autoscale saturate ");
				setAutoThreshold("Li");
				setThreshold(0, 21074, "raw");
				//setThreshold(0, 15677, "raw");
				setOption("BlackBackground", false);
				run("Convert to Mask");
				run("Analyze Particles...", "size=9-300 circularity=0.80-1.00 show=Outlines exclude overlay add");
				nROI=roiManager("count");
				sumROI=sumROI+nROI;
				print("detected "+nROI+" particles");
				print("Sum of particles in analysis is now: "+sumROI+"");
				roiManager("Measure");
				if(QC==true){
					selectWindow(""+title+"");
					roiManager("deselect");
					roiManager("Select All");
					roiManager("Show All");
					run("Flatten");
					saveAs("Gif", dir2+title2+"_QC.gif");
					print("saved QC image with ROI overlay as "+dir2+title2+"_QC.gif ");
				}
				print("___");
				if(nROI>=0){
					roiManager("Delete");
				}
				while (nImages>1) { 
					selectImage(nImages); 
			    	close(); 
				}
				N++;
			}	
	}
	run("Distribution...", "parameter=Feret automatic");
	selectWindow("Feret Distribution");
	saveAs("jpg", ""+dir2+"size_distribution_plot_"+day+"-"+month+"-"+year+"_"+hour+"h"+min+"min.jpg");
	run("Distribution...", "parameter=Circ. automatic");
	selectWindow("Circ. Distribution");
	saveAs("jpg", ""+dir2+"circularity_distribution_plot_"+day+"-"+month+"-"+year+"_"+hour+"h"+min+"min.jpg");
	selectWindow("Results");
	saveAs("txt", ""+dir2+"measurements_"+day+"-"+month+"-"+year+"_"+hour+"h"+min+"min.xls");
	selectWindow("Log");
	saveAs("Text", ""+dir2+"/analysis_log_"+day+"-"+month+"-"+year+"_"+hour+"h"+min+"min.txt");
	run("Close All");
	if ((Nf==0)||(Nf>1))  {
		NfN="files";
	}else{
		NfN="file";
	}
	print("___");
	print("Finished process at: "+day+"/"+month+"/"+year+" :: "+hour+":"+min+":"+sec+"");
	print(""+sumROI+" particles analysed in "+N+" files, "+Nf+" "+NfN+" failed. Results see; "+dir2+"");
	waitForUser("Summary"," "+sumROI+" particles analysed in "+N+" files, "+Nf+" "+NfN+" failed. Results see; "+dir2+"");
}
//Jens_20.11.22