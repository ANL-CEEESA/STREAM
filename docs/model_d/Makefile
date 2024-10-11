DOC  := dre4m_d.tex

RERUN := "(undefined references|Rerun to get (cross-references|the bars|point totals) right|Table widths have changed. Rerun LaTeX.|Linenumber reference failed)"
RERUNBIB := "No file.*\.bbl|Citation.*undefined"

all: doc


doc: $(DOC:.tex=.pdf)

%.pdf: %.tex
	pdflatex $<
	@egrep -q $(RERUNBIB) $*.log && bibtex $* && pdflatex $<; true
	@egrep -q $(RERUN) $*.log && pdflatex $<; true
	@egrep -q $(RERUN) $*.log && pdflatex $<; true

latexmk:
	-latexmk -pvc -pdf $(DOC)

purge:
	-rm -f *.{aux,dvi,log,bbl,blg,brf,fls,toc,thm,out,fdb_latexmk}

clean: purge
	-rm -f $(DOC:.tex=.pdf)

.PHONY: all purge clean
