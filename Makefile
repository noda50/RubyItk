RDOC_FILES = Octave/Octave.rb \
	     Dia/DiaUml.rb Dia/dia2ruby \
	     Maxima/Maxima.rb \
	     Canvas/myCanvas.rb

top : rdoc

rdoc :
	rdoc --force-update --line-numbers --diagram $(RDOC_FILES)
