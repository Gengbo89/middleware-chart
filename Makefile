.PHONY: dependencies lint template

HELM ?= helm

dependencies:
	test -f charts/mysql/Chart.yaml
	test -f charts/redis/Chart.yaml
	test -f charts/postgresql/Chart.yaml
	$(HELM) dependency list .

lint:
	$(HELM) lint .

template:
	$(HELM) template middleware . --namespace middleware
