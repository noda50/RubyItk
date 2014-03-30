RDOC_FILES = Octave/Octave.rb

top : rdoc

rdoc :
	rdoc $(RDOC_FILES)
