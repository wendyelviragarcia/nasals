#	nasals.praat (2025)
#
#								INSTRUCTIONS
#
#	0. Requirements
#	   You need a `.wav` file. Optionally, you may also have a `.TextGrid`
#	   with the same base name stored in the same folder. If a TextGrid
#	   is present, it must contain at least one interval tier.
#
#	1. Run the script
#	   Open the script in Praat and click Run > Run.
#
#	2. FORM EXPLANATIONS
#
#	   Folder
#	   In the first field you must write the path of the folder where
#	   your files are stored.
#
#	   Examples:
#	       macOS:   /Users/yourName/Desktop
#	       Windows: C:\Users\yourUserName\Desktop
#	       Linux:   (you probably already know your path)
#
#	   Tier
#	   If you are using TextGrids, specify the interval tier that
#	   contains the nasal segments to be analysed.
#
#	   Label
#	   Indicate the label used in the tier for nasal segments
#	   (for example: m, n, ŋ, or any label used in your annotation).
#
#	3. OUTPUT
#
#	   The script creates a `.txt` file saved in the same folder as
#	   the data. The file contains one line per analysed token with:
#
#	       • file name
#	       • interval label
#	       • time boundaries of the segment
#	       • acoustic measurements extracted by the script
#
#	   The output file can be opened with any text editor or imported
#	   into spreadsheet software (Excel BEWARE DECIMAL SEPARATOR IS ., LibreOffice, R, etc.).
#
#	4. Notes
#
#	   • `.wav` and `.TextGrid` files must share the same base name
#	     (e.g. `speaker01.wav` and `speaker01.TextGrid`).
#	   • All files should be located in the same folder specified
#	     in the form.
#	   • The script processes all matching files in that folder.
#
#
# Any feedback is welcome, please if you notice any mistakes or come up with anything that can improve this script, let me know!
#
#		Wendy Elvira-García
#		Laboratory of Phonetics (University of Barcelona)
#		wendy el vira@ ub.edu
#		
#		
##############################################################################################################


form Voice quality
	sentence Folder ./test
	comment _____
	comment If you have a TextGrid and want to analyse only certain sounds:
	sentence label_of_intervals non-empty
	integer tier 1
	comment _____
	comment F0 options
	choice f0_range 1
        button Manual
        button Auto
	comment If manual these are the values used __
	integer f0_floor  50
	integer f0_ceiling 500
	comment _____
	comment Duration of the analyses (s.)
	comment set to 0 to analyze the whole interval/sound
	integer chunk 0

endform

########################################


#folder$ = chooseDirectory$ ("Choose a directory to read")
#creates txt file
writeFileLine: folder$+ "/"+ "nasalance_log.txt" , "Filename", tab$, "Interval", tab$, "Interval_label", tab$, "duration_interval", tab$, "duration_chunk", tab$, "f0_mean", tab$, "F1", tab$, "F2", tab$, "A1", tab$, "P0", tab$, "A1-P0", tab$, "H1_dB", tab$, "H2_dB", tab$,  "H1-H2", tab$, "H1-A1", tab$, "spectral_peak", tab$, "f0_floor", tab$, "f0_ceiling"

#creates the list of files
myList= Create Strings as file list: "list", folder$+ "/" +"*.wav"
numberOfFiles = Get number of strings

