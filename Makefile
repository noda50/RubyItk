RDOC_FILES = Octave/Octave.rb \
	     Dia/DiaUml.rb Dia/dia2ruby \
	     Maxima/Maxima.rb \
	     Canvas/myCanvas.rb

top : rdoc

rdoc : dia2ruby
	rdoc --force-update --line-numbers --diagram $(RDOC_FILES)

dia2ruby :
	(cd Dia ; ./dia2ruby --help > USAGE.dia2ruby || echo)

publish :
	git push
	git co gh-pages
	git merge master
	git push
	git co master
