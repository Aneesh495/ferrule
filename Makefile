.PHONY: all test bench clean verify lint

PYTHON ?= python3

all: test

test:
	$(PYTHON) -m unittest discover -s tests -p "test_*.py" -v

bench:
	$(PYTHON) tools/benchmark.py

lint:
	$(PYTHON) -m py_compile engine/*.py tools/*.py tests/*.py

verify:
	$(PYTHON) -c 'import sys, os; \
	bad = []; \
	[bad.append(os.path.join(r, f)) for r, d, fs in os.walk(".") if not r.startswith("./.git") for f in fs if not f.endswith((".pyc", ".png", ".jpg", ".bin", ".dylib", ".so")) and open(os.path.join(r, f), "r", errors="ignore").read().find("\u2014") != -1]; \
	sys.exit(f"Em dash found in files: {bad}" if bad else 0)'

clean:
	find . -type d -name "__pycache__" -exec rm -rf {} +
	find . -type f -name "*.pyc" -delete
	rm -rf .pytest_cache
