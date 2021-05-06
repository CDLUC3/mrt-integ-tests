## Test command

```
docker-compose run --rm -e INTEG_TEST_ENV=development -e INGEST_FILES=basic-ingest -e PREVIEW_URL='http://uc3-mrtdocker01x2-dev.cdlib.org:8086/' mrt-integ-tests
```

```
docker-compose run --rm -e PREFIX=2021_05_05_1743 -e INTEG_TEST_ENV=development -e INGEST_FILES=basic-ingest -e PREVIEW_URL='http://uc3-mrtdocker01x2-dev.cdlib.org:8086/' mrt-integ-tests
```



```
docker-compose run --rm -e INTEG_TEST_ENV=development -e INGEST_FILES=basic-ingest -e PREVIEW_URL='http://uc3-mrtdocker01x2-dev.cdlib.org:8099/' mrt-integ-tests
```

## TODO: pass in a string to drive retrievals