interval = 0
label$ = "-"
#empieza el bucle
for ifile to numberOfFiles
	selectObject: myList
	fileName$ = Get string: ifile
	base$ = fileName$ - ".wav"

	# reads sound
	mySound = Read from file: folder$+ "/" + base$ + ".wav"
	#mySound = Convert to mono

	# reads paired textgrid if it exists
	if fileReadable(folder$ +"/"+ base$ + ".TextGrid")
		myText= Read from file: folder$ +"/"+ base$ + ".TextGrid"
		Convert to Unicode
		existsText = 1

		nIntervals = Get number of intervals: tier
		labeltrobada= 0
		for interval to nIntervals
			selectObject: myText
			label$= Get label of interval: tier, interval

			# removing all tabs to create a tsv
			label$ = replace$(label$, "	", "", 0)
			# removing trailing silences and tabs
			label$ = replace_regex$(label$, "^[ \t]+", "", 0)   ; remove from start
    		label$ = replace_regex$(label$, "[ \t]+$", "", 0)   ; remove from end

			if label$ != "" and (label$ == label_of_intervals$ or label_of_intervals$ == "non-empty")
				start = Get start time of interval: tier, interval
				end = Get end time of interval: tier, interval
				duration = end-start

				if chunk != 0
					end = start + chunk
				endif

				selectObject: mySound
				mySoundOfInterest = Extract part: start, end, "rectangular", 1, "no"
				duration_chunk = end-start

				@nasals: mySoundOfInterest
				removeObject: mySoundOfInterest

			endif
		endfor
		#removeObject: mySound, myText

	else 
		existsText = 0
		selectObject: mySound
		duration = Get total duration
		duration_chunk = duration

		if chunk != 0
			mySoundOfInterest = Extract part: chunk, end, "rectangular", 1, "no"
			duration_chunk = chunk

		else
			mySoundOfInterest = mySound
		endif


		@nasals: mySoundOfInterest
		#removeObject: mySound
	endif


endfor




procedure nasals: theSound

	# nasalance cheatsheat 
	# A1 - P0 and A1 - P1 proposed by Chen (1997). 
	#  A1 is the amplitude of the vowel F1, P0 is the amplitude of the nasal peak below 
	# the F1 and P1 is the amplitude of the nasal peak between the first two vowel formants, F1 and F2.

# A1, which is the highest harmonic peak near the first formant, and P0, is a low frequency harmonic (usually H1 or H2), the amplitude of the nasal peak below 

