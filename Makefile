.PHONY: inplace
inplace:
	python setup.py build_ext --inplace

.PHONY: build
build:
	python setup.py build

.PHONY: sdist
sdist:
	python setup.py sdist

.PHONY: clean
clean:
	python setup.py clean -a
	rm -f galxe/*.so galxe/*.dylib MANIFEST
	rm -rf dist