# Will Styler's manual: A1-P0 only works in situations where F1 is higher in frequency than H1 and H2. Most of
#the time, this is true, but for high vowels, A1 and P0 often occur at the same place in
#the spectrum, leaving the measurement useless.
#– In these situations, A1-P1 (a second nasal resonance peak 1000 Hz, described in is a better measure of vowel nasality
#A low A1-P0 relative to known oral tokens is a good predictor of nasality across a large
#number of tokens, but individual nasal/oral vowel pairs may or may not demonstrate
#a strong effect. It should not be used to measure the nasality of one individual token
#compared to another.
# A1-P0 should only be examined in comparison with other tokens. An A1-P0 of -2 may
#be normal for an oral vowel for some speakers, but indicate extreme nasality for others.
# The absolute value of A1-P0 is not easily interpretable across speakers.


	if f0_range = 2 
		myPitchCheck= noprogress To Pitch (raw autocorrelation): 0, f0_floor, f0_ceiling, 15, "no", 0.03, 0.45, 0.01, 0.35, 0.14
		#myPitchCheck= To Pitch (filtered autocorrelation): 0, f0_floor, f0_ceiling, 15, "no", 0.03, 0.09, 0.5, 0.055, 0.35, 0.14
		f0medial= Get mean: 0, 0, "Hertz"
		
		#cuantiles teoría de Hirst (2011) analysis by synthesis of speach melody
		q25 = Get quantile: 0, 0, 0.25, "Hertz"
		q75 = Get quantile: 0, 0, 0.75, "Hertz"

		if q25 != undefined
			f0_floor = q25 * 0.75
		else
			f0_floor = f0_floor

		endif
		
		if q75 != undefined
			f0_ceiling = q75 * 1.5
			#set to 2.5 for expressive speech for being safe, else 1.5
		else
			f0_ceiling= f0_ceiling
		endif

		removeObject: myPitchCheck
	endif

	selectObject: theSound
	myPitch= noprogress To Pitch (raw cross-correlation): 0, f0_floor, f0_ceiling, 15, "no", 0.03, 0.45, 0.01, 0.35, 0.14



	###### LTAS
	selectObject: theSound
	#ltas = undefined  
	#echo 'f0_floor' 'f0_ceiling'
	ltas = noprogress To Ltas (pitch-corrected): f0_floor, f0_ceiling, 8000, 50, 0.0001, 0.02, 1.3
	
	if ltas != undefined 
		spectral_peak = Get frequency of maximum: 0, 11000, "Cubic"
		spectral_peak$ = fixed$ (spectral_peak, 0)
		removeObject: ltas
	else 
		spectral_peak$ = "undefined"
	endif


	

	#### H1-H2
	# don't remember if it should be auto or cross, copied this from many 
	#years ago
	selectObject: theSound
	To Pitch: 0, f0_floor, f0_ceiling
	f0 = Get quantile: 0, 0, 0.5, "Hertz"
	Remove

	#h1
	selectObject: theSound
	h1band= Filter (pass Hann band): f0 - 50, f0 + 50, 100
	h1_energy = Get power: 0, 0
	removeObject: h1band

	# H2
	selectObject: theSound
	h2band = Filter (pass Hann band): 2 * f0 - 50, 2 * f0 + 50, 100
	h2_energy = Get power: 0, 0
	removeObject: h2band

	# Convert to dB scale and compute difference
	# breathy → high H1-H2
	# creaky → low/negative H1-H2
	if h1_energy > 0 and h2_energy > 0
	    h1_db = 10 * log10(h1_energy)
	    h2_db = 10 * log10(h2_energy)
	    h1h2 = h1_db - h2_db
	else
	    h1h2 = undefined
	endif


	# H1-A1: difference in dB between the first harmonic (H1) and the first formant region (A1)
	# want to do this dynamically when I have the time (I have the code in the formants script)
	if f0 > 180
		maximum_formant = 5500
	else
		maximum_formant = 5000
	endif


	nFormants = 5

	selectObject: theSound

	myFormants = To Formant (burg): 0, nFormants, maximum_formant, 0.025, 50
	f1 = Get quantile: 1, 0, 0, "hertz", 0.5
	f2 = Get quantile: 2, 0, 0, "hertz", 0.5

	removeObject: myFormants



	# Extract A1
	selectObject: theSound
	a1band = Filter (pass Hann band): f1 - 100, f1 + 100, 200  ; Broader window around F1
	a1_energy = Get power: 0, 0
	removeObject: a1band



	# Compute H1 and A1 in dB and their difference
	if h1_energy > 0 and a1_energy > 0
	    h1_dB = 10 * log10(h1_energy)
	   	h2_dB = 10 * log10(h2_energy)
	    a1_dB = 10 * log10(a1_energy)
	    h1a1 = h1_dB - a1_dB
	else
	    h1a1= undefined
	    h1_dB= undefined
	    h2_dB = undefined
	    a1_dB = undefined
	endif




	if h1_dB > h2_dB
		p0 = h1_dB
	else 
		p0 = h2_dB
	endif
	
	a1_p0 = a1_dB - p0

		appendFile: folder$+ "/"+ "nasalance_log.txt" , base$, tab$, interval, tab$, label$, tab$,
	... fixed$(duration, 2), tab$, duration_chunk, tab$, fixed$(f0, 0), tab$,
	... fixed$(f1, 0), tab$, fixed$(f2, 0),tab$,
	... fixed$(a1_dB, 2), tab$, fixed$(p0, 2),tab$, fixed$(a1_p0, 2), tab$,
	... fixed$ (h1_db,2), tab$, fixed$ (h2_db, 2), tab$, fixed$ (h1h2,2), tab$, fixed$ (h1a1,2), tab$, 
	... spectral_peak$, tab$, f0_floor, tab$, f0_ceiling, newline$


	removeObject: myPitch

endproc